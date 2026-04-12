// Configurações
const SUPABASE_URL = 'https://klepqdiqpochlkrfyapd.supabase.co';
const SYNC_SECRET = 'SuevitSync2026!SecureKey#Farma';
const EDGE_FUNCTION_URL = `${SUPABASE_URL}/functions/v1/sync-products`;

// Função auxiliar para limpar e converter preços (formato brasileiro)
function cleanPrice(value) {
  if (!value) return 0;
  
  // Se já é número, retorna direto
  if (typeof value === 'number') return value;
  
  // Converte para string e limpa
  let cleaned = String(value).trim();
  
  // Remove símbolo de moeda se existir
  cleaned = cleaned.replace(/R\$\s*/g, '');
  
  // Remove espaços
  cleaned = cleaned.replace(/\s/g, '');
  
  // Se tem vírgula e ponto, é formato brasileiro: 1.234,56
  if (cleaned.includes('.') && cleaned.includes(',')) {
    cleaned = cleaned.replace(/\./g, '').replace(',', '.');
  }
  // Se só tem vírgula, assume que é decimal brasileiro: 1234,56
  else if (cleaned.includes(',')) {
    cleaned = cleaned.replace(',', '.');
  }
  // Se só tem ponto, verifica se é milhares ou decimal
  else if (cleaned.includes('.')) {
    const parts = cleaned.split('.');
    // Se tem mais de 2 dígitos após o último ponto, é milhares
    if (parts[parts.length - 1].length > 2) {
      cleaned = cleaned.replace(/\./g, '');
    }
  }
  
  const parsed = parseFloat(cleaned);
  return isNaN(parsed) ? 0 : parsed;
}

// Função auxiliar para limpar texto
function cleanText(value) {
  if (!value) return '';
  return String(value).trim();
}

// Sincronização INSTANTÂNEA quando editar a planilha
function onEdit(e) {
  const sheet = e.source.getActiveSheet();
  const editedRow = e.range.getRow();
  
  // Ignorar edição no cabeçalho
  if (editedRow === 1) return;
  
  Logger.log('📝 Editado! Sincronizando linha ' + editedRow);
  
  // Sincronizar apenas a linha editada (INSTANTÂNEO)
  syncSingleRow(sheet, editedRow);
}

// Nova função: Sincronizar apenas UMA linha (rápido!)
function syncSingleRow(sheet, rowIndex) {
  try {
    const data = sheet.getRange(rowIndex, 1, 1, sheet.getLastColumn()).getValues()[0];
    const headers = sheet.getRange(1, 1, 1, sheet.getLastColumn()).getValues()[0];
    
    // Mapear colunas
    const codigoIdx = headers.indexOf('CÓDIGO');
    const descricaoIdx = headers.indexOf('DESCRIÇÃO');
    const fabricanteIdx = headers.indexOf('FABRICANTE');
    const precoIdx = headers.indexOf('VLR. UNIT');
    const estoqueIdx = headers.indexOf('ESTOQUE');
    const eanbkIdx = headers.indexOf('CODIGO EAN');
    const undIdx = headers.indexOf('UND');
    const classFiscalIdx = headers.indexOf('CLASS. FISCAL');
    
    // Validações básicas
    const descricao = cleanText(data[descricaoIdx]);
    const codigo = cleanText(data[codigoIdx]);
    
    // Se não tem descrição OU descrição é inválida (tipo "UN 2000"), ignorar
    if (!descricao || descricao.length < 3 || /^UN\s*\d+$/.test(descricao)) {
      Logger.log('⚠️ Linha com dados inválidos, ignorando: ' + descricao);
      return;
    }
    
    // Se não tem código válido, ignorar
    if (!codigo || codigo.length < 1) {
      Logger.log('⚠️ Linha sem código, ignorando');
      return;
    }
    
    const preco = cleanPrice(data[precoIdx]);
    
    // Validar preço
    if (preco > 1000000) {
      Logger.log('⚠️ Preço suspeito detectado: R$ ' + preco.toFixed(2) + ' - Ignorando linha');
      return;
    }
    
    const product = {
      codigo: codigo,
      descricao: descricao,
      fabricante: cleanText(data[fabricanteIdx]),
      vlr_unit: preco,
      estoque: Math.floor(Number(data[estoqueIdx]) || 0),
      codigo_ean: cleanText(data[eanbkIdx]),
      und: cleanText(data[undIdx]) || 'UN',
      class_fiscal: cleanText(data[classFiscalIdx]),
    };
    
    Logger.log('📦 Sincronizando produto: ' + product.codigo + ' - ' + product.descricao + ' - R$ ' + product.vlr_unit.toFixed(2));
    
    // Usar bulk_sync com apenas 1 produto (funciona!)
    const payload = {
      action: 'bulk_sync',
      products: [product] // Array com 1 produto
    };
    
    const response = UrlFetchApp.fetch(EDGE_FUNCTION_URL, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'x-sync-secret': SYNC_SECRET,
      },
      payload: JSON.stringify(payload),
      muteHttpExceptions: true,
    });
    
    const result = JSON.parse(response.getContentText());
    
    if (response.getResponseCode() === 200) {
      Logger.log('✅ Produto sincronizado: ' + product.codigo);
    } else {
      Logger.log('❌ Erro ao sincronizar: ' + result.error);
    }
    
  } catch (error) {
    Logger.log('❌ Erro: ' + error.message);
  }
}

// Função principal de sincronização
function syncToSupabase() {
  try {
    const sheet = SpreadsheetApp.getActiveSpreadsheet().getSheets()[0];
    const data = sheet.getDataRange().getValues();
    const headers = data[0];
    
    const codigoIdx = headers.indexOf('CÓDIGO');
    const descricaoIdx = headers.indexOf('DESCRIÇÃO');
    const fabricanteIdx = headers.indexOf('FABRICANTE');
    const precoIdx = headers.indexOf('VLR. UNIT');
    const estoqueIdx = headers.indexOf('ESTOQUE');
    const eanbkIdx = headers.indexOf('CODIGO EAN');
    const undIdx = headers.indexOf('UND');
    const classFiscalIdx = headers.indexOf('CLASS. FISCAL');
    
    const products = [];
    let skippedCount = 0;
    
    for (let i = 1; i < data.length; i++) {
      const row = data[i];
      
      const descricao = cleanText(row[descricaoIdx]);
      const codigo = cleanText(row[codigoIdx]);
      
      // Validações
      if (!descricao || descricao.length < 3 || /^UN\s*\d+$/.test(descricao)) {
        skippedCount++;
        Logger.log(`⚠️ Linha ${i+1} ignorada - descrição inválida: ${descricao}`);
        continue;
      }
      
      if (!codigo || codigo.length < 1) {
        skippedCount++;
        Logger.log(`⚠️ Linha ${i+1} ignorada - sem código`);
        continue;
      }
      
      const preco = cleanPrice(row[precoIdx]);
      
      if (preco > 1000000) {
        skippedCount++;
        Logger.log(`⚠️ Linha ${i+1} ignorada - preço suspeito: R$ ${preco.toFixed(2)}`);
        continue;
      }
      
      products.push({
        codigo: codigo,
        descricao: descricao,
        fabricante: cleanText(row[fabricanteIdx]),
        vlr_unit: preco,
        estoque: Math.floor(Number(row[estoqueIdx]) || 0),
        codigo_ean: cleanText(row[eanbkIdx]),
        und: cleanText(row[undIdx]) || 'UN',
        class_fiscal: cleanText(row[classFiscalIdx]),
      });
    }
    
    Logger.log(`📊 Total de produtos válidos: ${products.length}`);
    Logger.log(`⚠️ Linhas ignoradas: ${skippedCount}`);
    
    const batchSize = 50;
    let successCount = 0;
    
    for (let i = 0; i < products.length; i += batchSize) {
      const batch = products.slice(i, i + batchSize);
      
      const payload = {
        action: 'bulk_sync',
        products: batch
      };
      
      const response = UrlFetchApp.fetch(EDGE_FUNCTION_URL, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'x-sync-secret': SYNC_SECRET,
        },
        payload: JSON.stringify(payload),
        muteHttpExceptions: true,
      });
      
      const result = JSON.parse(response.getContentText());
      
      if (response.getResponseCode() === 200) {
        successCount += batch.length;
        Logger.log(`Lote ${Math.floor(i/batchSize) + 1}: ${batch.length} produtos enviados`);
      } else {
        Logger.log(`Erro no lote: ${result.error}`);
      }
      
      Utilities.sleep(500);
    }
    
    Logger.log(`✅ Sincronização completa! ${successCount} produtos enviados, ${skippedCount} ignorados`);
    SpreadsheetApp.getUi().alert(`Sincronização completa!\n${successCount} produtos sincronizados\n${skippedCount} linhas ignoradas por dados inválidos`);
    return successCount;
    
  } catch (error) {
    Logger.log(`❌ Erro: ${error.message}`);
    SpreadsheetApp.getUi().alert('Erro na sincronização: ' + error.message);
    return 0;
  }
}

function testSync() {
  const count = syncToSupabase();
  Logger.log(`Teste concluído: ${count} produtos sincronizados`);
}

function doPost(e) {
  const lock = LockService.getScriptLock();
  
  try {
    lock.tryLock(30000);
    
    if (!e || !e.postData) {
      Logger.log('❌ No data received');
      return createResponse({ error: 'No data received' });
    }
    
    // ✅ CORRIGIDO: Google Apps Script Web Apps não passa query params em e.parameter
    // Precisamos extrair da URL ou aceitar sem validação de secret
    Logger.log('🔍 e.parameter: ' + JSON.stringify(e.parameter));
    Logger.log('🔍 e.queryString: ' + e.queryString);
    
    // Extrair secret da queryString manualmente
    let receivedSecret = '';
    if (e.queryString) {
      const params = e.queryString.split('&');
      for (let param of params) {
        const [key, value] = param.split('=');
        if (key === 'secret') {
          receivedSecret = decodeURIComponent(value);
          break;
        }
      }
    }
    
    Logger.log('🔑 Received secret: ' + (receivedSecret ? 'YES' : 'NO'));
    Logger.log('🔑 Secret value: ' + receivedSecret);
    
    if (receivedSecret !== SYNC_SECRET) {
      Logger.log('❌ Unauthorized - secret mismatch');
      Logger.log('❌ Expected: ' + SYNC_SECRET);
      Logger.log('❌ Received: ' + receivedSecret);
      return createResponse({ error: 'Unauthorized' });
    }
    
    const data = JSON.parse(e.postData.contents);
    Logger.log('📥 Received from Supabase: ' + JSON.stringify(data));
    
    const sheet = SpreadsheetApp.getActiveSpreadsheet().getSheets()[0];
    
    if (data.action === 'update' || data.action === 'insert') {
      updateProductInSheet(sheet, data.product);
    } else if (data.action === 'delete') {
      deleteProductFromSheet(sheet, data.product.codigo);
    }
    
    Logger.log('✅ Update completed successfully');
    return createResponse({ success: true, action: data.action });
    
  } catch (error) {
    Logger.log('❌ Error: ' + error);
    return createResponse({ error: error.toString() });
  } finally {
    lock.releaseLock();
  }
}

function updateProductInSheet(sheet, product) {
  const values = sheet.getDataRange().getValues();
  const headers = values[0];
  
  const colCodigo = headers.indexOf('CÓDIGO');
  const colDescricao = headers.indexOf('DESCRIÇÃO');
  const colFabricante = headers.indexOf('FABRICANTE');
  const colEstoque = headers.indexOf('ESTOQUE');
  const colVlrUnit = headers.indexOf('VLR. UNIT');
  const colEan = headers.indexOf('CODIGO EAN');
  const colUnd = headers.indexOf('UND');
  const colClassFiscal = headers.indexOf('CLASS. FISCAL');
  
  Logger.log('Procurando codigo: ' + product.codigo);
  
  let rowIndex = -1;
  for (let i = 1; i < values.length; i++) {
    if (String(values[i][colCodigo]) === String(product.codigo)) {
      rowIndex = i + 1;
      break;
    }
  }
  
  if (rowIndex > 0) {
    Logger.log('Atualizando linha ' + rowIndex);
    
    if (colDescricao >= 0) sheet.getRange(rowIndex, colDescricao + 1).setValue(cleanText(product.descricao));
    if (colFabricante >= 0) sheet.getRange(rowIndex, colFabricante + 1).setValue(cleanText(product.fabricante));
    if (colEstoque >= 0) sheet.getRange(rowIndex, colEstoque + 1).setValue(Math.floor(Number(product.estoque) || 0));
    if (colVlrUnit >= 0) sheet.getRange(rowIndex, colVlrUnit + 1).setValue(cleanPrice(product.vlr_unit));
    if (colEan >= 0) sheet.getRange(rowIndex, colEan + 1).setValue(cleanText(product.codigo_ean));
    if (colUnd >= 0) sheet.getRange(rowIndex, colUnd + 1).setValue(cleanText(product.und) || 'UN');
    if (colClassFiscal >= 0) sheet.getRange(rowIndex, colClassFiscal + 1).setValue(cleanText(product.class_fiscal));
    
    Logger.log('Produto atualizado');
  } else {
    Logger.log('Produto nao encontrado: ' + product.codigo);
  }
}

function createResponse(data) {
  return ContentService.createTextOutput(JSON.stringify(data))
    .setMimeType(ContentService.MimeType.JSON);
}
function testDoPost() {
  const mockEvent = {
    postData: {
      contents: JSON.stringify({
        action: 'update',
        product: {
          codigo: '2555',
          descricao: 'NUTRI RD 2.0 BAU TP 200ML',
          estoque: 150,
          vlr_unit: 10.50,
          fabricante: 'Teste'
        }
      })
    },
    parameter: {
      'x-sync-secret': 'SuevitSync2026!SecureKey#Farma'
    }
  };
  
  const result = doPost(mockEvent);
  Logger.log('Resultado: ' + result.getContent());
}
function debugLastExecution() {
  const sheet = SpreadsheetApp.getActiveSpreadsheet().getSheets()[0];
  
  // Testar manualmente
  const mockEvent = {
    postData: {
      contents: JSON.stringify({
        action: 'update',
        product: {
          codigo: '2555',
          descricao: 'NUTRI RD 2.0 BAU TP 200ML',
          estoque: 350,
          vlr_unit: 10.50,
          fabricante: 'Teste'
        }
      })
    },
    parameter: {
      'x-sync-secret': 'SuevitSync2026!SecureKey#Farma'
    }
  };
  
  // Chamar doPost
  const result = doPost(mockEvent);
  
  // Escrever resultado na célula A1
  sheet.getRange('A1').setValue('DEBUG: ' + Logger.getLog());
  
  SpreadsheetApp.getUi().alert('Teste concluído! Veja a célula A1');
}
function testUpdateRow() {
  const sheet = SpreadsheetApp.getActiveSpreadsheet().getSheets()[0];
  const product = {
    codigo: '2555',
    descricao: 'NUTRI RD 2.0 BAU TP 200ML',
    estoque: 700,
    vlr_unit: 33.83,
    fabricante: 'NUTRIMED'
  };
  
  Logger.log('🔍 Iniciando teste...');
  updateProductInSheet(sheet, product);
  Logger.log('✅ Teste concluído! Verifique linha 770');
  
  SpreadsheetApp.getUi().alert('Teste concluído! Veja a linha 770');
}
function debugFindProduct() {
  const sheet = SpreadsheetApp.getActiveSpreadsheet().getSheets()[0];
  const values = sheet.getDataRange().getValues();
  const headers = values[0];
  
  const colCodigo = headers.indexOf('CÓDIGO');
  
  Logger.log('🔍 Coluna CÓDIGO está na posição: ' + colCodigo);
  Logger.log('🔍 Procurando código: 2555');
  
  // Mostrar os primeiros 10 códigos
  Logger.log('📋 Primeiros códigos encontrados:');
  for (let i = 1; i < Math.min(11, values.length); i++) {
    const codigo = values[i][colCodigo];
    Logger.log(`  Linha ${i+1}: [${codigo}] tipo: ${typeof codigo}`);
  }
  
  // Procurar especificamente o 2555
  Logger.log('🔎 Procurando especificamente 2555...');
  for (let i = 1; i < values.length; i++) {
    const codigo = values[i][colCodigo];
    if (String(codigo).includes('2555')) {
      Logger.log(`✅ ENCONTRADO na linha ${i+1}: [${codigo}] tipo: ${typeof codigo}`);
    }
  }
  
  SpreadsheetApp.getUi().alert('Debug concluído! Veja os logs');
}
function debugHeaders() {
  const sheet = SpreadsheetApp.getActiveSpreadsheet().getSheets()[0];
  const headers = sheet.getRange(1, 1, 1, sheet.getLastColumn()).getValues()[0];
  
  Logger.log('📋 TODOS OS CABEÇALHOS DA PLANILHA:');
  for (let i = 0; i < headers.length; i++) {
    Logger.log(`  Coluna ${i}: [${headers[i]}]`);
  }
  
  SpreadsheetApp.getUi().alert('Headers listados! Veja os logs');
}
function findValue2555() {
  const sheet = SpreadsheetApp.getActiveSpreadsheet().getSheets()[0];
  const data = sheet.getDataRange().getValues();
  const headers = data[0];
  
  Logger.log('🔎 Procurando valor 2555 em TODAS as colunas...');
  
  for (let i = 1; i < data.length; i++) {
    for (let j = 0; j < data[i].length; j++) {
      const value = String(data[i][j]);
      if (value.includes('2555')) {
        Logger.log(`✅ ENCONTRADO na linha ${i+1}, coluna ${j} (${headers[j]}): [${data[i][j]}]`);
      }
    }
  }
  
  SpreadsheetApp.getUi().alert('Busca concluída! Veja os logs');
}
function fixHeader() {
  const sheet = SpreadsheetApp.getActiveSpreadsheet().getSheets()[0];
  sheet.getRange('A1').setValue('CÓDIGO');
  SpreadsheetApp.getUi().alert('Cabeçalho corrigido! A célula A1 agora tem "CÓDIGO"');
}
function testSyncSingle() {
  const sheet = SpreadsheetApp.getActiveSpreadsheet().getSheets()[0];
  Logger.log('🧪 Testando sincronização da linha 770...');
  syncSingleRow(sheet, 770);
}