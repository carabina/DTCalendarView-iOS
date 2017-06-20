//
//  DTCalendarView.swift
//  Pods
//
//  Created by Tim Lemaster on 6/14/17.
//
//

import UIKit

/// An object that adopts the DTCalendarViewDelegate protocol is responsible for providing the data required by the DTCalendarView class and
/// responding to actions produced by interaction with the DTCalendarView by the user
public protocol DTCalendarViewDelegate: class {
    
    /**
     Asks your delegate for a view to use to display the month/year above the weeks of a month
     
     - parameter calendarView: The calendar view requesting the view
     
     - parameter month: A date representing the month/year the view should represent, othe Date data should be ignored - like the particular day
     
     - returns: A view representing the month/year to be displayed above the calendar. It will be sized to fill the available space
     
    */
    func calendarView(_ calendarView: DTCalendarView, viewForMonth month: Date) -> UIView
    
    /**
     Notifies your delegate that a user dragged a selected date to another day on the calendar. The date could be the selected start day or end day,
     this can be determined by testing against those properties on teh calendar view returned. It is entirely up to your delegate to determine if this
     drag should select that day on the calendar - and if that is the new selection start or end date.
     
     - parameter calendarView: The calendar view notifying the delegate
     
     - parameter fromDate: A date representing the day/month/year the user dragged from, other Date data should be ignored - like hours/minutes/seconds
     
     - parameter toDate: A date representing the day/month/year the user dragged to,  other Date data should be ignored - like hours/minutes/seconds
     
     */
    func calendarView(_ calendarView: DTCalendarView, dragFromDate fromDate: Date, toDate: Date)
    
    /**
     Notifies your delegate that a user taps on a particular day on a calendar. It is entirely up to your delegate to determine if this tap should
     select that day on the calendar as a new selection start date or selection end date.
     
     - parameter calendarView: The calendar view notifying the delegate
     
     - parameter date: A date representing the day/month/year the user taps, othe Date data should be ignored - like hours/minutes/seconds
     
    */
    func calendarView(_ calendarView: DTCalendarView, didSelectDate date: Date)
    
    
    /**
     Asks your delegate for the height used to display the view representing the month/year above the weeks of a month
     
     - parameter calendarView: The calendar view requesting the view
     
     - parameter month: A date representing the month/year the height should be for, othe Date data should be ignored - like the particular day
     
     - returns the height used the diplay the view
     
    */
    func calendarView(_ calendarView: DTCalendarView, heightOfViewForMonth month: Date) -> CGFloat
    
    /**
     Asks your delegate for the height used to display the view containing the weekday labels
     
     - parameter calendarView: The calendar view requesting the view
     
     - returns the height used the diplay the view
     
     */
    func calendarViewHeightOfWeekRows(_ calendarView: DTCalendarView) -> CGFloat
    
    /**
     Asks your delegate for the height used to display the view containing the weeks of the month
     
     - parameter calendarView: The calendar view requesting the view
     
     - returns the height used the diplay the view
     
     */
    func calendarViewHeightOfWeekdayLabelRow(_ calendarView: DTCalendarView) -> CGFloat
}


/// A structure for holding the various stylable attributes for various calendar states
public struct DisplayAttributes {
    
    /// The font used to render the day or weekday label
    let font: UIFont
    
    /// The text color used to render the day or weekday label
    let textColor: UIColor
    
    /// The background color used to render the background of the day or weekday label, or the selected/highlighed indicator background
    let backgroundColor: UIColor
    
    /// The how to align the text - usually .center
    let textAlignment: NSTextAlignment
}

/// The day state of a particular day on the calendar
public enum DayState {
    
    /// The default
    case normal
    
    /// Selected as the start or end date
    case selected
    
    /// In between the current start and end dates
    case highlighted
    
    /// A day from a previous or next month displayed in the current month view
    case preview
}

struct WeekDisplayAttributes {
    let normalDisplayAttributes: DisplayAttributes
    let selectedDisplayAttributes: DisplayAttributes
    let highlightedDisplayAttributes: DisplayAttributes
    let previewDisplayAttributes: DisplayAttributes
}

private enum PanMode {
    case none
    case start
    case end
}


/// A class for displaying a vertical scrolling calendar view. Supports selecting a range of dates and dragging those days around
public class DTCalendarView: UIControl {
    
    /// The month/year the calendar should start at - defaults to current month/year. Other Date attributes are ignored (day, hour, etc)
    public var displayStartDate: Date {
        get {
            return self._startDate
        }
        set {
            let calendar = Calendar.current
            var components = calendar.dateComponents([.year, .month, .day], from: newValue)
            components.setValue(1, for: .day)
            if let firstDayOfMonth = calendar.date(from: components) {
                _startDate = firstDayOfMonth
            }
        }
    }

    /// The month/year the calendar should end at - defaults to current month/year. Other Date attributes are ignored (day, hour, etc)
    public var displayEndDate: Date {
        get {
            return self._endDate
        }
        set {
            let calendar = Calendar.current
            var components = calendar.dateComponents([.year, .month, .day], from: newValue)
            components.setValue(1, for: .day)
            if let firstDayOfMonth = calendar.date(from: components) {
                _endDate = firstDayOfMonth
            }
        }
    }

    /// The day/month/year the calendar range selection starts at - also could be used for single selection - defaults to nil
    public var selectionStartDate: Date? {
        didSet {
            setNeedsDisplay()
        }
    }
    
    /// The day/month/year the calendar range selection end at - defaults to nil
    public var selectionEndDate: Date? {
        didSet {
            setNeedsDisplay()
        }
    }
    
    /// Should the calendar include days from the previous/next months in the current months to fill out complete weeks
    public var previewDaysInPreviousAndMonth = true {
        didSet {
            setNeedsDisplay()
        }
    }
    
    /// A delegate to provide required data to the calendar view and respond to user interaction with the calendar view
    public weak var delegate: DTCalendarViewDelegate?
    
    fileprivate var weekdayLabels: [String] = ["S", "M", "T", "W", "T", "F", "S"]
    
    fileprivate var weekDisplayAttributes = WeekDisplayAttributes(normalDisplayAttributes: DisplayAttributes(font: UIFont.systemFont(ofSize: 15),
                                                                                                         textColor: .black,
                                                                                                         backgroundColor: .white,
                                                                                                         textAlignment: .center),
                                                              selectedDisplayAttributes: DisplayAttributes(font: UIFont.boldSystemFont(ofSize: 15),
                                                                                                           textColor: .white,
                                                                                                           backgroundColor: .blue,
                                                                                                           textAlignment: .center),
                                                              highlightedDisplayAttributes: DisplayAttributes(font: UIFont.systemFont(ofSize: 15),
                                                                                                              textColor: .black,
                                                                                                              backgroundColor: .lightGray,
                                                                                                              textAlignment: .center),
                                                              previewDisplayAttributes: DisplayAttributes(font: UIFont.systemFont(ofSize: 15),
                                                                                                          textColor: UIColor.black.withAlphaComponent(0.5),
                                                                                                          backgroundColor: .white,
                                                                                                          textAlignment: .center))
    
    /// This display attributes that will be applied to the weekday labels
    public var weekdayDisplayAttributes = DisplayAttributes(font: UIFont.boldSystemFont(ofSize: 15),
                                                            textColor: .black,
                                                            backgroundColor: .white,
                                                            textAlignment: .center) {
        didSet {
            setNeedsDisplay()
        }
    }
    
    private var collectionViewFlowLayout: UICollectionViewFlowLayout
    fileprivate var collectionView: UICollectionView
    
    fileprivate var datePanGR: UIPanGestureRecognizer?
    fileprivate var panMode = PanMode.none
    
    private var _startDate: Date = {
        let calendar = Calendar.current
        let date = Date()
        var components = calendar.dateComponents([.year, .month, .day], from: date)
        components.setValue(1, for: .day)
        if let firstDayOfMonth = calendar.date(from: components) {
            return firstDayOfMonth
        }
        return date
    }() {
        didSet {
            collectionView.reloadData()
        }
    }

    private var _endDate: Date = {
        let calendar = Calendar.current
        let date = Date()
        var components = calendar.dateComponents([.year, .month, .day], from: date)
        components.setValue(1, for: .day)
        if let firstDayOfMonth = calendar.date(from: components) {
            return firstDayOfMonth
        }
        return date
    }() {
        didSet {
            collectionView.reloadData()
        }
    }
    
    /**
    Create a new calendar view with the given start/end display dates
     
     - parameter startDate: The month/year to begin the calendar
     
     - parameter endDate: The month/year to end the calendar
     
     - returns: a new calendar view
     
    */
    public init(startDate: Date, endDate: Date) {
        
        collectionViewFlowLayout = UICollectionViewFlowLayout()
        collectionView = UICollectionView(frame: .zero, collectionViewLayout: collectionViewFlowLayout)
        
        super.init(frame: .zero)
        
        self.displayStartDate = startDate
        self.displayEndDate = endDate
        
        
        setupCollectionView()
    }
    
    /**
     Create a new calendar view with the default start/end dates
     
     - returns: a new calendar view
     
     */
    required public init?(coder aDecoder: NSCoder) {
        
        collectionViewFlowLayout = UICollectionViewFlowLayout()
        collectionView = UICollectionView(frame: .zero, collectionViewLayout: collectionViewFlowLayout)
        
        super.init(coder: aDecoder)
        
        setupCollectionView()
    }
    
    override public func layoutSubviews() {
        
        collectionView.frame = CGRect(x: 0, y: 0, width: bounds.size.width, height: bounds.size.height)
        
        super.layoutSubviews()
    }
    
    override public func draw(_ rect: CGRect) {
        reloadVisibleCells()
    }
    
    /**
     Set the display attributes for the given date state
     
     - parameter displayAttributes: The attributes to apply
     
     - parameter state: The day state the attributes apply to
    */
    public func setDisplayAttributes(_ displayAttributes: DisplayAttributes, forState state: DayState) {
        
        var normalDisplayAttributes = weekDisplayAttributes.normalDisplayAttributes
        var selectedDisplayAttributes = weekDisplayAttributes.selectedDisplayAttributes
        var highlightedDisplayAttributes = weekDisplayAttributes.highlightedDisplayAttributes
        var previewDisplayAttributes = weekDisplayAttributes.previewDisplayAttributes
        
        switch state {
        case .normal:
            normalDisplayAttributes = displayAttributes
        case .selected:
            selectedDisplayAttributes = displayAttributes
        case .highlighted:
            highlightedDisplayAttributes = displayAttributes
        case .preview:
            previewDisplayAttributes = displayAttributes
        }
        
        weekDisplayAttributes = WeekDisplayAttributes(normalDisplayAttributes: normalDisplayAttributes,
                                                      selectedDisplayAttributes: selectedDisplayAttributes,
                                                      highlightedDisplayAttributes: highlightedDisplayAttributes,
                                                      previewDisplayAttributes: previewDisplayAttributes)
        
        setNeedsDisplay()
    }
    
    fileprivate func reloadVisibleCells() {
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        collectionView.reloadItems(at: collectionView.indexPathsForVisibleItems)
        CATransaction.commit()
    }
    
    private func setupCollectionView() {
        addSubview(collectionView)
        
        collectionViewFlowLayout.minimumLineSpacing = 0.0
        collectionViewFlowLayout.minimumInteritemSpacing = 0.0
        
        
        collectionView.register(DTMonthViewCell.self, forCellWithReuseIdentifier: "MonthViewCell")
        collectionView.register(DTWeekdayViewCell.self, forCellWithReuseIdentifier: "WeekDayViewCell")
        collectionView.register(DTCalendarWeekCell.self, forCellWithReuseIdentifier: "WeekViewCell")
        
        collectionView.decelerationRate = UIScrollViewDecelerationRateFast
        collectionView.dataSource = self
        collectionView.delegate = self
        
        datePanGR = UIPanGestureRecognizer(target: self, action: #selector(viewPanned(_:)))
        datePanGR!.delegate = self
        collectionView.addGestureRecognizer(datePanGR!)
    }
    
    func viewPanned(_ panGR: UIPanGestureRecognizer) {
        
        let point = panGR.location(in: collectionView)
        
        if let dayView = collectionView.hitTest(point, with: nil) as? DTCalendarDayView {
            
            if panGR.state == .began {
                switch dayView.rangeSelection {
                case .startSelectionNoEnd, .startSelection:
                    panMode = .start
                case .endSelectionNoStart, .endSelection:
                    panMode = .end
                default:
                    panMode = .none
                }
            } else if panGR.state == .changed {
                
                if panMode == .start {
                    
                    if let startDate = selectionStartDate {
                        delegate?.calendarView(self, dragFromDate: startDate, toDate: dayView.representedDate)
                    }
                } else if panMode == .end {
                    
                    if let endDate = selectionEndDate {
                        delegate?.calendarView(self, dragFromDate: endDate, toDate: dayView.representedDate)
                    }
                }
            }
        }
        
    }
    
    /**
     The text to use for the weekday labels
     
     -parameters labels: An array with the text labels, this must be an array with 7 values in order Sun-Sat
     
    */
    public func setWeekdayLabels(_ labels: [String]) {
        if labels.count != 7 {
            fatalError("It is a programmer error to provide more or less than 7 weekday label values")
        }
        
        weekdayLabels = labels
    }
}

extension DTCalendarView: UICollectionViewDataSource {
    
    public func numberOfSections(in collectionView: UICollectionView) -> Int {
        
        let calendar = Calendar.current
        let months = calendar.dateComponents([.month], from: displayStartDate, to: displayEndDate).month ?? 0
        
        return months + 1
    }
    
    @available(iOS 6.0, *)
    public func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return 8
    }
    
    @available(iOS 6.0, *)
    public func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        if indexPath.item == 0 {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "MonthViewCell", for: indexPath)
            let calendar = Calendar.current
            if let date = calendar.date(byAdding: .month, value: indexPath.section, to: displayStartDate),
                let monthCell = cell as? DTMonthViewCell {
                let userMonthView = delegate?.calendarView(self, viewForMonth: date)
                monthCell.userContentView = userMonthView
            }
            return cell
        } else if indexPath.item == 1 {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "WeekDayViewCell", for: indexPath)
            
            if let weekdayViewCell = cell as? DTWeekdayViewCell {
                weekdayViewCell.setDisplayAttributes(weekdayDisplayAttributes)
                weekdayViewCell.setWeekdayLabels(weekdayLabels)
            }
            
            return cell
        } else {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier:  "WeekViewCell", for: indexPath)
            
            let calendar = Calendar.current
            if let date = calendar.date(byAdding: .month, value: indexPath.section, to: displayStartDate),
                let weekViewCell = cell as? DTCalendarWeekCell {
                weekViewCell.delegate = self
                weekViewCell.selectionStartDate = selectionStartDate
                weekViewCell.selectionEndDate = selectionEndDate
                weekViewCell.displayMonth = date
                weekViewCell.displayWeek = indexPath.item - 1
                
                weekViewCell.updateCalendarLabels(weekDisplayAttributes: weekDisplayAttributes)
            }
            
            return cell
        }
    }
}

extension DTCalendarView: UICollectionViewDelegateFlowLayout {
    
    public func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        
        var height: CGFloat = 0
        if indexPath.item == 0 {
            let calendar = Calendar.current
            if let date = calendar.date(byAdding: .month, value: indexPath.section, to: displayStartDate) {
                height = delegate?.calendarView(self, heightOfViewForMonth: date) ?? 60
            }
        } else if indexPath.item == 1 {
            height = delegate?.calendarViewHeightOfWeekdayLabelRow(self) ?? 50
        } else {
            height = delegate?.calendarViewHeightOfWeekRows(self) ?? 40
        }
        
        return CGSize(width: collectionView.bounds.size.width, height: height)
    }
}

extension DTCalendarView: UIGestureRecognizerDelegate {
    
    public func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
        
        guard let datePanGR = datePanGR else { return true }
        
        if gestureRecognizer != datePanGR { return true }
        
        let location = touch.location(in: collectionView)
        
        if let dayView = collectionView.hitTest(location, with: nil) as? DTCalendarDayView {
            
            switch dayView.rangeSelection {
            case .endSelection, .startSelection, .endSelectionNoStart, .startSelectionNoEnd:
                return true
            default:
                return false
            }
        }
        
        return false
    }
}

extension DTCalendarView: DTCalendarWeekCellDelegate {
    
    func calendarWeekCell(_ calendarWeekCell: DTCalendarWeekCell, didTapDate date: Date) {
        
        delegate?.calendarView(self, didSelectDate: date)
    }
}
