const { ethers } = require("ethers");
const provider = new ethers.JsonRpcProvider("https://rpc.meechain.live");

// ใช้ private key จาก anvil (เช่น account 0)
const wallet = new ethers.Wallet("0xca0974bec39a17e36ba4a6b4238ff944bacb478cbed5efcae784d7bf4f2ff80", provider);

async function main() {
  const tx = await wallet.sendTransaction({
    to: "0x0000000000000000000000000000000000000000",
    value: ethers.parseEther("1.0")
  });
  console.log("TX Hash:", tx.hash);
  await tx.wait();
  console.log("Block mined!");
}

main();
