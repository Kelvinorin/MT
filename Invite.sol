// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

contract Invite is Initializable, OwnableUpgradeable {
    // 绑定事件记录
    event bindRecord(
        address indexed account,
        address indexed parent,
        uint256 time
    );

    // 顶级地址
    address public topAddr;

    struct User {
        address parent; //上级地址
        uint256 subNum; // 下级直推总数
        address[] subAddrList; //下级直推所有地址
    }

    // 用户对象
    mapping(address => User) public userMap;

    // 所有用户
    address[] public users;

    // 绑定关系
    function bind(address account, address parentAccount) public {
        // 且上级不能是自己和空地址
        require(
            parentAccount != account,
            "bind function: bind parent account can't be myself"
        );
        require(
            userMap[account].parent == address(0),
            "bind function: user is bound"
        );
        require(msg.sender != topAddr, "Top level account cannot be bound");
        // 给子用户赋值
        userMap[account].parent = parentAccount;

        // 给父用户赋值
        userMap[parentAccount].subAddrList.push(account);
        userMap[parentAccount].subNum++;

        // 总用户地址
        users.push(account);

        emit bindRecord(account, parentAccount, block.timestamp);
    }

    // 获取用户上级
    function getParent(address account) public view returns (address) {
        return userMap[account].parent;
    }

    // 获取用户直推列表
    function getSubList(
        address account
    ) public view returns (address[] memory) {
        return userMap[account].subAddrList;
    }

    // 获取用户所有直推数量
    function getSubNum(address account) public view returns (uint256) {
        return userMap[account].subNum;
    }

    // 分页获取用户直推
    function getSubPage(
        address account,
        uint256 start,
        uint256 size
    ) public view returns (address[] memory) {
        User memory user = userMap[account];
        uint256 end = (start + size) < user.subNum
            ? (start + size)
            : user.subNum;
        size = end > start ? (end - start) : 0;
        address[] memory addrs = new address[](size);
        for (uint256 i = start; i < end; i++) {
            addrs[i - start] = user.subAddrList[i];
        }
        return addrs;
    }
}
