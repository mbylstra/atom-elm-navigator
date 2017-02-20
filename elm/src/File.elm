module File exposing (..)

import List.Extra


type FileType
    = Elm
    | FileTypeUnknown


type alias File =
    { name : String
    , dirPath : List String
    , fileType : FileType
    , absolute : Bool
    , filePath : String
    }


toFullPath : File -> String
toFullPath file =
    "/" ++ (String.join "/" file.dirPath) ++ "/" ++ file.name


parseFileType : String -> FileType
parseFileType filename =
    if String.endsWith ".elm" filename then
        Elm
    else
        FileTypeUnknown


parseFilePath : String -> File
parseFilePath filePath =
    let
        ( absolute, filePathTail ) =
            if String.startsWith "/" filePath then
                ( True, String.uncons filePath |> Maybe.withDefault ( '/', "" ) |> Tuple.second )
            else
                ( False, filePath )
    in
        filePathTail
            |> String.split "/"
            |> List.reverse
            |> List.Extra.uncons
            |> Maybe.withDefault ( "", [] )
            |> (\( name, reversedDirPath ) ->
                    { name = name
                    , dirPath = List.reverse reversedDirPath
                    , fileType = parseFileType name
                    , absolute = absolute
                    , filePath = filePath
                    }
               )
