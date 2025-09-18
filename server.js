const venom = require('venom-bot');
const express = require('express');
const bodyParser = require('body-parser');

const app = express();
app.use(bodyParser.json());

const TOKEN = 'E8t4t5yxuRgP9n3xWaBQbHfKJZCvLmNsTqVuXy2z45a7d9FgHiJkL0MnOpQrStUv';

let client;
let clientReady = false;

async function safeSendText(client, to, text) {
    try {
        await client.waitForWAPI(10000);
        return await client.sendText(to, text);
    } catch (err) {
        console.error('❌ Error enviando mensaje de manera segura:', err);
        throw err;
    }
}

venom
    .create(
        'session1', 
        undefined, 
        (status) => {
            console.log('Status Session: ', status);
        }, 
        {
            headless: "new",
            useChrome: false,
            debug: false,
            logQR: true,
            browserArgs: ['--no-sandbox', '--disable-setuid-sandbox']
        }
    )
    .then((clientInstance) => {
        client = clientInstance;
        clientReady = true;
        console.log('✅ Cliente Venom listo y conectado a WhatsApp');
    })
    .catch((err) => {
        console.error('❌ Error inicializando Venom:', err);
    });

app.post('/sendText', async (req, res) => {
    const apiToken = req.header('x-api-token');
    if (!apiToken || apiToken !== TOKEN) {
        return res.status(401).json({ success: false, message: 'Token inválido o ausente' });
    }

    const { to, text } = req.body || {};

    if (!clientReady) {
        return res.status(503).json({ success: false, message: 'Cliente WhatsApp no listo aún' });
    }

    if (!to || !text) {
        return res.status(400).json({ success: false, message: 'Faltan parámetros "to" o "text"' });
    }

    try {
        await safeSendText(client, to, text);
        res.json({ success: true, message: 'Mensaje enviado' });
    } catch (err) {
        res.status(500).json({ success: false, message: 'Error enviando mensaje', error: err.toString() });
    }
});

const PORT = 8002;
app.listen(PORT, () => {
    console.log(`🌐 Servidor API REST Venom corriendo en puerto ${PORT}`);
});
