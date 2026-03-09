import Foundation

enum ActivityEventType {
    case keyboard
    case mouse
}

struct ActivityEvent {
    let type: ActivityEventType
    let timestamp: Date
}
