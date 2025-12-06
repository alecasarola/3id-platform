import { ethers } from 'ethers';
import { bundles } from './data-controller.js';
import { Web3Storage } from 'web3.storage';

const web3storage = new Web3Storage({ 
  token: process.env.WEB3_STORAGE_TOKEN 
});

export class NFTController {
  /**
   * Mint NFT per un bundle dati
   */
  static async mintNFT(req, res) {
    try {
      const authHeader = req.headers.authorization;
      if (!authHeader?.startsWith('Bearer ')) {
        return res.status(401).json({ error: 'Token mancante' });
      }
      
      const token = authHeader.split(' ')[1];
      const decoded = jwt.verify(token, process.env.JWT_SECRET);
      
      const { bundleId, mintTo } = req.body;
      const bundle = bundles.get(bundleId);
      
      if (!bundle || bundle.status !== 'uploaded') {
        return res.status(404).json({ 
          error: 'Bundle non trovato o non caricato su IPFS'
        });
      }
      
      // Configura provider Polygon Mumbai
      const provider = new ethers.JsonRpcProvider(process.env.POLYGON_RPC_URL);
      const wallet = new ethers.Wallet(process.env.SERVER_PRIVATE_KEY, provider);
      
      // Simple ERC-721 ABI
      const contractABI = [
        "function safeMint(address to, string memory tokenURI) public returns (uint256)",
        "function tokenURI(uint256 tokenId) public view returns (string memory)",
        "event Transfer(address indexed from, address indexed to, uint256 indexed tokenId)"
      ];
      
      const contractAddress = process.env.NFT_CONTRACT_ADDRESS;
      const contract = new ethers.Contract(contractAddress, contractABI, wallet);
      
      // Crea metadata NFT
      const nftMetadata = {
        name: `Data Bundle #${bundleId}`,
        description: 'Aggregated behavior data bundle (GDPR compliant)',
        owner_did: bundle.owner_did,
        data_reference: bundle.ipfsURL,
        data_hash: bundle.dataHash,
        schema: 'v1.0.behavior.bundle',
        privacy: {
          level: 'pseudonymized',
          gdpr_compliant: true,
          data_minimization: 'coarse-geo-only',
        },
        external_url: bundle.ipfsURL,
        image: 'ipfs://Qm...', // Immagine placeholder
      };
      
      // Upload metadata su IPFS
      const metadataFile = new File(
        [JSON.stringify(nftMetadata, null, 2)],
        `metadata-${bundleId}.json`,
        { type: 'application/json' }
      );
      
      const metadataCID = await web3storage.put([metadataFile], {
        name: `NFT-Metadata-${bundleId}`,
      });
      
      const tokenURI = `ipfs://${metadataCID}`;
      
      // Mint NFT
      const tx = await contract.safeMint(
        mintTo || wallet.address, 
        tokenURI
      );
      
      const receipt = await tx.wait();
      
      // Estrai tokenId
      let tokenId = null;
      const transferEvent = receipt.logs.find(log => 
        log.topics[0] === ethers.id('Transfer(address,address,uint256)')
      );
      
      if (transferEvent) {
        tokenId = ethers.toBigInt(transferEvent.topics[3]).toString();
      }
      
      // Aggiorna bundle
      bundle.nft = {
        tokenId,
        contractAddress,
        transactionHash: tx.hash,
        tokenURI,
        mintedAt: new Date().toISOString(),
        owner: mintTo || wallet.address,
      };
      bundle.status = 'nft_minted';
      
      res.json({
        success: true,
        bundleId,
        nft: bundle.nft,
        transaction: {
          hash: tx.hash,
          blockNumber: receipt.blockNumber,
        },
        metadata: {
          cid: metadataCID,
          url: `https://${metadataCID}.ipfs.w3s.link`,
        },
        explore: `https://mumbai.polygonscan.com/tx/${tx.hash}`,
        message: 'NFT mintato su Polygon Mumbai',
      });
      
    } catch (error) {
      console.error('NFT minting error:', error);
      res.status(500).json({ 
        error: 'Failed to mint NFT', 
        details: error.message,
        suggestion: 'Verifica che il wallet abbia MATIC per gas'
      });
    }
  }
  
  /**
   * Ottieni status di un bundle
   */
  static async getBundleStatus(req, res) {
    try {
      const { bundleId } = req.params;
      const bundle = bundles.get(bundleId);
      
      if (!bundle) {
        return res.status(404).json({ error: 'Bundle non trovato' });
      }
      
      res.json({
        success: true,
        bundleId,
        status: bundle.status,
        ipfs: bundle.ipfsCID ? {
          cid: bundle.ipfsCID,
          url: bundle.ipfsURL,
        } : null,
        nft: bundle.nft || null,
        summary: bundle.aggregatedData?.summary || null,
        createdAt: bundle.createdAt,
      });
      
    } catch (error) {
      console.error('Status check error:', error);
      res.status(500).json({ 
        error: 'Failed to get status', 
        details: error.message 
      });
    }
  }
}