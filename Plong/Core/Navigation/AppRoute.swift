import Foundation

public enum AppRoute: Hashable, Sendable {
    case crowdMap
    case taskLog
    case taskDetail(item: TaskLogItem)
}
