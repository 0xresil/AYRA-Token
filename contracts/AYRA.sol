// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ERC20.sol";
import "./Ownable.sol";
import "./Math.sol";

contract AYRA is ERC20, Ownable {

    using Math for uint256;

    address private walletOrigin = 0xE9fe09A55377f760128800e6813F2E2C07db60Ad;
    address private walletMarket = 0x0bD042059368389fdC3968d671c40319dEb39F2c;
    address private walletFoundingPartners = 0x454d1252EC7c1Dc7E4D0A92A84A3Da2BD158b1D7;
    address private walletBlockedFoundingPartners = 0x8f7F2243A34169931741ba7eB257841C639Bc165;
    address private walletSocialPartners = 0xe307d66905D10e7e51B0BFb12E7e64C876a04215;
    address private walletProgrammersAndPartners = 0xc21713ef49a48396c1939233F3B24E1c4CCD09a4;
    address private walletPrivateInvestors = 0x252Fa9eD5F51e3A9CF1b1890f479775eFeaa653d;
    address private walletAidsAndDonations = 0x1EEffDA40C880a93E19ecAF031e529C723072e51;

    uint256 private _maxBurnAmount = 100_000_000_000_000 * (10 ** decimals());
    uint256 private _maxStakingAmount = 60_000_000_000_000 * (10 ** decimals());
    uint256 private _maxStakingAmountPerAccount = 100_000_000 * (10 ** decimals());
    uint256 private _totalStakingAmount = 0;
    uint256 private _stakingPeriod = block.timestamp + 730 days;
    uint256 private _stakingFirstPeriod = block.timestamp + 365 days;

    uint256 private _stakingFirstPeriodReward = 1644;
    uint256 private _stakingSecondPeriodReward = 822;
    
    uint256 private _deployedTime = block.timestamp;
    uint256 private _burnedAmount = 0;
    
    mapping (address => uint) _stakedBalances;
    mapping (address => uint) _rewardedLastTime;

    event StakingSucceed(address indexed account, uint256 totalStakedAmount);
    event WithdrawSucceed(address indexed account, uint256 remainedStakedAmount);

    constructor() ERC20("AYRA", "AYRA") {
        //uint totalSupply = 1_000_000_000_000_000 * (10 ** decimals());
        _mint(walletOrigin, 400_000_000_000_000 * (10 ** decimals()));
        _mint(walletMarket, 100_000_000_000_000 * (10 ** decimals()));
        _mint(walletFoundingPartners, 90_000_000_000_000 * (10 ** decimals()));
        _mint(walletBlockedFoundingPartners, 10_000_000_000_000 * (10 ** decimals()));
        _mint(walletSocialPartners, 100_000_000_000_000 * (10 ** decimals()));
        _mint(walletProgrammersAndPartners, 180_000_000_000_000 * (10 ** decimals()));
        _mint(walletPrivateInvestors, 70_000_000_000_000 * (10 ** decimals()));
        _mint(walletAidsAndDonations, 50_000_000_000_000 * (10 ** decimals()));
    }

    function burn(address account, uint amount) public onlyOwner {
        require(_burnedAmount + amount < _maxBurnAmount, "Burning too much.");
        _burn(account, amount);
        _burnedAmount += amount;
    }

    function stake(uint amount) public {
        require(balanceOf(msg.sender) >= amount, "insufficient balance for staking.");
        require(block.timestamp <= _stakingPeriod, "The time is over staking period.");

        _updateReward(msg.sender);

        _stakedBalances[msg.sender] += amount;
        require(_stakedBalances[msg.sender] <= _maxStakingAmountPerAccount, "This account overflows staking amount");
        
        _totalStakingAmount += amount;
        require(_totalStakingAmount <= _maxStakingAmount, "Total staking amount overflows its limit.");
        
        _transfer(msg.sender, walletOrigin, amount);
        
        emit StakingSucceed(msg.sender, _stakedBalances[msg.sender]);
    }

    function balanceOf(address account) public view override returns (uint) {
        return ERC20.balanceOf(account) + _getAvailableReward(account);
    }

    function _getAvailableReward(address account) private view returns (uint) {
        require(_rewardedLastTime[account] <= block.timestamp, "last reward time is bigger than now!");

        if (_rewardedLastTime[account] > _stakingPeriod) return 0;
        
        uint reward = 0;
        if (_rewardedLastTime[account] <= _stakingFirstPeriod) {
            uint rewardDays = _stakingFirstPeriod.min(block.timestamp) - _rewardedLastTime[account];
            rewardDays /= 1 days;
            reward = rewardDays * _stakedBalances[account] * _stakingFirstPeriodReward / 10000;
        }

        if (block.timestamp > _stakingFirstPeriod) {
            uint rewardDays = _stakingPeriod.min(block.timestamp) - _rewardedLastTime[account].max(_stakingFirstPeriod);
            rewardDays /= 1 days;
            reward += rewardDays * _stakedBalances[account] * _stakingSecondPeriodReward / 10000;
        }
        
        return reward;
    }

    function withdraw(uint amount) public {
        require (_stakedBalances[msg.sender] >= amount, "Can't withdraw more than staked balance");

        _updateReward(msg.sender);
        _stakedBalances[msg.sender] -= amount;
        _totalStakingAmount -= amount;
        _transfer(walletOrigin, msg.sender, amount);
        emit WithdrawSucceed(msg.sender, _stakedBalances[msg.sender]);
    } 

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal override {
        if (from != address(0)) {
            _updateReward(from);
        }
    }

    function _updateReward(address account) private {
        uint availableReward = _getAvailableReward(account);
        _rewardedLastTime[account] = block.timestamp;
        _balances[account] += availableReward;
    }
} 