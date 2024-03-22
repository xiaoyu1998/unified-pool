// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.20;
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/utils/Context.sol";

abstract contract IndexERC20 is Context, IERC20{

    // Map of users address and their state data (userAddress => userStateData)
    mapping(address => uint256) internal _balances;
    mapping(address => uint256) internal _index;

    // Map of allowances (delegator => delegatee => allowanceAmount)
    mapping(address => mapping(address => uint256)) private _allowances;

    string private _name;
    string private _symbol;
    uint8 private _decimals;
    uint256 internal _totalSupply;

   
    // @dev Constructor.
    // @param name The name of the token
    // @param symbol The symbol of the token
    // @param decimals The number of decimals of the token
   
    constructor(string memory name_, string memory symbol_, uint8 decimals_) {
        _name = name_;
        _symbol = symbol_;
        _decimals = decimals_;
    }

    /// @inheritdoc IERC20
    function name() public view returns (string memory) {
        return _name;
    }

    /// @inheritdoc IERC20
    function symbol() external view returns (string memory) {
        return _symbol;
    }

    /// @inheritdoc IERC20
    function decimals() external view returns (uint8) {
        return _decimals;
    }

    /// @inheritdoc IERC20
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    /// @inheritdoc IERC20
    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    /// @inheritdoc IERC20
    function transfer(address to, uint256 amount) external virtual override returns (bool) {
        //uint128 castAmount = amount.toUint128();
        _transfer(_msgSender(), to, amount);
        return true;
    }

    /// @inheritdoc IERC20
    function allowance(
        address owner,
        address spender
    ) external view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    /// @inheritdoc IERC20
    function approve(address spender, uint256 amount) external virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    /// @inheritdoc IERC20
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external virtual override returns (bool) {
        //uint128 castAmount = amount.toUint128();
        _approve(from, _msgSender(), _allowances[from][_msgSender()] - amount);
        _transfer(from, to, amount);
        return true;
    }

     
    // @notice Increases the allowance of spender to spend _msgSender() tokens
    // @param spender The user allowed to spend on behalf of _msgSender()
    // @param addedValue The amount being added to the allowance
    // @return `true`
    function increaseAllowance(address spender, uint256 addedValue) external virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender] + addedValue);
        return true;
    }

   
    // @notice Decreases the allowance of spender to spend _msgSender() tokens
    // @param spender The user allowed to spend on behalf of _msgSender()
    // @param subtractedValue The amount being subtracted to the allowance
    // @return `true`
    function decreaseAllowance(
        address spender,
        uint256 subtractedValue
    ) external virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender] - subtractedValue);
        return true;
    }

   
    // @notice Transfers tokens between two users and apply incentives if defined.
    // @param from The source address
    // @param to The destination address
    // @param amount The amount getting transferred
    function _transfer(address from, address to, uint256 amount) internal virtual {
        require(from != address(0), "IndexERC20: transfer from the zero address");
        require(to != address(0), "IndexERC20: transfer to the zero address");

        uint256 fromBalance = _balances[from];
        require(fromBalance >= amount, "IndexERC20: transfer amount exceeds balance");
        unchecked {
            _balances[from] = fromBalance - amount;
            // Overflow not possible: the sum of all balances is capped by totalSupply, and the sum is preserved by
            // decrementing then incrementing.
            _balances[to] += amount;
        }

        //emit Transfer(from, to, amount);
    }

   
    // @notice Approve `spender` to use `amount` of `owner`s balance
    // @param owner The address owning the tokens
    // @param spender The address approved for spending
    // @param amount The amount of tokens to approve spending of
    function _approve(address owner, address spender, uint256 amount) internal virtual {
        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    //
    // @notice Update the name of the token
    // @param newName The new name for the token
    ///
    // function _setName(string memory newName) internal {
    //    _name = newName;
    // }

    //
    // @notice Update the symbol for the token
    // @param newSymbol The new symbol for the token
    ///
    // function _setSymbol(string memory newSymbol) internal {
    //     _symbol = newSymbol;
    // }

    //
    // @notice Update the number of decimals for the token
    // @param newDecimals The new number of decimals for the token
    ///
    // function _setDecimals(uint8 newDecimals) internal {
    //     _decimals = newDecimals;
    // }


}
