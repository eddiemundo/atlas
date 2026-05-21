{- |
Module      : GeniusYield.Types.Era
Copyright   : (c) 2023 GYELD GMBH
License     : Apache 2.0
Maintainer  : support@geniusyield.co
Stability   : develop
-}
module GeniusYield.Types.Era (
  ApiEra,
  ApiLedgerEra,
  apiAlonzoEraOnwards,
  apiAllegraEraOnwards,
  apiAnyShelleyBasedEra,
  apiAsType,
  apiBabbageEraOnwards,
  apiCardanoEra,
  apiConwayEraOnwards,
  apiMaryEraOnwards,
  apiPlutusScriptV1InEra,
  apiPlutusScriptV2InEra,
  apiPlutusScriptV3InEra,
  apiPlutusScriptV4InEra,
  apiSimpleScriptInEra,
  apiSBE,
  dijkstraMaxRefScriptSizePerBlock,
  dijkstraMaxRefScriptSizePerTx,
  dijkstraRefScriptCostMultiplier,
  dijkstraRefScriptCostStride,
) where

import Cardano.Ledger.BaseTypes qualified as Ledger
import Cardano.Api qualified as Api.S
import Data.Maybe (fromMaybe)
import Data.Word (Word32)

-- TODO: Make this module internal.
type ApiEra = Api.S.DijkstraEra

type ApiLedgerEra = Api.S.ShelleyLedgerEra ApiEra

apiAsType :: Api.S.AsType ApiEra
apiAsType = Api.S.AsDijkstraEra

apiCardanoEra :: Api.S.CardanoEra ApiEra
apiCardanoEra = Api.S.DijkstraEra

apiSBE :: Api.S.ShelleyBasedEra ApiEra
apiSBE = Api.S.ShelleyBasedEraDijkstra

apiAnyShelleyBasedEra :: Api.S.AnyShelleyBasedEra
apiAnyShelleyBasedEra = Api.S.AnyShelleyBasedEra apiSBE

apiMaryEraOnwards :: Api.S.MaryEraOnwards ApiEra
apiMaryEraOnwards = Api.S.MaryEraOnwardsDijkstra

apiAllegraEraOnwards :: Api.S.AllegraEraOnwards ApiEra
apiAllegraEraOnwards = Api.S.AllegraEraOnwardsDijkstra

apiAlonzoEraOnwards :: Api.S.AlonzoEraOnwards ApiEra
apiAlonzoEraOnwards = Api.S.AlonzoEraOnwardsDijkstra

apiBabbageEraOnwards :: Api.S.BabbageEraOnwards ApiEra
apiBabbageEraOnwards = Api.S.BabbageEraOnwardsDijkstra

apiConwayEraOnwards :: Api.S.ConwayEraOnwards ApiEra
apiConwayEraOnwards = Api.S.ConwayEraOnwardsDijkstra

apiSimpleScriptInEra :: Api.S.ScriptLanguageInEra Api.S.SimpleScript' ApiEra
apiSimpleScriptInEra = Api.S.SimpleScriptInDijkstra

apiPlutusScriptV1InEra :: Api.S.ScriptLanguageInEra Api.S.PlutusScriptV1 ApiEra
apiPlutusScriptV1InEra = Api.S.PlutusScriptV1InDijkstra

apiPlutusScriptV2InEra :: Api.S.ScriptLanguageInEra Api.S.PlutusScriptV2 ApiEra
apiPlutusScriptV2InEra = Api.S.PlutusScriptV2InDijkstra

apiPlutusScriptV3InEra :: Api.S.ScriptLanguageInEra Api.S.PlutusScriptV3 ApiEra
apiPlutusScriptV3InEra = Api.S.PlutusScriptV3InDijkstra

apiPlutusScriptV4InEra :: Api.S.ScriptLanguageInEra Api.S.PlutusScriptV4 ApiEra
apiPlutusScriptV4InEra = Api.S.PlutusScriptV4InDijkstra

dijkstraMaxRefScriptSizePerBlock :: Word32
dijkstraMaxRefScriptSizePerBlock = 1048576

dijkstraMaxRefScriptSizePerTx :: Word32
dijkstraMaxRefScriptSizePerTx = 204800

dijkstraRefScriptCostStride :: Ledger.NonZero Word32
dijkstraRefScriptCostStride = Ledger.unsafeNonZero 25600

dijkstraRefScriptCostMultiplier :: Ledger.PositiveInterval
dijkstraRefScriptCostMultiplier =
  fromMaybe (error "dijkstraRefScriptCostMultiplier: 1.2 is out of bounds") $
    Ledger.boundRational 1.2
