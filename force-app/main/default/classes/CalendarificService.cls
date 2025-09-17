public without sharing class CalendarificService {

    /**
     * Fetches public holidays for South Africa from Calendarific API.
     * @param year The year to query
     * @return List of maps with 'name' and 'date' keys
     */
    public static List<Map<String, String>> fetchHolidays(Integer year) {
        HttpRequest req = new HttpRequest();
        req.setEndpoint('callout:CalendarificAPI/holidays?country=ZA&year=' + year + '&type=national');
        req.setMethod('GET');
        req.setTimeout(10000); // 10-second timeout

        HttpResponse res;
        try {
            res = new Http().send(req);
        } catch (Exception ex) { 
            logCalloutFailure('CalendarificAPI', year, ex.getMessage());
            throw new AuraHandledException('Holiday service is currently unavailable. Please try again later.');
        }

        if (res.getStatusCode() != 200) { 
            logCalloutFailure('CalendarificAPI', year, 'Status:'+ res.getStatusCode());
            //throw new AuraHandledException('Failed to retrieve holidays. Please try again later.');
        }

        return parseHolidayResponse(res.getBody());
    }

    /**
     * Parses the JSON response from Calendarific.
     */
    private static List<Map<String, String>> parseHolidayResponse(String body) {
        List<Map<String, String>> holidays = new List<Map<String, String>>();
        Map<String, Object> json = (Map<String, Object>) JSON.deserializeUntyped(body);
        List<Object> holidayList = (List<Object>) ((Map<String, Object>) json.get('response')).get('holidays');

        for (Object h : holidayList) {
            Map<String, Object> holiday = (Map<String, Object>) h;
            Map<String, Object> dateObj = (Map<String, Object>) holiday.get('date');
            holidays.add(new Map<String, String>{
                'name' => (String) holiday.get('name'),
                'date' => (String) dateObj.get('iso')
            });
        }
        return holidays;
    }

    /**
     * Logs failed callouts to a custom object for admin review.
     */
    private static void logCalloutFailure(String serviceName, Integer year, String reason) {
       
        try {
            API_Callout_Log__c log = new API_Callout_Log__c(
                Name = serviceName,
                Service_Name__c = serviceName,
                Year__c = year,
                Failure_Reason__c = reason,
                Timestamp__c = System.now()
            );
         
            insert log;           
        } catch (Exception e) {
            // Avoid cascading failure
            System.debug('Log insert failed: ' + e.getMessage());
        }
    }
}