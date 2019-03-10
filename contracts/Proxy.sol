pragma solidity >=0.5.0;

import './Resolver.sol';
import 'openzeppelin-solidity/contracts/utils/Address.sol';
/**
 * @title Proxy
 * @dev Gives the possibility to delegate any call to a foreign implementation.
 */
 contract Proxy {

     bytes32 private constant IMPLEMENTATION_SLOT = keccak256(abi.encodePacked("implementation.address"));
     bytes32 private constant RESOLVER_SLOT = keccak256(abi.encodePacked("resolver.address"));


     // @dev Fallback function delegates call to implementing address
     function ()
     payable
     external {
         address _impl = Resolver(_resolver()).getUserVersion(msg.sender);
         require(_impl != address(0), "Implementing address can not be address 0x0");
         assembly {
             let ptr := mload(0x40)
             calldatacopy(ptr, 0, calldatasize)  // Copy incoming calldata
             let result := delegatecall(gas, _impl, ptr, calldatasize, 0, 0)
             let size := returndatasize
             returndatacopy(ptr, 0, size)

             switch result
             case 0 { revert(ptr, size) }
             default { return(ptr, size) }
         }
     }

     // @notice initializes the proxy with the initial implementation
     constructor(address implementation)
     public {
         require(implementation != address(0), "Implementing address must not be 0x0");
         require(Address.isContract(implementation));
         Resolver resolver = new Resolver(msg.sender);
         address res = address(resolver);
         bytes32 resolverSlot = RESOLVER_SLOT;
         bytes32 implementSlot = IMPLEMENTATION_SLOT;
         //solium-disable-next-line security/no-inline-assembly
         assembly {
             sstore(resolverSlot, res)
             sstore(implementSlot, implementation)
         }
         resolver.setValidImplementation(implementation, true);
         _setImplementation(implementation);
     }

     // @notice upgrades to new implementation
     function upgrade(address addr)
     public {
         address currentImplementation = _implementation();
         Resolver resolver = Resolver(_resolver());
         require(msg.sender == resolver.owner(), "Only owner can call");
         require(currentImplementation != address(0), "Must initialize Proxy first");
         // require(Address.isContract(implementation));
         resolver.setValidImplementation(addr, true);
         _setImplementation(addr);
     }

     function removeImplementation(address addr)
     public {
         require(addr != _implementation(), "Cannot remove the current implementation");
         Resolver resolver = Resolver(_resolver());
         require(msg.sender == resolver.owner());
         require(resolver.validImplementation(addr), "Must be a valid implementation being removed");
         resolver.setValidImplementation(addr, false);
     }

     // @notice Loads the implementation address from storage
     function _implementation()
     public
     view
     returns (address impl) {
         bytes32 implSpot = IMPLEMENTATION_SLOT;
         assembly {
           impl := sload(implSpot)
         }
     }

     // @notice Loads the resolver address from storage
     function _resolver()
     public
     view
     returns (address resolver) {
         bytes32 resolverSlot = RESOLVER_SLOT;
         assembly {
           resolver := sload(resolverSlot)
         }
     }

     function _setImplementation(address impl)
     internal {
         bytes32 implSpot = IMPLEMENTATION_SLOT;
         assembly {
             sstore(implSpot, impl)
         }
     }
 }
