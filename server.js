const fs = require('fs');
const venom = require('venom-bot');
const express = require('express');
const bodyParser = require('body-parser');

const app = express();
app.use(bodyParser.json());

const TOKEN = 'E8t4t5yxuRgP9n3xWaBQbHfKJZCvLmNsTqVuXy2z45a7d9FgHiJkL0MnOpQrStUv';
const BROWSER_PATH = '/usr/bin/google-chrome-stable';

if (!fs.existsSync(BROWSER_PATH)) {
  console.warn(`WARNING: No se encontró el ejecutable en ${BROWSER_PATH}. Asegurate de instalar Chrome/Chromium o ajustar BROWSER_PATH.`);
}

venom
  .create(
    'session1',
    undefined,
    (statusSession) => {
      console.log('Status Session:', statusSession);
    },
    {
      headless: true,
      useChrome: true,
      browserPathExecutable: BROWSER_PATH,
      args: [
        '--no-sandbox',
        '--disable-setuid-sandbox',
        '--disable-dev-shm-usage',
        '--disable-accelerated-2d-canvas',
        '--no-first-run',
        '--no-zygote',
        '--single-process',
        '--disable-gpu'
      ]
    }
  )
  .then((client) => {
    console.log('✅ Cliente Venom listo y conectado a WhatsApp');

    app.post('/send-message', async (req, res) => {
      const { token, number, message } = req.body;
      if (token !== TOKEN) return res.status(401).json({ error: 'Token inválido' });
      if (!number || !message) return res.status(400).json({ error: 'Faltan parámetros' });

      try {
        await client.sendText(`${number}@c.us`, message);
        res.json({ status: 'Mensaje enviado' });
      } catch (err) {
        res.status(500).json({ error: 'Error enviando mensaje', details: err.message });
      }
    });

    app.listen(8002, () => {
      console.log('🌐 Servidor API REST Venom corriendo en puerto 8002');
    });
  })
  .catch((err) => {
    console.error('❌ Error inicializando Venom:', err);
  });
