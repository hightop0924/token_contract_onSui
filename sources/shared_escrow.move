// Copyright (c) Mysten Labs, Inc.
// SPDX-License-Identifier: Apache-2.0

/// An escrow for atomic swap of objects without a trusted third party
module defi::shared_escrow {
    use std::option::{Self, Option};

    use sui::object::{Self, ID, UID};
    use sui::transfer;
    use sui::tx_context::{Self, TxContext};

    /// An object held in escrow
    struct EscrowedObj<T: key + store, phantom ExchangeForT: key + store> has key, store {
        id: UID,
        /// owner of the escrowed object
        creator: address,
        /// intended recipient of the escrowed object
        recipient: address,
        /// ID of the object `creator` wants in exchange
        exchange_for: ID,
        /// the escrowed object
        escrowed: Option<T>,
    }

    // Error codes
    /// The `recipient` of the escrow can exchange `obj` with the escrowed item
    public entry fun exchange<T: key + store, ExchangeForT: key + store>(
        obj: ExchangeForT,
        escrow: &mut EscrowedObj<T, ExchangeForT>,
        ctx: &TxContext
    ) {
        assert!(option::is_some(&escrow.escrowed), EAlreadyExchangedOrCancelled);
        let escrowed_item = option::extract<T>(&mut escrow.escrowed);
        assert!(&tx_context::sender(ctx) == &escrow.recipient, EWrongRecipient);
        assert!(object::borrow_id(&obj) == &escrow.exchange_for, EWrongExchangeObject);
        // everything matches. do the swap!
        transfer::public_transfer(escrowed_item, tx_context::sender(ctx));
        transfer::public_transfer(obj, escrow.creator);
    }

    /// The `creator` can cancel the escrow and get back the escrowed item
    public entry fun cancel<T: key + store, ExchangeForT: key + store>(
        escrow: &mut EscrowedObj<T, ExchangeForT>,
        ctx: &TxContext
    ) {
        assert!(&tx_context::sender(ctx) == &escrow.creator, EWrongOwner);
        assert!(option::is_some(&escrow.escrowed), EAlreadyExchangedOrCancelled);
        transfer::public_transfer(option::extract<T>(&mut escrow.escrowed), escrow.creator);
    }
}
