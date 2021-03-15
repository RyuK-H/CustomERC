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

contract IKIP7Receiver {
    function onKIP7Received(address _operator, address _from, uint256 _amount, bytes memory _data) public returns (bytes4);
}
// ----------------------------------------------------------------------------
// @title KIP7
// ----------------------------------------------------------------------------
contract KIP7 is KIP13, IKIP7 {
    using SafeMath for uint256;
    
    uint256 internal totalSupply_;
    uint8 private _decimals = 18;
    
    mapping(address => uint256) internal balances;
    mapping (address => mapping (address => uint256)) internal allowed;

    bytes4 private constant _KIP7_RECEIVED = 0x9d188c22;
    bytes4 private constant _INTERFACE_ID_KIP7 = 0x65787371;

    function totalSupply() public view returns (uint256) {
        return totalSupply_;
    }

    function balanceOf(address account) public view returns (uint256) {
        return balances[account];
    }

    function decimals() public view returns (uint8) {
        return _decimals;
    }

    function transfer(address recipient, uint256 amount) public returns (bool) {
        _transfer(msg.sender, recipient, amount);
        return true;
    }

    function allowance(address owner, address spender) public view returns (uint256) {
        return allowed[owner][spender];
    }

    function approve(address spender, uint256 amount) public returns (bool) {
        _approve(msg.sender, spender, amount);
        return true;
    }

    function increaseApproval(address spender, uint256 amount) public returns (bool) {
        _approve(msg.sender, spender, allowed[msg.sender][spender].add(amount));
        return true;
    }

    function decreaseApproval(address spender, uint256 amount) public returns (bool) {
        if (amount >= allowed[msg.sender][spender]) {
            amount = 0;
        } else {
            amount = allowed[msg.sender][spender].sub(amount);
        }

        _approve(msg.sender, spender, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) public returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, msg.sender, allowed[sender][msg.sender].sub(amount));
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

        allowed[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _transfer(address sender, address recipient, uint256 amount) internal {
        require(sender != address(0), "KIP7: transfer from the zero address");
        require(recipient != address(0), "KIP7: transfer to the zero address");

        balances[sender] = balances[sender].sub(amount);
        balances[recipient] = balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
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
// @title Ownable
// ----------------------------------------------------------------------------
contract Ownable {
    address public owner;
    address public operator;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    event OperatorTransferred(address indexed previousOperator, address indexed newOperator);

    constructor() public {
        owner    = msg.sender;
        operator = msg.sender;
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
// @title BlackList
// ----------------------------------------------------------------------------
contract BlackList is Ownable {
    event Lock(address indexed _lockAddress);
    event Unlock(address indexed _unlockAddress);

    mapping( address => bool ) public blackList;

    modifier CheckBlackList() { require(blackList[msg.sender] != true); _; }

    function SetLockAddress(address _lockAddress) external onlyOwnerOrOperator {
        require(_lockAddress != address(0));
        require(_lockAddress != owner);
        require(blackList[_lockAddress] != true);
        
        blackList[_lockAddress] = true;
        emit Lock(_lockAddress);
    }

    function UnLockAddress(address _unlockAddress) external onlyOwner {
        require(blackList[_unlockAddress] != false);
        
        blackList[_unlockAddress] = false;
        emit Unlock(_unlockAddress);
    }
}
// ----------------------------------------------------------------------------
// @title Pausable
// ----------------------------------------------------------------------------
contract Pausable is Ownable {
    event Pause();
    event Unpause();

    bool public paused = false;

    modifier whenNotPaused() { require(!paused); _; }
    modifier whenPaused() { require(paused); _; }

    function pause() onlyOwnerOrOperator whenNotPaused public {
        paused = true;
        emit Pause();
    }

    function unpause() onlyOwner whenPaused public {
        paused = false;
        emit Unpause();
    }
}
// ----------------------------------------------------------------------------
// @title MultiTransfer Token
// @dev Only Admin
// ----------------------------------------------------------------------------
contract MultiTransferToken is KIP7, Ownable {
    function MultiTransfer(address[] _to, uint256[] _amount) onlyOwner public returns (bool) {
        require(_to.length == _amount.length);

        uint256 ui;
        uint256 amountSum = 0;
    
        for (ui = 0; ui < _to.length; ui++) {
            require(_to[ui] != address(0));
            amountSum = amountSum.add(_amount[ui]);
        }

        require(amountSum <= balances[msg.sender]);
        
        for (ui = 0; ui < _to.length; ui++) {
            transfer(_to[ui], _amount[ui]);
        }
        
        return true;
    }
}
// ----------------------------------------------------------------------------
// @title Burnable Token
// @dev Token that can be irreversibly burned (destroyed).
// ----------------------------------------------------------------------------
contract BurnableToken is KIP7, Ownable {
    event BurnAdminAmount(address indexed burner, uint256 value);

    function burnAdminAmount(uint256 _value) onlyOwner public {
        require(_value <= balances[msg.sender]);

        balances[msg.sender] = balances[msg.sender].sub(_value);
        totalSupply_ = totalSupply_.sub(_value);
    
        emit BurnAdminAmount(msg.sender, _value);
        emit Transfer(msg.sender, address(0), _value);
    }
}
// ----------------------------------------------------------------------------
// @title Mintable token
// @dev Simple ERC20 Token example, with mintable token creation
// Based on code by TokenMarketNet: https://github.com/TokenMarketNet/ico/blob/master/contracts/MintableToken.sol
// ----------------------------------------------------------------------------
contract MintableToken is KIP7, Ownable {
    event Mint(address indexed to, uint256 amount);
    event MintFinished();
    event MintReStart();

    bool public _mintingFinished = false;

    modifier canMint() { require(!_mintingFinished); _; }
    modifier cantMint() { require(_mintingFinished); _; }

    function mintingFinished() public view returns (bool) {
        return _mintingFinished;
    }

    function mint(address _to, uint256 _amount) onlyOwner canMint public returns (bool) {
        totalSupply_ = totalSupply_.add(_amount);
        balances[_to] = balances[_to].add(_amount);
    
        emit Mint(_to, _amount);
        emit Transfer(address(0), _to, _amount);
    
        return true;
    }

    function finishMinting() onlyOwner canMint public returns (bool) {
        _mintingFinished = true;
        emit MintFinished();
        return true;
    }

    function reStartMinting() onlyOwner cantMint public returns (bool) {
        _mintingFinished = false;
        emit MintReStart();
        return true;
    }
}
// ----------------------------------------------------------------------------
// @title Pausable token
// @dev StandardToken modified with pausable transfers.
// ----------------------------------------------------------------------------
contract PausableToken is KIP7, Pausable, BlackList {
    function transfer(address recipient, uint256 amount) public whenNotPaused CheckBlackList returns (bool) {
        return super.transfer(recipient, amount);
    }

    function approve(address spender, uint256 amount) public whenNotPaused CheckBlackList returns (bool) {
        return super.approve(spender, amount);
    }

    function increaseApproval(address spender, uint amount) public whenNotPaused CheckBlackList returns (bool) {
        return super.increaseApproval(spender, amount);
    }

    function decreaseApproval(address spender, uint amount) public whenNotPaused CheckBlackList returns (bool) {
        return super.decreaseApproval(spender, amount);
    }

    function transferFrom(address sender, address recipient, uint256 amount) public whenNotPaused CheckBlackList returns (bool) {
        require(blackList[sender] != true);
        require(blackList[recipient] != true);

        return super.transferFrom(sender, recipient, amount);
    }
}
// ----------------------------------------------------------------------------
// @Project FitFunsGames (FFG)
// ----------------------------------------------------------------------------
contract FitFunsGames is PausableToken, MintableToken, BurnableToken, MultiTransferToken {
    string private _name = "FitFunsGames";
    string private _symbol = "FFG";

    function name() public view returns (string memory) {
        return _name;
    }

    function symbol() public view returns (string memory) {
        return _symbol;
    }
}