// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";


contract FarziUserControllerV2 is AccessControl {
        struct tradePool {
        uint256 level;
        uint256 maxLimit;
    }

    struct userStat {
        uint256 currentLevel;
        uint256 maxLimit;
        uint256 limitLeft;
        uint256 totalProfit;
    }

    event userStatsUpdated(userStat);
    event whitelistAdded(address user, bool status);
    event removedFromWhitelist(address user, bool status);
    event userBlocked(address user, bool status);
    event userUnblocked(address user, bool status);
    event adminAdded(address user, bool status);
    event adminRemoved(address user, bool status);


    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");
    bytes32 public constant USER_ROLE = keccak256("USER_ROLE");
    bytes32 public constant LOAN_PROVIDER = keccak256("LOAN_PROVIDER");

    mapping(address => userStat) internal userStats;
    mapping(uint256 => tradePool) internal tradePoolDetails;

    uint256 public poolLength;

    constructor(address admin, uint256[] memory limits) {
        _grantRole(ADMIN_ROLE, admin);
        poolLength = limits.length;
        for (uint256 index = 0; index < limits.length; index++) {
            tradePoolDetails[index + 1]= tradePool(index+1, limits[index]);
        }
    }

    function getLicensePoolDetails(uint256 level) public view returns(tradePool memory) {
        require(level >= 1 && level <= poolLength, "FarziUserStatsControllerV2: Invalid level");
        return tradePoolDetails[level];
    }

    function getUserStats(address user) public view returns(userStat memory) {
        require(hasRole(USER_ROLE, user), "FarziUserStatsControllerV2: Account not whitelisted");
        return userStats[user];
    }

    function updateUserStats(address user, uint256 borrowedValueinUSD, uint256 profitinUSD) internal returns(bool) {
        require(user != address(0) && borrowedValueinUSD > 0 && profitinUSD > 0, "FarziController: stats values should be greater than zero");
        userStats[user].limitLeft -= borrowedValueinUSD;
        userStats[user].totalProfit += profitinUSD;
        emit userStatsUpdated(userStats[user]);
        return true;
    }

    function addADMIN_ROLE(address newAdmin) external onlyRole(ADMIN_ROLE) {
        require(!hasRole(ADMIN_ROLE, newAdmin), "Controller: account already have ADMIN role");
        _grantRole(ADMIN_ROLE, newAdmin);
        emit adminAdded(newAdmin, true);
    }
    
    function removeADMIN_ROLE(address admin) external onlyRole(ADMIN_ROLE) {
        require(hasRole(ADMIN_ROLE, admin), "Controller: account not have ADMIN role");
        _revokeRole(ADMIN_ROLE, admin);
        emit adminRemoved(admin, true);
    }

    function addToWhitelist(address newUser, uint256 level) external onlyRole(ADMIN_ROLE) {
        require(!hasRole(USER_ROLE, newUser), "Controller: account already exists");
        require(level >= 1 && level <= poolLength, "FarziUserStatsControllerV2: Invalid level");
        _grantRole(USER_ROLE, newUser);
        uint256 _limit = tradePoolDetails[level].maxLimit;
        userStats[newUser] = userStat(level, _limit, _limit, 0);
        emit  whitelistAdded(newUser, true);
    }

    function updateExistingUserStats(address newUser, uint256 Mlimit, uint256 limitLeft, uint256 profit) external  onlyRole(ADMIN_ROLE) {
        require(!hasRole(USER_ROLE, newUser), "Controller: account not exists");
        uint256 _limit = Mlimit;
        userStats[newUser] = userStat(1, _limit, limitLeft, profit);
        emit  userStatsUpdated(userStats[newUser]);
    }

    function removeFromWhitelist(address user) external  onlyRole(ADMIN_ROLE) {
        require(hasRole(USER_ROLE, user), "Controller: account not exists");
        _revokeRole(USER_ROLE, user);
        emit removedFromWhitelist(user, true);
    }
}

contract FarziFundControllerV2 is FarziUserControllerV2 {

    struct ProfitParams {
        address tokenAddress;
        address userAddress;
        uint256 profitAmount;
        uint256 profitUSD;
        uint256 borrowedValueinUSD;
    }

    address public ADMIN;
    address public LOAN_PROVIDER_ADDRESS;

    event FUNDAddedToController(address token, uint256 amount);
    event ADMINRoleChanged(address prevAdmin, address newAdmin);
    event LOAN_PROVIDER_ADDRESS_ADDED(address prevProvider, address newProvider);
    event newPoolAdded(uint256 level, uint256 limit);
    event poolDataModified(uint256 level, uint256 newLimit);

    mapping(address => bool) internal blockedUsers;
    
    constructor(address adminaddress, uint256[] memory limits) FarziUserControllerV2(adminaddress, limits) {
        ADMIN = adminaddress;
        _grantRole(DEFAULT_ADMIN_ROLE, adminaddress);
    }

    function getBalance(address _tokenAddress) external view returns (uint256) {
        return IERC20(_tokenAddress).balanceOf(address(this));
    }

    function changeControllerAdmin(address newAdmin) external onlyRole(DEFAULT_ADMIN_ROLE) {
        require(newAdmin != address(0), "FarziController: amount should be greater than zero");
        _grantRole(DEFAULT_ADMIN_ROLE, newAdmin);
        _revokeRole(DEFAULT_ADMIN_ROLE, ADMIN);
        emit ADMINRoleChanged(ADMIN, newAdmin);
        ADMIN = newAdmin;
    }

    function addLOAN_PROVIDER(address provider) external onlyRole(ADMIN_ROLE) {
        require(provider != address(0), "FarziController: amount should be greater than zero");
        _grantRole(LOAN_PROVIDER, provider);
        _revokeRole(LOAN_PROVIDER, LOAN_PROVIDER_ADDRESS);
        emit ADMINRoleChanged(LOAN_PROVIDER_ADDRESS, provider);
        LOAN_PROVIDER_ADDRESS = provider;
    }

    function withdrawFunds(address token, uint256 amount) external  onlyRole(DEFAULT_ADMIN_ROLE) returns(bool) {
        require(amount !=0, "FarziController: amount should be greater than zero");
        bool status = IERC20(token).transfer(ADMIN, amount);
        emit FUNDAddedToController(token, amount);
        return  status;
    }

    function upgradeUserTradeLimit(address user, uint256 level) external onlyRole(ADMIN_ROLE) {
        require(checkUserRole(user), "FarziController: user must be in the whitelist");
        require(level >= 1 && level <= poolLength, "FarziUserStatsControllerV2: Invalid level");
        uint256 _limit = tradePoolDetails[level].maxLimit;
        userStats[user].currentLevel = level;
        userStats[user].maxLimit += _limit;
        userStats[user].limitLeft += _limit;
        emit userStatsUpdated(userStats[user]);
    }

    function transferProfit(ProfitParams calldata params) external onlyRole(LOAN_PROVIDER) returns(bool){
        require(params.profitAmount !=0, "FarziController: amount should be greater than zero");
        require(!blockedUsers[params.userAddress], "FarziController: Trade Blocked due to abnormal activity");
        require(userStats[params.userAddress].limitLeft >= params.borrowedValueinUSD, "FarziController: Trade Blocked due to inSufficient limit");
        bool status = IERC20(params.tokenAddress).transfer(params.userAddress, params.profitAmount);
        updateUserStats(params.userAddress, params.borrowedValueinUSD, params.profitUSD);
        return  status;
    }

    function blockUser(address user) external onlyRole(ADMIN_ROLE) returns(bool) {
        require(checkUserRole(user), "FarziController: user must be in the whitelist");
        blockedUsers[user] = true;
        emit userBlocked(user, true);
        return  true;
    }

    function unBlockUser(address user) external onlyRole(ADMIN_ROLE) returns(bool) {
        require(checkUserRole(user), "FarziController: user must be in the whitelist");
        blockedUsers[user] = false;
        emit userUnblocked(user, true);
        return  true;
    }

    function addNewPool(uint256 limit) external  onlyRole(DEFAULT_ADMIN_ROLE) {
        require(limit !=0, "FarziController: limit should be greater than zero");
        tradePoolDetails[poolLength+1] = tradePool(poolLength+1, limit);
        emit newPoolAdded(poolLength+1, limit);
    }

    function modifyPoollimit(uint256 level, uint256 limit) external onlyRole(DEFAULT_ADMIN_ROLE) {
        require(limit !=0, "FarziController: limit should be greater than zero");
        require(level >= 1 && level <= poolLength, "FarziUserStatsControllerV2: Invalid level");
        tradePoolDetails[level] = tradePool(level, limit);
        poolLength++;
        emit poolDataModified(level, limit);
    }

    function checkUserRole(address account) public view returns (bool) {
        return  hasRole(USER_ROLE, account);
    }

    function checkADMINRole(address account) public view returns (bool) {
        return  hasRole(DEFAULT_ADMIN_ROLE, account);
    }

}