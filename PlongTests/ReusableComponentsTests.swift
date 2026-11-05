import XCTest
import SwiftUI
@testable import Plong

@MainActor
final class ReusableComponentsTests: XCTestCase {
    
    // 1. StatusMetricCard test
    func test_statusMetricCard_initialization() {
        let card = StatusMetricCard(title: "Active Staff", value: "18")
        XCTAssertEqual(card.title, "Active Staff")
        XCTAssertEqual(card.value, "18")
        XCTAssertTrue(card.showsCardBackground)
    }
    
    // 2. StatusMetricsRow test
    func test_statusMetricsRow_initialization() {
        let row = StatusMetricsRow(status: "Overflow", crowdCount: 50)
        XCTAssertEqual(row.status, "Overflow")
        XCTAssertEqual(row.crowdCount, 50)
        XCTAssertFalse(row.showsCardBackground)
    }
    
    // 3. StaffRowView test with raw values
    func test_staffRowView_rawInitialization() {
        let row = StaffRowView(
            name: "Rendi Septrian",
            role: "Security",
            statusText: "Active Staff"
        )
        XCTAssertEqual(row.name, "Rendi Septrian")
        XCTAssertEqual(row.role, "Security")
        XCTAssertEqual(row.statusText, "Active Staff")
        XCTAssertEqual(row.avatarImage, "user_profile")
    }
    
    // 4. StaffRowView test with domain SecurityStaff model (Backend readiness)
    func test_staffRowView_domainModelBinding() {
        let staff = SecurityStaff(
            id: UUID(),
            name: "Bunga",
            status: .delegating
        )
        let row = StaffRowView(staff: staff)
        XCTAssertEqual(row.name, "Bunga")
        XCTAssertEqual(row.role, "Security")
        XCTAssertEqual(row.statusText, "Delegating")
    }
    
    // 5. TaskCard test with TaskLogItem
    func test_taskCard_initialization() {
        let ongoingItem = TaskLogItem(
            title: "Overflow in Pantry",
            dateString: "3 October 2026",
            timeString: "14:05",
            status: .ongoing
        )
        
        let staffCard = TaskCard(task: ongoingItem, ongoingStyle: .accepted)
        XCTAssertEqual(staffCard.title, "Overflow in Pantry")
        XCTAssertEqual(staffCard.statusStyle, .accepted)
        
        let managerCard = TaskCard(task: ongoingItem, ongoingStyle: .ongoing)
        XCTAssertEqual(managerCard.statusStyle, .ongoing)
        
        var doneItem = ongoingItem
        doneItem.status = .done
        let doneCard = TaskCard(task: doneItem)
        XCTAssertEqual(doneCard.statusStyle, .done)
    }
}
