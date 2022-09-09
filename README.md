
# TicketForge

TicketForge is a smart contract that allows you to create ticketing service for your shows, concerts or any other kind of event. 

Event organizers create an agency contract for their series of shows, and then create show contracts for each show in the series. Each show contract has a set of seat types, and each seat type has a set of seats. Prices for each seat type are set by the event organizer, and then the event organizer sells tickets to the show through the show contract.

Main features are presented as a set of test by Forge. See the tests in [`test/`](test/) for more details.

## Note: Check-in 

Check-in function is called by the admission staff or gatekeeper application to check-in a ticket.

In this application, check-in is simply to make sure that the person trying to enter has the correct ticket. (In other words, the person sure has the ticket holder's private key.) Thus, the same ticket can be checked in multiple times until the show is over.

For example, the admission staff can verify that the user has the correct ticket by validating a QR code with the user's private key signature value of the number posted near the entrance. This can be done without invoking a smart contract if the user's wallet works offline and the admission staff has previously downloaded the list of ticket holder's public address locally.

After the ticket is checked-in, the ticket is no longer tradable. (status is changed to "CheckedIn")

## Note: Ticket resale

Ticket holders can offer their tickets for resale through the show contract by calling `Show#offerTicket` function. Anyone can buy the ticket by calling `Show#buyOfferedTicket` function with original ticket's ID and the price.

## Note: Ticket cancellation and refund

Ticket holders cannot cancel their tickets. However, the event organizer can cancel the show by calling `Show#cancel` function. This will cancel all the tickets and refund the ticket holders.


## Prerequisites

- [Foundry](https://github.com/foundry-rs/foundry) 


## Installation and Test

```bash
$ git clone --recurse-submodules https://github.com/RayKitajima/TicketForge.git
$ cd TicketForge
$ forge test -vvvv
```

# Contributing

Feel free to open an issue or a pull request!


# License

TicketForge is licensed under the MIT license. 

