//SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import "./Show.sol";
import "./Utils.sol";

/**
 * @title Staff
 * @dev Functions in this contract can only be called by the Show (= contract owner)
 */
contract Staff {
    address public immutable owner; // The owner of the contract (the Show)

    address[] staffs; // list of staffs. just a list of addresses. max length (staffs) is 256
    mapping(address => string) staffNames; // mapping of staff address to staff name

    Show show; // The Show this staffs is for

    // utility struct for finding the index of staff in the staffs array
    struct FindStaffResult {
        bool found;
        uint256 index;
    }

    constructor(Show _show) {
        owner = msg.sender;
        show = _show;
    }

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    modifier onlyStaff() {
        require(isStaff(msg.sender));
        _;
    }

    modifier validStaffName(string memory _name) {
        require(Utils.strlen(_name) > 0, "Name is empty");
        require(Utils.strlen(_name) < 32, "Name is too long");
        _;
    }

    function addStaff(address _staff, string memory _name)
        public
        onlyOwner
        validStaffName(_name)
    {
        // check overflow (max length is 256)
        if (staffs.length >= 256) {
            revert("Staffs array is full");
        }
        staffs.push(_staff);
        staffNames[_staff] = _name;
    }

    function removeStaff(address _staff) public onlyOwner {
        FindStaffResult memory findStaffResult = findStaff(_staff);
        if (findStaffResult.found == false) {
            revert("Staff not found");
        }
        uint256 index = findStaffResult.index;
        if (staffs.length >= 256) {
            revert("invalid index");
        }
        for (uint256 i = index; i < staffs.length - 1; i++) {
            staffs[i] = staffs[i + 1];
        }
        staffs.pop();
        delete staffNames[_staff];
    }

    function getStaffs() public view returns (address[] memory) {
        return staffs;
    }

    function getStaffName(address _staff) public view returns (string memory) {
        return staffNames[_staff];
    }

    function getStaffCount() public view returns (uint256) {
        return staffs.length;
    }

    function isStaff(address _staff) public view returns (bool) {
        FindStaffResult memory findStaffResult = findStaff(_staff);
        return findStaffResult.found;
    }

    function findStaff(address val)
        private
        view
        returns (FindStaffResult memory)
    {
        for (uint256 i = 0; i < staffs.length; i++) {
            if (staffs[i] == val) {
                FindStaffResult memory found = FindStaffResult(true, i);
                return found;
            }
        }
        FindStaffResult memory notfound = FindStaffResult(false, 0);
        return notfound;
    }
}
