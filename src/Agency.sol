//SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import "./Show.sol";

contract Agency {
    address public owner;

    string public title; // The title of the Agency
    string public description; // The description of the Agency
    string public image; // The title image url of the Agency

    Show[] public shows; // list of shows, showId is the index in this array

    struct ShowDigest {
        string title; // title of the show
        string description; // description of the show
        string image; // title image url of the show
        string date; // date of the show, ISO 8601 format
        string openingTime; // opening time of the show, ISO 8601 format
        string closingTime; // closing time of the show, ISO 8601 format
    }

    error Unauthorized(); // error thrown when the caller is not the owner
    error InvalidShowId(); // showId is not valid

    constructor(
        string memory _title,
        string memory _description,
        string memory _image
    ) {
        owner = msg.sender;

        title = _title;
        description = _description;
        image = _image;
    }

    modifier onlyOwner() {
        if (msg.sender != owner) {
            revert Unauthorized();
        }
        _;
    }

    modifier onlyExistingShow(uint256 _showId) {
        if (_showId >= shows.length) {
            revert InvalidShowId();
        }
        _;
    }

    function transferOwnershipTo(address _newOwner) public onlyOwner {
        owner = _newOwner;
    }

    function createShow(
        string memory _title,
        string memory _description,
        string memory _image,
        string memory _date,
        string memory _openingTime,
        string memory _closingTime
    ) public onlyOwner returns (uint256) {
        uint256 showId = shows.length;
        Show show = new Show(
            msg.sender,
            showId,
            _title,
            _description,
            _image,
            _date,
            _openingTime,
            _closingTime
        );
        shows.push(show);
        return showId;
    }

    function getShow(uint256 _showId)
        public
        view
        onlyExistingShow(_showId)
        returns (Show)
    {
        return shows[_showId];
    }

    function getShowCount() public view returns (uint256) {
        return shows.length;
    }

    function getShowAddress(uint256 _showId)
        public
        view
        onlyExistingShow(_showId)
        returns (address)
    {
        return address(shows[_showId]);
    }

    function getShowsDigests() public view returns (ShowDigest[] memory) {
        ShowDigest[] memory showDigests = new ShowDigest[](shows.length);

        for (uint256 i = 0; i < shows.length; i++) {
            ShowDigest memory digest;

            digest.title = shows[i].title();
            digest.description = shows[i].description();
            digest.image = shows[i].image();
            digest.date = shows[i].date();
            digest.openingTime = shows[i].openingTime();
            digest.closingTime = shows[i].closingTime();
            showDigests[i] = digest;
        }

        return showDigests;
    }

    function getShowDigest(uint256 _showId)
        public
        view
        onlyExistingShow(_showId)
        returns (ShowDigest memory)
    {
        ShowDigest memory digest;

        digest.title = shows[_showId].title();
        digest.description = shows[_showId].description();
        digest.image = shows[_showId].image();
        digest.date = shows[_showId].date();
        digest.openingTime = shows[_showId].openingTime();
        digest.closingTime = shows[_showId].closingTime();

        return digest;
    }

    // MARK: withdraw

    function withdraw() public onlyOwner {
        uint256 balance = address(this).balance;
        if (balance > 0) {
            (bool sent, ) = payable(msg.sender).call{value: balance}("");
            require(sent, "Failed to send Ether");
        }
    }
}
