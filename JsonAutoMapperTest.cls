@IsTest(isParallel = true)
public class JsonAutoMapperTest {
    
    class TestDefault {
        public String abstract_x { get; set; }
        public Integer int_x { get; set; }
        public String normalStr { get; set; }
        public Integer normalInt { get; set; }
    }
    
    class TestCustom {
        public String PREFIXabstractSUFFIX { get; set; }
        public Integer numberValue { get; set; }
        public String normalStr { get; set; }
        public Integer normalInt { get; set; }
    }

	@IsTest
	static void it_should_rename_keywords_only() {
		TestDefault mdlNull = (TestDefault)new JsonAutoMapper().deserialize('null', TestDefault.class);
		System.assertEquals(null, mdlNull);
        
        // single model
        String jsonString = '{' +
            	'"abstract": "abc",' +
            	'"int": 123,' +
            	'"normalStr": "def",' +
            	'"normalInt": 456' +
            '}';
		TestDefault mdlDefault = (TestDefault)new JsonAutoMapper().deserialize(jsonString, TestDefault.class);
		System.assertEquals('abc', mdlDefault.abstract_x);
		System.assertEquals(123, mdlDefault.int_x);
		System.assertEquals('def', mdlDefault.normalStr);
		System.assertEquals(456, mdlDefault.normalInt);
        
        // array model
        String arrayString = '[' + jsonString + ',' + jsonString + ']';
		List<TestDefault> mdlDefaultList = (List<TestDefault>)new JsonAutoMapper().deserialize(arrayString, List<TestDefault>.class);
        System.assertEquals(2, mdlDefaultList.size());
        for (TestDefault mdl: mdlDefaultList) {
            System.assertEquals('abc', mdl.abstract_x);
            System.assertEquals(123, mdl.int_x);
            System.assertEquals('def', mdl.normalStr);
            System.assertEquals(456, mdl.normalInt);
        }
        
        /* change the naming conversion */
        JsonAutoMapper mapper = new JsonAutoMapper();
        mapper.reset()
            .addField('abstract', 'PREFIXabstractSUFFIX')
            .addField('int', 'numberValue');
        
		TestCustom mdlCustom = (TestCustom)mapper.deserialize(jsonString, TestCustom.class);
		System.assertEquals('abc', mdlCustom.PREFIXabstractSUFFIX);
		System.assertEquals(123, mdlCustom.numberValue);
		System.assertEquals('def', mdlCustom.normalStr);
		System.assertEquals(456, mdlCustom.normalInt);
        
        
        /* flatten */
        String multipleDeepJson = '{"a":[{' +
            	'"abstract": "abc",' +
            	'"int": 123,' +
            	'"normalStr": "def",' +
            	'"normalInt": 456' +
            '},{' +
            	'"abstract": "abc",' +
            	'"int": 123,' +
            	'"normalStr": "def",' +
            	'"normalInt": 456' +
            '}]}';
        JsonAutoMapper mapper1 = new JsonAutoMapper();
        mapper1.reset()
            .addPath('\\.a\\[0]\\.abstract', '.PREFIXabstractSUFFIX')
            .addPath('\\.a\\[0]\\.int', '.numberValue')
            .addPath('\\.a\\[0]\\.normalStr', '.normalStr')
            .addPath('\\.a\\[0]\\.normalInt', '.normalInt');
        
		TestCustom mdlCustom1 = (TestCustom)mapper1.deserialize(multipleDeepJson, TestCustom.class);
		System.assertEquals('abc', mdlCustom1.PREFIXabstractSUFFIX);
		System.assertEquals(123, mdlCustom1.numberValue);
		System.assertEquals('def', mdlCustom1.normalStr);
		System.assertEquals(456, mdlCustom1.normalInt);
        
        /* array of array to array of object */
        String arrayOfArray = '[[' +
            	'"abc",' +
            	'123,' +
            	'"def",' +
            	'456' +
            '],[' +
            	'"abc",' +
            	'123,' +
            	'"def",' +
            	'456' +
            '],[' +
            	'"abc",' +
            	'123,' +
            	'"def",' +
            	'456' +
            ']]';
        JsonAutoMapper mapper2 = new JsonAutoMapper();
        mapper2.reset()
            .addPath('\\[(\\d+)]\\[0]', '[$1].PREFIXabstractSUFFIX')
            .addPath('\\[(\\d+)]\\[1]', '[$1].numberValue')
            .addPath('\\[(\\d+)]\\[2]', '[$1].normalStr')
            .addPath('\\[(\\d+)]\\[3]', '[$1].normalInt');
        
		List<Object> mdlCustom2 = (List<Object>)mapper2.deserialize(arrayOfArray);
        for (Object obj: mdlCustom2) {
            Map<String, Object> mdl = (Map<String, Object>)obj;
            System.assertEquals('abc', mdl.get('PREFIXabstractSUFFIX'));
            System.assertEquals(123, mdl.get('numberValue'));
            System.assertEquals('def', mdl.get('normalStr'));
            System.assertEquals(456, mdl.get('normalInt'));
        }
	}
}