import React, { useState, useEffect } from 'react';
import { AlertCircle, CheckCircle, Zap, Shield, Award, Loader } from 'lucide-react';
import { ethers } from 'ethers';

/**
 * MeeChain Contract Dashboard
 * Displays live contract data from MeeChain RPC
 * Shows MEEToken and MEEReward contract status
 */

interface ContractInfo {
  address: string;
  name: string;
  symbol?: string;
  type: 'token' | 'nft';
  chainId: number;
  deployed: boolean;
  bytecode: string;
  blockDeployed?: number;
  totalSupply?: string;
}

interface DashboardState {
  meeToken: ContractInfo | null;
  meeReward: ContractInfo | null;
  rpcStatus: 'connected' | 'connecting' | 'failed';
  lastUpdated: Date | null;
  loading: boolean;
  error: string | null;
}

const ContractDashboard: React.FC = () => {
  const [state, setState] = useState<DashboardState>({
    meeToken: null,
    meeReward: null,
    rpcStatus: 'connecting',
    lastUpdated: null,
    loading: true,
    error: null,
  });

  // Contract addresses (update with your deployed addresses)
  const CONTRACTS = {
    MEEToken: {
      address: process.env.REACT_APP_MEE_TOKEN_ADDRESS || '0x0',
      abi: [
        'function name() public view returns (string)',
        'function symbol() public view returns (string)',
        'function totalSupply() public view returns (uint256)',
        'function decimals() public view returns (uint8)',
        'function balanceOf(address) public view returns (uint256)',
      ],
    },
    MEEReward: {
      address: process.env.REACT_APP_MEE_REWARD_ADDRESS || '0x0',
      abi: [
        'function name() public view returns (string)',
        'function symbol() public view returns (string)',
        'function totalBadgesMinted() public view returns (uint256)',
      ],
    },
  };

  // Fetch contract data from RPC
  useEffect(() => {
    const fetchContractData = async () => {
      try {
        setState(prev => ({ ...prev, loading: true, error: null }));

        // Connect to MeeChain RPC
        const provider = new ethers.JsonRpcProvider(
          process.env.REACT_APP_MEECHAIN_RPC_URL || 'https://rpc.meechain.live'
        );

        // Test RPC connection
        try {
          await provider.getBlockNumber();
          setState(prev => ({ ...prev, rpcStatus: 'connected' }));
        } catch (err) {
          setState(prev => ({ 
            ...prev, 
            rpcStatus: 'failed',
            error: 'Failed to connect to MeeChain RPC'
          }));
          return;
        }

        // Fetch MEEToken data
        if (CONTRACTS.MEEToken.address !== '0x0') {
          try {
            const meeTokenContract = new ethers.Contract(
              CONTRACTS.MEEToken.address,
              CONTRACTS.MEEToken.abi,
              provider
            );

            const [name, symbol, totalSupply, decimals] = await Promise.all([
              meeTokenContract.name().catch(() => 'MEE Token'),
              meeTokenContract.symbol().catch(() => 'MEE'),
              meeTokenContract.totalSupply().catch(() => '0'),
              meeTokenContract.decimals().catch(() => 18),
            ]);

            const bytecode = await provider.getCode(CONTRACTS.MEEToken.address);

            setState(prev => ({
              ...prev,
              meeToken: {
                address: CONTRACTS.MEEToken.address,
                name: String(name),
                symbol: String(symbol),
                type: 'token',
                chainId: 13390,
                deployed: bytecode !== '0x',
                bytecode,
                totalSupply: ethers.formatUnits(totalSupply, decimals),
              },
            }));
          } catch (err) {
            console.error('Error fetching MEEToken data:', err);
          }
        }

        // Fetch MEEReward data
        if (CONTRACTS.MEEReward.address !== '0x0') {
          try {
            const meeRewardContract = new ethers.Contract(
              CONTRACTS.MEEReward.address,
              CONTRACTS.MEEReward.abi,
              provider
            );

            const [name, symbol, totalBadges] = await Promise.all([
              meeRewardContract.name().catch(() => 'MeeChain Reward'),
              meeRewardContract.symbol().catch(() => 'MEEBD'),
              meeRewardContract.totalBadgesMinted().catch(() => '0'),
            ]);

            const bytecode = await provider.getCode(CONTRACTS.MEEReward.address);

            setState(prev => ({
              ...prev,
              meeReward: {
                address: CONTRACTS.MEEReward.address,
                name: String(name),
                symbol: String(symbol),
                type: 'nft',
                chainId: 13390,
                deployed: bytecode !== '0x',
                bytecode,
                totalSupply: String(totalBadges),
              },
            }));
          } catch (err) {
            console.error('Error fetching MEEReward data:', err);
          }
        }

        setState(prev => ({
          ...prev,
          lastUpdated: new Date(),
          loading: false,
        }));
      } catch (err) {
        setState(prev => ({
          ...prev,
          error: String(err),
          loading: false,
        }));
      }
    };

    fetchContractData();

    // Refresh every 30 seconds
    const interval = setInterval(fetchContractData, 30000);
    return () => clearInterval(interval);
  }, []);

  const formatAddress = (addr: string) => {
    if (!addr || addr === '0x0') return 'Not deployed';
    return `${addr.slice(0, 6)}...${addr.slice(-4)}`;
  };

  return (
    <div className="min-h-screen bg-gradient-to-br from-slate-900 via-purple-900 to-slate-900 p-8">
      {/* Header */}
      <div className="max-w-6xl mx-auto">
        <div className="flex items-center justify-between mb-12">
          <div className="flex items-center gap-4">
            <div className="w-12 h-12 bg-gradient-to-br from-purple-400 to-pink-600 rounded-lg flex items-center justify-center">
              <Zap className="text-white w-6 h-6" />
            </div>
            <div>
              <h1 className="text-4xl font-bold text-white">MeeChain Dashboard</h1>
              <p className="text-purple-300 text-sm">Live Contract Status</p>
            </div>
          </div>

          {/* RPC Status */}
          <div className="flex items-center gap-3 px-4 py-2 rounded-lg bg-purple-500 bg-opacity-20 border border-purple-400 border-opacity-30">
            <div className={`w-3 h-3 rounded-full ${
              state.rpcStatus === 'connected' ? 'bg-green-400' : 
              state.rpcStatus === 'connecting' ? 'bg-yellow-400 animate-pulse' : 
              'bg-red-400'
            }`} />
            <span className="text-sm text-purple-300">
              {state.rpcStatus === 'connected' && 'RPC Connected'}
              {state.rpcStatus === 'connecting' && 'Connecting...'}
              {state.rpcStatus === 'failed' && 'Connection Failed'}
            </span>
          </div>
        </div>

        {/* Error Alert */}
        {state.error && (
          <div className="mb-8 p-4 rounded-lg bg-red-500 bg-opacity-10 border border-red-500 border-opacity-30 flex gap-3">
            <AlertCircle className="text-red-400 w-5 h-5 flex-shrink-0 mt-0.5" />
            <div>
              <h3 className="text-red-300 font-semibold">Error</h3>
              <p className="text-red-200 text-sm">{state.error}</p>
            </div>
          </div>
        )}

        {/* Loading State */}
        {state.loading && (
          <div className="flex items-center justify-center py-16">
            <Loader className="w-8 h-8 text-purple-400 animate-spin" />
            <span className="ml-3 text-purple-300">Fetching contract data...</span>
          </div>
        )}

        {/* Contract Cards */}
        {!state.loading && (
          <div className="grid grid-cols-1 md:grid-cols-2 gap-8">
            {/* MEEToken Card */}
            <ContractCard
              title="MEE Token"
              icon={<Zap className="w-6 h-6" />}
              contract={state.meeToken}
              iconColor="from-yellow-400 to-orange-500"
            />

            {/* MEEReward Card */}
            <ContractCard
              title="MeeChain Reward"
              icon={<Award className="w-6 h-6" />}
              contract={state.meeReward}
              iconColor="from-purple-400 to-pink-500"
            />
          </div>
        )}

        {/* Last Updated */}
        {state.lastUpdated && (
          <div className="mt-12 text-center text-purple-300 text-sm">
            Last updated: {state.lastUpdated.toLocaleTimeString()}
            <div className="mt-2 text-purple-400">
              Auto-refreshing every 30 seconds
            </div>
          </div>
        )}

        {/* Footer Info */}
        <div className="mt-16 grid grid-cols-3 gap-4 text-center">
          <div className="p-4 rounded-lg bg-purple-500 bg-opacity-10 border border-purple-400 border-opacity-20">
            <div className="text-3xl font-bold text-purple-300">13390</div>
            <div className="text-sm text-purple-400 mt-1">Chain ID</div>
          </div>
          <div className="p-4 rounded-lg bg-purple-500 bg-opacity-10 border border-purple-400 border-opacity-20">
            <div className="text-3xl font-bold text-purple-300">RPC</div>
            <div className="text-xs text-purple-400 mt-1">rpc.meechain.live</div>
          </div>
          <div className="p-4 rounded-lg bg-purple-500 bg-opacity-10 border border-purple-400 border-opacity-20">
            <div className="text-3xl font-bold text-purple-300">✨</div>
            <div className="text-sm text-purple-400 mt-1">Live Status</div>
          </div>
        </div>
      </div>
    </div>
  );
};

/**
 * Reusable Contract Card Component
 */
interface ContractCardProps {
  title: string;
  icon: React.ReactNode;
  contract: ContractInfo | null;
  iconColor: string;
}

const ContractCard: React.FC<ContractCardProps> = ({
  title,
  icon,
  contract,
  iconColor,
}) => {
  if (!contract) {
    return (
      <div className="rounded-lg bg-gradient-to-br from-slate-800 to-slate-900 border border-slate-700 p-8">
        <div className={`w-12 h-12 bg-gradient-to-br ${iconColor} rounded-lg flex items-center justify-center mb-4`}>
          <div className="text-white opacity-50">{icon}</div>
        </div>
        <h2 className="text-xl font-bold text-slate-400 mb-4">{title}</h2>
        <div className="text-slate-500">Not configured</div>
      </div>
    );
  }

  return (
    <div className="rounded-lg bg-gradient-to-br from-slate-800 to-slate-900 border border-slate-700 p-8 hover:border-purple-500 hover:border-opacity-50 transition-all">
      {/* Header */}
      <div className="flex items-start justify-between mb-6">
        <div>
          <div className={`w-12 h-12 bg-gradient-to-br ${iconColor} rounded-lg flex items-center justify-center mb-4`}>
            <div className="text-white">{icon}</div>
          </div>
          <h2 className="text-xl font-bold text-white">{title}</h2>
        </div>

        {/* Status Badge */}
        <div className="flex items-center gap-2">
          {contract.deployed ? (
            <>
              <CheckCircle className="w-5 h-5 text-green-400" />
              <span className="text-xs font-semibold text-green-400 px-3 py-1 rounded-full bg-green-400 bg-opacity-10 border border-green-400 border-opacity-30">
                Deployed
              </span>
            </>
          ) : (
            <>
              <AlertCircle className="w-5 h-5 text-yellow-400" />
              <span className="text-xs font-semibold text-yellow-400 px-3 py-1 rounded-full bg-yellow-400 bg-opacity-10 border border-yellow-400 border-opacity-30">
                Not Found
              </span>
            </>
          )}
        </div>
      </div>

      {/* Content */}
      <div className="space-y-4">
        {/* Address */}
        <div>
          <label className="text-xs font-semibold text-slate-400 uppercase tracking-wider">
            Address
          </label>
          <div className="mt-1 font-mono text-sm text-purple-300 break-all">
            {contract.address}
          </div>
        </div>

        {/* Symbol */}
        {contract.symbol && (
          <div>
            <label className="text-xs font-semibold text-slate-400 uppercase tracking-wider">
              Symbol
            </label>
            <div className="mt-1 text-sm text-slate-300">
              {contract.symbol}
            </div>
          </div>
        )}

        {/* Total Supply / Badges */}
        {contract.totalSupply && (
          <div>
            <label className="text-xs font-semibold text-slate-400 uppercase tracking-wider">
              {contract.type === 'token' ? 'Total Supply' : 'Badges Minted'}
            </label>
            <div className="mt-1 text-sm text-slate-300">
              {contract.type === 'token' 
                ? `${parseFloat(contract.totalSupply).toLocaleString()} ${contract.symbol}`
                : `${contract.totalSupply} NFTs`
              }
            </div>
          </div>
        )}

        {/* Chain Info */}
        <div className="grid grid-cols-2 gap-4 pt-4 border-t border-slate-700">
          <div>
            <label className="text-xs font-semibold text-slate-400 uppercase tracking-wider">
              Network
            </label>
            <div className="mt-1 text-sm text-slate-300">MeeChain</div>
          </div>
          <div>
            <label className="text-xs font-semibold text-slate-400 uppercase tracking-wider">
              Type
            </label>
            <div className="mt-1 text-sm text-slate-300 capitalize">
              {contract.type === 'token' ? 'ERC20' : 'ERC721'}
            </div>
          </div>
        </div>
      </div>

      {/* Actions */}
      <div className="mt-6 pt-6 border-t border-slate-700 flex gap-2">
        <a
          href={`https://rpc.meechain.live/search?q=${contract.address}`}
          target="_blank"
          rel="noopener noreferrer"
          className="flex-1 px-3 py-2 rounded-lg bg-purple-500 bg-opacity-20 text-purple-300 text-sm font-medium hover:bg-opacity-30 transition-all border border-purple-500 border-opacity-30"
        >
          View on Explorer
        </a>
        <button
          onClick={() => navigator.clipboard.writeText(contract.address)}
          className="flex-1 px-3 py-2 rounded-lg bg-slate-700 bg-opacity-50 text-slate-300 text-sm font-medium hover:bg-opacity-70 transition-all"
        >
          Copy Address
        </button>
      </div>
    </div>
  );
};

export default ContractDashboard;
