{-|
Module      : GeniusYield.Types.TxBody
Copyright   : (c) 2023 GYELD GMBH
License     : Apache 2.0
Maintainer  : support@geniusyield.co
Stability   : develop

-}
module GeniusYield.Types.TxBody (
    -- * Transaction body
    GYTxBody,
    -- * Conversions
    txBodyFromApi,
    txBodyToApi,
    -- * Transaction creation
    signTx,
    unsignedTx,
    makeSignedTransaction,
    -- * Functions
    txBodyFee,
    txBodyFeeValue,
    txBodyUTxOs,
    txBodyTxIns,
    txBodyTxInsReference,
    txBodyTxId,
    txBodyToApiTxBodyContent,
    txBodyMintValue,
    txBodyValidityRange,
    txBodyCollateral,
    txBodyCollateralReturnOutput,
    txBodyCollateralReturnOutputValue,
    txBodyTotalCollateralLovelace,
    txBodyRequiredExtraWitnesses,
    getTxBody,
) where


import qualified Cardano.Api                 as Api
import qualified Cardano.Api.Shelley         as Api.S
import qualified Data.Set                    as Set

import           GeniusYield.Imports
import           GeniusYield.Types.Key.Class (ToShelleyWitnessSigningKey,
                                              toShelleyWitnessSigningKey)
import           GeniusYield.Types.Slot
import           GeniusYield.Types.Tx
import           GeniusYield.Types.TxOutRef
import           GeniusYield.Types.UTxO
import           GeniusYield.Types.Value
import GeniusYield.Types.PubKeyHash (GYPubKeyHash, pubKeyHashFromApi)

-- | Transaction body: the part which is then signed.
newtype GYTxBody = GYTxBody (Api.TxBody Api.BabbageEra)
  deriving Show

txBodyFromApi :: Api.TxBody Api.BabbageEra -> GYTxBody
txBodyFromApi = coerce

txBodyToApi :: GYTxBody -> Api.TxBody Api.BabbageEra
txBodyToApi = coerce

-- | Sign a transaction body with (potentially) multiple keys.
signTx :: ToShelleyWitnessSigningKey a =>  GYTxBody -> [a] -> GYTx
signTx (GYTxBody txBody) skeys = txFromApi $ Api.signShelleyTransaction txBody $ map toShelleyWitnessSigningKey skeys

-- | Make a signed transaction given the transaction body & list of key witnesses.
makeSignedTransaction :: GYTxWitness -> GYTxBody -> GYTx
makeSignedTransaction txWit (GYTxBody txBody) = txFromApi $ Api.makeSignedTransaction (txWitToKeyWitnessApi txWit) txBody

-- | Create an unsigned transaction from the body.
unsignedTx :: GYTxBody -> GYTx
unsignedTx (GYTxBody body) = txFromApi (Api.Tx body [])

txBodyRequiredExtraWitnesses :: GYTxBody -> [GYPubKeyHash]
txBodyRequiredExtraWitnesses (GYTxBody (Api.TxBody Api.TxBodyContent{ Api.txExtraKeyWits })) =
  case txExtraKeyWits of
    Api.TxExtraKeyWitnessesNone -> []
    Api.TxExtraKeyWitnesses _ pkhs -> fmap pubKeyHashFromApi pkhs

-- | Return the fees in lovelace.
txBodyFee :: GYTxBody -> Integer
txBodyFee (GYTxBody (Api.TxBody Api.TxBodyContent { Api.txFee = fee })) =
    case fee of
        Api.TxFeeImplicit x                       -> case x of {}
        Api.TxFeeExplicit _ (Api.Lovelace actual) -> actual

-- | Return the fees as 'GYValue'.
txBodyFeeValue :: GYTxBody -> GYValue
txBodyFeeValue = valueFromLovelace . txBodyFee

-- | Return utxos created by tx (body).
txBodyUTxOs :: GYTxBody -> GYUTxOs
txBodyUTxOs (GYTxBody body@(Api.TxBody Api.TxBodyContent {txOuts})) =
    utxosFromList $ zipWith f [0..] txOuts
  where
    txId = Api.getTxId body

    f :: Word -> Api.TxOut Api.CtxTx Api.BabbageEra -> GYUTxO
    f i = utxoFromApi (Api.TxIn txId (Api.TxIx i))

-- | Returns the 'GYTxOutRef' consumed by the tx.
txBodyTxIns :: GYTxBody -> [GYTxOutRef]
txBodyTxIns (GYTxBody (Api.TxBody Api.TxBodyContent {txIns})) = map (txOutRefFromApi . fst) txIns

-- | Returns the 'GYTxOutRef' for the reference inputs present in the tx.
txBodyTxInsReference :: GYTxBody -> [GYTxOutRef]
txBodyTxInsReference (GYTxBody (Api.TxBody Api.TxBodyContent {txInsReference})) = case txInsReference of
  Api.TxInsReferenceNone                                                        -> []
  Api.TxInsReference Api.S.ReferenceTxInsScriptsInlineDatumsInBabbageEra inRefs -> map txOutRefFromApi inRefs

-- | Returns the 'GYTxId' of the given 'GYTxBody'.
txBodyTxId :: GYTxBody -> GYTxId
txBodyTxId = txIdFromApi . Api.getTxId . txBodyToApi

-- | Returns the 'GYTxBody' of the given 'GYTx'.
getTxBody :: GYTx -> GYTxBody
getTxBody = txBodyFromApi . Api.getTxBody . txToApi

txBodyToApiTxBodyContent :: GYTxBody -> Api.TxBodyContent Api.ViewTx Api.BabbageEra
txBodyToApiTxBodyContent body = let Api.TxBody bc = txBodyToApi body in bc

-- | Returns the mint 'GYValue' of the given 'GYTxBody'.
txBodyMintValue :: GYTxBody -> GYValue
txBodyMintValue body = case Api.txMintValue $ txBodyToApiTxBodyContent body  of
    Api.TxMintNone        -> mempty
    Api.TxMintValue _ v _ -> valueFromApi v

-- | Returns the validity range of the given 'GYTxBody'.
txBodyValidityRange :: GYTxBody -> (Maybe GYSlot, Maybe GYSlot)
txBodyValidityRange body = case Api.txValidityRange $ txBodyToApiTxBodyContent body of
    (lb, ub) -> (f lb, g ub)
  where
    f :: Api.TxValidityLowerBound Api.BabbageEra -> Maybe GYSlot
    f Api.TxValidityNoLowerBound      = Nothing
    f (Api.TxValidityLowerBound _ sn) = Just $ slotFromApi sn

    g :: Api.TxValidityUpperBound Api.BabbageEra -> Maybe GYSlot
    g (Api.TxValidityNoUpperBound _)  = Nothing
    g (Api.TxValidityUpperBound _ sn) = Just $ slotFromApi sn

-- | Returns the set of 'GYTxOutRef' used as collateral in the given 'GYTxBody'.
txBodyCollateral :: GYTxBody -> Set GYTxOutRef
txBodyCollateral body = case Api.txInsCollateral $ txBodyToApiTxBodyContent body of
    Api.TxInsCollateralNone  -> Set.empty
    Api.TxInsCollateral _ xs -> Set.fromList $ txOutRefFromApi <$> xs

-- | Returns the total collateral for the given transaction body.
txBodyTotalCollateralLovelace :: GYTxBody -> Natural
txBodyTotalCollateralLovelace body = case Api.txTotalCollateral $ txBodyToApiTxBodyContent body of
    Api.TxTotalCollateralNone -> 0
    Api.TxTotalCollateral _ (Api.Lovelace l)
        | l >= 0              -> fromInteger l
        | otherwise           -> error $ "negative total collateral: " <> show l

txBodyCollateralReturnOutput :: GYTxBody -> Api.TxReturnCollateral Api.CtxTx Api.BabbageEra
txBodyCollateralReturnOutput body = Api.txReturnCollateral $ txBodyToApiTxBodyContent body

txBodyCollateralReturnOutputValue :: GYTxBody -> GYValue
txBodyCollateralReturnOutputValue body =
  case Api.txReturnCollateral $ txBodyToApiTxBodyContent body of
    Api.TxReturnCollateralNone                   -> mempty
    Api.TxReturnCollateral _ (Api.TxOut _ v _ _) -> valueFromApi $ Api.txOutValueToValue v
