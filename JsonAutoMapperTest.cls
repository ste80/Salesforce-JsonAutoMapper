@IsTest(isParallel = true)
public class JsonAutoMapperTest {
    
    class TestDefault {
        public String abstract_x { get; set; }
        public Integer int_x { get; set; }
        public String normalStr { get; set; }
        public Integer normalInt { get; set; }
        public Double normalDbl { get; set; }
        public Boolean normalBol { get; set; }
    }
    
    class TestCustom {
        public String PREFIXabstractSUFFIX { get; set; }
        public Integer numberValue { get; set; }
        public String normalStr { get; set; }
        public Integer normalInt { get; set; }
        public Double normalDbl { get; set; }
        public Boolean normalBol { get; set; }
    }

	@IsTest
	static void it_should_rename_keywords_only() {
        
        // null test
		TestDefault mdlNull = (TestDefault)new JsonAutoMapper().deserialize('null', TestDefault.class);
		System.assertEquals(null, mdlNull);
		TestDefault mdlNullCoverage = (TestDefault)new JsonAutoMapper(false).addPath('.+','$1$2').deserialize('null', TestDefault.class);
		System.assertEquals(null, mdlNullCoverage);
        
        // string test
		String mdlString = (String)new JsonAutoMapper().deserialize('"string"', String.class);
		System.assertEquals('string', mdlString);
		String mdlStringCoverage = (String)new JsonAutoMapper(false).addPath('.+','$1$2').deserialize('"string"', String.class);
		System.assertEquals('string', mdlStringCoverage);
        
        // integer test
		Integer mdlInteger = (Integer)new JsonAutoMapper().deserialize('123', Integer.class);
		System.assertEquals(123, mdlInteger);
		Integer mdlIntegerCoverage = (Integer)new JsonAutoMapper(false).addPath('.+','$1$2').deserialize('123', Integer.class);
		System.assertEquals(123, mdlIntegerCoverage);
        
        // double test
		Double mdlDouble = (Double)new JsonAutoMapper().deserialize('123.456', Double.class);
		System.assertEquals(123.456, mdlDouble);
		Double mdlDoubleCoverage = (Double)new JsonAutoMapper(false).addPath('.+','$1$2').deserialize('123.456', Double.class);
		System.assertEquals(123.456, mdlDoubleCoverage);
        
        // Boolean test
		Boolean mdlTrue = (Boolean)new JsonAutoMapper().deserialize('true', Boolean.class);
		System.assertEquals(true, mdlTrue);
		Boolean mdlFalse = (Boolean)new JsonAutoMapper().deserialize('false', Boolean.class);
		System.assertEquals(false, mdlFalse);
		Boolean mdlFalseCoverage = (Boolean)new JsonAutoMapper(false).addPath('.+','$1$2').deserialize('false', Boolean.class);
		System.assertEquals(false, mdlFalseCoverage);
        
        Object invalidObj = new JsonAutoMapper().deserialize('{"!":"Invalid Field Name"}');
        System.assertEquals('Invalid Field Name', invalidObj);
        
        // single model
        String jsonString = '{' +
            	'"abstract": "abc",' +
            	'"int": 123,' +
            	'"normalStr": "def",' +
            	'"normalInt": 456,' +
            	'"normalDbl": 789.012,' +
            	'"normalBol": true' +
            '}';
		TestDefault mdlDefault = (TestDefault)new JsonAutoMapper().deserialize(jsonString, TestDefault.class);
		System.assertEquals('abc', mdlDefault.abstract_x);
		System.assertEquals(123, mdlDefault.int_x);
		System.assertEquals('def', mdlDefault.normalStr);
		System.assertEquals(456, mdlDefault.normalInt);
        System.assertEquals(789.012, mdlDefault.normalDbl);
        System.assertEquals(true, mdlDefault.normalBol);
        
        // array model
        String arrayString = '[' + jsonString + ',' + jsonString + ']';
		List<TestDefault> mdlDefaultList = (List<TestDefault>)new JsonAutoMapper()
            .deserialize(arrayString, List<TestDefault>.class);
        System.assertEquals(2, mdlDefaultList.size());
        for (TestDefault mdl: mdlDefaultList) {
            System.assertEquals('abc', mdl.abstract_x);
            System.assertEquals(123, mdl.int_x);
            System.assertEquals('def', mdl.normalStr);
            System.assertEquals(456, mdl.normalInt);
            System.assertEquals(789.012, mdl.normalDbl);
            System.assertEquals(true, mdl.normalBol);
        }
        
        /* change the naming conversion */
        JsonAutoMapper mapper = new JsonAutoMapper(false)
            .addField('abstract', 'PREFIXabstractSUFFIX')
            .addField('int', 'numberValue');
        
		TestCustom mdlCustom = (TestCustom)mapper.deserialize(jsonString, TestCustom.class);
		System.assertEquals('abc', mdlCustom.PREFIXabstractSUFFIX);
		System.assertEquals(123, mdlCustom.numberValue);
		System.assertEquals('def', mdlCustom.normalStr);
		System.assertEquals(456, mdlCustom.normalInt);
        
        
        /* flatten */
        String multipleDeepJson = '{"a":{"b":{"c":[{' +
            	'"abstract": "abc",' +
            	'"int": 123,' +
            	'"normalStr": "def",' +
            	'"normalInt": 456,' +
            	'"normalDbl": 789.012,' +
            	'"normalBol": true' +
            '},{' +
            	'"abstract": "abc",' +
            	'"int": 123,' +
            	'"normalStr": "def",' +
            	'"normalInt": 456,' +
            	'"normalDbl": 789.012,' +
            	'"normalBol": true' +
            '}]}}}';
        JsonAutoMapper mapper1 = new JsonAutoMapper(true).reset()
            .addPath('\\.a\\.b\\.c\\[0]\\.abstract', '.PREFIXabstractSUFFIX')
            .addPath('\\.a\\.b\\.c\\[0]\\.int', '.numberValue')
            .addPath('\\.a\\.b\\.c\\[0]\\.normalStr', '.normalStr')
            .addPath('\\.a\\.b\\.c\\[0]\\.normalInt', '.normalInt')
            .addPath('\\.a\\.b\\.c\\[0]\\.normalDbl', '.normalDbl')
            .addPath('\\.a\\.b\\.c\\[0]\\.normalBol', '.normalBol');
        
		TestCustom mdlCustom1 = (TestCustom)mapper1.deserialize(multipleDeepJson, TestCustom.class);
		System.assertEquals('abc', mdlCustom1.PREFIXabstractSUFFIX);
		System.assertEquals(123, mdlCustom1.numberValue);
		System.assertEquals('def', mdlCustom1.normalStr);
		System.assertEquals(456, mdlCustom1.normalInt);
        System.assertEquals(789.012, mdlCustom1.normalDbl);
        System.assertEquals(true, mdlCustom1.normalBol);
        
        /* array of array to array of object */
        String arrayOfArray = '[[' +
            	'"abc",' +
            	'123,' +
            	'"def",' +
            	'456,' +
            	'789.012,' +
            	'true,' +
            	'null' +
            '],[' +
            	'"abc",' +
            	'123,' +
            	'"def",' +
            	'456,' +
            	'789.012,' +
            	'true,' +
            	'null' +
            '],[' +
            	'"abc",' +
            	'123,' +
            	'"def",' +
            	'456,' +
            	'789.012,' +
            	'true,' +
            	'null' +
            ']]';
        JsonAutoMapper mapper2 = new JsonAutoMapper(false)
            .addPath('\\[(\\d+)]\\[0]', '[$1].PREFIXabstractSUFFIX')
            .addPath('\\[(\\d+)]\\[1]', '[$1].numberValue')
            .addPath('\\[(\\d+)]\\[2]', '[$1].normalStr')
            .addPath('\\[(\\d+)]\\[3]', '[$1].normalInt')
            .addPath('\\[(\\d+)]\\[4]', '[$1].normalDbl')
            .addPath('\\[(\\d+)]\\[5]', '[$1].normalBol')
            .addPath('\\[(\\d+)]\\[6]', '');
        
		List<Object> mdlCustom2 = (List<Object>)mapper2.deserialize(arrayOfArray);
        for (Object obj: mdlCustom2) {
            Map<String, Object> mdl = (Map<String, Object>)obj;
            System.assertEquals('abc', mdl.get('PREFIXabstractSUFFIX'));
            System.assertEquals(123, mdl.get('numberValue'));
            System.assertEquals('def', mdl.get('normalStr'));
            System.assertEquals(456, mdl.get('normalInt'));
        }
        
        /* type convertion */
        List<TestDefault> listDefault = new List<TestDefault>();
        for (Integer i = 0; i <= 1; i++) {
            TestDefault mdl = new TestDefault();
            mdl.abstract_x = i == 0 ? 'a' : 'b';
            mdl.int_x = i == 0 ? 1 : 2;
            mdl.normalStr = i == 0 ? 'aa' : 'bb';
            mdl.normalInt = i == 0 ? 11 : 22;
            listDefault.add(mdl);
        }
        JsonAutoMapper mapper3 = new JsonAutoMapper(false)
            .addField('abstract_x', 'PREFIXabstractSUFFIX')
            .addField('int_x', 'numberValue');
		List<TestCustom> mdlCustom3 = (List<TestCustom>)mapper3.deserialize(JSON.serialize(listDefault), List<TestCustom>.class);
        for (Integer i = 0; i < mdlCustom3.size(); i++) {
            TestCustom mdl = mdlCustom3[i];
            System.assertEquals(i == 0 ? 'a' : 'b', mdl.PREFIXabstractSUFFIX);
            System.assertEquals(i == 0 ? 1 : 2, mdl.numberValue);
            System.assertEquals(i == 0 ? 'aa' : 'bb', mdl.normalStr);
            System.assertEquals(i == 0 ? 11 : 22, mdl.normalInt);
        }
        
        TestCustom objInput4 = new TestCustom();
        objInput4.PREFIXabstractSUFFIX = 'abc';
        objInput4.numberValue = 1;
        JsonAutoMapper mapper4 = new JsonAutoMapper(false)
            .addField('PREFIXabstractSUFFIX', 'abstract')
            .addField('numberValue', 'int');
        Map<String, Object> json4 = (Map<String, Object>)JSON.deserializeUntyped(mapper4.serialize(objInput4));
        System.assertEquals('abc', json4.get('abstract'));
        System.assertEquals(1, json4.get('int'));
        
        TestCustom objInput5 = new TestCustom();
        objInput5.PREFIXabstractSUFFIX = 'abc';
        objInput5.numberValue = 1;
        JsonAutoMapper mapper5 = new JsonAutoMapper(false)
            .addField('PREFIXabstractSUFFIX', 'abstract')
            .addPath('\\.numberValue', '.int');
        Map<String, Object> json5 = (Map<String, Object>)JSON.deserializeUntyped(mapper5.serialize(objInput5));
        System.assertEquals('abc', json5.get('abstract'));
        System.assertEquals(1, json5.get('int'));
        
	}
}