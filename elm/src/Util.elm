module Util exposing (..)

-- import CtagsParser exposing (File, Tag, TagType(..), FileType(Elm))

import Set
import Maybe.Extra
import String.Extra


allEqual : List comparable -> Bool
allEqual xs =
    Set.fromList xs
        |> (Set.size >> (==) 1)


{-| Finds the longest string that each of the strings start with
-}
commonStartsWith : List String -> String
commonStartsWith strings =
    let
        commonStartsWith_ : List String -> String -> String
        commonStartsWith_ strings_ startsWithAcc =
            let
                unconsStrings =
                    List.map String.uncons strings_
            in
                if not <| List.all Maybe.Extra.isJust unconsStrings then
                    -- if any of the remainder strings are empty, then we are done
                    startsWithAcc
                else
                    -- filter out values from the Justs
                    unconsStrings
                        |> List.filterMap identity
                        |> List.foldl
                            (\( head, tail ) ( heads, tails ) ->
                                ( head :: heads, tail :: tails )
                            )
                            ( [], [] )
                        -- now we have alist of heads and a list of tails
                        |>
                            (\( heads, tails ) ->
                                if not <| allEqual heads then
                                    -- if any of the heads are different, we are done
                                    startsWithAcc
                                else
                                    case List.head heads of
                                        Nothing ->
                                            startsWithAcc

                                        Just head ->
                                            -- commonStartsWith_ tails (startsWithAcc ++ String.fromChar head)
                                            commonStartsWith_ tails (startsWithAcc ++ String.fromChar head)
                            )
    in
        commonStartsWith_ strings ""


removeBasePath : String -> String -> String
removeBasePath basePath s =
    String.Extra.replace basePath "" s
