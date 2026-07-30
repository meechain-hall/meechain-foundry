// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

/**
 * @title QuestSystem
 * @dev Complete quest and gamification system for MeeChain Magic Hall
 * 
 * Features:
 * - Quest creation and completion
 * - XP earning and level progression
 * - Achievement badges (NFT)
 * - Leaderboard integration
 * - Reward distribution
 */
contract QuestSystem is Ownable, Pausable, ERC721 {
    
    // ============================================================
    // Structures
    // ============================================================
    
    enum Difficulty { Easy, Medium, Hard, Expert, Legendary }
    
    struct Quest {
        uint256 id;
        string title;
        string description;
        uint256 xpReward;
        uint256 tokenReward;
        Difficulty difficulty;
        bool active;
        uint256 createdAt;
        uint256 maxCompletions; // 0 = unlimited
        uint256 currentCompletions;
    }
    
    struct UserStats {
        uint256 totalXP;
        uint256 currentLevel;
        uint256 questsCompleted;
        uint256 badgesEarned;
        uint256 lastQuestTime;
        bool isActive;
    }
    
    struct Achievement {
        uint256 id;
        string name;
        string description;
        uint256 xpRequired;
        bool active;
    }
    
    // ============================================================
    // State Variables
    // ============================================================
    
    Quest[] public quests;
    Achievement[] public achievements;
    
    mapping(address => UserStats) public userStats;
    mapping(address => mapping(uint256 => bool)) public userCompletedQuests;
    mapping(address => mapping(uint256 => bool)) public userEarnedAchievements;
    
    uint256 private tokenIdCounter;
    
    // Leaderboard
    address[] public leaderboard;
    mapping(address => uint256) public leaderboardIndex;
    
    // ============================================================
    // Events
    // ============================================================
    
    event QuestCreated(uint256 indexed questId, string title, uint256 xpReward);
    event QuestCompleted(address indexed user, uint256 indexed questId, uint256 xpGained);
    event LevelUp(address indexed user, uint256 newLevel);
    event AchievementUnlocked(address indexed user, uint256 indexed achievementId, string achievementName);
    event BadgeMinted(address indexed user, uint256 indexed tokenId, uint256 level);
    event LeaderboardUpdated(address indexed user, uint256 rank);
    
    // ============================================================
    // Constructor
    // ============================================================
    
    constructor() ERC721("MeeChain Quest Badge", "MQB") {
        tokenIdCounter = 1;
        _initializeAchievements();
    }
    
    // ============================================================
    // Quest Management (Admin)
    // ============================================================
    
    /**
     * @dev Create a new quest
     */
    function createQuest(
        string memory title,
        string memory description,
        uint256 xpReward,
        uint256 tokenReward,
        Difficulty difficulty,
        uint256 maxCompletions
    ) external onlyOwner {
        quests.push(Quest({
            id: quests.length,
            title: title,
            description: description,
            xpReward: xpReward,
            tokenReward: tokenReward,
            difficulty: difficulty,
            active: true,
            createdAt: block.timestamp,
            maxCompletions: maxCompletions,
            currentCompletions: 0
        }));
        
        emit QuestCreated(quests.length - 1, title, xpReward);
    }
    
    /**
     * @dev Deactivate a quest
     */
    function deactivateQuest(uint256 questId) external onlyOwner {
        require(questId < quests.length, "Quest not found");
        quests[questId].active = false;
    }
    
    // ============================================================
    // Quest Completion
    // ============================================================
    
    /**
     * @dev User completes a quest
     * Note: In production, this would be called by an oracle or verified by another contract
     */
    function completeQuest(uint256 questId) external whenNotPaused {
        require(questId < quests.length, "Quest not found");
        
        Quest storage quest = quests[questId];
        UserStats storage stats = userStats[msg.sender];
        
        require(quest.active, "Quest not active");
        require(!userCompletedQuests[msg.sender][questId], "Already completed");
        require(quest.maxCompletions == 0 || quest.currentCompletions < quest.maxCompletions, "Quest limit reached");
        
        // Mark completed
        userCompletedQuests[msg.sender][questId] = true;
        quest.currentCompletions++;
        
        // Award XP
        uint256 oldLevel = stats.currentLevel;
        stats.totalXP += quest.xpReward;
        stats.currentLevel = calculateLevel(stats.totalXP);
        stats.questsCompleted++;
        stats.lastQuestTime = block.timestamp;
        stats.isActive = true;
        
        emit QuestCompleted(msg.sender, questId, quest.xpReward);
        
        // Check for level up
        if (stats.currentLevel > oldLevel) {
            emit LevelUp(msg.sender, stats.currentLevel);
            _mintBadge(msg.sender, stats.currentLevel);
        }
        
        // Check for achievements
        _checkAchievements(msg.sender);
        
        // Update leaderboard
        _updateLeaderboard(msg.sender);
    }
    
    // ============================================================
    // Level & XP System
    // ============================================================
    
    /**
     * @dev Calculate level based on XP
     * Level 1: 0-999 XP
     * Level 2: 1,000-4,999 XP
     * Level 3: 5,000-14,999 XP
     * Level 4: 15,000-49,999 XP
     * Level 5: 50,000+ XP (Master)
     */
    function calculateLevel(uint256 xp) public pure returns (uint256) {
        if (xp >= 50000) return 5;
        if (xp >= 15000) return 4;
        if (xp >= 5000) return 3;
        if (xp >= 1000) return 2;
        return 1;
    }
    
    /**
     * @dev Get XP required for next level
     */
    function getXpForNextLevel(uint256 currentLevel) public pure returns (uint256) {
        if (currentLevel == 1) return 1000;
        if (currentLevel == 2) return 5000;
        if (currentLevel == 3) return 15000;
        if (currentLevel == 4) return 50000;
        return type(uint256).max; // Max level reached
    }
    
    /**
     * @dev Get progress to next level
     */
    function getProgressToNextLevel(address user) external view returns (uint256 current, uint256 next, uint256 percent) {
        UserStats memory stats = userStats[user];
        uint256 nextRequired = getXpForNextLevel(stats.currentLevel);
        
        if (nextRequired == type(uint256).max) {
            return (stats.totalXP, type(uint256).max, 100);
        }
        
        uint256 currentRequired = getXpForNextLevel(stats.currentLevel - 1);
        uint256 progressInLevel = stats.totalXP - currentRequired;
        uint256 xpNeeded = nextRequired - currentRequired;
        
        return (
            progressInLevel,
            xpNeeded,
            (progressInLevel * 100) / xpNeeded
        );
    }
    
    // ============================================================
    // Achievement System
    // ============================================================
    
    /**
     * @dev Initialize predefined achievements
     */
    function _initializeAchievements() private {
        achievements.push(Achievement({
            id: 0,
            name: "First Quest",
            description: "Complete your first quest",
            xpRequired: 100,
            active: true
        }));
        
        achievements.push(Achievement({
            id: 1,
            name: "Quest Master",
            description: "Complete 10 quests",
            xpRequired: 1000,
            active: true
        }));
        
        achievements.push(Achievement({
            id: 2,
            name: "Level 2 Reached",
            description: "Reach level 2",
            xpRequired: 1000,
            active: true
        }));
        
        achievements.push(Achievement({
            id: 3,
            name: "Level 3 Master",
            description: "Reach level 3",
            xpRequired: 5000,
            active: true
        }));
    }
    
    /**
     * @dev Check and award achievements
     */
    function _checkAchievements(address user) private {
        UserStats memory stats = userStats[user];
        
        for (uint256 i = 0; i < achievements.length; i++) {
            if (achievements[i].active && !userEarnedAchievements[user][i]) {
                if (stats.totalXP >= achievements[i].xpRequired) {
                    userEarnedAchievements[user][i] = true;
                    emit AchievementUnlocked(user, i, achievements[i].name);
                }
            }
        }
    }
    
    // ============================================================
    // Badge System (NFT)
    // ============================================================
    
    /**
     * @dev Mint badge NFT for level up
     */
    function _mintBadge(address user, uint256 level) private {
        uint256 tokenId = tokenIdCounter;
        tokenIdCounter++;
        
        _safeMint(user, tokenId);
        emit BadgeMinted(user, tokenId, level);
    }
    
    /**
     * @dev Get badge URI for level
     */
    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        require(ownerOf(tokenId) != address(0), "Badge not found");
        
        // Return IPFS URL or base64 encoded metadata
        return string(abi.encodePacked(
            "ipfs://QmXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX/",
            Strings.toString(tokenId),
            ".json"
        ));
    }
    
    // ============================================================
    // Leaderboard
    // ============================================================
    
    /**
     * @dev Update leaderboard position
     */
    function _updateLeaderboard(address user) private {
        UserStats memory stats = userStats[user];
        
        if (leaderboardIndex[user] == 0) {
            // New user, add to leaderboard
            leaderboard.push(user);
            leaderboardIndex[user] = leaderboard.length;
        }
        
        // Sort leaderboard (simple bubble sort for small lists)
        uint256 userPos = leaderboardIndex[user] - 1;
        
        // Bubble up if needed
        while (userPos > 0) {
            address currentUser = leaderboard[userPos];
            address prevUser = leaderboard[userPos - 1];
            
            if (userStats[currentUser].totalXP > userStats[prevUser].totalXP) {
                // Swap
                leaderboard[userPos] = prevUser;
                leaderboard[userPos - 1] = currentUser;
                leaderboardIndex[prevUser] = userPos + 1;
                leaderboardIndex[currentUser] = userPos;
                userPos--;
            } else {
                break;
            }
        }
        
        emit LeaderboardUpdated(user, userPos + 1);
    }
    
    /**
     * @dev Get leaderboard (top 100)
     */
    function getLeaderboard(uint256 limit) external view returns (
        address[] memory users,
        uint256[] memory xpValues
    ) {
        uint256 count = limit < leaderboard.length ? limit : leaderboard.length;
        users = new address[](count);
        xpValues = new uint256[](count);
        
        for (uint256 i = 0; i < count; i++) {
            users[i] = leaderboard[i];
            xpValues[i] = userStats[leaderboard[i]].totalXP;
        }
        
        return (users, xpValues);
    }
    
    // ============================================================
    // Query Functions
    // ============================================================
    
    /**
     * @dev Get user statistics
     */
    function getUserStats(address user) external view returns (
        uint256 totalXP,
        uint256 currentLevel,
        uint256 questsCompleted,
        uint256 badgesEarned,
        uint256 leaderboardRank
    ) {
        UserStats memory stats = userStats[user];
        return (
            stats.totalXP,
            stats.currentLevel,
            stats.questsCompleted,
            balanceOf(user),
            leaderboardIndex[user]
        );
    }
    
    /**
     * @dev Get quest details
     */
    function getQuest(uint256 questId) external view returns (Quest memory) {
        require(questId < quests.length, "Quest not found");
        return quests[questId];
    }
    
    /**
     * @dev Get all active quests
     */
    function getActiveQuests() external view returns (Quest[] memory) {
        uint256 activeCount = 0;
        for (uint256 i = 0; i < quests.length; i++) {
            if (quests[i].active) activeCount++;
        }
        
        Quest[] memory active = new Quest[](activeCount);
        uint256 index = 0;
        for (uint256 i = 0; i < quests.length; i++) {
            if (quests[i].active) {
                active[index] = quests[i];
                index++;
            }
        }
        
        return active;
    }
    
    /**
     * @dev Check if user completed quest
     */
    function hasCompletedQuest(address user, uint256 questId) external view returns (bool) {
        return userCompletedQuests[user][questId];
    }
    
    /**
     * @dev Get total quests count
     */
    function getQuestsCount() external view returns (uint256) {
        return quests.length;
    }
    
    /**
     * @dev Get achievements count
     */
    function getAchievementsCount() external view returns (uint256) {
        return achievements.length;
    }

    // ============================================================
    // Admin Functions
    // ============================================================

    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }
}

