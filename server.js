/**
 * ============================================================================
 *  MeeChain Magic Layer — server.js
 * ============================================================================
 *  "Blockchain ที่ใช้งานเหมือนเวทมนตร์"
 *
 *  ไฟล์นี้คือ Magic Translation Layer ที่ครอบทับ MeeChain Core API เดิม
 *  (wallet / NFT / staking / explorer / MeeBot) แล้วแปลงเป็นภาษาประสบการณ์
 *  ตาม MeeChain Magic mapping:
 *
 *    Wallet      -> Magic Key
 *    NFT         -> Relic
 *    Token       -> Energy
 *    Explorer    -> Realm Vision
 *    Validator   -> Guardian
 *    Stake       -> Ritual
 *    Bridge      -> Portal
 *    Faucet      -> Blessing Fountain
 *
 *  โครงสร้าง:
 *    1) Config & mock-fallback helpers
 *    2) Magic Actions      (Layer 1 - Activate Key / Create Relic / Ritual / Blessing)
 *    3) Magic Orb          (Dashboard สถานะระบบ)
 *    4) Magic Achievements (Badge system)
 *    5) MeeBot Sage        (AI Assistant wrapper)
 *    6) Magic Map          (Explorer แบบใหม่)
 *    7) Magic Events       (Daily Quest)
 *    8) Magic Hall         (รวมทุกอย่างเป็นหน้าโปรไฟล์นักผจญภัย)
 *
 *  รันแบบ mock fallback ได้ทันทีถ้ายังไม่มี RPC/DB จริง (เห็นผลลัพธ์ demo ได้เลย)
 * ============================================================================
 */

const express = require("express");
const cors = require("cors");
const path = require("path");
const { ethers } = require("ethers"); // ethers v5 (ตาม stack เดิมของโปรเจกต์)
//const cron = require("node-cron");
const app = express();
app.use(cors());
app.use(express.json());
const cron = require('node-cron');

const PORT = process.env.PORT || 5000;
const CHAIN_ID = process.env.CHAIN_ID || "13390"; // MeeChain custom EVM
const RPC_URL = process.env.RPC_URL || "http://localhost:8545";

// ---------------------------------------------------------------------------
// Contract config — ต้องตั้งค่าใน .env ก่อนจะ "real mode" ทำงานได้จริง
//   BADGE_SYSTEM_ADDRESS   -> BadgeSystem.sol (soulbound ERC-721)
//   TOKEN_ADDRESS          -> MeeMusic Token (ERC20)
//   STAKING_ADDRESS        -> Ritual/Staking contract
//   REGISTRY_ADDRESS       -> Transparent Registry contract
//   BACKEND_SIGNER_KEY     -> private key ของ backend signer ที่มี MINTER_ROLE
//                             (ใช้เซ็น signature ให้ BadgeSystem.sol เท่านั้น
//                              ไม่ใช่ key ที่ถือเงินผู้ใช้)
// ---------------------------------------------------------------------------
const BADGE_SYSTEM_ADDRESS = process.env.BADGE_SYSTEM_ADDRESS || "";
const TOKEN_ADDRESS = process.env.TOKEN_ADDRESS || "";
const STAKING_ADDRESS = process.env.STAKING_ADDRESS || "";
const REGISTRY_ADDRESS = process.env.REGISTRY_ADDRESS || "";
const BACKEND_SIGNER_KEY = process.env.BACKEND_SIGNER_KEY || "";

const MOCK_MODE =
  process.env.MOCK_MODE === "true" ||
  !process.env.RPC_URL ||
  !BADGE_SYSTEM_ADDRESS ||
  !BACKEND_SIGNER_KEY;

// Minimal ABIs — ใส่เฉพาะ function ที่ endpoint นี้เรียกใช้จริง
const BADGE_SYSTEM_ABI = [
  "function nonces(address user) view returns (uint256)",
  "function mintBadge(address to, uint8 badgeType, uint256 nonce, bytes signature) returns (uint256)",
  "event BadgeMinted(address indexed to, uint256 indexed tokenId, uint8 badgeType)",
];
const ERC20_ABI = [
  "function balanceOf(address owner) view returns (uint256)",
  "function transfer(address to, uint256 amount) returns (bool)",
  "function decimals() view returns (uint8)",
];
const STAKING_ABI = [
  "function stake(uint256 amount) returns (bool)",
  "function totalStaked() view returns (uint256)",
];
const REGISTRY_ABI = ["function validatorCount() view returns (uint256)"];

let provider = null;
let backendSigner = null;
let badgeSystemRead = null; // read-only instance (ใช้ provider)
let badgeSystemWrite = null; // write instance (ใช้ backendSigner สำหรับ relay mint)
let tokenRead = null;
let stakingRead = null;
let registryRead = null;

if (!MOCK_MODE) {
  try {
    provider = new ethers.providers.JsonRpcProvider(RPC_URL);
    backendSigner = new ethers.Wallet(BACKEND_SIGNER_KEY, provider);

    badgeSystemRead = new ethers.Contract(BADGE_SYSTEM_ADDRESS, BADGE_SYSTEM_ABI, provider);
    badgeSystemWrite = new ethers.Contract(BADGE_SYSTEM_ADDRESS, BADGE_SYSTEM_ABI, backendSigner);

    if (TOKEN_ADDRESS) tokenRead = new ethers.Contract(TOKEN_ADDRESS, ERC20_ABI, provider);
    if (STAKING_ADDRESS) stakingRead = new ethers.Contract(STAKING_ADDRESS, STAKING_ABI, provider);
    if (REGISTRY_ADDRESS) registryRead = new ethers.Contract(REGISTRY_ADDRESS, REGISTRY_ABI, provider);

    console.log("🔗 MeeChain Magic Layer: real chain mode enabled");
  } catch (err) {
    console.error("⚠️ ตั้งค่า provider/contract ไม่สำเร็จ, กลับไปใช้ mock mode:", err.message);
  }
}

// badgeType enum ให้ตรงกับ BadgeSystem.sol (ปรับตัวเลขให้ตรงกับ contract จริง)
const BADGE_TYPE_MAP = {
  first_awakening: 0,
  relic_creator: 1,
  ritual_master: 2,
};

// ---------------------------------------------------------------------------
// 1) Magic Dictionary — ใช้แปลง response/label ให้เป็นภาษาเวทมนตร์เสมอ
// ---------------------------------------------------------------------------
const MAGIC_TERMS = {
  wallet: "Magic Key",
  nft: "Relic",
  token: "Energy",
  explorer: "Realm Vision",
  validator: "Guardian",
  stake: "Ritual",
  bridge: "Portal",
  faucet: "Blessing Fountain",
  transaction: "Energy Transfer",
  address: "Adventurer",
  block: "Timeline of Realms",
};

function magicResponse(action, data, extra = {}) {
  return {
    magic: true,
    action,
    dictionary: MAGIC_TERMS,
    result: data,
    mock: MOCK_MODE,
    ...extra,
  };
}

// mock helper กัน error ตอน RPC/DB ยังไม่พร้อม (ตาม pattern เดิมของโปรเจกต์)
function mockOrReal(mockFn, realFn) {
  return async (...args) => {
    if (MOCK_MODE) return mockFn(...args);
    try {
      return await realFn(...args);
    } catch (err) {
      console.warn("[MeeChain Magic] real call failed, falling back to mock:", err.message);
      return mockFn(...args);
    }
  };
}

// ---------------------------------------------------------------------------
// 2) MAGIC ACTIONS — Layer 1
// ---------------------------------------------------------------------------

// 🪄 Activate Magic Key  (เดิมคือ Connect Wallet)
app.post("/api/magic/activate-key", async (req, res) => {
  const { address } = req.body;
  if (!address) return res.status(400).json({ error: "ต้องระบุ address ของ Magic Key" });

  grantBadge(address, "firstAwakening"); // ปลุก Magic Key ครั้งแรก -> ได้ badge นี้ทันที

  const payload = {
    address,
    status: "activated",
    firstAwakening: true, // trigger badge check ฝั่ง client
    message: "🪄 Magic Key ของท่านถูกปลุกให้ตื่นแล้ว ยินดีต้อนรับสู่ MeeChain Realm",
  };
  res.json(magicResponse("activate-key", payload));
});

// 🪄 Create Relic (เดิมคือ Mint NFT)
//    Flow: backend อ่าน nonce ปัจจุบันของผู้ใช้ -> เซ็น signature ด้วย backendSigner
//          (ที่มี MINTER_ROLE บน BadgeSystem.sol) -> เรียก mintBadge() แทนผู้ใช้
//          (ตรงกับ pattern "off-chain verification + on-chain mint + nonce replay
//           protection" ที่ใช้ในโปรเจกต์นี้อยู่แล้ว)
app.post("/api/magic/create-relic", async (req, res) => {
  const { address, relicType, metadataUri } = req.body;
  if (!address || !relicType) {
    return res.status(400).json({ error: "ต้องระบุ address และ relicType" });
  }
  if (!BADGE_TYPE_MAP.hasOwnProperty(relicType) && !Number.isInteger(relicType)) {
    return res.status(400).json({
      error: `relicType ไม่ถูกต้อง ต้องเป็นหนึ่งใน: ${Object.keys(BADGE_TYPE_MAP).join(", ")}`,
    });
  }

  const badgeTypeId = BADGE_TYPE_MAP[relicType] ?? relicType;

  const mint = mockOrReal(
    () => ({
      relicId: `relic_${Date.now()}`,
      txHash: `0xMOCK${Math.random().toString(16).slice(2, 10)}`,
      relicType,
      metadataUri: metadataUri || null,
      chainId: CHAIN_ID,
    }),
    async () => {
      // 1) อ่าน nonce ปัจจุบันของผู้ใช้ (กัน replay attack)
      const nonce = await badgeSystemRead.nonces(address);

      // 2) สร้าง message hash แล้วเซ็นด้วย backend signer (มี MINTER_ROLE)
      const messageHash = ethers.utils.solidityKeccak256(
        ["address", "uint8", "uint256"],
        [address, badgeTypeId, nonce]
      );
      const signature = await backendSigner.signMessage(ethers.utils.arrayify(messageHash));

      // 3) relay ธุรกรรมจริงเข้า BadgeSystem.sol
      const tx = await badgeSystemWrite.mintBadge(address, badgeTypeId, nonce, signature);
      const receipt = await tx.wait();

      return {
        txHash: receipt.transactionHash,
        blockNumber: receipt.blockNumber,
        relicType,
        badgeTypeId,
        metadataUri: metadataUri || null,
        chainId: CHAIN_ID,
      };
    }
  );

  try {
    const result = await mint();
    logQuestEvent(address, "create-relic", "confirmed", { relicType, txHash: result.txHash });
    grantBadge(address, "relicCreator");
    autoCompleteDailyQuest(address, "create-relic");
    res.json(
      magicResponse("create-relic", result, {
        message: "🪄 ข้าจะเตรียมพิธีให้ ... Relic ของท่านถูกสร้างขึ้นแล้ว",
      })
    );
  } catch (err) {
    console.error("[create-relic] mint failed:", err.message);
    res.status(500).json({ error: "พิธีสร้าง Relic ล้มเหลว โปรดลองใหม่", detail: err.message });
  }
});

// 🪄 Ritual of Growth (เดิมคือ Stake Token)
//    ⚠️ สถาปัตยกรรม: การ stake ย้าย Energy (token) ของ "ผู้ใช้เอง" — backend ไม่ควร
//    ถือ private key ผู้ใช้เด็ดขาด ดังนั้น endpoint นี้แค่ "เตรียม unsigned tx"
//    (to, data, value) กลับไปให้ frontend เซ็นเองผ่าน Wagmi/Web3Auth แล้วค่อย
//    broadcast จริง backend ไม่ relay ธุรกรรมนี้แทนผู้ใช้
app.post("/api/magic/ritual-of-growth", async (req, res) => {
  const { address, amount, durationDays } = req.body;
  if (!address || !amount) {
    return res.status(400).json({ error: "ต้องระบุ address และ amount (Energy ที่จะใช้ทำพิธี)" });
  }

  const prepareStake = mockOrReal(
    () => ({
      ritualId: `ritual_${Date.now()}`,
      energyLocked: amount,
      durationDays: durationDays || 30,
      estimatedReward: (Number(amount) * 0.08).toFixed(4), // mock 8% APR แบบง่าย
      requiresUserSignature: false,
    }),
    async () => {
      if (!stakingRead) throw new Error("STAKING_ADDRESS ยังไม่ได้ตั้งค่าใน .env");

      const decimals = tokenRead ? await tokenRead.decimals() : 18;
      const amountWei = ethers.utils.parseUnits(String(amount), decimals);

      // เตรียม calldata ของฟังก์ชัน stake(amount) โดยไม่เซ็น/broadcast เอง
      const iface = new ethers.utils.Interface(STAKING_ABI);
      const data = iface.encodeFunctionData("stake", [amountWei]);

      const totalStaked = await stakingRead.totalStaked();

      return {
        ritualId: `ritual_${Date.now()}`,
        requiresUserSignature: true,
        unsignedTx: { to: STAKING_ADDRESS, data, value: "0x0", chainId: Number(CHAIN_ID) },
        currentTotalStaked: ethers.utils.formatUnits(totalStaked, decimals),
        durationDays: durationDays || 30,
        note: "โปรดเซ็นธุรกรรมนี้ด้วย Magic Key (wallet) ของท่านเองผ่าน frontend",
      };
    }
  );

  try {
    const result = await prepareStake();
    logQuestEvent(address, "ritual-of-growth", "started", { amount, durationDays });
    res.json(
      magicResponse("ritual-of-growth", result, {
        message: "🔥 พิธีแห่งการเติบโตถูกเตรียมไว้แล้ว จงยืนยันด้วย Magic Key ของท่านเพื่อเริ่มพิธี",
      })
    );
  } catch (err) {
    console.error("[ritual-of-growth] prepare failed:", err.message);
    res.status(500).json({ error: "เตรียมพิธีแห่งการเติบโตล้มเหลว", detail: err.message });
  }
});

// เรียกจาก frontend หลังจากผู้ใช้เซ็นและ tx confirm บนเชนแล้ว (ดู MagicActions.jsx)
app.post("/api/magic/ritual-of-growth/confirm", (req, res) => {
  const { address, txHash, amount, durationDays } = req.body;
  if (!address || !txHash) return res.status(400).json({ error: "ต้องระบุ address และ txHash" });

  logQuestEvent(address, "ritual-of-growth", "confirmed", { txHash, amount, durationDays });
  grantBadge(address, "ritualMaster");
  autoCompleteDailyQuest(address, "ritual-of-growth");

  res.json(
    magicResponse("ritual-of-growth-confirmed", { address, txHash }, {
      message: "🔥 พิธีแห่งการเติบโตสำเร็จแล้ว! พลังของท่านเพิ่มขึ้น",
    })
  );
});

// 🪄 Send Blessing (เดิมคือ Transfer Asset)
//    เช่นเดียวกับ Ritual of Growth — เป็นการย้าย Energy ของผู้ใช้เอง จึงเตรียมแค่
//    unsigned tx กลับไปให้ frontend เซ็นเอง ไม่ relay แทนผู้ใช้
app.post("/api/magic/send-blessing", async (req, res) => {
  const { from, to, amount } = req.body;
  if (!from || !to || !amount) {
    return res.status(400).json({ error: "ต้องระบุ from, to และ amount" });
  }

  const prepareTransfer = mockOrReal(
    () => ({
      txHash: `0xMOCK${Math.random().toString(16).slice(2, 10)}`,
      from,
      to,
      amount,
      requiresUserSignature: false,
    }),
    async () => {
      if (!tokenRead) throw new Error("TOKEN_ADDRESS ยังไม่ได้ตั้งค่าใน .env");

      const decimals = await tokenRead.decimals();
      const amountWei = ethers.utils.parseUnits(String(amount), decimals);

      const iface = new ethers.utils.Interface(ERC20_ABI);
      const data = iface.encodeFunctionData("transfer", [to, amountWei]);

      return {
        requiresUserSignature: true,
        unsignedTx: { to: TOKEN_ADDRESS, data, value: "0x0", chainId: Number(CHAIN_ID) },
        from,
        to,
        amount,
        note: "โปรดเซ็นธุรกรรมนี้ด้วย Magic Key (wallet) ของท่านเองผ่าน frontend",
      };
    }
  );

  try {
    const result = await prepareTransfer();
    logQuestEvent(from, "send-blessing", "started", { to, amount });
    res.json(
      magicResponse("send-blessing", result, {
        message: `✨ พรถูกเตรียมไว้แล้วสำหรับส่งจาก ${from} ไปยัง ${to} — รอการยืนยันจาก Magic Key`,
      })
    );
  } catch (err) {
    console.error("[send-blessing] prepare failed:", err.message);
    res.status(500).json({ error: "เตรียมพรล้มเหลว", detail: err.message });
  }
});

// เรียกจาก frontend หลังจากผู้ใช้เซ็นและ tx confirm บนเชนแล้ว (ดู MagicActions.jsx)
app.post("/api/magic/send-blessing/confirm", (req, res) => {
  const { from, to, txHash, amount } = req.body;
  if (!from || !txHash) return res.status(400).json({ error: "ต้องระบุ from และ txHash" });

  logQuestEvent(from, "send-blessing", "confirmed", { to, amount, txHash });
  autoCompleteDailyQuest(from, "send-blessing");

  res.json(
    magicResponse("send-blessing-confirmed", { from, to, txHash }, {
      message: "✨ พรถูกส่งถึงมือผู้รับเรียบร้อยแล้ว",
    })
  );
});

// ---------------------------------------------------------------------------
// 3) MAGIC ORB — Dashboard สถานะระบบแบบเรียลไทม์
// ---------------------------------------------------------------------------
app.get("/api/magic/orb", async (req, res) => {
  const getOrbStatus = mockOrReal(
    () => ({
      chainEnergy: { status: "🟢", label: "Chain Energy", detail: "Network healthy" },
      rpcSpirit: { status: "🟢", label: "RPC Spirit", detail: `Connected to ${RPC_URL}` },
      treasuryAura: { status: "🟢", label: "Treasury Aura", detail: "Reserves stable" },
      validatorForce: { status: "🟢", label: "Validator Force", detail: "Guardians online" },
    }),
    async () => {
      // ยิงจริงแบบขนานเพื่อความเร็ว: block number, treasury balance, validator count
      const treasuryAddress = process.env.TREASURY_ADDRESS || null;

      const [blockNumber, treasuryBalanceRaw, decimals, validatorCount] = await Promise.all([
        provider.getBlockNumber(),
        tokenRead && treasuryAddress ? tokenRead.balanceOf(treasuryAddress) : Promise.resolve(null),
        tokenRead ? tokenRead.decimals() : Promise.resolve(18),
        registryRead ? registryRead.validatorCount() : Promise.resolve(null),
      ]);

      return {
        chainEnergy: { status: "🟢", label: "Chain Energy", detail: `Block #${blockNumber}` },
        rpcSpirit: { status: "🟢", label: "RPC Spirit", detail: `Connected to ${RPC_URL}` },
        treasuryAura: {
          status: treasuryBalanceRaw ? "🟢" : "⚪",
          label: "Treasury Aura",
          detail: treasuryBalanceRaw
            ? `${ethers.utils.formatUnits(treasuryBalanceRaw, decimals)} Energy in reserve`
            : "TREASURY_ADDRESS ยังไม่ได้ตั้งค่า",
        },
        validatorForce: {
          status: validatorCount ? "🟢" : "⚪",
          label: "Validator Force",
          detail: validatorCount ? `${validatorCount.toString()} Guardians online` : "REGISTRY_ADDRESS ยังไม่ได้ตั้งค่า",
        },
      };
    }
  );

  try {
    const orb = await getOrbStatus();
    res.json(magicResponse("magic-orb", orb));
  } catch (err) {
    console.error("[magic-orb] read failed:", err.message);
    res.status(500).json({ error: "ลูกแก้วเวทมนตร์ขุ่นมัว โปรดลองใหม่", detail: err.message });
  }
});

// ---------------------------------------------------------------------------
// 4) MAGIC ACHIEVEMENTS — Badge system
// ---------------------------------------------------------------------------
const BADGE_CATALOG = {
  firstAwakening: { id: "first_awakening", label: "✨ First Awakening", trigger: "activate-key" },
  relicCreator: { id: "relic_creator", label: "🏺 Relic Creator", trigger: "create-relic" },
  ritualMaster: { id: "ritual_master", label: "🔥 Ritual Master", trigger: "ritual-of-growth" },
};

// mock in-memory store (แทนที่ด้วย MongoDB จริงตาม pattern เดิมของ meechain-api)
const achievementStore = new Map();

// ---------------------------------------------------------------------------
// Quest Log store — เก็บประวัติว่าผู้ใช้ทำ ritual/blessing/relic ไปแล้วกี่ครั้ง
//   บันทึก 2 จังหวะ:
//     - "started"   ทันทีตอนเตรียมธุรกรรม (ยังไม่ confirm บนเชน)
//     - "confirmed" ตอน frontend เซ็นและ confirm สำเร็จแล้ว (เรียก /confirm endpoint)
// ---------------------------------------------------------------------------
const questLogStore = new Map(); // address -> [{ type, status, detail, timestamp }]

function logQuestEvent(address, type, status, detail = {}) {
  const existing = questLogStore.get(address) || [];
  existing.push({ type, status, detail, timestamp: new Date().toISOString() });
  questLogStore.set(address, existing);
  return existing;
}

function getQuestSummary(address) {
  const log = questLogStore.get(address) || [];
  const confirmed = log.filter((e) => e.status === "confirmed");
  return {
    address,
    totalRitualsConfirmed: confirmed.filter((e) => e.type === "ritual-of-growth").length,
    totalBlessingsSent: confirmed.filter((e) => e.type === "send-blessing").length,
    totalRelicsCreated: confirmed.filter((e) => e.type === "create-relic").length,
    timeline: log.slice(-50).reverse(), // ล่าสุดขึ้นก่อน
  };
}

function grantBadge(address, badgeKey) {
  const existing = achievementStore.get(address) || [];
  if (!existing.find((b) => b.id === BADGE_CATALOG[badgeKey].id)) {
    // seen: false -> ยังไม่เคยแสดง popup ให้ผู้ใช้เห็นเลย (frontend จะ poll เจอแล้ว popup ขึ้น)
    existing.push({ ...BADGE_CATALOG[badgeKey], earnedAt: new Date().toISOString(), seen: false });
    achievementStore.set(address, existing);
    console.log(`🎖️ [Achievement] ${address} ปลดล็อก badge "${BADGE_CATALOG[badgeKey].id}"`);
  }
  return achievementStore.get(address);
}

app.post("/api/magic/achievements/grant", (req, res) => {
  const { address, badgeKey } = req.body;
  if (!address || !BADGE_CATALOG[badgeKey]) {
    return res.status(400).json({ error: "ต้องระบุ address และ badgeKey ที่ถูกต้อง" });
  }
  const badges = grantBadge(address, badgeKey);
  res.json(magicResponse("achievement-granted", { address, badges }));
});

app.get("/api/magic/achievements/:address", (req, res) => {
  const badges = achievementStore.get(req.params.address) || [];
  res.json(magicResponse("achievements", { address: req.params.address, badges }));
});

// เรียกจาก frontend หลัง popup แสดงผลให้ผู้ใช้เห็นแล้ว -> mark seen กันไม่ให้ popup ขึ้นซ้ำ
app.post("/api/magic/achievements/ack", (req, res) => {
  const { address, badgeIds } = req.body;
  if (!address || !Array.isArray(badgeIds)) {
    return res.status(400).json({ error: "ต้องระบุ address และ badgeIds (array)" });
  }
  const existing = achievementStore.get(address) || [];
  const updated = existing.map((b) => (badgeIds.includes(b.id) ? { ...b, seen: true } : b));
  achievementStore.set(address, updated);
  res.json(magicResponse("achievements-ack", { address, badges: updated }));
});

// ---------------------------------------------------------------------------
// QUEST LOG — สรุปว่าผู้ใช้ทำ ritual/blessing/relic ไปแล้วกี่ครั้ง + timeline
// ---------------------------------------------------------------------------
app.get("/api/magic/quest-log/:address", (req, res) => {
  const summary = getQuestSummary(req.params.address);
  res.json(magicResponse("quest-log", summary));
});

// ---------------------------------------------------------------------------
// 5) MEEBOT SAGE — AI Assistant wrapper (persona: 🧙 นักปราชญ์เวทมนตร์)
// ---------------------------------------------------------------------------
const SAGE_INTENTS = [
  {
    match: /สร้าง\s*nft|mint|relic/i,
    reply: "🪄 ข้าจะเตรียมพิธีให้ กดปุ่มด้านล่างเพื่อสร้าง Relic",
    suggestedAction: "create-relic",
  },
  {
    match: /stake|ปักหลัก|ริชวล|ritual/i,
    reply: "🔥 หากท่านต้องการเติบโต จงเริ่มพิธีแห่งการเติบโตกับข้า",
    suggestedAction: "ritual-of-growth",
  },
  {
    match: /wallet|กระเป๋า|connect|magic key/i,
    reply: "🗝️ จงปลุก Magic Key ของท่านก่อน แล้วโลก MeeChain Realm จะเปิดออกให้",
    suggestedAction: "activate-key",
  },
];

app.post("/api/magic/sage", (req, res) => {
  const { message, address } = req.body;

  // โหมด 1: ผู้ใช้พิมพ์คุยกับ Sage ตรงๆ -> intent matching แบบเดิม
  if (message) {
    const matched = SAGE_INTENTS.find((intent) => intent.match.test(message));
    const reply = matched
      ? { text: matched.reply, suggestedAction: matched.suggestedAction }
      : {
          text: "🧙 ข้าฟังคำท่านแล้ว แต่ยังไม่แน่ใจว่าท่านต้องการพิธีใด ลองถามใหม่อีกครั้งได้ไหม",
          suggestedAction: null,
        };
    return res.json(magicResponse("meebot-sage", reply));
  }

  // โหมด 2: ไม่มี message -> Sage อ่าน Quest Log ของ address นี้แล้วแนะนำ ritual ถัดไปเอง
  if (!address) {
    return res.status(400).json({ error: "ต้องระบุ message หรือ address อย่างน้อยหนึ่งอย่าง" });
  }

  const summary = getQuestSummary(address);
  const advice = adviseNextRitual(summary);
  return res.json(magicResponse("meebot-sage", advice, { questLog: summary }));
});

// วิเคราะห์ Quest Log แล้วแนะนำพิธีถัดไปที่ "เหมาะสมที่สุด" ให้ผู้ใช้คนนี้
function adviseNextRitual(summary) {
  const { totalRelicsCreated, totalRitualsConfirmed, totalBlessingsSent } = summary;

  // นักผจญภัยใหม่ ยังไม่เคยทำอะไรเลย -> แนะนำ Relic ก่อน (ง่ายสุด, ได้ badge แรกไว)
  if (totalRelicsCreated === 0) {
    return {
      text: "🧙 ข้าเห็นว่าท่านยังไม่มี Relic เลยสักชิ้น ลองเริ่มจากการสร้าง Relic แรกของท่านก่อนดีไหม",
      suggestedAction: "create-relic",
      reason: "no-relics-yet",
    };
  }

  // มี Relic แล้วแต่ยังไม่เคยทำ Ritual -> แนะนำ Ritual of Growth ต่อ
  if (totalRitualsConfirmed === 0) {
    return {
      text: "🔥 ท่านมี Relic แล้ว ลองนำพลังไปเข้าสู่พิธีแห่งการเติบโตเพื่อสร้างผลตอบแทนดูสิ",
      suggestedAction: "ritual-of-growth",
      reason: "no-rituals-yet",
    };
  }

  // เคย Ritual แล้วแต่ยังไม่เคยส่งพร -> แนะนำ Send Blessing เพื่อสร้างเครือข่ายผู้ใช้
  if (totalBlessingsSent === 0) {
    return {
      text: "✨ พลังของท่านเติบโตดีแล้ว ลองแบ่งปันพรให้เพื่อนนักผจญภัยคนอื่นดูบ้างไหม",
      suggestedAction: "send-blessing",
      reason: "no-blessings-yet",
    };
  }

  // ทำครบทุกอย่างแล้ว -> ชวนไปทำ Daily Quest หรือ Ritual เพิ่มเพื่อพลังที่มากขึ้น
  return {
    text: `🌟 ท่านผ่านพิธีมาแล้ว ${totalRitualsConfirmed} ครั้ง และส่งพรไป ${totalBlessingsSent} ครั้ง ลองแวะไปดู Daily Quest วันนี้เพื่อรับพลังเพิ่มเติมไหม`,
    suggestedAction: "daily-quest",
    reason: "veteran-adventurer",
  };
}

// ---------------------------------------------------------------------------
// 6) MAGIC MAP — Explorer แบบใหม่
// ---------------------------------------------------------------------------
app.get("/api/magic/realm-vision", async (req, res) => {
  const getRealmVision = mockOrReal(
    () => ({
      latestBlock: 123456,
      recentTransactions: [
        { txHash: "0xMOCKabc123", from: "0xUser1", to: "0xUser2", amount: "10 Energy" },
        { txHash: "0xMOCKdef456", from: "0xUser3", to: "0xUser4", amount: "5 Energy" },
      ],
      guardiansOnline: 7,
      chainId: CHAIN_ID,
    }),
    async () => {
      const blockNumber = await provider.getBlockNumber();
      const guardians = registryRead ? await registryRead.validatorCount() : 0;

      return {
        latestBlock: blockNumber,
        recentTransactions: [], // TODO: ดึงจาก RPC explorer จริง
        guardiansOnline: guardians.toString(),
        chainId: CHAIN_ID,
      };
    }
  );

  try {
    const vision = await getRealmVision();
    res.json(magicResponse("realm-vision", vision, {
      message: "🌌 Realm Vision เปิดเผยเส้นทางของโลก MeeChain แล้ว",
    }));
  } catch (err) {
    console.error("[realm-vision] read failed:", err.message);
    res.status(500).json({ error: "Realm Vision ล้มเหลว", detail: err.message });
  }
});

// ---------------------------------------------------------------------------
// 7) MAGIC EVENTS — Daily Quest (cron-based rotation + auto-completion)
// ---------------------------------------------------------------------------
// แนวคิด:
//   - QUEST_POOL คือคลังภารกิจทั้งหมดที่มีสิทธิ์ถูกสุ่มมาเป็น "ภารกิจวันนี้"
//   - ทุกเที่ยงคืน cron จะสุ่มเลือก 3 ภารกิจจาก pool มาเป็นชุดของวันนั้น
//     (ใช้ seeded shuffle จาก "วันที่" เป็น seed -> ผู้ใช้ทุกคนเห็นชุดเดียวกันในวันเดียวกัน)
//   - ภารกิจที่ mode: "auto" จะถูกเช็คสำเร็จอัตโนมัติจาก Quest Log ที่มีอยู่แล้ว
//     (เช่นพอ create-relic confirm สำเร็จวันนี้ -> relic_quest ติ๊กถูกทันที)
//   - ภารกิจที่ mode: "manual" ต้องให้ frontend เรียก /confirm เพื่อยืนยันเอง
//     (เช่น เข้าไปดู Realm Vision, หรือเช็ค RPC ผ่านหน้า Magic Orb)
// ---------------------------------------------------------------------------

const QUEST_POOL = [
  { id: "relic_quest", label: "🏺 Relic Quest", desc: "สร้าง Relic อย่างน้อย 1 ชิ้นวันนี้", mode: "auto", actionType: "create-relic" },
  { id: "ritual_quest", label: "🔥 Ritual Quest", desc: "ทำพิธี Ritual of Growth อย่างน้อย 1 ครั้งวันนี้", mode: "auto", actionType: "ritual-of-growth" },
  { id: "blessing_quest", label: "✨ Blessing Quest", desc: "ส่ง Blessing อย่างน้อย 1 ครั้งวันนี้", mode: "auto", actionType: "send-blessing" },
  { id: "rpc_guardian", label: "🛡️ RPC Guardian", desc: "ตรวจสอบ RPC ให้ยังคงออนไลน์วันนี้ (เปิดหน้า Magic Orb)", mode: "manual" },
  { id: "council_gathering", label: "🏛️ Council Gathering", desc: "โหวตใน DAO อย่างน้อย 1 ครั้ง", mode: "manual" },
  { id: "realm_explorer", label: "🌌 Realm Explorer", desc: "สำรวจ Magic Map (Realm Vision) วันนี้", mode: "manual" },
];
const QUESTS_PER_DAY = 3;

// dateStr ("YYYY-MM-DD") -> array ของ quest ที่ถูกสุ่มมาในวันนั้น
const dailyQuestRotationStore = new Map();
// `${address}|${dateStr}` -> Set ของ questId ที่ทำสำเร็จแล้ว
const dailyQuestCompletionStore = new Map();

function todayDateStr() {
  return new Date().toISOString().slice(0, 10);
}

// seeded shuffle แบบง่าย (LCG) เพื่อให้ผู้ใช้ทุกคนเห็นชุด quest เดียวกันในวันเดียวกัน
// แต่สลับสับเปลี่ยนไปทุกวันอย่างคาดเดาไม่ได้ล่วงหน้า
function seededShuffle(array, seedStr) {
  let seed = 0;
  for (let i = 0; i < seedStr.length; i++) seed = (seed * 31 + seedStr.charCodeAt(i)) >>> 0;
  const rand = () => {
    seed = (seed * 1103515245 + 12345) >>> 0;
    return seed / 0xffffffff;
  };
  const result = [...array];
  for (let i = result.length - 1; i > 0; i--) {
    const j = Math.floor(rand() * (i + 1));
    [result[i], result[j]] = [result[j], result[i]];
  }
  return result;
}

function generateDailyQuestSet(dateStr) {
  const chosen = seededShuffle(QUEST_POOL, dateStr).slice(0, QUESTS_PER_DAY);
  dailyQuestRotationStore.set(dateStr, chosen);
  console.log(`🎲 [Daily Quest] สุ่มภารกิจวันที่ ${dateStr}:`, chosen.map((q) => q.id).join(", "));
  return chosen;
}

function getTodayQuestSet() {
  const dateStr = todayDateStr();
  return dailyQuestRotationStore.get(dateStr) || generateDailyQuestSet(dateStr);
}

function markQuestComplete(address, dateStr, questId) {
  const key = `${address}|${dateStr}`;
  const set = dailyQuestCompletionStore.get(key) || new Set();
  set.add(questId);
  dailyQuestCompletionStore.set(key, set);
}

function isQuestComplete(address, dateStr, questId) {
  const set = dailyQuestCompletionStore.get(`${address}|${dateStr}`);
  return set ? set.has(questId) : false;
}

// เรียกจากทุก endpoint ที่ log quest event แบบ "confirmed" แล้ว (create-relic,
// ritual-of-growth/confirm, send-blessing/confirm) เพื่อเช็คว่ามันตรงกับภารกิจ
// auto ของวันนี้ไหม ถ้าใช่ ติ๊กถูกให้ทันทีโดยผู้ใช้ไม่ต้องทำอะไรเพิ่ม
function autoCompleteDailyQuest(address, actionType) {
  const dateStr = todayDateStr();
  const todaysQuests = getTodayQuestSet();
  const matched = todaysQuests.find((q) => q.mode === "auto" && q.actionType === actionType);
  if (matched) {
    markQuestComplete(address, dateStr, matched.id);
    console.log(`✅ [Daily Quest] ${address} ทำภารกิจ "${matched.id}" สำเร็จอัตโนมัติ`);
  }
}

// ตั้ง cron ให้สุ่มภารกิจใหม่ทุกเที่ยงคืน (เวลาเครื่อง server)
cron.schedule("0 0 * * *", () => {
  generateDailyQuestSet(todayDateStr());
});
// สุ่มไว้ล่วงหน้าตอน server เริ่มทำงาน เผื่อยังไม่มีชุดของวันนี้ (เช่นหลัง restart)
getTodayQuestSet();

// GET รายการภารกิจวันนี้ (ไม่ผูก address -> ไม่มีสถานะสำเร็จ)
app.get("/api/magic/daily-quest", (req, res) => {
  const quests = getTodayQuestSet();
  res.json(magicResponse("daily-quest", { quests, date: todayDateStr() }));
});

// GET รายการภารกิจวันนี้ + สถานะสำเร็จของ address นี้
app.get("/api/magic/daily-quest/:address", (req, res) => {
  const { address } = req.params;
  const dateStr = todayDateStr();
  const quests = getTodayQuestSet().map((q) => ({
    ...q,
    completed: isQuestComplete(address, dateStr, q.id),
  }));
  const completedCount = quests.filter((q) => q.completed).length;

  res.json(
    magicResponse("daily-quest", {
      date: dateStr,
      quests,
      completedCount,
      totalCount: quests.length,
      allComplete: completedCount === quests.length,
    })
  );
});

// ยืนยันภารกิจแบบ manual (เช่น เข้าไปดู Realm Vision แล้ว, เช็ค RPC แล้ว)
app.post("/api/magic/daily-quest/confirm", (req, res) => {
  const { address, questId } = req.body;
  if (!address || !questId) return res.status(400).json({ error: "ต้องระบุ address และ questId" });

  const dateStr = todayDateStr();
  const todaysQuests = getTodayQuestSet();
  const quest = todaysQuests.find((q) => q.id === questId);

  if (!quest) {
    return res.status(400).json({ error: "ภารกิจนี้ไม่ได้อยู่ในชุดภารกิจของวันนี้" });
  }
  if (quest.mode !== "manual") {
    return res.status(400).json({ error: "ภารกิจนี้เช็คสำเร็จอัตโนมัติอยู่แล้ว ไม่ต้องยืนยันเอง" });
  }

  markQuestComplete(address, dateStr, questId);
  res.json(
    magicResponse("daily-quest-confirmed", { address, questId, date: dateStr }, {
      message: `✅ ภารกิจ "${quest.label}" สำเร็จแล้ว!`,
    })
  );
});

// ---------------------------------------------------------------------------
// 8) MAGIC HALL — รวมทุกอย่างเป็นหน้าโปรไฟล์นักผจญภัย
// ---------------------------------------------------------------------------
app.get("/api/magic/hall/:address", async (req, res) => {
  const { address } = req.params;
  const badges = achievementStore.get(address) || [];

  const getRealmVision = mockOrReal(
    () => ({ adventurers: [{ address, relicsHeld: badges.filter((b) => b.id === "relic_creator").length }] }),
    async () => {
      throw new Error("not implemented");
    }
  );
  const vision = await getRealmVision();

  const dateStr = todayDateStr();
  const dailyQuests = getTodayQuestSet().map((q) => ({
    ...q,
    completed: isQuestComplete(address, dateStr, q.id),
  }));

  res.json(
    magicResponse("magic-hall", {
      address,
      badgeCollection: badges,
      dailyQuests,
      realmVision: vision,
      questLog: getQuestSummary(address),
      title: "หน้าโปรไฟล์การผจญภัยบน MeeChain",
    })
  );
});

app.get("/", (req, res) => {
  res.json({ status: "MeeChain API OK", chainId: CHAIN_ID });
});
// ---------------------------------------------------------------------------
// Health check + fallback 404 (ตาม pattern เดิมของ server.js หลัก)
// ---------------------------------------------------------------------------
app.get("/health", (req, res) => {
  res.json({ status: "ok", mock: MOCK_MODE, chainId: CHAIN_ID, service: "meechain-magic-layer" });
});

app.use((req, res) => {
  res.status(404).json({ error: "เส้นทางนี้ยังไม่มีพิธีกรรมรองรับ (route not found)" });
});


app.listen(PORT, () => {
  console.log(`🪄 MeeChain Magic Layer listening on port ${PORT} (mock mode: ${MOCK_MODE})`);
});

module.exports = app;
