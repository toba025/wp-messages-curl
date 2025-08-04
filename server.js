const venom = require('venom-bot');
const express = require('express');
const bodyParser = require('body-parser');

const app = express();
const PORT = 8002;

app.use(bodyParser.json());

let client;

venom
    .create(
        'session1',
        (base64Qr, asciiQR) => {
          console.log('QR RECEIVED', asciiQR);
        },
        undefined,
        {
          useChrome: true,
          headless: true,
          disableSpins: true,
          disableWelcome: true,
          logQR: true,
          browserArgs: ['--no-sandbox', '--disable-setuid-sandbox'],
        }
    )
    .then((clientInstance) => {
      client = clientInstance;
      console.log('✅ Cliente Venom listo');
    })
    .catch((error) => {
      console.error('❌ Error al crear cliente Venom:', error);
    });

app.post('/sendText', async (req, res) => {
  const { to, text } = req.body;

  if (!client) {
    return res.status(503).json({ success: false, message: 'Cliente no iniciado' });
  }
  if (!to || !text) {
    return res.status(400).json({ success: false, message: 'Faltan parámetros to o text' });
  }

  try {
    await client.sendText(to, text);
    res.json({ success: true, message: 'Mensaje enviado' });
  } catch (err) {
    res.status(500).json({ success: false, message: 'Error enviando mensaje', error: err.toString() });
  }
});

app.listen(PORT, () => {
  console.log(`Servidor API REST Venom corriendo en puerto ${PORT}`);
});
