//
//  SwiftOCR.swift
//  SwiftOpenCV
//
//  Created by Lee Whitney on 10/28/14.
//  Copyright (c) 2014 WhitneyLand. All rights reserved.
//

import Foundation
import UIKit

class SwiftOCR {
    
    var _image: UIImage
    var _tesseract: Tesseract
    var _characterBoxes : Array<CharBox>
    
    var _groupedImage : UIImage
    var _recognizedText: String
    
    //Get grouped image after executing recognize method
    var groupedImage : UIImage {
        get {
            return _groupedImage;
        }
    }
    
    //Get Recognized Text after executing recognize method
    var recognizedText: String {
        get {
            return _recognizedText;
        }
    }
    
    var characterBoxes :Array<CharBox> {
        get {
            return _characterBoxes;
        }
    }
    
    /*init(fromImagePath path:String) {
        _image = UIImage(contentsOfFile: path)!
        _tesseract = Tesseract(language: "eng")
        _tesseract.setVariableValue("0123456789abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ", forKey: "tessedit_char_whitelist")
        _tesseract.image = _image
        _characterBoxes = Array<CharBox>()
        _groupedImage = _image
        _recognizedText = ""
    }*/
    
    init(fromImage image:UIImage) {
        
        _image = image;
        _tesseract = Tesseract(language: "eng")
        _tesseract.setVariableValue("0123456789abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ()@+.-,!#$%&*?''", forKey: "tessedit_char_whitelist")
        println(image)
        _tesseract.image = image
        _characterBoxes = Array<CharBox>()
         _groupedImage = image
        _recognizedText = ""
        NSLog("%d",image.imageOrientation.rawValue);
    }
    
    
    //Recognize function
    func recognize() {
        
         _characterBoxes = Array<CharBox>()
        
        var uImage = CImage(image: _image);
        
        var channels = uImage.channels;
        
        let classifier1 = NSBundle.mainBundle().pathForResource("trained_classifierNM1", ofType: "xml")
        let classifier2 = NSBundle.mainBundle().pathForResource("trained_classifierNM2", ofType: "xml")
        
        var erFilter1 = ExtremeRegionFilter.createERFilterNM1(classifier1, c: 8, x: 0.00015, y: 0.13, f: 0.2, a: true, scale: 0.1);
        var erFilter2 = ExtremeRegionFilter.createERFilterNM2(classifier2, andX: 0.5);
        
        var regions = Array<ExtremeRegionStat>();
        
        var index : Int;
        for index = 0; index < channels.count; index++ {
            var region = ExtremeRegionStat()
            
            region = erFilter1.run(channels[index] as UIImage);
            
            regions.append(region);
        }
        
        _groupedImage = ExtremeRegionStat.groupImage(uImage, withRegions: regions);
        
        _tesseract.recognize();
        
        /*
        @property (nonatomic, readonly) NSArray *getConfidenceByWord;
        @property (nonatomic, readonly) NSArray *getConfidenceBySymbol;
        @property (nonatomic, readonly) NSArray *getConfidenceByTextline;
        @property (nonatomic, readonly) NSArray *getConfidenceByParagraph;
        @property (nonatomic, readonly) NSArray *getConfidenceByBlock;
        */
        
        var words = _tesseract.getConfidenceByWord;
        var paragraphs = _tesseract.getConfidenceByTextline
        
        var texts = Array<String>();
        
        var windex: Int
        /*for windex = 0; windex < words.count; windex++ {
            let dict = words[windex] as Dictionary<String, AnyObject>
            let text = dict["text"]! as String
            //println(text)
            let confidence = dict["confidence"]! as Float
            let box = dict["boundingbox"] as NSValue
            if((text.utf16Count < 2 || confidence < 51) || (text.utf16Count < 4 && confidence < 60)){
                continue
            }
            
            let rect = box.CGRectValue()
            _characterBoxes.append(CharBox(text: text, rect: rect))
            texts.append(text)
        }*/
        
        
        
        windex = 0
        texts = Array<String>();
        for windex = 0; windex < paragraphs.count; windex++ {
            let dict = paragraphs[windex] as Dictionary<String, AnyObject>
            let text = dict["text"]! as String
            println("paragraphs of \(windex) is \(text)")
            liguistingTagger(text)
            let confidence = dict["confidence"]! as Float
            let box = dict["boundingbox"] as NSValue
            if((text.utf16Count < 2 || confidence < 51) || (text.utf16Count < 4 && confidence < 60)){
                continue
            }
            let rect = box.CGRectValue()
            _characterBoxes.append(CharBox(text: text, rect: rect))
            texts.append(text)
        }
        
        var str : String = ""
        
        for (idx, item) in enumerate(texts) {
            str += item
            if idx < texts.count-1 {
                str += " "
            }
        }
        
        _recognizedText = str
    }
    
    
    func liguistingTagger(input:String) -> Array<String> {
        let options: NSLinguisticTaggerOptions = .OmitWhitespace | .OmitPunctuation | .JoinNames 
        let schemes = NSLinguisticTagger.availableTagSchemesForLanguage("en")
        let tagger = NSLinguisticTagger(tagSchemes: schemes, options: Int(options.rawValue))
        tagger.string = input
        var results = Array<String>();
        tagger.enumerateTagsInRange(NSMakeRange(0, (input as NSString).length), scheme: NSLinguisticTagSchemeNameTypeOrLexicalClass, options: options) { (tag, tokenRange, sentenceRange, _) in
            let token = (input as NSString).substringWithRange(tokenRange)
            results.append(token)
        }
        println("liguistingTagger \(results)")
        return results;
    }
}