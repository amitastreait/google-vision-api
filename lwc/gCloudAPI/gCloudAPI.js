/**
 * @description       : 
 * @author            : Amit Singh
 * @group             : 
 * @last modified on  : 08-23-2020
 * @last modified by  : Amit Singh
 * Modifications Log 
 * Ver   Date         Author       Modification
 * 1.0   08-23-2020   Amit Singh   Initial Version
**/
import { LightningElement } from 'lwc';
import detectTextFromImage from '@salesforce/apex/GoogleCloudVisionAPI.detectTextFromImage';
import detectObjectFromImage from '@salesforce/apex/GoogleCloudVisionAPI.detectObjectFromImage';
import detectLogoFromImage from '@salesforce/apex/GoogleCloudVisionAPI.detectLogoFromImage';
import detectSafeFromImage from '@salesforce/apex/GoogleCloudVisionAPI.detectSafeFromImage';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
export default class GCloudAPI extends LightningElement {

    fileReader;
    fileContents;
    content;
    file;
    errors;
    MAX_FILE_SIZE = 1500000;
    sizeLongMessage;
    isLoading = false;
    fileLabel = 'Upload Image'
    fileName = 'file not selected'
    task
    imgURL = '';
    gCImgURL = '';

    get options() {
        return [
            { label: 'TEXT DETECTION', value: 'TEXT_DETECTION' },
            { label: 'DOCUMENT TEXT DETECTION', value: 'DOCUMENT_TEXT_DETECTION' },
            { label: 'OBJECT SEARCH', value: 'OBJECT_LOCALIZATION' },
            { label: 'SAFE SEARCH DETECTION', value: 'SAFE_SEARCH_DETECTION' }
        ];
    }

    handleURLChange(event){
        if(event.target.value){
            this.imgURL = event.target.value;
        }else{
            this.imgURL = '';
        }
    }

    handlegCURLChange(event){
        if(event.target.value){
            this.gCImgURL = event.target.value;
        }else{
            this.gCImgURL = '';
        }
    }

    handleTaskChange(event){
        this.task = event.target.value;
    }

    handleFilesChange(event){
        this.file = event.target.files[0];
        this.fileName = event.target.files[0]['name'];
    }

    startPrediction(){
        this.isLoading = true;
        if(this.imgURL){
            this.readBinaryFile('', this.imgURL,this.gcImageURL, this.task);
        }else if(this.gCImgURL){
            this.readBinaryFile('', this.imgURL,this.gcImageURL, this.task);
        }else if(this.file){
            this.readFileAsBinary();
        }
        
    }

    readFileAsBinary(){
        if (this.file.size > this.MAX_FILE_SIZE) {
            this.sizeLongMessage = this.file.size+' File Size is to long';
            return ;
        }
        this.isLoading = true;
        this.fileReader= new FileReader();
        this.fileReader.onloadend = (() => {
            this.fileContents = this.fileReader.result;
            let base64 = 'base64,';
            this.content = this.fileContents.indexOf(base64) + base64.length;
            this.fileContents = this.fileContents.substring(this.content);
            this.readBinaryFile(this.fileContents, this.imgURL,this.gcImageURL, this.task);
        });
        this.fileReader.readAsDataURL(this.file);
    }


    readBinaryFile(binaryData, imageURL, gcImageURL, taskType){
        if(this.task === 'OBJECT_LOCALIZATION'){
            console.log('gC Cloudd OBJECT_LOCALIZATION');
            this.detectObjectFromImageJS(binaryData, imageURL, gcImageURL, taskType);
        }else if(this.task === 'SAFE_SEARCH_DETECTION'){
            console.log('gC Cloudd SAFE_SEARCH_DETECTION');
            this.detectSafeFromImageJS(binaryData, imageURL, gcImageURL, taskType);
        }else{
            console.log('gC Cloudd DOCUMENT_TEXT_DETECTION');
            this.detectTextFromImageJS(binaryData, imageURL, gcImageURL, taskType);
        }
    }

    detectTextFromImageJS(binaryData, imageURL, gcImageURL, taskType){
        detectTextFromImage({
            base64String : binaryData,
            imageURL : imageURL,
            gScURL : gcImageURL,
            type : taskType
        })
        .then(result => {
            console.log(` Return data from API `, result);
            this.errors = undefined;
            this.dispatchEvent(new ShowToastEvent({
                title: 'Success!',
                message: 'gcCloud returns Success!',
                variant: 'success'
            }));
        })
        .catch(error => {
            this.errors = error;
            this.resultCard = undefined;
            console.error({
                message : 'Error Occured While making callout to Google API',
                data : error
            })
            this.dispatchEvent(new ShowToastEvent({
                title: 'Error!',
                message: JSON.stringify(error),
                variant: 'error'
            }));
        })
        .finally(()=>{
            this.isLoading = false;
        })
    }

    detectObjectFromImageJS(binaryData, imageURL, gcImageURL, taskType){
        detectObjectFromImage({
            base64String : binaryData,
            imageURL : imageURL,
            gScURL : gcImageURL,
            type : taskType
        })
        .then(result => {
            this.dispatchEvent(new ShowToastEvent({
                title: 'Success!',
                message: 'gcCloud returns Success!',
                variant: 'success'
            }));
        })
        .catch(error => {
            // TODO Error handling
            this.dispatchEvent(new ShowToastEvent({
                title: 'Error!',
                message: JSON.stringify(error),
                variant: 'error'
            }));
        })
        .finally(()=>{
            this.isLoading = false;
        })
    }

    detectSafeFromImageJS(binaryData, imageURL, gcImageURL, taskType){
        detectSafeFromImage({
            base64String : binaryData,
            imageURL : imageURL,
            gScURL : gcImageURL,
            type : taskType
        })
        .then(result => {
            this.dispatchEvent(new ShowToastEvent({
                title: 'Success!',
                message: 'gcCloud returns Success!',
                variant: 'success'
            }));
        })
        .catch(error => {
            // TODO Error handling
            this.dispatchEvent(new ShowToastEvent({
                title: 'Error!',
                message: JSON.stringify(error),
                variant: 'error'
            }));
        })
        .finally(()=>{
            this.isLoading = false;
        })
    }

    detectLogoFromImageJS(binaryData, imageURL, gcImageURL, taskType){
        detectLogoFromImage({
            base64String : binaryData,
            imageURL : imageURL,
            gScURL : gcImageURL,
            type : taskType
        })
        .then(result => {
            this.dispatchEvent(new ShowToastEvent({
                title: 'Success!',
                message: 'gcCloud returns Success!',
                variant: 'success'
            }));
        })
        .catch(error => {
            // TODO Error handling
            this.dispatchEvent(new ShowToastEvent({
                title: 'Error!',
                message: JSON.stringify(error),
                variant: 'error'
            }));
        })
        .finally(()=>{
            this.isLoading = false;
        })
    }
}