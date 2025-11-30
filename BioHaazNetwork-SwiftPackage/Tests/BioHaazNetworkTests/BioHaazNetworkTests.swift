import XCTest
@testable import BioHaazNetwork

final class BioHaazNetworkTests: XCTestCase {
    
    func testInitialization() throws {
        let config = BioHaazNetworkConfig(
            environments: [
                .dev: "https://dev.api.example.com",
                .prod: "https://api.example.com"
            ],
            defaultEnvironment: .prod,
            debug: true
        )
        
        BioHaazNetworkManager.shared.initialize(with: config)
        
        // Test that the manager is initialized
        XCTAssertNotNil(BioHaazNetworkManager.shared)
    }
    
    func testEnvironmentSwitching() throws {
        let config = BioHaazNetworkConfig(
            environments: [
                .dev: "https://dev.api.example.com",
                .prod: "https://api.example.com"
            ],
            defaultEnvironment: .prod,
            debug: true
        )
        
        BioHaazNetworkManager.shared.initialize(with: config)
        
        // Test environment switching
        BioHaazNetworkManager.shared.setEnvironment(.dev)
        let currentEnv = BioHaazNetworkManager.shared.getCurrentEnvironment()
        XCTAssertEqual(currentEnv, .dev)
        
        BioHaazNetworkManager.shared.setEnvironment(.prod)
        let prodEnv = BioHaazNetworkManager.shared.getCurrentEnvironment()
        XCTAssertEqual(prodEnv, .prod)
    }
    
    func testBaseURLRetrieval() throws {
        let config = BioHaazNetworkConfig(
            environments: [
                .dev: "https://dev.api.example.com",
                .prod: "https://api.example.com"
            ],
            defaultEnvironment: .prod,
            debug: true
        )
        
        BioHaazNetworkManager.shared.initialize(with: config)
        
        let baseURL = BioHaazNetworkManager.shared.getBaseURL()
        XCTAssertEqual(baseURL, "https://api.example.com")
    }
}




