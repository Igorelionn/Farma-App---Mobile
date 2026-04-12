// Script do Google Apps Script para receber atualizações do Supabase
// Cole este código em: Extensions > Apps Script no Google Sheet

const SYNC_SECRET = 'SEU_SYNC_SECRET_AQUI'; // Mesmo valor da variável SYNC_SECRET no Supabase
const SHEET_NAME = 'Produtos'; // Nome da aba com os produtos

function doPost(e) {
  const lock = LockService.getScriptLock();
  
  try {
    // Aguardar até 30 segundos para obter o lock
    lock.tryLock(30000);
    
    if (!e || !e.postData) {
      return createResponse({ error: 'No data received' }, 400);
    }
    
    // Verificar secret para segurança
    const receivedSecret = e.parameter['x-sync-secret'] || 
                          (e.headers && e.headers['x-sync-secret']);
    
    if (receivedSecret !== SYNC_SECRET) {
      Logger.log('Unauthorized request - invalid secret');
      return createResponse({ error: 'Unauthorized' }, 401);
    }
    
    const data = JSON.parse(e.postData.contents);
    Logger.log('Received data: ' + JSON.stringify(data));
    
    const sheet = SpreadsheetApp.getActiveSpreadsheet().getSheetByName(SHEET_NAME);
    if (!sheet) {
      return createResponse({ error: 'Sheet not found: ' + SHEET_NAME }, 404);
    }
    
    const action = data.action;
    const product = data.product;
    
    if (action === 'update' || action === 'insert') {
      handleUpdateOrInsert(sheet, product);
    } else if (action === 'delete') {
      handleDelete(sheet, product.codigo);
    }
    
    return createResponse({ 
      success: true, 
      action: action,
      codigo: product.codigo 
    });
    
  } catch (error) {
    Logger.log('Error: ' + error.toString());
    return createResponse({ error: error.toString() }, 500);
    
  } finally {
    lock.releaseLock();
  }
}

function handleUpdateOrInsert(sheet, product) {
  const codigo = product.codigo;
  const dataRange = sheet.getDataRange();
  const values = dataRange.getValues();
  
  // Encontrar a coluna de cada campo (header na linha 1)
  const headers = values[0];
  const colCodigo = headers.indexOf('CÓDIGO') + 1;
  const colDescricao = headers.indexOf('DESCRIÇÃO') + 1;
  const colFabricante = headers.indexOf('FABRICANTE') + 1;
  const colEstoque = headers.indexOf('ESTOQUE') + 1;
  const colVlrUnit = headers.indexOf('VLR. UNIT') + 1;
  const colCodigoEan = headers.indexOf('CÓDIGO EAN') + 1;
  const colUnd = headers.indexOf('UND') + 1;
  const colClassFiscal = headers.indexOf('CLASS.FISCAL') + 1;
  const colDisponivel = headers.indexOf('DISPONÍVEL') + 1;
  const colCategoria = headers.indexOf('CATEGORIA') + 1;
  
  // Procurar linha existente
  let rowIndex = -1;
  for (let i = 1; i < values.length; i++) {
    if (values[i][colCodigo - 1] === codigo) {
      rowIndex = i + 1; // +1 porque getRange é 1-indexed
      break;
    }
  }
  
  if (rowIndex > 0) {
    // Atualizar linha existente
    Logger.log('Updating row ' + rowIndex + ' for codigo: ' + codigo);
    
    if (colDescricao > 0) sheet.getRange(rowIndex, colDescricao).setValue(product.descricao || '');
    if (colFabricante > 0) sheet.getRange(rowIndex, colFabricante).setValue(product.fabricante || '');
    if (colEstoque > 0) sheet.getRange(rowIndex, colEstoque).setValue(product.estoque || 0);
    if (colVlrUnit > 0) sheet.getRange(rowIndex, colVlrUnit).setValue(product.vlr_unit || 0);
    if (colCodigoEan > 0) sheet.getRange(rowIndex, colCodigoEan).setValue(product.codigo_ean || '');
    if (colUnd > 0) sheet.getRange(rowIndex, colUnd).setValue(product.und || 'UN');
    if (colClassFiscal > 0) sheet.getRange(rowIndex, colClassFiscal).setValue(product.class_fiscal || '');
    if (colDisponivel > 0) sheet.getRange(rowIndex, colDisponivel).setValue(product.disponivel ? 'SIM' : 'NÃO');
    if (colCategoria > 0) sheet.getRange(rowIndex, colCategoria).setValue(product.categoria || 'Outros');
    
  } else {
    // Inserir nova linha
    Logger.log('Inserting new row for codigo: ' + codigo);
    
    const newRow = new Array(headers.length).fill('');
    if (colCodigo > 0) newRow[colCodigo - 1] = product.codigo || '';
    if (colDescricao > 0) newRow[colDescricao - 1] = product.descricao || '';
    if (colFabricante > 0) newRow[colFabricante - 1] = product.fabricante || '';
    if (colEstoque > 0) newRow[colEstoque - 1] = product.estoque || 0;
    if (colVlrUnit > 0) newRow[colVlrUnit - 1] = product.vlr_unit || 0;
    if (colCodigoEan > 0) newRow[colCodigoEan - 1] = product.codigo_ean || '';
    if (colUnd > 0) newRow[colUnd - 1] = product.und || 'UN';
    if (colClassFiscal > 0) newRow[colClassFiscal - 1] = product.class_fiscal || '';
    if (colDisponivel > 0) newRow[colDisponivel - 1] = product.disponivel ? 'SIM' : 'NÃO';
    if (colCategoria > 0) newRow[colCategoria - 1] = product.categoria || 'Outros';
    
    sheet.appendRow(newRow);
  }
}

function handleDelete(sheet, codigo) {
  const dataRange = sheet.getDataRange();
  const values = dataRange.getValues();
  const headers = values[0];
  const colCodigo = headers.indexOf('CÓDIGO') + 1;
  
  // Encontrar e deletar linha
  for (let i = 1; i < values.length; i++) {
    if (values[i][colCodigo - 1] === codigo) {
      const rowIndex = i + 1;
      Logger.log('Deleting row ' + rowIndex + ' for codigo: ' + codigo);
      sheet.deleteRow(rowIndex);
      break;
    }
  }
}

function createResponse(data, statusCode = 200) {
  const response = ContentService.createTextOutput(JSON.stringify(data))
    .setMimeType(ContentService.MimeType.JSON);
    
  if (statusCode !== 200) {
    // Não há como definir status code no Apps Script, mas logamos
    Logger.log('Response status: ' + statusCode);
  }
  
  return response;
}

// Função de teste
function testWebhook() {
  const testPayload = {
    action: 'update',
    product: {
      codigo: 'TEST001',
      descricao: 'Produto de Teste',
      fabricante: 'Fabricante Teste',
      vlr_unit: 99.90,
      estoque: 100,
      codigo_ean: '7891234567890',
      und: 'UN',
      class_fiscal: '30049099',
      disponivel: true,
      categoria: 'Medicamentos'
    }
  };
  
  const mockEvent = {
    postData: {
      contents: JSON.stringify(testPayload)
    },
    parameter: {
      'x-sync-secret': SYNC_SECRET
    }
  };
  
  const result = doPost(mockEvent);
  Logger.log('Test result: ' + result.getContent());
}
