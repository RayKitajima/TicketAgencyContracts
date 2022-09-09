//SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import "./Ticket.sol";
import "./Staff.sol";
import "./Utils.sol";

/**
 * @title Show
 *
 * @dev This is a facade contract for the Show service.
 * Paying for the ticket fee, giving a refund for the some reason,
 * managing the ticket info and managing the staffs are all done in this contract.
 */
contract Show {
    address public owner; // The owner of the show. (also the owner of Agency)

    Ticket ticketContract; // ticket management contract
    Staff staffContract; // staff management contract

    uint256 public showId; // The id of the show this show is for
    string public title; // The title of the show
    string public description; // The description of the show
    string public image; // The title image url of the show
    string public date; // ISO 8601 format
    string public openingTime; // ISO 8601 format
    string public closingTime; // ISO 8601 format
    Status public status; // The status of the show

    SeatType[] public seatTypes; // list of seat types, seatTypeId is the index in this array
    mapping(uint256 => Seat[]) public seats; // mapping from seatTypeId to seats array for each seat type

    uint256 public MAX_SEAT_TYPES = 256; // max number of seat types allowed in the show (default is 256)
    uint256 public MAX_SEATS = 5120; // max number of seats per seat type allowed in the seat type (default is 5120)
    uint256 public MAX_STAFFS = 1024; // max number of staffs allowed in the show (default is 1024)

    enum Status {
        Pendding, // The show is pending
        Scheduled, // The show is scheduled
        Ended, // The show is ended (not required to be in this status if the show is ended)
        Cancelled // The show is cancelled. once the show is cancelled, all the tickets are refunded
    }

    struct SeatType {
        uint256 id; // The id of the seat type, this is the index in the seatTypes array
        string name; // The name of the seat type. e.g. "Standard", "VIP", "Premium"
        uint256 price; // The price of the seat type. all the tickets of this seat type will be paid this amount of wei
        bool available; // true if seat type is available for booking
    }

    struct Seat {
        uint256 id; // The number in the seat type. This is the index in the seats array. You can identify the seat by seatTypeId and seatId. Usually, seatId is called seatNum in this application.
        string name; // The name of the seat. This is also unique in the show. e.g. "Standard 1", "VIP 1", "Premium 1"
        uint256 ticketId; // ticketId for this seat. 0 if seat is not booked. This is published by the OpenZeppelin Counter in the Ticket contract (ERC721)
        bool available; // true can be reserved, false can't be reserved
    }

    event ShowScheduled(uint256 indexed showId, string title, string date); // emitted when the show is scheduled
    event ShowCancelled(); // emitted when the show is cancelled

    error Unauthorized(); // error thrown when the caller is not the owner (agency)
    error ShowIsNotScheduled(); // show is not in scheduled status

    constructor(
        address _owner,
        uint256 _showId,
        string memory _title,
        string memory _description,
        string memory _image,
        string memory _date,
        string memory _openingTime,
        string memory _closingTime
    ) {
        owner = _owner;

        showId = _showId;
        title = _title;
        description = _description;
        image = _image;
        date = _date;
        openingTime = _openingTime;
        closingTime = _closingTime;

        status = Status.Pendding;

        ticketContract = new Ticket(this);
        staffContract = new Staff(this);
    }

    // MARK: modifiers

    modifier onlyOwner() {
        if (msg.sender != owner) {
            revert Unauthorized();
        }
        _;
    }

    modifier onlyScheduledShow() {
        if (status != Status.Scheduled) {
            revert ShowIsNotScheduled();
        }
        _;
    }

    modifier onlyExistingSeatType(uint256 _seatTypeId) {
        require(_seatTypeId < seatTypes.length, "Seat type does not exist");
        _;
    }

    modifier onlyAvailableSeatType(uint256 _seatTypeId) {
        require(_seatTypeId < seatTypes.length, "Seat type does not exist");
        require(seatTypes[_seatTypeId].available, "Seat type is not available");
        require(seatTypes[_seatTypeId].price > 0, "Seat price is zero");
        _;
    }

    modifier onlyExistingSeat(uint256 _seatTypeId, uint256 _seatNum) {
        require(_seatTypeId < seatTypes.length, "Seat type does not exist");
        require(_seatNum < seats[_seatTypeId].length, "Seat does not exist");
        _;
    }

    modifier onlyAvailableSeat(uint256 _seatTypeId, uint256 _seatNum) {
        require(_seatTypeId < seatTypes.length, "Seat type does not exist");
        require(_seatNum < seats[_seatTypeId].length, "Seat does not exist");
        require(
            seats[_seatTypeId][_seatNum].available,
            "Seat is not available"
        );
        _;
    }

    modifier validSeatTypePrice(uint256 _price) {
        require(_price > 0, "Seat price is zero");
        _;
    }

    modifier validSeatTypeName(string memory _name) {
        require(
            Utils.strlen(_name) > 0 && Utils.strlen(_name) <= 64,
            "Seat type name is not valid"
        );
        _;
    }

    modifier uniqueSeatTypeName(string memory _name) {
        for (uint256 i = 0; i < seatTypes.length; i++) {
            if (Utils.strcmp(seatTypes[i].name, _name)) {
                revert("Seat type name already used");
            }
        }
        _;
    }

    modifier enoughSpaceForNewSeatTypes(uint256 _numSeatTypes) {
        require(
            seatTypes.length + _numSeatTypes <= MAX_SEAT_TYPES,
            "No more space for new seat types"
        );
        _;
    }

    modifier validSeatName(string memory _name) {
        require(
            Utils.strlen(_name) > 0 && Utils.strlen(_name) <= 64,
            "Seat name cannot be longer than 32 characters"
        );
        _;
    }

    modifier uniqueSeatName(string memory _name) {
        for (uint256 i = 0; i < seatTypes.length; i++) {
            for (uint256 j = 0; j < seats[i].length; j++) {
                // the key seatTypeId is the index of seatTypes array
                if (Utils.strcmp(seats[i][j].name, _name)) {
                    revert("Seat name already used");
                }
            }
        }
        _;
    }

    modifier enoughSpaceForNewSeats(uint256 _seatTypeId, uint256 _numSeats) {
        require(
            seats[_seatTypeId].length + _numSeats <= MAX_SEATS,
            "Not enough space for new seats"
        );
        _;
    }

    modifier onlyStaff() {
        require(staffContract.isStaff(msg.sender));
        _;
    }

    // MARK: State management functions

    function transferOwnershipTo(address _newOwner) public onlyOwner {
        owner = _newOwner;
    }

    function setShowScheduled() public onlyOwner {
        require(status == Status.Pendding, "Show is not pending");
        status = Status.Scheduled;
        emit ShowScheduled(showId, title, date);
    }

    function updateTitle(string memory _title) public onlyOwner {
        title = _title;
    }

    function updateDescription(string memory _description) public onlyOwner {
        description = _description;
    }

    function updateImage(string memory _image) public onlyOwner {
        image = _image;
    }

    function updateDate(string memory _date) public onlyOwner {
        date = _date;
    }

    function updateOpeningTime(string memory _openingTime) public onlyOwner {
        openingTime = _openingTime;
    }

    function updateClosingTime(string memory _closingTime) public onlyOwner {
        closingTime = _closingTime;
    }

    function setMaxSeatTypes(uint256 _maxSeatTypes) public onlyOwner {
        MAX_SEAT_TYPES = _maxSeatTypes;
    }

    function setMaxSeats(uint256 _maxSeats) public onlyOwner {
        MAX_SEATS = _maxSeats;
    }

    function setMaxStaffs(uint256 _maxStaffs) public onlyOwner {
        MAX_STAFFS = _maxStaffs;
    }

    function addSeatType(string memory _name, uint256 _price)
        public
        onlyOwner
        validSeatTypeName(_name)
        uniqueSeatTypeName(_name)
        validSeatTypePrice(_price)
        returns (uint256)
    {
        uint256 seatTypeId = seatTypes.length;
        SeatType memory seatType = SeatType(seatTypeId, _name, _price, true);
        seatTypes.push(seatType);

        return seatTypeId;
    }

    function addSeatTypes(string[] calldata _names, uint256[] calldata _prices)
        public
        onlyOwner
        enoughSpaceForNewSeatTypes(_names.length)
        returns (uint256[] memory)
    {
        require(
            _names.length == _prices.length,
            "Number of seat type names and prices do not match"
        );
        require(
            _names.length > 0,
            "Number of seat type names and prices cannot be zero"
        );

        uint256[] memory seatTypeIds = new uint256[](_names.length);
        for (uint256 i = 0; i < _names.length; i++) {
            seatTypeIds[i] = addSeatType(_names[i], _prices[i]);
        }

        return seatTypeIds;
    }

    function getSeatTypes()
        public
        view
        returns (
            uint256[] memory,
            string[] memory,
            uint256[] memory,
            bool[] memory
        )
    {
        uint256[] memory seatTypeIds = new uint256[](seatTypes.length);
        string[] memory names = new string[](seatTypes.length);
        uint256[] memory prices = new uint256[](seatTypes.length);
        bool[] memory availables = new bool[](seatTypes.length);

        for (uint256 i = 0; i < seatTypes.length; i++) {
            seatTypeIds[i] = seatTypes[i].id;
            names[i] = seatTypes[i].name;
            prices[i] = seatTypes[i].price;
            availables[i] = seatTypes[i].available;
        }

        return (seatTypeIds, names, prices, availables);
    }

    function getSeatType(uint256 _seatTypeId)
        public
        view
        onlyExistingSeatType(_seatTypeId)
        returns (SeatType memory)
    {
        return seatTypes[_seatTypeId];
    }

    function getRawSeatTypes() public view returns (SeatType[] memory) {
        return seatTypes;
    }

    function getSeatTypesCount() public view returns (uint256) {
        return seatTypes.length;
    }

    function getSeatTypePrice(uint256 _seatTypeId)
        public
        view
        onlyExistingSeatType(_seatTypeId)
        returns (uint256)
    {
        return seatTypes[_seatTypeId].price;
    }

    function updateSeatTypeName(uint256 _seatTypeId, string memory _name)
        public
        onlyOwner
        onlyExistingSeatType(_seatTypeId)
        validSeatTypeName(_name)
        uniqueSeatTypeName(_name)
    {
        seatTypes[_seatTypeId].name = _name;
    }

    function updateSeatTypePrice(uint256 _seatTypeId, uint256 _price)
        public
        onlyOwner
        onlyExistingSeatType(_seatTypeId)
        validSeatTypePrice(_price)
    {
        seatTypes[_seatTypeId].price = _price;
    }

    function updateSeatTypeAvailability(uint256 _seatTypeId, bool _available)
        public
        onlyOwner
        onlyExistingSeatType(_seatTypeId)
    {
        seatTypes[_seatTypeId].available = _available;
    }

    function addSeat(uint256 _seatTypeId, string memory _name)
        public
        onlyOwner
        onlyExistingSeatType(_seatTypeId)
        validSeatName(_name)
        uniqueSeatName(_name)
        returns (uint256)
    {
        uint256 seatNum = seats[_seatTypeId].length;
        Seat memory seat = Seat(seatNum, _name, 0, true);
        seats[_seatTypeId].push(seat);

        return seatNum;
    }

    function addSeats(uint256 _seatTypeId, string[] calldata _names)
        public
        onlyOwner
        onlyExistingSeatType(_seatTypeId)
        enoughSpaceForNewSeats(_seatTypeId, _names.length)
        returns (uint256[] memory)
    {
        require(_names.length > 0, "No seats to add");

        uint256[] memory seatNums = new uint256[](_names.length);
        for (uint256 i = 0; i < _names.length; i++) {
            seatNums[i] = addSeat(_seatTypeId, _names[i]);
        }

        return seatNums;
    }

    function getSeat(uint256 _seatTypeId, uint256 _seatNum)
        public
        view
        onlyExistingSeatType(_seatTypeId)
        onlyExistingSeat(_seatTypeId, _seatNum)
        returns (Seat memory)
    {
        return seats[_seatTypeId][_seatNum];
    }

    function getSeats(uint256 _seatTypeId)
        public
        view
        onlyExistingSeatType(_seatTypeId)
        returns (
            uint256[] memory,
            string[] memory,
            uint256[] memory,
            bool[] memory
        )
    {
        uint256[] memory seatNums = new uint256[](seats[_seatTypeId].length);
        string[] memory names = new string[](seats[_seatTypeId].length);
        uint256[] memory ticketIds = new uint256[](seats[_seatTypeId].length);
        bool[] memory availables = new bool[](seats[_seatTypeId].length);

        for (uint256 i = 0; i < seats[_seatTypeId].length; i++) {
            seatNums[i] = seats[_seatTypeId][i].id;
            names[i] = seats[_seatTypeId][i].name;
            ticketIds[i] = seats[_seatTypeId][i].ticketId;
            availables[i] = seats[_seatTypeId][i].available;
        }

        return (seatNums, names, ticketIds, availables);
    }

    function getRawSeats(uint256 _seatTypeId)
        public
        view
        onlyExistingSeatType(_seatTypeId)
        returns (Seat[] memory)
    {
        return seats[_seatTypeId];
    }

    function getSeatsCount(uint256 _seatTypeId)
        public
        view
        onlyExistingSeatType(_seatTypeId)
        returns (uint256)
    {
        return seats[_seatTypeId].length;
    }

    function getSeatName(uint256 _seatTypeId, uint256 _seatNum)
        public
        view
        onlyExistingSeatType(_seatTypeId)
        onlyExistingSeat(_seatTypeId, _seatNum)
        returns (string memory)
    {
        return seats[_seatTypeId][_seatNum].name;
    }

    function updateSeatName(
        uint256 _seatTypeId,
        uint256 _seatNum,
        string memory _name
    )
        public
        onlyOwner
        onlyExistingSeatType(_seatTypeId)
        onlyExistingSeat(_seatTypeId, _seatNum)
        validSeatName(_name)
        uniqueSeatName(_name)
    {
        seats[_seatTypeId][_seatNum].name = _name;
    }

    function updateSeatAvailability(
        uint256 _seatTypeId,
        uint256 _seatNum,
        bool _available
    )
        public
        onlyOwner
        onlyExistingSeatType(_seatTypeId)
        onlyExistingSeat(_seatTypeId, _seatNum)
    {
        seats[_seatTypeId][_seatNum].available = _available;
    }

    // MARK: Staff management

    function addStaff(address _staff, string memory _name) public {
        staffContract.addStaff(_staff, _name);
    }

    function removeStaff(address _staff) public {
        staffContract.removeStaff(_staff);
    }

    function isStaff(address _staff) public view returns (bool) {
        return staffContract.isStaff(_staff);
    }

    function getStaffCount() public view returns (uint256) {
        return staffContract.getStaffCount();
    }

    function getStaffs() public view returns (address[] memory) {
        return staffContract.getStaffs();
    }

    function getStaffName(address _staff) public view returns (string memory) {
        return staffContract.getStaffName(_staff);
    }

    // MARK: Ticket management functions

    modifier validDestinationAddress(address _destination) {
        require(_destination != address(0), "Invalid destination address");
        require(_destination != address(this), "Invalid destination address");
        _;
    }

    modifier paidEnough(uint256 _price) {
        require(msg.value >= _price, "Not enought ether");
        _;
    }

    modifier paidEnoughForOffer(uint256 _ticketId) {
        require(
            msg.value >= ticketContract.getTicketPrice(_ticketId),
            "Not enought ether"
        );
        _;
    }

    function isSeatAvailable(uint256 _seatTypeId, uint256 _seatNum)
        public
        view
        onlyExistingSeatType(_seatTypeId)
        onlyExistingSeat(_seatTypeId, _seatNum)
        returns (bool)
    {
        return seats[_seatTypeId][_seatNum].available;
    }

    function buyTicket(
        uint256 _seatTypeId,
        uint256 _seatNum,
        string memory _buyerName
    )
        public
        payable
        onlyScheduledShow
        onlyAvailableSeatType(_seatTypeId)
        onlyAvailableSeat(_seatTypeId, _seatNum)
        validDestinationAddress(msg.sender)
        paidEnough(getSeatTypePrice(_seatTypeId))
        returns (uint256)
    {
        seats[_seatTypeId][_seatNum].available = false;

        uint256 tiekctId = ticketContract.createTicket(
            _seatTypeId,
            _seatNum,
            seats[_seatTypeId][_seatNum].name,
            seatTypes[_seatTypeId].price,
            _buyerName,
            msg.sender
        );

        seats[_seatTypeId][_seatNum].ticketId = tiekctId;

        // give a return value to the buyer if buyer paid more than the price of the ticket
        if (msg.value > seatTypes[_seatTypeId].price) {
            uint256 returnValue = msg.value - seatTypes[_seatTypeId].price;
            (bool sent, ) = payable(msg.sender).call{value: returnValue}("");
            require(sent, "Failed to send Ether");
        }

        return tiekctId;
    }

    function getTicketInfo(uint256 _ticketId)
        public
        view
        returns (Ticket.TicketInfo memory)
    {
        return ticketContract.getTicketInfo(_ticketId);
    }

    function existTicket(uint256 _ticketId) public view returns (bool) {
        return ticketContract.existTicket(_ticketId);
    }

    function offerTicket(uint256 _ticketId) public onlyScheduledShow {
        ticketContract.offerTicket(msg.sender, _ticketId);
    }

    function unofferTicket(uint256 _ticketId) public onlyScheduledShow {
        ticketContract.unofferTicket(msg.sender, _ticketId);
    }

    function getTradableTickets()
        public
        view
        returns (Ticket.TicketInfo[] memory)
    {
        uint256[] memory tradableTicketIds = ticketContract
            .getTradableTickets();
        Ticket.TicketInfo[] memory tradableTickets = new Ticket.TicketInfo[](
            tradableTicketIds.length
        );
        for (uint256 i = 0; i < tradableTicketIds.length; i++) {
            tradableTickets[i] = ticketContract.getTicketInfo(
                tradableTicketIds[i]
            );
        }
        return tradableTickets;
    }

    function buyOfferedTicket(uint256 _ticketId, string memory _buyerName)
        public
        payable
        onlyScheduledShow
        validDestinationAddress(msg.sender)
        paidEnough(ticketContract.getTicketPrice(_ticketId))
        returns (uint256)
    {
        Ticket.TicketInfo memory ticketInfo = ticketContract.getTicketInfo(
            _ticketId
        );

        uint256 tiekctId = ticketContract.buyOfferedTicket(
            _ticketId,
            msg.sender,
            _buyerName
        );

        seats[ticketInfo.seatTypeId][ticketInfo.seatNum].ticketId = tiekctId;

        // give a return value to the buyer if the buyer paid more than the price of the ticket
        if (msg.value > ticketInfo.price) {
            uint256 returnValue = msg.value - ticketInfo.price;
            (bool sent, ) = payable(msg.sender).call{value: returnValue}("");
            require(sent, "Failed to send Ether");
        }

        return tiekctId; // returned ticket id is the same as the one of the offered ticket
    }

    function cancelTicket(uint256 _ticketId) public onlyOwner {
        uint256 ticketPrice = ticketContract.cancelTicket(
            msg.sender,
            _ticketId
        );

        (bool sent, ) = payable(msg.sender).call{value: ticketPrice}("");
        require(sent, "Failed to send Ether");
    }

    // MARK: check-in management functions

    /**
     * This function is called by the admission staff or gatekeeper application to check-in a ticket.
     *
     * Check-in is simply to make sure that the person trying to enter has the correct ticket.
     * Thus, the same ticket can be checked in multiple times.
     *
     * For example, the admission staff can verify that the user has the correct ticket
     * by validating a QR code with the user's private key signature value of the number posted near the entrance.
     * This can be done without invoking a smart contract if the user's wallet works offline
     * and the admission staff has previously downloaded the list of ticket holder's public address locally.
     *
     * After the ticket is checked-in, the ticket is no longer tradable. (status is changed to "CheckedIn")
     */
    function checkIn(uint256 _ticketId) public onlyScheduledShow onlyStaff {
        ticketContract.checkIn(_ticketId);
    }

    // MARK: cancel show

    function cancelShow() public onlyOwner onlyScheduledShow {
        status = Status.Cancelled;

        for (uint256 i = 0; i < seatTypes.length; i++) {
            uint256 seatTypeId = i;
            seatTypes[seatTypeId].available = false;

            for (uint256 j = 0; j < seats[seatTypeId].length; j++) {
                uint256 seatNum = j;
                uint256 ticketId = seats[seatTypeId][seatNum].ticketId;

                if (ticketId != 0) {
                    Ticket.TicketInfo memory ticketInfo = ticketContract
                        .getTicketInfo(ticketId);
                    uint256 ticketPrice = ticketInfo.price;

                    (bool sent, ) = payable(ticketInfo.buyer).call{
                        value: ticketPrice
                    }("");
                    require(sent, "Failed to send Ether");
                }
            }
        }

        ticketContract.cancelAllTickets();

        emit ShowCancelled();
    }

    // MARK: withdraw

    function withdraw() public onlyOwner {
        uint256 balance = address(this).balance;
        (bool sent, ) = payable(msg.sender).call{value: balance}("");
        require(sent, "Failed to send Ether");
    }
}
