//SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import "forge-std/Test.sol";
import "openzeppelin/contracts/utils/Strings.sol";

import "../src/Agency.sol";
import "../src/Show.sol";
import "../src/Ticket.sol";

import "./MusicFes.sol";
import "./Buyer.sol";

contract WithdrawTest is Test {
    address owner;

    MusicFes fesContract;
    Agency agencyContract;

    function setUp() public {
        owner = address(this);

        fesContract = new MusicFes(vm, owner);
        vm.deal(address(fesContract), 100 ether);
        fesContract.setup();

        agencyContract = fesContract.agencyContract();
        vm.deal(address(agencyContract), 100 ether);
        
        vm.deal(address(this), 100 ether);
        
        fesContract.deploy();

        fesContract.setAllShowsScheduled();
    }

    receive() external payable {}

    fallback() external payable {}

    function testWithdrawFromAgency() public {
        uint256 showId = 0;
        uint256 seatTypeId1 = 0;
        uint256 seatNum1 = 4;

        Show show = agencyContract.getShow(showId);

        // start buyer usecase
        Buyer buyer1 = new Buyer(agencyContract, "John Doe");
        vm.deal(address(buyer1), 100 ether);
        uint256 seatTypePrice1 = show.getSeatTypePrice(seatTypeId1);
        buyer1.buyTicket(showId, seatTypeId1, seatNum1, seatTypePrice1);
        Ticket.TicketInfo memory ticketInfo = buyer1.getTicketInfo();
        uint256 ticketId = ticketInfo.ticketId;
        assertEq(ticketId, 1, "ticketId should be 1");

        // check balance of buyer1
        assertEq(
            address(buyer1).balance,
            100 ether - seatTypePrice1,
            string(
                abi.encodePacked(
                    "address(buyer1).balance should be ",
                    Strings.toString(100 ether - seatTypePrice1)
                )
            )
        );

        // check balance of agency
        assertEq(
            address(agencyContract).balance,
            100 ether, // no change
            string(
                abi.encodePacked(
                    "address(agencyContract).balance should be ",
                    Strings.toString(100 ether + seatTypePrice1)
                )
            )
        );

        // check balance of show
        assertEq(
            address(show).balance,
            seatTypePrice1, // buyer1's ticket price
            string(
                abi.encodePacked(
                    "address(show).balance should be ",
                    Strings.toString(0 ether)
                )
            )
        );

        // check balance of owner
        assertEq(
            owner.balance,
            100 ether, // no change
            string(
                abi.encodePacked(
                    "owner.balance should be ",
                    Strings.toString(100 ether)
                )
            )
        );

        // withdraw from show
        show.withdraw();

        // check balance of buyer1
        assertEq(
            address(buyer1).balance,
            100 ether - seatTypePrice1, // decrease by seatTypePrice1
            string(
                abi.encodePacked(
                    "address(buyer1).balance should be ",
                    Strings.toString(100 ether - seatTypePrice1)
                )
            )
        );

        // check balance of agency
        assertEq(
            address(agencyContract).balance,
            100 ether, // no change
            string(
                abi.encodePacked("address(agencyContract).balance should be 0")
            )
        );

        // check balance of show
        assertEq(
            address(show).balance,
            0 ether, // all withdrawn
            string(abi.encodePacked("address(show).balance should be 0"))
        );

        // check balance of owner
        assertEq(
            owner.balance,
            100 ether + seatTypePrice1, // increase by seatTypePrice1 (withdrawn from show)
            string(
                abi.encodePacked(
                    "owner.balance should be ",
                    Strings.toString(100 ether + seatTypePrice1)
                )
            )
        );

        // withdraw from agency
        agencyContract.withdraw();

        // check balance of buyer1
        assertEq(
            address(buyer1).balance,
            100 ether - seatTypePrice1, // no change (same as before)
            string(
                abi.encodePacked(
                    "address(buyer1).balance should be ",
                    Strings.toString(100 ether - seatTypePrice1)
                )
            )
        );

        // check balance of agency
        assertEq(
            address(agencyContract).balance,
            0 ether, // all withdrawn
            string(
                abi.encodePacked("address(agencyContract).balance should be 0")
            )
        );

        // check balance of show
        assertEq(
            address(show).balance,
            0 ether, // no change (same as before)
            string(abi.encodePacked("address(show).balance should be 0"))
        );

        // check balance of owner
        assertEq(
            owner.balance,
            100 ether + 100 ether + seatTypePrice1, // increase by 100 ether (withdrawn from agency)
            string(
                abi.encodePacked(
                    "owner.balance should be ",
                    Strings.toString(100 ether + seatTypePrice1)
                )
            )
        );
    }
}
