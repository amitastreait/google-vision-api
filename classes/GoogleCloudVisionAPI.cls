/*


*/
global with sharing class GoogleCloudVisionAPI  {

    private static FINAL String END_POINT    = 'https://vision.googleapis.com/v1/images:annotate';
    private static FINAL String CONTENT_TYPE = 'application/json';
    private static FINAL String TOKEN_TYPE   = 'Bearer ';
    private static FINAL String GC_MODEL     = 'builtin/stable';
    
    @AuraEnabled
    public static List<Image_Detection__c> detectTextFromImage(String base64String, String imageURL, String gScURL, String type){
    
        ResponseWrapper wrapper = doCallGcCloudAPI(base64String, imageURL, gScURL, type);
        
        List<Image_Detection__c> imageDitList = new List<Image_Detection__c>();
        
        if(!String.isBlank(wrapper.response)){
        
            TextDetection text = (TextDetection)System.JSON.deserialize(wrapper.response, TextDetection.class);

            List<TextDetection.Responses> responseList = text.responses;
            
            if(responseList != null && !responseList.isEmpty()){
                List<TextDetection.TextAnnotations> annotations = responseList.get(0).textAnnotations;
                for(TextDetection.TextAnnotations ann : annotations){
                
                    Image_Detection__c img = new Image_Detection__c();
                    img.Name      = ann.description;
                    img.Locale__c = ann.locale;
                    img.External_Id__c = ann.description;
                    
                    imageDitList.add(img);
                }
            }
            
            insertImageDetData(wrapper.response, base64String );
            
        }
        return imageDitList;
        
    }
    
    
    @AuraEnabled
    public static List<OBJECT_LOCALIZATION__c> detectObjectFromImage(String base64String, String imageURL, String gScURL, String type){
        
        ResponseWrapper wrapper = doCallGcCloudAPI(base64String, imageURL, gScURL, type);
        //System.debug(System.LoggingLevel.DEBUG, wrappper);
        
        List<OBJECT_LOCALIZATION__c> objectList = new List<OBJECT_LOCALIZATION__c>();
        
        if(!String.isBlank(wrapper.response)){
        
            ObjectAnnonation objects = (ObjectAnnonation) System.JSON.deserialize(wrapper.response, ObjectAnnonation.class);
            
            System.debug(objects);
            
            List<ObjectAnnonation.Responses> responseList = objects.responses;
            
            if(responseList != null && !responseList.isEmpty()){
            
                List<ObjectAnnonation.LocalizedObjectAnnotations> annotations = responseList.get(0).localizedObjectAnnotations;
                
                for(ObjectAnnonation.LocalizedObjectAnnotations obj: annotations){
                    if(obj.name != 'Animal'){
                        OBJECT_LOCALIZATION__c ob = new OBJECT_LOCALIZATION__c(
                            Name = obj.name,
                            Score__c = obj.score
                        );
                        objectList.add(ob);
                    }
                }
                
            }
           Database.insert(objectList, false); 
        }
        
        return objectList;
    }
    
    @AuraEnabled
    public static void detectLogoFromImage(String base64String, String imageURL, String gScURL, String type){
        
        ResponseWrapper wrapper = doCallGcCloudAPI(base64String, imageURL, gScURL, type);
        //System.debug(System.LoggingLevel.DEBUG, wrapper);
        
        
    }
    
    @AuraEnabled
    public static String detectSafeFromImage(String base64String, String imageURL, String gScURL, String type){
    
        ResponseWrapper wrapper = doCallGcCloudAPI(base64String, imageURL, gScURL, type);
        
        System.debug(System.LoggingLevel.DEBUG, wrapper);
        String response = '';
        
        if(!String.isBlank(wrapper.response)){
            response = wrapper.response;
        }else{
            response = wrapper.error;
        }
        return response;
    }
    
    @future
    private static void insertImageDetData(String response, String base64String){
    
        List<Image_Detection__c> imageDitList = new List<Image_Detection__c>();
        Image_Detection__c parentImg = new Image_Detection__c();
        
        if(!String.isBlank(response)){
        
            TextDetection text = (TextDetection)System.JSON.deserialize(response, TextDetection.class);
    
            List<TextDetection.Responses> responseList = text.responses;
                
            if(responseList != null && !responseList.isEmpty()){
                List<TextDetection.TextAnnotations> annotations = responseList.get(0).textAnnotations;
                for(TextDetection.TextAnnotations ann : annotations){
                    Image_Detection__c img = new Image_Detection__c();
                    img.Name      = ann.description;
                    img.Locale__c = ann.locale;
                    img.External_Id__c = ann.description;
                    if(String.isBlank(ann.locale)){
                        imageDitList.add(img);
                    }else{
                        parentImg = img;
                    }
                    
                }
            }
        }
                        
        Database.upsert(parentImg, Image_Detection__c.External_Id__c, false);
         
        for(Image_Detection__c im: imageDitList){
            if( parentImg.Id != null ){
                im.Parent__c = parentImg.Id;
            }
        }
        
        Database.upsert(imageDitList, Image_Detection__c.External_Id__c, false);
        
    }
    
    private static ResponseWrapper doCallGcCloudAPI(String base64String, String imageURL, String gScURL, String type){
        
        String requestBody = prepareBody(base64String, imageURL, gScURL, type);
              
        //System.debug(System.LoggingLevel.DEBUG, requestBody);
        
        GoogleTokenUtility gt = GoogleTokenUtility.getInstance('GoogleToken');
        
        String accessToken = GoogleTokenUtility.googleToken.access_token__c;
        
        HttpRequest httpReq = GoogleTokenUtility.prepareRequest(END_POINT,'POST',requestBody,CONTENT_TYPE);
        httpReq.setHeader('Accept', CONTENT_TYPE);
        
        Boolean isExpired = GoogleTokenUtility.checkIfTokenIsValid(GoogleTokenUtility.googleToken);
        Map<String, Object> tokenMap;
        if(isExpired){
            tokenMap = GoogleTokenUtility.doRefreshToken(GoogleTokenUtility.googleToken);
            if(tokenMap!=null)
                accessToken = (String)tokenMap.get('access_token__c');
        }
        if(isExpired && ( tokenMap == null || tokenMap.size() == 0 ) ){
            return null;
        }
        
        httpReq.setHeader('Authorization', TOKEN_TYPE+accessToken);
        
       ResponseWrapper wrappper = sendRequest(httpReq);
       
       if(!String.isBlank(wrappper.error)){

       }else{
           //Success Reponse Here
           if(tokenMap!=null)
               CreateUpdateMetadataUtils.createUpdateMetadata('Google_Token.GoogleToken','GoogleToken',tokenMap);
       }
       return wrappper;
    }
    
    public static ResponseWrapper sendRequest(HttpRequest httpReq){
    
        HttpResponse httpRes = new HttpResponse();
        String errorMessage = '';
        String reesponse =  '';
        
        ResponseWrapper wrapper = new ResponseWrapper();
        try{
            httpRes = (new Http()).send(httpReq);
            if(httpRes.getStatusCode()==200){
                wrapper.response = httpRes.getBody();
            }else{
               errorMessage = 'Error: Unexpected Error while communicating with Google API. '
                        +'Status: '+httpRes.getStatus()+' and Status Code: '+httpRes.getStatuscode()
                        +' Response:: '+httpRes.getBody();
               
            }
        }catch(System.CalloutException ex){
            if(String.valueOf(ex).startsWith('Unauthorized endpoint')){
                errorMessage = 'Error: Unauthorize endpoint: An Administer must go to Setup -> Administer -> Security Control ->'
                        +' Remote Site Setting and add '+' '+ 'https://www.googleapis.com/' +' Endpoint'
                        +' Response:: '+httpRes.getBody();
                
            }else{
                errorMessage = 'Error: Unexpected Error while communicating with Google API. '
                        +'Status: '+httpRes.getStatus()+' and Status Code: '+httpRes.getStatuscode()
                        +' Response:: '+httpRes.getBody();
            }
        }
        wrapper.error = errorMessage;
        
        return wrapper;
    }
    
    private static String prepareBody(String base64String, String imageURL, String gScURL, String type){
    
        String content = String.isBlank(base64String) ? '""' : '"'+base64String+'"';
        String imgURL  = String.isBlank(imageURL)     ? '""' : '"'+imageURL+'"';
        String gcURL   = String.isBlank(gScURL)       ? '""' : '"'+gScURL+'"';
        
        String requestBody = '{'+
          '"requests": ['+
            '{'+
              '"features": ['+
                '{'+
                  '"model": "'+GC_MODEL+'",'+
                  '"type": "'+type+'",'+
                  '"maxResults": 10'+
                '}'+
              '],'+
              '"image": {'+
                '"source": {'+
                  '"imageUri": '+imgURL+','+
                  '"gcsImageUri": '+gcURL+
                '},'+
                '"content": '+content+
              '}'+
            '}'+
          ']'+
        '}';
        return requestBody;
    }
    
    public class ResponseWrapper {
        public String response { get; set; }
        public String error    { get; set; }
    }
}