// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @title BEP20Token
 * @dev BEP-20 token with optional Anti-Bot, Anti-Whale, and Burnable features.
 * Optimized for BSC 3-second block times and PancakeSwap V3.
 * Anti-Bot includes a self-destructing blacklist that expires after 50 blocks (~2.5 mins).
 */
contract BEP20Token is ERC20, ERC20Burnable, Ownable {
    uint8 private _decimals;
    
    // Feature Flags (Set at deployment)
    bool public antiBotEnabled;
    bool public antiWhaleEnabled;
    bool public airdropEnabled;
    
    // Anti-Bot: Temporary Blacklist functionality
    // This logic "self-destructs" after antiBotExpiry blocks to maintain contract trust scores.
    mapping(address => bool) public isBlacklisted;
    uint256 public antiBotExpiry;
    
    // Anti-Whale: Transaction and wallet limits
    uint256 public maxTransactionAmount;
    uint256 public maxWalletAmount;
    
    // Events
    event AddressBlacklisted(address indexed account, bool isBlacklisted);
    event LimitsUpdated(uint256 maxTransaction, uint256 maxWallet);
    event AntiBotToggled(bool enabled);
    event AntiWhaleToggled(bool enabled);

    /**
     * @dev Constructor
     * @param name_ Token name
     * @param symbol_ Token symbol  
     * @param decimals_ Token decimals
     * @param initialSupply_ Total supply
     * @param tokenOwner_ Address that will own the token
     * @param _antiBot Enable Anti-Bot protection
     * @param _antiWhale Enable Anti-Whale limits
     * @param _airdrop Enable Airdrop suite access
     */
    constructor(
        string memory name_,
        string memory symbol_,
        uint8 decimals_,
        uint256 initialSupply_,
        address tokenOwner_,
        bool _antiBot,
        bool _antiWhale,
        bool _airdrop
    ) ERC20(name_, symbol_) Ownable(tokenOwner_) {
        require(tokenOwner_ != address(0), "Owner cannot be zero address");
        
        _decimals = decimals_;
        antiBotEnabled = _antiBot;
        antiWhaleEnabled = _antiWhale;
        airdropEnabled = _airdrop;

        if (_antiBot) {
            antiBotExpiry = block.number + 50; // Self-destruct logic for scanners
        }
        
        uint256 totalSupply_ = initialSupply_ * (10 ** uint256(decimals_));
        _mint(tokenOwner_, totalSupply_);
        
        if (_antiWhale) {
            maxTransactionAmount = totalSupply_ / 100; // 1% max tx
            maxWalletAmount = totalSupply_ / 50;       // 2% max wallet
        }
    }

    function decimals() public view virtual override returns (uint8) {
        return _decimals;
    }

    // =========================================================================
    // Anti-Bot Functions (Self-Destructing after 50 blocks)
    // =========================================================================

    function setBlacklisted(address account, bool blacklisted) external onlyOwner {
        require(antiBotEnabled, "Anti-Bot not enabled");
        require(block.number < antiBotExpiry, "Anti-Bot protection period expired");
        require(account != owner(), "Cannot blacklist owner");
        isBlacklisted[account] = blacklisted;
        emit AddressBlacklisted(account, blacklisted);
    }

    function setBlacklistedBatch(address[] calldata accounts, bool blacklisted) external onlyOwner {
        require(antiBotEnabled, "Anti-Bot not enabled");
        require(block.number < antiBotExpiry, "Anti-Bot protection period expired");
        for (uint256 i = 0; i < accounts.length; i++) {
            if (accounts[i] != owner()) {
                isBlacklisted[accounts[i]] = blacklisted;
                emit AddressBlacklisted(accounts[i], blacklisted);
            }
        }
    }

    function disableAntiBot() external onlyOwner {
        require(antiBotEnabled, "Already disabled");
        antiBotEnabled = false;
        emit AntiBotToggled(false);
    }

    // =========================================================================
    // Anti-Whale Functions
    // =========================================================================

    function setLimits(uint256 _maxTransaction, uint256 _maxWallet) external onlyOwner {
        require(antiWhaleEnabled, "Anti-Whale not enabled");
        require(_maxTransaction > 0 && _maxWallet > 0, "Limits must be > 0");
        maxTransactionAmount = _maxTransaction;
        maxWalletAmount = _maxWallet;
        emit LimitsUpdated(_maxTransaction, _maxWallet);
    }

    function disableAntiWhale() external onlyOwner {
        require(antiWhaleEnabled, "Already disabled");
        antiWhaleEnabled = false;
        maxTransactionAmount = 0;
        maxWalletAmount = 0;
        emit AntiWhaleToggled(false);
    }

    /**
     * @dev Override _update to enforce Anti-Bot and Anti-Whale rules
     */
    function _update(address from, address to, uint256 value) internal virtual override {
        // Anti-Bot logic automatically stops working after antiBotExpiry block
        if (antiBotEnabled && block.number < antiBotExpiry) {
            require(!isBlacklisted[from], "Address is blacklisted in launch phase");
            require(!isBlacklisted[to], "Address is blacklisted in launch phase");
        }

        if (antiWhaleEnabled && from != address(0) && to != address(0)) {
            if (from != owner() && to != owner()) {
                require(value <= maxTransactionAmount, "Exceeds max transaction");
                if (to != address(0)) {
                    require(
                        balanceOf(to) + value <= maxWalletAmount,
                        "Exceeds max wallet"
                    );
                }
            }
        }

        super._update(from, to, value);
    }
}
