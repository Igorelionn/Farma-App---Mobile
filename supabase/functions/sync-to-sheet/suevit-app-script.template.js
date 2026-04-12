// ============================================================
// TEMPLATE: Google Apps Script - Webhook Receiver
// ============================================================
// INSTRUÇÕES:
// 1. Copie este arquivo para seu Google Apps Script
// 2. Configure as variáveis usando Script Properties:
//    - Vá em Project Settings > Script Properties
//    - Adicione: SUPABASE_URL, SYNC_SECRET
// 3. Deploy como Web App e copie a URL para GOOGLE_SHEET_WEBHOOK_URL
// ============================================================

// Configurações - USAR Script Properties Service
const SUPABASE_URL = PropertiesService.getScriptProperties().getProperty('SUPABASE_URL') || 'YOUR_SUPABASE_URL';
const SYNC_SECRET = PropertiesService.getScriptProperties().getProperty('SYNC_SECRET') || 'YOUR_SYNC_SECRET';
const EDGE_FUNCTION_URL = `${SUPABASE_URL}/functions/v1/sync-products`;

// Sincronização automática quando editar a planilha
function onEdit(e) {
  const sheet = e.source.getActiveSheet();
  const editedRow = e.range.getRow();
  
  if (editedRow === 1) return;
  
  Logger.log('Editado! Sincronizando...');
  syncToSupabase();
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
    
    for (let i = 1; i < data.length; i++) {
      const row = data[i];
      
      if (!row[descricaoIdx]) continue;
      
      products.push({
        codigo: String(row[codigoIdx] || ''),
        descricao: String(row[descricaoIdx] || ''),
        fabricante: String(row[fabricanteIdx] || ''),
        vlr_unit: Number(row[precoIdx]) || 0,
        estoque: Number(row[estoqueIdx]) || 0,
        codigo_ean: String(row[eanbkIdx] || ''),
        und: String(row[undIdx] || 'UN'),
        class_fiscal: String(row[classFiscalIdx] || ''),
      });
    }
    
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
    
    Logger.log(`Sincronização completa! ${successCount} produtos enviados`);
    return successCount;
    
  } catch (error) {
    Logger.log(`Erro: ${error.message}`);
    return 0;
  }
}

function testSync() {
  const count = syncToSupabase();
  Logger.log(`Teste concluído: ${count} produtos sincronizados`);
}

// Webhook receiver - recebe atualizações do Supabase
function doPost(e) {
  const lock = LockService.getScriptLock();
  
  try {
    lock.tryLock(30000);
    
    if (!e || !e.postData) {
      Logger.log('❌ No data received');
      return createResponse({ error: 'No data received' });
    }
    
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
    
    if (receivedSecret !== SYNC_SECRET) {
      Logger.log('❌ Unauthorized - secret mismatch');
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
    
    if (colDescricao >= 0) sheet.getRange(rowIndex, colDescricao + 1).setValue(product.descricao || '');
    if (colFabricante >= 0) sheet.getRange(rowIndex, colFabricante + 1).setValue(product.fabricante || '');
    if (colEstoque >= 0) sheet.getRange(rowIndex, colEstoque + 1).setValue(product.estoque || 0);
    if (colVlrUnit >= 0) sheet.getRange(rowIndex, colVlrUnit + 1).setValue(product.vlr_unit || 0);
    if (colEan >= 0) sheet.getRange(rowIndex, colEan + 1).setValue(product.codigo_ean || '');
    if (colUnd >= 0) sheet.getRange(rowIndex, colUnd + 1).setValue(product.und || 'UN');
    if (colClassFiscal >= 0) sheet.getRange(rowIndex, colClassFiscal + 1).setValue(product.class_fiscal || '');
    
    Logger.log('Produto atualizado');
  } else {
    Logger.log('Produto nao encontrado: ' + product.codigo);
  }
}

function createResponse(data) {
  return ContentService.createTextOutput(JSON.stringify(data))
    .setMimeType(ContentService.MimeType.JSON);
}
