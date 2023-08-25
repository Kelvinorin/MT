// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
contract Config is Initializable {

    // 个人等级
    struct UserLevel{
        uint num;//邀请人数
        uint rate;//收益比例
    }
    mapping(uint => UserLevel)  UserLevelMap;

    // 团队等级
    struct TeameLevel{
        uint num;//M等级
        uint rate;//权益比例
        uint amount;//入单金额
    }
    mapping(uint => TeameLevel)  TeameLevelMap;


    // constructor() {
    //     // 个人等级
    //     UserLevelMap[1]=UserLevel(1,10);
    //     UserLevelMap[2]=UserLevel(4,8);
    //     UserLevelMap[3]=UserLevel(6,7);
    //     UserLevelMap[4]=UserLevel(8,5);
    //     UserLevelMap[5]=UserLevel(10,4);
    //     UserLevelMap[6]=UserLevel(12,3);
    //     UserLevelMap[7]=UserLevel(12,2);
    //     UserLevelMap[8]=UserLevel(12,1);

    //     // 团队等级
    //     TeameLevelMap[1]=TeameLevel(1,20,30000);
    //     TeameLevelMap[2]=TeameLevel(3,25,0);
    //     TeameLevelMap[3]=TeameLevel(3,30,0);
    //     TeameLevelMap[4]=TeameLevel(3,40,0);
    //     TeameLevelMap[5]=TeameLevel(3,50,0);
    //     TeameLevelMap[6]=TeameLevel(3,60,0);
    // }


    // 获取用户等级
    function getUserRate(uint top) public view returns (uint num,uint rate) {
         return  (UserLevelMap[top].num,UserLevelMap[top].rate);
    }
    // 获取团队等级
    function getTeamRate(uint top) public view returns (TeameLevel memory amount) {
        return  TeameLevelMap[top];
    }




    
}