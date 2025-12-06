import { agent } from '../config/veramo-agent.js';
import { randomBytes } from 'crypto';
import jwt from 'jsonwebtoken';
import { ethers } from 'ethers';
import { generateMnemonic, mnemonicToSeedSync, validateMnemonic } from 'bip39';
import { fromSeed } from 'bip32';

// In-memory store per challenges (in produzione usa Redis)
const challengeStore = new Map();

export class AuthController {
  /**
   * Crea un nuovo DID con backup seed phrase
   */
  static async createDIDWithBackup(req, res) {
    try {
      const { didMethod = 'did:key', alias, password } = req.body;
      
      // Genera seed phrase (24 parole)
      const mnemonic = generateMnemonic(256);
      const seed = mnemonicToSeedSync(mnemonic);
      
      // Deriva chiave privata dal seed
      const root = fromSeed(seed);
      const child = root.derivePath("m/44'/60'/0'/0/0");
      const privateKeyHex = child.privateKey.toString('hex');
      
      // Crea DID usando Veramo
      const identifier = await agent.didManagerCreate({
        provider: didMethod,
        alias: alias || `user-${Date.now()}`,
        options: {
          privateKeyHex,
          keyType: 'Secp256k1',
        },
      });
      
      // Crittografa la seed phrase se password fornita
      let encryptedMnemonic = null;
      if (password) {
        const crypto = await import('crypto');
        const cipher = crypto.createCipheriv(
          'aes-256-gcm',
          crypto.createHash('sha256').update(password).digest(),
          crypto.randomBytes(16)
        );
        encryptedMnemonic = Buffer.concat([
          cipher.update(mnemonic, 'utf8'),
          cipher.final(),
          cipher.getAuthTag()
        ]).toString('hex');
      }
      
      res.json({
        success: true,
        did: identifier.did,
        didDocument: identifier.didDocument,
        mnemonic, // INVIA SOLO UNA VOLTA
        warning: '⚠️ SALVA QUESTA SEED PHRASE! Non verrà mostrata di nuovo.',
        backupInstructions: [
          '1. Scrivi queste 24 parole su carta',
          '2. Conserva in cassaforte',
          '3. Non condividere mai con nessuno',
          '4. Se perdi la seed phrase, perdi accesso a tutti i dati'
        ],
        encryptedMnemonic,
        createdAt: new Date().toISOString(),
      });
      
    } catch (error) {
      console.error('DID creation error:', error);
      res.status(500).json({ 
        error: 'Failed to create DID', 
        details: error.message 
      });
    }
  }
  
  /**
   * Recupera DID da seed phrase
   */
  static async recoverDIDFromMnemonic(req, res) {
    try {
      const { mnemonic, didMethod = 'did:key' } = req.body;
      
      if (!validateMnemonic(mnemonic)) {
        return res.status(400).json({ error: 'Mnemonic non valido' });
      }
      
      const seed = mnemonicToSeedSync(mnemonic);
      const root = fromSeed(seed);
      const child = root.derivePath("m/44'/60'/0'/0/0");
      const privateKeyHex = child.privateKey.toString('hex');
      
      const identifier = await agent.didManagerCreate({
        provider: didMethod,
        alias: `recovered-${Date.now()}`,
        options: {
          privateKeyHex,
          keyType: 'Secp256k1',
        },
      });
      
      res.json({
        success: true,
        did: identifier.did,
        message: 'DID recuperato con successo',
        didDocument: identifier.didDocument,
      });
      
    } catch (error) {
      console.error('Recovery error:', error);
      res.status(500).json({ 
        error: 'Recovery failed', 
        details: error.message 
      });
    }
  }
  
  /**
   * Genera challenge per autenticazione
   */
  static async generateChallenge(req, res) {
    try {
      const { did } = req.body;
      if (!did) {
        return res.status(400).json({ error: 'DID is required' });
      }
      
      const challenge = randomBytes(32).toString('hex');
      const expiresAt = Date.now() + 300000; // 5 minuti
      
      challengeStore.set(did, { challenge, expiresAt });
      
      res.json({
        success: true,
        challenge,
        expiresAt,
        message: 'Firma questa challenge con la tua chiave privata',
      });
      
    } catch (error) {
      console.error('Challenge error:', error);
      res.status(500).json({ error: 'Internal server error' });
    }
  }
  
  /**
   * Verifica firma e rilascia JWT
   */
  static async verifySignature(req, res) {
    try {
      const { did, challenge, signature, signatureType = 'jwt' } = req.body;
      
      const stored = challengeStore.get(did);
      if (!stored || stored.challenge !== challenge) {
        return res.status(400).json({ error: 'Challenge non valido o scaduto' });
      }
      
      if (Date.now() > stored.expiresAt) {
        challengeStore.delete(did);
        return res.status(400).json({ error: 'Challenge scaduto' });
      }
      
      let isValid = false;
      
      // Verifica firma in base al tipo
      if (signatureType === 'jwt') {
        const verification = await agent.verifyJWT({
          jwt: signature,
          did,
        });
        isValid = verification.verified;
      } else if (signatureType === 'ethereum') {
        const recoveredAddress = ethers.verifyMessage(challenge, signature);
        const didDoc = await agent.resolveDid({ didUrl: did });
        const ethAddress = didDoc.didDocument?.verificationMethod?.[0]?.blockchainAccountId?.split(':')[2];
        isValid = recoveredAddress.toLowerCase() === ethAddress?.toLowerCase();
      }
      
      if (!isValid) {
        return res.status(401).json({ error: 'Firma non valida' });
      }
      
      // Challenge consumato
      challengeStore.delete(did);
      
      // Genera JWT
      const token = jwt.sign(
        {
          did,
          exp: Math.floor(Date.now() / 1000) + 3600,
          iat: Math.floor(Date.now() / 1000),
          scope: 'user',
        },
        process.env.JWT_SECRET,
        { algorithm: 'HS256' }
      );
      
      res.json({
        success: true,
        token,
        did,
        expiresIn: 3600,
      });
      
    } catch (error) {
      console.error('Verification error:', error);
      res.status(500).json({ error: 'Internal server error' });
    }
  }
}