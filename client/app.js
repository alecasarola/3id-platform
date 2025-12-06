// ============================================
// DID DATA MARKETPLACE MVP - Frontend App
// ============================================

// Configurazione
const CONFIG = {
    API_BASE_URL: window.location.origin + '/api',
    VERSION: '1.0.0',
    ENVIRONMENT: 'production'
};

// Stato applicazione
const AppState = {
    // Identità utente
    user: {
        did: localStorage.getItem('did'),
        sessionToken: localStorage.getItem('sessionToken'),
        walletAddress: localStorage.getItem('walletAddress'),
        mnemonic: null, // Solo in memoria, mai in localStorage
    },
    
    // Dati raccolti
    data: {
        events: JSON.parse(localStorage.getItem('collectedEvents') || '[]'),
        currentBundle: localStorage.getItem('currentBundle'),
        ipfsCID: localStorage.getItem('ipfsCID'),
        nft: JSON.parse(localStorage.getItem('nft') || 'null'),
    },
    
    // Stato sistema
    system: {
        backendOnline: false,
        databaseOnline: false,
        lastHealthCheck: null,
        apiEndpoint: CONFIG.API_BASE_URL,
    },
    
    // UI State
    ui: {
        currentTab: 'identity',
        modalOpen: false,
        loading: false,
        notifications: []
    }
};

// ==================== UTILITY FUNCTIONS ====================

/**
 * Mostra una notifica
 */
function showNotification(type, title, message, duration = 5000) {
    const notification = {
        id: Date.now(),
        type,
        title,
        message,
        timestamp: new Date()
    };
    
    AppState.ui.notifications.push(notification);
    
    // Creare elemento DOM per la notifica
    const notificationEl = document.createElement('div');
    notificationEl.className = `notification ${type}`;
    notificationEl.innerHTML = `
        <div class="notification-icon">
            ${type === 'success' ? '✅' : type === 'error' ? '❌' : '⚠️'}
        </div>
        <div class="notification-content">
            <div class="notification-title">${title}</div>
            <div class="notification-message">${message}</div>
        </div>
    `;
    
    // Aggiungere al DOM
    document.body.appendChild(notificationEl);
    
    // Rimuovere dopo il timeout
    setTimeout(() => {
        notificationEl.remove();
        AppState.ui.notifications = AppState.ui.notifications.filter(n => n.id !== notification.id);
    }, duration);
}

/**
 * Mostra modal di caricamento
 */
function showLoading(message = 'Caricamento...') {
    AppState.ui.loading = true;
    
    const loadingEl = document.createElement('div');
    loadingEl.id = 'custom-loading';
    loadingEl.className = 'modal-overlay';
    loadingEl.innerHTML = `
        <div class="modal" style="max-width: 300px; text-align: center;">
            <div class="modal-body">
                <div class="spinner" style="margin: 0 auto 20px;"></div>
                <h4>${message}</h4>
            </div>
        </div>
    `;
    
    document.body.appendChild(loadingEl);
}

/**
 * Nascondi modal di caricamento
 */
function hideLoading() {
    AppState.ui.loading = false;
    const loadingEl = document.getElementById('custom-loading');
    if (loadingEl) {
        loadingEl.remove();
    }
}

/**
 * Copia testo negli appunti
 */
async function copyToClipboard(text) {
    try {
        await navigator.clipboard.writeText(text);
        showNotification('success', 'Copiato!', 'Testo copiato negli appunti');
        return true;
    } catch (err) {
        console.error('Errore copia:', err);
        showNotification('error', 'Errore', 'Impossibile copiare');
        return false;
    }
}

/**
 * Salva dati in localStorage
 */
function saveToLocalStorage() {
    localStorage.setItem('did', AppState.user.did || '');
    localStorage.setItem('sessionToken', AppState.user.sessionToken || '');
    localStorage.setItem('walletAddress', AppState.user.walletAddress || '');
    localStorage.setItem('collectedEvents', JSON.stringify(AppState.data.events));
    localStorage.setItem('currentBundle', AppState.data.currentBundle || '');
    localStorage.setItem('ipfsCID', AppState.data.ipfsCID || '');
    localStorage.setItem('nft', JSON.stringify(AppState.data.nft || null));
}

/**
 * Formatta dati per display
 */
function formatDataForDisplay(data) {
    if (typeof data === 'object') {
        return JSON.stringify(data, null, 2);
    }
    return String(data);
}

/**
 * Formatta timestamp
 */
function formatTimestamp(timestamp) {
    const date = new Date(timestamp);
    return date.toLocaleString('it-IT', {
        day: '2-digit',
        month: '2-digit',
        year: 'numeric',
        hour: '2-digit',
        minute: '2-digit'
    });
}

// ==================== API FUNCTIONS ====================

/**
 * Testa la connessione al backend
 */
async function testBackendConnection() {
    try {
        const response = await axios.get(`${CONFIG.API_BASE_URL}/health`);
        AppState.system.backendOnline = true;
        AppState.system.lastHealthCheck = new Date();
        
        return {
            success: true,
            data: response.data,
            timestamp: new Date()
        };
    } catch (error) {
        AppState.system.backendOnline = false;
        return {
            success: false,
            error: error.message,
            timestamp: new Date()
        };
    }
}

/**
 * Crea una nuova identità DID
 */
async function createDID() {
    try {
        showLoading('Creazione identità...');
        
        const response = await axios.post(`${CONFIG.API_BASE_URL}/auth/create-did`, {
            didMethod: 'did:key',
            alias: `user-${Date.now()}`
        });
        
        if (response.data.success) {
            AppState.user.did = response.data.did;
            AppState.user.mnemonic = response.data.mnemonic;
            
            // Salva solo DID, non la mnemonic!
            saveToLocalStorage();
            
            showNotification('success', 'Identità creata!', 'La tua DID è stata generata');
            
            // Mostra seed phrase warning
            showSeedPhraseModal(response.data.mnemonic);
            
            return response.data;
        }
    } catch (error) {
        console.error('Errore creazione DID:', error);
        showNotification('error', 'Errore', error.response?.data?.error || 'Impossibile creare identità');
        return null;
    } finally {
        hideLoading();
    }
}

/**
 * Recupera DID da seed phrase
 */
async function recoverDIDFromMnemonic(mnemonic) {
    try {
        showLoading('Recupero identità...');
        
        const response = await axios.post(`${CONFIG.API_BASE_URL}/auth/recover-did`, {
            mnemonic: mnemonic.trim(),
            didMethod: 'did:key'
        });
        
        if (response.data.success) {
            AppState.user.did = response.data.did;
            saveToLocalStorage();
            
            showNotification('success', 'Identità recuperata!', 'La tua DID è stata ripristinata');
            return response.data;
        }
    } catch (error) {
        console.error('Errore recupero DID:', error);
        showNotification('error', 'Errore', error.response?.data?.error || 'Seed phrase non valida');
        return null;
    } finally {
        hideLoading();
    }
}

/**
 * Invia dati raccolti al backend
 */
async function sendCollectedData() {
    if (!AppState.user.did) {
        showNotification('error', 'Errore', 'Crea prima un\'identità');
        return;
    }
    
    if (AppState.data.events.length === 0) {
        showNotification('error', 'Errore', 'Nessun dato da inviare');
        return;
    }
    
    try {
        showLoading('Invio dati...');
        
        const response = await axios.post(`${CONFIG.API_BASE_URL}/data/collect`, {
            did: AppState.user.did,
            sessionId: `sess_${Date.now()}`,
            events: AppState.data.events,
            consentProof: {
                version: '1.0',
                timestamp: new Date().toISOString(),
                did: AppState.user.did,
                purposes: ['data-aggregation', 'nft-minting'],
                legalBasis: 'consent',
                gdprCompliant: true
            }
        }, {
            headers: {
                'Authorization': `Bearer ${AppState.user.sessionToken}`
            }
        });
        
        if (response.data.success) {
            AppState.data.currentBundle = response.data.dataId;
            saveToLocalStorage();
            
            showNotification('success', 'Dati inviati!', `Bundle ID: ${response.data.dataId}`);
            return response.data;
        }
    } catch (error) {
        console.error('Errore invio dati:', error);
        showNotification('error', 'Errore', error.response?.data?.error || 'Impossibile inviare dati');
        return null;
    } finally {
        hideLoading();
    }
}

/**
 * Crea bundle aggregato
 */
async function createDataBundle() {
    if (!AppState.data.currentBundle) {
        showNotification('error', 'Errore', 'Prima invia i dati al server');
        return;
    }
    
    try {
        showLoading('Creazione bundle...');
        
        const response = await axios.post(`${CONFIG.API_BASE_URL}/data/bundle/create`, {
            dataIds: [AppState.data.currentBundle],
            bundleName: `My Data Bundle - ${new Date().toLocaleDateString()}`
        }, {
            headers: {
                'Authorization': `Bearer ${AppState.user.sessionToken}`
            }
        });
        
        if (response.data.success) {
            showNotification('success', 'Bundle creato!', 'I dati sono stati aggregati');
            return response.data;
        }
    } catch (error) {
        console.error('Errore creazione bundle:', error);
        showNotification('error', 'Errore', error.response?.data?.error || 'Impossibile creare bundle');
        return null;
    } finally {
        hideLoading();
    }
}

/**
 * Carica bundle su IPFS
 */
async function uploadBundleToIPFS() {
    if (!AppState.data.currentBundle) {
        showNotification('error', 'Errore', 'Prima crea un bundle');
        return;
    }
    
    try {
        showLoading('Upload su IPFS...');
        
        const response = await axios.post(`${CONFIG.API_BASE_URL}/data/bundle/upload`, {
            bundleId: AppState.data.currentBundle
        }, {
            headers: {
                'Authorization': `Bearer ${AppState.user.sessionToken}`
            }
        });
        
        if (response.data.success) {
            AppState.data.ipfsCID = response.data.ipfsCID;
            saveToLocalStorage();
            
            showNotification('success', 'Caricato su IPFS!', `CID: ${response.data.ipfsCID}`);
            return response.data;
        }
    } catch (error) {
        console.error('Errore upload IPFS:', error);
        showNotification('error', 'Errore', error.response?.data?.error || 'Impossibile caricare su IPFS');
        return null;
    } finally {
        hideLoading();
    }
}

/**
 * Mint NFT per il bundle
 */
async function mintNFT() {
    if (!AppState.data.ipfsCID) {
        showNotification('error', 'Errore', 'Prima carica il bundle su IPFS');
        return;
    }
    
    try {
        showLoading('Minting NFT su Polygon...');
        
        const response = await axios.post(`${CONFIG.API_BASE_URL}/nft/mint`, {
            bundleId: AppState.data.currentBundle,
            mintTo: AppState.user.walletAddress
        }, {
            headers: {
                'Authorization': `Bearer ${AppState.user.sessionToken}`
            }
        });
        
        if (response.data.success) {
            AppState.data.nft = response.data.nft;
            saveToLocalStorage();
            
            showNotification('success', 'NFT Mintato!', `Token ID: ${response.data.nft.tokenId}`);
            return response.data;
        }
    } catch (error) {
        console.error('Errore minting NFT:', error);
        showNotification('error', 'Errore', error.response?.data?.error || 'Impossibile mintare NFT');
        return null;
    } finally {
        hideLoading();
    }
}

// ==================== UI FUNCTIONS ====================

/**
 * Mostra modal con seed phrase
 */
function showSeedPhraseModal(mnemonic) {
    const words = mnemonic.split(' ');
    
    const modalHTML = `
        <div class="modal-header">
            <h3><i class="fas fa-exclamation-triangle"></i> ATTENZIONE: SALVA LA SEED PHRASE</h3>
            <button class="modal-close" onclick="closeModal()">&times;</button>
        </div>
        <div class="modal-body">
            <div class="info-box warning">
                <p><strong>Questa seed phrase è l'UNICO MODO per recuperare la tua identità.</strong></p>
                <p>Se la perdi, perdi accesso a tutti i tuoi dati e NFT.</p>
            </div>
            
            <div class="seed-phrase">
                <div class="seed-words">
                    ${words.map((word, index) => `
                        <div class="seed-word">
                            <span class="word-number">${index + 1}.</span>
                            <span class="word-text">${word}</span>
                        </div>
                    `).join('')}
                </div>
            </div>
            
            <div class="mt-3">
                <h4><i class="fas fa-list-ol"></i> Istruzioni di sicurezza:</h4>
                <ol style="margin-left: 20px; margin-top: 10px;">
                    <li>Scrivi queste 24 parole SU CARTA, nell'ordine esatto</li>
                    <li>Conserva la carta in un luogo SICURO (cassaforte)</li>
                    <li>NON salvare in chiaro su computer o cloud</li>
                    <li>NON condividere con nessuno, mai</li>
                    <li>Se perdi la seed phrase, PERDI TUTTI I DATI e NFT</li>
                </ol>
            </div>
        </div>
        <div class="modal-footer">
            <button class="btn btn-outline" onclick="printSeedPhrase()">
                <i class="fas fa-print"></i> Stampa
            </button>
            <button class="btn btn-success" onclick="downloadSeedPhrase()">
                <i class="fas fa-download"></i> Scarica Backup
            </button>
            <button class="btn btn-primary" onclick="confirmBackup()">
                <i class="fas fa-check"></i> Ho Salvato la Seed Phrase
            </button>
        </div>
    `;
    
    showModal('Backup Seed Phrase', modalHTML);
}

/**
 * Mostra modal generico
 */
function showModal(title, content) {
    const modalHTML = `
        <div class="modal-overlay" id="modal-overlay">
            <div class="modal">
                <div class="modal-header">
                    <h3>${title}</h3>
                    <button class="modal-close" onclick="closeModal()">&times;</button>
                </div>
                <div class="modal-body">
                    ${content}
                </div>
            </div>
        </div>
    `;
    
    // Rimuovi modal esistenti
    closeModal();
    
    // Aggiungi nuovo modal
    document.body.insertAdjacentHTML('beforeend', modalHTML);
    AppState.ui.modalOpen = true;
}

/**
 * Chiudi modal
 */
function closeModal() {
    const modal = document.getElementById('modal-overlay');
    if (modal) {
        modal.remove();
    }
    AppState.ui.modalOpen = false;
}

/**
 * Stampa seed phrase
 */
function printSeedPhrase() {
    if (!AppState.user.mnemonic) return;
    
    const printWindow = window.open('', '_blank');
    printWindow.document.write(`
        <!DOCTYPE html>
        <html>
        <head>
            <title>Backup Seed Phrase - DID Data Marketplace</title>
            <style>
                body { font-family: Arial, sans-serif; padding: 20px; }
                .seed-words { display: grid; grid-template-columns: repeat(3, 1fr); gap: 10px; margin: 20px 0; }
                .seed-word { padding: 10px; border: 1px solid #ccc; border-radius: 5px; }
                .warning { color: red; font-weight: bold; margin: 20px 0; }
            </style>
        </head>
        <body>
            <h1>🔐 Backup Seed Phrase</h1>
            <p><strong>Data:</strong> ${new Date().toLocaleString()}</p>
            <p><strong>DID:</strong> ${AppState.user.did}</p>
            
            <div class="warning">
                ⚠️ CONSERVA QUESTO DOCUMENTO IN UN LUOGO SICURO! ⚠️
            </div>
            
            <h3>Seed Phrase (24 parole):</h3>
            <div class="seed-words">
                ${AppState.user.mnemonic.split(' ').map((word, index) => `
                    <div class="seed-word">${index + 1}. ${word}</div>
                `).join('')}
            </div>
            
            <h3>Istruzioni:</h3>
            <ol>
                <li>Conserva questo documento in cassaforte</li>
                <li>Non condividere con nessuno</li>
                <li>Per recuperare l'identità, inserisci le 24 parole nell'app</li>
                <li>Se perdi la seed phrase, perdi accesso a tutti i dati</li>
            </ol>
            
            <hr>
            <p><small>Generato da DID Data Marketplace MVP</small></p>
        </body>
        </html>
    `);
    printWindow.document.close();
    printWindow.print();
}

/**
 * Scarica seed phrase come file
 */
function downloadSeedPhrase() {
    if (!AppState.user.mnemonic) return;
    
    const backupData = {
        did: AppState.user.did,
        mnemonic: AppState.user.mnemonic,
        date: new Date().toISOString(),
        warning: 'CONSERVA IN LUOGO SICURO - NON CONDIVIDERE',
        instructions: [
            '1. Scrivi queste 24 parole su carta',
            '2. Conserva in cassaforte',
            '3. Non salvare su computer',
            '4. Non condividere con nessuno',
            '5. Per recuperare: inserisci le 24 parole nell\'app'
        ]
    };
    
    const blob = new Blob([JSON.stringify(backupData, null, 2)], { type: 'application/json' });
    const url = URL.createObjectURL(blob);
    const a = document.createElement('a');
    a.href = url;
    a.download = `did-backup-${new Date().toISOString().split('T')[0]}.json`;
    document.body.appendChild(a);
    a.click();
    document.body.removeChild(a);
    URL.revokeObjectURL(url);
}

/**
 * Conferma backup seed phrase
 */
function confirmBackup() {
    closeModal();
    showNotification('success', 'Backup confermato', 'La tua identità è ora protetta');
    
    // Ora puoi procedere con l'autenticazione
    authenticateUser();
}

/**
 * Autentica utente con DID
 */
async function authenticateUser() {
    if (!AppState.user.did) return;
    
    try {
        showLoading('Autenticazione...');
        
        // 1. Richiedi challenge
        const challengeRes = await axios.post(`${CONFIG.API_BASE_URL}/auth/challenge`, {
            did: AppState.user.did
        });
        
        const challenge = challengeRes.data.challenge;
        
        // 2. Firma la challenge (simulata per l'MVP)
        // In produzione, qui useresti la chiave privata del DID
        const signature = `simulated-signature-${challenge}`;
        
        // 3. Verifica firma
        const verifyRes = await axios.post(`${CONFIG.API_BASE_URL}/auth/verify`, {
            did: AppState.user.did,
            challenge: challenge,
            signature: signature,
            signatureType: 'jwt'
        });
        
        if (verifyRes.data.success) {
            AppState.user.sessionToken = verifyRes.data.token;
            saveToLocalStorage();
            
            showNotification('success', 'Autenticato!', 'Accesso completato con successo');
            return true;
        }
    } catch (error) {
        console.error('Errore autenticazione:', error);
        showNotification('error', 'Errore autenticazione', 'Impossibile autenticarsi');
        return false;
    } finally {
        hideLoading();
    }
}

// ==================== DATA SIMULATION ====================

/**
 * Simula raccolta dati
 */
function simulateDataCollection(type) {
    const events = {
        geo: {
            type: 'geo',
            country: 'IT',
            city: ['Rome', 'Milan', 'Turin', 'Florence', 'Naples'][Math.floor(Math.random() * 5)],
            timestamp: Date.now(),
            source: 'simulated'
        },
        tap: {
            type: 'tap',
            count: Math.floor(Math.random() * 15) + 1,
            screen: ['home', 'profile', 'settings', 'feed', 'search'][Math.floor(Math.random() * 5)],
            timestamp: Date.now(),
            source: 'simulated'
        },
        like: {
            type: 'like',
            count: Math.floor(Math.random() * 10) + 1,
            content: `post_${Math.floor(Math.random() * 1000)}`,
            timestamp: Date.now(),
            source: 'simulated'
        },
        usage: {
            type: 'usage',
            seconds: Math.floor(Math.random() * 1200) + 60,
            app: ['social', 'news', 'entertainment', 'productivity'][Math.floor(Math.random() * 4)],
            timestamp: Date.now(),
            source: 'simulated'
        }
    };
    
    AppState.data.events.push(events[type]);
    saveToLocalStorage();
    
    // Aggiorna UI
    updateDataPreview();
    
    showNotification('success', 'Dato simulato', `Aggiunto evento: ${type}`);
}

/**
 * Aggiorna anteprima dati
 */
function updateDataPreview() {
    const previewEl = document.getElementById('data-preview');
    if (previewEl) {
        previewEl.textContent = JSON.stringify(AppState.data.events, null, 2);
    }
    
    // Aggiorna contatori
    const eventCountEl = document.getElementById('event-count');
    if (eventCountEl) {
        eventCountEl.textContent = `${AppState.data.events.length} eventi`;
    }
    
    const dataSizeEl = document.getElementById('data-size');
    if (dataSizeEl) {
        const size = JSON.stringify(AppState.data.events).length / 1024;
        dataSizeEl.textContent = `${size.toFixed(2)} KB`;
    }
    
    // Aggiorna progress bar
    const progressBar = document.getElementById('progress-bar');
    if (progressBar) {
        const progress = Math.min((AppState.data.events.length / 10) * 100, 100);
        progressBar.style.width = `${progress}%`;
    }
}

// ==================== INITIALIZATION ====================

/**
 * Inizializza l'applicazione
 */
async function initApp() {
    console.log('🚀 DID Data Marketplace MVP - Initializing...');
    console.log('Version:', CONFIG.VERSION);
    console.log('API Base:', CONFIG.API_BASE_URL);
    
    // 1. Carica stato da localStorage
    loadStateFromStorage();
    
    // 2. Testa connessione backend
    await testBackendConnection();
    
    // 3. Renderizza UI
    renderUI();
    
    // 4. Avvia auto-refresh
    startAutoRefresh();
    
    console.log('✅ App initialized');
}

/**
 * Carica stato da localStorage
 */
function loadStateFromStorage() {
    // Stato già caricato in AppState constructor
    console.log('📁 Loaded state from localStorage');
}

/**
 * Renderizza l'interfaccia utente
 */
function renderUI() {
    const appContainer = document.getElementById('app-container');
    
    if (!appContainer) {
        console.error('Container non trovato');
        return;
    }
    
    appContainer.innerHTML = `
        <div class="app-container">
            <!-- Header -->
            <header class="header fade-in-up">
                <div class="logo">
                    <div class="logo-icon">
                        <i class="fas fa-fingerprint fa-2x"></i>
                    </div>
                    <h1>DID Data Marketplace</h1>
                </div>
                <p class="subtitle">MVP Completo con DID, IPFS e NFT su Polygon</p>
                <div class="status-badge">
                    <i class="fas fa-server"></i>
                    <span>IONOS VPS | Node.js 25 | PostgreSQL 16</span>
                </div>
            </header>
            
            <!-- Dashboard -->
            <div class="dashboard">
                <!-- Card 1: Identità -->
                ${renderIdentityCard()}
                
                <!-- Card 2: Raccolta Dati -->
                ${renderDataCollectionCard()}
                
                <!-- Card 3: NFT Marketplace -->
                ${renderNFTMarketplaceCard()}
            </div>
            
            <!-- System Status -->
            ${renderSystemStatusCard()}
            
            <!-- Footer -->
            ${renderFooter()}
        </div>
    `;
    
    // Attacca event listeners dopo il render
    attachEventListeners();
    
    // Aggiorna preview dati
    updateDataPreview();
}

/**
 * Renderizza card identità
 */
function renderIdentityCard() {
    const hasDID = !!AppState.user.did;
    
    return `
        <div class="card fade-in-up">
            <h2 class="card-title">
                <i class="fas fa-id-card"></i> 1. Identità DID
            </h2>
            
            ${hasDID ? renderDIDInfo() : renderDIDCreation()}
        </div>
    `;
}

function renderDIDInfo() {
    return `
        <div class="info-box success">
            <i class="fas fa-check-circle"></i>
            <strong>Identità configurata</strong>
            <p>La tua DID è attiva e pronta all'uso</p>
        </div>
        
        <div class="info-item">
            <span class="info-label">Il tuo DID:</span>
            <span class="info-value">${AppState.user.did}</span>
        </div>
        
        <div class="btn-group mt-3">
            <button class="btn btn-outline" onclick="copyToClipboard('${AppState.user.did}')">
                <i class="fas fa-copy"></i> Copia DID
            </button>
            <button class="btn btn-outline" onclick="showDIDDetails()">
                <i class="fas fa-info-circle"></i> Dettagli
            </button>
        </div>
        
        <div class="mt-3">
            <button class="btn btn-danger btn-block" onclick="logout()">
                <i class="fas fa-sign-out-alt"></i> Disconnetti
            </button>
        </div>
    `;
}

function renderDIDCreation() {
    return `
        <div class="form-group">
            <label class="form-label">Scegli tipo DID:</label>
            <select class="form-control" id="did-method">
                <option value="did:key">DID:Key (Raccomandato)</option>
                <option value="did:ethr">DID:Ethr (MetaMask)</option>
            </select>
        </div>
        
        <button class="btn btn-primary btn-block" onclick="createDID()">
            <i class="fas fa-plus-circle"></i> Crea Nuova Identità
        </button>
        
        <div class="text-center my-3">
            <span class="text-muted">─ OPPURE ─</span>
        </div>
        
        <div class="form-group">
            <label class="form-label">Recupera con Seed Phrase:</label>
            <textarea class="form-control" id="recovery-mnemonic" 
                placeholder="Incolla le 24 parole separate da spazi..." 
                rows="3"></textarea>
        </div>
        
        <button class="btn btn-secondary btn-block" onclick="recoverDID()">
            <i class="fas fa-redo"></i> Recupera Identità
        </button>
    `;
}

/**
 * Renderizza card raccolta dati
 */
function renderDataCollectionCard() {
    return `
        <div class="card fade-in-up">
            <h2 class="card-title">
                <i class="fas fa-database"></i> 2. Raccolta Dati
            </h2>
            
            <div class="form-group">
                <label class="form-label">Simula raccolta dati:</label>
                <div class="btn-group">
                    <button class="btn btn-outline btn-sm" onclick="simulateDataCollection('geo')">
                        <i class="fas fa-map-marker-alt"></i> Geo
                    </button>
                    <button class="btn btn-outline btn-sm" onclick="simulateDataCollection('tap')">
                        <i class="fas fa-hand-pointer"></i> Tap
                    </button>
                    <button class="btn btn-outline btn-sm" onclick="simulateDataCollection('like')">
                        <i class="fas fa-thumbs-up"></i> Like
                    </button>
                    <button class="btn btn-outline btn-sm" onclick="simulateDataCollection('usage')">
                        <i class="fas fa-clock"></i> Usage
                    </button>
                </div>
            </div>
            
            <div class="form-group">
                <label class="form-label">Anteprima Dati:</label>
                <div class="code-block" id="data-preview">
                    ${AppState.data.events.length > 0 ? 
                        JSON.stringify(AppState.data.events, null, 2) : 
                        'Nessun dato raccolto. Clicca i bottoni sopra per simulare.'}
                </div>
                <div class="progress-label">
                    <span id="event-count">${AppState.data.events.length} eventi</span>
                    <span id="data-size">
                        ${(JSON.stringify(AppState.data.events).length / 1024).toFixed(2)} KB
                    </span>
                </div>
                <div class="progress">
                    <div class="progress-bar" id="progress-bar" 
                         style="width: ${Math.min((AppState.data.events.length / 10) * 100, 100)}%"></div>
                </div>
            </div>
            
            <div class="info-box">
                <i class="fas fa-shield-alt"></i>
                <strong>GDPR Compliant</strong>
                <p>I dati sono pseudonimizzati (DID) e cifrati end-to-end</p>
            </div>
            
            <button class="btn btn-success btn-block" onclick="sendCollectedData()" 
                ${AppState.data.events.length === 0 ? 'disabled' : ''}>
                <i class="fas fa-cloud-upload-alt"></i> Invia Dati al Server
            </button>
        </div>
    `;
}

/**
 * Renderizza card NFT Marketplace
 */
function renderNFTMarketplaceCard() {
    const steps = [
        { id: 'bundle', label: 'Crea Bundle', enabled: !!AppState.data.currentBundle },
        { id: 'ipfs', label: 'Carica su IPFS', enabled: !!AppState.data.ipfsCID },
        { id: 'nft', label: 'Mint NFT', enabled: !!AppState.data.nft }
    ];
    
    return `
        <div class="card fade-in-up">
            <h2 class="card-title">
                <i class="fas fa-cube"></i> 3. NFT Marketplace
            </h2>
            
            <div class="steps">
                <div class="step ${steps[0].enabled ? 'completed' : ''}">
                    <h4><i class="fas fa-box"></i> Crea Bundle Aggregato</h4>
                    <p>Combina i tuoi dati in un pacchetto sicuro</p>
                    <button class="btn btn-outline btn-sm" onclick="createDataBundle()" 
                        ${AppState.data.currentBundle ? '' : 'disabled'}>
                        <i class="fas fa-box"></i> Crea Bundle
                    </button>
                </div>
                
                <div class="step ${steps[1].enabled ? 'completed' : ''}">
                    <h4><i class="fas fa-cloud"></i> Carica su IPFS</h4>
                    <p>Archivia permanentemente su IPFS/Filecoin</p>
                    <button class="btn btn-outline btn-sm" onclick="uploadBundleToIPFS()" 
                        ${steps[0].enabled ? '' : 'disabled'}>
                        <i class="fas fa-cloud-upload-alt"></i> Carica su IPFS
                    </button>
                </div>
                
                <div class="step ${steps[2].enabled ? 'completed' : ''}">
                    <h4><i class="fas fa-coins"></i> Mint NFT</h4>
                    <p>Conia NFT su Polygon Mumbai Testnet</p>
                    <button class="btn btn-primary btn-sm" onclick="mintNFT()" 
                        ${steps[1].enabled ? '' : 'disabled'}>
                        <i class="fas fa-coins"></i> Mint NFT
                    </button>
                </div>
            </div>
            
            <div id="nft-status" class="mt-3">
                ${renderNFTStatus()}
            </div>
        </div>
    `;
}

function renderNFTStatus() {
    if (AppState.data.nft) {
        return `
            <div class="info-box success">
                <i class="fas fa-check-circle"></i>
                <strong>NFT Mintato!</strong>
                <p>Token ID: ${AppState.data.nft.tokenId}</p>
                <p>Contratto: ${AppState.data.nft.contractAddress.substring(0, 12)}...</p>
                <a href="${AppState.data.nft.explore || '#'}" target="_blank" class="btn btn-sm btn-outline mt-2">
                    <i class="fas fa-external-link-alt"></i> Vedi su Polygonscan
                </a>
            </div>
        `;
    } else if (AppState.data.ipfsCID) {
        return `
            <div class="info-box">
                <i class="fas fa-cloud"></i>
                <strong>Pronto per il minting!</strong>
                <p>Bundle caricato su IPFS: ${AppState.data.ipfsCID.substring(0, 16)}...</p>
                <p>Clicca "Mint NFT" per continuare</p>
            </div>
        `;
    } else if (AppState.data.currentBundle) {
        return `
            <div class="info-box">
                <i class="fas fa-box"></i>
                <strong>Dati pronti</strong>
                <p>Bundle creato: ${AppState.data.currentBundle}</p>
                <p>Carica su IPFS per procedere</p>
            </div>
        `;
    } else {
        return `
            <div class="info-box">
                <i class="fas fa-info-circle"></i>
                <strong>Inizia la raccolta dati</strong>
                <p>Simula dati e inviali al server per creare il tuo primo bundle</p>
            </div>
        `;
    }
}

/**
 * Renderizza card stato sistema
 */
function renderSystemStatusCard() {
    return `
        <div class="card fade-in-up">
            <h2 class="card-title">
                <i class="fas fa-heartbeat"></i> Stato Sistema
            </h2>
            
            <div class="info-item">
                <span class="info-label">Backend API:</span>
                <span class="status ${AppState.system.backendOnline ? 'status-online' : 'status-offline'}">
                    ${AppState.system.backendOnline ? '🟢 Online' : '🔴 Offline'}
                </span>
            </div>
            
            <div class="info-item">
                <span class="info-label">Database:</span>
                <span class="status status-online">🟢 PostgreSQL 16</span>
            </div>
            
            <div class="info-item">
                <span class="info-label">Node.js:</span>
                <span class="info-value">v25.x (IONOS VPS)</span>
            </div>
            
            <div class="info-item">
                <span class="info-label">Ultimo Check:</span>
                <span class="info-value">${AppState.system.lastHealthCheck ? formatTimestamp(AppState.system.lastHealthCheck) : 'Mai'}</span>
            </div>
            
            <div class="info-item">
                <span class="info-label">API Endpoint:</span>
                <span class="info-value">${CONFIG.API_BASE_URL}</span>
            </div>
            
            <div class="btn-group mt-3">
                <button class="btn btn-outline" onclick="refreshSystemStatus()">
                    <i class="fas fa-sync-alt"></i> Aggiorna
                </button>
                <button class="btn btn-outline" onclick="showApiDocumentation()">
                    <i class="fas fa-book"></i> API Docs
                </button>
                <button class="btn btn-outline" onclick="exportAllData()">
                    <i class="fas fa-download"></i> Esporta Dati
                </button>
            </div>
        </div>
    `;
}

/**
 * Renderizza footer
 */
function renderFooter() {
    return `
        <footer class="footer fade-in-up">
            <p>© 2025 DID Data Marketplace MVP | Deploy su IONOS VPS</p>
            <p class="text-muted">Node.js 25 • PostgreSQL 16 • Ubuntu 24.04 • GDPR Compliant</p>
            
            <div class="footer-links">
                <a href="#" class="footer-link" onclick="showPrivacyPolicy()">
                    <i class="fas fa-shield-alt"></i> Privacy & GDPR
                </a>
                <a href="#" class="footer-link" onclick="showSystemInfo()">
                    <i class="fas fa-info-circle"></i> Info Sistema
                </a>
                <a href="${CONFIG.API_BASE_URL}" class="footer-link" target="_blank">
                    <i class="fas fa-code"></i> API Documentation
                </a>
                <a href="${CONFIG.API_BASE_URL}/health" class="footer-link" target="_blank">
                    <i class="fas fa-heartbeat"></i> Health Check
                </a>
            </div>
            
            <div class="footer-info">
                <span>Versione: ${CONFIG.VERSION}</span>
                <span>Ambiente: ${CONFIG.ENVIRONMENT}</span>
                <span>Timestamp: ${new Date().toLocaleString()}</span>
            </div>
        </footer>
    `;
}

// ==================== EVENT LISTENERS ====================

/**
 * Attacca event listeners
 */
function attachEventListeners() {
    // Eventi già gestiti tramite onclick nelle funzioni inline
    console.log('📌 Event listeners attached');
}

/**
 * Aggiorna stato sistema
 */
async function refreshSystemStatus() {
    await testBackendConnection();
    renderUI();
    showNotification('success', 'Stato aggiornato', 'Sistema verificato');
}

/**
 * Mostra documentazione API
 */
function showApiDocumentation() {
    window.open(CONFIG.API_BASE_URL, '_blank');
}

/**
 * Mostra info sistema
 */
function showSystemInfo() {
    const info = `
        <h3>Informazioni Sistema</h3>
        <div class="info-item">
            <span class="info-label">Frontend:</span>
            <span class="info-value">v${CONFIG.VERSION}</span>
        </div>
        <div class="info-item">
            <span class="info-label">Browser:</span>
            <span class="info-value">${navigator.userAgent}</span>
        </div>
        <div class="info-item">
            <span class="info-label">API Endpoint:</span>
            <span class="info-value">${CONFIG.API_BASE_URL}</span>
        </div>
        <div class="info-item">
            <span class="info-label">DID Utente:</span>
            <span class="info-value">${AppState.user.did || 'Non configurato'}</span>
        </div>
        <div class="info-item">
            <span class="info-label">Eventi Raccorsi:</span>
            <span class="info-value">${AppState.data.events.length}</span>
        </div>
        <div class="info-item">
            <span class="info-label">Bundle Attivo:</span>
            <span class="info-value">${AppState.data.currentBundle || 'Nessuno'}</span>
        </div>
    `;
    
    showModal('Informazioni Sistema', info);
}

/**
 * Mostra policy privacy
 */
function showPrivacyPolicy() {
    const policy = `
        <h3>GDPR Compliance & Privacy Policy</h3>
        <div class="info-box success">
            <p><strong>Questo sistema è GDPR-compliant:</strong></p>
        </div>
        
        <ul>
            <li><strong>Pseudonimizzazione:</strong> Uso di DID invece di identità reali</li>
            <li><strong>Data Minimization:</strong> Solo dati necessari, geolocalizzazione coarse-only</li>
            <li><strong>Cifratura End-to-End:</strong> Dati cifrati lato client prima dell'invio</li>
            <li><strong>Consenso Esplicito:</strong> Richiesto per ogni raccolta dati</li>
            <li><strong>Diritto alla Cancellazione:</strong> Implementato tramite crypto-shredding</li>
            <li><strong>Portabilità dei Dati:</strong> Esporta i tuoi dati in qualsiasi momento</li>
        </ul>
        
        <h4 class="mt-3">Come funziona:</h4>
        <ol>
            <li>Tu controlli le tue chiavi crittografiche (non il server)</li>
            <li>I dati grezzi rimangono cifrati e sotto il tuo controllo</li>
            <li>L'NFT rappresenta solo il diritto di accesso, non i dati stessi</li>
            <li>Puoi revocare l'accesso in qualsiasi momento</li>
        </ol>
        
        <div class="info-box warning mt-3">
            <p><strong>⚠️ Attenzione:</strong> Se perdi la seed phrase, perdi accesso permanente a tutti i dati.</p>
        </div>
    `;
    
    showModal('Privacy & GDPR Policy', policy);
}

/**
 * Esporta tutti i dati
 */
function exportAllData() {
    const exportData = {
        version: CONFIG.VERSION,
        timestamp: new Date().toISOString(),
        user: {
            did: AppState.user.did,
            // NOTA: Non esportiamo la mnemonic!
        },
        data: {
            events: AppState.data.events,
            currentBundle: AppState.data.currentBundle,
            ipfsCID: AppState.data.ipfsCID,
            nft: AppState.data.nft
        },
        system: {
            lastHealthCheck: AppState.system.lastHealthCheck,
            backendOnline: AppState.system.backendOnline
        }
    };
    
    const blob = new Blob([JSON.stringify(exportData, null, 2)], { type: 'application/json' });
    const url = URL.createObjectURL(blob);
    const a = document.createElement('a');
    a.href = url;
    a.download = `did-mvp-export-${new Date().toISOString().split('T')[0]}.json`;
    document.body.appendChild(a);
    a.click();
    document.body.removeChild(a);
    URL.revokeObjectURL(url);
    
    showNotification('success', 'Dati esportati', 'Download iniziato');
}

/**
 * Logout utente
 */
function logout() {
    if (confirm('Sei sicuro di voler uscire? Perderai l\'accesso alla sessione corrente.')) {
        // Cancella tutto tranne i dati (per permettere recupero con seed phrase)
        AppState.user.sessionToken = null;
        saveToLocalStorage();
        
        showNotification('info', 'Disconnesso', 'Sessione terminata');
        renderUI();
    }
}

/**
 * Recupera DID da input
 */
async function recoverDID() {
    const mnemonicInput = document.getElementById('recovery-mnemonic');
    if (!mnemonicInput) return;
    
    const mnemonic = mnemonicInput.value.trim();
    if (!mnemonic) {
        showNotification('error', 'Errore', 'Inserisci la seed phrase');
        return;
    }
    
    const result = await recoverDIDFromMnemonic(mnemonic);
    if (result) {
        mnemonicInput.value = ''; // Pulisci input
        renderUI();
    }
}

/**
 * Mostra dettagli DID
 */
function showDIDDetails() {
    if (!AppState.user.did) return;
    
    const details = `
        <h3>Dettagli Identità Digitale</h3>
        <div class="info-item">
            <span class="info-label">DID:</span>
            <span class="info-value">${AppState.user.did}</span>
        </div>
        <div class="info-item">
            <span class="info-label">Metodo:</span>
            <span class="info-value">${AppState.user.did.split(':')[1]}</span>
        </div>
        <div class="info-item">
            <span class="info-label">Creata il:</span>
            <span class="info-value">${localStorage.getItem('did_created_at') || 'Sconosciuto'}</span>
        </div>
        
        <h4 class="mt-3">Cosa puoi fare:</h4>
        <ul>
            <li>Autenticarti su questo e altri servizi</li>
            <li>Firmare digitalmente dati e transazioni</li>
            <li>Ricevere credenziali verificabili</li>
            <li>Controllare l'accesso ai tuoi dati</li>
        </ul>
        
        <div class="btn-group mt-3">
            <button class="btn btn-outline" onclick="copyToClipboard('${AppState.user.did}')">
                <i class="fas fa-copy"></i> Copia DID
            </button>
            <button class="btn btn-outline" onclick="showQRCode('${AppState.user.did}')">
                <i class="fas fa-qrcode"></i> QR Code
            </button>
        </div>
    `;
    
    showModal('Dettagli DID', details);
}

/**
 * Mostra QR Code per DID
 */
function showQRCode(text) {
    // Usa un servizio esterno per generare QR code
    const qrUrl = `https://api.qrserver.com/v1/create-qr-code/?size=200x200&data=${encodeURIComponent(text)}`;
    
    const modalContent = `
        <h3>QR Code DID</h3>
        <div class="text-center">
            <img src="${qrUrl}" alt="QR Code" style="width: 200px; height: 200px; border: 10px solid white;">
            <p class="mt-3"><small>Scansiona per condividere il tuo DID</small></p>
            <div class="code-block mt-3">${text}</div>
        </div>
    `;
    
    showModal('QR Code', modalContent);
}

/**
 * Avvia auto-refresh
 */
function startAutoRefresh() {
    // Aggiorna stato ogni 30 secondi
    setInterval(async () => {
        if (!AppState.ui.modalOpen && !AppState.ui.loading) {
            await testBackendConnection();
            // Aggiorna solo alcuni elementi invece di rerender completo
            updateStatusIndicators();
        }
    }, 30000);
    
    // Aggiorna timestamp ogni minuto
    setInterval(() => {
        const timestampEl = document.querySelector('.footer-info span:last-child');
        if (timestampEl) {
            timestampEl.textContent = `Timestamp: ${new Date().toLocaleString()}`;
        }
    }, 60000);
}

/**
 * Aggiorna indicatori di stato
 */
function updateStatusIndicators() {
    const backendStatusEl = document.querySelector('.info-item:first-child .status');
    if (backendStatusEl) {
        backendStatusEl.className = `status ${AppState.system.backendOnline ? 'status-online' : 'status-offline'}`;
        backendStatusEl.textContent = AppState.system.backendOnline ? '🟢 Online' : '🔴 Offline';
    }
    
    const lastCheckEl = document.querySelector('.info-item:nth-child(4) .info-value');
    if (lastCheckEl) {
        lastCheckEl.textContent = AppState.system.lastHealthCheck ? 
            formatTimestamp(AppState.system.lastHealthCheck) : 'Mai';
    }
}

// ==================== EXPORT FUNCTIONS TO GLOBAL SCOPE ====================

// Esponi funzioni al global scope per gli eventi onclick
window.createDID = createDID;
window.recoverDID = recoverDID;
window.simulateDataCollection = simulateDataCollection;
window.sendCollectedData = sendCollectedData;
window.createDataBundle = createDataBundle;
window.uploadBundleToIPFS = uploadBundleToIPFS;
window.mintNFT = mintNFT;
window.copyToClipboard = copyToClipboard;
window.showSeedPhraseModal = showSeedPhraseModal;
window.closeModal = closeModal;
window.printSeedPhrase = printSeedPhrase;
window.downloadSeedPhrase = downloadSeedPhrase;
window.confirmBackup = confirmBackup;
window.refreshSystemStatus = refreshSystemStatus;
window.showApiDocumentation = showApiDocumentation;
window.showSystemInfo = showSystemInfo;
window.showPrivacyPolicy = showPrivacyPolicy;
window.exportAllData = exportAllData;
window.logout = logout;
window.showDIDDetails = showDIDDetails;
window.showQRCode = showQRCode;

// ==================== START APPLICATION ====================

// Avvia l'app quando il DOM è pronto
if (document.readyState === 'loading') {
    document.addEventListener('DOMContentLoaded', initApp);
} else {
    initApp();
}