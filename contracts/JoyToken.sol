pragma solidity ^0.4.18;

import './token/StandardToken.sol';
import './ownership/Ownable.sol';

contract JoyToken is StandardToken, Ownable {
    string constant public name = "JOYSO";
    string constant public symbol = "JOY";
    uint8 constant public decimals = 6;
    bool public isLocked = true;

    function JoyToken(address joysoWallet) public {
        totalSupply = 4 * 10 ** (8+6);
        balances[joysoWallet] = totalSupply;
    }

    modifier illegalWhenLocked() {
        require(!isLocked || msg.sender == owner);
        _;
    }

    // should be called by JoysoCrowdSale when crowdSale is finished
    function unlock() onlyOwner {
        isLocked = false;
    }

    function transfer(address _to, uint256 _value) illegalWhenLocked public returns (bool) {
        return super.transfer(_to, _value);
    }

    function transferFrom(address _from, address _to, uint256 _value) illegalWhenLocked public returns (bool) {
        return super.transferFrom(_from, _to, _value);
    }
}