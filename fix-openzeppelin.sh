#!/bin/bash

# 🔧 MeeChain Foundry OpenZeppelin Import Fix
# Fixes "Source not found" errors for OpenZeppelin imports

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

echo -e "${BLUE}"
echo "╔════════════════════════════════════════════════════════╗"
echo "║  🔧 Foundry OpenZeppelin Import Fix                  ║"
echo "║     Resolve 'Source not found' errors                ║"
echo "╚════════════════════════════════════════════════════════╝"
echo -e "${NC}"

# Navigate to project
PROJECT_DIR="$HOME/meechain-foundry"

if [ ! -d "$PROJECT_DIR" ]; then
  log_error "Project not found at $PROJECT_DIR"
  echo "Create it first:"
  echo "  mkdir -p ~/meechain-foundry && cd ~/meechain-foundry"
  echo "  forge init --no-git ."
  exit 1
fi

cd "$PROJECT_DIR"
log_success "Found project at $PROJECT_DIR"

# ============================================================
# Fix 1: Check OpenZeppelin Installation
# ============================================================

log_info "Checking OpenZeppelin installation..."

if [ ! -d "lib/openzeppelin-contracts" ]; then
  log_warn "OpenZeppelin not installed yet, installing..."
  forge install OpenZeppelin/openzeppelin-contracts@v4.9.3
  log_success "OpenZeppelin installed"
else
  log_success "OpenZeppelin already installed"
  
  # Verify folder structure
  if [ ! -d "lib/openzeppelin-contracts/contracts" ]; then
    log_error "OpenZeppelin folder structure incorrect"
    log_info "Reinstalling..."
    rm -rf lib/openzeppelin-contracts
    forge install OpenZeppelin/openzeppelin-contracts@v4.9.3
  fi
fi

# ============================================================
# Fix 2: Create/Update remappings.txt
# ============================================================

log_info "Creating remappings.txt..."

cat > remappings.txt << 'EOF'
@openzeppelin/contracts/=lib/openzeppelin-contracts/contracts/
EOF

log_success "remappings.txt created"
cat remappings.txt

# ============================================================
# Fix 3: Update foundry.toml with remappings
# ============================================================

log_info "Updating foundry.toml..."

if [ ! -f "foundry.toml" ]; then
  cat > foundry.toml << 'EOF'
[profile.default]
src = "src"
out = "out"
libs = ["lib"]
test = "test"
remappings = ["@openzeppelin/contracts/=lib/openzeppelin-contracts/contracts/"]
optimizer = true
optimizer_runs = 200
EOF
  log_success "foundry.toml created"
else
  # Check if remappings already in file
  if grep -q "remappings" foundry.toml; then
    log_info "Remappings already in foundry.toml"
  else
    # Add remappings to foundry.toml
    sed -i '/\[profile.default\]/a remappings = ["@openzeppelin/contracts/=lib/openzeppelin-contracts/contracts/"]' foundry.toml
    log_success "Remappings added to foundry.toml"
  fi
fi

cat foundry.toml

# ============================================================
# Fix 4: Verify Contract Path
# ============================================================

log_info "Verifying contract directory..."

if [ ! -d "src" ]; then
  mkdir -p src
  log_success "Created src directory"
fi

if [ ! -f "src/MyToken.sol" ]; then
  log_warn "MyToken.sol not found, creating..."
  
  cat > src/MyToken.sol << 'EOFTOKEN'
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
EOFTOKEN
  
  log_success "MyToken.sol created"
else
  log_success "MyToken.sol found"
fi

# ============================================================
# Fix 5: Clean Build Cache
# ============================================================

log_info "Cleaning build cache..."

if [ -d "out" ]; then
  rm -rf out
  log_success "Cleaned out directory"
fi

if [ -d "cache" ]; then
  rm -rf cache
  log_success "Cleaned cache directory"
fi

# ============================================================
# Fix 6: Recompile
# ============================================================

log_info "Recompiling contracts..."

if forge build; then
  log_success "✅ COMPILATION SUCCESSFUL!"
  
  # List generated artifacts
  if [ -d "out" ]; then
    echo ""
    log_info "Generated artifacts:"
    find out -name "*.json" -type f | head -10
  fi
else
  log_error "Compilation failed"
  exit 1
fi

# ============================================================
# Summary
# ============================================================

echo ""
echo -e "${GREEN}════════════════════════════════════════════════════════${NC}"
echo -e "${GREEN}✅ FOUNDRY FIXES APPLIED!${NC}"
echo -e "${GREEN}════════════════════════════════════════════════════════${NC}"
echo ""
echo "📁 Project: $PROJECT_DIR"
echo "📝 remappings.txt: Created"
echo "⚙️  foundry.toml: Updated"
echo "✅ Contracts: Compiled successfully"
echo ""
echo -e "${YELLOW}Next Step: Deploy Contract${NC}"
echo ""
echo "forge create \\"
echo "  --rpc-url http://127.0.0.1:8545 \\"
echo "  --private-key 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80 \\"
echo "  src/MyToken.sol:MyToken \\"
echo "  --constructor-args \"MyToken\" \"MTK\" \"1000000000000000000000000\" \\"
echo "  --broadcast"
echo ""
echo -e "${GREEN}════════════════════════════════════════════════════════${NC}"
