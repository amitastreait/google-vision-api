public class TextDetection {

    public Responses[] responses;
    
    public class Responses {
        public TextAnnotations[] textAnnotations;
    }
    
    public class TextAnnotations {
        public String locale;   
        public String description;  

    }
}