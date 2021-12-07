#!/usr/bin/python3
from brownie import BuyTheDipNFT, DipStaking, accounts, config
from scripts.helpful_scripts import get_breed, fund_with_link
import time


def main():
    dev = accounts.add(config["wallets"]["from_key"])

    print(f'You have deployed {len(BuyTheDipNFT)} Collectable(s).')

    # Get the latest of the collectables
    # print(f'Total number of collectibles: {len(BuyTheDipNFT)}')
    btd = BuyTheDipNFT[len(BuyTheDipNFT) - 1]

    create_single_collectible(0, 10**15)

    total_tokens = btd.tokenCounter()

    print(f'NFTs in latest deployment: {total_tokens}')

    # reset_all_dip_levels(total_tokens)
    print(f'Dip Levels:')
    print_all_dip_levels(total_tokens)
    perform_upkeep()
    # print(f'After upkeep:')
    # print_all_dip_levels(total_tokens)

    print("Staking token 0")
    stake_token(0)

    # set_dip_levels(set(range(btd.tokenCounter())),1)

    # side_piece()


def stake_token(_id):
    dev = accounts.add(config["wallets"]["from_key"])
    btd = BuyTheDipNFT[len(BuyTheDipNFT) - 1]
    dip_staking = DipStaking[len(DipStaking) - 1]

    print(f'dev: {dev}')
    print(f'dipStaking address: {dip_staking.address}')
    print(f'BTD address: {btd.address}')


    # btd.approve(dip_staking.address, 0, {"from": dev})
    btd.safeTransferFrom(dev, dip_staking.address, _id, {"from": dev})
    time.sleep(5)
    energy = dip_staking.getTotalStakingEnergy()
    print(f"energy: {energy}")

    assert energy > 0

    # dip_staking.call({"value": 10000, "from": dev})
    dev.transfer(dip_staking.address, 100)
    print(f'Balance before: {dip_staking.balance()}')
    print(f'Unstaking and claiming rewards...')
    dip_staking.withdrawRewards(_id, {"from": dev})
    dip_staking.unstake(_id, {"from": dev})
    print(f'Balance after: {dip_staking.balance()}')

    assert dip_staking.balance() == 0


def print_all_dip_levels(total_tokens):
    dev = accounts.add(config["wallets"]["from_key"])
    btd = BuyTheDipNFT[len(BuyTheDipNFT) - 1]
    # total_tokens = btd.tokenCounter()
    for i in range(total_tokens):
        print(f'{i}) dipLevel:  {btd.tokenIdToDipLevel(i)}')


def set_dip_levels(ids, value):
    dev = accounts.add(config["wallets"]["from_key"])
    btd = BuyTheDipNFT[len(BuyTheDipNFT) - 1]
    for i in ids:
        btd.setDipLevel(i, value, {"from": dev})



def reset_all_dip_levels(total_tokens):
    # global total_tokens
    print(f'resetting... total_tokens: {total_tokens}')
    dev = accounts.add(config["wallets"]["from_key"])
    btd = BuyTheDipNFT[len(BuyTheDipNFT) - 1]
    for i in range(total_tokens):
        btd.setDipLevel(i, 0, {"from": dev})
        print(f'resetting {i}... of {total_tokens}')


def perform_upkeep():
    dev = accounts.add(config["wallets"]["from_key"])
    btd = BuyTheDipNFT[len(BuyTheDipNFT) - 1]
    print(f'Performing Upkeep...')
    btd.performUpkeepTest({"from": dev});


def side_piece():
    for i in range(len(BuyTheDipNFT)):
        if BuyTheDipNFT[i] == "0x486424aa6c5f9b90789dc6e5843581e69a89b895":
            print(f'Found at {i}')
            print(BuyTheDipNFT[i].tokenURI)


def create_single_collectible(percent, eth_amount):
    dev = accounts.add(config["wallets"]["from_key"])
    btd = BuyTheDipNFT[len(BuyTheDipNFT) - 1]
    num_of_collectibles = btd.tokenCounter()
    try:
        tx = btd.createCollectible(percent, {"from": dev, "amount": eth_amount})  # dictionary needed for payables?)
    except Exception as e:
        print(f'Transaction failed."')
        print(f'e: {e}')

    if tx: print(f'tx.info(): {tx.info()}')


    assert tx is not None
    assert num_of_collectibles + 1 == btd.tokenCounter()

    return num_of_collectibles # token id of new token
