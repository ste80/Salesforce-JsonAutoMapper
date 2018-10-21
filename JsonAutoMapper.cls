public class JsonAutoMapper {
    public static final String RESERVED_KEYWORDS = 'abstract|activate|and|any|array|as|asc|autonomous|begin|bigdecimal|blob|break|bulk|by|byte|case|cast|catch|char|class|collect|commit|const|continue|convertcurrency|decimal|default|delete|desc|do|else|end|enum|exception|exit|export|extends|false|final|finally|float|for|from|future|global|goto|group|having|hint|if|implements|import|in|inner|insert|instanceof|interface|into|int|join|last_90_days|last_month|last_n_days|last_week|like|limit|list|long|loop|map|merge|new|next_90_days|next_month|next_n_days|next_week|not|null|nulls|number|object|of|on|or|outer|override|package|parallel|pragma|private|protected|public|retrieve|return|returning|rollback|savepoint|search|select|set|short|sort|stat|static|super|switch|synchronized|system|testmethod|then|this|this_month|this_week|throw|today|tolabel|tomorrow|transaction|trigger|true|try|type|undelete|update|upsert|using|virtual|webservice|when|where|while|yesterday';
    public static final String IGNORE_CASE = '(?i)';
 
    // Regex too complicated
    // public static final String OBJECT_QUOTE_START = '(?<!\\\\)(\\")';
    // public static final String OBJECT_QUOTE_END = '(?<!\\\\)\\"\\s*:';

    public static final String VARIABLE_PATH = '[\\s\\S]*\\.';
    public static final String INVALID_VARIABLE_CHARS = '[^a-z0-9_]';
    public static final String INVALID_UNDERSCORES = '(?:^_+|_+$|(?<=_)_+)';
    public static final Integer MAX_VARIABLE_LENGTH = 255;
    
    private static Pattern patternToken = Pattern.compile('\\[(\\d+)]|\\.([^\\.\\[]+)');

    // Regex too complicated
    // private List<Pattern> quotedFields = new List<Pattern>();
    // private List<String> replacementQuotedFields = new List<String>();

    private List<Pattern> targetFields = new List<Pattern>();
    private List<String> replacementFields = new List<String>();

    private List<Pattern> targetPaths = new List<Pattern>();
    private List<String> replacementPaths = new List<String>();

    public JsonAutoMapper() {
        addField(RESERVED_KEYWORDS, '$2_x');
    }

    public JsonAutoMapper(Boolean createDefault) {
        if (createDefault) {
        	addField(RESERVED_KEYWORDS, '$2_x');
        }
    }

    public JsonAutoMapper reset() {
    	// Regex too complicated
        // quotedFields.clear();
        // replacementQuotedFields.clear();
        targetFields.clear();
        replacementFields.clear();
        targetPaths.clear();
        replacementPaths.clear();
        return this;
    }

    public JsonAutoMapper addField(String target, String replacement) {
        return addField(target, replacement, true);
    }

    public JsonAutoMapper addField(String target, String replacement, Boolean ignoreCase) {
    	// Regex too complicated
        // quotedFields.add(Pattern.compile(
        //     (ignoreCase ? IGNORE_CASE : '') + OBJECT_QUOTE_START + '(' + target + ')' + OBJECT_QUOTE_END));
        // replacementQuotedFields.add('$1' + replacement + '":');
        targetFields.add(Pattern.compile(
            (ignoreCase ? IGNORE_CASE : '') + '^(' + VARIABLE_PATH + ')(' + target + ')$'));
        replacementFields.add('$1' + replacement);
        return this;
    }

    public JsonAutoMapper addPath(String target, String replacement) {
        return addPath(target, replacement, true);
    }

    public JsonAutoMapper addPath(String target, String replacement, Boolean ignoreCase) {
        targetPaths.add(Pattern.compile((ignoreCase ? IGNORE_CASE : '') + '^' + target + '$'));
        replacementPaths.add(replacement);
        return this;
    }
        
    public Object deserialize(String jsonString) {
        Map<String, Object> indexer = parseJsonToIndexer(jsonString);
        return getData(indexer);
	}
        
    public Object deserialize(String jsonString, System.Type apexType) {
    	// Regex too complicated
        // if (targetPaths.size() > 0) {
        Map<String, Object> indexer = parseJsonToIndexer(jsonString);
        String convertedJsonString = serializeIndexer(indexer);
        return JSON.deserialize(convertedJsonString, apexType);
        // } else {
        //     String convertedJsonString = transformJsonString(jsonString);
        //     return JSON.deserialize(convertedJsonString, apexType);
        // }
	}

    public String serialize(Object objInput) {
        String jsonString = JSON.serialize(objInput);
        
    	// Regex too complicated
        // if (targetPaths.size() > 0) {
        Map<String, Object> indexer = parseJsonToIndexer(jsonString);
        return serializeIndexer(indexer);
        // } else {
        //     return transformJsonString(jsonString);
        // }
    }
    
    public Map<String, Object> parseJsonToIndexer(String jsonString) {
        // deserializeUntyped: 
        // Object untyped = JSON.deserializeUntyped(jsonString);
        // Map<String, Object> indexer = convertToIndexer(untyped);

        // JSONParser: 
        Map<String, Object> indexer = new Map<String, Object>();
        JSONParser parser = JSON.createParser(jsonString);
        parseJson(indexer,'', parser);
        
        // System.debug('convertedJson');
        // System.debug(JSON.serialize(indexer));
        return indexer;
    }
    
    private String serializeIndexer(Map<String, Object> indexer) {
        // JSONGenerator: higher CPU
        // return JSON.serialize(getData(indexer));
        
        // JSONGenerator: lower CPU
        return getJson(indexer);
    }
    
    // private Map<String, Object> convertToIndexer(Object objInput) {
    //     Map<String, Object> indexer = new Map<String, Object>();
    //     indexObjectDeep(indexer,'', objInput);
    //     return indexer;
    // }

    // Regex too complicated
    // private String transformJsonString(String jsonString) {
    //     // System.debug(jsonString);
    //     String jsonStringOutput = jsonString;
    //     for (Integer i = 0; i < quotedFields.size(); i++) {
    //         jsonStringOutput = quotedFields[i].matcher(jsonStringOutput).replaceAll(replacementQuotedFields[i]);
    //     }
    //     // System.debug(jsonStringOutput);
    //     return jsonStringOutput;
    // }

    private String transformPath(String pathInput) {
        String pathOutput = pathInput;
        // System.debug('transformPath ' + pathOutput);
        for (Integer i = 0; i < targetFields.size(); i++) {
            pathOutput = targetFields[i].matcher(pathOutput).replaceAll(replacementFields[i]);
        }
        // System.debug('transformPath ' + pathOutput);
        for (Integer i = 0; i < targetPaths.size(); i++) {
            pathOutput = targetPaths[i].matcher(pathOutput).replaceAll(replacementPaths[i]);
        }
        return pathOutput;
    }

	private void parseJson(Map<String, Object> indexer, String path, JSONParser parser) {
        JSONToken prevToken = null;
        JSONToken token = parser.nextToken();
        while (token != null) {
            switch on token {
                when START_OBJECT {
                    parseJObject(indexer, path, parser);
                }
                when START_ARRAY {
                	parseJArray(indexer, path, 0, parser);
                }
                when VALUE_STRING, VALUE_EMBEDDED_OBJECT {
                    indexer.put(transformPath(path), parser.getText());
                }
                when VALUE_FALSE, VALUE_TRUE {
                    indexer.put(transformPath(path), parser.getBooleanValue());
                }
                when VALUE_NUMBER_FLOAT {
                    indexer.put(transformPath(path), parser.getDoubleValue());
                }
                when VALUE_NUMBER_INT {
                    indexer.put(transformPath(path), parser.getIntegerValue());
                }
                when VALUE_NULL {
                    indexer.put(transformPath(path), null);
                }
            }
            prevToken = token;
            token = parser.nextToken();
        }
    }

	private void parseJObject(Map<String, Object> indexer, String path, JSONParser parser) {
        JSONToken prevToken = null;
        JSONToken token = parser.nextToken();
        String fieldName = '';
        while (token != null) {
            switch on token {
                when START_OBJECT {
                    parseJObject(indexer, path + '.' + fieldName, parser);
                }
                when START_ARRAY {
                	parseJArray(indexer, path + '.' + fieldName, 0, parser);
                }
                when FIELD_NAME {
                    fieldName = parser.getText();
                }
                when VALUE_STRING, VALUE_EMBEDDED_OBJECT {
                    indexer.put(transformPath(path + '.' + fieldName), parser.getText());
                }
                when VALUE_FALSE, VALUE_TRUE {
                    indexer.put(transformPath(path + '.' + fieldName), parser.getBooleanValue());
                }
                when VALUE_NUMBER_FLOAT {
                    indexer.put(transformPath(path + '.' + fieldName), parser.getDoubleValue());
                }
                when VALUE_NUMBER_INT {
                    indexer.put(transformPath(path + '.' + fieldName), parser.getIntegerValue());
                }
                when VALUE_NULL {
                    indexer.put(transformPath(path + '.' + fieldName), null);
                }
                when END_OBJECT {
                    return;
                }
            }
            prevToken = token;
            token = parser.nextToken();
        }
    }
    
    private void parseJArray(Map<String, Object> indexer, String path, Integer arrayIndex, JSONParser parser) {
        JSONToken prevToken = null;
        JSONToken token = parser.nextToken();
        while (token != null) {
            switch on token {
                when START_OBJECT {
                    parseJObject(indexer, path + '[' + arrayIndex++ + ']', parser);
                }
                when START_ARRAY {
                	parseJArray(indexer, path + '[' + arrayIndex++ + ']', 0, parser);
                }
                when VALUE_STRING, VALUE_EMBEDDED_OBJECT {
                    indexer.put(transformPath(path + '[' + (arrayIndex++) + ']'), parser.getText());
                }
                when VALUE_FALSE, VALUE_TRUE {
                    indexer.put(transformPath(path + '[' + (arrayIndex++) + ']'), parser.getBooleanValue());
                }
                when VALUE_NUMBER_FLOAT {
                    indexer.put(transformPath(path + '[' + (arrayIndex++) + ']'), parser.getDoubleValue());
                }
                when VALUE_NUMBER_INT {
                    indexer.put(transformPath(path + '[' + (arrayIndex++) + ']'), parser.getIntegerValue());
                }
                when VALUE_NULL {
                    indexer.put(transformPath(path + '[' + (arrayIndex++) + ']'), null);
                }
                when END_ARRAY {
                    return;
                }
            }
            prevToken = token;
            token = parser.nextToken();
        }
    }

	// private void indexObjectDeep(Map<String, Object> indexer, String path, Object objInput) {
    //     if (objInput instanceof Map<String, Object>) {
    //         indexMapDeep(indexer, path, (Map<String, Object>)objInput);
    //     } else if (objInput instanceof List<Object>) {
    //         indexListDeep(indexer, path, (List<Object>)objInput);
    //     } else {
    //         // System.debug('indexObjectDeep');
    //         // System.debug(objInput);
    //         indexer.put(transformPath(path), objInput);
    //     }
    // }

	// private void indexMapDeep(Map<String, Object> indexer, String path, Map<String, Object> mapInput) {
    //     for (String key: mapInput.keySet()) {
    //         indexObjectDeep(indexer, path + '.' + key, mapInput.get(key));
    //     }
    // }
    
    // private void indexListDeep(Map<String, Object> indexer, String path, List<Object> listInput) {
    //     for (Integer i = 0; i < listInput.size(); i++) {
    //         indexObjectDeep(indexer, path + '[' + i + ']', listInput[i]);
    //     }
    // }
    
    private Object getData(Map<String, Object> indexer) {
        Map<String, Object> mapObject = spreadObject(indexer);
        // System.debug(mapObject);
        return reformatObject(mapObject);
    }
    
    private String getJson(Map<String, Object> indexer) {
        Map<String, Object> mapObject = spreadObject(indexer);
        // System.debug(mapObject);
        JSONGenerator gen = JSON.createGenerator(false);
        reformatObjectToJson(gen, mapObject);
        return gen.getAsString();
    }
    
    private Map<String, Object> spreadObject(Map<String, Object> indexer) {
        Map<String, Object> mapObject = new Map<String, Object>();
		
        for (String path: indexer.keySet()) {
            Map<String, Object> mapCurrent = mapObject;
            String keyCurrent = '';
            
            Matcher matcherToken = patternToken.matcher(path);
            
            while (matcherToken.find()) {
                if (!String.isEmpty(keyCurrent)) {
                    Map<String, Object> mapNew = null;
                    if (mapCurrent.get(keyCurrent) instanceof Map<String, Object>) {
                        mapNew = (Map<String, Object>)mapCurrent.get(keyCurrent);
                    }
                    if (mapNew == null) {
                        mapNew = new Map<String, Object>();
                    }
                    mapCurrent.put(keyCurrent, mapNew);
                    mapCurrent = mapNew;
                }
                
                keyCurrent = validateVarName(matcherToken.group(2));
                
                if (keyCurrent == null) {
                    keyCurrent = String.valueof(matcherToken.group(1));
                }
            }

            mapCurrent.put(keyCurrent, indexer.get(path));
        }
        return mapObject;
    }
    
    private Object reformatObject(Object objInput) {
        if (objInput instanceof Map<String, Object>) {
            Map<String, Object> mapInput = (Map<String, Object>)objInput;
            Object value = null;
            Map<String, Object> mapObject = new Map<String, Object>();
            Map<Integer, Object> mapArray = new Map<Integer, Object>();
            
            for (String key: mapInput.keySet()) {
                Object keyValue = mapInput.get(key);
                
                if (String.isEmpty(key)) {
                    value = keyValue;
                } else if (key.isNumeric()) {
                    mapArray.put(Integer.valueOf(key), keyValue);
                } else {
                    mapObject.put(key, keyValue);
                }
            }
            
            if (mapObject.size() > 0) {
                for (String key: mapObject.keySet()) {
                    mapObject.put(key, reformatObject(mapObject.get(key)));
                }
                return mapObject;
            } else if (mapArray.size() > 0) {
                List<Object> listOutput = new List<Object>();
                List<Integer> listKey = new List<Integer>(mapArray.keySet());
                listKey.sort();
                for (Integer key: listKey) {
                    listOutput.add(reformatObject(mapArray.get(key)));
                }
                return listOutput;
            } else {
                return reformatObject(value);
            }
        } else {
        	return objInput;
        }
    }
    
    private void reformatObjectToJson(JSONGenerator gen, Object objInput) {
        if (objInput instanceof Map<String, Object>) {
            Map<String, Object> mapInput = (Map<String, Object>)objInput;
            Object value = null;
            Map<String, Object> mapObject = new Map<String, Object>();
            Map<Integer, Object> mapArray = new Map<Integer, Object>();
            
            for (String key: mapInput.keySet()) {
                Object keyValue = mapInput.get(key);
                
                if (String.isEmpty(key)) {
                    value = keyValue;
                } else if (key.isNumeric()) {
                    mapArray.put(Integer.valueOf(key), keyValue);
                } else {
                    mapObject.put(key, keyValue);
                }
            }
            
            if (mapObject.size() > 0) {
                gen.writeStartObject();
                for (String key: mapObject.keyset()) {
                    gen.writeFieldName(key);
                    reformatObjectToJson(gen, mapObject.get(key));
                }
                gen.writeEndObject();
            } else if (mapArray.size() > 0) {
                List<Integer> listKey = new List<Integer>(mapArray.keySet());
                listKey.sort();
                gen.writeStartArray();
                for (Integer key: listKey) {
                    reformatObjectToJson(gen, mapArray.get(key));
                }
                gen.writeEndArray();
            } else {
				reformatObjectToJson(gen, value);
            }
        } else if (objInput != null) {
            gen.writeObject(objInput);
        } else {
            gen.writeNull();
        }
    }
    
    private String validateVarName(String variableName) {
        return variableName == null ? null :
            variableName
                .replaceAll(IGNORE_CASE + INVALID_VARIABLE_CHARS, '')
                .replaceAll(INVALID_UNDERSCORES, '')
                .left(MAX_VARIABLE_LENGTH);
    }

}