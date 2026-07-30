#!/bin/bash

# 🚀 ONE-COMMAND FOUNDRY SETUP & CONTRACT DEPLOYMENT
# Copy-paste this entire script into your VM terminal

set -e

echo "🚀 MeeChain Foundry Setup & Contract Deployment"
echo "==============================================="

# Configuration
PROJECT_DIR="$HOME/meechain-foundry"
RPC_URL="http://127.0.0.1:8545"
PRIVATE_KEY="0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80"

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}Step 1: Creating Foundry project...${NC}"
mkdir -p "$PROJECT_DIR"
cd "$PROJECT_DIR"

# Initialize foundry
forge init --no-git . 2>/dev/null || echo "Project already exists"

echo -e "${BLUE}Step 2: Creating MyToken.sol contract...${NC}"
mkdir -p src

cat > src/MyToken.sol << 'EOF'
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract MyToken is ERC20, ERC20Burnable, Ownable {
    uint8 private _decimals;

    constructor(
        string memory name,
        string memory symbol,
        uint256 initialSupply
    ) ERC20(name, symbol) {
        _decimals = 18;
        _mint(msg.sender, initialSupply);
    }

    function decimals() public view override returns (uint8) {
        return _decimals;
    }

    function mint(address to, uint256 amount) public onlyOwner {
        _mint(to, amount);
    }

    function burnFrom(address account, uint256 amount) public override onlyOwner {
        _burn(account, amount);
    }
}
EOF

echo -e "${GREEN}✅ MyToken.sol created${NC}"

echo -e "${BLUE}Step 3: Installing OpenZeppelin contracts...${NC}"
forge install OpenZeppelin/openzeppelin-contracts@v4.9.3 2>/dev/null || echo "Already installed"

echo -e "${BLUE}Step 4: Compiling contracts...${NC}"
forge build

echo -e "${GREEN}✅ Contracts compiled${NC}"

echo -e "${BLUE}Step 5: Deploying MyToken...${NC}"

# Deploy MyToken
DEPLOY_OUTPUT=$(forge create \
  --rpc-url "$RPC_URL" \
  --private-key "$PRIVATE_KEY" \
  src/MyToken.sol:MyToken \
  --constructor-args "MyToken" "MTK" "1000000000000000000000000" \
  --broadcast 2>&1)

echo "$DEPLOY_OUTPUT"

# Extract contract address
CONTRACT_ADDR=$(echo "$DEPLOY_OUTPUT" | grep "Deployed to:" | awk '{print $3}' | tr -d '\n')

if [ -z "$CONTRACT_ADDR" ]; then
  echo -e "${YELLOW}⚠️  Could not extract contract address${NC}"
else
  echo -e "${GREEN}✅ MyToken deployed to: $CONTRACT_ADDR${NC}"
  
  # Save address
  mkdir -p deployments
  echo "$CONTRACT_ADDR" > deployments/MyToken.txt
  
  echo -e "${BLUE}Step 6: Verifying deployment...${NC}"
  
  # Verify name
  NAME=$(cast call "$CONTRACT_ADDR" "name()" --rpc-url "$RPC_URL" 2>/dev/null || echo "Unknown")
  echo -e "${GREEN}✅ Token Name: $NAME${NC}"
  
  # Verify symbol
  SYMBOL=$(cast call "$CONTRACT_ADDR" "symbol()" --rpc-url "$RPC_URL" 2>/dev/null || echo "Unknown")
  echo -e "${GREEN}✅ Token Symbol: $SYMBOL${NC}"
  
  # Verify supply
  SUPPLY=$(cast call "$CONTRACT_ADDR" "totalSupply()" --rpc-url "$RPC_URL" 2>/dev/null || echo "0x0")
  echo -e "${GREEN}✅ Total Supply: $SUPPLY${NC}"
fi

echo ""
echo -e "${GREEN}════════════════════════════════════════════════════════${NC}"
echo -e "${GREEN}✅ SETUP COMPLETE!${NC}"
echo -e "${GREEN}════════════════════════════════════════════════════════${NC}"
echo ""
echo "📁 Project location: $PROJECT_DIR"
echo "📝 Contract file: $PROJECT_DIR/src/MyToken.sol"
echo "🔧 Configuration: $PROJECT_DIR/foundry.toml"
echo "📦 Artifacts: $PROJECT_DIR/out/"
echo ""
echo "🎯 Contract Address: $CONTRACT_ADDR"
echo "📡 RPC URL: $RPC_URL"
echo "⛓️  Chain ID: 13390"
echo ""
echo "🚀 Next Deploy Another Token:"
echo "forge create --rpc-url $RPC_URL --private-key $PRIVATE_KEY src/MyToken.sol:MyToken --constructor-args \"TokenName\" \"SYMBOL\" \"1000000000000000000000000\" --broadcast"
echo ""
