import { LightningElement, api, track } from 'lwc';
import processId from '@salesforce/apex/SAIDProcessor.processId';
import getHolidays from '@salesforce/apex/SAIDProcessor.getHolidays';

export default class saHolidayViewer extends LightningElement {
    @api idNumber = '';
    @track result = [];
    @track dob;
    @track isDisabled = true;
    @track errorMessage;
    @track isLoading = false; 
    @track showTable = false;

    //column definations for datatable
    @track columns = [
        { label: 'Holiday Name', fieldName: 'name', type: 'text' },
        { label: 'Date', fieldName: 'date', type: 'date' }
    ];

    //handle input change
    handleChange(event) {
        this.idNumber = event.target.value;
        this.validateId(this.idNumber);
    }

    //validate SA ID format and checksum
    validateId(id) {
        // must be 13 digits and pass Luhn check
        if (!/^\d{13}$/.test(id) || !this.luhnCheck(id)) {
            this.errorMessage = '❌ Please enter a valid 13-digit SA ID number.';
            this.isDisabled = true;
            return;
        }

        this.isDisabled = false;
        this.errorMessage = '';
    }

    // luhn algorithm for SA ID checksum validation
    luhnCheck(id) {
        let sum = 0;
        let alternate = false;

        // traverse digits from right to left
        for (let i = id.length - 1; i >= 0; i--) {
        let n = parseInt(id.charAt(i), 10);
        if (alternate) {
            n *= 2;
            if (n > 9) n -= 9;
        }
        sum += n;
        alternate = !alternate;
        }
        // valid if sum modulo 10 is zero
        return sum % 10 === 0;
    }

    // handle search action: decode ID and fetch holidays
    async handleSearch() {
        this.isLoading = true;
        this.showTable = false;
        try {
            // call Apex to decode ID and extract DOB
            const resultYear = await processId({ id: this.idNumber });
            try{
                // fetch holidays for the birth year
                const holidays = await getHolidays({ year: resultYear.year });
                this.result = holidays;
                this.showTable = this.result.length > 0;
            }catch (error) {
                console.error('Holiday fetch error:', error);
                this.errorMessage = 'Could not retrieve holidays.';
            }

        } catch (error) {
            console.error('ID processing error:', error);
            this.errorMessage = 'Invalid ID or decoding failed.';
        }finally{
            this.isLoading = false;
        }
    }
}