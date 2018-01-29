pragma solidity ^0.4.18;

import './token/ERC20Basic.sol';
import './math/SafeMath.sol';

contract JoyTokenAbstract {
  function unlock();
}

/**
 * @title Crowdsale
 * @dev Crowdsale is a base contract for managing a token crowdsale.
 * Crowdsales have a start and end timestamps, where investors can make
 * token purchases and the crowdsale will assign them tokens based
 * on a token per ETH rate. Funds collected are forwarded to a wallet
 * as they arrive.
 */
contract JoysoCrowdsale {
  using SafeMath for uint256;

  // The token being sold
  address constant public JOY = 0xDDe12a12A6f67156e0DA672be05c374e1B0a3e57;

  // start and end timestamps where investments are allowed (both inclusive)
  uint256 public startTime;
  uint256 public endTime;

  // address where funds are collected
  address public joysoWallet = 0xC640B901a529C58FB6f6C53665768E2d5c835421;

  // how many token units a buyer gets per wei
  uint256 public rate = 10000;

  // amount of raised money in wei
  uint256 public weiRaised;

  /**
   * event for token purchase logging
   * @param purchaser who paid for the tokens
   * @param beneficiary who got the tokens
   * @param value weis paid for purchase
   * @param amount amount of tokens purchased
   */
  event TokenPurchase(address indexed purchaser, address indexed beneficiary, uint256 value, uint256 amount);

  // fallback function can be used to buy tokens
  function () external payable {
    buyTokens(msg.sender);
  }

  // low level token purchase function
  function buyTokens(address beneficiary) public payable {
    require(beneficiary != address(0));
    require(validPurchase());

    // calculate token amount 
    uint256 joyAmounts = calculateObtainedJOY(msg.value);

    // update state
    weiRaised = weiRaised.add(msg.value);

    require(ERC20Basic(JOY).transfer(beneficiary, joyAmounts));
    TokenPurchase(msg.sender, beneficiary, msg.value, joyAmounts);

    forwardFunds();
  }

  // send ether to the fund collection wallet
  // override to create custom fund forwarding mechanisms
  function forwardFunds() internal {
    joysoWallet.transfer(msg.value);
  }

  function calculateObtainedJOY(uint256 amountEtherInWei) public view returns (uint256) {
    return amountEtherInWei.mul(rate).div(10 ** 12);
  } 

  // @return true if the transaction can buy tokens
  function validPurchase() internal view returns (bool) {
    bool withinPeriod = now >= startTime && now <= endTime;
    return withinPeriod;
  }

  // @return true if crowdsale event has ended
  function hasEnded() public view returns (bool) {
    bool isEnd = now > endTime || weiRaised == 2000000000000000;
    return isEnd;
  }

  // only admin 
  function releaseJoyToken() public returns (bool) {
    require (hasEnded() && startTime != 0);
    require (msg.sender == joysoWallet || now > endTime + 10 days);
    uint256 remainedJoy = ERC20Basic(JOY).balanceOf(this);
    require(ERC20Basic(JOY).transfer(joysoWallet, remainedJoy));    
    JoyTokenAbstract(JOY).unlock();
  }

  // be sure to get the joy token ownerships
  function start() public returns (bool) {
    require (msg.sender == joysoWallet);
    startTime = now;
    endTime = now + 1 hours;
  }

  function changeJoysoWallet(address _joysoWallet) public returns (bool) {
    require (msg.sender == joysoWallet);
    joysoWallet = _joysoWallet;
  }
}
