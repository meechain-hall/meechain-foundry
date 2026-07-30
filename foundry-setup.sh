#!/bin/bash

# 🔨 MeeChain Foundry Project Setup
# Initialize and deploy contracts using Foundry (forge)

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log_info() { echo -e "${BLUE}ℹ️  ${1}${NC}"; }
log_success() { echo -e "${GREEN}✅ ${1}${NC}"; }
log_warn() { echo -e "${YELLOW}⚠️  ${1}${NC}"; }
log_error() { echo -e "${RED}❌ ${1}${NC}"; }
log_header() { echo -e "\n${BLUE}════════════════════════════════════════════════════════════${NC}\n${BLUE}${1}${NC}\n${BLUE}════════════════════════════════════════════════════════════${NC}\n"; }

# ============================================================
# Configuration
# ============================================================

PROJECT_DIR="$HOME/meechain-foundry"
RPC_URL="http://127.0.0.1:8545"
CHAIN_ID="13390"

# Anvil default private key (Account 0)
PRIVATE_KEY="0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80"

echo -e "${BLUE}"
echo "╔════════════════════════════════════════════════════════╗"
echo "║   🔨 MeeChain Foundry Project Setup                   ║"
echo "║      Initialize & Deploy Contracts                    ║"
echo "╚════════════════════════════════════════════════════════╝"
echo -e "${NC}"

# ============================================================
# Step 1: Create Foundry Project
# ============================================================

setup_project() {
  log_header "Step 1: Create Foundry Project"
  
  if [ -d "$PROJECT_DIR" ]; then
    log_warn "Project directory already exists: $PROJECT_DIR"
    read -p "Delete and recreate? (y/n): " recreate
    if [ "$recreate" = "y" ]; then
      rm -rf "$PROJECT_DIR"
    else
      log_info "Using existing directory"
      return
    fi
  fi
  
  # Initialize Foundry project
  mkdir -p "$PROJECT_DIR"
  cd "$PROJECT_DIR"
  
  log_info "Initializing Foundry project..."
  forge init --no-git . 2>/dev/null || true
  
  log_success "Foundry project created at $PROJECT_DIR"
}

# ============================================================
# Step 2: Create Contract Files
# ============================================================

create_contracts() {
  log_header "Step 2: Create Contract Files"
  
  cd "$PROJECT_DIR"
  
  # Create src directory if needed
  mkdir -p src
  
  # Create MyToken.sol
  log_info "Creating MyToken.sol (ERC20)..."
  cat > src/MyToken.sol << 'EOFTOKEN'
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @title MyToken
 * @dev MeeChain ERC20 Token
 */
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
EOFTOKEN
  
  log_success "MyToken.sol created"
  
  # Create MEEToken.sol (ERC20 for ecosystem)
  log_info "Creating MEEToken.sol (Ecosystem Token)..."
  cat > src/MEEToken.sol << 'EOFMEE'
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Pausable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @title MEEToken
 * @dev MeeChain ecosystem token
 */
contract MEEToken is ERC20, ERC20Pausable, Ownable {
    
    constructor(uint256 initialSupply) ERC20("MeeChain Token", "MEE") {
        _mint(msg.sender, initialSupply);
    }

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    function _update(address from, address to, uint256 value)
        internal
        override(ERC20, ERC20Pausable)
    {
        super._update(from, to, value);
    }
}
EOFMEE
  
  log_success "MEEToken.sol created"
}

# ============================================================
# Step 3: Setup foundry.toml
# ============================================================

setup_foundry_config() {
  log_header "Step 3: Setup foundry.toml"
  
  cd "$PROJECT_DIR"
  
  log_info "Creating foundry.toml..."
  cat > foundry.toml << 'EOFCONFIG'
[profile.default]
src = "src"
out = "out"
libs = ["lib"]
test = "test"
remappings = []

# Optimization
optimizer = true
optimizer_runs = 200

# RPC settings
[rpc]
localhost = "http://127.0.0.1:8545"
meechain = "http://127.0.0.1:8545"

# Network profiles
[profile.anvil]
optimizer_runs = 200

[profile.production]
optimizer_runs = 1000
EOFCONFIG
  
  log_success "foundry.toml created"
}

# ============================================================
# Step 4: Install Dependencies
# ============================================================

install_deps() {
  log_header "Step 4: Install OpenZeppelin Contracts"
  
  cd "$PROJECT_DIR"
  
  if [ -d "lib/openzeppelin-contracts" ]; then
    log_warn "OpenZeppelin contracts already installed"
    return
  fi
  
  log_info "Installing OpenZeppelin contracts library..."
  forge install OpenZeppelin/openzeppelin-contracts@v4.9.3
  
  log_success "Dependencies installed"
}

# ============================================================
# Step 5: Compile Contracts
# ============================================================

compile_contracts() {
  log_header "Step 5: Compile Contracts"
  
  cd "$PROJECT_DIR"
  
  log_info "Compiling contracts..."
  forge build
  
  if [ -d "out" ]; then
    log_success "Contracts compiled successfully"
    log_info "Artifacts in: out/"
  else
    log_error "Compilation failed"
    exit 1
  fi
}

# ============================================================
# Step 6: Deploy Contracts
# ============================================================

deploy_mytoken() {
  log_header "Step 6: Deploy MyToken Contract"
  
  cd "$PROJECT_DIR"
  
  log_warn "Deploying MyToken to $RPC_URL"
  log_info "Parameters:"
  echo "  - Name: MyToken"
  echo "  - Symbol: MTK"
  echo "  - Initial Supply: 1,000,000 (10^18 wei)"
  
  INITIAL_SUPPLY="1000000000000000000000000"  # 1M tokens with 18 decimals
  
  DEPLOY_OUTPUT=$(forge create \
    --rpc-url "$RPC_URL" \
    --private-key "$PRIVATE_KEY" \
    src/MyToken.sol:MyToken \
    --constructor-args "MyToken" "MTK" "$INITIAL_SUPPLY" \
    2>&1) || true
  
  if echo "$DEPLOY_OUTPUT" | grep -q "Deployed to"; then
    CONTRACT_ADDR=$(echo "$DEPLOY_OUTPUT" | grep "Deployed to" | awk '{print $3}')
    log_success "MyToken deployed to: $CONTRACT_ADDR"
    
    # Save address
    mkdir -p deployments
    echo "$CONTRACT_ADDR" > deployments/MyToken.txt
    
    return 0
  else
    log_error "Deployment failed"
    echo "$DEPLOY_OUTPUT"
    return 1
  fi
}

deploy_meetoken() {
  log_header "Step 7: Deploy MEEToken Contract"
  
  cd "$PROJECT_DIR"
  
  log_warn "Deploying MEEToken to $RPC_URL"
  log_info "Parameters:"
  echo "  - Name: MeeChain Token"
  echo "  - Symbol: MEE"
  echo "  - Initial Supply: 10,000,000 (10^18 wei)"
  
  INITIAL_SUPPLY="10000000000000000000000000"  # 10M tokens with 18 decimals
  
  DEPLOY_OUTPUT=$(forge create \
    --rpc-url "$RPC_URL" \
    --private-key "$PRIVATE_KEY" \
    src/MEEToken.sol:MEEToken \
    --constructor-args "$INITIAL_SUPPLY" \
    2>&1) || true
  
  if echo "$DEPLOY_OUTPUT" | grep -q "Deployed to"; then
    CONTRACT_ADDR=$(echo "$DEPLOY_OUTPUT" | grep "Deployed to" | awk '{print $3}')
    log_success "MEEToken deployed to: $CONTRACT_ADDR"
    
    # Save address
    mkdir -p deployments
    echo "$CONTRACT_ADDR" > deployments/MEEToken.txt
    
    return 0
  else
    log_error "Deployment failed"
    echo "$DEPLOY_OUTPUT"
    return 1
  fi
}

# ============================================================
# Step 8: Verify Deployment
# ============================================================

verify_deployment() {
  log_header "Step 8: Verify Deployment"
  
  cd "$PROJECT_DIR"
  
  if [ ! -f "deployments/MyToken.txt" ]; then
    log_warn "MyToken not deployed yet"
    return
  fi
  
  MYTOKEN_ADDR=$(cat deployments/MyToken.txt)
  
  log_info "MyToken address: $MYTOKEN_ADDR"
  
  # Check balance
  log_info "Checking token balance..."
  BALANCE=$(cast call "$MYTOKEN_ADDR" "balanceOf(address)" "0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266" \
    --rpc-url "$RPC_URL" 2>/dev/null || echo "0x0")
  
  if [ "$BALANCE" != "0x0" ]; then
    log_success "Token balance verified: $BALANCE"
  else
    log_warn "Could not verify balance"
  fi
  
  # Check name
  NAME=$(cast call "$MYTOKEN_ADDR" "name()" --rpc-url "$RPC_URL" 2>/dev/null || echo "Unknown")
  log_info "Token name: $NAME"
  
  # Check symbol
  SYMBOL=$(cast call "$MYTOKEN_ADDR" "symbol()" --rpc-url "$RPC_URL" 2>/dev/null || echo "Unknown")
  log_info "Token symbol: $SYMBOL"
}

# ============================================================
# Show Summary
# ============================================================

show_summary() {
  log_header "📋 Setup Complete!"
  
  echo -e "${GREEN}"
  echo "════════════════════════════════════════════════════════"
  echo "Foundry Project Setup Summary"
  echo "════════════════════════════════════════════════════════"
  echo ""
  echo "✅ Project created at: $PROJECT_DIR"
  echo "✅ Contracts compiled"
  echo "✅ OpenZeppelin contracts installed"
  echo "✅ Contracts deployed to Anvil (Chain 13390)"
  echo ""
  echo "════════════════════════════════════════════════════════"
  echo ""
  echo "📁 Project Structure:"
  echo "   $PROJECT_DIR/"
  echo "   ├── src/"
  echo "   │   ├── MyToken.sol"
  echo "   │   └── MEEToken.sol"
  echo "   ├── test/"
  echo "   ├── out/"
  echo "   ├── lib/"
  echo "   ├── deployments/"
  echo "   └── foundry.toml"
  echo ""
  
  if [ -f "$PROJECT_DIR/deployments/MyToken.txt" ]; then
    echo "🎯 Deployed Contracts:"
    MYTOKEN=$(cat "$PROJECT_DIR/deployments/MyToken.txt")
    echo "   MyToken: $MYTOKEN"
  fi
  
  if [ -f "$PROJECT_DIR/deployments/MEEToken.txt" ]; then
    MEETOKEN=$(cat "$PROJECT_DIR/deployments/MEEToken.txt")
    echo "   MEEToken: $MEETOKEN"
  fi
  
  echo ""
  echo "📡 RPC Configuration:"
  echo "   URL: $RPC_URL"
  echo "   Chain ID: $CHAIN_ID"
  echo "   Deployer: 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266"
  echo ""
  echo "🔧 Useful Commands:"
  echo "   cd $PROJECT_DIR"
  echo "   forge build              # Compile contracts"
  echo "   forge test              # Run tests"
  echo "   forge create ... --broadcast  # Deploy contract"
  echo ""
  echo "════════════════════════════════════════════════════════"
  echo -e "${NC}"
}

# ============================================================
# MAIN
# ============================================================

main() {
  setup_project
  create_contracts
  setup_foundry_config
  install_deps
  compile_contracts
  deploy_mytoken
  deploy_meetoken
  verify_deployment
  show_summary
}

main
