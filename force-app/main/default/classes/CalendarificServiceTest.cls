/**
 * 
 * This class contains unit tests for validating the behavior of CalendarificService Apex classes
 * 
 */
@isTest
public class CalendarificServiceTest {

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
     * Mocks a failed Calendarific API response (e.g. 500 error).
     */
    private class CalendarificMockFailure implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setStatusCode(500);
            res.setBody('{"error":"Internal Server Error"}');
            return res;
        }
    }

    /**
     * Tests successful holiday fetch.
     */
    @isTest
    static void testFetchHolidaysSuccess() {
        Test.setMock(HttpCalloutMock.class, new CalendarificMockSuccess());
        Test.startTest();
        List<Map<String, String>> holidays = CalendarificService.fetchHolidays(2025);
        Test.stopTest();

        System.assertEquals(2, holidays.size(), 'Should return two holidays');
        System.assertEquals('Freedom Day', holidays[0].get('name'));
        System.assertEquals('2025-04-27', holidays[0].get('date'));
    }

    /**
     * Tests failed holiday fetch and logs the error.
     */
    @isTest
    static void testFetchHolidaysFailure() {
        Test.setMock(HttpCalloutMock.class, new CalendarificMockFailure());
        Test.startTest();
        try {
            CalendarificService.fetchHolidays(2025);
            System.assert(false, 'Expected AuraHandledException was not thrown');
        } catch (Exception ex) {
            System.debug('EXCEPTION TYPE: ' + ex.getTypeName());
            System.debug('EXCEPTION MESSAGE: ' + ex.getMessage());

            System.assert(ex instanceof AuraHandledException, 'Exception is not AuraHandledException');
        }

        Test.stopTest();

        List<API_Callout_Log__c> logs = [SELECT Service_Name__c, Year__c, Failure_Reason__c FROM API_Callout_Log__c];
        System.assertEquals(1, logs.size(), 'Should log one failed callout');
        System.assertEquals('CalendarificAPI', logs[0].Service_Name__c);
        System.assertEquals(2025, logs[0].Year__c);
    }
}