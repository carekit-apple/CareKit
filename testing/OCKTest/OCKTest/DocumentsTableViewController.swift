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


import CareKit


class DocumentsTableViewController: UITableViewController {
    
    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 12
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {

        if let cell = tableView.dequeueReusableCellWithIdentifier("cell") {
            switch indexPath.row {
            case 0:
                cell.textLabel?.text = "HTML - Bar Charts"
            case 1:
                cell.textLabel?.text = "HTML - Tables"
            case 2:
                cell.textLabel?.text = "HTML - Subtitles"
            case 3:
                cell.textLabel?.text = "HTML - Images"
            case 4:
                cell.textLabel?.text = "HTML - Paragraphs"
            case 5:
                cell.textLabel?.text = "HTML - All"
            case 6:
                cell.textLabel?.text = "PDF - Bar Charts"
            case 7:
                cell.textLabel?.text = "PDF - Tables"
            case 8:
                cell.textLabel?.text = "PDF - Subtitles"
            case 9:
                cell.textLabel?.text = "PDF - Images"
            case 10:
                cell.textLabel?.text = "PDF - Paragraphs"
            case 11:
                cell.textLabel?.text = "PDF - All"
            default:
                cell.textLabel?.text = nil
            }
            return cell
        } else {
            return UITableViewCell.init()
        }
    }
    
    func getDocumentCharts() -> [OCKDocumentElement] {
        
        let bar1 = OCKBarSeries.init(title: "Title 1", values: [6,5], valueLabels: ["6","5"], tintColor: UIColor.brownColor())
        let bar2 = OCKBarSeries.init(title: "Title 2", values: [5,10], valueLabels: ["5","10"], tintColor: UIColor.blackColor())
        let bar3 = OCKBarSeries.init(title: "Title 3", values: [4,10], valueLabels: ["4","10"], tintColor: UIColor.blueColor())
        let bar4 = OCKBarSeries.init(title: "Title 4", values: [15,4], valueLabels: ["15","4"], tintColor: UIColor.grayColor())
        let bar5 = OCKBarSeries.init(title: "Title 7", values: [-20,-8], valueLabels: ["-20","-8"], tintColor: UIColor.cyanColor())
        
        let chart1 = OCKBarChart.init(title: "Chart #1", text: "Chart #1 Description", tintColor: UIColor.grayColor(), axisTitles: ["Axis #1","Axis #2"], axisSubtitles: ["Subtitle #1","Subtitle #2"], dataSeries: [bar1, bar2, bar3, bar4, bar5])
        
        let series1 = OCKBarSeries.init(title: "Series #1", values: [20,24,60,40,50,60], valueLabels: ["20","24","60","40","50","60"], tintColor: UIColor.darkGrayColor())
        let series2 = OCKBarSeries.init(title: "Series #2", values: [25,15,35,16,60,20], valueLabels: ["25","15","35","16","60","20"], tintColor: UIColor.orangeColor())
        let chart2 = OCKBarChart.init(title: "Chart #2", text: "Chart #2 Description", tintColor: UIColor.grayColor(), axisTitles: ["ABC","DEF","GHI","JKL","MNO"], axisSubtitles: ["123","456","789","012"],dataSeries: [series1, series2])
        return [OCKDocumentElementChart.init(chart: chart1),OCKDocumentElementChart.init(chart: chart2)]
        
    }
    
    func getDocumentTables() -> [OCKDocumentElement] {
        
        let table1 = OCKDocumentElementTable.init(headers: ["A","B","C","D"], rows: [["1","10","100","1000"],["2","20","200"],["-3/3"],["4","40","400"]])
        let table2 = OCKDocumentElementTable.init(headers: ["Monday 8th","Tuesday 9th","Wednesday 10th","Thursday 11th","Friday 12th", "Saturday 13th", "Sunday 14th"], rows: [["A","A","A","A","A","A","A"],["B00 B00","B","B","B","B","B","B"],["C","C","C","C","C","C","C"],["D","D","D","D","D"],["E","E","E","E","E","E","E","E","E"],["A","A","A","A","A","ABCDEFGHIJKLMNOPQRSTUVWXYZ","A"],["B","This cell has a lot of data. It might take up more height than any of the other rows","B","B","B","B","B"],["C","C","C","C","C","C","C"],["D","D","D","D","D"],["E","E","E","E","E","E","E","E","E"]])
        let table3 = OCKDocumentElementTable.init(headers: nil, rows: nil)
        let table4 = OCKDocumentElementTable.init(headers: [], rows: [[],[],[]])
        let table5 = OCKDocumentElementTable.init(headers: nil, rows: [["This is a table with no headers","It really has no Header row"]])
        let table6 = OCKDocumentElementTable.init(headers: ["No Rows Here","No Cells Either"], rows: nil)
        let table7 = OCKDocumentElementTable.init(headers: ["One\n Column"], rows: [["Hello"],["World"],["Only"],["One"],["Column"]])
        return [table1, table2, table3, table4, table5, table6, table7]
        
    }
    
    func getDocumentSubtitles() -> [OCKDocumentElement] {
        
        let subtitle1 = OCKDocumentElementSubtitle.init(subtitle: "This is a subtitle that should get included in the HTML/PDF Files")
        let subtitle2 = OCKDocumentElementSubtitle.init(subtitle: "I am another subtitle")
        let subtitle3 = OCKDocumentElementSubtitle.init(subtitle: LoremIpsum)
        return [subtitle1, subtitle2, subtitle3]
        
    }
    
    func getDocumentParagraphs() -> [OCKDocumentElement] {
        
        let para1 = OCKDocumentElementParagraph.init()
        para1.content = "This is a paragraph with only one sentence"
        let para2 = OCKDocumentElementParagraph.init(content: LoremIpsum)
        let para3 = OCKDocumentElementParagraph.init()
        let para4 = OCKDocumentElementParagraph.init(content: LoremIpsum)
        return [para1, para2, para3, para4]
        
    }
    
    func getDocumentImages() -> [OCKDocumentElement] {
        
        let image1 = OCKDocumentElementImage.init()
        image1.image = UIImage.init()
        let image2 = OCKDocumentElementImage.init(image: UIImage.init(named: "SquareCircle")!)
        let image3 = OCKDocumentElementImage.init(image: UIImage.init(named: "Triangles.jpg")!)
        let image4 = OCKDocumentElementImage.init(image: UIImage.init(named: "Stars.png")!)
        let image5 = OCKDocumentElementImage.init(image: UIImage.init(named: "Stars")!)
        image5.image = nil
        return [image1, image2, image3, image4, image5]
        
    }
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        
        let document = OCKDocument.init(title: "Here is a Title for the Document. \n This is a new line", elements: nil)
        document.pageHeader = "This Page Header should appear on the top of every single page"
        
        if indexPath.row % 6 == 0 { // Rows 0 and 6
            document.elements = getDocumentCharts()
        } else if indexPath.row % 6 == 1 { // Rows 1 and 7
            document.elements = getDocumentTables()
        } else if indexPath.row % 6 == 2 { // Rows 2 and 8
            document.elements = getDocumentSubtitles()
        } else if indexPath.row % 6 == 3 { // Rows 3 and 9
            document.elements = getDocumentImages()
        } else if indexPath.row % 6 == 4 { // Rows 4 and 10
            document.elements = getDocumentParagraphs()
        } else if indexPath.row % 6 == 5 { // Rows 5 and 11
            let chartsAndTables = getDocumentCharts() + getDocumentTables()
            let paragraphsAndImages = getDocumentParagraphs() + getDocumentImages()
            let subtitles = getDocumentSubtitles()
            document.elements = chartsAndTables + paragraphsAndImages + subtitles
        }
        
        let webViewController = UIViewController.init()
        webViewController.view.backgroundColor = UIColor.whiteColor()
        let webView = UIWebView.init()
        webView.translatesAutoresizingMaskIntoConstraints = false
        webViewController.view.addSubview(webView)
        webView.topAnchor.constraintEqualToAnchor(webViewController.view.topAnchor, constant: 30).active = true
        webView.bottomAnchor.constraintEqualToAnchor(webViewController.view.bottomAnchor).active = true
        webView.leftAnchor.constraintEqualToAnchor(webViewController.view.leftAnchor).active = true
        webView.rightAnchor.constraintEqualToAnchor(webViewController.view.rightAnchor).active = true
        
        if indexPath.row >= 6 {
            // PDFs
            document.createPDFDataWithCompletion { (data, error) in
                dispatch_async(dispatch_get_main_queue(),{
                    webView.loadData(data, MIMEType: "application/pdf", textEncodingName: "", baseURL: NSURL())
                    self.navigationController?.pushViewController(webViewController, animated: true)
                })
            }
        } else {
            // HTMLs
            webView.loadHTMLString(document.HTMLContent, baseURL: nil)
            self.navigationController?.pushViewController(webViewController, animated: true)
        }

    }
}
