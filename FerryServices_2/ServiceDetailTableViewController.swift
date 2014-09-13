//
//  SCServiceDetailTableViewController.swift
//  FerryServices_2
//
//  Created by Stefan Church on 26/07/2014.
//  Copyright (c) 2014 Stefan Church. All rights reserved.
//

import UIKit
import MapKit
import QuickLook

class ServiceDetailTableViewController: UITableViewController, MKMapViewDelegate, QLPreviewControllerDataSource, QLPreviewItem {
    
    struct MainStoryBoard {
        struct TableViewCellIdentifiers {
            static let basicCell = "basicCell"
            static let mapCell = "mapCell"
            static let disruptionsCell = "disruptionsCell"
            static let noDisruptionsCell = "noDisruptionsCell"
            static let loadingCell = "loadingCell"
            static let errorCell = "errorLoadingCell"
        }
    }
    
    var disruptionDetails: DisruptionDetails?;
    var routeDetails: RouteDetails?;
    var serviceStatus: ServiceStatus!;
    var refreshing: Bool = false
    
    var isTimetableDataAvailable: Bool {
        if let routeId = self.serviceStatus.serviceId {
            return Trip.areTripsAvailableForRouteId(routeId)
        }
            
        return false
    }
    
    var previewItemURL: NSURL {
        return NSURL(fileURLWithPath: NSBundle.mainBundle().pathForResource("\(self.serviceStatus.serviceId!)", ofType: "pdf")!)
    }
    
    var previewItemTitle: String {
        return "Summer"
    }
    
    // MARK: - private vars
    private var locations: [Location]!
    
    // MARK: - view lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.title = self.serviceStatus.area
        
        self.tableView.rowHeight = UITableViewAutomaticDimension;
        self.tableView.estimatedRowHeight = 44.0;
        
        if let serviceId = self.serviceStatus.serviceId {
            self.locations = Location.fetchLocationsForSericeId(serviceId)
        }
        
        self.refresh(nil)
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        if let selectedIndexPath = self.tableView.indexPathForSelectedRow() {
            self.tableView.deselectRowAtIndexPath(selectedIndexPath, animated: true)
        }
    }
    
    // MARK: - refresh
    func refresh(sender: UIRefreshControl?) {
        if self.refreshing {
            return
        }
        
        self.refreshing = true
        self.tableView.reloadData()
        
        self.fetchLatestDisruptionDataWithCompletion {
            self.refreshing = false
            self.refreshControl?.endRefreshing()
            self.tableView.reloadData()
        }
    }
    
    private func fetchLatestDisruptionDataWithCompletion(completion: () -> ()) {
        if let serviceId = self.serviceStatus.serviceId {
            APIClient.sharedInstance.fetchDisruptionDetailsForFerryServiceId(serviceId) { disruptionDetails, routeDetails, error in
                if (error == nil) {
                    self.disruptionDetails = disruptionDetails
                    self.routeDetails = routeDetails
                }
                else {
                    self.disruptionDetails =  nil
                    self.routeDetails = nil
                }
                
                completion()
            }
        }
        else {
            completion()
        }
    }
    
    private func showPDFTimetable() {
        let previewViewController = QLPreviewController()
        previewViewController.dataSource = self
        self.navigationController?.pushViewController(previewViewController, animated: true)
    }

    // MARK: - tableview datasource
    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 3
    }
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch section {
        case 0:
            return self.isTimetableDataAvailable ? 2 : 1
        case 1:
            return 1
        case 2:
            return 1
        default:
            return 0
        }
    }
    
    override func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        switch section {
        case 0:
            return self.serviceStatus.area
        case 1:
            return "Map"
        case 2:
            return "Disruptions"
        default:
            return ""
        }
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        if indexPath.section == 0 {
            let cell = tableView.dequeueReusableCellWithIdentifier(MainStoryBoard.TableViewCellIdentifiers.basicCell) as UITableViewCell
            
            if self.isTimetableDataAvailable {
                if indexPath.row == 0 {
                    cell.textLabel?.text = "Departures"
                }
                else {
                    cell.textLabel?.text = "Summer timetable"
                }
            }
            else {
                cell.textLabel?.text = "Summer timetable"
            }
            
            return cell
        }
        else if indexPath.section == 1 {
            let cell = tableView.dequeueReusableCellWithIdentifier(MainStoryBoard.TableViewCellIdentifiers.mapCell) as ServiceDetailMapTableViewCell
            cell.mapView.delegate = self
            cell.configureCellForLocations(self.locations)
            return cell
        }
        else {
            if self.refreshing {
                return tableView.dequeueReusableCellWithIdentifier(MainStoryBoard.TableViewCellIdentifiers.loadingCell) as UITableViewCell
            }
            else if self.disruptionDetails == nil {
                return tableView.dequeueReusableCellWithIdentifier(MainStoryBoard.TableViewCellIdentifiers.errorCell) as UITableViewCell
            }
            else {
                if let disruptionStatus = self.disruptionDetails!.disruptionStatus {
                    switch disruptionStatus {
                    case .Normal, .Information:
                        return tableView.dequeueReusableCellWithIdentifier(MainStoryBoard.TableViewCellIdentifiers.noDisruptionsCell) as UITableViewCell
                    default:
                        let cell = tableView.dequeueReusableCellWithIdentifier(MainStoryBoard.TableViewCellIdentifiers.disruptionsCell) as ServiceDetailDisruptionsTableViewCell
                        cell.configureWithDisruptionDetails(self.disruptionDetails!)
                        return cell
                    }
                }
                else {
                    return tableView.dequeueReusableCellWithIdentifier(MainStoryBoard.TableViewCellIdentifiers.noDisruptionsCell) as UITableViewCell
                }
            }
        }
    }
    
    // MARK: - tableview controller delegate
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        if indexPath.section == 0 {
            if self.isTimetableDataAvailable {
                if indexPath.row == 0 {
                    if let routeId = self.serviceStatus.serviceId {
                        let timetableViewController = UIStoryboard(name: "Main", bundle: nil).instantiateViewControllerWithIdentifier("timetableViewController") as TimetableViewController
                        timetableViewController.routeId = routeId
                        self.navigationController?.pushViewController(timetableViewController, animated: true)
                    }
                }
                else {
                    self.showPDFTimetable()
                }
            }
            else {
                self.showPDFTimetable()
            }
        }
    }
    
    // MARK: - mapview delegate
    func mapView(mapView: MKMapView!, didSelectAnnotationView view: MKAnnotationView!) {
        mapView.deselectAnnotation(view.annotation, animated: false)
    }
    
    // MARK: - preview view controller datasource
    func numberOfPreviewItemsInPreviewController(controller: QLPreviewController!) -> Int {
        return 1
    }
    
    func previewController(controller: QLPreviewController!, previewItemAtIndex index: Int) -> QLPreviewItem! {
        return self
    }
}
