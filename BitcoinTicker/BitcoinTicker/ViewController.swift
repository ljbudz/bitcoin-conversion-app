//
//  ViewController.swift
//  BitcoinTicker
//

import UIKit
import SwiftyJSON
import Alamofire
import Charts

class ViewController: UIViewController, UIPickerViewDataSource, UIPickerViewDelegate  {
    
    let baseURL = "https://apiv2.bitcoinaverage.com/indices/global/ticker/BTC"
    let historicalURL = "https://min-api.cryptocompare.com/data/histohour?limit=24&fsym=BTC&tsym="
    let currencyArray = ["AUD", "BRL","CAD","CNY","EUR","GBP","HKD","IDR","ILS","INR","JPY","MXN","NOK","NZD","PLN","RON","RUB","SEK","SGD","USD","ZAR"]
    let currencySymbol = ["$", "R$", "$", "¥", "€", "£", "$", "Rp", "₪", "₹", "¥", "$", "kr", "$", "zł", "lei", "₽", "kr", "$", "$", "R"]
    var finalURL = ""
    var finalHistURL = ""
    var currencySelected = ""
    var time_stamp = ""
    
    let x_axis = ["", "Ask", "Bid", "Last", "High", "Low"]
    var y_axis : [Double] = []
    
    var time_axis : [String] = [""]
    var hist_axis : [Double] = []
    
    //Pre-setup IBOutlets
    @IBOutlet weak var bitcoinPriceLabel: UILabel!
    @IBOutlet weak var currencyPicker: UIPickerView!
    @IBOutlet weak var myChart: BarChartView!
    @IBOutlet weak var lineChart: LineChartView!
    
    var isBarChartShowing = false
    
    @IBAction func left(_ sender: UISwipeGestureRecognizer) {
        sender.direction = .left
        UIView.transition(from: myChart, to: lineChart, duration: 1.0, options: .showHideTransitionViews, completion: nil)
    }
    
    @IBAction func right(_ sender: UISwipeGestureRecognizer) {
        sender.direction = .right
        UIView.transition(from: lineChart, to: myChart, duration: 1.0, options: .showHideTransitionViews, completion: nil)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        currencyPicker.delegate = self
        currencyPicker.dataSource = self
        bitcoinPriceLabel.adjustsFontSizeToFitWidth = true
        
        currencySelected = currencySymbol[0]
        finalURL = baseURL + currencyArray[0]
        finalHistURL = historicalURL + currencyArray[0]
        
        lineChart.isHidden = true
        getBitcoinData(url: finalURL)
        getHistoricalData(url: finalHistURL)
        myChart.highlightPerDragEnabled = false
    }

    //TODO: Place your 3 UIPickerView delegate methods here
    
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return currencyArray.count
    }
    
    func pickerView(_ pickerView: UIPickerView, attributedTitleForRow row: Int, forComponent component: Int) -> NSAttributedString? {
        return NSAttributedString(string: currencyArray[row], attributes: [NSAttributedString.Key.foregroundColor : UIColor.white])
    }
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        currencySelected = currencySymbol[row]
        finalURL = baseURL + currencyArray[row]
        finalHistURL = historicalURL + currencyArray[row]
        getBitcoinData(url: finalURL)
        getHistoricalData(url: finalHistURL)
    }
    
//    
//    //MARK: - Networking
//    /***************************************************************/
//
    
    func getBitcoinData(url : String) {
        
        Alamofire.request(url, method: .get)
            .responseJSON { response in
                if response.result.isSuccess {
                    print("Success! Got Bitcoin data")
                    let bitcoinJSON : JSON = JSON(response.result.value!)
                    self.updateBitcoinData(json: bitcoinJSON)
                }
                
                else {
                    print("Error: \(String(describing: response.result.error))")
                    self.bitcoinPriceLabel.text = "Bad connection"
                    self.myChart.noDataText = "No data to display"
                }
        }
        
    }
    
    func getHistoricalData(url : String) {
        
        Alamofire.request(url, method: .get)
            .responseJSON { response in
                if response.result.isSuccess {
                    print("Success! Got historical data")
                    let historicalJSON : JSON = JSON(response.result.value!)
                    self.updateHistoricalData(json: historicalJSON)
                }
                    
                else {
                    print("Error: \(String(describing: response.result.error))")
                    self.lineChart.noDataText = "No data to display"
                }
        }
        
    }
    
//    //MARK: - JSON Parsing
//    /***************************************************************/
//
    
    func updateBitcoinData(json : JSON) {
        if let ask = json["ask"].double {
            bitcoinPriceLabel.text = currencySelected + String(ask)
 
            y_axis.removeAll()
            y_axis.append(ask)
            y_axis.append(json["bid"].double!)
            y_axis.append(json["last"].double!)
            y_axis.append(json["high"].double!)
            y_axis.append(json["low"].double!)

            time_stamp = json["display_timestamp"].string!
            
            updateBarChart()
        }
        
        else {
            bitcoinPriceLabel.text = "Data unavailable"
            myChart.noDataText = ""
        }
    }
    
    func updateHistoricalData(json : JSON) {
        if json["Response"].string == "Success" {
            hist_axis.removeAll()
            let data = json["Data"]
            for i in 0..<25 {
                hist_axis.append(data[i]["close"].double!)
                time_axis.append(getTime(data[i]["time"].double!))
            }
            
            updateLineChart()
        }
            
        else {
            lineChart.noDataText = "Data unavailable"
        }
    }
    
    func updateBarChart() {
        
        var dataEntries : [BarChartDataEntry] = []
        
        for i in 0..<x_axis.count-1 {
            let entry = BarChartDataEntry(x: Double(i+1), y: y_axis[i])
            dataEntries.append(entry)
        }
        
        let barChartDataSet = BarChartDataSet(entries: dataEntries, label: time_stamp)
        barChartDataSet.colors = ChartColorTemplates.material()
        barChartDataSet.valueTextColor = UIColor.white
        barChartDataSet.highlightEnabled = false
        myChart.doubleTapToZoomEnabled = false
        myChart.animate(xAxisDuration: 1.2, yAxisDuration: 1.2, easingOption: ChartEasingOption.easeOutQuint)

        myChart.xAxis.labelTextColor = UIColor.white
        myChart.xAxis.labelPosition = .bottom
        myChart.xAxis.drawGridLinesEnabled = false
        myChart.xAxis.valueFormatter = IndexAxisValueFormatter(values: x_axis)
        myChart.xAxis.granularityEnabled = true
        myChart.xAxis.granularity = 1

        myChart.leftAxis.labelTextColor = UIColor.white
        myChart.leftAxis.drawGridLinesEnabled = false
        myChart.leftAxis.drawAxisLineEnabled = false
        
        let diff = y_axis.max()! - y_axis.min()!
        let i = powf(10, Float(get_size(diff) - 1))

        myChart.leftAxis.axisMaximum = y_axis.max()! + Double(i)
        myChart.leftAxis.axisMinimum = y_axis.min()! - Double(i)
        
        myChart.rightAxis.labelTextColor = UIColor.white
        myChart.rightAxis.drawGridLinesEnabled = false
        myChart.rightAxis.drawAxisLineEnabled = false
        myChart.rightAxis.axisMaximum = myChart.leftAxis.axisMaximum
        myChart.rightAxis.axisMinimum = myChart.leftAxis.axisMinimum

        myChart.legend.textColor = UIColor.white
        
        let chartData = BarChartData(dataSet: barChartDataSet)
        myChart.data = chartData
    }
    
    func updateLineChart(){
        
        var dataEntries : [ChartDataEntry] = []
        
        for i in 0..<hist_axis.count {
            let entry = ChartDataEntry(x: Double(i+1), y: hist_axis[i])
            dataEntries.append(entry)
        }
        
        let lineChartDataSet = LineChartDataSet(entries: dataEntries, label: "24 Hour Close")
        lineChartDataSet.colors = [NSUIColor.init(red: 242/255, green: 156/255, blue: 18/255, alpha: 1.0)]
        lineChartDataSet.valueTextColor = UIColor.white
        lineChartDataSet.setDrawHighlightIndicators(false)
        lineChartDataSet.drawFilledEnabled = true
        lineChartDataSet.mode = .cubicBezier
        lineChartDataSet.circleRadius = 3.0
        lineChartDataSet.drawCircleHoleEnabled = false
        lineChart.animate(xAxisDuration: 1.2, yAxisDuration: 1.2, easingOption: ChartEasingOption.easeOutQuint)
        
        let colorTop =  UIColor(red: 242/255, green: 156/255, blue: 18/255, alpha: 1.0).cgColor
        let colorBottom = UIColor(red: 1.0, green: 1.0, blue: 1.0, alpha: 1.0).cgColor
        let gradientColors = [colorTop, colorBottom] as CFArray
        let colorLocations:[CGFloat] = [0.0, 1.0]
        let gradient = CGGradient.init(colorsSpace: CGColorSpaceCreateDeviceRGB(), colors: gradientColors, locations: colorLocations) // Gradient Object
        lineChartDataSet.fill = Fill.fillWithLinearGradient(gradient!, angle: 90.0)
        
        lineChart.doubleTapToZoomEnabled = false
        lineChart.pinchZoomEnabled = true
        
        lineChart.xAxis.labelTextColor = UIColor.white
        lineChart.xAxis.labelPosition = .bottom
        lineChart.xAxis.valueFormatter = IndexAxisValueFormatter(values: time_axis)
        lineChart.xAxis.granularityEnabled = true
        lineChart.xAxis.granularity = 1
        lineChart.xAxis.drawGridLinesEnabled = false
        lineChart.xAxis.drawAxisLineEnabled = false
        
        lineChart.leftAxis.labelTextColor = UIColor.white
        myChart.leftAxis.drawAxisLineEnabled = false
        
        let diff = hist_axis.max()! - hist_axis.min()!
        let i = powf(10, Float(get_size(diff) - 1))
        
        lineChart.leftAxis.axisMaximum = hist_axis.max()! + Double(i)
        lineChart.leftAxis.axisMinimum = hist_axis.min()! - Double(i)
        lineChart.leftAxis.gridColor = UIColor.init(white: 1.0, alpha: 0.2)
        lineChart.leftAxis.drawAxisLineEnabled = false
        
        lineChart.rightAxis.labelTextColor = UIColor.white
        lineChart.rightAxis.drawAxisLineEnabled = false
        lineChart.rightAxis.axisMaximum = lineChart.leftAxis.axisMaximum
        lineChart.rightAxis.axisMinimum = lineChart.leftAxis.axisMinimum
        lineChart.rightAxis.gridColor = UIColor.init(white: 1.0, alpha: 0.2)
        lineChart.rightAxis.drawAxisLineEnabled = false
        
        lineChart.legend.textColor = UIColor.white
        
        let lineChartData = LineChartData(dataSet: lineChartDataSet)
        lineChart.data = lineChartData
    }
    
    func get_size(_ num : Double) -> Int {
        
        var count = 0
        var temp = Int(num)
        
        while temp != 0 {
            temp /= 10
            count += 1
        }
        
        return count
    }
    
    func getTime(_ unixDate : Double) -> String {
        let date = Date(timeIntervalSince1970 : unixDate)
        let dateFormatter = DateFormatter()
        dateFormatter.timeZone = TimeZone(abbreviation: "EST")
        dateFormatter.locale = NSLocale.current
        dateFormatter.dateFormat = "HH:mm"
        return dateFormatter.string(from: date)
    }
}

