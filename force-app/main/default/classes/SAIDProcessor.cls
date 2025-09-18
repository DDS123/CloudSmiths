/**
 * SAIDProcessor Class
 *
 * Validates and decodes South African ID numbers, stores/upserts records,
 * and returns structured identity data with public holidays.
 *
 * Author: Divya Muvvala
 * Created: September 2025
 */
global without sharing class SAIDProcessor {
  
    /**
     * Main method exposed to LWC or Flow.
     * Returns decoded identity info and holidays using wrapper.
     */
    @AuraEnabled
    public static Map<String,String> processId(String id) {

        SAIDNumberWrapper wrapper = new SAIDNumberWrapper();
        wrapper.idNumber = id;
        // Decode DOB
        wrapper.dob = decodeDob(id);
        wrapper.gender = decodeGender(id);
        wrapper.citizenStatus = decodeCitizenship(id);

        upsertIdRecord(wrapper);

        Integer year = wrapper.dob.year();       
        return new Map<String, String>{
                    'year' => String.valueOf(year),
                    'dob' => String.ValueOf(wrapper.dob.format())
                };
    }

    @AuraEnabled
    public static List<Map<String, String>> getHolidays(Integer year) {
        List<Map<String, String>> holidays = CalendarificService.fetchHolidays(year);
        return holidays;
    }

    // Decode date of birth from ID
    private static Date decodeDob(String id) {
        Integer year = Integer.valueOf(id.substring(0, 2));
        Integer month = Integer.valueOf(id.substring(2, 4));
        Integer day = Integer.valueOf(id.substring(4, 6));
        Integer fullYear = Date.today().year();
        Integer currentYear = Math.mod(fullYear, 100);
        year += (year > currentYear ? 1900 : 2000);
        return Date.newInstance(year, month, day);
    }

    // Decode gender from ID
    private static String decodeGender(String id) {
        return Integer.valueOf(id.substring(6, 10)) < 5000 ? 'Female' : 'Male';
    }

    // Decode citizenship status from ID
    private static String decodeCitizenship(String id) {
        return id.substring(10, 11) == '0' ? 'SA Citizen' : 'Permanent resident';
    }

    // Upsert record in custom object
    private static void upsertIdRecord(SAIDNumberWrapper wrapper) {
        South_Africa_ID_Number__c record;
        List<South_Africa_ID_Number__c> existing = [
            SELECT Id, Search_Count__c FROM South_Africa_ID_Number__c WHERE ID_Number__c = :wrapper.idNumber LIMIT 1
        ];
        if (existing.isEmpty()) {
            record = new South_Africa_ID_Number__c(
                ID_Number__c = wrapper.idNumber,
                Date_of_Birth__c = wrapper.dob,
                Gender__c = wrapper.gender,
                SA_Citizen_status__c = wrapper.citizenStatus,
                Search_Count__c = 1,
                Last_Searched__c = System.now()
            );
        } else {
            record = existing[0];
            record.Search_Count__c += 1;
            record.Last_Searched__c = System.now();
        }
        upsert record;
    }

    public class SAIDNumberWrapper {
        public String idNumber;
        public Date dob;
        public String gender;
        public String citizenStatus;
    }
}