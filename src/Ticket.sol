//SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import "openzeppelin/contracts/utils/Counters.sol";
import "openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";

import "./Show.sol";
import "./Utils.sol";

/**
 * @title Ticket
 * @dev State changes in this contract can only be made by the Show (= contract owner)
 */
contract Ticket is ERC721 {
    address public immutable owner; // the owner of the contract (the show)

    using Counters for Counters.Counter;
    Counters.Counter private tokenID;

    Show show; // The Show this Ticket is for

    struct TicketInfo {
        uint256 ticketId; // the id of the ticket (called tokenId in this contract, called ticketId in the outside world)
        uint256 showId; // the id of the show this ticket is for ( = show.showId)
        uint256 seatTypeId; // the id of the seat type this ticket is for ( = seatType.id)
        uint256 seatNum; // the seat number this ticket is for ( = seat.seatNum)
        string seatName; // the seat name this ticket is for ( = seat.seatName)
        uint256 price; // the price of the ticket ( = seat.price)
        string date; // ISO 8601 format ( = show.date. YYYY-MM-DD, e.g. 2018-01-01, 2018-01-01T00:00:00Z)
        string openingTime; // ISO 8601 format ( = show.openingTime. e.g. 00:00:00, 00:00:00Z)
        string closingTime; // ISO 8601 format ( = show.closingTime. e.g. 00:00:00, 00:00:00Z)
        TicketStatus status; // TicketStatus of the ticket
        address buyer; // the buyer of the ticket
        string buyerName; // the name of the buyer, arbitrary name
        uint256 createdAt; // the timestamp when the ticket was created
        uint256 updatedAt; // the timestamp when the ticket was updated
    }

    enum TicketStatus {
        Ready, // ready to be used
        CheckedIn, // checked in
        Tradable // ready to be traded
    }

    address[] buyers; // list of all buyers
    mapping(address => uint256) private buyerToTokenId; // mapping from buyer to tokenId
    mapping(uint256 => TicketInfo) public ticketInfo; // mapping from tokenId to ticketInfo

    // utility struct for finding the index of buyer in buyers array
    struct FindBuyerResult {
        bool found;
        uint256 index;
    }

    function isBuyer(address _buyer) public view returns (bool) {
        FindBuyerResult memory findBuyerResult = findBuyer(_buyer);
        return findBuyerResult.found;
    }

    function findBuyer(address val)
        private
        view
        returns (FindBuyerResult memory)
    {
        for (uint256 i = 0; i < buyers.length; i++) {
            if (buyers[i] == val) {
                FindBuyerResult memory found = FindBuyerResult(true, i);
                return found;
            }
        }
        FindBuyerResult memory notfound = FindBuyerResult(false, 0);
        return notfound;
    }

    function removeBuyer(address _buyer) public onlyOwner {
        FindBuyerResult memory findBuyerResult = findBuyer(_buyer);
        if (findBuyerResult.found == false) {
            revert("Buyer not found");
        }
        uint256 index = findBuyerResult.index;
        if (buyers.length >= 256) {
            revert("invalid index");
        }
        for (uint256 i = index; i < buyers.length - 1; i++) {
            buyers[i] = buyers[i + 1];
        }
        buyers.pop();
    }

    function isTicketBuyer(uint256 _tokenId, address _caller)
        public
        view
        returns (bool)
    {
        if (buyerToTokenId[_caller] == _tokenId) {
            return true;
        }
        return false;
    }

    event TicketCreated(uint256 _tokenId);
    event TicketOffered(uint256 _tokenId);

    constructor(Show _show) ERC721("Ticket", "TICK") {
        owner = msg.sender;
        show = _show;
    }

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    modifier onlyExistingToken(uint256 _tokenId) {
        require(_exists(_tokenId), "Ticket does not exist");
        _;
    }

    modifier validBuyerName(string memory _name) {
        // check if name is empty
        require(Utils.strlen(_name) > 0, "Name is empty");
        require(Utils.strlen(_name) < 32, "Name is too long");
        _;
    }

    /**
     * Mint a new ticket for a show and seat to the buyer,
     * and store the ticket info in the ticketInfo mapping.
     * Then returns the token id (= ticket id) of the new ticket.
     *
     * Buyer can only buy one ticket per show.
     *
     * @param _seatTypeId the seat type id of the seat to buy ( = seatType.id)
     * @param _seatNum the seat number of the seat ( = seat.seatNum)
     * @param _seatName the seat name of the seat ( = seat.seatName)
     * @param _price the price of the ticket (in wei / 1e18) ( = seatType.price)
     * @param _buyerName the name of the buyer (arbitrary name)
     * @param _buyer the address of the buyer ( = msg.sender of Show.buyTicket)
     *
     * @return the token id of the new ticket
     */
    function createTicket(
        uint256 _seatTypeId,
        uint256 _seatNum,
        string memory _seatName,
        uint256 _price,
        string calldata _buyerName,
        address _buyer
    ) public onlyOwner returns (uint256) {
        tokenID.increment();
        uint256 tokenId = tokenID.current();

        _safeMint(_buyer, tokenId);

        buyers.push(_buyer);
        buyerToTokenId[_buyer] = tokenId;

        ticketInfo[tokenId] = TicketInfo(
            tokenId,
            show.showId(),
            _seatTypeId,
            _seatNum,
            _seatName,
            _price,
            show.date(),
            show.openingTime(),
            show.closingTime(),
            TicketStatus.Ready,
            _buyer,
            _buyerName,
            block.timestamp,
            block.timestamp
        );

        emit TicketCreated(tokenId);

        return tokenId;
    }

    function getTicketId(address _buyer) public view returns (uint256) {
        return buyerToTokenId[_buyer]; // ticketId = tokenId
    }

    function existTicket(uint256 _tokenId) public view returns (bool) {
        return _exists(_tokenId);
    }

    function getTicketInfo(uint256 _tokenId)
        public
        view
        onlyExistingToken(_tokenId)
        returns (TicketInfo memory)
    {
        return ticketInfo[_tokenId];
    }

    function getTicketPrice(uint256 _tokenId)
        public
        view
        onlyExistingToken(_tokenId)
        returns (uint256)
    {
        return ticketInfo[_tokenId].price;
    }

    function getBuyers() public view returns (address[] memory) {
        return buyers;
    }

    function updateTicketStatus(uint256 _tokenId, TicketStatus _status)
        public
        onlyOwner
    {
        require(_status == TicketStatus.Ready);
        ticketInfo[_tokenId].status = _status;
    }

    /**
     * @dev Cancel a ticket.
     *
     * Cancel a ticket, and emit the event Transfer (by OpenZeppelin ERC721).
     * Giving a refund to the buyer is a responsibility of the Show contract ( = caller).
     *
     * Buyer cannot cancel its ticket by itself, but can offer the ticket for sale.
     *
     * @param _tokenId the token id of the ticket to be cancelled ( = ticket id).
     */
    function cancelTicket(address _buyer, uint256 _tokenId)
        public
        onlyOwner
        onlyExistingToken(_tokenId)
        returns (uint256)
    {
        require(isTicketBuyer(_tokenId, _buyer), "Not a buyer");
        require(
            ticketInfo[_tokenId].status == TicketStatus.Ready,
            "Ticket is not ready"
        );

        uint256 ticketPrice = ticketInfo[_tokenId].price;
        require(ticketPrice > 0, "Ticket price is 0");

        _burn(_tokenId); // will emit Transfer event

        removeBuyer(_buyer);
        delete buyerToTokenId[_buyer];
        delete ticketInfo[_tokenId];

        return ticketPrice;
    }

    function cancelAllTickets() public onlyOwner {
        for (uint256 i = 0; i < buyers.length; i++) {
            cancelTicket(buyers[i], buyerToTokenId[buyers[i]]);
        }
    }

    // offer a ticket to be traded.
    function offerTicket(address _buyer, uint256 _tokenId) public {
        require(isTicketBuyer(_tokenId, _buyer), "Not a buyer");
        require(
            ticketInfo[_tokenId].status == TicketStatus.Ready,
            "Ticket is not ready"
        );
        ticketInfo[_tokenId].status = TicketStatus.Tradable;
        emit TicketOffered(_tokenId);
    }

    // unoffer a ticket to be traded.
    function unofferTicket(address _buyer, uint256 _tokenId) public {
        require(isTicketBuyer(_tokenId, _buyer));
        require(
            ticketInfo[_tokenId].status == TicketStatus.Tradable,
            "Ticket is not tradable"
        );
        ticketInfo[_tokenId].status = TicketStatus.Ready;
    }

    // get list of tradable tickets
    function getTradableTickets() public view returns (uint256[] memory) {
        uint256[] memory tradableTickets = new uint256[](buyers.length);
        uint256 count = 0;
        for (uint256 i = 0; i < buyers.length; i++) {
            uint256 tokenId = buyerToTokenId[buyers[i]];
            if (ticketInfo[tokenId].status == TicketStatus.Tradable) {
                tradableTickets[count] = tokenId;
                count++;
            }
        }
        return tradableTickets; // rest of the array is filled with 0
    }

    // buy an offered ticket.
    function buyOfferedTicket(
        uint256 _tokenId, // ticket id = token id to be bought
        address _newBuyer, // new buyer address
        string memory _newBuyerName // new buyer name. any name is ok.
    ) public validBuyerName(_newBuyerName) returns (uint256) {
        require(
            ticketInfo[_tokenId].status == TicketStatus.Tradable,
            "Ticket is not tradable"
        );
        require(
            ticketInfo[_tokenId].buyer != _newBuyer,
            "You cannot buy your own ticket"
        );
        require(_newBuyer != address(0), "invalid address");

        address originalBuyer = ticketInfo[_tokenId].buyer;

        ticketInfo[_tokenId].buyer = _newBuyer;
        ticketInfo[_tokenId].buyerName = _newBuyerName;
        ticketInfo[_tokenId].status = TicketStatus.Ready;
        ticketInfo[_tokenId].updatedAt = block.timestamp;

        _transfer(originalBuyer, ticketInfo[_tokenId].buyer, _tokenId); // will emit Transfer event

        return _tokenId; // put back the token id
    }

    function checkIn(uint256 _tokenId)
        public
        onlyExistingToken(_tokenId)
        returns (bool)
    {
        require(
            ticketInfo[_tokenId].status == TicketStatus.CheckedIn,
            "Ticket is already checked in"
        );

        ticketInfo[_tokenId].status = TicketStatus.CheckedIn;
        ticketInfo[_tokenId].updatedAt = block.timestamp;

        return true;
    }
}
