import Foundation
import SwiftData

@Model
final class UserActivity {
    var timestamp: Date
    var actionTypeValue: String
    var listeningDuration: Float
    
    var actionType: ActionType {
        get { ActionType(rawValue: actionTypeValue) ?? .play }
        set { actionTypeValue = newValue.rawValue }
    }
    
    var track: Track?
    
    init(timestamp: Date = Date(), actionType: ActionType, listeningDuration: Float) {
        self.timestamp = timestamp
        self.actionTypeValue = actionType.rawValue
        self.listeningDuration = listeningDuration
    }
}

enum ActionType: String, Codable {
    case play = "Play"
    case skip = "Skip"
}
