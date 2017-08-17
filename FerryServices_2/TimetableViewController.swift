//
//  TimetableViewController.swift
//  FerryServices_2
//
//  Created by Stefan Church on 30/08/14.
//  Copyright (c) 2014 Stefan Church. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa
import RxDataSources

class TimetableViewController: UIViewController {
    
    private static let dateFormatter: DateFormatter = {
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .full
        return dateFormatter
    }()
    
    @IBOutlet weak var tableView: UITableView!
    
    private var disposeBag = DisposeBag()
    private var expanded = Variable(false)
    private var date = Variable(Date())
    private var dataSource = RxTableViewSectionedReloadDataSource<Section>()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = "Depatures"
        
        tableView.estimatedRowHeight = 44
        tableView.rowHeight = UITableViewAutomaticDimension
        
        dataSource.configureCell = configureCell
        
        let departures = date.asObservable().map { date -> (values: [[Departure]], date: (Date)) in
            let ardrossanToBrodick = Departures().fetchDepartures(date: date, from: "9300ARD", to: "9300BRB")
            let brodickToArdrossan = Departures().fetchDepartures(date: date, from: "9300BRB", to: "9300ARD")
            
            return (values: [ardrossanToBrodick, brodickToArdrossan], date: date)
        }
        
        let sectionData: Observable<[Section]> = Observable.combineLatest(expanded.asObservable(), departures) {
            (expanded, departureGroups) in
            let dateSelectorSection = Section.SectionType.dateSelector(date: departureGroups.date, expanded: expanded)
            
            let departureSections = departureGroups.values.map { (departures: [Departure]) -> Section in
                let sectionType = Section.SectionType.departures(departures: departures, date: departureGroups.date)
                return Section(sectionType: sectionType)
            }
            
            return [Section(sectionType: dateSelectorSection)] + departureSections
        }
        
        sectionData
            .bind(to: tableView.rx.items(dataSource: dataSource))
            .disposed(by: disposeBag)
        
        tableView.rx.itemSelected.subscribe(onNext: { [unowned self] indexPath in
            let item = self.dataSource[indexPath]
            if case .date = item {
                self.expanded.value =  !self.expanded.value
            }
        }).addDisposableTo(disposeBag)
    }
    
    private func configureCell(dataSource: TableViewSectionedDataSource<Section>, tableView: UITableView, indexPath: IndexPath, item: Section.Row) -> UITableViewCell {
        
        switch item {
        case let .header(from, to):
            let cell = tableView.dequeueReusableCell(withIdentifier: "headerCell", for: indexPath) as! TimetableHeaderViewCell
            cell.imageViewTransportType.image = #imageLiteral(resourceName: "ferry_icon")
            cell.labelHeader.text = "\(from) to \(to)"
            
            return cell
            
        case let .time(depatureTime, arrivalTime):
            let cell = tableView.dequeueReusableCell(withIdentifier: "timeCell", for: indexPath) as! TimetableTimeTableViewCell
            cell.labelTime.text = depatureTime
            cell.labelTimeCounterpart.text = "arriving at \(arrivalTime)"
            
            return cell
        case let .date(date):
            let cell = tableView.dequeueReusableCell(withIdentifier: "dateCell", for: indexPath) as! TimetableDateTableViewCell
            cell.labelDeparturesArrivals.text = "Departures"
            cell.labelSelectedDate.text = TimetableViewController.dateFormatter.string(from: date)
            
            return cell
            
        case let .datePicker(date):
            let cell = tableView.dequeueReusableCell(withIdentifier: "datePickerCell", for: indexPath) as! TimeTableDatePickerCell
            cell.datePicker.date = date
            
            cell.datePicker.rx.controlEvent(.valueChanged).subscribe(onNext: { _ in
                self.date.value = cell.datePicker.date
            })
            .disposed(by: cell.disposeBag)
            
            return cell
            
        }
    }
    
}

fileprivate struct Section: SectionModelType {
    
    enum Row {
        case date(date: Date)
        case datePicker(date: Date)
        case header(from: String, to: String)
        case time(departureTime: String, arrivalTime: String)
    }
    
    enum SectionType {
        case dateSelector(date: Date, expanded: Bool)
        case departures(departures: [Departure], date: Date)
        
        func rows() -> [Row] {
            switch self {
            case let .dateSelector(date, expanded):
                return expanded ? [Row.date(date: date), Row.datePicker(date: date)] : [Row.date(date: date)]
            case let .departures(departures, date):
                let from = departures.first?.from ?? ""
                let to = departures.first?.to ?? ""
                
                let header = Row.header(from: from, to: to)
                let times = departures.map {
                    Row.time(departureTime: $0.departureTime, arrivalTime: $0.arrivalTime(withDate: date))
                }
                
                return [header] + times
            }
        }
    }
    
    private(set) var items: [Row]
    
    init(sectionType: SectionType) {
        items = sectionType.rows()
    }
    
    init(original: Section, items: [Row]) {
        self = original
        self.items = items
    }
    
}
