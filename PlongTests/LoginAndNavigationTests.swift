import XCTest
@testable import Plong

@MainActor
final class LoginAndNavigationTests: XCTestCase {
    func test_loginValidation_rejectsEmptyFields() {
        let router = NavigationRouter()
        let vm = LoginViewModel(router: router)
        
        // Reset to empty
        vm.email = ""
        vm.password = ""
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
    
    func test_loginRoleSelection_managerAndStaff() async {
        let router = NavigationRouter()
        let vm = LoginViewModel(router: router)
        
        // Sign in with Staff email
        vm.email = "staff@venue.com"
        vm.password = "password123"
        vm.signIn()
        try? await Task.sleep(nanoseconds: 400_000_000)
        XCTAssertTrue(router.isAuthenticated)
        XCTAssertEqual(router.currentUserRole, .staff)
        
        // Logout
        router.logout()
        XCTAssertFalse(router.isAuthenticated)
        
        // Sign in with Manager email
        vm.email = "manager@venue.com"
        vm.password = "password123"
        vm.signIn()
        try? await Task.sleep(nanoseconds: 400_000_000)
        XCTAssertTrue(router.isAuthenticated)
        XCTAssertEqual(router.currentUserRole, .manager)
        
        // Sign in with standard email (defaults to manager experience)
        router.logout()
        vm.email = "abcde@gmail.com"
        vm.password = "password123"
        vm.signIn()
        try? await Task.sleep(nanoseconds: 400_000_000)
        XCTAssertTrue(router.isAuthenticated)
        XCTAssertEqual(router.currentUserRole, .manager)
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
    
    func test_navigationRouter_staffTaskDetailRoute() {
        let router = NavigationRouter()
        let sampleItem = TaskLogItem(
            title: "Overflow in Pantry",
            dateString: "3 October 2026",
            timeString: "14:05",
            status: .ongoing
        )
        router.navigate(to: .staffTaskDetail(item: sampleItem))
        XCTAssertEqual(router.path.count, 1)
        
        router.pop()
        XCTAssertTrue(router.path.isEmpty)
    }
    
    func test_taskLogViewModel_segmentedOngoingAndHistory() {
        let repo = MockCrowdFlowRepository()
        let router = NavigationRouter()
        let vm = TaskLogViewModel(repository: repo, router: router)
        
        // Default is ongoing
        XCTAssertEqual(vm.selectedSegment, .ongoing)
        XCTAssertTrue(vm.taskLogs.allSatisfy { $0.status == .ongoing })
        XCTAssertTrue(vm.taskLogs.contains(where: { $0.title == "Overflow in Pantry" }))
        XCTAssertTrue(vm.taskLogs.contains(where: { $0.title == "Overflow in Lab 2" }))
        
        // Switch to History
        vm.selectedSegment = .history
        XCTAssertTrue(vm.taskLogs.allSatisfy { $0.status == .done })
        XCTAssertTrue(vm.taskLogs.contains(where: { $0.title == "Overflow in Pantry" }))
        XCTAssertTrue(vm.taskLogs.contains(where: { $0.title == "Overflow in Lab 2" }))
        XCTAssertTrue(vm.taskLogs.contains(where: { $0.title == "Overflow in Lab 1" }))
    }
}
