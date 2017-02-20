module Factories exposing (..)

import File
import SymbolNavigator


tag : SymbolNavigator.Tag
tag =
    { symbol = "dummyFunction"
    , file = file
    , context = "dummyFunction : String -> Bool"
    , type_ = SymbolNavigator.Function
    , lineNumber = 10
    }


file : File.File
file =
    { name = "Dummy.elm"
    , dirPath = [ "home", "elm" ]
    , fileType = File.Elm
    , absolute = True
    , filePath = "/home/elm/Dummy.elm"
    }


rawTag : SymbolNavigator.RawTag
rawTag =
    { context = "dummyFunction : String -> Bool"
    , lineNumber = 10
    , symbol = "dummyFunction"
    , type_ = "Function"
    , filePath = "/home/elm/Dummy.elm"
    }
