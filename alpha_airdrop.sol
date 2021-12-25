// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity 0.7.5;

library SafeMath {

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        return c;
    }
}

library Address {

  function isContract(address account) internal view returns (bool) {
        // This method relies in extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        // solhint-disable-next-line no-inline-assembly
        assembly { size := extcodesize(account) }
        return size > 0;
    }

    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        return _functionCallWithValue(target, data, 0, errorMessage);
    }

    function _functionCallWithValue(address target, bytes memory data, uint256 weiValue, string memory errorMessage) private returns (bytes memory) {
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{ value: weiValue }(data);
        if (success) {
            return returndata;
        } else {
            if (returndata.length > 0) {
                // solhint-disable-next-line no-inline-assembly
                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }

    function _verifyCallResult(bool success, bytes memory returndata, string memory errorMessage) private pure returns(bytes memory) {
        if (success) {
            return returndata;
        } else {
            if (returndata.length > 0) {
                // solhint-disable-next-line no-inline-assembly
                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

interface IOwnable {
  function manager() external view returns (address);

  function renounceManagement() external;
  
  function pushManagement( address newOwner_ ) external;
  
  function pullManagement() external;
}

contract Ownable is IOwnable {

    address internal _owner;
    address internal _newOwner;

    event OwnershipPushed(address indexed previousOwner, address indexed newOwner);
    event OwnershipPulled(address indexed previousOwner, address indexed newOwner);

    constructor () {
        _owner = msg.sender;
        emit OwnershipPushed( address(0), _owner );
    }

    function manager() public view override returns (address) {
        return _owner;
    }

    modifier onlyManager() {
        require( _owner == msg.sender, "Ownable: caller is not the owner" );
        _;
    }

    function renounceManagement() public virtual override onlyManager() {
        emit OwnershipPushed( _owner, address(0) );
        _owner = address(0);
    }

    function pushManagement( address newOwner_ ) public virtual override onlyManager() {
        require( newOwner_ != address(0), "Ownable: new owner is the zero address");
        emit OwnershipPushed( _owner, newOwner_ );
        _newOwner = newOwner_;
    }
    
    function pullManagement() public virtual override {
        require( msg.sender == _newOwner, "Ownable: must be new owner to pull");
        emit OwnershipPulled( _owner, _newOwner );
        _owner = _newOwner;
    }
}

interface IERC20 {
    function decimals() external view returns (uint8);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount) external returns (bool);

    function approve(address spender, uint256 amount) external returns (bool);

    function totalSupply() external view returns (uint256);

    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed owner, address indexed spender, uint256 value);
}

library SafeERC20 {
    using SafeMath for uint256;
    using Address for address;

    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) { // Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

interface IStaking {
    function stake( uint _amount, address _recipient ) external returns ( bool );
    function claim ( address _recipient ) external;
}


contract AirDrop is Ownable {
  using SafeMath for uint;
  using SafeERC20 for IERC20;
  // This declares a state variable that would store the contract address
  address public domeaddress;
  address public sdomeaddress;
  address public stakingAddress;
  uint public epochs;
  uint public upfront; 
  uint public perEpochAmount;
  uint public domeEpochs;
  uint public previousStaked;
  uint public stakeAmount;
  
  address[] public MemberAddresses;
  address[] public AirdropPerms;
  mapping( address => bool ) public isAllowed;

  constructor(uint _epochs, uint _upfront) {
    epochs = _epochs;
    upfront = _upfront;
    previousStaked = 0;
    domeEpochs = 3;
    AirdropPerms.push(msg.sender);
    isAllowed[ msg.sender ] = true;
  }
    function viewEpochs() external view returns (uint) {
        return epochs;
    }

    function viewPEA() external view returns (uint) {
        return perEpochAmount;
    }

    function viewCount() external view returns (uint) {
        return MemberAddresses.length;
    }

    function registerAddresses(address[] calldata _memberAddresses) external onlyManager() {
        MemberAddresses = _memberAddresses;
    }
    function registerAirdropAddress(address _address) external onlyManager() {
        AirdropPerms.push(_address);
        isAllowed[ _address ] = true;
    }

    function airdrop(address _token, uint _amount, uint _count) internal {
        for (uint256 i = 0; i < _count; i++)
        {
            IERC20( _token ).safeTransfer( MemberAddresses[i], _amount.div(_count));
        }
    }

    function init_airdrop(address _domeaddress, uint _domeAmount, address _sdomeaddress, address _stakingAddress) external onlyManager() {
        sdomeaddress = _sdomeaddress;
        stakingAddress = _stakingAddress;
        domeaddress = _domeaddress;
        IERC20( domeaddress ).safeTransferFrom( msg.sender, address(this), _domeAmount );
        airdrop(domeaddress, _domeAmount.div(100).mul(upfront), MemberAddresses.length);
        uint bal = IERC20( domeaddress ).balanceOf(address(this));
        perEpochAmount = bal.div(epochs);
        stakeAmount = bal.sub(perEpochAmount.mul(domeEpochs));
        IERC20( domeaddress ).approve(stakingAddress, stakeAmount);
        IStaking (stakingAddress).stake(stakeAmount, address(this));
        previousStaked = stakeAmount;
    }

    function doAirDrop() external returns (bool) {
        require(isAllowed[msg.sender]);
        if(epochs>0) {
            epochs = epochs.sub(1);
        } else {
            kill();
        }
        if(domeEpochs != 0) {
            airdrop(domeaddress, perEpochAmount, MemberAddresses.length);
            domeEpochs = domeEpochs.sub(1);
            if(domeEpochs == 0 ) {
                IStaking (stakingAddress).claim(address(this));
            }
            return true;
        } 
        uint increase = IERC20( sdomeaddress ).balanceOf(address(this)).sub(previousStaked);
        airdrop(sdomeaddress, perEpochAmount.add(increase), MemberAddresses.length);
        previousStaked = IERC20( sdomeaddress ).balanceOf(address(this));
        return true;
    }

    function kill() internal {
        uint dBal = IERC20( domeaddress ).balanceOf(address(this));
        uint sBal = IERC20( sdomeaddress ).balanceOf(address(this));
        airdrop(domeaddress, dBal, MemberAddresses.length);
        airdrop(sdomeaddress, sBal, MemberAddresses.length);
        selfdestruct(payable(_owner));
    }
}
