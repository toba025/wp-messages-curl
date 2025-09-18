const venom = require('venom-bot');
const express = require('express');
const bodyParser = require('body-parser');

const app = express();
app.use(bodyParser.json());
const TOKEN = 'E8t4t5yxuRgP9n3xWaBQbHfKJZCvLmNsTqVuXy2z45a7d9FgHiJkL0MnOpQrStUv';


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

        client.onStateChange((state) => {
            console.log('Estado WhatsApp:', state);
            if (state === 'CONNECTED') clientReady = true;
            else clientReady = false;
        });

        console.log('✅ Cliente Venom listo y conectado a WhatsApp');
    })
    .catch((err) => {
        console.error('❌ Error inicializando Venom:', err);
    });

async function safeSendText(to, text) {
    if (!clientReady) throw new Error('Cliente no está listo');
    return await client.sendText(to, text);
}

app.post('/sendText', async (req, res) => {
    const apiToken = req.header('x-api-token');
    if (!apiToken || apiToken !== TOKEN) return res.status(401).json({ success: false, message: 'Token inválido' });

    const { to, text } = req.body || {};
    if (!to || !text) return res.status(400).json({ success: false, message: 'Faltan parámetros "to" o "text"' });

    try {
        await safeSendText(to, text);
        res.json({ success: true, message: 'Mensaje enviado' });
    } catch (err) {
        console.error('❌ Error enviando mensaje:', err);
        res.status(500).json({ success: false, message: 'Error enviando mensaje', error: err.toString() });
    }
});

app.listen(8002, () => console.log('🌐 Servidor API REST Venom corriendo en puerto 8002'));
