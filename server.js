const venom = require('venom-bot');
const express = require('express');
const bodyParser = require('body-parser');

const app = express();
const PORT = 8002;
const TOKEN = "E8t4t5yxuRgP9n3xWaBQbHfKJZCvLmNsTqVuXy2z45a7d9FgHiJkL0MnOpQrStUv";

app.use(bodyParser.json());

let client;
let clientReady = false;

async function initVenom() {
    console.log('🚀 Iniciando cliente Venom...');
    try {
        client = await venom.create(
            'session1',
            (base64Qr, asciiQR) => {
                console.log('QR recibido:\n', asciiQR);
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
        );

        console.log('✅ Cliente Venom creado, esperando conexión a WhatsApp...');
        await waitUntilConnected(client);
        clientReady = true;

        console.log('✅ WhatsApp Web listo para enviar mensajes');

        client.onStateChange((state) => {
            console.log('🔄 Estado WhatsApp:', state);
            if (state === 'CONFLICT' || state === 'UNPAIRED' || state === 'UNLAUNCHED') {
                console.log('⚠️ Estado problemático, reiniciando sesión...');
                clientReady = false;
                client.close();
                initVenom();
            }
        });

    } catch (err) {
        console.error('❌ Error al inicializar Venom:', err);
        setTimeout(initVenom, 5000);
    }
}

async function waitUntilConnected(clientInstance) {
    let connected = await clientInstance.isConnected();
    while (!connected) {
        console.log('⏳ Esperando conexión...');
        await new Promise(r => setTimeout(r, 2000));
        connected = await clientInstance.isConnected();
    }
}

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
        await client.sendText(to, text);
        res.json({ success: true, message: 'Mensaje enviado' });
    } catch (err) {
        console.error('❌ Error enviando mensaje:', err);
        res.status(500).json({ success: false, message: 'Error enviando mensaje', error: err.toString() });
    }
});

app.listen(PORT, () => {
    console.log(`🌐 Servidor API REST Venom corriendo en puerto ${PORT}`);
    initVenom();
});
