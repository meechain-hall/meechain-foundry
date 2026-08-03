#!/bin/bash

# MeeChain RPC URL
RPC_URL="https://rpc.meechain.live"

# Contract addresses
MEETOKEN="0x3aa5ebb10dc797cac828524e59a333d0a371443c"
MEEREWARD="0xAdd57a9b9b17d34bebb88566ab2f5d8799cc46f"

echo "🔎 Checking MEEToken..."
cast code --rpc-url $RPC_URL $MEETOKEN

echo "🔎 Checking MEEReward..."
cast code --rpc-url $RPC_URL $MEEREWARD

