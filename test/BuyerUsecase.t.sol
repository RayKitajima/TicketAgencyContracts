//SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import "forge-std/Test.sol";
import "openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "openzeppelin/contracts/utils/Strings.sol";

import "../src/Agency.sol";
import "../src/Show.sol";
import "../src/Ticket.sol";

import "./MusicFes.sol";
import "./Buyer.sol";

contract BuyerUsecaseTest is Test {
    address owner;

    MusicFes fesContract;
    Agency agencyContract;

    function setUp() public {
        owner = address(this);
        fesContract = new MusicFes(vm, owner);
        agencyContract = fesContract.agencyContract();
        
        fesContract.deploy();

        vm.deal(address(agencyContract), 100 ether);
        vm.deal(address(fesContract), 100 ether);
        vm.deal(address(this), 100 ether);
        
        fesContract.setAllShowsScheduled();
    }

    function testBuyTicket() public {
        uint256 showId = 0;
        uint256 seatTypeId1 = 0;
        uint256 seatTypeId2 = 1;
        uint256 seatNum1 = 0;
        uint256 seatNum2 = 1;

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
            "balance should be 100 ether - seatTypePrice1"
        );

        // start another buyer usecase
        Buyer buyer2 = new Buyer(agencyContract, "Sam Smith");
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
    }

    function testResaleTicket() public {
        uint256 showId = 0;
        uint256 seatTypeId = 0;
        uint256 seatNum = 2;

        Show show = agencyContract.getShow(showId);

        Buyer buyer1 = new Buyer(agencyContract, "John Doe");
        vm.deal(address(buyer1), 100 ether);

        uint256 seatTypePrice = show.getSeatTypePrice(seatTypeId);

        buyer1.buyTicket(showId, seatTypeId, seatNum, seatTypePrice);
        Ticket.TicketInfo memory ticketInfo = buyer1.getTicketInfo();
        uint256 ticketId = ticketInfo.ticketId;
        assertEq(ticketId, 1, "ticketId should be 1");

        buyer1.offerTicket();

        Ticket.TicketInfo memory ticketInfo2 = buyer1.getTicketInfo();
        assertTrue(
            ticketInfo2.status == Ticket.TicketStatus.Tradable,
            "status should be Tradable"
        );

        Buyer buyer2 = new Buyer(agencyContract, "Steve Doe");
        vm.deal(address(buyer2), 100 ether);

        // get offered ticket
        buyer2.buyOfferedTicket(showId, ticketId, seatTypePrice);

        Ticket.TicketInfo memory tradedTicketInfo = buyer2.getTicketInfo();
        uint256 tradedTicketId = tradedTicketInfo.ticketId;
        assertEq(tradedTicketId, 1, "ticketId should be also 1");
        // check balance of address(buyer2)
        assertEq(
            address(buyer2).balance,
            100 ether - seatTypePrice,
            string(
                abi.encodePacked(
                    "balance of buyer2 is unexpected : ",
                    Strings.toString(address(buyer2).balance)
                )
            )
        );
    }

    function testCancelTicket() public {
        uint256 showId = 0;
        uint256 seatTypeId = 0;
        uint256 seatNum = 3;

        Show show = agencyContract.getShow(showId);

        Buyer buyer1 = new Buyer(agencyContract, "John Doe");
        vm.deal(address(buyer1), 100 ether);

        uint256 seatTypePrice = show.getSeatTypePrice(seatTypeId);

        buyer1.buyTicket(showId, seatTypeId, seatNum, seatTypePrice);
        Ticket.TicketInfo memory ticketInfo = buyer1.getTicketInfo();
        uint256 ticketId = ticketInfo.ticketId;
        assertEq(ticketId, 1, "ticketId should be 1");
        assertTrue(buyer1.hasTicket(), "buyer1 should have ticket");
        assertEq(
            address(buyer1).balance,
            100 ether - seatTypePrice,
            string(
                abi.encodePacked(
                    "balance of buyer1 is unexpected : ",
                    Strings.toString(address(buyer1).balance)
                )
            )
        );

        vm.expectRevert(Show.Unauthorized.selector);
        buyer1.cancelTicket(); // only owner can cancel ticket

        assertTrue(buyer1.hasTicket(), "buyer1 should have ticket"); // cannot cancel ticket

        assertEq(
            address(buyer1).balance,
            100 ether - seatTypePrice, // no refund
            string(
                abi.encodePacked(
                    "balance of buyer1 is unexpected : ",
                    Strings.toString(address(buyer1).balance)
                )
            )
        );
    }
}
