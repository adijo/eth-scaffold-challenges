pragma solidity >=0.6.0 <0.7.0;

import "hardhat/console.sol";
import "./ExampleExternalContract.sol"; //https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/access/Ownable.sol

contract Staker {

  ExampleExternalContract public exampleExternalContract;
  uint256 public constant threshold = 1 ether;
  mapping(address => uint256) public balances;
  uint256 public deadline = now + 30 seconds;
  bool public openForWithdraw = false;

  event Stake(address indexed _from, uint256 _amount);
  
  constructor(address exampleExternalContractAddress) public {
    exampleExternalContract = ExampleExternalContract(exampleExternalContractAddress);
  }

  // Collect funds in a payable `stake()` function and track individual `balances` with a mapping:
  //  ( make sure to add a `Stake(address,uint256)` event and emit it for the frontend <List/> display )
  function stake() public payable isDeadlineUp {
    require(msg.value > 0, "amount should be greater than 0");

    emit Stake(msg.sender, msg.value);
    // You can stake more than once.
    balances[msg.sender] += msg.value;
  
  }

  // After some `deadline` allow anyone to call an `execute()` function
  //  It should either call `exampleExternalContract.complete{value: address(this).balance}()` to send all the value
  function execute() public isDeadlineUp notCompleted {

    if(timeLeft() > 0 && address(this).balance >= threshold) {
        exampleExternalContract.complete{value: address(this).balance}();
    }
    else {
      openForWithdraw = true;
    }

  }


  // if the `threshold` was not met, allow everyone to call a `withdraw()` function
  function withdraw() public isDeadlineUp notCompleted {
      require(openForWithdraw, "Wait until transaction deadline to withdraw");

      msg.sender.call{value: address(this).balance}(" ");

  }


  function timeLeft() public view returns (uint256) {
    if(now < deadline) {
      return deadline - now;
    }
    else {
      return 0;
    }
  }

  modifier isDeadlineUp() {
    require(now < deadline, "Deadline is up");
    _;
  }

  modifier notCompleted() {
    require(!exampleExternalContract.completed(), "Contract should not be completed");
    _;
  }


}
