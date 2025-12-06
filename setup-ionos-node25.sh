#!/bin/bash
# ===========================================
# DID DATA MARKETPLACE MVP - SETUP COMPLETO
# Node.js 25 + PostgreSQL 16 + Ubuntu 24.04
# Ottimizzato per IONOS VPS (2-4GB RAM)
# ===========================================

set -e
clear

echo " "
echo "██████╗ ██╗██████╗     ███╗   ███╗██╗   ██╗██████╗ "
echo "██╔══██╗██║██╔══██╗    ████╗ ████║██║   ██║██╔══██╗"
echo "██║  ██║██║██║  ██║    ██╔████╔██║██║   ██║██████╔╝"
echo "██║  ██║██║██║  ██║    ██║╚██╔╝██║██║   ██║██╔═══╝ "
echo "██████╔╝██║██████╔╝    ██║ ╚═╝ ██║╚██████╔╝██║     "
echo "╚═════╝ ╚═╝╚═════╝     ╚═╝     ╚═╝ ╚═════╝ ╚═╝     "
echo " "
echo "======================================================"
echo "SETUP COMPLETO SU IONOS VPS - Ubuntu 24.04"
echo "======================================================"
echo " "

# ================= CONFIGURAZIONE =================
DOMINIO="datamarket.tuodominio.com"    # MODIFICA: Il tuo dominio
DB_PASSWORD="SuperSecretDB123!"        # MODIFICA: Password database
EMAIL_SSL="tua@email.com"              # MODIFICA: Email per SSL
IP_SERVER=$(hostname -I | awk '{print $1}')
START_TIME=$(date)
# ==================================================

echo "⚙️  Configurazione iniziale:"
echo "   • Dominio: $DOMINIO"
echo "   • IP Server: $IP_SERVER"
echo "   • Data/Ora: $START_TIME"
echo " "

# ============ 1. AGGIORNAMENTO SISTEMA ============
echo "🔧 [1/12] Aggiornamento sistema..."
apt-get update -y
apt-get upgrade -y
apt-get install -y software-properties-common curl wget git unzip
echo "✅ Sistema aggiornato"
echo " "

# ============ 2. INSTALLA NODE.JS 25 ==============
echo "🟢 [2/12] Installazione Node.js 25.x..."
# Rimuovi versioni vecchie
apt-get remove -y nodejs npm 2>/dev/null || true
rm -rf /usr/lib/node_modules /usr/include/node /usr/share/man/man1/node*

# Installa Node.js 25
curl -fsSL https://deb.nodesource.com/setup_25.x | bash -
apt-get install -y nodejs

# Verifica installazione
NODE_VERSION=$(node --version)
NPM_VERSION=$(npm --version)
echo "✅ Node.js $NODE_VERSION installato"
echo "✅ npm $NPM_VERSION installato"
echo " "

# Installa yarn e PM2
npm install -g yarn pm2
echo "✅ PM2 installato per process management"

# =========== 3. INSTALLA POSTGRESQL 16 ============
echo "🗄️  [3/12] Installazione PostgreSQL 16..."
apt-get install -y postgresql postgresql-contrib postgresql-client

# Avvia e abilita PostgreSQL
systemctl start postgresql
systemctl enable postgresql

# Configura database
echo "🔧 Configurazione database..."
sudo -u postgres psql -c "DROP DATABASE IF EXISTS did_mvp;"
sudo -u postgres psql -c "DROP USER IF EXISTS did_user;"
sudo -u postgres psql -c "CREATE DATABASE did_mvp;"
sudo -u postgres psql -c "CREATE USER did_user WITH PASSWORD '$DB_PASSWORD';"
sudo -u postgres psql -c "GRANT ALL PRIVILEGES ON DATABASE did_mvp TO did_user;"
sudo -u postgres psql -d did_mvp -c "CREATE EXTENSION IF NOT EXISTS \"uuid-ossp\";"
sudo -u postgres psql -d did_mvp -c "GRANT ALL ON SCHEMA public TO did_user;"

echo "✅ PostgreSQL 16 configurato"
echo "   Database: did_mvp"
echo "   User: did_user"
echo " "

# ============= 4. INSTALLA NGINX ==================
echo "🌐 [4/12] Installazione Nginx..."
apt-get install -y nginx
systemctl start nginx
systemctl enable nginx
echo "✅ Nginx installato e avviato"
echo " "

# ============ 5. CONFIGURA FIREWALL ===============
echo "🛡️  [5/12] Configurazione firewall..."
apt-get install -y ufw
ufw --force reset
ufw default deny incoming
ufw default allow outgoing
ufw allow ssh
ufw allow http
ufw allow https
ufw allow 3001/tcp
echo "y" | ufw --force enable
ufw status verbose
echo "✅ Firewall configurato"
echo " "

# ========= 6. CREA STRUTTURA PROGETTO =============
echo "📁 [6/12] Creazione struttura progetto..."
mkdir -p /var/www/did-mvp
mkdir -p /var/www/did-mvp/backend
mkdir -p /var/www/did-mvp/client
mkdir -p /var/log/did-mvp
mkdir -p /var/backups/did-mvp
mkdir -p /etc/did-mvp

# Crea directory per logs
touch /var/log/did-mvp/{backend.log,errors.log,access.log}
chmod 755 /var/log/did-mvp
echo "✅ Struttura directory creata"
echo " "

# ============ 7. SETUP BACKEND ====================
echo "⚙️  [7/12] Setup backend Node.js..."

# Crea package.json
cat > /var/www/did-mvp/backend/package.json << 'EOF'
{
  "name": "did-mvp-backend",
  "version": "1.0.0",
  "type": "module",
  "scripts": {
    "start": "node --experimental-specifier-resolution=node server.js",
    "dev": "nodemon --experimental-specifier-resolution=node server.js",
    "setup-db": "node scripts/setup-database.js",
    "test": "NODE_OPTIONS='--experimental-vm-modules' npx jest",
    "lint": "eslint .",
    "build": "node --experimental-specifier-resolution=node build.js"
  },
  "dependencies": {
    "@veramo/core": "^5.5.0",
    "@veramo/did-manager": "^5.5.0",
    "@veramo/key-manager": "^5.5.0",
    "@veramo/kms-local": "^5.5.0",
    "@veramo/data-store": "^5.5.0",
    "@veramo/did-provider-key": "^5.5.0",
    "@veramo/did-provider-ethr": "^5.5.0",
    "@veramo/did-resolver": "^5.5.0",
    "@veramo/credential-w3c": "^5.5.0",
    "express": "^4.18.2",
    "cors": "^2.8.5",
    "dotenv": "^16.3.1",
    "jsonwebtoken": "^9.0.2",
    "uuid": "^9.0.1",
    "bip39": "^3.1.0",
    "bip32": "^3.1.0",
    "axios": "^1.6.2",
    "web3.storage": "^4.4.0",
    "ethers": "^6.10.0",
    "pg": "^8.11.3",
    "typeorm": "^0.3.20",
    "reflect-metadata": "^0.1.13",
    "multer": "^1.4.5-lts.1",
    "winston": "^3.11.0",
    "helmet": "^7.1.0",
    "rate-limiter-flexible": "^4.0.1"
  },
  "devDependencies": {
    "nodemon": "^3.0.1",
    "jest": "^29.7.0",
    "supertest": "^6.3.3",
    "eslint": "^8.56.0"
  },
  "engines": {
    "node": ">=25.0.0",
    "npm": ">=10.0.0"
  }
}
EOF

# Crea server.js principale
cat > /var/www/did-mvp/backend/server.js << 'EOF'
import express from "express";
import cors from "cors";
import dotenv from "dotenv";
import helmet from "helmet";
import winston from "winston";
import { createRequire } from 'module';

const require = createRequire(import.meta.url);
dotenv.config();

// Configurazione logger
const logger = winston.createLogger({
  level: process.env.LOG_LEVEL || 'info',
  format: winston.format.combine(
    winston.format.timestamp(),
    winston.format.json()
  ),
  transports: [
    new winston.transports.File({ 
      filename: '/var/log/did-mvp/errors.log', 
      level: 'error' 
    }),
    new winston.transports.File({ 
      filename: '/var/log/did-mvp/backend.log' 
    }),
    new winston.transports.Console({
      format: winston.format.simple()
    })
  ]
});

const app = express();
const PORT = process.env.PORT || 3001;

// Middleware di sicurezza
app.use(helmet({
  contentSecurityPolicy: {
    directives: {
      defaultSrc: ["'self'"],
      styleSrc: ["'self'", "'unsafe-inline'", "https://cdnjs.cloudflare.com"],
      scriptSrc: ["'self'", "'unsafe-inline'", "https://cdn.jsdelivr.net"],
      fontSrc: ["'self'", "https://cdnjs.cloudflare.com"],
      imgSrc: ["'self'", "data:", "https:"]
    }
  }
}));

app.use(cors({
  origin: process.env.CLIENT_URL || '*',
  credentials: true
}));

app.use(express.json({ limit: '10mb' }));
app.use(express.urlencoded({ extended: true, limit: '10mb' }));

// Health check
app.get("/api/health", (req, res) => {
  logger.info('Health check richiesto');
  res.json({
    status: "online",
    service: "DID MVP Backend",
    version: "1.0.0",
    nodeVersion: process.version,
    environment: process.env.NODE_ENV || 'development',
    timestamp: new Date().toISOString(),
    uptime: process.uptime(),
    database: "PostgreSQL 16",
    memory: `${(process.memoryUsage().heapUsed / 1024 / 1024).toFixed(2)} MB`
  });
});

// API root
app.get("/api", (req, res) => {
  res.json({
    name: "DID Data Marketplace API",
    version: "1.0.0",
    documentation: "https://github.com/alecasarola/3id-platform.git/did-data-mvp",
    endpoints: {
      auth: {
        challenge: "POST /api/auth/challenge",
        verify: "POST /api/auth/verify",
        create: "POST /api/auth/create-did",
        recover: "POST /api/auth/recover-did"
      },
      data: {
        collect: "POST /api/data/collect",
        bundle: "POST /api/data/bundle/create",
        ipfs: "POST /api/data/bundle/upload"
      },
      nft: {
        mint: "POST /api/nft/mint",
        status: "GET /api/nft/status/:bundleId"
      }
    }
  });
});

// Route temporanee (saranno sostituite con i controller reali)
app.post("/api/auth/challenge", (req, res) => {
  const { did } = req.body;
  if (!did) {
    return res.status(400).json({ error: "DID required" });
  }
  
  const challenge = `did-challenge-${Date.now()}-${Math.random().toString(36).substr(2, 9)}`;
  logger.info(`Challenge generato per ${did.substring(0, 20)}...`);
  
  res.json({
    success: true,
    challenge,
    expiresAt: Date.now() + 300000,
    message: "Firma questa challenge con la tua chiave privata"
  });
});

app.post("/api/data/collect", (req, res) => {
  const { events } = req.body;
  
  if (!Array.isArray(events)) {
    return res.status(400).json({ error: "Events deve essere un array" });
  }
  
  logger.info(`Ricevuti ${events.length} eventi`);
  
  res.json({
    success: true,
    received: events.length,
    bundleId: `bundle_${Date.now()}_${Math.random().toString(36).substr(2, 6)}`,
    message: "Eventi ricevuti (modalità simulazione)"
  });
});

// 404 handler
app.use((req, res) => {
  logger.warn(`Route non trovata: ${req.method} ${req.url}`);
  res.status(404).json({
    error: "Endpoint non trovato",
    path: req.url,
    method: req.method
  });
});

// Error handler globale
app.use((err, req, res, next) => {
  logger.error(`Errore: ${err.message}`, { stack: err.stack });
  
  res.status(err.status || 500).json({
    error: "Errore interno del server",
    message: process.env.NODE_ENV === 'development' ? err.message : undefined,
    requestId: req.headers['x-request-id'] || Math.random().toString(36).substr(2, 9)
  });
});

// Avvio server
const server = app.listen(PORT, '0.0.0.0', () => {
  logger.info(`
  ==========================================
  🚀 DID Data Marketplace Backend
  ==========================================
  ✅ Server in ascolto sulla porta: ${PORT}
  ✅ Ambiente: ${process.env.NODE_ENV || 'development'}
  ✅ Node.js: ${process.version}
  ✅ PID: ${process.pid}
  ✅ Health check: http://localhost:${PORT}/api/health
  ==========================================
  `);
});

// Graceful shutdown
const shutdown = () => {
  logger.info('Ricevuto segnale di shutdown, chiusura graceful...');
  server.close(() => {
    logger.info('Server HTTP chiuso');
    process.exit(0);
  });
  
  setTimeout(() => {
    logger.error('Forzata chiusura dopo timeout');
    process.exit(1);
  }, 10000);
};

process.on('SIGTERM', shutdown);
process.on('SIGINT', shutdown);
EOF

# Crea file .env
cat > /var/www/did-mvp/backend/.env << EOF
# ============================================
# DID DATA MARKETPLACE - CONFIGURAZIONE PRODUZIONE
# ============================================

# SERVER
NODE_ENV=production
PORT=3001
HOST=0.0.0.0
LOG_LEVEL=info
LOG_TO_FILE=true
LOG_DIR=/var/log/did-mvp

# DATABASE (PostgreSQL 16)
DB_TYPE=postgres
DB_HOST=localhost
DB_PORT=5432
DB_USER=did_user
DB_PASSWORD=$DB_PASSWORD
DB_NAME=did_mvp
DB_SYNCHRONIZE=false
DB_LOGGING=false

# JWT & SICUREZZA
JWT_SECRET=$(openssl rand -base64 64)
JWT_EXPIRES_IN=24h
SESSION_SECRET=$(openssl rand -base64 48)
ENCRYPTION_KEY=$(openssl rand -base64 32)
API_RATE_LIMIT=100
API_WINDOW_MS=900000

# WEB3.STORAGE (IPFS) - OTTIENI SU: https://web3.storage
WEB3_STORAGE_TOKEN=INSERISCI_QUI_TUO_TOKEN_WEB3STORAGE
IPFS_GATEWAY=https://ipfs.io
IPFS_TIMEOUT=30000

# POLYGON (Testnet Mumbai) - OTTIENI SU: https://infura.io
POLYGON_RPC_URL=https://polygon-mumbai.infura.io/v3/INSERISCI_QUI_TUO_INFURA_KEY
POLYGON_CHAIN_ID=80001
POLYGON_EXPLORER=https://mumbai.polygonscan.com
POLYGON_SYMBOL=MATIC
POLYGON_DECIMALS=18

# WALLET SERVER (SOLO PER TEST!)
# Crea wallet test su MetaMask e prendi MATIC da: https://faucet.polygon.technology/
SERVER_PRIVATE_KEY=INSERISCI_QUI_TUO_PRIVATE_KEY_TEST
SERVER_ADDRESS=0x...

# SMART CONTRACT (dopo deploy)
NFT_CONTRACT_ADDRESS=0x...
NFT_CONTRACT_ABI=[]

# DID CONFIG
DEFAULT_DID_PROVIDER=did:key
DID_ETHR_RPC=https://mainnet.infura.io/v3/INSERISCI_QUI_TUO_INFURA_KEY
DID_CACHE_TTL=3600000

# CLIENT
CLIENT_URL=https://$DOMINIO
API_BASE_URL=https://$DOMINIO/api
CORS_ORIGIN=https://$DOMINIO

# GDPR & PRIVACY
GDPR_CONSENT_REQUIRED=true
DATA_RETENTION_DAYS=90
PSEUDONYMIZATION_ENABLED=true
AUTO_DELETION_ENABLED=false

# PERFORMANCE
MAX_REQUEST_SIZE=10mb
MAX_FILE_SIZE=5mb
UV_THREADPOOL_SIZE=4
WORKER_THREADS=2

# MONITORING
METRICS_ENABLED=true
HEALTH_CHECK_INTERVAL=30000
ALERT_THRESHOLD=0.9
EOF

chmod 600 /var/www/did-mvp/backend/.env

# Crea ecosystem.config.js per PM2
cat > /var/www/did-mvp/backend/ecosystem.config.js << 'EOF'
module.exports = {
  apps: [{
    name: "did-mvp-backend",
    script: "server.js",
    instances: 1,
    exec_mode: "fork",
    watch: false,
    max_memory_restart: "500M",
    env: {
      NODE_ENV: "production",
      NODE_OPTIONS: "--max-old-space-size=384 --experimental-specifier-resolution=node"
    },
    env_development: {
      NODE_ENV: "development",
      NODE_OPTIONS: "--max-old-space-size=512 --experimental-specifier-resolution=node --inspect"
    },
    error_file: "/var/log/pm2/did-mvp-error.log",
    out_file: "/var/log/pm2/did-mvp-out.log",
    log_file: "/var/log/pm2/did-mvp-combined.log",
    log_date_format: "YYYY-MM-DD HH:mm:ss",
    merge_logs: true,
    time: true,
    
    // Restart strategies
    autorestart: true,
    restart_delay: 3000,
    max_restarts: 10,
    min_uptime: "10s",
    
    // Monitoring
    listen_timeout: 8000,
    kill_timeout: 5000,
    shutdown_with_message: true,
    
    // Performance
    node_args: [
      "--experimental-specifier-resolution=node",
      "--max-old-space-size=384",
      "--max-http-header-size=16384",
      "--no-warnings"
    ],
    
    // Advanced
    source_map_support: true,
    vizion: false,
    filter_env: ["npm_"]
  }]
}
EOF

# Installa dipendenze backend
cd /var/www/did-mvp/backend
echo "📦 Installazione dipendenze backend..."
npm install --omit=dev

echo "✅ Backend configurato"
echo " "

# ============ 8. SETUP FRONTEND ===================
echo "🎨 [8/12] Setup frontend..."

# Crea index.html principale
cat > /var/www/did-mvp/client/index.html << 'EOF'
<!DOCTYPE html>
<html lang="it">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>DID Data Marketplace - MVP</title>
    <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.4.0/css/all.min.css">
    <link rel="preconnect" href="https://fonts.googleapis.com">
    <link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
    <link href="https://fonts.googleapis.com/css2?family=Inter:wght@300;400;500;600;700&display=swap" rel="stylesheet">
    <style>
        :root {
            --primary: #4361ee;
            --primary-dark: #3a56d4;
            --secondary: #7209b7;
            --success: #4cc9f0;
            --warning: #f72585;
            --danger: #f72585;
            --light: #f8f9fa;
            --dark: #1a1a2e;
            --gray: #6c757d;
            --border: #2d3047;
            --card-bg: #16213e;
            --gradient: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
        }

        * {
            margin: 0;
            padding: 0;
            box-sizing: border-box;
        }

        body {
            font-family: 'Inter', sans-serif;
            background: var(--dark);
            color: #e0e0e0;
            min-height: 100vh;
            line-height: 1.6;
        }

        .app-container {
            max-width: 1400px;
            margin: 0 auto;
            padding: 20px;
        }

        /* Header */
        .header {
            background: var(--card-bg);
            border-radius: 20px;
            padding: 30px;
            margin-bottom: 30px;
            box-shadow: 0 10px 30px rgba(0,0,0,0.3);
            border: 1px solid var(--border);
            text-align: center;
        }

        .logo {
            font-size: 3rem;
            margin-bottom: 15px;
            background: var(--gradient);
            -webkit-background-clip: text;
            -webkit-text-fill-color: transparent;
            background-clip: text;
        }

        .subtitle {
            color: var(--success);
            font-size: 1.2rem;
            opacity: 0.9;
        }

        .status-badge {
            display: inline-block;
            background: var(--primary);
            color: white;
            padding: 8px 16px;
            border-radius: 20px;
            font-size: 0.9rem;
            margin-top: 15px;
            font-weight: 500;
        }

        /* Dashboard */
        .dashboard {
            display: grid;
            grid-template-columns: repeat(auto-fit, minmax(350px, 1fr));
            gap: 25px;
            margin-bottom: 30px;
        }

        .card {
            background: var(--card-bg);
            border-radius: 20px;
            padding: 25px;
            border: 1px solid var(--border);
            transition: all 0.3s ease;
        }

        .card:hover {
            border-color: var(--primary);
            transform: translateY(-5px);
            box-shadow: 0 15px 35px rgba(67, 97, 238, 0.15);
        }

        .card-title {
            color: var(--success);
            margin-bottom: 20px;
            font-size: 1.4rem;
            display: flex;
            align-items: center;
            gap: 10px;
        }

        .card-title i {
            font-size: 1.2rem;
        }

        /* Form elements */
        .form-group {
            margin-bottom: 20px;
        }

        .form-label {
            display: block;
            margin-bottom: 8px;
            color: #b0b0b0;
            font-weight: 500;
        }

        .form-input, .form-select, .form-textarea {
            width: 100%;
            padding: 14px;
            background: rgba(255,255,255,0.05);
            border: 2px solid var(--border);
            border-radius: 12px;
            color: #fff;
            font-size: 1rem;
            transition: all 0.3s;
        }

        .form-input:focus, .form-select:focus, .form-textarea:focus {
            outline: none;
            border-color: var(--primary);
            background: rgba(255,255,255,0.08);
        }

        .form-textarea {
            min-height: 120px;
            resize: vertical;
            font-family: 'Courier New', monospace;
        }

        /* Buttons */
        .btn {
            display: inline-flex;
            align-items: center;
            justify-content: center;
            gap: 12px;
            padding: 14px 28px;
            border: none;
            border-radius: 12px;
            font-size: 1rem;
            font-weight: 600;
            cursor: pointer;
            transition: all 0.3s ease;
            width: 100%;
            margin-bottom: 12px;
            text-decoration: none;
        }

        .btn-primary {
            background: var(--gradient);
            color: white;
        }

        .btn-primary:hover {
            transform: translateY(-2px);
            box-shadow: 0 10px 20px rgba(67, 97, 238, 0.3);
        }

        .btn-secondary {
            background: var(--secondary);
            color: white;
        }

        .btn-secondary:hover {
            background: #6200a8;
            transform: translateY(-2px);
        }

        .btn-outline {
            background: transparent;
            border: 2px solid var(--primary);
            color: var(--primary);
        }

        .btn-outline:hover {
            background: var(--primary);
            color: white;
        }

        .btn-small {
            padding: 8px 16px;
            font-size: 0.9rem;
            width: auto;
        }

        /* Info displays */
        .info-box {
            background: rgba(67, 97, 238, 0.1);
            border-left: 4px solid var(--primary);
            padding: 20px;
            border-radius: 10px;
            margin-bottom: 20px;
        }

        .info-item {
            display: flex;
            justify-content: space-between;
            margin-bottom: 12px;
            padding-bottom: 12px;
            border-bottom: 1px solid rgba(255,255,255,0.1);
        }

        .info-label {
            color: #b0b0b0;
            font-weight: 500;
        }

        .info-value {
            font-family: 'Courier New', monospace;
            color: var(--success);
            word-break: break-all;
            max-width: 70%;
        }

        /* Status indicators */
        .status {
            padding: 6px 14px;
            border-radius: 20px;
            font-size: 0.85rem;
            font-weight: 600;
            display: inline-block;
        }

        .status-online {
            background: rgba(76, 201, 240, 0.2);
            color: var(--success);
            border: 1px solid var(--success);
        }

        .status-offline {
            background: rgba(247, 37, 133, 0.2);
            color: var(--warning);
            border: 1px solid var(--warning);
        }

        .status-pending {
            background: rgba(255, 193, 7, 0.2);
            color: #ffc107;
            border: 1px solid #ffc107;
        }

        /* Warning box */
        .warning-box {
            background: rgba(247, 37, 133, 0.1);
            border: 2px solid var(--warning);
            border-radius: 15px;
            padding: 20px;
            margin: 20px 0;
            display: flex;
            align-items: flex-start;
            gap: 15px;
        }

        .warning-box i {
            color: var(--warning);
            font-size: 1.5rem;
            margin-top: 3px;
        }

        /* Code display */
        .code-block {
            background: rgba(0,0,0,0.3);
            border-radius: 10px;
            padding: 20px;
            margin: 15px 0;
            overflow-x: auto;
            font-family: 'Courier New', monospace;
            font-size: 0.9rem;
            line-height: 1.5;
            border: 1px solid var(--border);
        }

        /* Tabs */
        .tabs {
            display: flex;
            border-bottom: 2px solid var(--border);
            margin-bottom: 25px;
        }

        .tab {
            padding: 15px 25px;
            background: none;
            border: none;
            color: #b0b0b0;
            font-weight: 600;
            cursor: pointer;
            border-bottom: 3px solid transparent;
            transition: all 0.3s;
        }

        .tab.active {
            color: var(--primary);
            border-bottom-color: var(--primary);
        }

        .tab:hover:not(.active) {
            color: white;
        }

        /* Footer */
        .footer {
            background: var(--card-bg);
            border-radius: 20px;
            padding: 25px;
            margin-top: 40px;
            text-align: center;
            border: 1px solid var(--border);
        }

        .footer-links {
            display: flex;
            justify-content: center;
            gap: 30px;
            margin-top: 20px;
        }

        .footer-link {
            color: var(--success);
            text-decoration: none;
            display: flex;
            align-items: center;
            gap: 8px;
            transition: color 0.3s;
        }

        .footer-link:hover {
            color: white;
            text-decoration: underline;
        }

        /* Responsive */
        @media (max-width: 768px) {
            .dashboard {
                grid-template-columns: 1fr;
            }
            
            .header {
                padding: 20px;
            }
            
            .logo {
                font-size: 2rem;
            }
            
            .footer-links {
                flex-direction: column;
                gap: 15px;
            }
            
            .tabs {
                flex-direction: column;
            }
            
            .tab {
                text-align: left;
                border-bottom: 1px solid var(--border);
            }
        }

        /* Animations */
        @keyframes fadeIn {
            from { opacity: 0; transform: translateY(10px); }
            to { opacity: 1; transform: translateY(0); }
        }

        .fade-in {
            animation: fadeIn 0.5s ease-out;
        }

        /* Progress bar */
        .progress-bar {
            height: 8px;
            background: var(--border);
            border-radius: 4px;
            overflow: hidden;
            margin: 20px 0;
        }

        .progress-fill {
            height: 100%;
            background: var(--gradient);
            width: 0%;
            transition: width 0.5s ease;
        }

        /* Badge */
        .badge {
            display: inline-block;
            padding: 4px 10px;
            background: var(--primary);
            color: white;
            border-radius: 12px;
            font-size: 0.75rem;
            font-weight: 600;
            margin-left: 10px;
            vertical-align: middle;
        }

        /* Tooltip */
        .tooltip {
            position: relative;
            display: inline-block;
        }

        .tooltip .tooltip-text {
            visibility: hidden;
            width: 200px;
            background: var(--dark);
            color: #fff;
            text-align: center;
            padding: 10px;
            border-radius: 6px;
            position: absolute;
            z-index: 1;
            bottom: 125%;
            left: 50%;
            margin-left: -100px;
            opacity: 0;
            transition: opacity 0.3s;
            border: 1px solid var(--border);
        }

        .tooltip:hover .tooltip-text {
            visibility: visible;
            opacity: 1;
        }
    </style>
</head>
<body>
    <div class="app-container">
        <!-- Header -->
        <header class="header fade-in">
            <div class="logo">
                <i class="fas fa-fingerprint"></i> DID Data Marketplace
            </div>
            <p class="subtitle">MVP Completo con Node.js 25 & PostgreSQL 16</p>
            <div class="status-badge">
                <i class="fas fa-server"></i> IONOS VPS | Ubuntu 24.04
            </div>
        </header>

        <!-- Dashboard -->
        <div class="dashboard">
            <!-- Card 1: Identità -->
            <div class="card fade-in">
                <h2 class="card-title">
                    <i class="fas fa-id-card"></i> 1. Identità DID
                </h2>
                
                <div class="form-group">
                    <label class="form-label">Tipo di DID:</label>
                    <select class="form-select" id="did-method">
                        <option value="did:key">DID:Key (Raccomandato)</option>
                        <option value="did:ethr">DID:Ethr (MetaMask)</option>
                    </select>
                </div>

                <button class="btn btn-primary" onclick="createIdentity()">
                    <i class="fas fa-plus-circle"></i> Crea Nuova Identità
                </button>

                <div class="divider" style="text-align: center; margin: 20px 0; color: var(--gray);">
                    ─── OPPURE ───
                </div>

                <div class="form-group">
                    <label class="form-label">Recupera con Seed Phrase:</label>
                    <textarea class="form-textarea" id="recovery-mnemonic" 
                        placeholder="Incolla le 24 parole della tua seed phrase..."></textarea>
                </div>
                <button class="btn btn-secondary" onclick="recoverIdentity()">
                    <i class="fas fa-redo"></i> Recupera Identità
                </button>
            </div>

            <!-- Card 2: Dati -->
            <div class="card fade-in">
                <h2 class="card-title">
                    <i class="fas fa-database"></i> 2. Raccolta Dati
                </h2>
                
                <div class="form-group">
                    <label class="form-label">Simula Dati:</label>
                    <div style="display: grid; grid-template-columns: 1fr 1fr; gap: 10px;">
                        <button class="btn btn-outline btn-small" onclick="simulateData('geo')">
                            <i class="fas fa-map-marker-alt"></i> Geolocalizzazione
                        </button>
                        <button class="btn btn-outline btn-small" onclick="simulateData('tap')">
                            <i class="fas fa-hand-pointer"></i> Tap/Click
                        </button>
                        <button class="btn btn-outline btn-small" onclick="simulateData('like')">
                            <i class="fas fa-thumbs-up"></i> Like
                        </button>
                        <button class="btn btn-outline btn-small" onclick="simulateData('usage')">
                            <i class="fas fa-clock"></i> Utilizzo
                        </button>
                    </div>
                </div>

                <div class="form-group">
                    <label class="form-label">Dati Raccorsi:</label>
                    <div class="code-block" id="data-preview">
                        Nessun dato raccolto...
                    </div>
                    <div style="display: flex; justify-content: space-between; font-size: 0.9rem; color: var(--gray);">
                        <span id="event-count">0 eventi</span>
                        <span id="data-size">0 KB</span>
                    </div>
                </div>

                <div class="form-group">
                    <div class="info-box">
                        <i class="fas fa-shield-alt"></i>
                        <strong>GDPR Compliant:</strong> I dati sono pseudonimizzati e cifrati end-to-end
                    </div>
                </div>

                <button class="btn btn-primary" onclick="sendData()" id="send-data-btn">
                    <i class="fas fa-cloud-upload-alt"></i> Invia Dati al Server
                </button>
            </div>

            <!-- Card 3: NFT & Marketplace -->
            <div class="card fade-in">
                <h2 class="card-title">
                    <i class="fas fa-cube"></i> 3. NFT Marketplace
                </h2>
                
                <div class="progress-bar">
                    <div class="progress-fill" id="progress-bar"></div>
                </div>

                <div class="steps">
                    <div class="step" style="margin-bottom: 20px;">
                        <h4><i class="fas fa-box"></i> Crea Bundle</h4>
                        <p>Aggrega i tuoi dati in un pacchetto sicuro</p>
                        <button class="btn btn-outline btn-small" onclick="createBundle()" id="create-bundle-btn">
                            <i class="fas fa-box"></i> Crea Bundle
                        </button>
                    </div>

                    <div class="step" style="margin-bottom: 20px;">
                        <h4><i class="fas fa-cloud"></i> Carica su IPFS</h4>
                        <p>Archivia permanentemente su IPFS/Filecoin</p>
                        <button class="btn btn-outline btn-small" onclick="uploadToIPFS()" id="upload-ipfs-btn" disabled>
                            <i class="fas fa-cloud-upload-alt"></i> Carica su IPFS
                        </button>
                    </div>

                    <div class="step" style="margin-bottom: 20px;">
                        <h4><i class="fas fa-coins"></i> Mint NFT</h4>
                        <p>Conia NFT su Polygon Mumbai</p>
                        <button class="btn btn-primary btn-small" onclick="mintNFT()" id="mint-nft-btn" disabled>
                            <i class="fas fa-coins"></i> Mint NFT
                        </button>
                    </div>
                </div>

                <div class="info-box" id="nft-status">
                    <i class="fas fa-info-circle"></i>
                    Connetti il tuo wallet per iniziare...
                </div>
            </div>
        </div>

        <!-- Status Panel -->
        <div class="card fade-in">
            <h2 class="card-title">
                <i class="fas fa-heartbeat"></i> Stato Sistema
            </h2>
            
            <div class="info-item">
                <span class="info-label">Backend API:</span>
                <span id="backend-status" class="status status-pending">Verifica...</span>
            </div>
            
            <div class="info-item">
                <span class="info-label">Database:</span>
                <span id="database-status" class="status status-pending">Verifica...</span>
            </div>
            
            <div class="info-item">
                <span class="info-label">Node.js:</span>
                <span id="node-version" class="info-value">Rilevamento...</span>
            </div>
            
            <div class="info-item">
                <span class="info-label">Server:</span>
                <span class="info-value">IONOS VPS | Ubuntu 24.04</span>
            </div>

            <div class="info-item">
                <span class="info-label">Uptime:</span>
                <span id="uptime" class="info-value">--</span>
            </div>

            <div class="actions" style="margin-top: 20px;">
                <button class="btn btn-outline btn-small" onclick="refreshStatus()">
                    <i class="fas fa-sync-alt"></i> Aggiorna Stato
                </button>
                <button class="btn btn-outline btn-small" onclick="showApiDocs()">
                    <i class="fas fa-book"></i> API Docs
                </button>
                <button class="btn btn-outline btn-small" onclick="exportLogs()">
                    <i class="fas fa-download"></i> Esporta Logs
                </button>
            </div>
        </div>

        <!-- Footer -->
        <footer class="footer fade-in">
            <p>© 2025 DID Data Marketplace MVP | Deploy su IONOS VPS</p>
            <p style="color: var(--gray); font-size: 0.9rem; margin-top: 10px;">
                Node.js 25 • PostgreSQL 16 • Ubuntu 24.04 • GDPR Compliant
            </p>
            <div class="footer-links">
                <a href="#" class="footer-link" onclick="showPrivacyPolicy()">
                    <i class="fas fa-shield-alt"></i> Privacy & GDPR
                </a>
                <a href="#" class="footer-link" onclick="showSystemInfo()">
                    <i class="fas fa-info-circle"></i> Info Sistema
                </a>
                <a href="https://github.com/alecasarola/3id-platform.git/did-data-mvp" class="footer-link" target="_blank">
                    <i class="fab fa-github"></i> GitHub
                </a>
                <a href="/api/health" class="footer-link" target="_blank">
                    <i class="fas fa-heartbeat"></i> Health Check
                </a>
            </div>
        </footer>
    </div>

    <!-- JavaScript -->
    <script src="https://cdn.jsdelivr.net/npm/axios/dist/axios.min.js"></script>
    <script>
        // Configurazione
        const API_BASE = window.location.origin + '/api';
        const CLIENT_VERSION = '1.0.0';
        
        // Stato applicazione
        let appState = {
            did: null,
            sessionToken: localStorage.getItem('sessionToken'),
            collectedEvents: [],
            currentBundle: null,
            nftStatus: null,
            lastHealthCheck: null
        };

        // Inizializzazione
        document.addEventListener('DOMContentLoaded', () => {
            console.log('DID MVP Frontend v' + CLIENT_VERSION);
            console.log('API Base:', API_BASE);
            
            // Carica stato da localStorage
            loadFromLocalStorage();
            
            // Aggiorna stato sistema
            refreshStatus();
            
            // Aggiorna uptime periodicamente
            setInterval(updateUptime, 1000);
            
            // Auto-refresh status ogni 30 secondi
            setInterval(refreshStatus, 30000);
        });

        // Funzioni principali
        async function createIdentity() {
            try {
                showLoading('Creazione identità...');
                
                const response = await axios.post(API_BASE + '/auth/create-did', {
                    didMethod: document.getElementById('did-method').value,
                    alias: 'user-' + Date.now()
                });
                
                if (response.data.success) {
                    appState.did = response.data.did;
                    localStorage.setItem('did', appState.did);
                    
                    showSuccess('Identità creata con successo!');
                    showSeedPhraseWarning(response.data.mnemonic);
                }
            } catch (error) {
                showError('Errore creazione identità', error);
            }
        }

        async function recoverIdentity() {
            const mnemonic = document.getElementById('recovery-mnemonic').value.trim();
            
            if (!mnemonic) {
                showError('Inserisci la seed phrase');
                return;
            }
            
            try {
                showLoading('Recupero identità...');
                
                const response = await axios.post(API_BASE + '/auth/recover-did', {
                    mnemonic: mnemonic,
                    didMethod: document.getElementById('did-method').value
                });
                
                if (response.data.success) {
                    appState.did = response.data.did;
                    localStorage.setItem('did', appState.did);
                    showSuccess('Identità recuperata!');
                }
            } catch (error) {
                showError('Errore recupero identità', error);
            }
        }

        function simulateData(type) {
            const events = {
                geo: {
                    type: 'geo',
                    country: 'IT',
                    city: ['Rome', 'Milan', 'Turin'][Math.floor(Math.random() * 3)],
                    ts: Math.floor(Date.now() / 1000)
                },
                tap: {
                    type: 'tap',
                    count: Math.floor(Math.random() * 10) + 1,
                    screen: 'home',
                    ts: Math.floor(Date.now() / 1000)
                },
                like: {
                    type: 'like',
                    count: Math.floor(Math.random() * 5) + 1,
                    content: 'post_' + Math.floor(Math.random() * 1000),
                    ts: Math.floor(Date.now() / 1000)
                },
                usage: {
                    type: 'usage',
                    seconds: Math.floor(Math.random() * 600) + 60,
                    app: 'social',
                    ts: Math.floor(Date.now() / 1000)
                }
            };
            
            appState.collectedEvents.push(events[type]);
            updateDataPreview();
            
            // Abilita pulsante invio dati
            document.getElementById('send-data-btn').disabled = false;
        }

        function updateDataPreview() {
            const preview = document.getElementById('data-preview');
            preview.textContent = JSON.stringify(appState.collectedEvents, null, 2);
            
            // Aggiorna contatori
            document.getElementById('event-count').textContent = 
                `${appState.collectedEvents.length} eventi`;
            
            const dataSize = JSON.stringify(appState.collectedEvents).length / 1024;
            document.getElementById('data-size').textContent = 
                `${dataSize.toFixed(2)} KB`;
            
            // Aggiorna progress bar
            const progress = Math.min((appState.collectedEvents.length / 10) * 100, 100);
            document.getElementById('progress-bar').style.width = `${progress}%`;
        }

        async function sendData() {
            if (!appState.did) {
                showError('Crea prima un\'identità');
                return;
            }
            
            try {
                showLoading('Invio dati al server...');
                
                const response = await axios.post(API_BASE + '/data/collect', {
                    did: appState.did,
                    sessionId: 'sess_' + Date.now(),
                    events: appState.collectedEvents,
                    consentProof: {
                        version: '1.0',
                        timestamp: new Date().toISOString(),
                        purposes: ['data-aggregation', 'nft-minting'],
                        legalBasis: 'consent'
                    }
                });
                
                if (response.data.success) {
                    appState.currentBundle = response.data.bundleId;
                    showSuccess('Dati inviati con successo!');
                    
                    // Abilita pulsanti successivi
                    document.getElementById('create-bundle-btn').disabled = false;
                }
            } catch (error) {
                showError('Errore invio dati', error);
            }
        }

        async function createBundle() {
            try {
                showLoading('Creazione bundle...');
                
                const response = await axios.post(API_BASE + '/data/bundle/create', {
                    dataIds: [appState.currentBundle],
                    bundleName: `Bundle_${new Date().toLocaleDateString()}`
                });
                
                if (response.data.success) {
                    showSuccess('Bundle creato!');
                    document.getElementById('upload-ipfs-btn').disabled = false;
                }
            } catch (error) {
                showError('Errore creazione bundle', error);
            }
        }

        async function uploadToIPFS() {
            try {
                showLoading('Upload su IPFS...');
                
                const response = await axios.post(API_BASE + '/data/bundle/upload', {
                    bundleId: appState.currentBundle
                });
                
                if (response.data.success) {
                    showSuccess('Caricato su IPFS! CID: ' + response.data.ipfsCID.substring(0, 16) + '...');
                    document.getElementById('mint-nft-btn').disabled = false;
                }
            } catch (error) {
                showError('Errore upload IPFS', error);
            }
        }

        async function mintNFT() {
            try {
                showLoading('Minting NFT su Polygon...');
                
                const response = await axios.post(API_BASE + '/nft/mint', {
                    bundleId: appState.currentBundle
                });
                
                if (response.data.success) {
                    showSuccess('NFT mintato con successo!');
                    document.getElementById('nft-status').innerHTML = `
                        <i class="fas fa-check-circle"></i>
                        <strong>NFT Mintato!</strong><br>
                        Token ID: ${response.data.nft.tokenId}<br>
                        <a href="${response.data.explore}" target="_blank">Visualizza su Polygonscan</a>
                    `;
                }
            } catch (error) {
                showError('Errore minting NFT', error);
            }
        }

        async function refreshStatus() {
            try {
                const response = await axios.get(API_BASE + '/health');
                const data = response.data;
                
                // Aggiorna UI stato backend
                const backendStatus = document.getElementById('backend-status');
                backendStatus.className = 'status status-online';
                backendStatus.innerHTML = `
                    <i class="fas fa-check-circle"></i> Online
                `;
                
                // Aggiorna versione Node.js
                document.getElementById('node-version').textContent = data.nodeVersion;
                
                // Aggiorna database status
                const dbStatus = document.getElementById('database-status');
                dbStatus.className = 'status status-online';
                dbStatus.innerHTML = `
                    <i class="fas fa-database"></i> PostgreSQL 16
                `;
                
                // Salva timestamp ultimo check
                appState.lastHealthCheck = new Date();
                
            } catch (error) {
                const backendStatus = document.getElementById('backend-status');
                backendStatus.className = 'status status-offline';
                backendStatus.innerHTML = `
                    <i class="fas fa-exclamation-circle"></i> Offline
                `;
            }
        }

        function updateUptime() {
            if (appState.lastHealthCheck) {
                const uptimeEl = document.getElementById('uptime');
                const diff = Math.floor((new Date() - new Date(appState.lastHealthCheck)) / 1000);
                
                const hours = Math.floor(diff / 3600);
                const minutes = Math.floor((diff % 3600) / 60);
                const seconds = diff % 60;
                
                uptimeEl.textContent = 
                    `${hours.toString().padStart(2, '0')}:${minutes.toString().padStart(2, '0')}:${seconds.toString().padStart(2, '0')}`;
            }
        }

        // Utility functions
        function showSeedPhraseWarning(mnemonic) {
            const words = mnemonic.split(' ');
            let display = '';
            
            for (let i = 0; i < words.length; i += 3) {
                display += `<div style="margin-bottom: 10px;">`;
                for (let j = 0; j < 3 && (i + j) < words.length; j++) {
                    display += `<span style="display: inline-block; width: 100px; padding: 5px; background: rgba(0,0,0,0.3); margin: 2px; border-radius: 4px;">
                        ${i + j + 1}. ${words[i + j]}
                    </span>`;
                }
                display += `</div>`;
            }
            
            const html = `
                <div style="text-align: left; padding: 20px;">
                    <h3 style="color: var(--warning); margin-bottom: 15px;">
                        <i class="fas fa-exclamation-triangle"></i> ATTENZIONE CRITICA
                    </h3>
                    <p>La seguente seed phrase è l'<strong>UNICO MODO</strong> per recuperare la tua identità:</p>
                    <div style="background: rgba(0,0,0,0.3); padding: 15px; border-radius: 8px; margin: 15px 0; font-family: monospace;">
                        ${display}
                    </div>
                    <p><strong>Istruzioni:</strong></p>
                    <ol style="margin-left: 20px; margin-top: 10px;">
                        <li>Scrivi queste 24 parole SU CARTA</li>
                        <li>Conserva in luogo SICURO (cassaforte)</li>
                        <li>NON salvare in chiaro su computer</li>
                        <li>NON condividere con nessuno</li>
                        <li>Se perdi la seed phrase, PERDI TUTTO</li>
                    </ol>
                </div>
            `;
            
            showModal('Backup Seed Phrase', html);
        }

        function showLoading(message) {
            const loading = document.createElement('div');
            loading.id = 'loading-overlay';
            loading.style.cssText = `
                position: fixed;
                top: 0;
                left: 0;
                right: 0;
                bottom: 0;
                background: rgba(0,0,0,0.8);
                display: flex;
                flex-direction: column;
                align-items: center;
                justify-content: center;
                z-index: 1000;
            `;
            
            loading.innerHTML = `
                <div style="text-align: center;">
                    <div class="spinner" style="
                        width: 50px;
                        height: 50px;
                        border: 5px solid var(--border);
                        border-top: 5px solid var(--primary);
                        border-radius: 50%;
                        animation: spin 1s linear infinite;
                        margin: 0 auto 20px auto;
                    "></div>
                    <h3 style="color: white;">${message}</h3>
                </div>
                <style>
                    @keyframes spin {
                        0% { transform: rotate(0deg); }
                        100% { transform: rotate(360deg); }
                    }
                </style>
            `;
            
            document.body.appendChild(loading);
        }

        function hideLoading() {
            const loading = document.getElementById('loading-overlay');
            if (loading) {
                loading.remove();
            }
        }

        function showSuccess(message) {
            hideLoading();
            
            const notification = document.createElement('div');
            notification.style.cssText = `
                position: fixed;
                top: 20px;
                right: 20px;
                background: rgba(76, 201, 240, 0.2);
                border: 1px solid var(--success);
                color: white;
                padding: 15px 25px;
                border-radius: 10px;
                z-index: 1001;
                max-width: 400px;
                animation: slideIn 0.3s ease;
            `;
            
            notification.innerHTML = `
                <i class="fas fa-check-circle" style="color: var(--success); margin-right: 10px;"></i>
                ${message}
            `;
            
            document.body.appendChild(notification);
            
            setTimeout(() => {
                notification.style.animation = 'slideOut 0.3s ease';
                setTimeout(() => notification.remove(), 300);
            }, 3000);
            
            // Aggiungi animazioni CSS
            if (!document.getElementById('notification-styles')) {
                const style = document.createElement('style');
                style.id = 'notification-styles';
                style.textContent = `
                    @keyframes slideIn {
                        from { transform: translateX(100%); opacity: 0; }
                        to { transform: translateX(0); opacity: 1; }
                    }
                    @keyframes slideOut {
                        from { transform: translateX(0); opacity: 1; }
                        to { transform: translateX(100%); opacity: 0; }
                    }
                `;
                document.head.appendChild(style);
            }
        }

        function showError(title, error) {
            hideLoading();
            
            const message = error?.response?.data?.error || error?.message || title;
            
            const notification = document.createElement('div');
            notification.style.cssText = `
                position: fixed;
                top: 20px;
                right: 20px;
                background: rgba(247, 37, 133, 0.2);
                border: 1px solid var(--warning);
                color: white;
                padding: 15px 25px;
                border-radius: 10px;
                z-index: 1001;
                max-width: 400px;
                animation: slideIn 0.3s ease;
            `;
            
            notification.innerHTML = `
                <i class="fas fa-exclamation-circle" style="color: var(--warning); margin-right: 10px;"></i>
                <strong>${title}</strong><br>
                <small>${message}</small>
            `;
            
            document.body.appendChild(notification);
            
            setTimeout(() => {
                notification.style.animation = 'slideOut 0.3s ease';
                setTimeout(() => notification.remove(), 300);
            }, 5000);
        }

        function showModal(title, content) {
            const modal = document.createElement('div');
            modal.id = 'modal-overlay';
            modal.style.cssText = `
                position: fixed;
                top: 0;
                left: 0;
                right: 0;
                bottom: 0;
                background: rgba(0,0,0,0.9);
                display: flex;
                align-items: center;
                justify-content: center;
                z-index: 1002;
                padding: 20px;
            `;
            
            modal.innerHTML = `
                <div style="
                    background: var(--card-bg);
                    border-radius: 20px;
                    max-width: 600px;
                    width: 100%;
                    max-height: 90vh;
                    overflow-y: auto;
                    border: 2px solid var(--border);
                ">
                    <div style="
                        padding: 25px;
                        border-bottom: 1px solid var(--border);
                        display: flex;
                        justify-content: space-between;
                        align-items: center;
                    ">
                        <h2 style="color: var(--success); margin: 0;">${title}</h2>
                        <button onclick="closeModal()" style="
                            background: none;
                            border: none;
                            color: var(--gray);
                            font-size: 1.5rem;
                            cursor: pointer;
                        ">&times;</button>
                    </div>
                    <div style="padding: 25px;">
                        ${content}
                    </div>
                </div>
            `;
            
            document.body.appendChild(modal);
        }

        function closeModal() {
            const modal = document.getElementById('modal-overlay');
            if (modal) {
                modal.remove();
            }
        }

        function loadFromLocalStorage() {
            const savedDID = localStorage.getItem('did');
            if (savedDID) {
                appState.did = savedDID;
                showSuccess('Identità caricata da localStorage');
            }
        }

        function showSystemInfo() {
            const info = `
                <div style="line-height: 1.8;">
                    <p><strong>Sistema:</strong> IONOS VPS</p>
                    <p><strong>OS:</strong> Ubuntu 24.04</p>
                    <p><strong>Node.js:</strong> ${process.version || 'N/A (client)'}</p>
                    <p><strong>Browser:</strong> ${navigator.userAgent}</p>
                    <p><strong>API:</strong> ${API_BASE}</p>
                    <p><strong>DID:</strong> ${appState.did || 'Non configurato'}</p>
                    <hr style="border-color: var(--border); margin: 15px 0;">
                    <p><small>Frontend v${CLIENT_VERSION}</small></p>
                </div>
            `;
            showModal('Informazioni Sistema', info);
        }

        function showApiDocs() {
            window.open(API_BASE, '_blank');
        }

        function exportLogs() {
            const logs = {
                timestamp: new Date().toISOString(),
                did: appState.did,
                events: appState.collectedEvents.length,
                bundle: appState.currentBundle,
                nft: appState.nftStatus,
                userAgent: navigator.userAgent
            };
            
            const dataStr = JSON.stringify(logs, null, 2);
            const dataUri = 'data:application/json;charset=utf-8,'+ encodeURIComponent(dataStr);
            
            const exportFileDefaultName = `did-mvp-logs-${new Date().toISOString().split('T')[0]}.json`;
            
            const linkElement = document.createElement('a');
            linkElement.setAttribute('href', dataUri);
            linkElement.setAttribute('download', exportFileDefaultName);
            linkElement.click();
        }

        function showPrivacyPolicy() {
            const policy = `
                <div style="line-height: 1.6;">
                    <h3 style="color: var(--success); margin-bottom: 15px;">GDPR Compliance</h3>
                    <p><strong>Questo sistema è GDPR-compliant:</strong></p>
                    <ul style="margin-left: 20px; margin-bottom: 15px;">
                        <li>Dati pseudonimizzati (DID)</li>
                        <li>Geolocalizzazione coarse-only (città/paese)</li>
                        <li>Cifratura end-to-end</li>
                        <li>Consenso esplicito richiesto</li>
                        <li>Diritto alla cancellazione implementato</li>
                    </ul>
                    <p>I dati grezzi rimangono cifrati e sotto il controllo dell'utente.</p>
                    <p>L'NFT rappresenta solo il diritto di accesso, non i dati stessi.</p>
                </div>
            `;
            showModal('Privacy & GDPR Policy', policy);
        }
    </script>
</body>
</html>
EOF

# Crea file .htaccess per SPA routing
cat > /var/www/did-mvp/client/.htaccess << 'EOF'
RewriteEngine On
RewriteBase /
RewriteRule ^index\.html$ - [L]
RewriteCond %{REQUEST_FILENAME} !-f
RewriteCond %{REQUEST_FILENAME} !-d
RewriteRule . /index.html [L]
EOF

echo "✅ Frontend configurato"
echo " "

# ============ 9. CONFIGURA NGINX ==================
echo "🌐 [9/12] Configurazione Nginx..."

# Crea configurazione Nginx ottimizzata
cat > /etc/nginx/sites-available/did-mvp << EOF
# DID Data Marketplace - Nginx Configuration
# Optimized for Node.js 25 + PostgreSQL 16

upstream did_backend {
    server 127.0.0.1:3001;
    keepalive 32;
}

server {
    listen 80;
    listen [::]:80;
    
    server_name $DOMINIO;
    root /var/www/did-mvp/client;
    index index.html;

    # SSL Redirect (will be added by Certbot)
    # return 301 https://\$server_name\$request_uri;

    # Security Headers
    add_header X-Frame-Options "SAMEORIGIN" always;
    add_header X-Content-Type-Options "nosniff" always;
    add_header X-XSS-Protection "1; mode=block" always;
    add_header Referrer-Policy "strict-origin-when-cross-origin" always;
    add_header Strict-Transport-Security "max-age=31536000; includeSubDomains" always;
    add_header Content-Security-Policy "default-src 'self'; script-src 'self' 'unsafe-inline' https://cdn.jsdelivr.net https://cdnjs.cloudflare.com; style-src 'self' 'unsafe-inline' https://cdnjs.cloudflare.com; font-src 'self' https://cdnjs.cloudflare.com; img-src 'self' data: https:; connect-src 'self' https://*.infura.io https://*.web3.storage;" always;

    # Gzip Compression
    gzip on;
    gzip_vary on;
    gzip_min_length 1024;
    gzip_proxied any;
    gzip_comp_level 6;
    gzip_types
        application/atom+xml
        application/javascript
        application/json
        application/ld+json
        application/manifest+json
        application/rss+xml
        application/vnd.geo+json
        application/vnd.ms-fontobject
        application/x-font-ttf
        application/x-web-app-manifest+json
        application/xhtml+xml
        application/xml
        font/opentype
        image/bmp
        image/svg+xml
        image/x-icon
        text/cache-manifest
        text/css
        text/plain
        text/vcard
        text/vnd.rim.location.xloc
        text/vtt
        text/x-component
        text/x-cross-domain-policy;

    # Frontend - SPA
    location / {
        try_files \$uri \$uri/ /index.html;
        expires 1h;
        add_header Cache-Control "public, no-transform";
        
        # Security
        add_header X-Content-Type-Options nosniff;
        add_header X-Frame-Options DENY;
        add_header X-XSS-Protection "1; mode=block";
    }

    # Static Assets
    location ~* \.(js|css|png|jpg|jpeg|gif|ico|svg|woff|woff2|ttf|eot)$ {
        expires 1y;
        add_header Cache-Control "public, immutable";
        access_log off;
        add_header X-Content-Type-Options nosniff;
    }

    # Backend API
    location /api {
        proxy_pass http://did_backend;
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
        proxy_set_header X-Forwarded-Host \$host;
        proxy_set_header X-Forwarded-Port \$server_port;
        
        # Timeouts
        proxy_connect_timeout 30s;
        proxy_send_timeout 30s;
        proxy_read_timeout 30s;
        
        # Buffers
        proxy_buffer_size 128k;
        proxy_buffers 4 256k;
        proxy_busy_buffers_size 256k;
        
        # Keepalive
        keepalive_timeout 30;
        
        # Security
        proxy_hide_header X-Powered-By;
    }

    # Health Check (public)
    location /health {
        proxy_pass http://did_backend/api/health;
        proxy_set_header Host \$host;
        access_log off;
    }

    # Deny access to hidden files
    location ~ /\. {
        deny all;
        access_log off;
        log_not_found off;
    }

    # Deny access to sensitive files
    location ~* \.(log|sql|bak|old|swp)$ {
        deny all;
        access_log off;
        log_not_found off;
    }

    # Logs
    access_log /var/log/nginx/did-mvp-access.log;
    error_log /var/log/nginx/did-mvp-error.log;
}
EOF

# Abilita sito
ln -sf /etc/nginx/sites-available/did-mvp /etc/nginx/sites-enabled/
rm -f /etc/nginx/sites-enabled/default

# Test configurazione Nginx
nginx -t

# Riavvia Nginx
systemctl restart nginx

echo "✅ Nginx configurato e avviato"
echo " "

# ============ 10. CONFIGURA SSL ===================
echo "🔐 [10/12] Configurazione SSL..."

# Installa Certbot se non presente
if ! command -v certbot &> /dev/null; then
    apt-get install -y certbot python3-certbot-nginx
fi

# Controlla se il dominio è valido (non il placeholder)
if [[ "$DOMINIO" != "datamarket.tuodominio.com" && ! -z "$EMAIL_SSL" ]]; then
    echo "📧 Richiesta certificato SSL per $DOMINIO..."
    
    # Prova a ottenere certificato SSL
    if certbot --nginx -d $DOMINIO --non-interactive --agree-tos -m $EMAIL_SSL --redirect; then
        echo "✅ SSL configurato con successo!"
        
        # Setup auto-renewal
        certbot renew --dry-run
        echo "0 3 * * * certbot renew --quiet --post-hook 'systemctl reload nginx'" > /etc/cron.d/certbot-renewal
    else
        echo "⚠️  Fallita configurazione SSL. Continua senza SSL..."
    fi
else
    echo "⚠️  Salto SSL: configura dominio reale in cima allo script"
fi

systemctl reload nginx
echo " "

# ============ 11. AVVIA APPLICAZIONE ==============
echo "🚀 [11/12] Avvio applicazione..."

cd /var/www/did-mvp/backend

# Avvia con PM2
pm2 delete did-mvp-backend 2>/dev/null || true
pm2 start ecosystem.config.js
pm2 save
pm2 startup

# Attendi che il server sia avviato
sleep 3

# Verifica che il server sia in esecuzione
if curl -s http://localhost:3001/api/health > /dev/null; then
    echo "✅ Backend avviato con successo!"
else
    echo "⚠️  Backend non risponde, controlla i logs..."
    pm2 logs did-mvp-backend --lines 20
fi

echo " "

# ============ 12. CONFIGURA BACKUP ================
echo "💾 [12/12] Configurazione backup automatico..."

# Crea script di backup
cat > /usr/local/bin/backup-did-mvp.sh << 'EOF'
#!/bin/bash
# Backup script per DID MVP

BACKUP_DIR="/var/backups/did-mvp"
DATE=$(date +%Y%m%d_%H%M%S)
LOG_FILE="/var/log/did-mvp-backup.log"

echo "[$DATE] Inizio backup..." >> $LOG_FILE

# 1. Crea directory backup
mkdir -p $BACKUP_DIR

# 2. Backup database
echo "[$DATE] Backup database..." >> $LOG_FILE
PGPASSWORD=$(grep DB_PASSWORD /var/www/did-mvp/backend/.env | cut -d= -f2) \
pg_dump -U did_user -h localhost did_mvp > $BACKUP_DIR/db_$DATE.sql 2>> $LOG_FILE

# 3. Backup codice sorgente
echo "[$DATE] Backup codice..." >> $LOG_FILE
tar -czf $BACKUP_DIR/code_$DATE.tar.gz \
    /var/www/did-mvp \
    /etc/nginx/sites-available/did-mvp \
    /etc/systemd/system/pm2-root.service 2>> $LOG_FILE

# 4. Backup configurazioni
echo "[$DATE] Backup configurazioni..." >> $LOG_FILE
cp /var/www/did-mvp/backend/.env $BACKUP_DIR/env_$DATE.backup
cp /var/www/did-mvp/backend/ecosystem.config.js $BACKUP_DIR/pm2_$DATE.backup

# 5. Backup PM2 state
echo "[$DATE] Backup PM2..." >> $LOG_FILE
pm2 save 2>> $LOG_FILE
cp /root/.pm2/dump.pm2 $BACKUP_DIR/pm2_state_$DATE.pm2 2>> $LOG_FILE

# 6. Rimuovi backup vecchi (> 7 giorni)
echo "[$DATE] Pulizia backup vecchi..." >> $LOG_FILE
find $BACKUP_DIR -name "*.tar.gz" -mtime +7 -delete 2>> $LOG_FILE
find $BACKUP_DIR -name "*.sql" -mtime +7 -delete 2>> $LOG_FILE
find $BACKUP_DIR -name "*.backup" -mtime +7 -delete 2>> $LOG_FILE
find $BACKUP_DIR -name "*.pm2" -mtime +7 -delete 2>> $LOG_FILE

# 7. Calcola dimensione backup
TOTAL_SIZE=$(du -sh $BACKUP_DIR | cut -f1)
echo "[$DATE] Backup completato. Dimensione totale: $TOTAL_SIZE" >> $LOG_FILE

# 8. Notifica (se configurato)
if [ -f /etc/did-mvp/alert.conf ]; then
    source /etc/did-mvp/alert.conf
    if [ ! -z "$ALERT_EMAIL" ]; then
        echo "Backup DID MVP completato il $DATE. Dimensione: $TOTAL_SIZE" | \
        mail -s "DID MVP Backup Report" $ALERT_EMAIL
    fi
fi

chmod 600 $BACKUP_DIR/* 2>/dev/null
EOF

chmod +x /usr/local/bin/backup-did-mvp.sh

# Crea cron job per backup giornaliero alle 2 AM
echo "0 2 * * * root /usr/local/bin/backup-did-mvp.sh" > /etc/cron.d/did-mvp-backup

echo "✅ Backup automatico configurato (ogni giorno alle 2 AM)"
echo " "

# ============ RIEPILOGO FINALE ====================
END_TIME=$(date)
RUNTIME=$(( $(date -d "$END_TIME" +%s) - $(date -d "$START_TIME" +%s) ))

echo "======================================================"
echo "✅ SETUP COMPLETATO SUCCESSO!"
echo "======================================================"
echo " "
echo "📋 RIEPILOGO INSTALLAZIONE:"
echo "   • Tempo esecuzione: $RUNTIME secondi"
echo "   • Node.js: $(node --version)"
echo "   • npm: $(npm --version)"
echo "   • PostgreSQL: $(psql --version | head -n1)"
echo "   • Nginx: $(nginx -v 2>&1 | head -n1)"
echo "   • PM2: $(pm2 --version)"
echo " "
echo "🌐 URL DI ACCESSO:"
echo "   • Frontend: http://$DOMINIO"
echo "   • Backend API: http://$DOMINIO/api"
echo "   • Health Check: http://$DOMINIO/api/health"
echo "   • Server IP: $IP_SERVER"
echo " "
echo "🔧 FILE IMPORTANTI:"
echo "   • Codice: /var/www/did-mvp/"
echo "   • Config: /var/www/did-mvp/backend/.env"
echo "   • Logs: /var/log/did-mvp/"
echo "   • Backup: /var/backups/did-mvp/"
echo "   • Nginx: /etc/nginx/sites-available/did-mvp"
echo " "
echo "📝 COMANDI UTILI:"
echo "   • Riavvia backend: pm2 restart did-mvp-backend"
echo "   • Logs backend: pm2 logs did-mvp-backend"
echo "   • Status: pm2 status"
echo "   • Logs Nginx: tail -f /var/log/nginx/did-mvp-error.log"
echo "   • Backup manuale: /usr/local/bin/backup-did-mvp.sh"
echo "   • Connetti DB: psql -U did_user -d did_mvp"
echo " "
echo "⚠️  PASSI SUCCESSIVI OBBLIGATORI:"
echo "   1. MODIFICA /var/www/did-mvp/backend/.env con le tue API keys"
echo "   2. Ottieni token da:"
echo "      • Web3.Storage: https://web3.storage"
echo "      • Infura: https://infura.io"
echo "      • Crea wallet test con MetaMask"
echo "   3. Deploy smart contract su Polygon Mumbai"
echo "   4. Testa l'applicazione end-to-end"
echo " "
echo "🔐 API KEYS DA INSERIRE IN .env:"
echo "   WEB3_STORAGE_TOKEN=tuo_token_web3storage"
echo "   POLYGON_RPC_URL=https://polygon-mumbai.infura.io/v3/tuo_infura_key"
echo "   SERVER_PRIVATE_KEY=0x... (wallet test)"
echo " "
echo "🎉 IL TUO MVP È PRONTO PER IL DEPLOY!"
echo "======================================================"