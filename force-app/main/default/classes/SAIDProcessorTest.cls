/**
 * 
 * This class contains unit tests for validating the behavior of SAIDProcessor Apex classes
 *
 */
@isTest
public class SAIDProcessorTest {

    /**
     * Mocks a successful Calendarific API response.
     */
    private class CalendarificMockSuccess implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            res.setStatusCode(200);
            res.setBody('{"response":{"holidays":[{"name":"Freedom Day","date":{"iso":"2025-04-27"}},{"name":"Heritage Day","date":{"iso":"2025-09-24"}}]}}');
            return res;
        }
    }

    /**
     * Tests the processId method with a valid SA ID.
     */
    @isTest
    static void testProcessIdCreatesRecord() {
        String validId = '8001015009087'; // 1980-01-01, Male, SA Citizen

        Test.startTest();
        Map<String, String> result = SAIDProcessor.processId(validId);
        Test.stopTest();

        System.assertEquals('1980', result.get('year'), 'Year should match decoded DOB');
        System.assertEquals('01/01/1980', result.get('dob'), 'DOB should be correctly formatted');

        // Verify record was inserted
        South_Africa_ID_Number__c record = [
            SELECT ID_Number__c, Gender__c, SA_Citizen_status__c, Search_Count__c
            FROM South_Africa_ID_Number__c
            WHERE ID_Number__c = :validId
            LIMIT 1
        ];
        System.assertEquals('Male', record.Gender__c);
        System.assertEquals('SA Citizen', record.SA_Citizen_status__c);
        System.assertEquals(1, record.Search_Count__c);
    }

    /**
     * Tests the getHolidays method with a mocked response.
     */
    @isTest
    static void testGetHolidays() {
        Test.setMock(HttpCalloutMock.class, new CalendarificMockSuccess());

        Test.startTest();
        List<Map<String, String>> holidays = SAIDProcessor.getHolidays(2025);
        Test.stopTest();

        System.assertEquals(2, holidays.size(), 'Should return two holidays');
        System.assertEquals('Freedom Day', holidays[0].get('name'));
        System.assertEquals('2025-04-27', holidays[0].get('date'));
    }

    /**
     * Test update logic if record already exists
     */
     @isTest
    static void testProcessIdUpdatesRecord() {
        String validId = '8001015009087';

        // Insert existing record
        South_Africa_ID_Number__c existing = new South_Africa_ID_Number__c(
            ID_Number__c = validId,
            Date_of_Birth__c = Date.newInstance(1980, 1, 1),
            Gender__c = 'Male',
            SA_Citizen_status__c = 'SA Citizen',
            Search_Count__c = 1,
            Last_Searched__c = System.now().addDays(-1)
        );
        insert existing;

        Test.startTest();
        SAIDProcessor.processId(validId);
        Test.stopTest();

        // Validate Search_Count__c incremented
        South_Africa_ID_Number__c updated = [
            SELECT Search_Count__c FROM South_Africa_ID_Number__c WHERE ID_Number__c = :validId
        ];
        System.assertEquals(2, updated.Search_Count__c, 'Search count should increment');
    }
}