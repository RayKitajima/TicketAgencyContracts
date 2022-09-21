// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.15;

import "forge-std/Test.sol";
import "openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";

import "../src/AgencyFactory.sol";
import "../src/Agency.sol";
import "../src/Ticket.sol";

/**
 * @dev Basic test contract for Ticket contract.
 */
contract TicketContractTest is Test, IERC721Receiver {
    address owner;

    Agency agencyContract;
    Ticket ticketContract;

    function setUp() public {
        owner = address(this);

        agencyContract = new Agency(
            "Agency",
            "Agency description",
            "https://agency.com/image.png"
        );
        uint256 showId = agencyContract.createShow(
            "My Show.0",
            "Show description",
            "https://show.com/image.png",
            "2018-01-01T09:00:00Z",
            "10:00",
            "20:00"
        );
        Show show = agencyContract.getShow(showId);
        vm.prank(owner);
        show.setShowScheduled();
        ticketContract = new Ticket(show);
    }

    function onERC721Received(
        address _operator,
        address _from,
        uint256 _tokenId,
        bytes memory _data
    ) public virtual override returns (bytes4) {
        //ERC721 nftContract = ERC721(msg.sender);
        uint256 tokenId = _tokenId;
        bool tokenAdded = true;

        console2.log(_operator);
        console2.log(_from);
        console2.log(tokenId);
        console2.log(string(_data));
        console2.log(tokenAdded);

        return this.onERC721Received.selector;
    }

    // test createTicket()
    function testCreateTicket() public {
        uint256 seatTypeId = 2;
        uint256 seatNum = 3;
        string memory seatName = "A";
        address buyer = msg.sender;
        uint256 tokenId = ticketContract.createTicket(
            seatTypeId,
            seatNum,
            seatName,
            100,
            "John Doe",
            buyer
        );
        assertEq(tokenId, 1, "tokenId should be 1");
        assertEq(
            ticketContract.getTicketInfo(tokenId).seatTypeId,
            seatTypeId,
            "seatTypeId should be 2"
        );
        assertEq(
            ticketContract.getTicketInfo(tokenId).seatNum,
            seatNum,
            "seatNum should be 3"
        );
        assertEq(
            ticketContract.getTicketInfo(tokenId).seatName,
            seatName,
            "seatName should be A"
        );
        assertFalse(
            !(ticketContract.getTicketInfo(tokenId).status ==
                Ticket.TicketStatus.Ready),
            "isAvailable should be true"
        );
    }

    function testGetTicketInfo() public {
        uint256 seatTypeId = 2;
        uint256 seatNum = 3;
        string memory seatName = "A"; // any string is fine here since we are not testing the seatName
        address buyer = msg.sender;
        uint256 tokenId = ticketContract.createTicket(
            seatTypeId,
            seatNum,
            seatName,
            100,
            "John Doe",
            buyer
        );

        assertEq(
            ticketContract.getTicketInfo(tokenId).seatTypeId,
            seatTypeId,
            "seatTypeId should be 2"
        );
        assertEq(
            ticketContract.getTicketInfo(tokenId).seatNum,
            seatNum,
            "seatNum should be 3"
        );
        assertEq(
            ticketContract.getTicketInfo(tokenId).seatName,
            seatName,
            "seatName should be A"
        );
        assertEq(
            ticketContract.getTicketInfo(tokenId).date,
            "2018-01-01T09:00:00Z",
            "date should be 2018-01-01T09:00:00Z"
        );
        assertEq(
            ticketContract.getTicketInfo(tokenId).openingTime,
            "10:00",
            "openingTime should be 10:00"
        );
        assertEq(
            ticketContract.getTicketInfo(tokenId).closingTime,
            "20:00",
            "closingTime should be 20:00"
        );
        assertEq(
            ticketContract.getTicketInfo(tokenId).buyer,
            buyer,
            "buyer should be msg.sender"
        );
        assertEq(
            ticketContract.getTicketInfo(tokenId).buyerName,
            "John Doe",
            "buyerName should be John Doe"
        );
        assertTrue(
            ticketContract.getTicketInfo(tokenId).status ==
                Ticket.TicketStatus.Ready,
            "status should be Ready"
        );
    }
}
