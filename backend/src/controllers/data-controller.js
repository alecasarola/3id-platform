import { agent } from '../config/veramo-agent.js';
import { Web3Storage } from 'web3.storage';
import { randomBytes, createCipheriv, createDecipheriv, createHash } from 'crypto';
import jwt from 'jsonwebtoken';
import { ethers } from 'ethers';

// Configurazioni
const web3storage = new Web3Storage({ 
  token: process.env.WEB3_STORAGE_TOKEN 
});

// Storage temporaneo (in produzione usa database)
const dataVault = new Map();
const bundles = new Map();

export class DataController {
  /**
   * Ricevi e conserva dati dall'utente
   */
  static async collectData(req, res) {
    try {
      // Verifica autenticazione
      const authHeader = req.headers.authorization;
      if (!authHeader?.startsWith('Bearer ')) {
        return res.status(401).json({ error: 'Token mancante' });
      }
      
      const token = authHeader.split(' ')[1];
      let decoded;
      try {
        decoded = jwt.verify(token, process.env.JWT_SECRET);
      } catch (err) {
        return res.status(401).json({ error: 'Token non valido' });
      }
      
      const { did, sessionId, events, consentProof } = req.body;
      
      if (!did || !Array.isArray(events)) {
        return res.status(400).json({ error: 'DID e events array richiesti' });
      }
      
      if (decoded.did !== did) {
        return res.status(403).json({ error: 'DID non autorizzato' });
      }
      
      // Validazione GDPR: geolocalizzazione coarse-only
      const hasPreciseGeo = events.some(e => 
        e.type === 'geo' && 
        (e.latitude || e.longitude || e.precision < 1000 || e.ip)
      );
      
      if (hasPreciseGeo) {
        return res.status(400).json({ 
          error: 'Geolocalizzazione deve essere coarse (città/paese)',
          requirement: 'Usa solo "country" e "city", non coordinate precise'
        });
      }
      
      // Verifica consenso
      if (!consentProof) {
        return res.status(400).json({ error: 'Proof del consenso GDPR richiesta' });
      }
      
      // Genera ID dati
      const dataId = `data_${Date.now()}_${randomBytes(6).toString('hex')}`;
      const finalSessionId = sessionId || `sess_${Date.now()}_${randomBytes(4).toString('hex')}`;
      
      // Cifratura dati (envelope encryption)
      const dataKey = randomBytes(32);
      const iv = randomBytes(16);
      const cipher = createCipheriv('aes-256-gcm', dataKey, iv);
      
      const rawData = JSON.stringify({
        did,
        sessionId: finalSessionId,
        events,
        collectedAt: new Date().toISOString(),
        consentProof,
      });
      
      let encrypted = cipher.update(rawData, 'utf8', 'hex');
      encrypted += cipher.final('hex');
      const authTag = cipher.getAuthTag().toString('hex');
      
      // Calcola hash per integrità
      const dataHash = createHash('sha256').update(rawData).digest('hex');
      
      // Salva nel vault
      dataVault.set(dataId, {
        encrypted,
        iv: iv.toString('hex'),
        authTag,
        dataKey: dataKey.toString('hex'), // In produzione cifrare questa chiave
        metadata: {
          did,
          sessionId: finalSessionId,
          eventCount: events.length,
          collectedAt: new Date().toISOString(),
          dataHash,
        },
      });
      
      res.json({
        success: true,
        dataId,
        sessionId: finalSessionId,
        dataHash,
        message: 'Dati ricevuti e conservati cifrati',
        nextSteps: [
          'Usa /bundle/create per aggregare',
          'Poi /bundle/upload per IPFS',
        ],
      });
      
    } catch (error) {
      console.error('Data collection error:', error);
      res.status(500).json({ 
        error: 'Failed to collect data', 
        details: error.message 
      });
    }
  }
  
  /**
   * Crea bundle aggregato
   */
  static async createBundle(req, res) {
    try {
      const authHeader = req.headers.authorization;
      if (!authHeader?.startsWith('Bearer ')) {
        return res.status(401).json({ error: 'Token mancante' });
      }
      
      const token = authHeader.split(' ')[1];
      const decoded = jwt.verify(token, process.env.JWT_SECRET);
      const userDid = decoded.did;
      
      const { dataIds, bundleName } = req.body;
      
      // Recupera e aggrega dati
      const aggregatedData = {
        owner_did: userDid,
        period: { from: null, to: null },
        summary: {
          total_taps: 0,
          total_likes: 0,
          total_usage_seconds: 0,
          regions: new Set(),
          event_types: new Set(),
        },
      };
      
      for (const dataId of dataIds) {
        const data = dataVault.get(dataId);
        if (!data) continue;
        
        // Qui andrebbe la decifratura e processing reale
        // Per l'MVP simuliamo
        
        aggregatedData.summary.total_taps += Math.floor(Math.random() * 100);
        aggregatedData.summary.total_likes += Math.floor(Math.random() * 50);
        aggregatedData.summary.total_usage_seconds += Math.floor(Math.random() * 3600);
        aggregatedData.summary.regions.add('IT-Rome');
        aggregatedData.summary.regions.add('IT-Milan');
        aggregatedData.summary.event_types.add('geo');
        aggregatedData.summary.event_types.add('tap');
      }
      
      // Converti Set in Array
      aggregatedData.summary.regions = Array.from(aggregatedData.summary.regions);
      aggregatedData.summary.event_types = Array.from(aggregatedData.summary.event_types);
      
      // Crea bundle
      const bundleId = `bundle_${Date.now()}_${randomBytes(6).toString('hex')}`;
      const bundle = {
        bundleId,
        owner_did: userDid,
        createdAt: new Date().toISOString(),
        dataIds,
        aggregatedData,
        status: 'created',
      };
      
      bundles.set(bundleId, bundle);
      
      res.json({
        success: true,
        bundleId,
        bundleName: bundleName || `Data Bundle ${bundleId}`,
        aggregatedData: aggregatedData.summary,
        message: 'Bundle creato con successo',
      });
      
    } catch (error) {
      console.error('Bundle creation error:', error);
      res.status(500).json({ 
        error: 'Failed to create bundle', 
        details: error.message 
      });
    }
  }
  
  /**
   * Carica bundle su IPFS
   */
  static async uploadToIPFS(req, res) {
    try {
      const authHeader = req.headers.authorization;
      if (!authHeader?.startsWith('Bearer ')) {
        return res.status(401).json({ error: 'Token mancante' });
      }
      
      const token = authHeader.split(' ')[1];
      jwt.verify(token, process.env.JWT_SECRET);
      
      const { bundleId } = req.body;
      const bundle = bundles.get(bundleId);
      
      if (!bundle) {
        return res.status(404).json({ error: 'Bundle non trovato' });
      }
      
      // Prepara dati per IPFS
      const ipfsData = {
        schema: 'v1.0.behavior.bundle',
        version: '1.0',
        owner_did: bundle.owner_did,
        createdAt: bundle.createdAt,
        summary: bundle.aggregatedData,
        metadata: {
          privacyLevel: 'pseudonymized',
          gdprCompliant: true,
          dataMinimization: 'coarse-geo-only',
        },
      };
      
      // Upload su IPFS
      const file = new File(
        [JSON.stringify(ipfsData, null, 2)],
        `bundle-${bundleId}.json`,
        { type: 'application/json' }
      );
      
      const cid = await web3storage.put([file], {
        name: `DID-Data-Bundle-${bundleId}`,
      });
      
      // Aggiorna bundle
      bundle.ipfsCID = cid;
      bundle.ipfsURL = `https://${cid}.ipfs.w3s.link`;
      bundle.status = 'uploaded';
      bundle.uploadedAt = new Date().toISOString();
      
      // Calcola hash
      bundle.dataHash = createHash('sha256')
        .update(JSON.stringify(ipfsData))
        .digest('hex');
      
      res.json({
        success: true,
        bundleId,
        ipfsCID: cid,
        ipfsURL: bundle.ipfsURL,
        dataHash: bundle.dataHash,
        message: 'Bundle caricato su IPFS',
      });
      
    } catch (error) {
      console.error('IPFS upload error:', error);
      res.status(500).json({ 
        error: 'Failed to upload to IPFS', 
        details: error.message 
      });
    }
  }
}