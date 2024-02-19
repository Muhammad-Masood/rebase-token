// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract MagnetToken is ERC20, Ownable(msg.sender) {
    uint256 private _rebasePercentage = 987; // 9.87%
    uint256 private _lastRebaseTime;
    uint256 private _rebaseInterval = 1 minutes; // Rebase interval set to 15 minutes
    uint256 _totalSupply;
    mapping(address account => uint256) public _shares;

    event Rebase(uint256 newTotalSupply, uint256 rebaseAmount);

    constructor() ERC20("MagnetToken", "MGNT") {
        _mint(msg.sender, 1234567890 * 10 ** 18); // Initial total supply for MGNT
        _lastRebaseTime = block.timestamp;
    }

    function balanceOf(address account) public view override returns (uint256) {
        uint256 balance = ((_shares[account] * _totalSupply) /
            (100 * 10 ** 18));
        return balance;
    }

    function _update(
        address from,
        address to,
        uint256 value
    ) internal override {
        if (from == address(0)) {
            // Overflow check required: The rest of the code assumes that totalSupply never overflows
            _totalSupply += value;
        } else {
            uint256 valueShare = getShare(value);
            uint256 fromShare = _shares[from];
            if (fromShare < valueShare) {
                revert ERC20InsufficientBalance(from, balanceOf(from), value);
            }
            unchecked {
                // Overflow not possible: value <= fromBalance <= totalSupply.
                _shares[from] = _shares[from] - valueShare;
            }
        }
        if (to == address(0)) {
            unchecked {
                // Overflow not possible: value <= totalSupply or value <= fromBalance <= totalSupply.
                _totalSupply -= value;
            }
        } else {
            unchecked {
                // Overflow not possible: balance + value is at most totalSupply, which we know fits into a uint256.
                _shares[to] += getShare(value);
            }
        }
        emit Transfer(from, to, value);
    }

    function rebase() external {
        require(
            block.timestamp >= _lastRebaseTime + _rebaseInterval,
            "Rebase interval has not elapsed yet"
        );
        uint256 rebaseAmount = (_totalSupply * _rebasePercentage) / (10000); // Calculate the rebase amount
        _totalSupply = _totalSupply - rebaseAmount; // Increase total supply by rebase amount
        _lastRebaseTime = block.timestamp;
        emit Rebase(_totalSupply, rebaseAmount);
    }

    function lastRebaseTime() external view returns (uint256) {
        return _lastRebaseTime;
    }

    function rebaseInterval() external view returns (uint256) {
        return _rebaseInterval;
    }

    function rebasePercentage() external view returns (uint256) {
        return _rebasePercentage;
    }

    function getShare(uint256 amount) public view returns (uint256) {
        uint256 share = ((amount * 100) * 10 ** 18) / _totalSupply;
        return share;
    }

    function totalSupply() public view override returns (uint256) {
        return _totalSupply;
    }
}
