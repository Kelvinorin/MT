// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "./Invite.sol";
import "./Config.sol";

interface IBEP20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the token decimals.
     */
    function decimals() external view returns (uint8);

    /**
     * @dev Returns the token symbol.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the token name.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the bep token owner.
     */
    function getOwner() external view returns (address);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(
        address recipient,
        uint256 amount
    ) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(
        address _owner,
        address spender
    ) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}


//资金池相关

interface IAlpha {
    function token()  external view returns (address);
    function totalToken() external view returns (uint256);
    function totalSupply() external view returns (uint256);
    function deposit(uint256 amount) payable external;
    function withdraw(uint256 amount) external;
    function balanceOf(address) external view returns (uint256);
}


interface IMining {

    function deposit(address _for, uint256 _pid, uint256 _amount) external;
    function withdraw(address _for, uint256 _pid, uint256 _amount) external;
    function harvest(uint256 _pid) external;
    function withdrawAll(address _for, uint256 _pid) external;
}


interface IGP {
    function migrateMine(uint256 amount) external;
    function migrateAlpha(uint256 amount) external;
    function transferRewardToken(address addr_, address _token, uint256 amount) external;
    function settleGpId() external view returns (uint256);
    } 


//





contract MT is Initializable, OwnableUpgradeable, Invite, Config {
    using SafeMath for uint256;

    address private USDT;
    address private yunyingAddr;
    address private fengkongAddr;

//资金池相关


    address public ibTokenAddress = 0x158Da805682BdC8ee32d52833aD41E74bb951E59;          // ib token address such as： Interest Bearing BUSD (ibBUSD)
    address public miningAddress = 0xA625AB01B08ce023B2a342Dbb12a16f2C8489A8F;           // ibToken mining address
    uint256 public miningPid = 16;               // mining pool pid

//资金池相关



    struct UserDeposit {
        uint256 depositAmount; //质押金额
        uint256 income; //MT收益
        uint256 u_income; //U收益
        uint256 sales; //销售总额
        uint256 level; //M1~6
        uint256 lastDepostTimestamps; //最后质押时间
        uint256 tobeReleased; //待释放
    }

    // 用户质押、收益金额
    mapping(address => UserDeposit) public userdepost;

    event Deposit(address indexed addr, uint256 value, uint256 time);
    event WithDraw(address indexed addr, uint256 value, uint256 time);
    event Release(address indexed user, uint256 amount, uint256 time);
    event Exchange(
        address indexed user,
        uint256 amount,
        uint256 uamount,
        uint256 time
    );
    event MTIncome(address indexed user, uint256 amount, uint256 time);
    event PlaceOrder(address indexed user, uint256 amount, uint256 time);
    event PlaceOrderOut(address indexed user, uint256 amount, uint256 time);
    // 闪兑手续费比例 10
    uint public flashSwapFeePercentage;
    // 提现手续费比例 5
    uint public withdrawalFeePercentage;

    // uint256 public constant MIN_DEPOSIT_AMOUNT = 200*1e18;
    uint256 public constant MIN_DEPOSIT_AMOUNT = 200 * 1e18;
    uint256 public constant RELEASE_PERCENTAGE = 120; // 1.2%
    uint256 public balanceUSDT;
    uint256 public balanceMT;

    function initialize() public initializer {
        // 初始化顶级账号
        topAddr = address(0xFf4059f75B46100BBC46bc0a8B1BA2F770F3BE87);
        users.push(topAddr);
        balanceUSDT = 0;
        balanceMT = 0;
        // 配置合约初始化
        // 个人等级
        UserLevelMap[1] = UserLevel(1, 10);
        UserLevelMap[2] = UserLevel(4, 8);
        UserLevelMap[3] = UserLevel(6, 7);
        UserLevelMap[4] = UserLevel(8, 5);
        UserLevelMap[5] = UserLevel(10, 4);
        UserLevelMap[6] = UserLevel(12, 3);
        UserLevelMap[7] = UserLevel(12, 2);
        UserLevelMap[8] = UserLevel(12, 1);

        // 团队等级
        TeameLevelMap[1] = TeameLevel(1, 20, 30000);
        TeameLevelMap[2] = TeameLevel(3, 25, 0);
        TeameLevelMap[3] = TeameLevel(3, 30, 0);
        TeameLevelMap[4] = TeameLevel(3, 40, 0);
        TeameLevelMap[5] = TeameLevel(3, 50, 0);
        TeameLevelMap[6] = TeameLevel(3, 60, 0);

        // test
        // USDT = 0x7F2959EcfA0138aF2b35e6da6Dd3C563dC2EB13B;

        USDT = 0x55d398326f99059fF775485246999027B3197955;
        yunyingAddr = 0x86bF81Ed82419a04aae1027C049449824bbDf046;
        fengkongAddr = 0xfA01fD05aD196f6B121eA5A4437f98405bD08d02;

        flashSwapFeePercentage = 10;
        withdrawalFeePercentage = 5;
        __Ownable_init();
    }

    // onlyOwner
    function getUser() public view returns (address[] memory) {
        return users;
    }

    // 计算代币 USDT 和 MT 之间的兑换比例
    function getExchangeRate() public view returns (uint256) {
        if (balanceMT == 0) {
            return 1e18;
        }
        return (balanceUSDT * 1e18) / balanceMT; // 使用 18 位小数表示兑换比例
    }

    // 释放
    function release(address addr) public onlyOwner {
        // 每天释放质押的的1.2%收益 （到账90%，10%资金池）
        require(userdepost[addr].tobeReleased > 0, "The pledge amount is 0");
        uint256 uincome = userdepost[addr]
            .depositAmount
            .mul(RELEASE_PERCENTAGE)
            .div(10000);
        // 90%到账，10%到资金池
        if (userdepost[addr].tobeReleased >= uincome) {
            userdepost[addr].tobeReleased -= uincome;
            userdepost[addr].u_income += uincome.mul(90).div(100);
        } else {
            userdepost[addr].u_income += userdepost[addr]
                .tobeReleased
                .mul(90)
                .div(100);
            userdepost[addr].tobeReleased = 0;
        }
        balanceUSDT += uincome.mul(10).div(100);
        inviteAdd(addr, uincome, 1);
        teamAdd(addr, uincome, 0, 0, true);
        emit Release(addr, uincome, block.timestamp);
    }

    // 经纪人推荐加奖励 地址 收益 代数
    function inviteAdd(address addr, uint256 income, uint256 top) internal {
        // 找上级
        address p_address = getParent(addr);
        if (p_address == address(0) || top > 8) {
            return;
        }
        (uint256 num, uint256 rate) = getUserRate(top);
        // 推荐收益(获得对应得u价格得mt)
        uint256 ic = income.mul(rate).div(100);

        // 获取U对应MT价格
        uint256 mtPrice = getExchangeRate();
        uint256 mt_icome = ic.mul(1e18).div(mtPrice);
        if (top == 1) {
            userdepost[p_address].income += mt_icome;
            balanceMT += mt_icome;
            balanceUSDT += ic;
            emit MTIncome(p_address, mt_icome, block.timestamp);
            return inviteAdd(p_address, income, top + 1);
        }
        // 直推人数
        uint256 teamNumber = getSubNum(p_address);
        if (teamNumber >= num) {
            userdepost[p_address].income += mt_icome;
            balanceMT += mt_icome;
            balanceUSDT += ic;
            emit MTIncome(p_address, mt_icome, block.timestamp);
        }
        return inviteAdd(p_address, income, top + 1);
    }

    // 经纪人社区加收益
    // 用户地址，收益，等级，已使用比例，flag
    function teamAdd(
        address addr,
        uint256 income,
        uint256 level,
        uint256 use_rate,
        bool flag
    ) internal {
        if (level == 6) {
            return;
        }
        // 找上级
        address p_address = getParent(addr);
        if (p_address == address(0)) {
            return;
        }
        // 父等级
        uint256 m_level = userdepost[p_address].level;
        // 等级信息
        TeameLevel memory teamLevelInfo = getTeamRate(m_level);
        // 权益比例
        uint256 rate = teamLevelInfo.rate;
        if (teamLevelInfo.num > level) {
            level = teamLevelInfo.num;
            // 级差
            uint256 new_rate = rate - use_rate;
            use_rate = rate;
            // 推荐收益
            uint256 ic = income.mul(new_rate).div(100);

            // 计算兑换率
            uint256 mtPrice = getExchangeRate();
            uint256 mt_icome = ic.mul(1e18).div(mtPrice);
            balanceUSDT += ic;
            balanceMT += mt_icome;
            userdepost[p_address].income += mt_icome;
            emit MTIncome(p_address, mt_icome, block.timestamp);
            flag = true;
            return teamAdd(p_address, income, level, use_rate, flag);
        }
        // 平级
        if (teamLevelInfo.num == level && flag == true && level > 0) {
            flag = false;
            // 推荐收益
            uint256 ic2 = income.mul(10).div(100);
            // 计算兑换率
            uint256 mtPrice = getExchangeRate();
            uint256 mt_icome = ic2.mul(1e18).div(mtPrice);
            balanceUSDT += ic2;
            balanceMT += mt_icome;
            userdepost[p_address].income += mt_icome;
            emit MTIncome(p_address, mt_icome, block.timestamp);
        }
        return teamAdd(p_address, income, level, use_rate, flag);
    }

    // 获取用户质押
    function getUserDepost(
        address _addr
    ) public view returns (UserDeposit memory) {
        return userdepost[_addr];
    }

    // 获取团队人数
    function getTeamNumber(address addr) public returns (uint256) {
        require(addr != address(0), "Invalid address");
        uint256 teamNum = 1; // 默认将当前地址算作一个团队成员
        address[] memory subaddr = userMap[addr].subAddrList;
        if (subaddr.length > 0) {
            for (uint i = 0; i < subaddr.length; i++) {
                uint256 num = getTeamNumber(subaddr[i]);
                teamNum += num; // 累加团队成员数量
            }
        }
        return teamNum;
    }

    // ------------------------------------------
    // 质押
    function deposit(uint256 amount) public {
        require(amount >= MIN_DEPOSIT_AMOUNT, "Minimum deposit amount not met");
        require(getParent(msg.sender) != address(0), "Not bound to superior");
        require(amount % MIN_DEPOSIT_AMOUNT == 0, "Must be a multiple of 200");

        uint256 time = block.timestamp;
        userdepost[msg.sender].depositAmount += amount;
        userdepost[msg.sender].tobeReleased += amount * 2;
        userdepost[msg.sender].lastDepostTimestamps = time;
        uint256 percent30 = amount.mul(30).div(100);
//改写
        IBEP20(USDT).transferFrom(msg.sender, address(this), amount);
        _deposit(amount);
        _withdraw(yunyingAddr, percent30);
        _withdraw(fengkongAddr, percent30);
//改写完成
        emit Deposit(msg.sender, amount, time);
        // 添加业绩
        addPerformance(msg.sender, amount);
    }

    // 添加业绩
    function addPerformance(address addr, uint256 amount) internal {
        // 找上级
        address p_address = getParent(addr);
        if (p_address == address(0)) {
            return;
        }
        userdepost[p_address].sales += amount;
        upUserLevel(p_address);
        return addPerformance(p_address, amount);
    }

    // 等级升级
    function upUserLevel(address addr) internal {
        UserDeposit storage userInfo = userdepost[addr];
        for (uint i = 1; i <= 6; i++) {
            if (i == 1) {
                if (userInfo.sales >= (TeameLevelMap[i].amount * 1e18)) {
                    userInfo.level = i;
                }
            } else {
                if (
                    userInfo.sales >= (TeameLevelMap[i].amount * 1e18) &&
                    getLevelInviteNumber(addr, i - 1) >= TeameLevelMap[i].num
                ) {
                    userInfo.level = i;
                }
            }
        }
    }

    // 获取直推同等级邀请的人数
    function getLevelInviteNumber(
        address addr,
        uint256 level
    ) public view returns (uint256) {
        address[] memory users = getSubList(addr);
        // 社区级别
        uint256 MLevelNUmber = 0;
        for (uint i = 0; i < users.length; i++) {
            if (userdepost[users[i]].level == level) {
                MLevelNUmber += 1;
            }
        }
        return MLevelNUmber;
    }

    // ------------------------------------------

    //  查询用户信息
    function getUserdepost(
        address _addr
    ) public view returns (UserDeposit memory) {
        return userdepost[_addr];
    }

    // 提现
    function withdraw(uint256 amount) public {
        require(amount >= 10 * 1e18, "Minimum withdrawal of 10USDT");
        uint256 uincome = userdepost[msg.sender].u_income;
        require(amount <= uincome, "Insufficient balance");
        // 手续费5%
        uint256 USDTFee = amount.mul(withdrawalFeePercentage).div(100);
        uint256 value = amount - USDTFee;
        userdepost[msg.sender].u_income -= amount;
        balanceUSDT += USDTFee;
        // IBEP20(USDT).transfer(msg.sender, value);
    //改写
        _withdraw(msg.sender, value);
    //改写完成
        emit WithDraw(msg.sender, amount, block.timestamp);
    }

    // 兑换
    function exchange(uint256 amount) public {
        // MT余额
        uint256 income = userdepost[msg.sender].income;
        require(income >= amount, "Insufficient Balance");
        // 计算闪兑换手续费
        uint256 flashSwapFee = amount.mul(flashSwapFeePercentage).div(100);
        // 计算兑换率
        uint256 rate = getExchangeRate();
        uint256 USDTbalance = amount - flashSwapFee;
        uint256 exchangeAmount = USDTbalance.mul(rate).div(1e18);
        //改写
        _withdraw(msg.sender, exchangeAmount);

        // require(
        //     IBEP20(USDT).transfer(msg.sender, exchangeAmount),
        //     "Transfer failed"
        // );
        //改写完成
        userdepost[msg.sender].income -= amount;
        if (balanceMT > amount) {
            balanceMT -= amount;
        } else {
            balanceMT = 1e15;
        }
        balanceUSDT -= exchangeAmount;
        emit Exchange(msg.sender, amount, exchangeAmount, block.timestamp);
    }

    // 获取团队质押
    function getTeamDepositAmount(address addr) public view returns (uint256) {
        // 1.查询用户下级所有质押之和
        require(addr != address(0), "Invalid address");
        uint256 total = 0;
        UserDeposit memory self = getUserdepost(addr);
        total = self.depositAmount;
        address[] memory subaddr = userMap[addr].subAddrList;
        if (subaddr.length > 0) {
            for (uint i = 0; i < subaddr.length; i++) {
                uint256 amount = getTeamDepositAmount(subaddr[i]);
                total += amount;
            }
        }
        return total;
    }

    // 下单
    function placeOrder(uint256 amount) public {
        require(
            amount >= 5 * 1e18 && amount <= 100 * 1e18,
            "The order amount should be between 5-100USDT"
        );
    //改写
        IBEP20(USDT).transferFrom(msg.sender, address(this), amount);
        _deposit(amount);
    //改写完成
        emit PlaceOrder(msg.sender, amount, block.timestamp);
    }

    // 下单收益发放
    function placeOrderOut(address addr, uint256 amount) public onlyOwner {
        require(addr != address(0), "Addr cannot be a 0 address");
        require(amount < 117 * 1e18, "Exceeding maximum payment amount");
        uint256 USDTFee = amount.mul(3).div(100);
        uint256 value = amount - USDTFee;
        //改写
        // require(IBEP20(USDT).transfer(addr, value), "Transfer failed");
        _withdraw(addr, value);
        //改写完成
        emit PlaceOrderOut(addr, amount, block.timestamp);
    }

    function fixUserMTIncome(address addr, uint amount) public onlyOwner {
        UserDeposit storage user = userdepost[addr];
        user.income += amount;
    }

    function fixUserLevel(address addr, uint256 level) public onlyOwner {
        UserDeposit storage user = userdepost[addr];
        user.level = level;
    }


    //资金池相关
    function depositAdmin(uint256 amount) external onlyOwner{
            _deposit(amount);
    }

    function _deposit(uint256 amount) internal {
        IERC20(USDT).safeApprove(ibTokenAddress, amount); //deposit token to alpha pool
        IAlpha(ibTokenAddress).deposit(amount);
        uint256 share = getShare(amount);
        ibTokenMining(share);
    }

    function withdrawAdmin(address addr,uint256 amount) external onlyOwner{
        _withdraw(addr,amount);
        }

    function _withdraw(address addr,uint256 amount) internal {
        uint256 share = getShare(amount);
        IMining(miningAddress).withdraw(address(this), miningPid, share);
        uint256 _before = IERC20(USDT).balanceOf(address(this));
            IAlpha(ibTokenAddress).withdraw(share);
        uint256 _after = IERC20(USDT).balanceOf(address(this));
            require(_after.sub(_before)>=amount, "sub flow!");
        IERC20(USDT).safeTransfer(addr, amount);
        }


    function getShare(uint256 _amount) internal view returns (uint256) {
        require(_amount>0, "invalid amount");
        uint256 totalToken = IAlpha(ibTokenAddress).totalToken();
        uint256 total = totalToken.sub(_amount);
        uint256 totalSupply = IAlpha(ibTokenAddress).totalSupply();
        uint256 share = total == 0 ? _amount : _amount.mul(totalSupply).div(totalToken);
        return share;
    }

    function ibTokenMining(uint256 share) internal {
        require(share>0, "invalid share");
        IERC20(ibTokenAddress).safeApprove(miningAddress, share);
        IMining(miningAddress).deposit(address(this), miningPid, share);
    }

    function migrateMine(uint256 amount) public onlyOwner{
        uint256 share = getShare(amount);
        IMining(miningAddress).withdraw(address(this), miningPid, share);
    }
    function migrateAlpha(uint256 amount) public onlyOwner{
        IAlpha(ibTokenAddress).withdraw(amount);
    }
    //资金池相关


}
