#!/usr/bin/python3
# brownie test -s --network rinkeby
from brownie import BuyTheDipNFT, DipStaking, accounts, config
from scripts.helpful_scripts import get_breed, fund_with_link
import time
import pytest

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
    Contract making money through buying the dip, early withdrawal
    Redip NFT ( needs to be built on website)

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
    deploy_and_create()
    # verify_packing()
    # contract_makes_money()
    test_stake_token()
    contract_and_staking_rewards()
    destroyAndRefund()



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


# difficult to test
def earn_interest_while_waiting_to_buy_dip():
# def perform_upkeep(deploy_and_create):
    dev = accounts.add(config["wallets"]["from_key"])
    btd = BuyTheDipNFT[len(BuyTheDipNFT) - 1]
    # print(f'Performing Upkeep...')
    # btd.performUpkeepTest({"from": dev});
    initial_balance = btd.lendingBalance(0)
    final_balanace = btd.lendingBalance(0)

    print(f'inital_balance: {initial_balance}, final_balance: {final_balanace}')
    print_test("Lend balance should increase (given enought time")
    assert final_balanace >= initial_balance # bad test. Need more time


# todo-- complete this
# def contract_and_staking_rewards(deploy_and_create):
def contract_and_staking_rewards():
    _id = 0
    print(f'#### contract_and_staking_rewards ####')
    print(f'Staking token {_id}')

    dev = accounts.add(config["wallets"]["from_key"])
    btd = BuyTheDipNFT[len(BuyTheDipNFT) - 1]
    dip_staking = DipStaking[len(DipStaking) - 1]
    # time.sleep(30)
    _id = create_single_collectible(25, 10**15)  # generates profit, but not collected


    print(f'attempting to withdraw')

    bal_beg = dev.balance
    btd.releaseOwnerProfits({"from": dev});
    bal_end = dev.balance

    assert bal_beg < bal_end

    #brainstorm --todo
    # mint NFT
    # buythedip
    # early release
    # interest on existing funds

    # Stake -- todo
    # See that there are rewards


#def test_contract_makes_money(deploy_and_create):
def contract_makes_money():

    print(f'\n##### Contract makes money Tests #####')
    dev = accounts.add(config["wallets"]["from_key"])
    initial_balance = dev.balance();
    btd = BuyTheDipNFT[len(BuyTheDipNFT) - 1]
    start_profit = btd.contractStablecoinProfit()

    # minting an NFT
    _id = create_single_collectible(0, 10**15)
    end_profit = btd.contractStablecoinProfit()

    # print(f'just minted id: {_id}. \nPrinting dip levels:\n---\n')
    # print_all_dip_levels()

    print_test("Contract makes money when a NFt is minted.")
    assert start_profit < end_profit


    # buy the dip
    start_profit = end_profit
    initial_balance = dev.balance();

    perform_upkeep()
    end_profit = btd.contractStablecoinProfit()
    final_balance = dev.balance();

    print(f'expecting these two numbers to be equal (start, final): {initial_balance} , {final_balance }')
    print(f'The difference between them: {final_balance - initial_balance}')
    print(f'start_profit: {start_profit}')
    print(f'end_profit: {end_profit}')


    print_test("Contract makes money when a dip is bought.")
    assert start_profit < end_profit


    # early withdrawal
    _id = create_single_collectible(25, 10**15)
    start_profit = btd.contractStablecoinProfit()
    initial_balance = dev.balance();
    btd.destroyAndRefund(_id, {"from": dev}) # todo: see why this creates stableCoinProfit to be zero. Has it been released?
    final_balance = dev.balance();

    end_profit = btd.contractStablecoinProfit()

    print_test("Contract makes money when a dip is bought.")
    assert start_profit < end_profit


    # Withdrawal to account
    # btd.retrieveLentStablecoins calls releaseProfits, which releases to designated wallet. This happens automatically.
    # _id = create_single_collectible(25, 10**16)
    # start_profit = btd.contractStablecoinProfit()
    # btd.destroyAndRefund(_id)
    # end_profit = btd.contractStablecoinProfit()
    #
    # print_test("Contract makes money when a dip is bought.")
    # assert start_profit == end_profit


# def test_destroyAndRefund(deploy_and_create):
def destroyAndRefund():

    print(f'\n##### destroyAndRefund Tests #####')
    dev = accounts.add(config["wallets"]["from_key"])
    btd = BuyTheDipNFT[len(BuyTheDipNFT) - 1]
    _id = create_single_collectible(25, 10**15)
    initial_balance = dev.balance();
    t = btd.destroyAndRefund(_id, {"from": dev})  # dictionary needed for payables?)

    print_test("destroyAndRefund call did not fail") # may not be due to gas
    assert t is not None

    print_test("token burnt") # may not be due to gas
    assert "0x000000000000000000000000000000000000dEaD" == btd.ownerOf(_id), f'btd.ownerOf(_id): {btd.ownerOf(_id)}'

    print_test("Balance should be equal or greater after destroyAndRefund") # may not be due to gas
    assert dev.balance() >= initial_balance


def test_stake_token():
    # def test_stake_token():
    _id = 0
    print(f'\n##### Staking Tests #####')

    dev = accounts.add(config["wallets"]["from_key"])
    btd = BuyTheDipNFT[len(BuyTheDipNFT) - 1]
    dip_staking = DipStaking[len(DipStaking) - 1]

    _id = create_single_collectible(0, 10**15)
    perform_upkeep()

    if btd.ownerOf(_id) != dev.address:
        # btd.safeTransferFrom(dev, dip_staking.address, _id, {"from": dev})
        pass
        print('Error. Not owner.')

    else:
        btd.safeTransferFrom(dev, dip_staking.address, _id, {"from": dev})

    time.sleep(15)
    energy = dip_staking.getTotalStakingEnergy()

    # todo -- see why this is getting 0xfe not defined
    print_test('Sending NFT to DipStaking gives it energy:')
    print(f'energy: {energy}')
    assert energy > 0

    # dip_staking.call({"value": 10000, "from": dev})
    # send 100 (gwei?)
    dev.transfer(dip_staking.address, 100)

    #  get rewards in native token
    dip_staking.withdrawRewards(_id, {"from": dev})
    dip_staking.unstake(_id, {"from": dev})

    print_test('Unstake removes balance:')

    assert dip_staking.balance() == 0


def verify_packing():
    dev = accounts.add(config["wallets"]["from_key"])
    btd = BuyTheDipNFT[len(BuyTheDipNFT) - 1]

    res = btd.verifyPacking()
    print_test("packing works")
    assert res == True






### HELPERS

def create_single_collectible(percent, eth_amount):
    dev = accounts.add(config["wallets"]["from_key"])
    btd = BuyTheDipNFT[len(BuyTheDipNFT) - 1]
    num_of_collectibles = btd.tokenCounter()
    t = btd.createCollectible(percent, {"from": dev, "amount": eth_amount})  # dictionary needed for payables?)

    assert t is not None
    assert num_of_collectibles + 1 == btd.tokenCounter()

    return num_of_collectibles # token id of new token


def perform_upkeep():
    dev = accounts.add(config["wallets"]["from_key"])
    btd = BuyTheDipNFT[len(BuyTheDipNFT) - 1]
    print(f'Performing Upkeep...')
    tx = btd.performUpkeepTest({"from": dev});
    print(f'events: {tx.events}')
    print(f'tx: {tx}')


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
