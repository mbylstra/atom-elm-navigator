module Tests exposing (..)

import Test exposing (..)
import Expect
import Util exposing (allEqual, commonStartsWith)
import SymbolNavigator exposing (..)
import Factories exposing (..)


all : Test
all =
    describe "All"
        [ describe "Util.elm"
            [ describe "allEqual"
                [ test "two that are the same" <|
                    \() ->
                        allEqual [ 1, 1 ]
                            |> Expect.equal True
                , test "one different of three" <|
                    \() ->
                        allEqual [ 1, 1, 2 ]
                            |> Expect.equal False
                , test "single item list" <|
                    \() ->
                        allEqual [ 1 ]
                            |> Expect.equal True
                , test "empty list" <|
                    \() ->
                        allEqual []
                            |> Expect.equal False
                , test "two a chars" <|
                    \() ->
                        allEqual [ 'a', 'a' ]
                            |> Expect.equal True
                ]
            , describe "commonStartsWith"
                [ test "empty list" <|
                    \() ->
                        commonStartsWith []
                            |> Expect.equal ""
                , test "list of empty strings" <|
                    \() ->
                        commonStartsWith [ "", "" ]
                            |> Expect.equal ""
                , test "list of two a's" <|
                    \() ->
                        commonStartsWith [ "a", "a" ]
                            |> Expect.equal "a"
                , test "list of one a" <|
                    \() ->
                        commonStartsWith [ "a" ]
                            |> Expect.equal "a"
                , test "list of a,a,b" <|
                    \() ->
                        commonStartsWith [ "a", "a", "b" ]
                            |> Expect.equal ""
                , test "list bark, bad, band = ba" <|
                    \() ->
                        commonStartsWith [ "bark", "bad", "band" ]
                            |> Expect.equal "ba"
                , test "list bark, bad, band = ba" <|
                    \() ->
                        commonStartsWith [ "/home/code/One.elm", "/home/code/Two.elm", "/home/code/Three.elm" ]
                            |> Expect.equal "/home/code/"
                ]
            ]
        , describe "SymbolNavigator.elm"
            [ describe "replaceTagsForFilePath"
                [ test "updating a symbol name should preserve file order" <|
                    \() ->
                        let
                            filePath2 =
                                "/home/elm/File2.elm"

                            file2 =
                                { file | filePath = filePath2, name = "File2.elm" }

                            tag2 =
                                { tag | file = file2 }

                            result : List Tag
                            result =
                                replaceTagsForFilePath
                                    { filePath = "/home/elm/File2.elm"
                                    , rawTags =
                                        [ { rawTag | symbol = "SymbolRenamed", filePath = filePath2 } ]
                                    }
                                    [ tag, tag2 ]
                        in
                            Expect.all
                                [ Expect.equalLists [ tag, { tag2 | symbol = "SymbolRenamed" } ]
                                , (\subject -> Expect.equal 2 (List.length subject))
                                ]
                                result
                ]
            ]
        ]
