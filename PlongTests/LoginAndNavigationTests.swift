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
        
        router.navigate(to: .zoneDetail(zoneID: MockDataConstants.zoneAId))
        XCTAssertEqual(router.path.count, 1)
        
        router.navigate(to: .broadcast(zoneID: MockDataConstants.zoneAId))
        XCTAssertEqual(router.path.count, 2)
        
        router.pop()
        XCTAssertEqual(router.path.count, 1)
        
        router.popToRoot()
        XCTAssertTrue(router.path.isEmpty)
    }
}
