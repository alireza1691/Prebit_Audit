# First Flight #1: Trading - Findings Report

# Table of contents

- ### [Contest Summary](#contest-summary)
- ### [Results Summary](#results-summary)
- ## High Risk Findings

  - [H-01. Anyone can set the password by calling `PasswordStore::setPassword`](#H-01)
  - [H-02. Owner's password stored in the `s_password` state variable is not a secret and can be seen by everyone](#H-02)

- ## Low Risk Findings
  - [L-01. Initialization Timeframe Vulnerability](#L-01)

# <a id='contest-summary'></a>Contest Summary

### Sponsor: First Flight #1

### Dates: Oct 18th, 2023 - Oct 25th, 2023

[See more contest details here](https://www.codehawks.com/contests/clnuo221v0001l50aomgo4nyn)

# <a id='results-summary'></a>Results Summary

### Number of findings:

- High: 2
- Medium: 0
- Low: 1

# Low Risk Findings

## <a id='L-01'></a>L-01. To make code more clear and efficient you can use `ether` keyword instead of eighteen zeros.

```diff

-    uint256 public upAmountAutofill = 10000000000000000000;
-    uint256 public downAmountAutofill = 10000000000000000000;

+   uint256 public upAmountAutofill = 10 ether;
+   uint256 public downAmountAutofill = 10 ether;

// You can also use 10e18 instead of 10 ether. (1 ether = 1e18)
```

## Summary

Since you want to set specific amount of a token which it has 18 decimals, to set real amount of token (10 token) instead of adding 18 zeros to the real number, you can simply add `ether` keyword.

## Vulnerability Details

While it may not constitute a security vulnerability, adhering to this practice enhances the professionalism and cleanliness of your contract code.

## Impact

Readablility

## Proof of Concept

### Working Test Case

## Recommended Mitigation

## Tools Used

## <a id='L-02'></a>L-02. Potentioally unnecessary event

## Summary

Based on the contract, it seems that the event "NewTreasuryFee" doesn't need to be stored or displayed anywhere. If it doesn't serve a specific purpose or functionality, consider removing it or retrieving its value directly from the contract rather than emitting events.

## Impact

Emmiting events consumes gas. Therefore, eliminating unnecessary events enhances gas efficiency.

## <a id='L-03'></a>L-03. Constant variable

## Summary

According to the contract code, payToken is an instance of a token, specifically an ERC20 token interface. Its value (address) is set in the constructor and remains constant thereafter. However, in one of the error messages within the TradeDown function, it refers to payToken as USDT. To ensure clarity, you can define payToken as an constant variable on the destination network by specifying its address.

```diff

-      IERC20 public payToken;
+      IERC20 public constant payToken = IERC20('USDT Address');
// also you can define it as private variable

  constructor(
        address _operatorAddress,
-        address _tokenPayAddress,
        address _referralContractAddress
    ) {
        operatorAddress = _operatorAddress;
-        payToken = IERC20(_tokenPayAddress);
        referralContract = IPrebitReferrals(_referralContractAddress);
    }


```

Here are some other variables that we can turn to constant varable:

```solidity
    IPrebitReferrals public referralContract;

    uint256 public percentReferralsLv1 = 2;

    uint256 public percentReferralsLv2 = 1;

    uint256 private  percentAllFees = treasuryFee+percentReferralsLv1+percentReferralsLv2;

    uint256 public potPercent=94; // Unused variable


```

\*\*\* Note that if you do not interact with them externally,setting their visibility to `private` can also optimize gas usage.

## Impact

Gas efficiency

## <a id='L-04'></a>L-04. Increment and decrement

## Summary

To increment and decrement values it is recommended to replace this approach:

```diff
// Line 573:
- round.totalTreasuryAmount = round.totalTreasuryAmount +  treasuryFeeAmount;

+ round.totalTreasuryAmount += treasuryFeeAmount;

// To decrement you can replace + with -
// Line 980:
- rewardAmount =rewardAmount - totalAutofillAmount[epoch].mul(percentAllFees).div(100);
+ rewardAmount -= totalAutofillAmount[epoch].mul(percentAllFees).div(100);

// Also if decrement or increment amount is 1, you can use ++ or --
// Line 792:
- currentEpoch = currentEpoch + 1;
+ currentEpoch ++;

```

Using this approach make code cleaner, more readable and more gas efficient.

Consider it in mentioned Lines:
573-617-751-765-763-792-980-991-997

## <a id='L-05'></a>L-05. Enhancing transfer safety

## Summary

For safer interactions with `ERC20` tokens, it's advised to utilize the `TransferHelper` library from Uniswap rather than directly invoking functions from `IERC20`, as the contract engages with the ERC20 interface (IERC20) across multiple functions.

https://github.com/Uniswap/v3-periphery/blob/main/contracts/libraries/TransferHelper.sol

```diff
- payToken.transferFrom(msg.sender,parentAddress,_totalPayAmount.mul(percentReferralsLv1).div(100));

+ TransferHelper.SafeTransferFrom(address(payToken),msg.sender,parentAddress, _totalPayAmount.mul(percentReferralsLv1).div(100))
```

## Recommended approach

You can locate interactions with the token interface by searching for payToken and substituting the mentioned approach wherever you've invoked the interface function.

## <a id='L-06'></a>L-06. Prevent defining a structure 3 times

## Summary

In the `claim` function, you'll notice the mapping `ledger[epochs[i]][msg.sender]` referencing the `TradeInfo` structure, which is accessed 3 times. This approach isn't optimal in terms of gas efficiency and code cleanliness. To improve this, consider defining its instance in `storage`, as modifying its value throughout the function prevents defining it in `memory`.

## Recommended approach

```diff
function claim(uint256[] calldata epochs) external nonReentrant notContract {
    uint256 reward; // Initializes reward

    for (uint256 i = 0; i < epochs.length; i++) {
        require(rounds[epochs[i]].startTimestamp != 0, "Round has not started");
        require(block.timestamp > rounds[epochs[i]].closeTimestamp, "Round has not ended");

        uint256 addedReward = 0;
+        Ledger storage userLedger = ledger[epochs[i]][msg.sender]; // Define once in storage

        // Round valid, claim rewards
        if (rounds[epochs[i]].lockPrice > 0) {
            require(claimable(epochs[i], msg.sender), "Not eligible for claim");
            Round memory round = rounds[epochs[i]];
-            addedReward = ((ledger[epochs[i]][msg.sender].amount) * round.rewardAmount) / round.rewardBaseCalAmount;
+            addedReward = (userLedger.amount * round.rewardAmount) / round.rewardBaseCalAmount; // Use stored value
        }
        // Round invalid, refund bet amount
        else {
            require(refundable(epochs[i], msg.sender), "Not eligible for refund");
-            addedReward = ledger[epochs[i]][msg.sender].amount;

+            addedReward = userLedger.amount; // Use stored value
        }
-       ledger[epochs[i]][msg.sender].claimed = true;
+        userLedger.claimed = true; // Update stored value
        reward += addedReward;

        emit Claim(msg.sender, epochs[i], addedReward);
    }

    if (reward > 0) {
        payToken.transfer(address(msg.sender), reward);
    }
}

```

## <a id='L-07'></a>L-07. Defining unusable variable and unnecessary`if` statement in `genesisStartRound` function

## Summary

1_In the `genesisStartRound` function, you've defined `uint256 startTimestamp`, which receives its value from `_startTimestamp`, an input variable whose value remains constant. Therefore, you can directly utilize `_startTimestamp` instead of creating an additional variable.

2_Since the `genesisStartRound` function is invoked only once, specifically when `currentEpoch` equals `0`, there's no necessity to verify whether its value differs from 0 before executing another action. Hence, we can straightforwardly omit this check.

## Recommended approach

```diff

 function genesisStartRound(uint256 _startTimestamp,uint256 _startEpoch) external whenNotPaused onlyOperator {
        require(!genesisStartOnce, "Can only run genesisStartRound once");
-        if (currentEpoch ==0){
-            currentEpoch = currentEpoch + _startEpoch ;
-        }else{
-            currentEpoch = currentEpoch;
-        }
+       currentEpoch = currentEpoch + _startEpoch ;

        Round storage round = rounds[currentEpoch];
-       uint256 startTimestamp = _startTimestamp;
-       round.startTimestamp = startTimestamp;
+       round.startTimestamp = _startTimestamp;
-       round.lockTimestamp = startTimestamp + intervalSeconds;
+       round.lockTimestamp = _startTimestamp + intervalSeconds;
-       round.closeTimestamp =startTimestamp +  (2*intervalSeconds);
+       round.closeTimestamp =_startTimestamp +  (2*intervalSeconds);
        round.epoch = currentEpoch;
        round.totalAmount = 0;
        genesisStartOnce = true;
    }

```

## <a id='L-08'></a>L-08. Natspec and modifiers of `pause` function does not match

## Summary

In natspec of `pause` function mentioned that this function is callable `by owner` and `operator`:

```solidity

  /**
     * @notice called by the admin to pause, triggers stopped state
     * @dev Callable by admin or operator
     */
    function pause() external whenNotPaused onlyOwner {
        _pause();

        emit Pause(currentEpoch);
    }

```

However, the function modifiers restrict its invocation solely to the owner, disallowing the operator. If you intend to permit the operator to execute this function, consider adjusting the modifiers accordingly. Alternatively, if operator access isn't required, you can simply remove it from natspec.

## <a id='H-01'></a>L-01. Initialization Timeframe Vulnerability

_Submitted by [dianivanov](/profile/clo3cuadr0017mp08rvq00v4e)._

### Relevant GitHub Links

https://github.com/Cyfrin/2023-10-PasswordStore/blob/main/src/PasswordStore.sol

## Summary

The PasswordStore contract exhibits an initialization timeframe vulnerability. This means that there is a period between contract deployment and the explicit call to setPassword during which the password remains in its default state. It's essential to note that even after addressing this issue, the password's public visibility on the blockchain cannot be entirely mitigated, as blockchain data is inherently public as already stated in the "Storing password in blockchain" vulnerability.

## Vulnerability Details

The contract does not set the password during its construction (in the constructor). As a result, when the contract is initially deployed, the password remains uninitialized, taking on the default value for a string, which is an empty string.

During this initialization timeframe, the contract's password is effectively empty and can be considered a security gap.

## Impact

The impact of this vulnerability is that during the initialization timeframe, the contract's password is left empty, potentially exposing the contract to unauthorized access or unintended behavior.

## Tools Used

No tools used. It was discovered through manual inspection of the contract.

## Recommendations

To mitigate the initialization timeframe vulnerability, consider setting a password value during the contract's deployment (in the constructor). This initial value can be passed in the constructor parameters.

```solidity
/*
     * @notice This function allows only the owner to set a new password.
     * @param newPassword The new password to set.
     */
    function setPassword(string memory newPassword) external {
        s_password = newPassword;
        emit SetNetPassword();
    }
```
