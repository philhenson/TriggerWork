//
//  RecordSessionViewController.swift
//  TriggerWork
//
//  Created by Phil Henson on 4/10/16.
//  Copyright © 2016 Lost Nation R&D. All rights reserved.
//

import UIKit
import CorePlot

class RecordSessionViewController: UIViewController {
  
  // Data
  var data = [[String : String]]()
  var currentIndex = 0
  var resetPlot = false
  
  // Core Plot
  var graph : CPTGraph?
  var plot : CPTPlot?
  
  // Firebase
  let firManager = FIRDataManager()
  
  // IBOutlets
  @IBOutlet weak var graphView: CPTGraphHostingView!
  @IBOutlet weak var infoView: UIView!
  @IBOutlet weak var startStopButton: StartStopButton!
  
  // MARK: - Lifecycle
  override func viewDidLoad() {
    super.viewDidLoad()
    // Unsure if this is needed
    //startStopButton = StartStopButton()
  }
  
  // MARK: - IBActions
  @IBAction func startStopButtonPressed(sender: AnyObject) {
    if !startStopButton.selected {
      // Clear plot and prepare to save data
      self.clearPlot()
      
    } else {
      // Save data and clear plot
      self.saveDataAndClearPlot()
    }
    
    startStopButton.selected = !startStopButton.selected
  }
  
  // MARK: - UI Settings
  override func preferredStatusBarStyle() -> UIStatusBarStyle {
    return .LightContent
  }
}

// MARK: - BTService Delegate
extension RecordSessionViewController: BTServiceDelegate {
  override func viewWillAppear(animated: Bool) {
    super.viewWillAppear(animated)
    setupGraphView()
    infoView.hidden = false
    
    // Set the delegate so the view can respond to changes broadcasted values
    if let service = btDiscoverySharedInstance.bleService {
      service.delegate = self
    }
  }
  
  func didUpdateTriggerValue(value: String) {
    // Append new values to data array for plotting
    
    dispatch_async(dispatch_get_main_queue(), {
      self.infoView.hidden = true
      self.updatePlot(value)
    })
    
    
    // The following was used for only plotting values greater than 0
    // Right now we want continuous plotting regarless of magnitude
    // Might return to this in the future
    
    /*
        resetPlot = Int(value) <= 1
        if Int(value) > 0 {
          dispatch_async(dispatch_get_main_queue(), {
            self.infoView.hidden = true
            self.updatePlot(value)
          })
        }
     */
  }
}

// MARK: - Core Plot Data Source
extension RecordSessionViewController: CPTPlotDataSource {
  func setupGraphView() {
    
    // Styles
    let dataLineStyle = CPTMutableLineStyle()
    dataLineStyle.lineWidth = 3.0
    dataLineStyle.lineColor = CPTColor(CGColor: Colors.defaultGreenColor().CGColor)
    
    // Plotting Space
    let graph = CPTXYGraph(frame: CGRectZero)
    
    let axisSet = graph.axisSet as! CPTXYAxisSet
    axisSet.xAxis?.axisLineStyle = nil
    axisSet.xAxis?.hidden = true
    axisSet.yAxis?.axisLineStyle = nil
    axisSet.yAxis?.hidden = true
    
    let plot = CPTScatterPlot()
    plot.identifier = Constants.CorePlotIdentifier
    plot.dataSource = self
    plot.interpolation = .Curved
    plot.dataLineStyle = dataLineStyle
    
    let plotSpace = graph.defaultPlotSpace as! CPTXYPlotSpace
    plotSpace.xRange = CPTPlotRange(location: 0, length: Constants.MaxDataPoints - 2)
    plotSpace.yRange = CPTPlotRange(location: -5, length: Constants.MaxYValue)
    
    graph.addPlot(plot)
    graphView.hostedGraph = graph
    
    self.plot = plot
    self.graph = graph
  }
  
  // Helpers
  func clearPlot() {
    if let _ = plot {
      // Remove data from array and clear plot space
      plot!.deleteDataInIndexRange(NSMakeRange(0, data.count))
      data.removeAll()
      currentIndex = 0
    }
  }
  
  func saveDataAndClearPlot() {
    firManager.saveSessionWithShotData(data)
    self.clearPlot()
  }
  
  func updatePlot(newValue: String) {
    
    // Optional reset when data is < 1. Currently unused
    //    if resetPlot {
    //      plot.deleteDataInIndexRange(NSMakeRange(0, data.count))
    //      data.removeAll()
    //      currentIndex = 0
    //    }
    
    // If both graph and plot exist, plot points
    if let _ = graph, _ = plot {
      
      let plotSpace = graph!.defaultPlotSpace as! CPTXYPlotSpace
      let location = currentIndex >= Constants.MaxDataPoints ? currentIndex - Constants.MaxDataPoints + 2 : 0
      let newRange = CPTPlotRange(location: location,
                                  length: Constants.MaxDataPoints - 2)
      
      CPTAnimation.animate(plotSpace,
                           property: "xRange",
                           fromPlotRange: plotSpace.xRange,
                           toPlotRange: newRange,
                           duration: 0.1)
      
      currentIndex += 1
      data.append(["location" : "\(data.count)",
                   "value" : newValue])
      plot!.insertDataAtIndex(UInt(data.count - 1), numberOfRecords: 1)
      print("location: \(location)")
      print("xRange length: \(plotSpace.xRange.length)")
      print("data count: \(data.count)")
      print("")
    }
  }

  func numberOfRecordsForPlot(plot: CPTPlot) -> UInt {
    return UInt(data.count)
  }
  
  func numberForPlot(plot: CPTPlot, field fieldEnum: UInt, recordIndex idx: UInt) -> AnyObject? {
    var dataPoint: Double = 0.0
    
    switch (fieldEnum) {
    case 0:
      dataPoint = Double(Int(idx) + currentIndex - data.count)
      print("dataX: \(dataPoint)")
      break;
    case 1:
      if let stringValue = data[Int(idx)]["value"] {
        if let value = Double(stringValue) {
          dataPoint = value
          print("dataY: \(dataPoint)")
        }
      }
      break;
    default:
      break;
    }
    return dataPoint
  
  }
}

// MARK: - Scatter Plot Data Source
extension RecordSessionViewController: CPTScatterPlotDataSource {
  func symbolForScatterPlot(plot: CPTScatterPlot, recordIndex idx: UInt) -> CPTPlotSymbol? {
    return nil
  }
}