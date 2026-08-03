#!/bin/bash

###############################################################################
# 🏰 MeeChain Contract Verification Script
# Verifies that contracts are properly deployed on MeeChain RPC
# 
# Usage:
#   ./verify-contracts.sh 0xTOKEN_ADDRESS 0xREWARD_ADDRESS
#   ./verify-contracts.sh  # Interactive mode
###############################################################################

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
NC='\033[0m' # No Color

# Configuration
RPC_URL="${MEECHAIN_RPC_URL:-https://rpc.meechain.live}"
CHAIN_ID=13390

# Functions
print_header() {
  echo -e "${BLUE}╔════════════════════════════════════════════╗${NC}"
  echo -e "${BLUE}║   🏰 MeeChain Contract Verification       ║${NC}"
  echo -e "${BLUE}╚════════════════════════════════════════════╝${NC}"
  echo ""
}

print_section() {
  echo -e "${PURPLE}▶ $1${NC}"
}

print_success() {
  echo -e "${GREEN}✅ $1${NC}"
}

print_error() {
  echo -e "${RED}❌ $1${NC}"
}

print_warning() {
  echo -e "${YELLOW}⚠️  $1${NC}"
}

print_info() {
  echo -e "${BLUE}ℹ️  $1${NC}"
}

# Check if cast is installed
check_cast() {
  print_section "Checking prerequisites..."
  
  if ! command -v cast &> /dev/null; then
    print_error "cast CLI not found"
    echo "Install Foundry: curl -L https://foundry.paradigm.xyz | bash"
    exit 1
  fi
  print_success "cast CLI found"
}

# Test RPC connection
test_rpc() {
  print_section "Testing RPC connection..."
  
  if cast bn --rpc-url "$RPC_URL" &> /dev/null; then
    BLOCK_NUMBER=$(cast bn --rpc-url "$RPC_URL")
    print_success "Connected to MeeChain"
    print_info "Current block: $BLOCK_NUMBER"
    echo ""
    return 0
  else
    print_error "Cannot connect to RPC: $RPC_URL"
    return 1
  fi
}

# Verify contract at address
verify_contract() {
  local address=$1
  local name=$2
  
  print_section "Verifying $name at $address..."
  
  # Validate address format
  if ! [[ $address =~ ^0x[0-9a-fA-F]{40}$ ]]; then
    print_error "Invalid address format: $address"
    return 1
  fi
  
  # Get bytecode
  BYTECODE=$(cast code "$address" --rpc-url "$RPC_URL" 2>/dev/null || echo "0x")
  
  if [ "$BYTECODE" = "0x" ]; then
    print_error "No bytecode found at $address"
    echo "  → Contract not deployed or address is incorrect"
    return 1
  fi
  
  # Get code size
  CODE_SIZE=$((${#BYTECODE} / 2 - 1))  # subtract 1 for "0x"
  
  print_success "$name contract found"
  echo "  Address:  $address"
  echo "  Code size: $CODE_SIZE bytes"
  echo ""
  return 0
}

# Verify MEEToken
verify_meetoken() {
  local token_address=$1
  
  print_section "Verifying MEEToken (ERC20)..."
  
  if ! verify_contract "$token_address" "MEEToken"; then
    return 1
  fi
  
  # Try to read token data
  echo "  Reading token data..."
  
  # Get name
  NAME=$(cast call "$token_address" "function name() returns (string)" \
    --rpc-url "$RPC_URL" 2>/dev/null || echo "Error")
  if [ "$NAME" != "Error" ]; then
    print_success "Token name: $NAME"
  fi
  
  # Get symbol
  SYMBOL=$(cast call "$token_address" "function symbol() returns (string)" \
    --rpc-url "$RPC_URL" 2>/dev/null || echo "Error")
  if [ "$SYMBOL" != "Error" ]; then
    print_success "Token symbol: $SYMBOL"
  fi
  
  # Get total supply
  SUPPLY=$(cast call "$token_address" "function totalSupply() returns (uint256)" \
    --rpc-url "$RPC_URL" 2>/dev/null || echo "0")
  if [ "$SUPPLY" != "0" ]; then
    # Convert to human readable (assuming 18 decimals)
    SUPPLY_HUMAN=$(cast format-units "$SUPPLY" 18 2>/dev/null || echo "$SUPPLY")
    print_success "Total supply: $SUPPLY_HUMAN MEE"
  fi
  
  echo ""
  return 0
}

# Verify MEEReward
verify_meereward() {
  local reward_address=$1
  
  print_section "Verifying MEEReward (ERC721 Soulbound)..."
  
  if ! verify_contract "$reward_address" "MEEReward"; then
    return 1
  fi
  
  # Try to read NFT data
  echo "  Reading NFT data..."
  
  # Get name
  NAME=$(cast call "$reward_address" "function name() returns (string)" \
    --rpc-url "$RPC_URL" 2>/dev/null || echo "Error")
  if [ "$NAME" != "Error" ]; then
    print_success "NFT name: $NAME"
  fi
  
  # Get symbol
  SYMBOL=$(cast call "$reward_address" "function symbol() returns (string)" \
    --rpc-url "$RPC_URL" 2>/dev/null || echo "Error")
  if [ "$SYMBOL" != "Error" ]; then
    print_success "NFT symbol: $SYMBOL"
  fi
  
  # Get total badges minted
  BADGES=$(cast call "$reward_address" "function totalBadgesMinted() returns (uint256)" \
    --rpc-url "$RPC_URL" 2>/dev/null || echo "0")
  if [ "$BADGES" != "0" ]; then
    print_success "Total badges minted: $BADGES"
  else
    print_info "No badges minted yet (this is normal for new contracts)"
  fi
  
  echo ""
  return 0
}

# Generate summary report
generate_report() {
  local token_address=$1
  local reward_address=$2
  local token_verified=$3
  local reward_verified=$4
  
  echo ""
  echo -e "${BLUE}╔════════════════════════════════════════════╗${NC}"
  echo -e "${BLUE}║         VERIFICATION SUMMARY               ║${NC}"
  echo -e "${BLUE}╚════════════════════════════════════════════╝${NC}"
  echo ""
  
  echo "Network:  MeeChain (Chain ID: $CHAIN_ID)"
  echo "RPC URL:  $RPC_URL"
  echo ""
  
  echo "Contracts:"
  if [ "$token_verified" = "true" ]; then
    echo -e "  ${GREEN}✅ MEEToken:${NC} $token_address"
  else
    echo -e "  ${RED}❌ MEEToken:${NC} $token_address (not verified)"
  fi
  
  if [ "$reward_verified" = "true" ]; then
    echo -e "  ${GREEN}✅ MEEReward:${NC} $reward_address"
  else
    echo -e "  ${RED}❌ MEEReward:${NC} $reward_address (not verified)"
  fi
  
  echo ""
  
  if [ "$token_verified" = "true" ] && [ "$reward_verified" = "true" ]; then
    echo -e "${GREEN}✨ All contracts verified successfully! ✨${NC}"
    echo ""
    echo "Next steps:"
    echo "  1. Update your .env with contract addresses"
    echo "  2. Test interactions with cast or ethers.js"
    echo "  3. Monitor transaction logs"
    echo ""
    return 0
  else
    echo -e "${YELLOW}⚠️  Some contracts could not be verified${NC}"
    echo ""
    echo "Troubleshooting:"
    echo "  • Check addresses are correct"
    echo "  • Wait a few blocks for propagation"
    echo "  • Verify RPC connectivity"
    echo ""
    return 1
  fi
}

# Main execution
main() {
  print_header
  
  # Get addresses from arguments or prompt
  if [ $# -eq 2 ]; then
    TOKEN_ADDRESS="$1"
    REWARD_ADDRESS="$2"
    print_info "Using provided addresses"
  else
    echo "Enter contract addresses to verify:"
    echo ""
    read -p "MEEToken address (0x...): " TOKEN_ADDRESS
    read -p "MEEReward address (0x...): " REWARD_ADDRESS
  fi
  
  echo ""
  
  # Run verification steps
  check_cast || exit 1
  test_rpc || exit 1
  
  TOKEN_OK="false"
  REWARD_OK="false"
  
  verify_meetoken "$TOKEN_ADDRESS" && TOKEN_OK="true"
  verify_meereward "$REWARD_ADDRESS" && REWARD_OK="true"
  
  # Generate report
  generate_report "$TOKEN_ADDRESS" "$REWARD_ADDRESS" "$TOKEN_OK" "$REWARD_OK"
  
  # Save report to file
  if [ ! -d "deployments" ]; then
    mkdir -p deployments
  fi
  
  REPORT_FILE="deployments/verification-$(date +%s).json"
  cat > "$REPORT_FILE" << EOF
{
  "timestamp": "$(date -u +'%Y-%m-%dT%H:%M:%SZ')",
  "network": "MeeChain",
  "chainId": $CHAIN_ID,
  "rpcUrl": "$RPC_URL",
  "contracts": {
    "MEEToken": {
      "address": "$TOKEN_ADDRESS",
      "verified": $TOKEN_OK
    },
    "MEEReward": {
      "address": "$REWARD_ADDRESS",
      "verified": $REWARD_OK
    }
  }
}
EOF
  
  print_info "Verification report saved to: $REPORT_FILE"
  echo ""
}

# Run main function
main "$@"
