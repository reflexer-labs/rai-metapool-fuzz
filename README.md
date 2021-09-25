# RAI Metapool Fuzz

Fuzz campaign for the RAI Curve metapool implementation (factory).

To run the fuzzer, set up Echidna (https://github.com/crytic/echidna).

To run:
```
echidna-test src/RaiMetaPoolFuzz.sol --contract RaiMetaPoolFuzz --config echidna.yaml
```

## Changes made to the original contracts

Minor changes were made to the original contracts to enable this setup:

### 3pool
- Accepting token addresses in initialize

### RAI Metapool
- Base pool info (BASE_POOL and BASE_COINS) are now storage variables initialized through ```initialize()```
- Removed the constructor (allowing implementation to be used as a pool, without a proxy)

Original and modified contracts are in the folder _src/vyper_.

## Goal
The RAI metapool is a slightly modified version of the metaUSD pool currently used by the Metapool Factory.

The rate for RAI is adjusted using a snapshot of the current `redemptionPrice` (on the original metapool the rate is always set to 1 and used to adjust for different token decimals).

The original implementation has been audited and has been battletested for months.

The goal of this campaign is to verify that the metapool changes do not affect the contract in any harmful way and swaps behave as intended.

## Description
Both 3pool and a RAI metapool are deployed.

3pool is initialized with $90mm and the RAI meta pool with 166,000 RAI and the equivalent in 3pool (around the minimum threshold to be listed in Curve's UI).

The script will perform swaps (also with the underlying 3pool tokens), and check received amounts (allowing for a slippage threshold).

The redemption price starts at $3 and deviates within a preset window.

Callers have unlimited token balances. The number of different users can be set in echidna.yaml.

Calls that revert with a ```require```are not considered failures.

## Results

### Initial params:
- A is set to 100 (same as FRAX and LUSD)
- Swaps between 1 and 3001 Token
- seqLen (echidna.yaml) set to 50
- Redemption price deviation: 5%
- Accepted slippage: 1%
- Each run performs 200k calls

```
assertion in swap: passed! 🎉
Seed: -7833100418140387905
```

Running swaps of limited value ensure that all swaps go through (the pool isn't depleted by one large swap or several swaps to the same side). Removing the cap from the swap, we can have an insight on the size of a single trade needed to cause a slippage of 1% (echidna will shrink the input to the approximate minimum failure):

```
assertion in swap: failed!💥
  Call sequence, shrinking (5000/5000):
    swap(false,141174359536023270922483)


Seed: -1561486297794490057
```

141,174.359536... or ~30% of the total token supply (from) liquidity.

67,326.23 (13%) for .5% slippage.

Testing with different amplification factors we get:
| A | trade size | Size in relation to pool
| - | -:| -:|
| 10 | 23867.93145 | 4.79% |
| 100 | 141174.3595	| 28.35% |
| 2000 | 351745.9759| 70.63% |

To test for larger swaps, we then increased the trade limit to 30k and set seqLen to 5 (A set to 100).

```
assertion in swap: passed! 🎉
Seed: -7016443365875589214
```

## Conclusion
No exceptions noted. The pool behaves as inteded in the described scenario, with the main difference from the currently in prod metapool taken into consideration (RAI's moving redemption price).
