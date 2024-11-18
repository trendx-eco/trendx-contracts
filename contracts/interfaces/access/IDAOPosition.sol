//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IDAOPosition {
    function getProjectPM(
        uint8 _role,
        uint256 _projectId
    ) external view returns (address); //Find the project party by project id

    function getProxyCode(
        uint8 _role,
        address _account,
        uint256 _projectId
    ) external view returns (bytes32); //Query the project invitation code of the specified account agent

    function getProxyNum(
        uint8 _role,
        address _account
    ) external view returns (uint256); //Query the number of agent items

    function getProxyByCode(
        uint8 _role,
        uint256 _projectId,
        bytes32 _code
    ) external view returns (address); //Find the agent address through the project's invitation code

    function checkIsProxy(
        uint8 _role,
        uint256 _projectId,
        address _proxyAddress
    ) external view returns (bool);
}
