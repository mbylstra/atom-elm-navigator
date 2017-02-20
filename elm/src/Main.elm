module Main exposing (..)

import Html
import SymbolNavigator exposing (Model, Msg, init, update, view, subscriptions, Flags)


main : Program Never Model Msg
main =
    Html.program
        { init = init ! []
        , update = update
        , view = view
        , subscriptions = (\_ -> subscriptions)
        }
