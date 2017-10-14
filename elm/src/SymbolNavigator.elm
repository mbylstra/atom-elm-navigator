port module SymbolNavigator
    exposing
        ( Model
        , Flags
        , Msg
        , init
        , update
        , view
        , subscriptions
        , Tag
        , TagType(..)
        , RawTag
        , replaceTagsForFilePath
        )

import Html
    exposing
        -- delete what you don't need
        ( Html
        , div
        , span
        , img
        , p
        , a
        , h1
        , h2
        , h3
        , h4
        , h5
        , h6
        , h6
        , text
        , ol
        , ul
        , li
        , dl
        , dt
        , dd
        , form
        , input
        , textarea
        , button
        , select
        , option
        , table
        , caption
        , tbody
        , thead
        , tr
        , td
        , th
        , em
        , strong
        , blockquote
        , hr
        )
import Html.Attributes
    exposing
        ( style
        , class
        , classList
        , id
        , title
        , hidden
        , type_
        , checked
        , placeholder
        , selected
        , name
        , href
        , target
        , src
        , height
        , width
        , alt
        , tabindex
        )
import Html.Events
    exposing
        ( on
        , targetValue
        , targetChecked
        , keyCode
        , onBlur
        , onFocus
        , onSubmit
        , onClick
        , onDoubleClick
        , onMouseDown
        , onMouseUp
        , onMouseEnter
        , onMouseLeave
        , onMouseOver
        , onMouseOut
        , onInput
        )
import Util exposing (commonStartsWith, removeBasePath)
import File exposing (File)
import String.Extra


-- MODEL


type alias Model =
    { tags : List Tag
    , currentFile : Maybe File
    , searchKeyword : String
    , tagTypeFilter : Maybe TagType
    }


type alias TagsGroupedByFile =
    List ( File, List Tag )


type alias RawTag =
    { context : String
    , lineNumber : Int
    , symbol : String
    , type_ : String
    , filePath : String
    }


type alias Flags =
    List RawTag


type TagType
    = Constant
    | Function
    | Type
    | TypeAlias
    | Port
    | TagTypeUnknown


type alias Tag =
    { symbol : String
    , file : File
    , context : String
    , type_ : TagType
    , lineNumber : Int
    }


init : Model
init =
    { tags = []
    , currentFile = Nothing
    , searchKeyword = ""
    , tagTypeFilter = Nothing
    }


parseTagType : String -> TagType
parseTagType typeString =
    case typeString of
        "Function" ->
            Function

        "Constant" ->
            Constant

        "Type" ->
            Type

        "TypeAlias" ->
            TypeAlias

        "Port" ->
            Port

        _ ->
            TagTypeUnknown


convertRawTag : RawTag -> Tag
convertRawTag rawTag =
    { symbol = rawTag.symbol
    , lineNumber = rawTag.lineNumber
    , file = File.parseFilePath rawTag.filePath
    , context = rawTag.context
    , type_ = parseTagType rawTag.type_
    }


excludeFileTags : List Tag -> File -> List Tag
excludeFileTags tags file =
    List.filter (.file >> (/=) file) tags


keepOnlyFileTags : List Tag -> File -> List Tag
keepOnlyFileTags tags file =
    List.filter (.file >> (==) file) tags


search : String -> List Tag -> List Tag
search keyword allTags =
    List.filter
        (.symbol >> String.toLower >> String.contains (String.toLower keyword))
        allTags


replaceTagsForFilePath : { filePath : String, rawTags : List RawTag } -> List Tag -> List Tag
replaceTagsForFilePath { filePath, rawTags } currentTags =
    let
        newTags =
            List.map convertRawTag rawTags
    in
        currentTags
            |> List.foldl
                (\tag ({ left, new, right } as acc) ->
                    if tag.file.filePath == filePath then
                        { left = left, new = newTags, right = right }
                    else if new == [] then
                        { acc | left = left ++ [ tag ] }
                    else
                        { acc | right = right ++ [ tag ] }
                )
                { left = [], new = [], right = [] }
            |> (\{ left, new, right } ->
                    left ++ new ++ right
               )


groupByFile : List Tag -> TagsGroupedByFile
groupByFile tags =
    tags
        |> List.foldl
            (\tag ({ files, currTags, maybePrevFile } as acc) ->
                case maybePrevFile of
                    Nothing ->
                        { files = []
                        , currTags = [ tag ]
                        , maybePrevFile = Just tag.file
                        }

                    Just prevFile ->
                        if tag.file == prevFile then
                            { acc | currTags = currTags ++ [ tag ] }
                        else
                            { files = files ++ [ ( prevFile, currTags ) ]
                            , currTags = [ tag ]
                            , maybePrevFile = Just tag.file
                            }
            )
            { files = [], currTags = [], maybePrevFile = Nothing }
        |> (\{ files, currTags, maybePrevFile } ->
                case maybePrevFile of
                    Nothing ->
                        []

                    Just prevFile ->
                        files ++ [ ( prevFile, currTags ) ]
           )


type Msg
    = NavigateToTag Tag
    | SearchInputUpdated String
    | FilterByTagType (Maybe TagType)
    | FilesUpdated (List RawTag)
    | FileUpdated { filePath : String, rawTags : List RawTag }
    | ActiveFileChanged { filePath : String }


update : Msg -> Model -> ( Model, Cmd Msg )
update action model =
    -- case Debug.log "action" action of
    case action of
        NavigateToTag tag ->
            model
                ! [ goToLineInFile
                        { lineNumber = tag.lineNumber
                        , uri = tag.file.filePath
                        }
                  ]

        SearchInputUpdated s ->
            { model | searchKeyword = s } ! []

        FilterByTagType maybeTagType ->
            { model | tagTypeFilter = maybeTagType } ! []

        FilesUpdated rawTags ->
            let
                tags =
                    List.map convertRawTag rawTags
            in
                { model | tags = tags } ! []

        FileUpdated { filePath, rawTags } ->
            let
                newTags =
                    replaceTagsForFilePath { filePath = filePath, rawTags = rawTags } model.tags
            in
                { model | tags = newTags } ! []

        ActiveFileChanged { filePath } ->
            let
                domId =
                    toHtmlAnchorId filePath
            in
                model ! [ focusDomElement { id = domId } ]


view : Model -> Html Msg
view model =
    let
        filteredTags =
            if model.searchKeyword == "" then
                model.tags
            else
                search model.searchKeyword model.tags

        projectTags =
            model.currentFile
                |> Maybe.map (excludeFileTags filteredTags)
                |> Maybe.withDefault filteredTags
                |> groupByFile

        currentFileTags =
            model.currentFile
                |> Maybe.map (keepOnlyFileTags filteredTags)
                |> Maybe.withDefault []

        basePath : String
        basePath =
            model.tags |> List.map (.file >> .filePath) |> commonStartsWith
    in
        div [ class "esn-main-view" ]
            -- [ h2 [] [ text (model.currentFile |> Maybe.map .name |> Maybe.withDefault "") ]
            -- [ h1 [] [ text "wtf?" ]
            [ input
                [ type_ "search"
                , class "native-key-bindings input-search"
                , onInput SearchInputUpdated
                , placeholder "search..."
                ]
                []

            -- , tagTypeFilterView model -- currently disabled till I do more work on it
            -- , h2 [] [ text "Current File" ]
            -- , tagsView basePath currentFileTags -- disabled (not sure it was such a great idea)
            -- , h2 [] [ text "Project" ]
            , projectTagsView basePath projectTags
            ]


tagsView : String -> List Tag -> Html Msg
tagsView basePath tags =
    ul [ class "list-group" ]
        (List.map (tagView basePath) tags)


projectTagsView : String -> TagsGroupedByFile -> Html Msg
projectTagsView basePath tags =
    div [ class "esn-project-tags" ] (List.map (fileTagsView basePath) tags)


toHtmlAnchorId : String -> String
toHtmlAnchorId filePath =
    "esn--" ++ (filePath |> String.Extra.replace " " "_")


fileTagsView : String -> ( File, List Tag ) -> Html Msg
fileTagsView basePath ( file, tags ) =
    div [ class "esn-file-tags" ]
        [ a [ id <| toHtmlAnchorId file.filePath ] []
        , h3 [] [ file.filePath |> removeBasePath basePath |> text ]
        , tagsView basePath tags
        ]


isTeaSymbol : String -> Bool
isTeaSymbol symbol =
    List.member symbol [ "init", "Model", "Msg", "model", "view", "update", "main" ]


tagView : String -> Tag -> Html Msg
tagView basePath tag =
    li
        [ classList [ ( "list-item", True ), ( "tea-symbol", isTeaSymbol tag.symbol ) ]
        , onClick <| NavigateToTag tag
        ]
        [ div [ class "list-item-wrapper" ]
            [ tagTypeView tag.type_
            , span [ class "symbol-name" ] [ text tag.symbol ]
            ]
        ]


tagTypeView : TagType -> Html msg
tagTypeView tagType =
    let
        tagTypeString =
            toString tagType
    in
        span
            [ class ("elm-navigator-type elm-navigator-type-" ++ tagTypeString) ]
            []


tagTypeFilterView : Model -> Html Msg
tagTypeFilterView model =
    div [ class "esn-tag-type-filter" ]
        [ tagTypeFilterItemView model Type
        , tagTypeFilterItemView model TypeAlias
        , tagTypeFilterItemView model Constant
        , tagTypeFilterItemView model Function
        , tagTypeFilterItemView model Port
        ]


tagTypeFilterItemView : Model -> TagType -> Html Msg
tagTypeFilterItemView model tagType =
    let
        highlighted =
            case model.tagTypeFilter of
                Just currTagType ->
                    tagType == currTagType

                Nothing ->
                    False
    in
        div
            [ classList
                [ ( "esn-tag-type-filter-item", True )
                , ( "esn-tag-type-filter-" ++ (toString tagType), True )
                , ( "elm-navigator-type-" ++ (toString tagType), True )
                , ( "esn-tag-type-filter-highlighted", highlighted )
                ]
            , onClick <| FilterByTagType (Just tagType)
            ]
            []



-- PORTS


port filesUpdated : (List RawTag -> msg) -> Sub msg


port fileUpdated : ({ filePath : String, rawTags : List RawTag } -> msg) -> Sub msg


port activeFileChanged : ({ filePath : String } -> msg) -> Sub msg


port goToLineInFile : { uri : String, lineNumber : Int } -> Cmd msg


port focusDomElement : { id : String } -> Cmd msg



-- SUBSCRIPTIONS


subscriptions : Sub Msg
subscriptions =
    Sub.batch
        [ filesUpdated FilesUpdated
        , fileUpdated FileUpdated
        , activeFileChanged ActiveFileChanged
        ]
