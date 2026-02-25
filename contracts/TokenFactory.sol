// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./BEP20Token.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/**
 * @title TokenFactory
 * @dev Factory contract for deploying BEP-20 tokens with configurable fees.
 * Users call createToken directly and pay fees to the contract.
 * Admin can update fees and withdraw collected fees.
 */
contract TokenFactory is Ownable, ReentrancyGuard, Pausable {
    // Fee configuration (in wei)
    // Flat fee model: one price includes all features
    uint256 public baseFee;

    // Whitelist for free launches
    mapping(address => bool) public isWhitelisted;

    // MINT Token Integration (for discounts)
    address public mintToken;
    uint256 public discountThreshold; // Minimum MINT to hold for discount
    uint256 public discountPercentage; // e.g., 20 for 20% discount

    // Statistics
    uint256 public totalTokensCreated;
    uint256 public totalFeesCollected;

    // Events
    event WhitelistUpdated(address indexed user, bool status);
    event TokenCreated(
        address indexed tokenAddress,
        address indexed creator,
        string name,
        string symbol,
        uint256 totalSupply,
        uint256 feePaid
    );
    event FeesUpdated(
        uint256 baseFee,
        uint256 antiBotFee,
        uint256 antiWhaleFee,
        uint256 airdropFee
    );
    event FeesWithdrawn(address indexed to, uint256 amount);
    event DiscountConfigUpdated(address indexed mintToken, uint256 threshold, uint256 percentage);

    /**
     * @dev Constructor - sets initial flat fee
     * @param _baseFee Flat fee for token creation - includes all features (in wei)
     * @param _mintToken Address of MINT token for holder discounts
     */
    constructor(uint256 _baseFee, address _mintToken) Ownable(msg.sender) {
        baseFee = _baseFee;
        mintToken = _mintToken;
        // All features included in flat base fee
    }

    /**
     * @dev Calculate the total fee required for token creation
     * Flat fee model: all features included in base price
     * @param antiBot Ignored - kept for interface compatibility
     * @param antiWhale Ignored - kept for interface compatibility
     * @param airdrop Ignored - kept for interface compatibility
     * @param user Address to check for whitelist/discount eligibility
     * @return Total fee required in wei
     */
    function calculateFee(
        bool antiBot,
        bool antiWhale,
        bool airdrop,
        address user
    ) public view returns (uint256) {
        if (isWhitelisted[user]) return 0;
        
        // Flat fee - all features included
        uint256 totalFee = baseFee;

        // Apply MINT holder discount if configured
        if (mintToken != address(0) && discountPercentage > 0) {
            try IERC20(mintToken).balanceOf(user) returns (uint256 balance) {
                if (balance >= discountThreshold) {
                    totalFee = (totalFee * (100 - discountPercentage)) / 100;
                }
            } catch {}
        }

        return totalFee;
    }

    /**
     * @dev Get all current fee values
     * Flat fee model: only base fee is used, feature fees are always 0
     * @return base Flat deployment fee (includes all features)
     * @return antiBot Always 0 (included in base)
     * @return antiWhale Always 0 (included in base)
     * @return airdrop Always 0 (included in base)
     */
    function getFees() external view returns (
        uint256 base,
        uint256 antiBot,
        uint256 antiWhale,
        uint256 airdrop
    ) {
        // All features included in base price
        return (baseFee, 0, 0, 0);
   }

    /**
     * @dev Create a new BEP-20 token
     * @param name Token name
     * @param symbol Token symbol
     * @param decimals Token decimals
     * @param initialSupply Initial supply (before decimals multiplication)
     * @param antiBot Enable Anti-Bot protection
     * @param antiWhale Enable Anti-Whale limits
     * @param airdrop Enable Airdrop functionality
     * @return tokenAddress Address of the deployed token
     */
    function createToken(
        string memory name,
        string memory symbol,
        uint8 decimals,
        uint256 initialSupply,
        bool antiBot,
        bool antiWhale,
        bool airdrop
    ) external payable nonReentrant whenNotPaused returns (address tokenAddress) {
        // Input validation
        require(bytes(name).length > 0, "TokenFactory: Name cannot be empty");
        require(bytes(name).length <= 50, "TokenFactory: Name too long");
        require(bytes(symbol).length > 0, "TokenFactory: Symbol cannot be empty");
        require(bytes(symbol).length <= 10, "TokenFactory: Symbol too long");
        require(decimals >= 6 && decimals <= 18, "TokenFactory: Decimals must be 6-18");
        require(initialSupply > 0, "TokenFactory: Supply must be greater than 0");
        
        // Calculate required fee
        uint256 requiredFee = calculateFee(antiBot, antiWhale, airdrop, msg.sender);
        require(msg.value >= requiredFee, "TokenFactory: Insufficient fee");

        // Deploy the token with msg.sender as owner
        BEP20Token token = new BEP20Token(
            name,
            symbol,
            decimals,
            initialSupply,
            msg.sender,  // Token owner is the caller
            antiBot,
            antiWhale,
            airdrop
        );

        tokenAddress = address(token);

        // Update statistics
        totalTokensCreated++;
        totalFeesCollected += requiredFee;

        // Emit event
        emit TokenCreated(
            tokenAddress,
            msg.sender,
            name,
            symbol,
            initialSupply * (10 ** uint256(decimals)),
            requiredFee
        );

        // Refund excess payment
        if (msg.value > requiredFee) {
            uint256 refund = msg.value - requiredFee;
            (bool success, ) = payable(msg.sender).call{value: refund}("");
            require(success, "TokenFactory: Refund failed");
        }

        return tokenAddress;
    }

    /**
     * @dev Update flat fee (onlyOwner)
     * Simple version for flat pricing model
     * @param _baseFee New flat fee for all tokens
     */
    function setBaseFee(uint256 _baseFee) external onlyOwner {
        baseFee = _baseFee;
        emit FeesUpdated(_baseFee, 0, 0, 0);
    }

    /**
     * @dev Update fee configuration (onlyOwner)
     * Legacy function for compatibility - only uses base fee
     * Feature fees are ignored (flat pricing model)
     * @param _baseFee New flat fee
     * @param _antiBotFee Ignored (kept for compatibility)
     * @param _antiWhaleFee Ignored (kept for compatibility)
     * @param _airdropFee Ignored (kept for compatibility)
     */
    function setFees(
        uint256 _baseFee,
        uint256 _antiBotFee,
        uint256 _antiWhaleFee,
        uint256 _airdropFee
    ) external onlyOwner {
        // Only use base fee - feature fees ignored
        baseFee = _baseFee;
        emit FeesUpdated(_baseFee, 0, 0, 0);
    }

    /**
     * @dev Update whitelist status (onlyOwner)
     * @param user Address of the user
     * @param status Whitelist status
     */
    function setWhitelist(address user, bool status) external onlyOwner {
        isWhitelisted[user] = status;
        emit WhitelistUpdated(user, status);
    }

    /**
     * @dev Set MINT token discount parameters (onlyOwner)
     * @param _mintToken Address of the MINT token
     * @param _threshold Minimum tokens to hold
     * @param _percentage Discount percentage (0-100)
     */
    function setDiscountConfig(
        address _mintToken,
        uint256 _threshold,
        uint256 _percentage
    ) external onlyOwner {
        require(_percentage <= 100, "TokenFactory: Invalid percentage");
        mintToken = _mintToken;
        discountThreshold = _threshold;
        discountPercentage = _percentage;
        emit DiscountConfigUpdated(_mintToken, _threshold, _percentage);
    }

    /**
     * @dev Withdraw collected fees to owner (onlyOwner)
     */
    function withdraw() external onlyOwner {
        uint256 balance = address(this).balance;
        require(balance > 0, "TokenFactory: No balance to withdraw");
        
        (bool success, ) = payable(owner()).call{value: balance}("");
        require(success, "TokenFactory: Withdraw failed");
        
        emit FeesWithdrawn(owner(), balance);
    }

    /**
     * @dev Withdraw collected fees to specific address (onlyOwner)
     * @param to Address to send fees to
     */
    function withdrawTo(address payable to) external onlyOwner {
        require(to != address(0), "TokenFactory: Invalid address");
        uint256 balance = address(this).balance;
        require(balance > 0, "TokenFactory: No balance to withdraw");
        
        (bool success, ) = to.call{value: balance}("");
        require(success, "TokenFactory: Withdraw failed");
        
        emit FeesWithdrawn(to, balance);
    }

    /**
     * @dev Get contract balance (collected fees)
     */
    function getBalance() external view returns (uint256) {
        return address(this).balance;
    }

    /**
     * @dev Pause token creation (emergency stop)
     * Only callable by owner
     */
    function pause() external onlyOwner {
        _pause();
    }

    /**
     * @dev Resume token creation
     * Only callable by owner
     */
    function unpause() external onlyOwner {
        _unpause();
    }
}
