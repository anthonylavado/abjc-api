import XCTest
@testable import abjc_api

final class abjc_apiTests: XCTestCase {
    func testExample() {
        let expect = expectation(description: "ss")
        ArtworkFetcher.fetchArtwork(for: "Star Wars: The Force Awakens", in: "en-gb") { (result) in
            switch result {
                case .success(let artwork):
                    print(artwork.cover.url(1600, 900))
                    
//                    print(artwork.logo?.url(1600, 900))
                case .failure(let error):
                    print(error)
            }
            expect.fulfill()
        }
        
        wait(for: [expect], timeout: 120.0)
    }

    static var allTests = [
        ("testExample", testExample),
    ]
}
