public with sharing class StripeProductController {
    private static final String STRIPE_SECRET_KEY = 'sk_test_51PJU2RSIYOZmnVyHGQG0auC8DJLHX689fa3W0DTILjIH50xDMET38iBsMBf8Bx96ComgPe46uty8k5XxEbQeM1Sn00CMYPGkiM';
    
    //Product object 
    public class Product {
        @AuraEnabled
        public String id { get; set; }
        @AuraEnabled
        public String name { get; set; }
        @AuraEnabled
        public String description { get; set; }
        @AuraEnabled
        public String image { get; set; }
        @AuraEnabled
        public String price { get; set; }
        @AuraEnabled
        public String priceId { get; set; }
    }

    //Method to Get All Products from Stripe
    //Accepts no arguments
    //Returns List of Products from stripe
    @AuraEnabled(cacheable=true)
    public static List<Product> getProducts(){
        Http http = new Http();
        HttpRequest req = new HttpRequest();
        req.setEndpoint('https://api.stripe.com/v1/products');
        req.setMethod('GET');
        req.setHeader('Authorization', 'Bearer ' + STRIPE_SECRET_KEY);
        HttpResponse response = http.send(req);
        
        //If result is success
        if(response.getStatusCode() == 200) {
            List<Product> products = new List<Product>();
            Map<String, Object> resMap = (Map<String, Object>) JSON.deserializeUntyped(response.getBody());
            List<Object> dataList = (List<Object>) resMap.get('data');
            for(Object obj : dataList) {
                Map<String, Object> productMap = (Map<String, Object>) obj;
                Product product = new Product();
                product.id = (String) productMap.get('id');
                product.name = (String) productMap.get('name');
                product.description = (String) productMap.get('description');
                product.priceId = (String) productMap.get('default_price');
                product.image = productMap.get('images') != null && !((List<Object>) productMap.get('images')).isEmpty() ? ((List<Object>) productMap.get('images'))[0].toString() : null;
                String defaultPriceId = (String) productMap.get('default_price');
                if (defaultPriceId != null) {
                    product.price = fetchProductPrice(defaultPriceId);
                }
                products.add(product);
            }
            return products;
        } 
        //If result is fail
        else {
            throw new AuraHandledException('Error : ' + response.getBody());
        }
    }

    //Method to Get price of Product with priceId
    //Accepts String type price Id of product as argument
    //Returns String contaning price of product
    public static String fetchProductPrice(String priceId) {
        Http http = new Http();
        HttpRequest req = new HttpRequest();
        req.setEndpoint('https://api.stripe.com/v1/prices/' + priceId);
        req.setMethod('GET');
        req.setHeader('Authorization', 'Bearer ' + STRIPE_SECRET_KEY);
        HttpResponse response = http.send(req);

        //If result is success
        if (response.getStatusCode() == 200) {
            Map<String, Object> priceMap = (Map<String, Object>) JSON.deserializeUntyped(response.getBody());
            String unitAmount = (Integer) priceMap.get('unit_amount') + '';
            return unitAmount.substring(0, unitAmount.length()-2) + '.' + unitAmount.substring(unitAmount.length()-2);
        }
        return '0';
    }

    //Method to Create Payment Link of Product
    //Accepts String type price Id of product as argument
    //Returns Generated link of product payment
    @AuraEnabled
    public static String createPaymentLink(String priceId) {
        Http http = new Http();
        HttpRequest req = new HttpRequest();
        req.setEndpoint('https://api.stripe.com/v1/payment_links');
        req.setMethod('POST');
        req.setHeader('Authorization', 'Bearer ' + STRIPE_SECRET_KEY);
        req.setHeader('Content-Type', 'application/x-www-form-urlencoded');
        req.setBody('line_items[0][price]=' + priceId + '&line_items[0][quantity]=1');

        HttpResponse response = http.send(req);

        //If result is success
        if (response.getStatusCode() == 200) {
            Map<String, Object> paymentLinkMap = (Map<String, Object>) JSON.deserializeUntyped(response.getBody());
            return (String) paymentLinkMap.get('url');
        }
        throw new AuraHandledException('Error creating payment link: ' + response.getBody());
    }

}