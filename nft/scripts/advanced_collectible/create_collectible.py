#!/usr/bin/python3
from brownie import BuyTheDipNFT, accounts, config, SimpleToken
from scripts.helpful_scripts import get_breed, fund_with_link
import time


def print_all_NFTs(btd):
    number_of_btds = btd.tokenCounter()
    for token_id in range(number_of_btds):
        dip_level = btd.tokenIdToDipLevel(token_id)
        print(f'Dip level of tokenId {token_id} is {dip_level}')

def main():
    dev = accounts.add(config["wallets"]["from_key"])
    print(f'You have deployed {len(BuyTheDipNFT)} Collectable.')
    # Get the latest of the collectables
    btd = BuyTheDipNFT[len(BuyTheDipNFT) - 1]
    # fund_with_link(btd.address)
    transactions = []
    NFTs_to_create = 3;

    for i in range(NFTs_to_create):
        t = btd.createCollectible(i*15*0,  {"from": dev, "amount":10**16}) # dictionary needed for payables?
        transactions.append(t)

    print(f'Number of NFTs: {len(transactions)}')
    print("Waiting on second transaction...")
    # wait for the 2nd transaction

    if NFTs_to_create:
        t = transactions[-1]
        t.wait(1)
        time.sleep(35)
    else:
        t = []

    # for t in transactions:
    #     requestId = t.events["requestedCollectible"]["requestId"]
    #     token_id = btd.requestIdToTokenId(requestId)
    #     print(f't: {t}, id: {token_id}, request_id: {requestId}');


    # requestId = transaction.events["requestedCollectible"]["requestId"]
    # token_id = btd.requestIdToTokenId(requestId)
    # breed = get_breed(btd.tokenIdToBreed(token_id))
    # print(f'Dog breed of tokenId {token_id} is {breed}')

    # simp = SimpleToken[len(SimpleToken) - 1]
    # print(f'Dev ETH balance: {dev.balance()}')
    # print(f'BuyTheDip ETH balance: {btd.balance()}')

    # print(f'simp balance of dev: {simp.balanceOf(accounts[0])}')

    # print(f'simp address:  {simp}')
    # print(f'simp ETH balance?: {simp.balance()}')
    # print(f'accounts[0]: {accounts[0]}')
    # print(f'simp balance of dev: {simp.balanceOf(accounts[0])}')
    # print(f'simp balance of advanced collectable: {simp.balanceOf(btd)}')

    print(f'\nThese are all the NFTs ({btd.tokenCounter()}) in this collection.')
    print_all_NFTs(btd)

    print(f'btd address: {btd}')

    price = btd.getLatestPrice()
    price = int(price)
    print(f'Latest price of ETH: {price}')
