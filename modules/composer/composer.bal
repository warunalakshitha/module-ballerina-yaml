import yaml.parser;
import yaml.event;
import yaml.lexer;

# Compose single YAML document to native Ballerina structure.
#
# + state - Initiated composer state  
# + eventParam - Passed the expected event if already fetched
# + return - Native Ballerina data structure on success
public function composeDocument(ComposerState state, event:Event? eventParam = ()) returns json|parser:ParsingError|lexer:LexicalError|ComposingError {
    // Obtain the root event
    event:Event event = eventParam is () ? check checkEvent(state) : eventParam;

    // Return an empty document if end is reached
    if isEndOfDocument(event) {
        return ();
    }

    // TODO: Set up the hash map for tag handling
    if event is event:DocumentStartEvent {
        event = check checkEvent(state);
    }

    // Construct the single document
    json output = check composeNode(state, event);

    // Return an error if there is another root event
    event = check checkEvent(state);
    return isEndOfDocument(event) ? output
            : generateError(state, "There can only be one root event to a document");
}

# Compose a stream YAML documents to an array of native Ballerina structure.
#
# + state - Initiated composer state  
# + return - Native Ballerina data structure on success
public function composeStream(ComposerState state) returns json[]|parser:ParsingError|lexer:LexicalError|ComposingError {
    json[] output = [];
    event:Event event = check checkEvent(state);

    // Iterate all the documents
    while !(event is event:EndEvent && event.endType == event:STREAM) {
        output.push(check composeDocument(state, event));
        state.docTerminated = false;
        event = check checkEvent(state);
    }

    return output;
}
