# 🏰 MeeChain CI/CD Ritual Checklist
## Complete End-to-End Deployment Guide

**Status:** Ready for Deployment ✨  
**Chain:** MeeChain (Chain ID: 13390)  
**RPC:** https://rpc.meechain.live  
**Last Updated:** August 3, 2026

---

## 📋 Table of Contents

1. [Pre-Deployment Setup](#pre-deployment-setup)
2. [GitHub Actions Configuration](#github-actions-configuration)
3. [First Deployment](#first-deployment)
4. [Post-Deployment Verification](#post-deployment-verification)
5. [Dashboard Integration](#dashboard-integration)
6. [Monitoring & Maintenance](#monitoring--maintenance)

---

## 🔧 Pre-Deployment Setup

### ✅ Step 1: Verify Local Environment

```bash
# Check Foundry installation
forge --version
# Expected: forge 0.2.0 or higher

# Check cast installation
cast --version
# Expected: cast 0.2.0 or higher

# Verify contracts compile
cd ~/meechain-metheus
forge clean
forge build

# Expected output:
# ✓ Compiled successfully
# 2 solidity files compiled
```

### ✅ Step 2: Test RPC Connection

```bash
# Test MeeChain RPC
cast bn --rpc-url https://rpc.meechain.live
# Expected: Current block number

cast gas-price --rpc-url https://rpc.meechain.live
# Expected: Current gas price in wei
```

### ✅ Step 3: Prepare Deployment Wallet

```bash
# Check wallet balance
WALLET_ADDRESS="0x<your_address>"
cast balance $WALLET_ADDRESS --rpc-url https://rpc.meechain.live

# Expected: > 0 (needs MEE tokens for gas)
# If 0, fund wallet via faucet or transfer
```

---

## 🔐 GitHub Actions Configuration

### ✅ Step 1: Create GitHub Secrets

Go to: **GitHub Repository → Settings → Secrets and variables → Actions**

**Secret 1: PRIVATE_KEY**
- Name: `PRIVATE_KEY`
- Value: Your deployment key (WITHOUT `0x` prefix)
- Format: `ac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80`

**Secret 2: MEECHAIN_RPC_URL** (Optional)
- Name: `MEECHAIN_RPC_URL`
- Value: `https://rpc.meechain.live`
- Default: Already in workflow, only needed if overriding

**Secret 3: SLACK_WEBHOOK_URL** (Optional)
- Name: `SLACK_WEBHOOK_URL`
- Value: Your Slack webhook URL
- Used for: Notifications after deployment

### ✅ Step 2: Setup Workflow File

```bash
# Copy workflow to your repository
cd ~/meechain-metheus

mkdir -p .github/workflows
cp deploy.yml .github/workflows/deploy.yml

# Verify structure
ls -la .github/workflows/deploy.yml
# Expected: File exists

# Commit to GitHub
git add .github/workflows/deploy.yml
git commit -m "🏰 Add MeeChain CI/CD deployment workflow"
git push origin main
```

### ✅ Step 3: Verify Workflow Setup

1. Go to: **GitHub → Actions**
2. Look for: **"🏰 MeeChain Contract Ritual Deploy"**
3. Status should show: "This workflow has a workflow_dispatch event"

---

## 🚀 First Deployment

### Option A: Automatic Deployment (Recommended)

```bash
# 1. Make a change to contracts
cd ~/meechain-metheus
echo "// Updated" >> src/MEEToken.sol

# 2. Commit and push
git add src/MEEToken.sol
git commit -m "chore: update MEEToken"
git push origin main

# 3. Workflow automatically triggers
# Go to: GitHub Actions tab and watch it run
```

### Option B: Manual Workflow Trigger

1. **Go to:** GitHub Actions tab
2. **Click:** "🏰 MeeChain Contract Ritual Deploy"
3. **Click:** "Run workflow" button
4. **Select:** Environment (testnet/mainnet)
5. **Click:** "Run workflow"

### ✅ Step 1: Monitor Deployment

**Watch the workflow execution:**

```
GitHub → Actions → Latest workflow run
```

**Expected steps:**
```
1. ✓ Build & Test Contracts
   ├─ Checkout Repository
   ├─ Install Foundry
   ├─ Check Solidity Files
   ├─ Build Contracts
   └─ Run Tests

2. ✓ Deploy to MeeChain
   ├─ Deploy MEEToken
   ├─ Deploy MEEReward
   ├─ Verify Deployment
   └─ Save Artifacts

3. ✓ Notify Status
   └─ Send notifications
```

### ✅ Step 2: Extract Contract Addresses

From GitHub Actions output, save these addresses:

```
MEEToken Deployed:  0x25d6E5E73Bc76a34CbD9Fb3f12D0e2B7e5c8e5C5
MEEReward Deployed: 0xa9e3F9c2C5d8a4E1b7F3C6D9E2A5B8C1D4E7F0A3
```

### ✅ Step 3: Download Deployment Artifact

1. **Go to:** GitHub Actions → Latest run
2. **Scroll down:** Find "Artifacts" section
3. **Download:** `deployment-meechain-XXXXX`
4. **Extract:** Contains full deployment JSON with all details

---

## ✅ Post-Deployment Verification

### Step 1: Verify Contracts On-Chain

```bash
# Set variables
TOKEN_ADDRESS="0x25d6E5E73Bc76a34CbD9Fb3f12D0e2B7e5c8e5C5"
REWARD_ADDRESS="0xa9e3F9c2C5d8a4E1b7F3C6D9E2A5B8C1D4E7F0A3"
RPC_URL="https://rpc.meechain.live"

# Run verification script
chmod +x verify-contracts.sh
./verify-contracts.sh $TOKEN_ADDRESS $REWARD_ADDRESS

# Or verify manually with cast
cast code $TOKEN_ADDRESS --rpc-url $RPC_URL
# Expected: Should NOT be "0x"

cast code $REWARD_ADDRESS --rpc-url $RPC_URL
# Expected: Should NOT be "0x"
```

### Step 2: Test Contract Interactions

```bash
# Check MEEToken details
cast call $TOKEN_ADDRESS "function name() returns (string)" \
  --rpc-url $RPC_URL
# Expected: MEEToken

cast call $TOKEN_ADDRESS "function symbol() returns (string)" \
  --rpc-url $RPC_URL
# Expected: MEE

cast call $TOKEN_ADDRESS "function totalSupply() returns (uint256)" \
  --rpc-url $RPC_URL
# Expected: 1000000000000000000000000 (1B tokens in wei)

# Check MEEReward details
cast call $REWARD_ADDRESS "function name() returns (string)" \
  --rpc-url $RPC_URL
# Expected: MeeChain Reward

cast call $REWARD_ADDRESS "function symbol() returns (string)" \
  --rpc-url $RPC_URL
# Expected: MEEBD
```

### Step 3: Save Deployment Info

```bash
# Create deployment record
cat > DEPLOYMENTS.md << EOF
# MeeChain Deployments

## Mainnet (Chain ID 13390)

**Deployment Date:** $(date)

### Contracts

| Contract | Address | Type |
|----------|---------|------|
| MEEToken | $TOKEN_ADDRESS | ERC20 |
| MEEReward | $REWARD_ADDRESS | ERC721 Soulbound |

### Verification

✅ Bytecode verified on-chain
✅ Contract interactions tested
✅ Ready for production

### Next Steps

- [ ] Update frontend .env with addresses
- [ ] Deploy React dashboard
- [ ] Test full integration
- [ ] Monitor transaction logs
EOF

git add DEPLOYMENTS.md
git commit -m "docs: add mainnet deployment records"
git push origin main
```

---

## 🎨 Dashboard Integration

### Step 1: Setup React Environment

```bash
# Navigate to frontend project
cd ~/meechain-app  # or your React app

# Create .env.local file
cat > .env.local << EOF
REACT_APP_MEECHAIN_RPC_URL=https://rpc.meechain.live
REACT_APP_MEECHAIN_CHAIN_ID=13390
REACT_APP_MEE_TOKEN_ADDRESS=$TOKEN_ADDRESS
REACT_APP_MEE_REWARD_ADDRESS=$REWARD_ADDRESS
REACT_APP_IPFS_GATEWAY=https://ipfs.io/ipfs/
EOF

# Update .gitignore
echo ".env.local" >> .gitignore
git add .gitignore
git commit -m "chore: ignore env files"
```

### Step 2: Install Dashboard Component

```bash
# Copy dashboard component
cp ContractDashboard.tsx src/components/

# Update your React router/layout
# Add to pages or routes:
# <Route path="/dashboard" element={<ContractDashboard />} />

# Install dependencies (if not already installed)
npm install ethers lucide-react

# Test locally
npm start
# Go to: http://localhost:3000/dashboard
```

### Step 3: Deploy to Vercel

```bash
# Push to GitHub (if not already done)
git add .
git commit -m "feat: add contract dashboard"
git push origin main

# Vercel auto-detects and deploys
# Or connect via: https://vercel.com/new
```

---

## 📊 Monitoring & Maintenance

### Step 1: Setup Monitoring

```bash
# Monitor wallet balance
watch -n 5 'cast balance 0x<WALLET> --rpc-url https://rpc.meechain.live'

# Monitor contract events (example)
cast logs "Transfer" \
  --rpc-url https://rpc.meechain.live \
  --address $TOKEN_ADDRESS

# Monitor gas prices
watch -n 10 'cast gas-price --rpc-url https://rpc.meechain.live'
```

### Step 2: Regular Maintenance

**Weekly:**
- [ ] Check wallet balance
- [ ] Monitor contract interactions
- [ ] Review GitHub Actions logs
- [ ] Test dashboard functionality

**Monthly:**
- [ ] Update contracts if needed
- [ ] Review deployment history
- [ ] Check for security updates
- [ ] Backup deployment records

**Quarterly:**
- [ ] Rotate deployment keys
- [ ] Audit contract usage
- [ ] Update documentation
- [ ] Plan next features

### Step 3: Troubleshooting

**Issue: Deployment fails with "Insufficient balance"**
```bash
# Check balance
cast balance 0x<WALLET> --rpc-url https://rpc.meechain.live

# Fund wallet (via faucet or transfer)
# Then retry deployment
```

**Issue: RPC connection timeout**
```bash
# Test RPC connectivity
curl -X POST https://rpc.meechain.live \
  -H "Content-Type: application/json" \
  -d '{"jsonrpc":"2.0","method":"eth_blockNumber","params":[],"id":1}'

# If fails, check MeeChain node status or update RPC URL
```

**Issue: Contract interaction fails**
```bash
# Verify contract is deployed
cast code $TOKEN_ADDRESS --rpc-url https://rpc.meechain.live

# Check contract ABI matches
# Verify function signatures
```

---

## 🎯 Deployment Checklist

### Pre-Deployment
- [ ] Contracts compile successfully locally
- [ ] All tests pass
- [ ] RPC connection works
- [ ] Deployment wallet has balance
- [ ] GitHub Secrets configured

### Deployment
- [ ] Workflow runs without errors
- [ ] MEEToken deployed successfully
- [ ] MEEReward deployed successfully
- [ ] Contracts verified on-chain
- [ ] Deployment artifacts saved

### Post-Deployment
- [ ] Contract addresses saved
- [ ] On-chain verification passed
- [ ] Contract interactions tested
- [ ] Frontend .env updated
- [ ] Dashboard deployed
- [ ] Documentation updated

### Production
- [ ] Monitoring setup complete
- [ ] Alerts configured
- [ ] Backup procedures in place
- [ ] Team notified
- [ ] Ready for public use

---

## 🏰 Ritual Timeline

```
🔧 Preparation (5 min)
    ↓
🔐 Setup Secrets (2 min)
    ↓
📁 Install Workflow (1 min)
    ↓
🚀 Deploy (10 min)
    ↓
✅ Verify (5 min)
    ↓
🎨 Integrate Dashboard (10 min)
    ↓
📊 Monitor (Ongoing)

Total Time: ~33 minutes from start to production
```

---

## 📞 Support Resources

- **Foundry Docs:** https://book.getfoundry.sh/
- **Cast CLI:** https://book.getfoundry.sh/cast/
- **MeeChain RPC:** https://rpc.meechain.live
- **GitHub Actions:** https://docs.github.com/en/actions
- **React Docs:** https://react.dev/

---

## ✨ Success Criteria

When deployment is complete, you should have:

✅ MEEToken (ERC20) deployed to MeeChain  
✅ MEEReward (Soulbound NFT) deployed to MeeChain  
✅ Contracts verified on-chain  
✅ GitHub Actions CI/CD automated  
✅ React dashboard displaying contract data  
✅ Frontend integrated with contract addresses  
✅ Monitoring and alerts configured  
✅ Full documentation and records saved  

---

## 🎉 Congratulations!

Your MeeChain contracts are now:

- **Live** on the blockchain (Chain ID 13390)
- **Automated** via GitHub Actions CI/CD
- **Monitored** with dashboards and alerts
- **Integrated** with your frontend
- **Production-ready** for users

**🚀 MeeChain awaits!**

---

**Ritual completed by:** MeeChain Development Team  
**Date:** August 3, 2026  
**Next Ritual:** Contract Upgrades & Governance
