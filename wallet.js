// wallet.js
import WalletConnectProvider from 'https://esm.sh/@walletconnect/ethereum-provider@2';

let provider = null;

/**
 * Connects to WalletConnect on Sepolia and returns the first account address.
 * @returns {Promise<string>} The connected wallet address.
 */
export async function connectWallet() {
  if (!provider) {
    provider = await WalletConnectProvider.init({
      projectId: 'b483d3b3633faaf5ea62cb2c0069bd39',
      chains: [11155111],               // Sepolia only
      rpcMap: {
        11155111: 'https://rpc.sepolia.org'  // Public Sepolia RPC
      },
      showQrModal: true,
    });

    // Optional: subscribe to events
    provider.on('connect', (info) => {
      console.log('✅ WalletConnect connected:', info);
    });
    provider.on('accountsChanged', (accounts) => {
      console.log('🔄 Accounts changed:', accounts);
    });
    provider.on('chainChanged', (chainId) => {
      console.log('🌐 Chain changed to:', chainId);
    });
    provider.on('disconnect', (code, reason) => {
      console.log('❌ Disconnected:', code, reason);
      provider = null;
    });
  }

  // Trigger QR modal / deep link if not already connected
  const accounts = await provider.enable();
  return accounts[0];
}