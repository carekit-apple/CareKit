/*
 Copyright (c) 2016, Apple Inc. All rights reserved.
 
 Redistribution and use in source and binary forms, with or without modification,
 are permitted provided that the following conditions are met:
 
 1.  Redistributions of source code must retain the above copyright notice, this
 list of conditions and the following disclaimer.
 
 2.  Redistributions in binary form must reproduce the above copyright notice,
 this list of conditions and the following disclaimer in the documentation and/or
 other materials provided with the distribution.
 
 3.  Neither the name of the copyright holder(s) nor the names of any contributors
 may be used to endorse or promote products derived from this software without
 specific prior written permission. No license is granted to the trademarks of
 the copyright holders even if such marks are included in this software.
 
 THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
 AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
 IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
 ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE
 FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
 DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
 SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
 CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
 OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
 OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */


#import "OCKDocument.h"
#import "OCKChart_Internal.h"
#import "OCKHTMLPDFWriter.h"


@implementation OCKDocument {
    OCKHTMLPDFWriter *_writer;
}

- (instancetype)initWithTitle:(NSString *)title elements:(NSArray<id<OCKDocumentElement>> *)elements {
    self = [super init];
    if (self) {
        _elements = [elements copy];
        _title = [title copy];
    }
    return self;
}

- (NSString *)htmlContent {
    NSString *html = @"<!doctype html>\n";
    
    NSString *css = @"body {\n"
    "font-family: -apple-system, Helvetica, Arial;\n"
    "}\n";
    if (css.length > 0) {
        css = [NSString stringWithFormat:@"<style>\n"
               "%@\n"
               "</style>\n", css];
    }
    
    
    html = [html stringByAppendingFormat:@"<html>\n"
            "<head>\n"
            "<title>%@</title>\n"
            "<meta charset=\"utf-8\">\n"
            "%@"
            "</head>\n"
            "<body>\n", _title.length > 0 ? _title : @"html", css]; // To pass w3c html validation
    
    if (_title) {
        html = [html stringByAppendingString:[NSString stringWithFormat:@"<h2>%@</h2>\n", _title]];
    }
    
    for (id<OCKDocumentElement> element in _elements) {
        html = [html stringByAppendingString:[element HTMLContent]];
        html = [html stringByAppendingString:@"\n"];
    }
    
    html = [html stringByAppendingString:@"</body>\n</html>\n"];
    
    return html;
}

- (void)createPDFWithCompletion:(void (^)(NSData *data, NSError *error))completion {
    if (_writer == nil) {
        _writer = [[OCKHTMLPDFWriter alloc] init];
    }
    [_writer writePDFFromHTML:self.htmlContent header:_pageHeader withCompletionBlock:^(NSData *data, NSError *error) {
        completion(data, error);
    }];
}

@end


@implementation OCKDocumentElementSubtitle 

- (instancetype)initWithSubtitle:(NSString *)subtitle {
    self = [super init];
    if (self) {
        _subtitle = subtitle;
    }
    return self;
}

- (NSString *)HTMLContent {
    NSString *html = @"";
    
    if (_subtitle) {
        html = [html stringByAppendingString:[NSString stringWithFormat:@"<h3>%@</h3>", _subtitle]];
    }
    
    return html;
}

@end


@implementation OCKDocumentElementParagraph

- (instancetype)initWithContent:(NSString *)content {
    self = [super init];
    if (self) {
        _content = content;
    }
    return self;
}

- (NSString *)HTMLContent {
    NSString *html = @"";
    if (_content) {
        html = [html stringByAppendingString:[NSString stringWithFormat:@"<p>%@</p>", _content]];
    }
    return html;
}

@end


static NSString *imageTagFromImage (UIImage *image) {
    NSData *imageData = UIImagePNGRepresentation(image);
    NSString *format = @"<img style='vertical-align: middle;' alt=\"\" height='%@' width='%@' src='data:image/png;base64,%@' />\n";
    NSString *base64String = [imageData base64EncodedStringWithOptions:0];
    NSString *imageTag = [NSString stringWithFormat:format, @(image.size.height), @(image.size.width), base64String];
    return imageTag;
}

static NSString *imageTagFromView (UIView *view) {
    UIGraphicsBeginImageContextWithOptions(view.frame.size, YES, 2.0);
    [view.layer renderInContext:UIGraphicsGetCurrentContext()];
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return imageTagFromImage(image);
}


@implementation OCKDocumentElementChart

- (instancetype)initWithChart:(OCKChart *)chart {
    self = [super init];
    if (self) {
        _chart = chart;
    }
    return self;
}

- (NSString *)HTMLContent {
    NSString *html = @"";
    if (_chart) {
        
        html = [html stringByAppendingString:@"<p>"];
        
        if (_chart.title) {
            html = [html stringByAppendingFormat:@"<b>%@</b><br/>\n", _chart.title];
        }
        
    
        UIView *view = [_chart chartView];
        
        if (view) {
            // This triggers autolayout.
            UITableViewCell *cell = [[UITableViewCell alloc] init];
            [cell.contentView addSubview:view];
            cell.frame = CGRectMake(0, 0, 480, 320);
        }
        
        view.frame = CGRectMake(0, 0, 480, 320);
        view.backgroundColor = [UIColor whiteColor];
        
        html = [html stringByAppendingString:imageTagFromView(view)];
    
        
        if (_chart.text) {
            html = [html stringByAppendingFormat:@"<i>%@</i>\n", _chart.text];
        }
        
        html = [html stringByAppendingString:@"</p>"];
        
    }
    return html;
}

@end

 
@implementation OCKDocumentElementImage

- (instancetype)initWithImage:(UIImage *)image {
    self = [super init];
    if (self) {
        _image = image;
    }
    return self;
}

- (NSString *)HTMLContent {
    NSString *html = @"";
    if (_image) {
        
        html = [html stringByAppendingString:@"<p>"];
        html = [html stringByAppendingString:imageTagFromImage(_image)];
        html = [html stringByAppendingString:@"</p>"];
    }
    return html;
}

@end

