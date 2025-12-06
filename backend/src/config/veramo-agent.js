import { createAgent } from '@veramo/core';
import { DIDManager } from '@veramo/did-manager';
import { KeyManager } from '@veramo/key-manager';
import { KeyManagementSystem } from '@veramo/kms-local';
import { DIDResolverPlugin } from '@veramo/did-resolver';
import { Resolver } from 'did-resolver';
import { getResolver as keyDidResolver } from 'key-did-resolver';
import { getResolver as ethrDidResolver } from 'ethr-did-resolver';
import { CredentialPlugin, CredentialIssuer } from '@veramo/credential-w3c';
import { DataSource } from 'typeorm';
import { Entities, KeyStore, DIDStore, PrivateKeyStore, migrations } from '@veramo/data-store';
import { DIDConfigurationPlugin } from '@veramo/did-configuration';

// Configurazione database PostgreSQL
const dbConnection = new DataSource({
  type: 'postgres',
  host: process.env.DB_HOST,
  port: parseInt(process.env.DB_PORT),
  username: process.env.DB_USER,
  password: process.env.DB_PASSWORD,
  database: process.env.DB_NAME,
  synchronize: false,
  migrationsRun: true,
  logging: process.env.NODE_ENV === 'development',
  entities: Entities,
  extra: {
    ssl: process.env.DB_SSL === 'true' ? {
      rejectUnauthorized: false
    } : false
  }
}).initialize();

// Provider did:ethr
const ethrProviderConfig = {
  defaultKms: 'local',
  networks: [
    {
      name: 'mainnet',
      rpcUrl: process.env.DID_ETHR_RPC,
      registry: '0xdca7ef03e98e0dc2b855be647c39abe984fcf21b',
    },
    {
      name: 'sepolia',
      rpcUrl: process.env.ETH_SEPOLIA_URL || 'https://sepolia.infura.io/v3/...',
      registry: '0x03d5003bf0e79c5f5223588f347eba39afbc3818',
    },
  ],
};

// Crea agente Veramo
export const agent = createAgent({
  plugins: [
    new KeyManager({
      store: new KeyStore(dbConnection),
      kms: {
        local: new KeyManagementSystem(new PrivateKeyStore(dbConnection, new TextEncoder())),
      },
    }),
    new DIDManager({
      store: new DIDStore(dbConnection),
      defaultProvider: process.env.DEFAULT_DID_PROVIDER || 'did:key',
      providers: {
        'did:key': {
          defaultKms: 'local',
        },
        'did:ethr': ethrProviderConfig,
      },
    }),
    new DIDResolverPlugin({
      resolver: new Resolver({
        ...keyDidResolver(),
        ...ethrDidResolver(ethrProviderConfig),
      }),
    }),
    new CredentialPlugin(),
    new CredentialIssuer(),
    new DIDConfigurationPlugin(),
  ],
});

// Utility per seed phrase
export async function generateSeedPhrase() {
  const { generateMnemonic, mnemonicToSeedSync } = await import('bip39');
  const mnemonic = generateMnemonic(256);
  const seed = mnemonicToSeedSync(mnemonic);
  return { mnemonic, seed };
}