import XCTest

#if !canImport(ObjectiveC)
public func allTests() -> [XCTestCaseEntry] {
    return [
        testCase(abjc_apiTests.allTests),
    ]
}
#endif
