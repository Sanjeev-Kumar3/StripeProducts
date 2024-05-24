import { LightningElement, track, wire } from 'lwc';
import getProducts from '@salesforce/apex/StripeProductController.getProducts';
import createPaymentLink from '@salesforce/apex/StripeProductController.createPaymentLink';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

export default class GetStripeProducts extends LightningElement {

    @track products; //store all products
    @track error; //store error

    //Calling getProduct apex method to get all products
    @wire(getProducts)
    wiredProducts({error, data}) {
        if(data) {
            this.products = data;
            this.error = undefined;
        } else if(error) {
            this.error = error;
            this.products = undefined;
        }
    }

    //Mathod to generate payment link of specific product
    handleCreatePaymentLink(event) {
        const priceId = event.target.dataset.priceId;
        createPaymentLink({ priceId : priceId })
            .then((paymentLink) => {
                this.showToast('Success', 'Payment link created: ' + paymentLink, 'success');
                window.open(paymentLink);
            })
            .catch((error) => {
                this.showToast('Error', 'Error creating payment link: ' + error.body.message, 'error');
            });
    }

    //Method to show toast
    showToast(title, message, variant) {
        const event = new ShowToastEvent({ title, message, variant });
        this.dispatchEvent(event);
    }

}