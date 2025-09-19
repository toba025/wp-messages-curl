const fs = require('fs');
const venom = require('venom-bot');
const express = require('express');
const bodyParser = require('body-parser');

const app = express();
app.use(bodyParser.json());

const TOKEN = 'E8t4t5yxuRgP9n3xWaBQbHfKJZCvLmNsTqVuXy2z45a7d9FgHiJkL0MnOpQrStUv';
const SESSION_NAME = 'session1';
const BROWSER_PATH = '/usr/bin/google-chrome-stable';

let client = null;
let isConnected = false;
let reconnectAttempts = 0;
const MAX_RECONNECT_ATTEMPTS = 5;

function log(message, type = 'INFO') {
  const timestamp = new Date().toISOString();
  console.log(`[${timestamp}] [${type}] ${message}`);
}

function checkChromeInstallation() {
  const possiblePaths = [
    '/usr/bin/google-chrome-stable',
    '/usr/bin/google-chrome',
    '/usr/bin/chromium-browser',
    '/usr/bin/chromium',
    '/snap/bin/chromium'
  ];

  for (const path of possiblePaths) {
    if (fs.existsSync(path)) {
      log(`✅ Chrome encontrado en: ${path}`);
      return path;
    }
  }

  log('⚠️  Chrome no encontrado en las rutas estándar', 'WARN');
  return '/usr/bin/google-chrome-stable';
}

async function checkConnectionStatus() {
  if (!client) {
    return false;
  }

  try {
    const status = await client.getConnectionState();
    return status === 'CONNECTED';
  } catch (error) {
    log(`Error verificando estado de conexión: ${error.message}`, 'ERROR');
    return false;
  }
}

async function initializeVenom() {
  try {
    log('🚀 Inicializando Venom-bot...');
    
    const browserPath = checkChromeInstallation();
    
    const venomOptions = {
      headless: true,
      useChrome: true,
      browserPathExecutable: browserPath,
      session: SESSION_NAME,
      disableWelcome: true,
      updatesLog: false,
      autoClose: 60000,
      createPathFileToken: false,
      args: [
        '--no-sandbox',
        '--disable-setuid-sandbox',
        '--disable-dev-shm-usage',
        '--disable-accelerated-2d-canvas',
        '--no-first-run',
        '--no-zygote',
        '--single-process',
        '--disable-gpu',
        '--disable-web-security',
        '--disable-features=VizDisplayCompositor',
        '--disable-extensions',
        '--disable-plugins',
        '--disable-images',
        '--disable-javascript-harmony-shipping',
        '--disable-background-timer-throttling',
        '--disable-backgrounding-occluded-windows',
        '--disable-renderer-backgrounding',
        '--disable-features=TranslateUI',
        '--disable-ipc-flooding-protection',
        '--user-agent=Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36'
      ]
    };

    client = await venom.create(
      SESSION_NAME,
      (statusSession) => {
        log(`📱 Estado de sesión: ${statusSession}`);
        
        if (statusSession === 'isLogged' || statusSession === 'qrReadSuccess' || statusSession === 'chatsAvailable') {
          isConnected = true;
          reconnectAttempts = 0;
          log('✅ WhatsApp conectado exitosamente');
        } else if (statusSession === 'notLogged' || statusSession === 'qrReadFail' || statusSession === 'autocloseCalled') {
          isConnected = false;
          log('❌ WhatsApp desconectado', 'ERROR');
        }
      },
      venomOptions
    );

    log('✅ Cliente Venom inicializado correctamente');
    return true;

  } catch (error) {
    log(`❌ Error inicializando Venom: ${error.message}`, 'ERROR');
    isConnected = false;
    return false;
  }
}

async function reconnect() {
  if (reconnectAttempts >= MAX_RECONNECT_ATTEMPTS) {
    log('❌ Máximo número de intentos de reconexión alcanzado', 'ERROR');
    return false;
  }

  reconnectAttempts++;
  log(`🔄 Intento de reconexión ${reconnectAttempts}/${MAX_RECONNECT_ATTEMPTS}`);
  
  await new Promise(resolve => setTimeout(resolve, 5000 * reconnectAttempts));
  
  return await initializeVenom();
}

async function sendMessage(number, message) {
  try {
    if (!client) {
      throw new Error('Cliente WhatsApp no está disponible');
    }

    const connectionStatus = await checkConnectionStatus();
    if (!connectionStatus) {
      log('⚠️  Cliente no conectado, intentando reconectar...', 'WARN');
      const reconnected = await reconnect();
      if (!reconnected) {
        throw new Error('No se pudo reconectar al WhatsApp');
      }
    }

    const cleanNumber = number.replace(/\D/g, ''); // Remover caracteres no numéricos
    if (cleanNumber.length < 10) {
      throw new Error('Número de teléfono inválido');
    }

    const formattedNumber = `${cleanNumber}@c.us`;
    
    log(`📤 Enviando mensaje a ${formattedNumber}`);
    
    const result = await client.sendText(formattedNumber, message);
    
    log(`✅ Mensaje enviado exitosamente a ${formattedNumber}`);
    return result;

  } catch (error) {
    log(`❌ Error enviando mensaje: ${error.message}`, 'ERROR');
    throw error;
  }
}

async function startServer() {
  const venomInitialized = await initializeVenom();
  
  if (!venomInitialized) {
    log('❌ No se pudo inicializar Venom. El servidor se iniciará sin WhatsApp.', 'ERROR');
  }

  app.post('/send-message', async (req, res) => {
    try {
      const { token, number, message } = req.body;
      
      if (token !== TOKEN) {
        return res.status(401).json({ error: 'Token inválido' });
      }
      
      if (!number || !message) {
        return res.status(400).json({ error: 'Faltan parámetros: number y message son requeridos' });
      }

      const result = await sendMessage(number, message);
      res.json({ 
        status: 'success', 
        message: 'Mensaje enviado exitosamente',
        result: result 
      });

    } catch (error) {
      log(`❌ Error en endpoint /send-message: ${error.message}`, 'ERROR');
      res.status(500).json({ 
        error: 'Error enviando mensaje', 
        details: error.message 
      });
    }
  });

  app.get('/status', async (req, res) => {
    try {
      const connectionStatus = await checkConnectionStatus();
      res.json({
        status: 'ok',
        whatsapp_connected: connectionStatus,
        server_time: new Date().toISOString()
      });
    } catch (error) {
      res.status(500).json({
        status: 'error',
        whatsapp_connected: false,
        error: error.message
      });
    }
  });

  app.listen(8002, () => {
    log('🌐 Servidor API REST iniciado en puerto 8002');
    log('📋 Endpoints disponibles:');
    log('  POST /send-message - Enviar mensaje de WhatsApp');
    log('  GET /status - Verificar estado del servidor');
  });
}

process.on('SIGINT', () => {
  log('🛑 Cerrando servidor...');
  if (client) {
    client.close();
  }
  process.exit(0);
});

startServer().catch(error => {
  log(`❌ Error fatal: ${error.message}`, 'ERROR');
  process.exit(1);
});
