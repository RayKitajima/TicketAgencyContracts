//SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import "forge-std/Test.sol";

import "../src/AgencyFactory.sol";
import "../src/Agency.sol";
import "../src/Show.sol";

import "./MusicFes.sol";

contract StaffTest is Test {
    address owner;

    MusicFes fesContract;
    AgencyFactory agencyFactoryContract;
    Agency agencyContract;

    function setUp() public {
        owner = address(this);
        agencyFactoryContract = new AgencyFactory();

        fesContract = new MusicFes(vm, owner, agencyFactoryContract);
        vm.deal(address(fesContract), 100 ether);
        fesContract.setup();

        agencyContract = fesContract.agencyContract();
        vm.deal(address(agencyContract), 100 ether);
        
        vm.deal(address(this), 100 ether);
        
        fesContract.deploy();

        fesContract.setAllShowsScheduled();
    }

    function testAddStaff() public {
        uint256 showId = 0;
        Show show = agencyContract.getShow(showId);

        // add staff

        address staffAddress = address(1234);
        vm.prank(owner);
        show.addStaff(staffAddress, "John Doe");

        // check staff count
        uint256 staffCountBefore = show.getStaffCount();
        assertEq(staffCountBefore, 1, "staffCount should be 1");

        // check registered staff name
        string memory staffName = show.getStaffName(staffAddress);
        assertEq(staffName, "John Doe", "staff name should be John Doe");

        // remove staff
        show.removeStaff(staffAddress);

        // check removed staff name
        staffName = show.getStaffName(staffAddress);
        assertEq(staffName, "", "staff name should be empty");

        // check staff count
        uint256 staffCountAfter = show.getStaffCount();
        assertEq(staffCountAfter, 0, "staff count should be 0");
    }
}
