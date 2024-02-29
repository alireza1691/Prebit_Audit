# First Flight #1: Trading - Findings Report

# Table of contents

- ### [Contest Summary](#contest-summary)
- ### [Results Summary](#results-summary)

- ## Low Risk Findings
  - [L-01. Use `ether` keyword instead of eighteen zeros.](#L-01)
  - [L-02. Potentioally unnecessary event](#L-02)
  - [L-03. Optimize gas cost by using constant variables](#L-03)
  - [L-04. Increment and decrement](#L-04)
  - [L-05. Enhancing transfer safety](#L-05)
  - [L-06. Prevent defining a mapping 3 times](#L-06)
  - [L-07. Remove unusable variable and unnecessary`if` statement in `genesisStartRound` function](#L-07)
  - [L-08. Natspec and modifiers of `pause` function does not match](#L-08)
  - [L-09. `unpause` Function does not have mentioned functionality](#L-09)
  - [L-10. `treasuryFee` can set to zero](#L-10)
  - [L-11. `treasuryPercentages[index]` can set to zero](#L-11)
- ## Medium Risk Findings
- [M-01. `treasuryAddress` can be zero address.](#M-01)
- [M-02. `recoverToken` detected as malicious function.](#M-02)
- [M-03. Manipulating the timestamps to incorrect values can lead to crashing the epoch/round.](#M-02)
- [M-04. Using floating pragma version.](#M-02)

- ## High Risk Findings

# <a id='contest-summary'></a>Contest Summary

### Dates: Feb 20th, 2024 - Feb 26th, 2024

[Audited by Alireza Haghshenas](https://github.com/alireza1691)

# <a id='results-summary'></a>Results Summary

### Number of findings:

- High: 0
- Medium: 4
- Low: 11

# Low Risk Findings

## <a id='L-01'></a>L-01. Use `ether` keyword instead of eighteen zeros.

```diff

-    uint256 public upAmountAutofill = 10000000000000000000;
-    uint256 public downAmountAutofill = 10000000000000000000;

+   uint256 public upAmountAutofill = 10 ether;
+   uint256 public downAmountAutofill = 10 ether;

// You can also use 10e18 instead of 10 ether. (1 ether = 1e18)
```

## Summary

If you intend to specify a particular amount of a token with 18 decimal places, rather than appending 18 zeros to the actual number, you can conveniently employ the `ether` keyword. This method is simpler and cleaner.

## Vulnerability Details

While it may not constitute a security vulnerability, adhering to this practice enhances the professionalism and cleanliness of your contract code.

## <a id='L-02'></a>L-02. Potentioally unnecessary event

## Summary

Based on the contract, it seems that the event `NewTreasuryFee` doesn't need to be stored or displayed anywhere. If it doesn't serve a specific purpose or functionality, consider removing it or retrieving its value directly from the contract rather than emitting events.

Emmiting events consumes gas. Therefore, eliminating unnecessary events enhances gas efficiency.

## <a id='L-03'></a>L-03. Optimize gas cost by using constant variables

## Summary

According to the contract code, payToken is an instance of a token, specifically an ERC20 token interface. Its value (address) is set in the constructor and remains constant thereafter. However, in one of the error messages within the TradeDown function, it refers to payToken as USDT. To ensure clarity and gas optimization, you can define payToken as an constant variable on the destination network by specifying its address.

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

## Documentation source

https://github.com/Uniswap/v3-periphery/blob/main/contracts/libraries/TransferHelper.sol

## Recommended approach

```diff
- payToken.transferFrom(msg.sender,parentAddress,_totalPayAmount.mul(percentReferralsLv1).div(100));

+ TransferHelper.SafeTransferFrom(address(payToken),msg.sender,parentAddress, _totalPayAmount.mul(percentReferralsLv1).div(100))
```

You can locate interactions with the token interface by searching for payToken and substituting the mentioned approach wherever you've invoked the interface function.

## <a id='L-06'></a>L-06. Prevent defining a mapping 3 times

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

## <a id='L-07'></a>L-07. Remove unusable variable and unnecessary`if` statement in `genesisStartRound` function

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

It also appears that the function serves no particular purpose. Please keep in mind that removing such unused functions can optimize gas usage.

## <a id='L-09'></a>L-09. `unpause` Function does not have mentioned functionality

## Summary

According to `unpause` function natspec:

```solidity
 /**
     * @notice called by the admin to unpause, returns to normal state
     * Reset genesis state. Once paused, the rounds would need to be kickstarted by genesis
     */
```

It should kickstart genesis round. But it does not contain required functionalities, It just call `_unpause` function from `Pausable` contract which is imported.

```solidity
   function unpause() external whenPaused onlyOwner {
        // genesisStartOnce = false;
        // genesisLockOnce = false;
        _unpause();

        emit Unpause(currentEpoch);
    }

```

## Recommended approach

Since it appears that the function lacks a clear purpose, please either incorporate the mentioned functionality or eliminate it altogether.

## <a id='L-10'></a>L-10. `treasuryFee` can set to zero

## Summary

In the `setTreasuryFee` function, where the owner can establish a new treasuryFee, we ensure that the fee is less than `MAX_TREASURY_FEE`, but we neglect to verify if it exceeds zero. Therefore, unless there's a specific reason for it to be otherwise, it's advisable to confirm that the fee is greater than zero.

```diff
  function setTreasuryFee(uint256 _treasuryFee) external  onlyOwner {
-       require(_treasuryFee <= MAX_TREASURY_FEE, "Treasury fee too high");
+       require(0 < _treasuryFee <= MAX_TREASURY_FEE, "Treasury fee too high");
        treasuryFee = _treasuryFee;

        emit NewTreasuryFee(currentEpoch, treasuryFee);
    }

```

## <a id='L-11'></a>L-11. `treasuryPercentages[index]` can set to zero

## Summary

In both the `addTreasuryWallet` and `updateTreasuryWallet` functions, where the owner can create a new treasury wallet or modify an existing one, we validate that `_percentage` is less than 100. However, if the value is 0, the function proceeds without reverting and sets `treasuryPercentages[index]` to the provided value of 0.

The sole function that utilizes `treasuryPercentages[index]` is `_paysTreasury`, where we determine `amountToTransfer` and execute the transfer for the calculated amount:

```solidity
  function _paysTreasury(uint256 _totalTransfers) private {
        uint256 remainingAmount = _totalTransfers;
        if (treasuryWallets.length > 0) {
            for (uint256 i = 0; i < treasuryWallets.length; i++) {
                uint256 amountToTransfer = (_totalTransfers) // **** Here ***
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
```

When we multiply `_totalTransfers` by `treasuryPercentages[index]`, if `treasuryPercentages[index]` equals 0, the resulting `amountToTransfer` will also be 0, indicating no transfer amount. Therefore, having any treasury wallet with a 0 percentage is deemed pointless, and it's wise to avoid incorporating unnecessary functionality or variables.

## Recommended approach

Replace require statement with this one in both `addTreasuryWallet` and `updateTreasuryWallet` functions:

```diff
-  require(_percentage <= 100, "Percentage must be between 0 and 100");
+  require(0 < _percentage <= 100, "Percentage must be between 0 and 100");
```

# Medium Risk Findings

## <a id='M-01'></a>M-01. `treasuryAddress` Can set to zero address.

## Summary

In the `setOperatorAndtreasuryAddress` function, the owner has the ability to designate a new operatorAddress and treasuryAddress. While a require statement ensures that `_operatorAddress`, the new operator address, is not set to the zero address, but it does not validate `_treasuryAddress`, potentially allowing it to be set to the zero address.

## Vulnerability Details

Given that the contract sends tokens to `treasuryAddress`, sending tokens to the zero address will result in their loss if `treasuryAddress` is set to zero.

## Impact

Loss of money

## Recommendations

```diff
   function setOperatorAndtreasuryAddress(address _operatorAddress,address _treasuryAddress) external onlyOwner {
-       require(_operatorAddress != address(0), "Cannot be zero address");
+       require(_operatorAddress != address(0) && _treasuryAddress != address(0), "Cannot be zero address");
        operatorAddress = _operatorAddress;
        treasuryAddress = _treasuryAddress;

    }

```

## <a id='M-02'></a>M-01. `recoverToken` detected as malicious function.

## Summary

The function `recoverToken` permits the owner to reclaim tokens inadvertently transferred to the contract. However, it also grants the owner the ability to withdraw all tokens, potentially compromising trust. To enhance transparency and mitigate misuse, consider implementing additional modifiers to impose stricter limitations on its usage.

## Recommendations

For instance, you can easily demonstrate that the admin will refrain from transferring payToken` that might rightfully belong to users.

```diff

  function recoverToken(address _token, uint256 _amount) external onlyOwner {
+       require(_token != address(payToken),"relevant error message" )
        IERC20(_token).transfer(address(msg.sender), _amount);

        emit TokenRecovery(_token, _amount);
    }

```

## <a id='M-03'></a>M-03. Manipulating the timestamps to incorrect values can lead to crashing the epoch/round.

## Summary

In the `adjustTimestamp` function, which allows the owner to update the `startTimestamp`, `lockTimestamp`, and `closeTimestamp` of an existing round, if the entered values (timestamps) do not align with the logic and functionality of the contract, the function does not revert. For instance, it's possible to set the `startTimestamp` to a value greater than the `closeTimestamp`.

## Impact

Mismatched timestamps in a round could compromise the contract's functionality and potentially lead to loss of money, specially user losses.

## Recommendations

You can simply add a require statement:

```diff
   function adjustTimestamp(
        uint256 _epoch,
        uint256 startTimestamp,
        uint256 lockTimestamp,
        uint256 closeTimestamp
    ) external onlyOwner {
+   require( startTimestamp < lockTimestamp < closeTimestamp, "Timestamps do not match!")
        rounds[_epoch].startTimestamp = startTimestamp;
        rounds[_epoch].lockTimestamp = lockTimestamp;
        rounds[_epoch].closeTimestamp = closeTimestamp;
    }

```

## <a id='M-04'></a>M-04. Using floating pragma version `^0.8.19`.

## Summary

In `Trading.sol`, we can see contract uses floating pragma version:

```solidity
pragma solidity ^0.8.19;
```

Using a floating pragma version in Solidity smart contracts, such as `^0.8.19`, is generally discouraged for several reasons:

### `Compatibility Risks`: Floating pragmas allow the Solidity compiler to use any version greater than or equal to the specified version. While this enables access to new features and optimizations, it also introduces the risk of compatibility issues. Code that compiles and behaves correctly with one compiler version might produce unexpected results with another version.

### `Security Concerns`: New compiler versions may introduce changes to the language semantics or optimizations that could inadvertently impact the security of your smart contracts. Relying on a floating pragma increases the likelihood of unintended vulnerabilities being introduced into your codebase.

### `Code Maintenance`: Smart contracts are often intended to have long lifespans, and relying on a floating pragma makes it harder to ensure consistent behavior and maintainability over time. By specifying a fixed pragma version, you establish a known environment in which your contract operates, making it easier to predict and manage changes.

### `Auditing and Verification`: Specifying a fixed pragma version allows for easier auditing and verification of your smart contract code. Auditors and reviewers can focus on a specific compiler version, reducing the complexity of their analysis and ensuring that the code behaves as intended.

## Recommendations

Simply remove `^` and choose your desire version.
