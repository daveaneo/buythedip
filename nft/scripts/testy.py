#!/usr/bin/python3
# brownie test -s --network rinkeby
from brownie import BuyTheDipNFT, DipStaking, accounts, config
from scripts.helpful_scripts import get_breed, fund_with_link
import time
import pytest
from enum import IntEnum

ACCOUNT_TESTING_TWO = "0xAb0517Ed8EED859deD85Bad8018D462f236e2c07"

# creating enumerations using class
class ConfigurableVariables(IntEnum):
    SwapSlippage = 0
    CheckUpkeepInterval = 1
    MinCoinDeposit = 2
    EarlyWithdrawalFeePercent = 3
    NormalWithdrawalFeePercent = 4
    MintFee = 5
    StableCoinDustThreshold = 6
    ProfitReleaseThreshold = 7


test_counter = 0
BTD_DEPLOYED = False


''' Things to test, ✓ means the test has been created
#BuyTheDipNFT
✓    Creation of NFT Contract
✓    Creation of collectible
✓    Successful buying the dip
✓    Energy, IsWaitingToBuy, DipLevel change after buying dip
✓    Earning interest for NFT holder
✓    Early withdrawal for NFT holder
✓    destroyAndRefund gets funds, sends token to dead address
✓    Contract making money through buying the dip, early withdrawal
    Redip NFT ( needs to be built on website)
✓    NFT Owner receives BNB after dip

#DipStaking
Receiving NFT for staking
Rejection of 0-energy NFT
Rejection of non BuyTheDipNFT (needs to be built on smart contract)
Earn funds
Successful withdrawal of BNB
Successful withdrawal of NFT

NOTES -- Difficult to test staking rewards, as that takes time
'''


def main():
    test_do_tests_in_order()


def print_test(s):
    global test_counter
    print(f'{test_counter}) {s}')
    test_counter += 1


def test_do_tests_in_order():
    pass
    deploy_and_create()
    # verify_packing()
    contract_rewards_and_fees_for_contract_owner()
    contract_rewards_and_fees_for_NFT_owner()
    destroyAndRefund()
    redip_test()
    test_stake_token()
    # todo -- exploitatoin tests

#@pytest.fixture
def deploy_and_create():
    dev = accounts.add(config["wallets"]["from_key"])

    global BTD_DEPLOYED
    if not BTD_DEPLOYED:
        print(f"\n##### Deploying new BuyTheDip contract, creating new collectibles. #####")

        # Deploy
        btd = BuyTheDipNFT.deploy(
            {"from": dev},
            publish_source=False,
        )

        print_test('BuyTheDip Deployed:')
        time.sleep(15)
        assert btd is not None
        BTD_DEPLOYED = True
        dip_staking = DipStaking.deploy(btd.address, {"from": dev}, publish_source=False)
    else:
        btd = BuyTheDipNFT[-1]

    for i in range(1):
        t = btd.createCollectible(i * 15, {"from": dev, "amount": 10 ** 15})  # dictionary needed for payables?
        print_test('NFT Created:')
        assert t is not None

    # perform_upkeep()

    if not BTD_DEPLOYED:
        print_test('Dip Level increases after dip bought:')
        # assert btd.tokenIdToDipLevel(0) == 1

        print_test('IsWaitingToBuy becomes false after dip bought:')
        # assert btd.tokenIdToIsWaitingToBuy(0) is False

        print_test('Token gains energy after dip bought:')
        # assert btd.tokenIdToEnergy(0) > 0


def redip_test():
    # enum DataProperties {DipValue, StableCoinAmount, Energy, DipPercent, DipLevel, IsWaitingToBuy};

    # def perform_upkeep(deploy_and_create):
    print(f'\n#### redip_test ####')
    dev = accounts.add(config["wallets"]["from_key"])
    btd = BuyTheDipNFT[len(BuyTheDipNFT) - 1]

    # dip_value 0
    _id = create_single_collectible(0, 10**15)
    dip_level = btd.getProperty(_id, 4, {"from": dev})
    print_test("dip_level starts at 0")
    assert dip_level == 0, f"starting dip level is not 0, {dip_level}"

    # dip_value 1
    perform_upkeep()

    stable_coin_amount = btd.getProperty(_id, 1, {"from": dev})
    print_test("stable_coin is 0 after buying dip")
    assert stable_coin_amount == 0, f"stable_coin_amount != 0, {stable_coin_amount}"
    dip_level = btd.getProperty(_id, 4, {"from": dev})
    print_test("dip_level is 1 after buying dip")
    assert dip_level == 1, f"Dip level should be 1, {dip_level}"

    # dip_value 2
    btd.redip(_id, {"from": dev, "value": 10**15})
    dip_level = btd.getProperty, _id, 4, {"from": dev}
    stable_coin_amount = btd.getProperty(_id, 1, {"from": dev})
    print_test("stable_coin is greater than 0 after redip")
    assert stable_coin_amount > 0, "stable_coin_amount is 0"
    perform_upkeep()
    dip_level = btd.getProperty(_id, 4, {"from": dev})
    print_test("dip_level is 2 after rebuying dip")
    assert dip_level == 2, f"Dip level should be 2, {dip_level}"


# difficult to test
def earn_interest_while_waiting_to_buy_dip():
# def perform_upkeep(deploy_and_create):
    print(f'\n#### earn_interest_while_waiting_to_buy_dip ####')
    print(f'--testing does not work due to time restrictions.')
    dev = accounts.add(config["wallets"]["from_key"])
    btd = BuyTheDipNFT[len(BuyTheDipNFT) - 1]
    # print(f'Performing Upkeep...')
    # btd.performUpkeepTest({"from": dev});
    initial_balance = btd.lendingBalance(0)
    final_balanace = btd.lendingBalance(0)

    print(f'inital_balance: {initial_balance}, final_balance: {final_balanace}')
    print_test("Lend balance should increase (given enought time")
    assert final_balanace >= initial_balance # bad test. Need more time


def contract_rewards_and_fees_for_NFT_owner():
    print(f'\n#### contract_rewards_and_fees_for_contract_owner ####')

    # For NFT Owner
        # get (some) funds back when destroyingNFT
        # get funds back when buying the dip
        # interest gained while in contract

    dev = accounts.add(config["wallets"]["from_key"])
    btd = BuyTheDipNFT[len(BuyTheDipNFT) - 1]
    dip_staking = DipStaking[len(DipStaking) - 1]

    '''
    ##### fees when minting
    mint_fee_start = btd.getConfiguration(ConfigurableVariables.MintFee)
    btd.changeConfiguration(ConfigurableVariables.MintFee, 9*10**14, {"from": dev})
    mint_fee_end = btd.getConfiguration(ConfigurableVariables.MintFee);
    assert mint_fee_start != mint_fee_end, f'MintFee did not change: {mint_fee_start}'
    assert 9*10**14 == int(mint_fee_end), f'mint_fee_end: {mint_fee_end}, not expected'

    _id = create_single_collectible(25, 10**15)  # generates profit, but not collected

    btd.changeConfiguration(ConfigurableVariables.ProfitReleaseThreshold, 0, {"from": dev})
    bal_beg = dev.balance()
    tx = btd.releaseOwnerProfits({"from": dev})
    bal_end = dev.balance()

    print(f'events: {tx.events}')

    print_test('Contract owner makes profit after minting')
    assert bal_beg < bal_end, f'bal_beg does not increase: {bal_beg} => {bal_end}\ndiff: {bal_end - bal_beg}'

    # Change config back
    btd.changeConfiguration(ConfigurableVariables.ProfitReleaseThreshold, 10**16, {"from": dev})
    btd.changeConfiguration(ConfigurableVariables.MintFee, 10**12, {"from": dev})
    '''

    ##### profit when destroying NFT
    global ACCOUNT_TESTING_TWO
    _id = create_single_collectible(25, 10**15)  # generates profit, but not collected
    # btd.safeTransferFrom(dev, ACCOUNT_TESTING_TWO, _id, {"from": dev})
    btd.changeConfiguration(ConfigurableVariables.EarlyWithdrawalFeePercent, 0, {"from": dev})
    btd.changeConfiguration(ConfigurableVariables.NormalWithdrawalFeePercent, 0, {"from": dev})

    bal_beg = dev.balance()
    tx = btd.destroyAndRefund(_id, {"from": dev})
    bal_end = dev.balance()

    print_test('NFT owner makes profit after destroyAndRefund')
    assert bal_beg < bal_end, f'bal_beg does not increase: {bal_beg} => {bal_end}\ndiff: {bal_end - bal_beg}'

    ##### profit when buying the dip
    _id = create_single_collectible(0, 10**15)
    bal_beg = dev.balance()
    perform_upkeep()
    bal_end = dev.balance()

    print_test('NFT owner makes profit when dip is bought')
    assert bal_beg < bal_end, f'bal_beg does not increase: {bal_beg} => {bal_end}\ndiff: {bal_end - bal_beg}'

    # reinstate fees
    # btd.changeConfiguration(ConfigurableVariables.EarlyWithdrawalFeePercent, 300, {"from": dev})
    # btd.changeConfiguration(ConfigurableVariables.NormalWithdrawalFeePercent, 100, {"from": dev})


def contract_rewards_and_fees_for_contract_owner():
    """# For contractOwner/ProfitReceiver --
            # fees when minting
            # fees when destroying
            # fees when buythedip
    """

    print(f'\n##### Contract makes money Tests #####')
    dev = accounts.add(config["wallets"]["from_key"])
    initial_balance = dev.balance();
    btd = BuyTheDipNFT[len(BuyTheDipNFT) - 1]
    start_profit = btd.contractStableCoinProfit()

    # minting an NFT
    _id = create_single_collectible(0, 10**15)
    end_profit = btd.contractStableCoinProfit()

    print_test("Contract makes money when a NFt is minted.")
    assert start_profit < end_profit, f'profit not the same. Difference: {end_profit - start_profit}'


    # buy the dip
    start_profit = end_profit
    initial_balance = dev.balance();

    perform_upkeep()
    end_profit = btd.contractStableCoinProfit()
    final_balance = dev.balance();

    print(f'expecting these two numbers to be equal (start, final): {initial_balance} , {final_balance }')
    print(f'The difference between them: {final_balance - initial_balance}')
    print(f'start_profit: {start_profit}')
    print(f'end_profit: {end_profit}')

    print_test("Contract makes money when a dip is bought.")
    assert start_profit < end_profit

    # destroyAndRefund NFT
    _id = create_single_collectible(25, 10**15)
    start_profit = btd.contractStableCoinProfit()
    initial_balance = dev.balance()
    btd.destroyAndRefund(_id, {"from": dev})
    final_balance = dev.balance()

    end_profit = btd.contractStableCoinProfit()

    print_test("Contract makes money when a dip is bought.")
    assert start_profit < end_profit


    # Withdrawal to account
    # btd.retrieveLentStablecoins calls releaseProfits, which releases to designated wallet. This happens automatically.
    # _id = create_single_collectible(25, 10**16)
    # start_profit = btd.contractStableCoinProfit()
    # btd.destroyAndRefund(_id, {"from": dev})
    # end_profit = btd.contractStableCoinProfit()
    #
    # print_test("Contract makes money when a dip is bought.")
    # assert start_profit == end_profit


# def test_destroyAndRefund(deploy_and_create):
def destroyAndRefund():

    print(f'\n##### destroyAndRefund Tests #####')
    dev = accounts.add(config["wallets"]["from_key"])
    btd = BuyTheDipNFT[len(BuyTheDipNFT) - 1]
    _id = create_single_collectible(25, 10**15)
    initial_balance = dev.balance()
    t = btd.destroyAndRefund(_id, {"from": dev})  # dictionary needed for payables?)

    print_test("destroyAndRefund call did not fail") # may not be due to gas
    assert t is not None

    print_test("token burnt") # may not be due to gas
    assert "0x000000000000000000000000000000000000dEaD" == btd.ownerOf(_id), f'btd.ownerOf(_id): {btd.ownerOf(_id)}'

    print_test("Balance should be equal or greater after destroyAndRefund") # may not be due to gas
    assert dev.balance() >= initial_balance, f'dev balance decreased. before & after: \n{initial_balance}\n{dev.balance()}'


def test_stake_token():
    print(f'\n##### Staking Tests #####')

    # ✓ test dipStaking receives NFT
    # ✓ test dipStaking generates TotalStakingEnergy as time passes
    # ✓ dipStaking withdraw funds gets profit for NFT owner
    # ✓ dipstaking gets profit for contract owner
    # ✓ dipstaking unstake returns ownership
    # ✓ dipStaking rejects non-whitelisted NFTs
    # ✓ dipStaking receives funds from BTD

    # retrieve contracts
    dev = accounts.add(config["wallets"]["from_key"])
    btd = BuyTheDipNFT[len(BuyTheDipNFT) - 1]
    dip_staking = DipStaking.deploy(btd.address, {"from": dev}, publish_source=False) # returns tx receipt or other object?
    dip_staking = DipStaking[len(DipStaking) - 1]

    # configure
    btd.changeConfiguration(ConfigurableVariables.ProfitReleaseThreshold, 10**18, {"from": dev})


    # ✓ test dipStaking receives NFT
    _id = create_single_collectible(0, 10**15)
    perform_upkeep()
    assert btd.ownerOf(_id) == dev.address, f"dev does not own NFT"
    btd.safeTransferFrom(dev, dip_staking.address, _id, {"from": dev})
    time.sleep(35)
    print_test("dip_staking should be new NFT owner")
    assert btd.ownerOf(_id) == dip_staking.address, f'Transfer to dip_staking has failed. \nNFTowner: {btd.ownerOf(_id)}\ndipStaking: {dip_staking.address}'


    # ✓ test dipStaking generates TotalStakingEnergy as time passes
    energy = dip_staking.getTotalStakingEnergy()
    print_test('Sending NFT to DipStaking gives it energy:')
    assert energy > 0, f'energy: {energy} <-- 0'


    # ✓ dipStaking withdraw funds gets profit for NFT owner
    dev.transfer(dip_staking.address, 10**15)
    bal_before = dev.balance()
    tx = dip_staking.withdrawRewards(_id, {"from": dev})
    time.sleep(15)
    bal_after = dev.balance()
    print_test("previous owner gets a profit in staking")
    assert bal_after > bal_before, f"bal_before: {bal_before}\nbal_after: {bal_after}\ndiff: {bal_after-bal_before}"


    # ✓ dipstaking gets profit for contract owner
    bal_before = dev.balance()
    dip_staking.withdrawRewardsForPrimaryProfitReceiver({"from": dev})
    time.sleep(15)
    bal_after = dev.balance()
    print_test("contract owner gets a profit in staking")
    assert bal_after > bal_before, f"bal_before: {bal_before}\nbal_after: {bal_after}\ndiff: {bal_after-bal_before}"


    # ✓ unstaking returns token, grants funds
    dev.transfer(dip_staking.address, 10**15)
    bal_before = dev.balance()
    tx = dip_staking.unstake(_id, {"from": dev})
    time.sleep(15)
    bal_after = dev.balance()
    print_test("unstaking returns NFT to previous owner")
    assert btd.ownerOf(_id) == dev.address, f"dev does not own NFT"
    print_test("NFT owner gets a profit in staking after unstaking")
    assert bal_after > bal_before, f"bal_before: {bal_before}\nbal_after: {bal_after}\ndiff: {bal_after-bal_before}"


    # ✓ dipStaking rejects non-whitelisted NFTs
    dip_staking.setBTDAdress(dev.address, {"from": dev})
    reverted = False
    try:
        tx = btd.safeTransferFrom(dev, dip_staking.address, _id, {"from": dev})
    except Exception as e:
        # print(f'there should be an error we diagnose: {e}') #todo confirm exact revert language
        # print(f'events: {tx.events}')
        reverted = True;
    finally:
        print_test("non whitelisted NFT causes revert on transfer to staking")
        # todo
        assert reverted, "Transaction failed to revert."
    dip_staking.setBTDAdress(btd.address, {"from": dev})


    # ✓ dipstaking receives founds from BTD
    tx = btd.setProfitReceiver(dip_staking.address, {"from": dev})
    btd.changeConfiguration(ConfigurableVariables.ProfitReleaseThreshold, 0, {"from": dev})
    bal_before = dip_staking.balance()
    _id = create_single_collectible(0, 10**15)
    bal_after = dip_staking.balance()
    print_test("BTD sends funds to DipStaking")
    assert bal_after > bal_before, f"dip_staking balance did not increase. Before, after:\n{bal_before}\n{bal_after}"


    # reset for testing purposes
    tx = btd.setProfitReceiver(dev.address, {"from": dev})
    #   btd.changeConfiguration(ConfigurableVariables.ProfitReleaseThreshold, 0, {"from": dev})


def verify_packing():
    print(f'#### Testing Packing ####')

    dev = accounts.add(config["wallets"]["from_key"])
    btd = BuyTheDipNFT[len(BuyTheDipNFT) - 1]
    dip_staking = DipStaking[len(DipStaking) - 1]

    print_test("packing on BTD works")
    res = btd.verifyPacking()
    assert res == True


    # # dipStaking doesn't have packing. Only structs.
    # print_test("packing on DipStaking works: ")
    # # res = dip_staking.verifyPacking()
    # assert res == True



### HELPERS

def create_single_collectible(percent, eth_amount):
    dev = accounts.add(config["wallets"]["from_key"])
    btd = BuyTheDipNFT[len(BuyTheDipNFT) - 1]
    num_of_collectibles = btd.tokenCounter()
    t = btd.createCollectible(percent, {"from": dev, "amount": eth_amount})  # dictionary needed for payables?)

    assert t is not None
    assert num_of_collectibles + 1 == btd.tokenCounter(), f'{num_of_collectibles +1} != {btd.tokenCounter()}'

    return num_of_collectibles  # token id of new token


def perform_upkeep():
    dev = accounts.add(config["wallets"]["from_key"])
    btd = BuyTheDipNFT[len(BuyTheDipNFT) - 1]
    print(f'Performing Upkeep...')
    tx = btd.performUpkeepTest({"from": dev});
    # print(f'events: {tx.events}')
    # print(f'tx: {tx}')


def reset_all_dip_levels(total_tokens):
    # global total_tokens
    print(f'resetting... total_tokens: {total_tokens}')
    dev = accounts.add(config["wallets"]["from_key"])
    btd = BuyTheDipNFT[len(BuyTheDipNFT) - 1]
    for i in range(total_tokens):
        btd.setDipLevel(i, 0, {"from": dev})
        print(f'resetting {i}... of {total_tokens}')


def set_dip_levels(ids, value):
    dev = accounts.add(config["wallets"]["from_key"])
    btd = BuyTheDipNFT[len(BuyTheDipNFT) - 1]
    for i in ids:
        btd.setDipLevel(i, value, {"from": dev})


def print_all_dip_levels():
    # currently broken after refactoring BTD
    dev = accounts.add(config["wallets"]["from_key"])
    btd = BuyTheDipNFT[len(BuyTheDipNFT) - 1]
    total_tokens = btd.tokenCounter()
    for i in range(total_tokens):
#        print(f'{i}) dipLevel:  {btd.tokenIdToDipLevel(i)}')
        pass
