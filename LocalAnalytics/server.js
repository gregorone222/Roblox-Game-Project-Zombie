const http = require('http');
const fs = require('fs');
const path = require('path');
const port = 3000;

// Helper to handle body parsing
const getBody = (req) => {
    return new Promise((resolve, reject) => {
        let body = '';
        req.on('data', chunk => body += chunk.toString());
        req.on('end', () => {
            try {
                resolve(JSON.parse(body));
            } catch (e) {
                resolve({});
            }
        });
        req.on('error', reject);
    });
};

const logsDir = path.join(__dirname, 'logs');
if (!fs.existsSync(logsDir)) {
    fs.mkdirSync(logsDir);
}

const server = http.createServer(async (req, res) => {
    // CORS headers
    res.setHeader('Access-Control-Allow-Origin', '*');
    res.setHeader('Access-Control-Allow-Methods', 'POST, GET, OPTIONS');
    res.setHeader('Access-Control-Allow-Headers', 'Content-Type');

    if (req.method === 'OPTIONS') {
        res.writeHead(204);
        res.end();
        return;
    }

    if (req.method === 'POST' && req.url === '/log-error') {
        const body = await getBody(req);
        const { scriptName, message, stackTrace, logName } = body;

        let fileName = "";
        if (logName) {
            const safeName = logName.replace(/[^a-zA-Z0-9_\-]/g, '');
            fileName = `${safeName}.txt`;
        } else {
            const date = new Date().toISOString().split('T')[0];
            fileName = `error_log_${date}.txt`;
        }

        const logFile = path.join(logsDir, fileName);

        const logEntry = `[${new Date().toISOString()}] [${scriptName || 'Unknown'}] ${message}\nStack: ${stackTrace}\n----------------------------------\n`;

        fs.appendFile(logFile, logEntry, (err) => {
            if (err) {
                console.error("Failed to write log", err);
                res.writeHead(500);
                res.end("Error writing log");
                return;
            }
            console.log(`🚨 Error Logged from Roblox [${fileName}]: ${message}`);
            res.writeHead(200);
            res.end("Logged");
        });
        return;
    }

    if (req.method === 'GET' && req.url === '/config') {
        const configFile = path.join(__dirname, 'LiveConfig.json');
        if (fs.existsSync(configFile)) {
            res.setHeader('Content-Type', 'application/json');
            fs.createReadStream(configFile).pipe(res);
        } else {
            res.setHeader('Content-Type', 'application/json');
            res.end('{}');
        }
        return;
    }

    if (req.method === 'GET' && req.url === '/') {
        res.writeHead(200);
        res.end('Roblox Local Analytics Server Running');
        return;
    }

    res.writeHead(404);
    res.end('Not Found');
});

server.listen(port, () => {
    console.log(`🚀 Analytics Server listening on http://localhost:${port}`);
    console.log(`   - Logs will be saved to: ${logsDir}`);
});
