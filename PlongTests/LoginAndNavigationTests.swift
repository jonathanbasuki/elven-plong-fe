import XCTest
@testable import Plong

@MainActor
final class LoginAndNavigationTests: XCTestCase {
    func test_loginValidation_rejectsEmptyFields() {
        let router = NavigationRouter()
        let vm = LoginViewModel(router: router)
        
        // Empty
        XCTAssertFalse(vm.validate())
        XCTAssertNotNil(vm.emailError)
        XCTAssertNotNil(vm.passwordError)
        
        // Invalid email
        vm.email = "notanemail"
        vm.password = "12345"
        XCTAssertFalse(vm.validate())
        XCTAssertNotNil(vm.emailError)
        
        // Short password
        vm.email = "admin@venue.com"
        vm.password = "12"
        XCTAssertFalse(vm.validate())
        XCTAssertNotNil(vm.passwordError)
        
        // Valid
        vm.email = "admin@venue.com"
        vm.password = "password123"
        XCTAssertTrue(vm.validate())
        XCTAssertNil(vm.emailError)
        XCTAssertNil(vm.passwordError)
    }
    
    func test_navigationRouter_stateTransitions() {
        let router = NavigationRouter()
        XCTAssertFalse(router.isAuthenticated)
        XCTAssertTrue(router.path.isEmpty)
        
        router.navigate(to: .taskLog)
        XCTAssertEqual(router.path.count, 1)
        
        let sampleItem = TaskLogItem(
            title: "Overflow in Pantry",
            dateString: "3 October 2026",
            timeString: "14:05",
            status: .ongoing
        )
        router.navigate(to: .taskDetail(item: sampleItem))
        XCTAssertEqual(router.path.count, 2)
        
        router.pop()
        XCTAssertEqual(router.path.count, 1)
        
        router.popToRoot()
        XCTAssertTrue(router.path.isEmpty)
    }
    
    func test_navigationRouter_taskLogRoute() {
        let router = NavigationRouter()
        router.navigate(to: .taskLog)
        XCTAssertEqual(router.path.count, 1)
        
        router.pop()
        XCTAssertTrue(router.path.isEmpty)
    }
    
    func test_taskLogViewModel_filteringAndLogItems() {
        let repo = MockCrowdFlowRepository()
        let router = NavigationRouter()
        let vm = TaskLogViewModel(repository: repo, router: router)
        
        // Initial items match sample/Manager/Task log.svg
        XCTAssertGreaterThanOrEqual(vm.taskLogs.count, 4)
        XCTAssertTrue(vm.taskLogs.contains(where: { $0.title == "Overflow in Pantry" && $0.status == .ongoing }))
        XCTAssertTrue(vm.taskLogs.contains(where: { $0.title == "Overflow in Lab 2" && $0.status == .done }))
        
        // Filter ongoing
        vm.selectedStatusFilter = .ongoing
        XCTAssertTrue(vm.taskLogs.allSatisfy { $0.status == .ongoing })
        
        // Filter history (done)
        vm.selectedStatusFilter = .history
        XCTAssertTrue(vm.taskLogs.allSatisfy { $0.status == .done })
        
        // Filter all
        vm.selectedStatusFilter = .all
        XCTAssertEqual(vm.taskLogs.count, 4)
    }
}
