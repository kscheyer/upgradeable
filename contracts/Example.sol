pragma solidity >=0.5.0;


contract Example {
    bytes32 public highestHash;

    // @notice if the sha3() hash of the string is higher than highest hash, replace highestHash with 'a'
    function setHighestHash(string memory a)
    public {
        bytes32 newHash = getSha3(a);
        require(newHash > highestHash);
        highestHash = newHash;
    }

    // @notice is 'a' higher than the current highest hash
    function isHighest(string memory a)
    public
    view
    returns (bool) {
        return getSha3(a) > highestHash;
    }

    function getSha3(string memory a)
    public
    pure
    returns (bytes32) {
        return keccak256(abi.encodePacked(a));
    }

    function getNullBytes()
    public
    pure
    returns (bytes32) {
    return bytes32(0);
    }

}

contract Example2 is Example {
    uint public nonce;

    // @notice adds the nonce variable to the storage hierarchy
    function setHighestHash(string memory a)
    public {
        bytes32 newHash = getSha3(a);
        require(newHash > highestHash);
        highestHash = newHash;
        nonce++;
    }

}

contract Example3 is Example2 {
    uint public fee;

    function setHighestHashPay(string memory a)
    public
    payable {
        require(msg.value == fee);
        setHighestHash(a);
    }

    function setHighestHash(string memory a)
    public {
        require(msg.sender == address(this));
        bytes32 newHash = getSha3(a);
        require(newHash > highestHash);
        highestHash = newHash;
        nonce++;
    }

}
