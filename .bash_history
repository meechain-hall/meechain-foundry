ls
la
curl -X POST http://127.0.0.1:8545   -H "Content-Type: application/json"   --data '{"jsonrpc":"2.0","method":"eth_blockNumber","params":[],"id":1}'
ingress:
curl https://meechain.live/health
cd /home/meechain/dashboard/build/meechain-magic-hall
# เขียน .env.production ใหม่ — ตัวแปรละ 1 บรรทัดเท่านั้น
cat > .env.production <<'EOF'
VITE_CHAIN_NAME=MeeChain
VITE_CHAIN_ID=13390
VITE_RPC_ENDPOINT=https://rpc-testnet.meechain.live
VITE_API_BASE_URL=https://dashboard.meechain.run.place
VITE_QUEST_SYSTEM_ADDRESS=0x3Aa5ebB10DC797CAC828524e59A333d0A371443c
EOF

npm run build
sudo systemctl reload nginx
curl -s https://rpc-testnet.meechain.live   -H 'Content-Type: application/json'   --data '{"jsonrpc":"2.0","method":"eth_blockNumber","params":[],"id":1}'
node -v
npm -v
npx hardhat compile
sudo apt install npm
sudo apt install nodejs
ls
sudo apt install nodejs
cd
ls
z
apt update
apt install python3-pip -y
pip install certbot
apt update
apt install python3-pip -y
pip install certbot
sudo apt install python3-pip
apt update
apt install python3-pip -y
pip install certbot
apt update
apt install certbot python3-certbot-nginx -y
which certbot
certbot --version
sudo apt install certbot
which certbot
certbot --version
systemctl status snapd
snap install core
snap refresh core
snap install certbot --classic
/snap/bin/certbot --version
/snap/bin/certbot certonly --webroot -w /var/www/html -d meechain.live
apt remove certbot -y
snap install core; snap refresh core
snap install certbot --classic
certbot --version
certbot certonly --webroot -w /var/www/html -d meechain.live
nginx -t
nginx -s reloadnginx -t
nginx -s reload
sudo apt install nginx-core
nginx -t
sudo nano /etc/nginx/nginx.conf
# Add cloudflare gpg key
sudo mkdir -p --mode=0755 /usr/share/keyrings
https://pkg.cloudflare.com/cloudflared
echo 'deb [signed-by=/usr/share/keyrings/cloudflare-main.gpg] https://pkg.cloudflare.com/cloudflared any main' | sudo tee /etc/apt/sources.list.d/cloudflared.list
sudo apt-get update && sudo apt-get install cloudflared
sudo cloudflared service install eyJhIjoiZjFjMDc3NjUzNTBiZjhmNGZlYzgxYzhjOWJmYjk4MDAiLCJ0IjoiODE5ZDM3OTgtZTg5MS00YTBiLTg1YWUtMDgxY2NjNGE1OGQ3IiwicyI6Ik9EVTFZalppTkRjdE4ySTVOQzAwTlRVMExXSXhOVGt0T1RWbE5qaG1NamczWlRBMCJ9
cloudflared tunnel run --token eyJhIjoiZjFjMDc3NjUzNTBiZjhmNGZlYzgxYzhjOWJmYjk4MDAiLCJ0IjoiODE5ZDM3OTgtZTg5MS00YTBiLTg1YWUtMDgxY2NjNGE1OGQ3IiwicyI6Ik9EVTFZalppTkRjdE4ySTVOQzAwTlRVMExXSXhOVGt0T1RWbE5qaG1NamczWlRBMCJ9
docker run cloudflare/cloudflared:latest tunnel --no-autoupdate run --token eyJhIjoiZjFjMDc3NjUzNTBiZjhmNGZlYzgxYzhjOWJmYjk4MDAiLCJ0IjoiODE5ZDM3OTgtZTg5MS00YTBiLTg1YWUtMDgxY2NjNGE1OGQ3IiwicyI6Ik9EVTFZalppTkRjdE4ySTVOQzAwTlRVMExXSXhOVGt0T1RWbE5qaG1NamczWlRBMCJ9
sudo apt install docker.io
sudo apt install podman-docker
docker run cloudflare/cloudflared:latest tunnel --no-autoupdate run --token eyJhIjoiZjFjMDc3NjUzNTBiZjhmNGZlYzgxYzhjOWJmYjk4MDAiLCJ0IjoiODE5ZDM3OTgtZTg5MS00YTBiLTg1YWUtMDgxY2NjNGE1OGQ3IiwicyI6Ik9EVTFZalppTkRjdE4ySTVOQzAwTlRVMExXSXhOVGt0T1RWbE5qaG1NamczWlRBMCJ9
cloudflared.exe service install eyJhIjoiZjFjMDc3NjUzNTBiZjhmNGZlYzgxYzhjOWJmYjk4MDAiLCJ0IjoiODE5ZDM3OTgtZTg5MS00YTBiLTg1YWUtMDgxY2NjNGE1OGQ3IiwicyI6Ik9EVTFZalppTkRjdE4ySTVOQzAwTlRVMExXSXhOVGt0T1RWbE5qaG1NamczWlRBMCJ9
mkdir -p /var/www/html/.well-known/acme-challenge
echo "hello-acme" > /var/www/html/.well-known/acme-challenge/test.txt
curl http://meechain.live/.well-known/acme-challenge/test.txt
nano /etc/nginx/sites-enabled/meechain.conf
nginx -t
nginx -s reload
mkdir -p /var/www/html/.well-known/acme-challenge
echo "hello-acme" > /var/www/html/.well-known/acme-challenge/test.txt
curl http://meechain.live/.well-known/acme-challenge/test.txt
apt install curl -y
curl -I http://localhost
sudo nano /etc/nginx/sites-enabled/meechain.conf
nginx -t
nginx -s reload
sudo nano /etc/nginx/sites-enabled/meechain.conf
nginx -t
mkdir -p /var/www/html/.well-known/acme-challenge
echo "hello-acme" > /var/www/html/.well-known/acme-challenge/test.txt
curl http://meechain.live/.well-known/acme-challenge/test.txt
sudo nginx -t
ls -ld /var/log/nginx
sudo chown root:adm /var/log/nginx

sudo chmod 755 /var/log/nginx
ls -ld /var/log/nginx
sudo nginx -t
sudo chown root:adm /var/log/nginx
sudo nano /etc/nginx/sites-enabled/meechain.conf
ps aux | grep geth
netstat -tulnp | grep 8545
sudo apt install net-tools
sudo tee /etc/systemd/system/meechain-node.service < /dev/null [Unit]
sudo systemctl daemon-reload
sudo systemctl disable --now geth-node.service
sudo nano /etc/systemd/system/meechain-node.service
sudo systemctl disable --now geth-node.service
sudo systemctl daemon-reload
sudo systemctl enable --now meechain-node.service
sudo systemctl status meechain-node --no-pager
ps aux | grep geth
netstat -tulnp | grep 8545
geth --http --http.addr 127.0.0.1 --http.port 8545 --http.api eth,net,web3
systemctl reload nginx
ls -l /home/meechain/.foundry/bin/anvil
curl -L https://foundry.paradigm.xyz | bash && ~/.foundry/bin/foundryup
anvil --chain-id 13390   --host 127.0.0.1 --port 8545   --block-time 5   --state /home/meechain/anvil-state.json
ls -l /home/meechain/.foundry/bin/anvil
sudo nano # ใน .env ของ /home/meechain/dashboard
sudo nano /home/meechain/dashboard
ls -l /home/meechain/.foundry/bin/anvil
chmod +x /home/meechain/.foundry/bin/anvil
/home/meechain/.foundry/bin/anvil --chain-id 13390 --host 127.0.0.1 --port 8545 --block-time 5
root@localhost:~# curl -X POST http://127.0.0.1:8545 >   -H "Content-Type: application/json" >   --data '{"jsonrpc":"2.0","method":"eth_blockNumber","params":[],"id":1}'
curl: (7) Failed to connect to 127.0.0.1 port 8545 after 1 ms: Couldn't connect to server
curl -X POST http://meechain.live   -H "Content-Type: application/json"   --data '{"jsonrpc":"2.0","method":"eth_blockNumber","params":[],"id":1}'
root@localhost:~# curl -X POST http://127.0.0.1:8545 >   -H "Content-Type: application/json" >   --data '{"jsonrpc":"2.0","method":"eth_blockNumber","params":[],"id":1}'
~/.local/bin/certbot certonly --webroot -w /var/www/html -d meechain.live
sudo ~/.local/bin/certbot certonly --webroot -w /var/www/html -d meechain.live
sudo nano  /etc/nginx/sites-enabled/meechain.conf
sudo certbot certonly --webroot -w /var/www/certbot -d api.meechain.live
sudo mkdir -p /var/www/certbot/.well-known/acme-challenge
sudo chown -R www-data:www-data /var/www/certbot
sudo chmod -R 755 /var/www/certbot
echo "hello-acme" | sudo tee /var/www/certbot/.well-known/acme-challenge/test.txt
curl http://api.meechain.live/.well-known/acme-challenge/test.txt
curl http://rpc.meechain.live/.well-known/acme-challenge/test.txt
sudo certbot certonly --webroot -w /var/www/certbot -d api.meechain.live
ls -l /var/www/certbot/.well-known/acme-challenge/test.txt
sudo mkdir -p /var/log/letsencrypt
ls -ld /etc/letsencrypt
sudo chown -R root:root /etc/letsencrypt
sudo nano  /etc/nginx/sites-enabled/meechain.conf
curl -I https://meechain.live
sudo nginx -t
sudo mkdir -p /var/www/certbot/.well-known/acme-challenge
echo "hello-acme" | sudo tee /var/www/certbot/.well-known/acme-challenge/test.txt
curl http://api.meechain.live/.well-known/acme-challenge/test.txt
curl http://rpc.meechain.live/.well-known/acme-challenge/test.txt
echo "hello-acme" | sudo tee /var/www/certbot/.well-known/acme-challenge/test.txt
curl http://api.meechain.live/.well-known/acme-challenge/test.txt
curl http://rpc.meechain.live/.well-known/acme-challenge/test.txt
echo "hello-acme" | sudo tee /var/www/certbot/.well-known/acme-challenge/test.txt
curl http://api.meechain.live/.well-known/acme-challenge/test.txt
curl http://rpc.meechain.live/.well-known/acme-challenge/test.txt
sudo nginx -t
sudo mkdir -p /var/www/certbot/.well-known/acme-challenge
sudo nginx -t
sudo nano  /etc/nginx/sites-enabled/meechain.conf
sudo mkdir -p /var/www/certbot/.well-known/acme-challenge
echo "hello-acme" | sudo tee /var/www/certbot/.well-known/acme-challenge/test.txt
sudo nginx -t
sudo nano /etc/nginx/nginx.conf
sudo nano  /etc/nginx/sites-enabled/meechain.conf
sudo nginx -t
sudo nano  /etc/nginx/sites-enabled/meechain.conf
sudo nginx -t
sudo nano  /etc/nginx/sites-enabled/meechain.conf
sudo nginx -t
sudo nano /etc/nginx/nginx.conf
sudo nano  /etc/nginx/sites-enabled/meechain.conf
sudo nginx -t
sudo nano  /etc/nginx/sites-enabled/meechain.conf
sudo nginx -t
sudo nano  /etc/nginx/sites-enabled/meechain.conf
sudo nginx -t
sudo nano  /etc/nginx/sites-enabled/meechain.conf
sudo nginx -t
sudo nano  /etc/nginx/sites-enabled/meechain.conf
sudo nginx -t
sudo nano  /etc/nginx/sites-enabled/meechain.conf
sudo nginx -t
meechain@VM1:~$ sudo nginx -t
nginx: [warn] "ssl_stapling" ignored, no OCSP responder URL in the certificate "/etc/letsencrypt/live/meechain.live/fullchain.pem"
nginx: the configuration file /etc/nginx/nginx.conf syntax is ok
nginx: configuration file /etc/nginx/nginx.conf test is successful
sudo nginx -t
curl -I https://meechain.live
curl -I https://api.meechain.live
curl -I https://rpc.meechain.live
curl -I https://meechain.live
curl -I https://api.meechain.live
curl -I https://rpc.meechain.live
sudo nginx -t
sudo systemctl status nginx
sudo certbot certonly --webroot -w /var/www/certbot -d api.meechain.live -d rpc.meechain.live
sudo ss -tulnp | grep nginx
sudo nano /etc/nginx/sites-enabled/meechain.conf
sudo nginx -t
sudo nano /etc/nginx/sites-enabled/meechain.conf
sudo nginx -t
sudo systemctl reload nginx
sudo ss -tulnp | grep 443
curl -I https://meechain.live
curl -I https://api.meechain.live
curl -I https://rpc.meechain.live
sudo certbot certonly --webroot -w /var/www/certbot   -d meechain.live -d api.meechain.live -d rpc.meechain.live
sudo nginx -t
sudo ss -tulnp | grep 443
curl -I https://meechain.live
curl -I https://api.meechain.live
curl -I https://rpc.meechain.live
sudo systemctl reload nginx
curl -I https://meechain.live
curl -I https://api.meechain.live
curl -I https://rpc.meechain.live
sudo ss -tulnp | grep 5000
sudo ss -tulnp | grep 8080
cd /path/to/api
npm start
sudo apt install npm
cd /path/to/api
sudo nano /etc/nginx/sites-enabled/meechain.conf
npm start
sudo chmod 755 /etc/letsencrypt/live/
sudo nano server.js
nade server.js
node server.js
npm init -y
curl -fsSL https://deb.nodesource.com/setup_18.x | sudo -E bash -
sudo apt install -y nodejs
sudo nano /etc/apt/sources.list.d/cloudflared.list
curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash -
sudo apt install -y nodejs
sudo apt remove -y libnode-dev
sudo apt remove -y nodejs
sudo apt install -y nodejs
node-v
node -v
npm -v
node server.js
npm install node-cron
npm install ethers@5
npm install cors
npm install express
npm audit fix --force
node server.js
mkdir -p home/meechain/meechain-api
cd /home/meechain/meechain-api
mkdir -p .github/workflows
cp /home/meechain/ci-meechain/deploy.yml .github/workflows/
ls
ls .github/workflows/
cd /home/meechain
git init   # ถ้ายังไม่ได้ init
git remote add origin <YOUR_GITHUB_REPO_URL>
git add .github/workflows/deploy.yml
git commit -m "Add CI/CD deploy workflow"
git push origin main
cd /home/meechain
git init   # ถ้ายังไม่ได้ init
git remote add origin https://github.com/MEECHAIN1/meechain-foundry
git add .github/workflows/deploy.yml
git commit -m "Add CI/CD deploy workflow"
git push origin main
git add .github/workflows/deploy.yml
git commit -m "Add CI/CD deploy workflow"
git push origin main
git branch
git branch -M main
git push -u origin main
git branch
git push -u origin main
git config --global credential.helper store
ls
cd dashboard
curl -X POST http://127.0.0.1:8545   -H "Content-Type: application/json"   --data '{"jsonrpc":"2.0","method":"eth_blockNumber","params":[],"id":1}'
curl -X POST http://127.0.0.1:8545   -H "Content-Type: application/json"   --data '{"jsonrpc":"2.0","method":"web3_clientVersion","params":[],"id":1}'
curl -X POST http://127.0.0.1:8545   -H "Content-Type: application/json"   --data '{"jsonrpc":"2.0","method":"eth_blockNumber","params":[],"id":1}'
curl -X POST https://rpc.meechain.live   -H "Content-Type: application/json"   --data '{"jsonrpc":"2.0","method":"eth_blockNumber","params":[],"id":1}'
curl -X POST https://rpc.meechain.live   -H "Content-Type: application/json"   --data '{"jsonrpc":"2.0","method":"eth_blockNumber","params":[],"id":1}'
sudo nano ethers.js
curl -X POST https://rpc.meechain.live   -H "Content-Type: application/json"   --data '{"jsonrpc":"2.0","method":"eth_blockNumber","params":[],"id":1}'
sudo nano ethers.js
curl -X POST https://rpc.meechain.live   -H "Content-Type: application/json"   --data '{"jsonrpc":"2.0","method":"eth_blockNumber","params":[],"id":1}'
sudo nano ethers.js
curl -X POST https://rpc.meechain.live   -H "Content-Type: application/json"   --data '{"jsonrpc":"2.0","method":"eth_blockNumber","params":[],"id":1}'
npm install ethers@5
npm audit fix
npm audit fix --force
ls
cat > meechain/src/MEEReward.sol << 'EOF'
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {ERC721} from "lib/openzeppelin-contracts/contracts/token/ERC721/ERC721.sol";
import {Ownable} from "lib/openzeppelin-contracts/contracts/access/Ownable.sol";

/**
 * @title MeeChain Reward Badge (Soulbound NFT)
 * @dev Dynamic NFT for Foundry + OZ v5
 */
contract MEEReward is ERC721, Ownable {
    uint256 private _tokenIdCounter = 0;

    struct Badge {
        uint256 tokenId;
        address owner;
        uint256 xp;
        uint256 level;
        uint256 mintedAt;
        bool isSoulbound;
    }

    mapping(uint256 => Badge) public badges;
    mapping(address => uint256) public userBadgeId;
    mapping(uint256 => string) public levelURIs;

    event BadgeMinted(address indexed to, uint256 indexed tokenId, uint256 level);
    event BadgeUpgraded(address indexed user, uint256 indexed tokenId, uint256 newLevel);
    event XPGained(address indexed user, uint256 indexed tokenId, uint256 xpAmount);
    event LevelURISet(uint256 level, string uri);

    constructor() ERC721("MeeChain Reward", "MEEBD") Ownable(msg.sender) {
        levelURIs[1] = "ipfs://meechain/badge/novice";
        levelURIs[2] = "ipfs://meechain/badge/elite";
        levelURIs[3] = "ipfs://meechain/badge/master";
    }

    function mintBadge(address to) public onlyOwner returns (uint256) {
        require(to != address(0), "Cannot mint to zero address");
        require(userBadgeId[to] == 0, "User already has a badge");

        uint256 tokenId = _tokenIdCounter;
        _tokenIdCounter++;

        _safeMint(to, tokenId);

        Badge memory newBadge = Badge({
            tokenId: tokenId,
            owner: to,
            xp: 0,
            level: 1,
            mintedAt: block.timestamp,
            isSoulbound: true
        });

        badges[tokenId] = newBadge;
        userBadgeId[to] = tokenId;

        emit BadgeMinted(to, tokenId, 1);
        return tokenId;
    }

    function addXP(address user, uint256 xpAmount) public onlyOwner {
        uint256 tokenId = userBadgeId[user];
        require(tokenId != 0, "Badge not found for user");

        Badge storage badge = badges[tokenId];
        badge.xp += xpAmount;

        emit XPGained(user, tokenId, xpAmount);

        uint256 newLevel = calculateLevel(badge.xp);
        if (newLevel > badge.level) {
            badge.level = newLevel;
            emit BadgeUpgraded(user, tokenId, newLevel);
        }
    }

    function calculateLevel(uint256 xp) public pure returns (uint256) {
        if (xp < 1000) return 1;
        if (xp < 5000) return 2;
        return 3;
    }

    function getBadge(uint256 tokenId) public view returns (Badge memory) {
        require(_ownerOf(tokenId) != address(0), "Badge does not exist");
        return badges[tokenId];
    }

    function getUserBadge(address user) public view returns (uint256) {
        return userBadgeId[user];
    }

    function getUserLevel(address user) public view returns (uint256) {
        uint256 tokenId = userBadgeId[user];
        require(tokenId != 0, "User has no badge");
        return badges[tokenId].level;
    }

    function getUserXP(address user) public view returns (uint256) {
        uint256 tokenId = userBadgeId[user];
        require(tokenId != 0, "User has no badge");
        return badges[tokenId].xp;
    }

    function setLevelURI(uint256 level, string memory uri) public onlyOwner {
        require(level >= 1 && level <= 3, "Invalid level");
        levelURIs[level] = uri;
        emit LevelURISet(level, uri);
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId,
        uint256 batchSize
    ) internal override {
        require(from == address(0) || to == address(0), "Soulbound: Transfer not allowed");
        super._beforeTokenTransfer(from, to, tokenId, batchSize);
    }

    function burnBadge(uint256 tokenId) public onlyOwner {
        require(_ownerOf(tokenId) != address(0), "Badge does not exist");
        address owner = ownerOf(tokenId);
        delete badges[tokenId];
        delete userBadgeId[owner];
        _burn(tokenId);
    }

    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        require(_ownerOf(tokenId) != address(0), "Badge does not exist");
        Badge memory badge = badges[tokenId];
        return levelURIs[badge.level];
    }

    function totalBadgesMinted() public view returns (uint256) {
        return _tokenIdCounter;
    }

    function badgeExists(uint256 tokenId) public view returns (bool) {
        return _ownerOf(tokenId) != address(0);
    }
}
EOF

sudo nano  /etc/nginx/sites-enabled/meechain.conf
sudo nginx -t
sudo nano  /etc/nginx/sites-enabled/meechain.conf
sudo nginx -t
sudo systemctl reload nginx
scp /storage/emulated/0/Download/ci-meechain.zip     meechain@4.155.210.21:/home/meechain/
ls
ls -lh /home/meechain/ci-meechain.zip
unzip /home/meechain/ci-meechain.zip -d /home/meechain/ci-meechain
sudo apt install unzip
unzip /home/meechain/ci-meechain.zip -d /home/meechain/ci-meechain
ls /home/meechain/ci-meechain
ls
sudo ss -tulnp | grep 8545
geth --http --http.port 8545 --http.api web3,eth,net
sudo nginx -t
sudo systemctl reload nginx
sudo systemctl status meechain-node
sudo systemctl reload nginx
sudo systemctl status meechain-node
sudo nano /etc/systemd/system/meechain-node.service
ls -l /usr/local/bin/geth
/home/meechain/.foundry/bin/anvil --versio
curl -L https://foundry.paradigm.xyz | bash
source ~/.bashrc
foundryup
sudo systemctl stop meechain-node
sudo systemctl status meechain-node
sudo nano /etc/systemd/system/meechain-node.service
sudo systemctl daemon-reload
sudo systemctl status meechain-node.service
sudo systemctl enable meechain-node.service
sudo systemctl restart meechain-node.service
sudo systemctl status meechain-node.service
sudo ss -tulnp | grep 8545
/home/meechain/.foundry/bin/anvil --chain-id 13390 --http-port 8545 --host 0.0.0.0
/home/meechain/.foundry/bin/anvil --help
/home/meechain/.foundry/bin/anvil 
sudo s ystemctl status meechain-node.service
sudo nano /etc/systemd/system/meechain-node.service
sudo s ystemctl status meechain-node.service
sudo systemctl daemon-reload
sudo systemctl enable meechain-node.service
sudo ss -tulnp | grep 8545
sudo systemctl restart meechain-node.service
sudo s ystemctl status meechain-node.service
ls
cd dashboard
nano /etc/systemd/system/meechain-node.service
nano nano /etc/systemd/system/meechain-node.service
sudo nano /etc/systemd/system/meechain-node.service
sudo systemctl daemon-reload
sudo systemctl enable meechain-node.service
sudo systemctl restart meechain-node.service
sudo systemctl status meechain-node.service
curl -I http://127.0.0.1:5000
nano server.js
sudo nano server.js
app.get("/", (req, res) => {
sudo nginx -t
sudo systemctl reload nginx
curl -I https://api.meechain.live
curl -I https://rpc.meechain.live
sudo nano  /etc/nginx/sites-enabled/meechain.conf
curl -I https://api.meechain.live
sudo nginx -t
sudo systemctl reload nginx
curl -I https://api.meechain.live
curl -I https://rpc.meechain.live
sudo ss -tulnp | grep 8545
geth --http --http.port 8545 --http.api web3,eth,net
sudo systemctl status nginx
