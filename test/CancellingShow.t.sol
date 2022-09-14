//SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import "forge-std/Test.sol";
import "openzeppelin/contracts/utils/Strings.sol";

import "../src/Agency.sol";
import "../src/Show.sol";
import "../src/Ticket.sol";

import "./MusicFes.sol";
import "./Buyer.sol";

contract CancellingShowTest is Test {
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

    function testCancelShow() public {
        uint256 showId = 0;
        uint256 seatTypeId1 = 0;
        uint256 seatTypeId2 = 1;
        uint256 seatNum1 = 4;
        uint256 seatNum2 = 5;

        Show show = agencyContract.getShow(showId);

        // start buyer usecase
        Buyer buyer1 = new Buyer(agencyContract, "John Doe");
        vm.deal(address(buyer1), 100 ether);
        uint256 seatTypePrice1 = show.getSeatTypePrice(seatTypeId1);
        buyer1.buyTicket(showId, seatTypeId1, seatNum1, seatTypePrice1);
        Ticket.TicketInfo memory ticketInfo = buyer1.getTicketInfo();
        uint256 ticketId = ticketInfo.ticketId;
        assertEq(ticketId, 1, "ticketId should be 1");

        // check balance of address(buyer1)
        assertEq(
            address(buyer1).balance,
            100 ether - seatTypePrice1,
            string(
                abi.encodePacked(
                    "balance of buyer1 is unexpected : ",
                    Strings.toString(address(buyer1).balance)
                )
            )
        );

        // start another buyer usecase
        Buyer buyer2 = new Buyer(agencyContract, "Jane Doe");
        vm.deal(address(buyer2), 100 ether);
        uint256 seatTypePrice2 = show.getSeatTypePrice(seatTypeId2);
        // will refund seatTypePrice2
        buyer2.buyTicket(
            showId,
            seatTypeId2,
            seatNum2,
            seatTypePrice2 + seatTypePrice2
        );
        Ticket.TicketInfo memory ticketInfo2 = buyer2.getTicketInfo();
        uint256 ticketId2 = ticketInfo2.ticketId;
        assertEq(ticketId2, 2, "ticketId should be 2");

        // check balance of address(buyer2)
        assertEq(
            address(buyer2).balance,
            100 ether - seatTypePrice2,
            string(
                abi.encodePacked(
                    "balance of buyer2 is unexpected : ",
                    Strings.toString(address(buyer2).balance)
                )
            )
        );

        // cancel show
        vm.startPrank(owner);
        show.cancelShow();
        vm.stopPrank();

        // check availability of seat type
        assertEq(
            show.getSeatType(seatTypeId1).available,
            false,
            "seat type should be available"
        );

        // check balance of address(buyer1)
        assertEq(
            address(buyer1).balance,
            100 ether,
            string(
                abi.encodePacked(
                    "balance of buyer1 is unexpected (not refunded) : ",
                    Strings.toString(address(buyer1).balance)
                )
            )
        );
        // check balance of address(buyer2)
        assertEq(
            address(buyer2).balance,
            100 ether,
            string(
                abi.encodePacked(
                    "balance of buyer2 is unexpected (not refunded) : ",
                    Strings.toString(address(buyer2).balance)
                )
            )
        );
    }
}
