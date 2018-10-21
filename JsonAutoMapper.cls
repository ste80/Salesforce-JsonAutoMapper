public class JsonAutoMapper {
    public static final String RESERVED_KEYWORDS = 'abstract|activate|and|any|array|as|asc|autonomous|begin|bigdecimal|blob|break|bulk|by|byte|case|cast|catch|char|class|collect|commit|const|continue|convertcurrency|decimal|default|delete|desc|do|else|end|enum|exception|exit|export|extends|false|final|finally|float|for|from|future|global|goto|group|having|hint|if|implements|import|in|inner|insert|instanceof|interface|into|int|join|last_90_days|last_month|last_n_days|last_week|like|limit|list|long|loop|map|merge|new|next_90_days|next_month|next_n_days|next_week|not|null|nulls|number|object|of|on|or|outer|override|package|parallel|pragma|private|protected|public|retrieve|return|returning|rollback|savepoint|search|select|set|short|sort|stat|static|super|switch|synchronized|system|testmethod|then|this|this_month|this_week|throw|today|tolabel|tomorrow|transaction|trigger|true|try|type|undelete|update|upsert|using|virtual|webservice|when|where|while|yesterday';
    public static final String IGNORE_CASE = '(?i)';
    public static final String VARIABLE_PATH = '([\\s\\S]*\\.|[\\s\\S]\\[\\d+]])';
    public static final String INVALID_VARIABLE_CHARS = '[^a-z0-9_]';
    public static final String INVALID_UNDERSCORES = '(?:^_+|_+$|(?<=_)_+)';
    public static final Integer MAX_VARIABLE_LENGTH = 255;
    
    private static Pattern defaultPattern = Pattern.compile(IGNORE_CASE + '^' + VARIABLE_PATH + '(' + RESERVED_KEYWORDS + ')$');
    private static Pattern patternToken = Pattern.compile('\\[(\\d+)]|\\.([^\\.\\[]+)');

    private List<Pattern> targets = new List<Pattern>();
    private List<String> replacements = new List<String>();

    public JsonAutoMapper() {
        targets.add(defaultPattern);
        replacements.add('$1$2_x');
    }

    public JsonAutoMapper(Boolean createDefault) {
        if (createDefault) {
            targets.add(defaultPattern);
            replacements.add('$1$2_x');
        }
    }

    public JsonAutoMapper reset() {
        targets.clear();
        replacements.clear();
        return this;
    }

    public JsonAutoMapper addField(String target, String replacement) {
        return addField(target, replacement, true);
    }

    public JsonAutoMapper addField(String target, String replacement, Boolean ignoreCase) {
        targets.add(Pattern.compile((ignoreCase ? IGNORE_CASE : '') + '^([\\s\\S]*\\.)(' + target + ')$'));
        replacements.add('$1' + replacement);
        return this;
    }

    public JsonAutoMapper addPath(String target, String replacement) {
        return addPath(target, replacement, true);
    }

    public JsonAutoMapper addPath(String target, String replacement, Boolean ignoreCase) {
        targets.add(Pattern.compile((ignoreCase ? IGNORE_CASE : '') + '^' + target + '$'));
        replacements.add(replacement);
        return this;
    }
        
    public Object deserialize(String jsonString) {
        JSONParser parser = JSON.createParser(jsonString);
    	return convertJson(parser);
	}
        
    public Object deserialize(String jsonString, System.Type apexType) {
        JSONParser parser = JSON.createParser(jsonString);
    	return convertJson(parser, apexType);
	}
    
    public Object convertJson(JSONParser parser) {
        Map<String, Object> objOutput = new Map<String, Object>();
        fetchJson(objOutput,'', parser);
        // System.debug('convertedJson');
        // System.debug(JSON.serialize(objOutput));
        return getData(objOutput);
    }

    public Object convertJson(JSONParser parser, System.Type apexType) {
        Object objConverted = convertJson(parser);
        String jsonString = JSON.serialize(objConverted);
        return JSON.deserialize(jsonString, apexType);
    }
    
    public Object convert(Object objInput) {
        Map<String, Object> objOutput = new Map<String, Object>();
        fetchDeep(objOutput,'', objInput);
        return getData(objOutput);
    }

    public Object convert(Object objInput, System.Type apexType) {
        Object objConverted = convert(objInput);
        String jsonString = JSON.serialize(objConverted);
        return JSON.deserialize(jsonString, apexType);
    }

    private String transformPath(String pathInput) {
        String pathOutput = pathInput;
        for (Integer i = 0; i < targets.size(); i++) {
            pathOutput = targets[i].matcher(pathOutput).replaceAll(replacements[i]);
        }
        return pathOutput;
    }

	private void fetchJson(Map<String, Object> objOutput, String path, JSONParser parser) {
        JSONToken prevToken = null;
        JSONToken token = parser.nextToken();
        while (token != null) {
            switch on token {
                when START_ARRAY {
                	fetchJArray(objOutput, path, 0, parser);
                }
                when START_OBJECT {
                    fetchJObject(objOutput, path, parser);
                }
                when VALUE_STRING, VALUE_EMBEDDED_OBJECT {
                    objOutput.put(transformPath(path), parser.getText());
                }
                when VALUE_FALSE, VALUE_TRUE {
                    objOutput.put(transformPath(path), parser.getBooleanValue());
                }
                when VALUE_NUMBER_FLOAT {
                    objOutput.put(transformPath(path), parser.getDoubleValue());
                }
                when VALUE_NUMBER_INT {
                    objOutput.put(transformPath(path), parser.getIntegerValue());
                }
                when VALUE_NULL {
                    objOutput.put(transformPath(path), null);
                }
            }
            prevToken = token;
            token = parser.nextToken();
        }
    }

	private void fetchJObject(Map<String, Object> objOutput, String path, JSONParser parser) {
        JSONToken prevToken = null;
        JSONToken token = parser.nextToken();
        String fieldName = '';
        while (token != null) {
            switch on token {
                when START_OBJECT {
                    fetchJObject(objOutput, path + '.' + fieldName, parser);
                }
                when START_ARRAY {
                	fetchJArray(objOutput, path + '.' + fieldName, 0, parser);
                }
                when FIELD_NAME {
                    fieldName = parser.getText();
                }
                when VALUE_STRING, VALUE_EMBEDDED_OBJECT {
                    objOutput.put(transformPath(path + '.' + fieldName), parser.getText());
                }
                when VALUE_FALSE, VALUE_TRUE {
                    objOutput.put(transformPath(path + '.' + fieldName), parser.getBooleanValue());
                }
                when VALUE_NUMBER_FLOAT {
                    objOutput.put(transformPath(path + '.' + fieldName), parser.getDoubleValue());
                }
                when VALUE_NUMBER_INT {
                    objOutput.put(transformPath(path + '.' + fieldName), parser.getIntegerValue());
                }
                when VALUE_NULL {
                    objOutput.put(transformPath(path + '.' + fieldName), null);
                }
                when END_OBJECT {
                    return;
                }
            }
            prevToken = token;
            token = parser.nextToken();
        }
    }
    
    private void fetchJArray(Map<String, Object> objOutput, String path, Integer arrayIndex, JSONParser parser) {
        JSONToken prevToken = null;
        JSONToken token = parser.nextToken();
        while (token != null) {
            switch on token {
                when START_OBJECT {
                    fetchJObject(objOutput, path + '[' + arrayIndex++ + ']', parser);
                }
                when START_ARRAY {
                	fetchJArray(objOutput, path + '[' + arrayIndex++ + ']', 0, parser);
                }
                when VALUE_STRING, VALUE_EMBEDDED_OBJECT {
                    objOutput.put(transformPath(path + '[' + (arrayIndex++) + ']'), parser.getText());
                }
                when VALUE_FALSE, VALUE_TRUE {
                    objOutput.put(transformPath(path + '[' + (arrayIndex++) + ']'), parser.getBooleanValue());
                }
                when VALUE_NUMBER_FLOAT {
                    objOutput.put(transformPath(path + '[' + (arrayIndex++) + ']'), parser.getDoubleValue());
                }
                when VALUE_NUMBER_INT {
                    objOutput.put(transformPath(path + '[' + (arrayIndex++) + ']'), parser.getIntegerValue());
                }
                when VALUE_NULL {
                    objOutput.put(transformPath(path + '[' + (arrayIndex++) + ']'), null);
                }
                when END_ARRAY {
                    return;
                }
            }
            prevToken = token;
            token = parser.nextToken();
        }
    }

	private void fetchDeep(Map<String, Object> objOutput, String path, Object objInput) {
        if (objInput instanceof Map<String, Object>) {
            fetchDeep(objOutput, path, (Map<String, Object>)objInput);
        } else if (objInput instanceof List<Object>) {
            fetchDeep(objOutput, path, (List<Object>)objInput);
        } else {
            objOutput.put(transformPath(path), objInput);
        }
    }

	private void fetchDeep(Map<String, Object> objOutput, String path, Map<String, Object> mapInput) {
        for (String key: mapInput.keySet()) {
            fetchDeep(objOutput, path + '.' + key, mapInput.get(key));
        }
    }
    
    private void fetchDeep(Map<String, Object> objOutput, String path, List<Object> listInput) {
        for (Integer i = 0; i < listInput.size(); i++) {
            fetchDeep(objOutput, path + '[' + i + ']', listInput[i]);
        }
    }
    
    private Object getData(Map<String, Object> objOutput) {
        Map<String, Object> mapObject = spreadObject(objOutput);
        // System.debug(mapObject);
        return reformatObject(mapObject);
    }
    
    private Map<String, Object> spreadObject(Map<String, Object> objOutput) {
        Map<String, Object> mapObject = new Map<String, Object>();
		
        for (String path: objOutput.keySet()) {
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

            mapCurrent.put(keyCurrent, objOutput.get(path));
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
                Object keyValue = reformatObject(mapInput.get(key));
                
                if (String.isEmpty(key)) {
                    value = keyValue;
                } else if (key.isNumeric()) {
                    mapArray.put(Integer.valueOf(key), keyValue);
                } else {
                    mapObject.put(key, keyValue);
                }
            }
            
            if (mapObject.size() > 0) {
                return mapObject;
            } else if (mapArray.size() > 0) {
                List<Object> listOutput = new List<Object>();
                List<Integer> listKey = new List<Integer>(mapArray.keySet());
                listKey.sort();
                for (Integer key: listKey) {
                    listOutput.add(mapArray.get(key));
                }
                return listOutput;
            } else {
                return value;
            }
        } else {
        	return objInput;
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