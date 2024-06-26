import UIKit
import OSLog
import ActivityKit

fileprivate enum Setting:Int, CaseIterable {
    
    /// should reading be shown in notification
    case showReadingInNotification = 0
    
    /// - minimum time between two readings, for which notification should be created (in minutes)
    /// - except if there's been a disconnect, in that case this value is not taken into account
    case notificationInterval = 1
    
    /// show live activities
    case liveActivityType = 2
    
    /// live activity size
    case liveActivitySize = 3
    
    /// show reading in app badge
    case showReadingInAppBadge = 4
    
    /// if reading is shown in app badge, should value be multiplied with 10 yes or no
    case multipleAppBadgeValueWith10 = 5
    
}

/// conforms to SettingsViewModelProtocol for all general settings in the first sections screen
class SettingsViewNotificationsSettingsViewModel: NSObject, SettingsViewModelProtocol {
    
    /// for trace
    private let log = OSLog(subsystem: ConstantsLog.subSystem, category: ConstantsLog.categorySettingsViewDataSourceSettingsViewModel)
    
    override init() {
        super.init()
        addObservers()
    }
    
    var sectionReloadClosure: (() -> Void)?
    
    func storeRowReloadClosure(rowReloadClosure: ((Int) -> Void)) {}
    
    func storeSectionReloadClosure(sectionReloadClosure: @escaping (() -> Void)) {
        self.sectionReloadClosure = sectionReloadClosure
    }
    
    func storeUIViewController(uIViewController: UIViewController) {}
    
    func storeMessageHandler(messageHandler: ((String, String) -> Void)) {
        // this ViewModel does need to send back messages to the viewcontroller asynchronously
    }
    
    func completeSettingsViewRefreshNeeded(index: Int) -> Bool {
        
        return false
    }
    
    func isEnabled(index: Int) -> Bool {
        return true
    }
    
    func onRowSelect(index: Int) -> SettingsSelectedRowAction {
        guard let setting = Setting(rawValue: index) else { fatalError("Unexpected Section") }
        
        switch setting {
            
        case .showReadingInNotification, .showReadingInAppBadge, .multipleAppBadgeValueWith10:
            return .nothing
            
        case .notificationInterval:
            
            return SettingsSelectedRowAction.askText(title: Texts_SettingsView.settingsviews_IntervalTitle, message: Texts_SettingsView.settingsviews_IntervalMessage, keyboardType: .numberPad, text: UserDefaults.standard.notificationInterval.description, placeHolder: "0", actionTitle: nil, cancelTitle: nil, actionHandler: {(interval:String) in if let interval = Int(interval) {UserDefaults.standard.notificationInterval = Int(interval)}}, cancelHandler: nil, inputValidator: nil)
            
        case .liveActivityType:
            // live activities can only be used in master mode as follower mode
            // will not allow updates whilst the app is in the background
            if UserDefaults.standard.isMaster || UserDefaults.standard.followerBackgroundKeepAliveType == .heartbeat {
                
                // data to be displayed in list from which user needs to pick a live activity type
                var data = [String]()
                
                var selectedRow: Int?
                
                var index = 0
                
                let currentLiveActivityType = UserDefaults.standard.liveActivityType
                
                // get all data source types and add the description to data. Search for the type that matches the FollowerDataSourceType that is currently stored in userdefaults.
                for liveActivityType in LiveActivityType.allCases {
                    
                    data.append(liveActivityType.description)
                    
                    if liveActivityType == currentLiveActivityType {
                        selectedRow = index
                    }
                    
                    index += 1
                    
                }
                
                return SettingsSelectedRowAction.selectFromList(title: Texts_SettingsView.labelLiveActivityType, data: data, selectedRow: selectedRow, actionTitle: nil, cancelTitle: nil, actionHandler: {(index:Int) in
                    
                    // we'll set this here so that we can use it in the else statement for logging
                    let oldLiveActivityType = UserDefaults.standard.liveActivityType
                    
                    if index != selectedRow {
                        
                        UserDefaults.standard.liveActivityType = LiveActivityType(rawValue: index) ?? .disabled
                        
                        let newLiveActivityType = UserDefaults.standard.liveActivityType
                        
                        trace("Live activity type was changed from '%{public}@' to '%{public}@'", log: self.log, category: ConstantsLog.categorySettingsViewNotificationsSettingsViewModel, type: .info, oldLiveActivityType.description, newLiveActivityType.description)
                        
                    }
                    
                }, cancelHandler: nil, didSelectRowHandler: nil)
                
            } else {
                
                return .showInfoText(title: Texts_SettingsView.labelLiveActivityType, message: Texts_SettingsView.liveActivityDisabledInFollowerModeMessage, actionHandler: {})
                
            }
            
        case .liveActivitySize:
            // live activities can only be used in master mode as follower mode
            // will not allow updates whilst the app is in the background
            if UserDefaults.standard.isMaster || UserDefaults.standard.followerBackgroundKeepAliveType == .heartbeat {
                
                // data to be displayed in list from which user needs to pick a live activity type
                var data = [String]()
                
                var selectedRow: Int?
                
                var index = 0
                
                let currentliveActivitySize = UserDefaults.standard.liveActivitySize
                
                // get all data source types and add the description to data. Search for the type that matches the FollowerDataSourceType that is currently stored in userdefaults.
                for liveActivitySize in LiveActivitySize.allCasesForList {
                    
                    data.append(liveActivitySize.description)
                    
                    if liveActivitySize == currentliveActivitySize {
                        selectedRow = index
                    }
                    
                    index += 1
                    
                }
                
                return SettingsSelectedRowAction.selectFromList(title: Texts_SettingsView.labelliveActivitySize, data: data, selectedRow: selectedRow, actionTitle: nil, cancelTitle: nil, actionHandler: {(index:Int) in
                    
                    // we'll set this here so that we can use it in the else statement for logging
                    let oldliveActivitySize = UserDefaults.standard.liveActivitySize
                    
                    if index != selectedRow {
                        
                        UserDefaults.standard.liveActivitySize = LiveActivitySize(forRowAt: index) ?? .normal
                        
                        let newliveActivitySize = UserDefaults.standard.liveActivitySize
                        
                        trace("Live activity notification size was changed from '%{public}@' to '%{public}@'", log: self.log, category: ConstantsLog.categorySettingsViewNotificationsSettingsViewModel, type: .info, oldliveActivitySize.description, newliveActivitySize.description)
                    }
                    
                }, cancelHandler: nil, didSelectRowHandler: nil)
                
            } else {
                
                return .showInfoText(title: Texts_SettingsView.labelliveActivitySize, message: Texts_SettingsView.liveActivityDisabledInFollowerModeMessage, actionHandler: {})
                
            }
        }
    }
    
    func sectionTitle() -> String? {
        return ConstantsSettingsIcons.notificationsSettingsIcon + " " + Texts_SettingsView.sectionTitleNotifications
    }

    func numberOfRows() -> Int {
        
        // if unit is mmol and if show value in app badge is on and if showReadingInNotification is not on, then show also if to be multiplied by 10 yes or no
        // (if showReadingInNotification is on, then badge counter will be set via notification, in this case we can use NSNumber so we don't need to multiply by 10)
        if !UserDefaults.standard.bloodGlucoseUnitIsMgDl && UserDefaults.standard.showReadingInAppBadge {
            return Setting.allCases.count
        } else {
            return Setting.allCases.count - 1
        }
        
    }

    func settingsRowText(index: Int) -> String {
        guard let setting = Setting(rawValue: index) else { fatalError("Unexpected Section") }

        switch setting {
            
        case .showReadingInNotification:
            return Texts_SettingsView.showReadingInNotification
            
        case .notificationInterval:
            return Texts_SettingsView.settingsviews_IntervalTitle
            
        case .liveActivityType:
            return Texts_SettingsView.labelLiveActivityType
            
        case .liveActivitySize:
            return Texts_SettingsView.labelliveActivitySize
            
        case .showReadingInAppBadge:
            return Texts_SettingsView.labelShowReadingInAppBadge
            
        case .multipleAppBadgeValueWith10:
            return Texts_SettingsView.multipleAppBadgeValueWith10
            
        }
    }
    
    func accessoryType(index: Int) -> UITableViewCell.AccessoryType {
        guard let setting = Setting(rawValue: index) else { fatalError("Unexpected Section") }
        
        switch setting {
            
        case .showReadingInNotification, .showReadingInAppBadge, .multipleAppBadgeValueWith10:
            return .none
            
        case .notificationInterval:
            return .disclosureIndicator
            
        case .liveActivityType, .liveActivitySize:
            return UserDefaults.standard.isMaster || UserDefaults.standard.followerBackgroundKeepAliveType == .heartbeat ? .disclosureIndicator : .none
        }
    }
    
    func detailedText(index: Int) -> String? {
        guard let setting = Setting(rawValue: index) else { fatalError("Unexpected Section") }

        switch setting {
            
        case .showReadingInNotification, .showReadingInAppBadge, .multipleAppBadgeValueWith10:
            return nil
            
        case .notificationInterval:
            return UserDefaults.standard.notificationInterval.description
            
        case .liveActivityType:
            return UserDefaults.standard.isMaster || UserDefaults.standard.followerBackgroundKeepAliveType == .heartbeat ? UserDefaults.standard.liveActivityType.description : Texts_SettingsView.liveActivityDisabledInFollowerMode
            
        case .liveActivitySize:
            return UserDefaults.standard.isMaster || UserDefaults.standard.followerBackgroundKeepAliveType == .heartbeat ? UserDefaults.standard.liveActivitySize.description : Texts_SettingsView.liveActivityDisabledInFollowerMode
        }
    }
    
    func uiView(index: Int) -> UIView? {
        
        guard let setting = Setting(rawValue: index) else { fatalError("Unexpected Section") }
        
        switch setting {
        case .showReadingInNotification:
            return UISwitch(isOn: UserDefaults.standard.showReadingInNotification, action: {(isOn:Bool) in UserDefaults.standard.showReadingInNotification = isOn})
            
        case .showReadingInAppBadge:
            return UISwitch(isOn: UserDefaults.standard.showReadingInAppBadge, action: {(isOn:Bool) in UserDefaults.standard.showReadingInAppBadge = isOn})

        case .multipleAppBadgeValueWith10:
            return UISwitch(isOn: UserDefaults.standard.multipleAppBadgeValueWith10, action: {(isOn:Bool) in UserDefaults.standard.multipleAppBadgeValueWith10 = isOn})

        case .notificationInterval, .liveActivityType, .liveActivitySize:
            return nil
        }
    }
    
    // MARK: - observe functions
    
    private func addObservers() {
        
        // Listen for changes in the active sensor value to trigger the UI to be updated
        UserDefaults.standard.addObserver(self, forKeyPath: UserDefaults.Key.followerBackgroundKeepAliveType.rawValue, options: .new, context: nil)
        
    }
    
    override public func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        
        guard let keyPath = keyPath,
              let keyPathEnum = UserDefaults.Key(rawValue: keyPath)
        else { return }
        
        switch keyPathEnum {
        case UserDefaults.Key.followerBackgroundKeepAliveType:
            
            // we have to run this in the main thread to avoid access errors
            DispatchQueue.main.async {
                self.sectionReloadClosure?()
            }
            
        default:
            break
            
        }
    }
}
