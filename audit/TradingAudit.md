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

## <a id='L-05'></a>L-05. Enhancing transfer

## Summary

The contract interacts with interface of ERC20 in several functions. To have safer interactions with ERC20 token it is recommended to use `TransferHelper` library from `Uniswap` instead of calling `IERC20` functions directly:

https://github.com/Uniswap/v3-periphery/blob/main/contracts/libraries/TransferHelper.sol

```diff
- payToken.transferFrom(msg.sender,parentAddress,_totalPayAmount.mul(percentReferralsLv1).div(100));

+ TransferHelper.SafeTransferFrom(address(payToken),msg.sender,parentAddress, _totalPayAmount.mul(percentReferralsLv1).div(100))
```

## Recommended Mitigation

You can find interactions with token interface by searching `payToken` and replacing mentioned approach wherever you called the interface funtion.

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
