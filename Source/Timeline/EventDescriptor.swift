#if os(iOS)
import Foundation
import UIKit

public enum EventType {
    case availability
    case request
    case fullRequest
}

public protocol EventDescriptor: AnyObject {
    var type: EventType {get set}
    var isFullWidth: Bool {get set}
    var isTappable: Bool {get set}
    var isEditable: Bool {get set}
    var startDate: Date {get set}
    var endDate: Date {get set}
    var isAllDay: Bool {get}
    var text: String {get}
    var attributedText: NSAttributedString? {get}
    var font : UIFont {get}
    var color: UIColor {get}
    var textColor: UIColor {get}
    var backgroundColor: UIColor {get}
    var editedEvent: EventDescriptor? {get set}
    func makeEditable() -> Self
    func commitEditing()
}
#endif
