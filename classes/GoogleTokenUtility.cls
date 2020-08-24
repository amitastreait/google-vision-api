global without sharing class GoogleTokenUtility {

    private static GoogleTokenUtility instance = null;
    
    private static FINAL String QUERY_SELECT = 'SELECT ';
    private static FINAL String QUERY_WHERE  = ' WHERE ';
    private static FINAL String QUERY_FROM   = ' FROM ';
    private static FINAL String QUERY_LIMIT  = ' LIMIT ';
    
    public static Google_Config__mdt googleConfig { get; set; }
    public static Google_Token__mdt googleToken   { get; set; }
    
    public FINAL String baseURL = System.URL.getSalesforceBaseURL().toExternalForm()+'/';
    
    public GoogleTokenUtility(){}

    private GoogleTokenUtility(String filter){
        getTokenInfo(filter);
    }
    
    public static GoogleTokenUtility getInstance(String filter){
        if(instance == null) {
           instance = new GoogleTokenUtility(filter);
        }
        return instance;
    }
    
    public static Google_Config__mdt getConfig(String filter){
        if(GoogleTokenUtility.googleConfig == null) {
            getConfigurationSettings(filter);
        }
        return GoogleTokenUtility.googleConfig;
    }
    
    
    private void getTokenInfo(String filter){
    
        Schema.sObjectType sobj = Schema.getGlobalDescribe().get('Google_Token__mdt');
        DescribeSObjectResult objectDescribe = sobj.getDescribe();
        Map<String, Schema.SObjectField> fieldMap = objectDescribe.fields.getMap();
        
        String whereClause = 'Masterlabel =:filter';
        String query = buildQueryAllString(fieldMap.values(),objectDescribe, whereClause, 1);
        
        List<Google_Token__mdt> tokenList = Database.Query(query);
        if(tokenList != null && !tokenList.isEmpty()){
            googleToken =  tokenList.get(0);
        }
        
    }
    
    private static void getConfigurationSettings(String filter){
    
        Schema.sObjectType sobj = Schema.getGlobalDescribe().get('Google_Config__mdt');
        DescribeSObjectResult objectDescribe = sobj.getDescribe();
        Map<String, Schema.SObjectField> fieldMap = objectDescribe.fields.getMap();
        
        String whereClause = 'Masterlabel =:filter';
        String query = buildQueryAllString(fieldMap.values(),objectDescribe, whereClause, 1);
        
        List<Google_Config__mdt> configList = Database.Query(query);
        if(configList != null && !configList.isEmpty()){
            googleConfig =  configList.get(0);
        }
        
    }
    
    private static String buildQueryAllString(List<Schema.SObjectField> allFields, DescribeSObjectResult obj, String filter, Integer rLimit) {
        
        String query = QUERY_SELECT;
        for(Schema.SObjectField dfr : allFields){
            query = query + dfr.getDescribe().getName() + ',';
        }
        query = query.subString(0,query.length() - 1);
        query = query + QUERY_FROM;
        query = query + obj.getName();
        if(!String.isBlank(filter)){
            query = query + QUERY_WHERE;
            query = query + filter;
        }
        query = query + QUERY_LIMIT;
        query = query + rLimit;
        return query;
        
    }
    
    public PageReference getAuthCode(){
    
        getConfig('Google_Config'); // Note:- Use a custom label to store the value and then refer label here
        
        if(GoogleTokenUtility.googleConfig == null){
            // Error Here
            return null;
        }
        
        String redirectURI = baseURL + GoogleTokenUtility.googleConfig.redirect_uri__c;
        
        String authURL = GoogleTokenUtility.googleConfig.authorize_url__c+
                         '?client_id='+GoogleTokenUtility.googleConfig.client_id__c+'&'+
                         'response_type='+GoogleTokenUtility.googleConfig.response_type__c+'&'+
                         'scope='+GoogleTokenUtility.googleConfig.scope__c+'&'+
                         'access_type='+GoogleTokenUtility.googleConfig.access_type__c+'&'+
                         'prompt='+GoogleTokenUtility.googleConfig.prompt__c+'&'+
                         'redirect_uri='+redirectURI;
                         
        PageReference pageRef = new PageReference(authURL);
        pageRef.setRedirect(true);
        
        return pageRef;
    }
    
    public PageReference getAccessToken(){
    
        String errorMessage = '';
        String authCode = ApexPages.currentPage().getParameters().get('code');
        getConfig('Google_Config'); // Note:- Use a custom label to store the value and then refer label here
        
        if(GoogleTokenUtility.googleConfig == null || String.isBlank(authCode)){
            // Error Here
            return null;
        }
        
        String redirectURI = baseURL + GoogleTokenUtility.googleConfig.redirect_uri__c;
        
        
        
        String requestBody = 'code='+authCode+'&'+
                             'client_id='+GoogleTokenUtility.googleConfig.client_id__c+'&'+
                             'client_secret='+GoogleTokenUtility.googleConfig.client_secret__c+'&'+
                             'redirect_uri='+redirectURI+'&'+
                             'grant_type='+GoogleTokenUtility.googleConfig.grant_type__c;
        
        HttpRequest httpReq = prepareRequest(GoogleTokenUtility.googleConfig.Token_URL__c,'POST',requestBody,
                                        GoogleTokenUtility.googleConfig.Content_Type__c);
        
        HttpResponse httpRes = new HttpResponse();
        try{
            httpRes = (new Http()).send(httpReq);
            if(httpRes.getStatusCode()==200){
                
                Map<String, Object> responseMap = (Map<String, Object>)JSON.deserializeUntyped(httpRes.getBody());

                Map<String, Object> tokenMap = new Map<String, Object>();
                
                Integer seconds = (Integer)responseMap.get('expires_in');
                tokenMap.put('access_token__c',(String)responseMap.get('access_token'));
                tokenMap.put('expires_in__c',seconds);
                tokenMap.put('expires_in_time__c',System.now().addSeconds(seconds));
                tokenMap.put('External_Id__c','GoogleToken');
                tokenMap.put('refresh_token__c',(String)responseMap.get('refresh_token'));
                tokenMap.put('scope__c',(String)responseMap.get('scope'));
                
                CreateUpdateMetadataUtils.createUpdateMetadata('Google_Token.GoogleToken','GoogleToken',tokenMap);
                
                ApexPages.addmessage(new ApexPages.message(ApexPages.severity.INFO, 'You can close the Window now!'));
                
            }else{
               errorMessage = 'Unexpected Error while communicating with Google API. '
                        +'Status '+httpRes.getStatus()+' and Status Code '+httpRes.getStatuscode();
               ApexPages.addmessage(new ApexPages.message(ApexPages.severity.ERROR, errorMessage));
            }
        }catch(System.CalloutException ex){
            if(String.valueOf(ex).startsWith('Unauthorized endpoint')){
                errorMessage = 'Unauthorize endpoint: An Administer must go to Setup -> Administer -> Security Control ->'
                        +' Remote Site Setting and add '+' '+ 'https://www.googleapis.com/' +' Endpoint';
                ApexPages.addmessage(new ApexPages.message(ApexPages.severity.ERROR, errorMessage));
            }
        }catch(System.Exception ex){
            if(String.valueOf(ex).startsWith('Unauthorized endpoint')){
                errorMessage = 'Unauthorize endpoint: An Administer must go to Setup -> Administer -> Security Control ->'
                        +' Remote Site Setting and add '+' '+ 'https://www.googleapis.com/' +' Endpoint';
                ApexPages.addmessage(new ApexPages.message(ApexPages.severity.ERROR, errorMessage));
            }
        }
        return null;
    }
    
    public static Map<String, Object> doRefreshToken(Google_Token__mdt googleToken){
    
        String errorMessage = '';
        getConfig('Google_Config'); // Note:- Use a custom label to store the value and then refer label here
        
        if(googleToken == null || GoogleTokenUtility.googleConfig == null){
            // Error Here
            return null;
        }
        
        String requestBody = 'client_id='+GoogleTokenUtility.googleConfig.client_id__c+'&'+
                             'client_secret='+GoogleTokenUtility.googleConfig.client_secret__c+'&'+
                             'refresh_token='+googleToken.refresh_token__c+'&'+
                             'grant_type=refresh_token';
        
        HttpRequest httpReq = prepareRequest(GoogleTokenUtility.googleConfig.Token_URL__c,'POST',requestBody,
                                        GoogleTokenUtility.googleConfig.Content_Type__c);
        
        HttpResponse httpRes = new HttpResponse();
        
        Map<String, Object> tokenMap = new Map<String, Object>();
        
        try{
            httpRes = (new Http()).send(httpReq);
            if(httpRes.getStatusCode()==200){

                Map<String, Object> responseMap = (Map<String, Object>)JSON.deserializeUntyped(httpRes.getBody());

                Integer seconds = (Integer)responseMap.get('expires_in');
                tokenMap.put('access_token__c',(String)responseMap.get('access_token'));
                tokenMap.put('expires_in__c',seconds);
                tokenMap.put('expires_in_time__c',System.now().addSeconds(seconds));
                
                //CreateUpdateMetadataUtils.createUpdateMetadata('Google_Token.GoogleToken','GoogleToken',tokenMap);
                
                
            }else{
               errorMessage = 'Unexpected Error while communicating with Google API. '
                        +'Status '+httpRes.getStatus()+' and Status Code '+httpRes.getStatuscode();
               
            }
        }catch(System.CalloutException ex){
            if(String.valueOf(ex).startsWith('Unauthorized endpoint')){
                errorMessage = 'Unauthorize endpoint: An Administer must go to Setup -> Administer -> Security Control ->'
                        +' Remote Site Setting and add '+' '+ 'https://www.googleapis.com/' +' Endpoint';
                
            }
        }catch(System.Exception ex){
            if(String.valueOf(ex).startsWith('Unauthorized endpoint')){
                errorMessage = 'Unauthorize endpoint: An Administer must go to Setup -> Administer -> Security Control ->'
                        +' Remote Site Setting and add '+' '+ 'https://www.googleapis.com/' +' Endpoint';
            }
        }
        return tokenMap;
    }
    
    public static Boolean checkIfTokenIsValid(Google_Token__mdt googleToken){
        Boolean isExpired = false;
        if(googleToken.expires_in_time__c < System.now()){
            isExpired = true;
        }
        return isExpired;
    }
    
    public static HttpRequest prepareRequest(String endPoint, String Method, String Body, String contentType){
        
        HttpRequest httpReq = new HttpRequest();
        httpReq.setEndpoint(endPoint);
        httpReq.setMethod(Method);
        httpReq.setHeader('Content-Type',contentType);
        if(!String.isBlank(body)){
            httpReq.setBody(body);
        }
        return httpReq;
        
    }
}