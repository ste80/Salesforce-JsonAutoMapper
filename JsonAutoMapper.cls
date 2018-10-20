public class JsonAutoMapper {
    public final String RESERVED_KEYWORDS = 'abstract|activate|and|any|array|as|asc|autonomous|begin|bigdecimal|blob|break|bulk|by|byte|case|cast|catch|char|class|collect|commit|const|continue|convertcurrency|decimal|default|delete|desc|do|else|end|enum|exception|exit|export|extends|false|final|finally|float|for|from|future|global|goto|group|having|hint|if|implements|import|in|inner|insert|instanceof|interface|into|int|join|last_90_days|last_month|last_n_days|last_week|like|limit|list|long|loop|map|merge|new|next_90_days|next_month|next_n_days|next_week|not|null|nulls|number|object|of|on|or|outer|override|package|parallel|pragma|private|protected|public|retrieve|return|returning|rollback|savepoint|search|select|set|short|sort|stat|static|super|switch|synchronized|system|testmethod|then|this|this_month|this_week|throw|today|tolabel|tomorrow|transaction|trigger|true|try|type|undelete|update|upsert|using|virtual|webservice|when|where|while|yesterday';
    public final String IGNORE_CASE = '(?i)';
    public final String VARIABLE_PATH = '([\\s\\S]*\\.|[\\s\\S]\\[\\d+]])';
    public final String INVALID_VARIABLE_CHARS = '[^a-z0-9_]';
    public final String INVALID_UNDERSCORES = '(?:^_+|_+$|(?<=_)_+)';
    public final Integer MAX_VARIABLE_LENGTH = 255;
    
    public List<String[]> fieldMapping { get; private set; }

    public JsonAutoMapper() {
        List<String[]> defaultFieldMapping = new List<String[]> {
            new String[] {
                IGNORE_CASE + '^' + VARIABLE_PATH + '(' + RESERVED_KEYWORDS + ')$',
                '$1$2_x'
            }
        };
        initialize(defaultFieldMapping);
    }

    private void initialize(List<String[]> fieldMapping) {
        this.fieldMapping = fieldMapping;
    }

    public JsonAutoMapper reset() {
        fieldMapping.clear();
        return this;
    }

    public JsonAutoMapper addField(String target, String replacement) {
        return addField(target, replacement, true);
    }

    public JsonAutoMapper addField(String target, String replacement, Boolean ignoreCase) {
        fieldMapping.add(new String[] {
            (ignoreCase ? IGNORE_CASE : '') + '^([\\s\\S]*\\.)(' + target + ')$',
            '.' + replacement
        });
        return this;
    }

    public JsonAutoMapper addPath(String target, String replacement) {
        return addPath(target, replacement, true);
    }

    public JsonAutoMapper addPath(String target, String replacement, Boolean ignoreCase) {
        fieldMapping.add(new String[] {
            (ignoreCase ? IGNORE_CASE : '') + '^' + target + '$',
            replacement
        });
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
        for (String[] mapping: fieldMapping) {
            pathOutput = pathOutput.replaceAll(mapping[0], mapping[1]);
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
        Pattern patternToken = Pattern.compile('\\[(\\d+)]|\\.([^\\.\\[]+)');
		
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