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
        Object objInput = JSON.deserializeUntyped(jsonString);
    	return convert(objInput);
	}
        
    public Object deserialize(String jsonString, System.Type apexType) {
        Object objInput = JSON.deserializeUntyped(jsonString);
    	return convert(objInput, apexType);
	}

    public Object convert(Object objInput, System.Type apexType) {
        Object objConverted = convert(objInput);
        String jsonString = JSON.serialize(objConverted);
        // System.debug(jsonString);
        return JSON.deserialize(jsonString, apexType);
    }
    
    public Object convert(Object objInput) {
        Map<String, Object> output = new Map<String, Object>();
        fetchDeep(output,'', objInput);
        
        for (String path: output.keySet()) {
            String transformedPath = transformPath(path);
            
            if (transformedPath != path) {
                output.put(transformedPath, output.remove(path));
            }
        }
        return getData(output);
    }

    private String transformPath(String pathInput) {
        String pathOutput = pathInput;
        for (Integer i = 0; i < targets.size(); i++) {
            pathOutput = targets[i].matcher(pathOutput).replaceAll(replacements[i]);
        }
        return pathOutput;
    }

	private void fetchDeep(Map<String, Object> output, String path, Object objInput) {
        if (objInput instanceof Map<String, Object>) {
            fetchDeep(output, path, (Map<String, Object>)objInput);
        } else if (objInput instanceof List<Object>) {
            fetchDeep(output, path, (List<Object>)objInput);
        } else {
            output.put(path, objInput);
        }
    }

	private void fetchDeep(Map<String, Object> output, String path, Map<String, Object> mapInput) {
        for (String key: mapInput.keySet()) {
            fetchDeep(output, path + '.' + key, mapInput.get(key));
        }
    }
    
    private void fetchDeep(Map<String, Object> output, String path, List<Object> listInput) {
        for (Integer i = 0; i < listInput.size(); i++) {
            fetchDeep(output, path + '[' + i + ']', listInput[i]);
        }
    }
    
    private Object getData(Map<String, Object> output) {
        Map<String, Object> mapObject = spreadObject(output);
        // System.debug(mapObject);
        return reformatObject(mapObject);
    }
    
    private Map<String, Object> spreadObject(Map<String, Object> output) {
        Map<String, Object> mapObject = new Map<String, Object>();
		
        for (String path: output.keySet()) {
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

            mapCurrent.put(keyCurrent, output.get(path));
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