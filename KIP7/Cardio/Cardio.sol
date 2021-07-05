pragma solidity ^0.4.24;

/**
 * @dev SafeMath
 * Math operations with safety checks that throw on error
 * https://github.com/OpenZeppelin/zeppelin-solidity/blob/master/contracts/math/SafeMath.sol
 */
library SafeMath {
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        assert(c / a == b);
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b <= a);
        return a - b;
    }

    function safeSub(uint256 a, uint256 b) internal pure returns (uint256) {
        if (b > a) return 0;
        return a - b;
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        assert(c >= a);
        return c;
    }
}
/**
 * @dev Interface of the KIP-13 standard, as defined in the
 * [KIP-13](http://kips.klaytn.com/KIPs/kip-13-interface_query_standard).
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others.
 *
 * For an implementation, see `KIP13`.
 */
interface IKIP13 {
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}
/**
 * @dev Interface of the KIP7 standard as defined in the KIP. Does not include
 * the optional functions; to access them see `KIP7Metadata`.
 * See http://kips.klaytn.com/KIPs/kip-7-fungible_token
 */
contract IKIP7 is IKIP13 {
    function totalSupply() public view returns (uint256);
    function balanceOf(address account) public view returns (uint256);
    function decimals() public view returns (uint8);
    function transfer(address recipient, uint256 amount) public returns (bool);
    function allowance(address owner, address spender) public view returns (uint256);
    function approve(address spender, uint256 amount) public returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) public returns (bool);
    function safeTransfer(address recipient, uint256 amount, bytes memory data) public;
    function safeTransfer(address recipient, uint256 amount) public;
    function safeTransferFrom(address sender, address recipient, uint256 amount, bytes memory data) public;
    function safeTransferFrom(address sender, address recipient, uint256 amount) public;

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}
/**
 * @dev Implementation of the `IKIP13` interface.
 *
 * Contracts may inherit from this and call `_registerInterface` to declare
 * their support of an interface.
 */
contract KIP13 is IKIP13 {
    bytes4 private constant _INTERFACE_ID_KIP13 = 0x01ffc9a7;
    mapping(bytes4 => bool) private _supportedInterfaces;

    constructor () internal {
        _registerInterface(_INTERFACE_ID_KIP13);
    }

    function supportsInterface(bytes4 interfaceId) external view returns (bool) {
        return _supportedInterfaces[interfaceId];
    }

    function _registerInterface(bytes4 interfaceId) internal {
        require(interfaceId != 0xffffffff, "KIP13: invalid interface id");
        _supportedInterfaces[interfaceId] = true;
    }
}

contract IKIP7Receiver {
    function onKIP7Received(address _operator, address _from, uint256 _amount, bytes memory _data) public returns (bytes4);
}
// ----------------------------------------------------------------------------
// @title Ownable
// ----------------------------------------------------------------------------
contract Ownable {
    address public owner;
    address public operator;

    event SetOwner(address owner);
    event SetMinter(address minter);
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    event OperatorTransferred(address indexed previousOperator, address indexed newOperator);

    constructor() public {
        owner    = msg.sender;
        operator = msg.sender;

        emit SetOwner(msg.sender);
        emit SetMinter(msg.sender);
    }

    modifier onlyOwner() { require(msg.sender == owner); _; }
    modifier onlyOwnerOrOperator() { require(msg.sender == owner || msg.sender == operator); _; }

    function transferOwnership(address _newOwner) external onlyOwner {
        require(_newOwner != address(0));
        emit OwnershipTransferred(owner, _newOwner);
        owner = _newOwner;
    }

    function transferOperator(address _newOperator) external onlyOwner {
        require(_newOperator != address(0));
        emit OperatorTransferred(operator, _newOperator);
        operator = _newOperator;
    }
}
// ----------------------------------------------------------------------------
// @title KIP7
// ----------------------------------------------------------------------------
contract KIP7 is KIP13, IKIP7, Ownable {
    using SafeMath for uint256;
    
    event LockedInfo(address indexed from, address indexed to, uint256 value, uint8 tokenType, uint256 distributedTime, uint256 lockUpPeriodMonth, uint256 unlockAmountPerCount, uint256 remainUnLockCount, uint256 CONST_UNLOCKCOUNT);
    event ChangeListingTime(uint256 oldTime, uint256 newTime);
    event FinshedSetExchangeListingTime();

    struct LockInfo {
        bool isLocked;
        uint8 tokenType;
        uint256 amount;
        uint256 distributedTime;
        uint256 lockUpPeriodMonth;
        uint256 lastUnlockTimestamp;
        uint256 unlockAmountPerCount;
        uint256 remainUnLockCount;
        uint256 CONST_UNLOCKCOUNT;
    }
    
    uint256 internal _totalSupply;
    uint8 private _decimals = 18;

    uint256 internal _tokenCreatedTime;
    uint256 internal _exchangeListingTime = 9999999999;
    bool private _setExchangeListingTimeFinished = false;
    
    mapping(address => uint256) internal _balances;
    mapping(address => mapping (address => uint256)) internal _allowances;

    mapping(address => uint8) internal _cardioWallet;
    mapping(address => mapping (uint8 => LockInfo)) internal _lockedInfo;

    bytes4 private constant _KIP7_RECEIVED = 0x9d188c22;
    bytes4 private constant _INTERFACE_ID_KIP7 = 0x65787371;

    modifier canSetExchangeListingTime() { require(!_setExchangeListingTimeFinished); _; }

    constructor() public {
        _tokenCreatedTime = now;
        // Crowd Sale Wallet
        _cardioWallet[0xAb388B7E9bB7C9DB8858DbACACCC667d4Cf5D390] = 1;
        // Team & Advisors A
        _cardioWallet[0x5Ea976A033aE4473faA7beaAe4A9CCFFD6075FCc] = 2;
        // Team & Advisors B
        _cardioWallet[0x9Cd9A5fad80707005a3835bEc9F68A892e256108] = 3;
        // Ecosystem Activation
        _cardioWallet[0x596C53c1d24F1BA7F7Fb38c2676F7673378150c9] = 4;
        // Business Development
        _cardioWallet[0x3F6B9a3b0682E3A8Cda81eeE78d4E9D53E4FbC24] = 5;
    }

    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) public view returns (uint256) {
        uint256 totalBalances = _balances[account];
        uint8 tokenType;

        for (tokenType = 1; tokenType <= 5; tokenType++) {
            LockInfo memory lockInfo = _lockedInfo[account][tokenType];
            totalBalances = totalBalances.add(lockInfo.amount);
        }
        
        return totalBalances;
    }

    function unLockBalanceOf(address account) public view returns (uint256) {
        return _balances[account];
    }

    function lockUpInfo(address account, uint8 tokenType) public view returns (bool, uint8, uint256, uint256, uint256, uint256, uint256, uint256, uint256) {
        LockInfo memory lockInfo = _lockedInfo[account][tokenType];
        return (lockInfo.isLocked, lockInfo.tokenType, lockInfo.amount, lockInfo.distributedTime, lockInfo.lockUpPeriodMonth, lockInfo.lastUnlockTimestamp, lockInfo.unlockAmountPerCount, lockInfo.remainUnLockCount, lockInfo.CONST_UNLOCKCOUNT);
    }

    function decimals() public view returns (uint8) {
        return _decimals;
    }

    function exchangeListingTime() public view returns (uint256) {
        return _exchangeListingTime;
    }

    function setExchangeListingTimeFinished() public view returns (bool) {
        return _setExchangeListingTimeFinished;
    }

    function setExchangeListingTime(uint256 listingTime) onlyOwner canSetExchangeListingTime public {
        emit ChangeListingTime(_exchangeListingTime, listingTime);
        _exchangeListingTime = listingTime;
    }

    function finishSetExchangeListingTime() onlyOwner canSetExchangeListingTime public {
        _setExchangeListingTimeFinished = true;
        emit FinshedSetExchangeListingTime();
    }

    function transfer(address recipient, uint256 amount) public returns (bool) {
        _transfer(msg.sender, recipient, amount);
        return true;
    }

    function allowance(address owner, address spender) public view returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount) public returns (bool) {
        _approve(msg.sender, spender, amount);
        return true;
    }

    function increaseApproval(address spender, uint256 amount) public returns (bool) {
        _approve(msg.sender, spender, _allowances[msg.sender][spender].add(amount));
        return true;
    }

    function decreaseApproval(address spender, uint256 amount) public returns (bool) {
        if (amount >= _allowances[msg.sender][spender]) {
            amount = 0;
        } else {
            amount = _allowances[msg.sender][spender].sub(amount);
        }

        _approve(msg.sender, spender, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) public returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, msg.sender, _allowances[sender][msg.sender].sub(amount));
        return true;
    }
    
    function safeTransfer(address recipient, uint256 amount) public {
        safeTransfer(recipient, amount, "");
    }

    function safeTransfer(address recipient, uint256 amount, bytes memory data) public {
        transfer(recipient, amount);
        require(_checkOnKIP7Received(msg.sender, recipient, amount, data), "KIP7: transfer to non KIP7Receiver implementer");
    }
    
    function safeTransferFrom(address sender, address recipient, uint256 amount) public {
        safeTransferFrom(sender, recipient, amount, "");
    }

    function safeTransferFrom(address sender, address recipient, uint256 amount, bytes memory data) public {
        transferFrom(sender, recipient, amount);
        require(_checkOnKIP7Received(sender, recipient, amount, data), "KIP7: transfer to non KIP7Receiver implementer");
    }

    function _approve(address owner, address spender, uint256 amount) internal {
        require(owner != address(0), "KIP7: approve from the zero address");
        require(spender != address(0), "KIP7: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _transfer(address sender, address recipient, uint256 amount) internal {
        require(sender != address(0), "KIP7: transfer from the zero address");
        require(recipient != address(0), "KIP7: transfer to the zero address");

        uint8 adminAccountType = _cardioWallet[sender];
        // Crowd Sale Wallet, Team & Advisors from admin wallet Type 1, 2, 3
        if(adminAccountType > 0 && adminAccountType <= 3) {
            _addLocker(sender, recipient, adminAccountType, amount);
        } else {
            // Check "From" LockUp Balance
            uint8 tokenType;
            for (tokenType = 1; tokenType <= 5; tokenType++) {
                LockInfo storage lockInfo = _lockedInfo[sender][tokenType];
                if (lockInfo.isLocked) {
                    _unLock(sender, tokenType);
                }
            }
            _balances[sender] = _balances[sender].sub(amount);
            _balances[recipient] = _balances[recipient].add(amount);
        }

        emit Transfer(sender, recipient, amount);
    }

    function _addLocker(address sender, address recipient, uint8 adminAcountType, uint256 amount) internal {
        require(_lockedInfo[recipient][adminAcountType].isLocked == false, "Already Locked User");
        
        uint256 distributedTime;
        uint256 lockUpPeriodMonth;
        uint256 unlockAmountPerCount;
        uint256 remainUnLockCount;
        uint256 CONST_UNLOCKCOUNT;
        
        if(adminAcountType == 1) { // Crowd Sale
            distributedTime = _exchangeListingTime;
            lockUpPeriodMonth = 2;
            unlockAmountPerCount = amount.div(5);
            remainUnLockCount = 5;
            CONST_UNLOCKCOUNT = 5;
        } else if(adminAcountType == 2) { // Team & Advisors
            distributedTime = now;
            lockUpPeriodMonth = 3;
            unlockAmountPerCount = amount.div(10);
            remainUnLockCount = 10;
            CONST_UNLOCKCOUNT = 10;
        } else { // Team & Advisors
            distributedTime = now;
            lockUpPeriodMonth = 12;
            unlockAmountPerCount = amount.div(10);
            remainUnLockCount = 10;
            CONST_UNLOCKCOUNT = 10;
        }
        
        LockInfo memory newLockInfo = LockInfo({
            isLocked: true,
            tokenType : adminAcountType,
            amount: amount,
            distributedTime: distributedTime,
            lockUpPeriodMonth: lockUpPeriodMonth,
            lastUnlockTimestamp: 0,
            unlockAmountPerCount: unlockAmountPerCount,
            remainUnLockCount: remainUnLockCount,
            CONST_UNLOCKCOUNT: CONST_UNLOCKCOUNT
        });
        
        _balances[sender] = _balances[sender].sub(amount);
        _lockedInfo[recipient][adminAcountType] = newLockInfo;
    }
    
    function _unLock(address sender, uint8 tokenType) internal {
        LockInfo storage lockInfo = _lockedInfo[sender][tokenType];

        // Only Crowd Sale Type
        if(tokenType == 1 && _exchangeListingTime <= now && lockInfo.remainUnLockCount == 5) {
            // lockInfo update
            lockInfo.distributedTime = _exchangeListingTime;
            lockInfo.remainUnLockCount = 4;
            lockInfo.CONST_UNLOCKCOUNT = 4;
            lockInfo.amount = lockInfo.amount.sub(lockInfo.unlockAmountPerCount);
            
            _balances[sender] = _balances[sender].add(lockInfo.unlockAmountPerCount);
        }

        if(_isOverLockUpPeriodMonth((now.safeSub(lockInfo.distributedTime)), lockInfo.lockUpPeriodMonth) == false) {
            return;
        }

        uint256 blockTime = now;
        uint256 count = _getUnLockCount(blockTime, lockInfo);

        // None
        if(count == 0) return;
        uint256 unlockAmount = count.mul(lockInfo.unlockAmountPerCount);

        // Shortage due to burn token
        // or the last distribution
        uint256 remainUnLockCount = lockInfo.remainUnLockCount.safeSub(count);
        if (lockInfo.amount.safeSub(unlockAmount) == 0 || remainUnLockCount == 0) {
            unlockAmount = lockInfo.amount;
            lockInfo.isLocked = false;
        }
        
        // lockInfo update
        lockInfo.lastUnlockTimestamp = now;
        lockInfo.remainUnLockCount = remainUnLockCount;
        lockInfo.amount = lockInfo.amount.sub(unlockAmount);
        
        _balances[sender] = _balances[sender].add(unlockAmount);
    }
    
    function _getUnLockCount(uint256 curBlockTime, LockInfo lockInfo) internal pure returns (uint256) {
        // 1 Month = 30 Days 
        uint256 lockUpTime = lockInfo.lockUpPeriodMonth * 30 * 24 * 60 * 60;

        uint256 startTime = lockInfo.distributedTime.add(lockUpTime);
        uint256 count = 0;

        if (lockInfo.lastUnlockTimestamp == 0) {
            count = _convertMSToMonth(curBlockTime - startTime);
        } else {
            uint256 unLockedCount = _convertMSToMonth(curBlockTime - startTime);
            uint256 alreadyUnLockCount = lockInfo.CONST_UNLOCKCOUNT - lockInfo.remainUnLockCount;
            
            count = unLockedCount.safeSub(alreadyUnLockCount);
        }
        return count;
    }
    
    function _isOverLockUpPeriodMonth(uint256 time, uint256 period) internal pure returns (bool) {
        return _convertMSToMonth(time) > period;
    }
    
    function _convertMSToMonth(uint256 time) internal pure returns (uint256) {
        return time.div(60).div(60).div(24).div(30);
    }

    function isContract(address account) internal view returns (bool) {
        uint256 size;
        assembly { size := extcodesize(account) }
        return size > 0;
    }

    function _checkOnKIP7Received(address sender, address recipient, uint256 amount, bytes memory _data) internal returns (bool) {
        if (!isContract(recipient)) {
            return true;
        }
        bytes4 retval = IKIP7Receiver(recipient).onKIP7Received(msg.sender, sender, amount, _data);
        return (retval == _KIP7_RECEIVED);
    }
}
// ----------------------------------------------------------------------------
// @title Burnable Token
// @dev Token that can be irreversibly burned (destroyed).
// ----------------------------------------------------------------------------
contract BurnableToken is KIP7 {
    event BurnAdminAmount(address indexed burner, uint256 value);
    event BurnLockedToken(address indexed burner, uint256 value, uint8 tokenType);

    modifier onlyCardioWallet() {
      require(msg.sender == 0x9Cd9A5fad80707005a3835bEc9F68A892e256108
      || msg.sender == 0x596C53c1d24F1BA7F7Fb38c2676F7673378150c9
      || msg.sender == 0x3F6B9a3b0682E3A8Cda81eeE78d4E9D53E4FbC24
    ); _; }

    function burnAdminAmount(uint256 _value) onlyOwner public {
        require(_value <= _balances[msg.sender]);

        _balances[msg.sender] = _balances[msg.sender].sub(_value);
        _totalSupply = _totalSupply.sub(_value);
    
        emit BurnAdminAmount(msg.sender, _value);
        emit Transfer(msg.sender, address(0), _value);
    }

    // Team & Advisors B - 3
    // 0x9Cd9A5fad80707005a3835bEc9F68A892e256108
    // Ecosystem Activation - 4
    // 0x596C53c1d24F1BA7F7Fb38c2676F7673378150c9
    // Business Development - 5
    // 0x3F6B9a3b0682E3A8Cda81eeE78d4E9D53E4FbC24
    function burnTypeToken(uint256 _value) onlyCardioWallet public {
        uint8 adminAccountType = _cardioWallet[msg.sender];
        LockInfo storage lockInfo = _lockedInfo[msg.sender][adminAccountType];

        lockInfo.amount = lockInfo.amount.sub(_value);
        _totalSupply = _totalSupply.sub(_value);

        if(lockInfo.amount == 0) {
            lockInfo.isLocked = false;
        }
    
        emit BurnLockedToken(msg.sender, _value, adminAccountType);
        emit Transfer(msg.sender, address(0), _value);
    }
}
// ----------------------------------------------------------------------------
// @title Mintable token
// @dev Simple ERC20 Token example, with mintable token creation
// Based on code by TokenMarketNet: https://github.com/TokenMarketNet/ico/blob/master/contracts/MintableToken.sol
// ----------------------------------------------------------------------------
contract MintableToken is KIP7 {
    event Mint(address indexed to, uint256 amount);
    event MintFinished();

    bool private _mintingFinished = false;

    modifier canMint() { require(!_mintingFinished); _; }

    function mintingFinished() public view returns (bool) {
        return _mintingFinished;
    }

    function mint(address _to, uint256 _amount, uint8 _tokenType) onlyOwner canMint public returns (bool) {
        _totalSupply = _totalSupply.add(_amount);

        if(_tokenType >= 4) {
            uint256 lockUpPeriodMonth;
            uint256 unlockAmountPerCount;
            uint256 remainUnLockCount;
            uint256 CONST_UNLOCKCOUNT;
            
            if(_tokenType == 4) { // Ecosystem Activation
                lockUpPeriodMonth = 0;
                unlockAmountPerCount = _amount.div(100);
                remainUnLockCount = 100;
                CONST_UNLOCKCOUNT = 100;
            } else if(_tokenType == 5) { // Business Development
                lockUpPeriodMonth = 0;
                unlockAmountPerCount = _amount.div(20);
                remainUnLockCount = 20;
                CONST_UNLOCKCOUNT = 20;
            }
            
            LockInfo memory newLockInfo = LockInfo({
                isLocked: true,
                tokenType : _tokenType,
                amount: _amount,
                distributedTime: _tokenCreatedTime,
                lockUpPeriodMonth: lockUpPeriodMonth,
                lastUnlockTimestamp: 0,
                unlockAmountPerCount: unlockAmountPerCount,
                remainUnLockCount: remainUnLockCount,
                CONST_UNLOCKCOUNT: CONST_UNLOCKCOUNT
            });
            
            _lockedInfo[_to][_tokenType] = newLockInfo;
            
            emit LockedInfo(address(0), _to, _amount, _tokenType, _tokenCreatedTime, lockUpPeriodMonth, unlockAmountPerCount, remainUnLockCount, CONST_UNLOCKCOUNT);
        } else {
            _balances[_to] = _balances[_to].add(_amount);
        }

        emit Mint(_to, _amount);
        emit Transfer(address(0), _to, _amount);

        return true;
    }

    function finishMinting() onlyOwner canMint public returns (bool) {
        _mintingFinished = true;
        emit MintFinished();
        return true;
    }
}
// ----------------------------------------------------------------------------
// @Project CardioCoin
// ----------------------------------------------------------------------------
contract CardioCoin is MintableToken, BurnableToken {
    event SetTokenInfo(string name, string symbol);
    string private _name = "";
    string private _symbol = "";

    constructor() public {
        _name = "CardioCoin";
        _symbol = "CRDC";

        emit SetTokenInfo(_name, _symbol);
    }

    function name() public view returns (string memory) {
        return _name;
    }

    function symbol() public view returns (string memory) {
        return _symbol;
    }
}