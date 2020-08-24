public class ObjectAnnonation {

    public Responses[] responses;
    
    public class Responses {
        public LocalizedObjectAnnotations[] localizedObjectAnnotations;
    }
    
    public class LocalizedObjectAnnotations {
        public String mid;  
        public String name; 
        public Double score;    
    }
   
}