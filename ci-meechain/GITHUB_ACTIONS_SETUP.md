# 🏰 GitHub Actions CI/CD Setup Guide — MeeChain Auto-Deploy

**Status:** Complete CI/CD Ritual Ready 🎉

---

## 📋 Table of Contents

1. [Setup GitHub Secrets](#setup-github-secrets)
2. [Workflow File Installation](#workflow-file-installation)
3. [First Deployment](#first-deployment)
4. [Verification & Monitoring](#verification--monitoring)
5. [Troubleshooting](#troubleshooting)

---

## 🔐 Setup GitHub Secrets

### Step 1: Go to Repository Settings

1. **Navigate to:** `https://github.com/MEECHAIN1/meechain-foundry`
2. **Click:** Settings → Secrets and variables → Actions
3. **Click:** "New repository secret"

### Step 2: Add Required Secrets

#### Secret 1: `PRIVATE_KEY`

- **Name:** `PRIVATE_KEY`
- **Value:** Your deployment wallet's private key (without `0x` prefix)
  
```
# Example (DO NOT USE THIS):
ac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80
```

**⚠️ SECURITY WARNING:**
- Never commit this to version control
- Use a dedicated deployment wallet (not your main wallet)
- Rotate regularly
- Check balances before deployment

#### Secret 2: `MEECHAIN_RPC_URL` (Optional)

- **Name:** `MEECHAIN_RPC_URL`
- **Value:** `https://rpc.meechain.live`

**Note:** Already defaults to `https://rpc.meechain.live` in workflow

#### Secret 3: `SLACK_WEBHOOK_URL` (Optional)

- **Name:** `SLACK_WEBHOOK_URL`
- **Value:** Your Slack webhook URL (for notifications)

**To get Slack webhook:**
1. Go to: https://api.slack.com/apps
2. Create or select your app
3. Enable "Incoming Webhooks"
4. Create new webhook for your channel
5. Copy the URL

---

## 📁 Workflow File Installation

### Step 1: Create Workflow Directory

```bash
cd ~/meechain-metheus

# Create workflow directory
mkdir -p .github/workflows
```

### Step 2: Copy Workflow File

**Option A: Copy from this guide**

```bash
cp deploy.yml .github/workflows/deploy.yml
```

**Option B: Create manually**

```bash
cat > .github/workflows/deploy.yml << 'EOF'
[Copy entire content from deploy.yml file provided]
EOF
```

### Step 3: Verify File Structure

```bash
# Should show:
# .github/workflows/deploy.yml exists
find .github -type f -name "*.yml"

# Expected output:
# .github/workflows/deploy.yml
```

### Step 4: Push to GitHub

```bash
git add .github/workflows/deploy.yml
git commit -m "🏰 Add MeeChain CI/CD deployment workflow"
git push origin main
```

---

## 🚀 First Deployment

### Option 1: Automatic (Push to Main)

```bash
# Make any change to contracts
echo "# Updated" >> src/MEEToken.sol

# Commit and push
git add src/MEEToken.sol
git commit -m "update: MEEToken improvements"
git push origin main

# Workflow automatically triggers!
# Watch at: https://github.com/MEECHAIN1/meechain-foundry/actions
```

### Option 2: Manual Trigger (Workflow Dispatch)

1. **Go to:** GitHub repo → Actions
2. **Find:** "🏰 MeeChain Contract Ritual Deploy"
3. **Click:** "Run workflow"
4. **Select:** Environment (testnet/mainnet)
5. **Click:** "Run workflow"

### Option 3: Push to Any Branch

Workflow only runs on pushes to `main` branch by default. To change:

Edit `.github/workflows/deploy.yml`:

```yaml
on:
  push:
    branches:
      - main        # Add other branches here
      - develop
      - staging
```

---

## ✅ Verification & Monitoring

### Monitor Deployment Progress

1. **Go to:** `https://github.com/MEECHAIN1/meechain-foundry/actions`
2. **Click:** Latest workflow run
3. **Watch:** Step-by-step execution

### Expected Workflow Output

```
✅ Build & Test Contracts
  ✓ Checkout Repository
  ✓ Install Foundry
  ✓ Check Solidity Files
  ✓ Build Contracts
  ✓ Run Tests (if available)

✅ Deploy to MeeChain
  ✓ Deploy MEEToken → 0x...
  ✓ Deploy MEEReward → 0x...
  ✓ Verify Deployment
  ✓ Save Deployment Artifacts

✅ Notify Deployment Status
  ✓ Send Slack notification (if configured)
```

### Retrieve Contract Addresses

After successful deployment:

1. **Go to:** Actions → Latest run
2. **Click:** "deploy-meechain" job
3. **Look for:** Output lines:
   ```
   ✅ MEEToken deployed to: 0x...
   ✅ MEEReward deployed to: 0x...
   ```

### Download Deployment Artifact

1. **Go to:** Actions → Latest run
2. **Scroll down:** "Artifacts" section
3. **Download:** `deployment-meechain-XXXXX.zip`
4. **Extract:** Contains `meechain-XXXXX.json` with full deployment info

### Verify On-Chain

```bash
# Check MEEToken bytecode
cast code 0x<TOKEN_ADDRESS> --rpc-url https://rpc.meechain.live

# Check MEEReward bytecode
cast code 0x<REWARD_ADDRESS> --rpc-url https://rpc.meechain.live

# If returns anything other than 0x, deployment was successful ✓
```

### View Deployment History

```bash
# All GitHub Actions runs
gh run list --repo MEECHAIN1/meechain-foundry --limit 20

# Check specific workflow
gh run view <RUN_ID>
```

---

## 🐛 Troubleshooting

### Issue 1: "Error: No such file or directory"

**Problem:** Workflow can't find contract files

**Solution:**
```bash
# Ensure contracts exist
ls -la src/MEEToken.sol src/MEEReward.sol

# Check correct paths in workflow
grep "src/" .github/workflows/deploy.yml
```

### Issue 2: "Error: Private key is invalid"

**Problem:** PRIVATE_KEY secret not set or format wrong

**Solution:**
```bash
# Check secret is set
# Go to: Settings → Secrets → Actions → Verify PRIVATE_KEY exists

# Ensure key is WITHOUT 0x prefix
# ❌ WRONG: 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80
# ✅ RIGHT: ac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80
```

### Issue 3: "RPC connection timeout"

**Problem:** Can't connect to MeeChain RPC

**Solution:**
```bash
# Test RPC connection locally
curl -X POST https://rpc.meechain.live \
  -H "Content-Type: application/json" \
  -d '{"jsonrpc":"2.0","method":"eth_blockNumber","params":[],"id":1}'

# If fails, check MeeChain node status
# Update RPC URL in workflow if needed
```

### Issue 4: "Deployment succeeded but verification failed"

**Problem:** Contracts deployed but can't verify on-chain

**Solution:**
```bash
# Wait a few blocks for propagation (usually <1 min)
sleep 30

# Verify again
cast code 0x<ADDRESS> --rpc-url https://rpc.meechain.live
```

### Issue 5: "Insufficient balance for gas"

**Problem:** Deployment wallet doesn't have enough MeeChain tokens

**Solution:**
```bash
# Check balance
cast balance 0x<YOUR_ADDRESS> --rpc-url https://rpc.meechain.live

# Fund the wallet (faucet or transfer)
# Then retry deployment
```

---

## 🔧 Advanced Configuration

### Customize Deployment Parameters

Edit `.github/workflows/deploy.yml`:

```yaml
- name: 📤 Deploy MEEToken
  run: forge create \
    --rpc-url ${{ secrets.MEECHAIN_RPC_URL }} \
    --private-key ${{ secrets.PRIVATE_KEY }} \
    src/MEEToken.sol:MEEToken \
    --constructor-args "MEEToken" "MEE" "1000000000000000000000000" \
    # Add more args if needed
```

### Deploy to Multiple Networks

Create separate workflow files:

```bash
.github/workflows/
├── deploy-meechain.yml    (current)
├── deploy-polygon.yml     (new)
└── deploy-ethereum.yml    (new)
```

Example for Polygon:

```yaml
name: Deploy to Polygon

on:
  workflow_dispatch:
    inputs:
      network:
        description: 'Polygon network'
        required: true
        type: choice
        options:
          - mumbai
          - mainnet

jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
      # ... similar steps as MeeChain ...
      - run: forge create \
          --rpc-url https://rpc-${{ inputs.network }}.maticvigil.com \
          # ... rest of deployment
```

### Add Slack Notifications

The workflow already includes Slack support. To enable:

1. Get Slack webhook URL (see [Step 2](#step-2-add-required-secrets))
2. Add to GitHub secrets as `SLACK_WEBHOOK_URL`
3. Workflow will auto-notify on success/failure

### Run Tests Before Deploy

Workflow automatically runs tests if `/test` directory exists:

```bash
# Create test file
cat > test/MEEToken.t.sol << 'EOF'
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../src/MEEToken.sol";

contract MEETokenTest is Test {
    MEEToken token;

    function setUp() public {
        token = new MEEToken();
    }

    function testMint() public {
        token.mint(address(this), 100 ether);
        assertEq(token.balanceOf(address(this)), 100 ether);
    }
}
EOF

# Tests will run automatically before deployment
```

---

## 📊 Deployment Workflow Architecture

```
GitHub Push (main branch)
        ↓
    Build & Test
    ├─ Checkout code
    ├─ Install Foundry
    ├─ Build contracts
    └─ Run tests (if exist)
        ↓
    Deploy to MeeChain
    ├─ Deploy MEEToken
    ├─ Deploy MEEReward
    ├─ Verify on-chain
    └─ Save deployment artifacts
        ↓
    Notify Status
    ├─ Upload artifacts to GitHub
    └─ Send Slack notification (optional)
        ↓
    ✅ Deployment Complete
```

---

## 🎯 Best Practices

### 1. **Use Dedicated Deployment Wallet**
```bash
# Create separate wallet for CI/CD
# Never use production private key
cast wallet new  # Generate new wallet
```

### 2. **Monitor Gas Prices**
```bash
# Check gas before major deployments
cast gas-price --rpc-url https://rpc.meechain.live
```

### 3. **Version Your Deployments**
```bash
# Tag releases for production deployments
git tag -a v1.0.0 -m "MEEChain contracts v1.0.0"
git push origin v1.0.0
```

### 4. **Document Contract Addresses**
```bash
# After each deployment, save addresses
cat > DEPLOYMENTS.md << 'EOF'
# MeeChain Contract Deployments

## Mainnet
- MEEToken: 0x...
- MEEReward: 0x...

## Testnet
- MEEToken: 0x...
- MEEReward: 0x...
EOF
```

### 5. **Rotate Secrets Regularly**
```bash
# Update PRIVATE_KEY every 3 months
# Or after each major deployment
```

---

## 📞 Support & Resources

- **GitHub Actions Docs:** https://docs.github.com/en/actions
- **Foundry Docs:** https://book.getfoundry.sh/
- **MeeChain RPC:** https://rpc.meechain.live
- **Cast CLI:** https://book.getfoundry.sh/cast/

---

## ✨ You're All Set!

Your MeeChain CI/CD ritual is now active:

✅ Automated deployment on every push  
✅ Contract verification on-chain  
✅ Deployment artifacts saved  
✅ Optional Slack notifications  
✅ Full audit trail in GitHub Actions  

**Next:** Update your frontend with deployed contract addresses! 🚀

---

**Last Updated:** August 3, 2026  
**MeeChain Development Team**
