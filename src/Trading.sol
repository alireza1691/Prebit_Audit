// SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;

import './Ownable.sol';
import './SafeMath.sol';
import './IERC20.sol';


// Interfaces

interface IPrebitReferrals {
    function generateReferralCode(uint256 _parentCode) external;

    function generateReferralCodeWithContract(
        uint256 _parentCode,
        address _user
    ) external;

    function userReferralCode(address _user)
        external
        view
        returns (
            uint256,
            address,
            address,
            bool
        );

    function referralCodeToAddress(uint256 _referralCode)
        external
        view
        returns (address);

    function userReferralCodeCheck(address _user) external view returns (bool);

    function userReferralCodeToAddress(uint256 _code)
        external
        view
        returns (address);

    function getUserTparent(address _user) external view returns (address);

    function getUserParent(address _user) external view returns (address);

    function isContractAllowed(address _contractAddress)
        external
        view
        returns (bool);
}

abstract contract Pausable is Context {
    bool private _paused;

    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    /**
     * @dev The operation failed because the contract is paused.
     */
    error EnforcedPause();

    /**
     * @dev The operation failed because the contract is not paused.
     */
    error ExpectedPause();

    /**
     * @dev Initializes the contract in unpaused state.
     */
    constructor() {
        _paused = false;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        _requireNotPaused();
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        _requirePaused();
        _;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Throws if the contract is paused.
     */
    function _requireNotPaused() internal view virtual {
        if (paused()) {
            revert EnforcedPause();
        }
    }

    /**
     * @dev Throws if the contract is not paused.
     */
    function _requirePaused() internal view virtual {
        if (!paused()) {
            revert ExpectedPause();
        }
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements: 
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }
}


abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant NOT_ENTERED = 1;
    uint256 private constant ENTERED = 2;

    uint256 private _status;

    /**
     * @dev Unauthorized reentrant call.
     */
    error ReentrancyGuardReentrantCall();

    constructor() {
        _status = NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        _nonReentrantBefore();
        _;
        _nonReentrantAfter();
    }

    function _nonReentrantBefore() private {
        // On the first call to nonReentrant, _status will be NOT_ENTERED
        if (_status == ENTERED) {
            revert ReentrancyGuardReentrantCall();
        }

        // Any calls to nonReentrant after this point will fail
        _status = ENTERED;
    }

    function _nonReentrantAfter() private {
        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = NOT_ENTERED;
    }

    /**
     * @dev Returns true if the reentrancy guard is currently set to "entered", which indicates there is a
     * `nonReentrant` function in the call stack.
     */
    function _reentrancyGuardEntered() internal view returns (bool) {
        return _status == ENTERED;
    }
}

library Address {
    /**
     * @dev The ETH balance of the account is not enough to perform the operation.
     */
    error AddressInsufficientBalance(address account);

    /**
     * @dev There's no code at `target` (it is not a contract).
     */
    error AddressEmptyCode(address target);

    /**
     * @dev A call to an address target failed. The target may have reverted.
     */
    error FailedInnerCall();

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://consensys.net/diligence/blog/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.8.20/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        if (address(this).balance < amount) {
            revert AddressInsufficientBalance(address(this));
        }

        (bool success, ) = recipient.call{value: amount}("");
        if (!success) {
            revert FailedInnerCall();
        }
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason or custom error, it is bubbled
     * up by this function (like regular Solidity function calls). However, if
     * the call reverted with no returned reason, this function reverts with a
     * {FailedInnerCall} error.
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        if (address(this).balance < value) {
            revert AddressInsufficientBalance(address(this));
        }
        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResultFromTarget(target, success, returndata);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResultFromTarget(target, success, returndata);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResultFromTarget(target, success, returndata);
    }

    /**
     * @dev Tool to verify that a low level call to smart-contract was successful, and reverts if the target
     * was not a contract or bubbling up the revert reason (falling back to {FailedInnerCall}) in case of an
     * unsuccessful call.
     */
    function verifyCallResultFromTarget(
        address target,
        bool success,
        bytes memory returndata
    ) internal view returns (bytes memory) {
        if (!success) {
            _revert(returndata);
        } else {
            // only check if target is a contract if the call was successful and the return data is empty
            // otherwise we already know that it was a contract
            if (returndata.length == 0 && target.code.length == 0) {
                revert AddressEmptyCode(target);
            }
            return returndata;
        }
    }

    /**
     * @dev Tool to verify that a low level call was successful, and reverts if it wasn't, either by bubbling the
     * revert reason or with a default {FailedInnerCall} error.
     */
    function verifyCallResult(bool success, bytes memory returndata) internal pure returns (bytes memory) {
        if (!success) {
            _revert(returndata);
        } else {
            return returndata;
        }
    }

    /**
     * @dev Reverts with returndata if present. Otherwise reverts with {FailedInnerCall}.
     */
    function _revert(bytes memory returndata) private pure {
        // Look for revert reason and bubble it up if present
        if (returndata.length > 0) {
            // The easiest way to bubble the revert reason is using memory via assembly
            /// @solidity memory-safe-assembly
            assembly {
                let returndata_size := mload(returndata)
                revert(add(32, returndata), returndata_size)
            }
        } else {
            revert FailedInnerCall();
        }
    }
}
interface IERC20Permit {
    /**
     * @dev Sets `value` as the allowance of `spender` over ``owner``'s tokens,
     * given ``owner``'s signed approval.
     *
     * IMPORTANT: The same issues {IERC20-approve} has related to transaction
     * ordering also apply here.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `deadline` must be a timestamp in the future.
     * - `v`, `r` and `s` must be a valid `secp256k1` signature from `owner`
     * over the EIP712-formatted function arguments.
     * - the signature must use ``owner``'s current nonce (see {nonces}).
     *
     * For more information on the signature format, see the
     * https://eips.ethereum.org/EIPS/eip-2612#specification[relevant EIP
     * section].
     */
    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    /**
     * @dev Returns the current nonce for `owner`. This value must be
     * included whenever a signature is generated for {permit}.
     *
     * Every successful call to {permit} increases ``owner``'s nonce by one. This
     * prevents a signature from being used multiple times.
     */
    function nonces(address owner) external view returns (uint256);

    /**
     * @dev Returns the domain separator used in the encoding of the signature for {permit}, as defined by {EIP712}.
     */
    // solhint-disable-next-line func-name-mixedcase
    function DOMAIN_SEPARATOR() external view returns (bytes32);
}



contract PrebitTrading is Ownable, Pausable, ReentrancyGuard {
    
    using SafeMath for uint256;
  // Token used for purchasing 
     IERC20 public payToken;
   
    IPrebitReferrals public referralContract;
  
    bool public genesisLockOnce = false;
    bool public genesisStartOnce = false;

    address public operatorAddress; // address of the operator
    address public treasuryAddress;
    uint256 public intervalSeconds=300; // interval in seconds between two prediction rounds

    uint256 public minPosition; // minimum position 
    uint256 public treasuryFee=3; 
    uint256 public percentReferralsLv1 = 2;
    uint256 public percentReferralsLv2 = 1;
    uint256 private  percentAllFees = treasuryFee+percentReferralsLv1+percentReferralsLv2;
    uint256 public potPercent=94; // 
    
    uint256 public treasuryAmount; // treasury amount that was not claimed
    address[] public treasuryWallets;
    uint256[] public treasuryPercentages;

    uint256 public currentEpoch; // current epoch for prediction round
    //Auto Fill Option
    bool public  isActiveAutoFill=true;
    uint256 public upAmountAutofill=10000000000000000000;
    uint256 public downAmountAutofill=10000000000000000000;
   
    uint256 public constant MAX_TREASURY_FEE = 10; // 10%

    mapping(uint256 => mapping(address => TradeInfo)) public ledger;
    mapping(uint256 => Round) public rounds;
    mapping(uint256 => uint256) public totalAutofillAmount;
    mapping(address => uint256[]) public userRounds;

    enum Position {
        Bull,
        Bear
    }

    struct Round {
        uint256 epoch;
        uint256 startTimestamp;
        uint256 lockTimestamp;
        uint256 closeTimestamp;
        int256 lockPrice;
        int256 closePrice;
        uint256 totalAmount;
        uint256 bullAmount;
        uint256 bearAmount;
        uint256 rewardBaseCalAmount;
        uint256 rewardAmount;
        uint256 totalTreasuryAmount;
        uint256 totalAmountReferralsLv1;
        uint256 totalAmountReferralsLv2;

        
       
    }

    struct TradeInfo {
        Position position;
        uint256 amount;
        bool claimed; // default false
    }

    event BetBear(address indexed sender, uint256 indexed epoch, uint256 amount,uint256 _partnerCode);
    event BetBull(address indexed sender, uint256 indexed epoch, uint256 amount,uint256 _partnerCode);
    event Claim(address indexed sender, uint256 indexed epoch, uint256 amount);
    event EndRound(uint256 indexed epoch, int256 price);
    event LockRound(uint256 indexed epoch, int256 price);

    event NewMinBetAmount(uint256 indexed epoch, uint256 minBetAmount);
    event NewTreasuryFee(uint256 indexed epoch, uint256 treasuryFee);

    event Pause(uint256 indexed epoch);
    event RewardsCalculated(
        uint256 indexed epoch,
        uint256 rewardBaseCalAmount,
        uint256 rewardAmount,
        uint256 treasuryAmount
    );

    event StartRound(uint256 indexed epoch);
    event TokenRecovery(address indexed token, uint256 amount);
    event TreasuryClaim(uint256 amount);
    event Unpause(uint256 indexed epoch);

 
    event PayReferralsEvent(
        address _parent,
        uint256 _prebitID,
        uint256 _payReferralAmount,
        uint256 _totalAmount,
        uint256 _type,
        uint256 _partnerCode
    );


    modifier onlyOperator() {
        require(msg.sender == operatorAddress, "Not operator");
        _;
    }

    modifier notContract() {
        require(!_isContract(msg.sender), "Contract not allowed");
        require(msg.sender == tx.origin, "Proxy contract not allowed");
        _;
    }

  
    constructor(
        address _operatorAddress,
        address _tokenPayAddress,
        address _referralContractAddress
    ) {
        operatorAddress = _operatorAddress;
        payToken = IERC20(_tokenPayAddress);
        referralContract = IPrebitReferrals(_referralContractAddress);
    }

    /**
     * @notice  bear position
     * @param epoch: epoch
     */
    function TradeDown(uint256 epoch,uint256 _amount,uint256 _referralCode,uint256 _partnerCode) external  whenNotPaused nonReentrant notContract {
        require(epoch == currentEpoch, "Trade is too early/late");
        require(_bettable(epoch), "Round not Tradeable");
        require(_amount >= minPosition, "Trade amount must be greater than minTradeAmount");
        require(ledger[epoch][msg.sender].amount == 0, "Can only Trade once per round");
        require(
            payToken.balanceOf(msg.sender) >= _amount,
            "102 : Insufficient USDT balance"
        );
         uint256 treasuryFeeAmount =  _amount.mul(treasuryFee).div(100);

      

        referralContract.generateReferralCodeWithContract(
            _referralCode,
            msg.sender
        );
         _paysProcess(_amount,epoch,_partnerCode);
      
        Round storage round = rounds[epoch];
        round.totalAmount = round.totalAmount + _amount;
        round.bearAmount = round.bearAmount + _amount;
        round.totalTreasuryAmount = round.totalTreasuryAmount +  treasuryFeeAmount;

       
        TradeInfo storage betInfo = ledger[epoch][msg.sender];
        betInfo.position = Position.Bear;
        betInfo.amount = _amount;
        userRounds[msg.sender].push(epoch);

        emit BetBear(msg.sender, epoch, _amount, _partnerCode);
    }

       /**
     * @notice  bull position
     * @param epoch: epoch
     */
    function TradeUp(uint256 epoch,uint256 _amount,uint256 _referralCode,uint256 _partnerCode) external  whenNotPaused nonReentrant notContract {
        require(epoch == currentEpoch, "Trade is too early/late");
        require(_bettable(epoch), "Round not Tradeable");
        require(_amount >= minPosition, "Trade amount must be greater than minTradeAmount");
        require(ledger[epoch][msg.sender].amount == 0, "Can only bet once per round");
        

           require(
            payToken.balanceOf(msg.sender) >= _amount,
            "102 : Insufficient USDT balance"
        );

       
         uint256 treasuryFeeAmount =  _amount.mul(treasuryFee).div(100);

          


            referralContract.generateReferralCodeWithContract(
            _referralCode,
            msg.sender
        );
      
       _paysProcess(_amount,epoch,_partnerCode);
       
        Round storage round = rounds[epoch];
        round.totalAmount = round.totalAmount + _amount;
        round.bullAmount = round.bullAmount + _amount;
       
        round.totalTreasuryAmount = round.totalTreasuryAmount +  treasuryFeeAmount;

      
        TradeInfo storage betInfo = ledger[epoch][msg.sender];
        betInfo.position = Position.Bull;
        betInfo.amount = _amount;
        userRounds[msg.sender].push(epoch); 

        emit BetBull(msg.sender, epoch, _amount,_partnerCode);
    }

    /**
     * @dev Handles the payment process for a user's purchase of precards, including referral rewards.
     * @param _totalPayAmount The total payment amount made by the user.
     */
    function _paysProcess(uint256 _totalPayAmount,uint256 _epoch,uint256 _partnerCode) private {

        uint256 newAmount = _totalPayAmount;
        address parentAddress = referralContract.getUserParent(msg.sender);
        if (parentAddress != address(0)) {
            newAmount -= _totalPayAmount.mul(percentReferralsLv1).div(100);
            payToken.transferFrom(
                msg.sender,
                parentAddress,
                _totalPayAmount.mul(percentReferralsLv1).div(100)
            );

               emit PayReferralsEvent(
                parentAddress,
                _epoch,
                _totalPayAmount.mul(percentReferralsLv1).div(100),
                _totalPayAmount,
                1,
                _partnerCode
            );
          rounds[_epoch].totalAmountReferralsLv1+=_totalPayAmount.mul(percentReferralsLv1).div(100);
            address tParentAddress = referralContract.getUserTparent(
                msg.sender
            );
           
            if (tParentAddress != address(0)) {
                payToken.transferFrom(
                    msg.sender,
                    tParentAddress,
                    _totalPayAmount.mul(percentReferralsLv2).div(100)
                );
                newAmount -= _totalPayAmount.mul(percentReferralsLv2).div(100);
                 rounds[_epoch].totalAmountReferralsLv2+=_totalPayAmount.mul(percentReferralsLv2).div(100);
                  emit PayReferralsEvent(
                    tParentAddress,
                    _epoch,
                    _totalPayAmount.mul(percentReferralsLv2).div(100),
                    _totalPayAmount,
                    2,
                    _partnerCode
                );
            } else {
                rounds[_epoch].totalTreasuryAmount += _totalPayAmount
                    .mul(percentReferralsLv2)
                    .div(100);
            }
        } else {
            rounds[_epoch].totalTreasuryAmount += _totalPayAmount
                .mul(percentReferralsLv1 + percentReferralsLv2)
                .div(100);
        }

        payToken.transferFrom(msg.sender, address(this), newAmount);
    }

 

    /**
     * @notice Claim reward for an array of epochs
     * @param epochs: array of epochs
     */
    function claim(uint256[] calldata epochs) external nonReentrant notContract {
        uint256 reward; // Initializes reward

        for (uint256 i = 0; i < epochs.length; i++) {
            require(rounds[epochs[i]].startTimestamp != 0, "Round has not started");
            require(block.timestamp > rounds[epochs[i]].closeTimestamp, "Round has not ended");

            uint256 addedReward = 0;

            // Round valid, claim rewards
            if (rounds[epochs[i]].lockPrice > 0) {
                require(claimable(epochs[i], msg.sender), "Not eligible for claim");
                Round memory round = rounds[epochs[i]];
                addedReward = ((ledger[epochs[i]][msg.sender].amount) * round.rewardAmount) / round.rewardBaseCalAmount;
            }
            // Round invalid, refund bet amount
            else {
                require(refundable(epochs[i], msg.sender), "Not eligible for refund");
                addedReward = ledger[epochs[i]][msg.sender].amount;
            }

            ledger[epochs[i]][msg.sender].claimed = true;
            reward += addedReward;

            emit Claim(msg.sender, epochs[i], addedReward);
        }

        if (reward > 0) {
            payToken.transfer(address(msg.sender), reward);
        }
    }

    /**
     * @notice Start the next round n, lock price for round n-1, end round n-2
     * @dev Callable by operator
     */
     //Set BTC Price in real timeframes Binance BTCUSDT 
    function executeRound(int256 _btcPrice) external  onlyOperator {
        require(
            genesisStartOnce && genesisLockOnce,
            "Can only run after genesisStartRound and genesisLockRound is triggered"
        );

   
        int256 currentPrice =_btcPrice;
     

        // CurrentEpoch refers to previous round (n-1)
        _safeLockRound(currentEpoch, currentPrice);
        _safeEndRound(currentEpoch - 1, currentPrice);
        _calculateRewards(currentEpoch - 1);

            //Pay to Treasury wallets
       
           _paysTreasury(rounds[currentEpoch - 1].totalTreasuryAmount);
      

        // Increment currentEpoch to current round (n)
        currentEpoch = currentEpoch + 1;
        _safeStartRound(currentEpoch);
    }

  
    /**
     * @notice Start genesis round
     * @dev Callable by admin or operator
     */
    function genesisStartRound(uint256 _startTimestamp,uint256 _startEpoch) external whenNotPaused onlyOperator {
        require(!genesisStartOnce, "Can only run genesisStartRound once");
        if (currentEpoch ==0){
            currentEpoch = currentEpoch + _startEpoch ;
        }else{
            currentEpoch = currentEpoch;
        }
       
        Round storage round = rounds[currentEpoch];
        uint256 startTimestamp = _startTimestamp;
        round.startTimestamp = startTimestamp;
        round.lockTimestamp = startTimestamp + intervalSeconds;
        round.closeTimestamp =startTimestamp +  (2*intervalSeconds);
        round.epoch = currentEpoch;
        round.totalAmount = 0;
        genesisStartOnce = true;
    }

    /**
     * @notice Lock genesis round
     * @dev Callable by operator
     */
    function genesisLockRound(int256 _btcPrice) external whenNotPaused onlyOperator {
        require(genesisStartOnce, "Can only run after genesisStartRound is triggered");
        require(!genesisLockOnce, "Can only run genesisLockRound once");

         int256 currentPrice =_btcPrice;
    

    
        _safeLockRound(currentEpoch, currentPrice);

        currentEpoch = currentEpoch + 1;
        _startRound(currentEpoch);
        genesisLockOnce = true;
    }
    /**
     * @notice called by the admin to pause, triggers stopped state
     * @dev Callable by admin or operator
     */
    function pause() external whenNotPaused onlyOwner {
        _pause();
        
        emit Pause(currentEpoch);
    }

 

    /**
     * @notice called by the admin to unpause, returns to normal state
     * Reset genesis state. Once paused, the rounds would need to be kickstarted by genesis
     */
    function unpause() external whenPaused onlyOwner {
        // genesisStartOnce = false;
        // genesisLockOnce = false;
        _unpause();

        emit Unpause(currentEpoch);
    }

    /**
     * @notice Set  interval (in seconds)
     * @dev Callable by admin
     */
    function setIntervalSeconds(uint256 _intervalSeconds)
        external
        onlyOwner
    {
      
        intervalSeconds = _intervalSeconds;

    }

    /**
     * @notice Set minBetAmount
     * @dev Callable by admin
     */
    function setMinPositionAmount(uint256 _minPositionAmount) external  onlyOwner {
        require(_minPositionAmount != 0, "Must be superior to 0");
        minPosition = _minPositionAmount;

        emit NewMinBetAmount(currentEpoch, minPosition);
    }

    /**
     * @notice Set operator address
     * @dev Callable by admin
     */
    function setOperatorAndtreasuryAddress(address _operatorAddress,address _treasuryAddress) external onlyOwner {
        require(_operatorAddress != address(0), "Cannot be zero address");
        operatorAddress = _operatorAddress;
        treasuryAddress = _treasuryAddress;
       
    }

    /**
     * @notice Set treasury fee
     * @dev Callable by admin
     */
    function setTreasuryFee(uint256 _treasuryFee) external  onlyOwner {
        require(_treasuryFee <= MAX_TREASURY_FEE, "Treasury fee too high");
        treasuryFee = _treasuryFee;

        emit NewTreasuryFee(currentEpoch, treasuryFee);
    }

    /**
     * @notice It allows the owner to recover tokens sent to the contract by mistake
     * @param _token: token address
     * @param _amount: token amount
     * @dev Callable by owner
     */
    function recoverToken(address _token, uint256 _amount) external onlyOwner {
        IERC20(_token).transfer(address(msg.sender), _amount);

        emit TokenRecovery(_token, _amount);
    }



    /**
     * @notice Returns round epochs and bet information for a user that has participated
     * @param user: user address
     * @param cursor: cursor
     * @param size: size
     */
    function getUserRounds(
        address user,
        uint256 cursor,
        uint256 size
    )
        external
        view
        returns (
            uint256[] memory,
            TradeInfo[] memory,
            uint256
        )
    {
        uint256 length = size;

        if (length > userRounds[user].length - cursor) {
            length = userRounds[user].length - cursor;
        }

        uint256[] memory values = new uint256[](length);
        TradeInfo[] memory betInfo = new TradeInfo[](length);

        for (uint256 i = 0; i < length; i++) {
            values[i] = userRounds[user][cursor + i];
            betInfo[i] = ledger[values[i]][user];
        }

        return (values, betInfo, cursor + length);
    }

    /**
     * @notice Returns round epochs length
     * @param user: user address
     */
    function getUserRoundsLength(address user) external view returns (uint256) {
        return userRounds[user].length;
    }

    /**
     * @notice Get the claimable stats of specific epoch and user account
     * @param epoch: epoch
     * @param user: user address
     */
    function claimable(uint256 epoch, address user) public view returns (bool) {
        TradeInfo memory betInfo = ledger[epoch][user];
        Round memory round = rounds[epoch];
        if (round.lockPrice == round.closePrice) {
            return false;
        }
        return
            round.closePrice > 0 &&
            betInfo.amount != 0 &&
            !betInfo.claimed &&
            ((round.closePrice > round.lockPrice && betInfo.position == Position.Bull) ||
                (round.closePrice < round.lockPrice && betInfo.position == Position.Bear));
    }

    /**
     * @notice Get the refundable stats of specific epoch and user account
     * @param epoch: epoch
     * @param user: user address
     */
    function refundable(uint256 epoch, address user) public view returns (bool) {
        TradeInfo memory betInfo = ledger[epoch][user];
        Round memory round = rounds[epoch];
        return
            (round.closePrice > 0) &&
            !betInfo.claimed &&
            block.timestamp > round.closeTimestamp  &&
            betInfo.amount != 0;
    }

    /**
     * @notice Calculate rewards for round
     * @param epoch: epoch
     */
    function _calculateRewards(uint256 epoch) internal {
        require(rounds[epoch].rewardBaseCalAmount == 0 && rounds[epoch].rewardAmount == 0, "Rewards calculated");
        Round storage round = rounds[epoch];
        uint256 rewardBaseCalAmount;
        uint256 treasuryAmt;
        uint256 rewardAmount;

        // Bull wins
        if (round.closePrice > round.lockPrice) {
            rewardBaseCalAmount = round.bullAmount;
           
         
              if (rewardBaseCalAmount==0){
               
                round.totalTreasuryAmount = round.totalAmount  - (round.totalAmountReferralsLv1+round.totalAmountReferralsLv2) ;
            }

                rewardAmount = round.totalAmount - round.totalTreasuryAmount - (round.totalAmountReferralsLv1+round.totalAmountReferralsLv2);
                rewardAmount =rewardAmount - totalAutofillAmount[epoch].mul(percentAllFees).div(100);
        }
        // Bear wins
        else if (round.closePrice < round.lockPrice) {
            rewardBaseCalAmount = round.bearAmount;
           
            if (rewardBaseCalAmount==0){
               
                round.totalTreasuryAmount = round.totalAmount - (round.totalAmountReferralsLv1+round.totalAmountReferralsLv2);
            }
             rewardAmount = round.totalAmount - round.totalTreasuryAmount - (round.totalAmountReferralsLv1+round.totalAmountReferralsLv2);
              rewardAmount =rewardAmount - totalAutofillAmount[epoch].mul(percentAllFees).div(100);
        }
        // House wins
        else {
            rewardBaseCalAmount = 0;
            rewardAmount = 0;
            round.totalTreasuryAmount = round.totalTreasuryAmount+  (round.totalAmount - totalAutofillAmount[epoch] - (round.totalAmountReferralsLv1+round.totalAmountReferralsLv2));
        }
        round.rewardBaseCalAmount = rewardBaseCalAmount;
    
        round.rewardAmount = rewardAmount;
       
      

        emit RewardsCalculated(epoch, rewardBaseCalAmount, rewardAmount, treasuryAmt);
    }

    /**
     * @notice End round
     * @param epoch: epoch
     * @param price: price of the round
     */
    function _safeEndRound(
        uint256 epoch,
        int256 price
    ) internal {
        require(rounds[epoch].lockTimestamp != 0, "Can only end round after round has locked");
        require(block.timestamp >= rounds[epoch].closeTimestamp, "Can only end round after closeTimestamp");

        Round storage round = rounds[epoch];
        round.closePrice = price;
    

        emit EndRound(epoch, round.closePrice);
    }

    /**
     * @notice Lock round
     * @param epoch: epoch
     * @param price: price of the round
     */
    function _safeLockRound(
        uint256 epoch,
        int256 price
    ) internal {
        require(rounds[epoch].startTimestamp != 0, "Can only lock round after round has started");
        require(block.timestamp >= rounds[epoch].lockTimestamp, "Can only lock round after lockTimestamp");

        Round storage round = rounds[epoch];
        round.closeTimestamp = round.lockTimestamp + intervalSeconds;
        round.lockPrice = price;
       

        emit LockRound(epoch, round.lockPrice);
    }

    /**
     * @notice Start round
     * Previous round n-2 must end
     * @param epoch: epoch
     */
    function _safeStartRound(uint256 epoch) internal {
        require(genesisStartOnce, "Can only run after genesisStartRound is triggered");
        require(rounds[epoch - 2].closeTimestamp != 0, "Can only start round after round n-2 has ended");
        require(
            block.timestamp >= rounds[epoch - 2].closeTimestamp,
            "Can only start new round after round n-2 closeTimestamp"
        );
        _startRound(epoch);
    }

 

    /**
     * @notice Start round
     * Previous round n-2 must end
     * @param epoch: epoch
     */
    function _startRound(uint256 epoch) internal {
        Round storage round = rounds[epoch];
          uint256 nowTimestamp = block.timestamp;
         uint256 startTimestamp = rounds[epoch-1].lockTimestamp;
        while((startTimestamp+intervalSeconds) < nowTimestamp){
                startTimestamp = startTimestamp+intervalSeconds;
        }
       
        round.startTimestamp = startTimestamp;
        round.lockTimestamp = startTimestamp + intervalSeconds;
        round.closeTimestamp =startTimestamp +  (2*intervalSeconds);
        round.epoch = epoch;
        round.totalAmount = 0;
        if (isActiveAutoFill){
            round.bearAmount+=downAmountAutofill;
            round.bullAmount+=upAmountAutofill;
            round.totalAmount += upAmountAutofill + downAmountAutofill;
            totalAutofillAmount[epoch] = upAmountAutofill + downAmountAutofill;
        }

        emit StartRound(epoch);
    }

    /**
     * @notice Determine if a round is valid for receiving bets
     * Round must have started and locked
     * Current timestamp must be within startTimestamp and closeTimestamp
     */
    function _bettable(uint256 epoch) internal view returns (bool) {
        return
            rounds[epoch].startTimestamp != 0 &&
            rounds[epoch].lockTimestamp != 0 &&
            block.timestamp > rounds[epoch].startTimestamp &&
            block.timestamp < rounds[epoch].lockTimestamp;
    }

  
    /**
     * @dev Distributes funds to various treasury wallets based on configured percentages.
     * @param _totalTransfers The total amount to be distributed to treasuries.
     */
    function _paysTreasury(uint256 _totalTransfers) private {
        uint256 remainingAmount = _totalTransfers;
        if (treasuryWallets.length > 0) {
            for (uint256 i = 0; i < treasuryWallets.length; i++) {
                uint256 amountToTransfer = (_totalTransfers)
                    .mul(treasuryPercentages[i])
                    .div(100);

                if (amountToTransfer > 0) {
                    remainingAmount -= amountToTransfer;
                    payToken.transfer(treasuryWallets[i], amountToTransfer);
                }
            }

            if (remainingAmount > 0) {
                payToken.transfer(treasuryAddress, remainingAmount);
            }
        } else {
            payToken.transfer(treasuryAddress, remainingAmount);
        }
    }

    /**
     * @dev Add a treasury wallet address with a percentage share.
     *
     * @param _wallet The address of the treasury wallet.
     * @param _percentage The percentage share for the wallet.
     */
    function addTreasuryWallet(address _wallet, uint256 _percentage)
        external
        onlyOwner
    {
        require(
            _wallet != address(0),
            "Treasury wallet address cannot be zero"
        );
        require(_percentage <= 100, "Percentage must be between 0 and 100");
        uint256 totalPercentage = 0;
        for (uint256 i = 0; i < treasuryWallets.length; i++) {
            totalPercentage += treasuryPercentages[i];
        }
        require(
            totalPercentage + _percentage <= 100,
            "Percentage must be less than 100"
        );

        treasuryWallets.push(_wallet);
        treasuryPercentages.push(_percentage);
    }

    /**
     * @dev Update a treasury wallet address and its percentage share.
     *
     * @param _index The index of the treasury wallet to update.
     * @param _wallet The new address for the treasury wallet.
     * @param _percentage The new percentage share for the wallet.
     */
    function updateTreasuryWallet(
        uint256 _index,
        address _wallet,
        uint256 _percentage
    ) external onlyOwner {
        require(_index < treasuryWallets.length, "Invalid index");
        require(
            _wallet != address(0),
            "Treasury wallet address cannot be zero"
        );
        require(_percentage <= 100, "Percentage must be between 1 and 100");

        uint256 totalPercentage = 0;
        for (uint256 i = 0; i < treasuryWallets.length; i++) {
            totalPercentage += treasuryPercentages[i];
        }
        require(
            totalPercentage + _percentage <= 100,
            "Percentage must be less than 100"
        );

        treasuryWallets[_index] = _wallet;
        treasuryPercentages[_index] = _percentage;
    }
/**
 * @dev Adjust the timestamps for a specific epoch.
 *
 * Requirements:
 * - The caller must be the owner of the contract.
 * - The specified epoch must exist.
 *
 * @param _epoch The epoch for which timestamps are adjusted.
 * @param startTimestamp The new start timestamp for the epoch.
 * @param lockTimestamp The new lock timestamp for the epoch.
 * @param closeTimestamp The new close timestamp for the epoch.
 */

    function adjustTimestamp(
        uint256 _epoch,
        uint256 startTimestamp,
        uint256 lockTimestamp,
        uint256 closeTimestamp
    ) external onlyOwner {
        rounds[_epoch].startTimestamp = startTimestamp;
        rounds[_epoch].lockTimestamp = lockTimestamp;
        rounds[_epoch].closeTimestamp = closeTimestamp;
    }

    /**
     * @dev Set or update the auto-fill options.
     *
     * Requirements:
     * - The caller must be the owner of the contract.
     *
     * @param _isActiveAutoFill The new value for isActiveAutoFill.
     * @param _upAmountAutofill The new value for upAmountAutofill.
     * @param _downAmountAutofill The new value for downAmountAutofill.
     */
    function setAutoFillOptions(
        bool _isActiveAutoFill,
        uint256 _upAmountAutofill,
        uint256 _downAmountAutofill
    ) external onlyOwner {
        isActiveAutoFill = _isActiveAutoFill;
        upAmountAutofill = _upAmountAutofill;
        downAmountAutofill = _downAmountAutofill;
    }
    /**
     * @notice Returns true if `account` is a contract.
     * @param account: account address
     */
    function _isContract(address account) internal view returns (bool) {
        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
    }


  
}