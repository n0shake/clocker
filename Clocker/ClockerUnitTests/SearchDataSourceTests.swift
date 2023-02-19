// Copyright © 2015 Abhishek Banthia

import CoreModelKit
import XCTest

@testable import Clocker

class SearchDataSourceTests: XCTestCase {
    private var subject: SearchDataSource!

    private func setupSubject(searchText: String = "") {
        let mockSearchField = NSSearchField()
        mockSearchField.stringValue = searchText
        subject = SearchDataSource(with: mockSearchField, location: .preferences)
    }

    private func setupMockData() {
        subject.searchTimezones("los")
        XCTAssertTrue(subject.calculateChangesets())

        let mockTimezone = TimezoneData()
        mockTimezone.timezoneID = "PST"
        mockTimezone.formattedAddress = "Los Angeles"
        subject.setFilteredArrayValue([mockTimezone])

        subject.searchTimezones("los")
        XCTAssertTrue(subject.calculateChangesets())
    }

    override func tearDownWithError() throws {
        subject = nil
        try super.tearDownWithError()
    }

    func testSearchTimezones() {
        setupSubject(searchText: "")
        // Test capitalized string
        subject.searchTimezones("MUMBAI")
        XCTAssert(subject.timezoneFilteredArray.isEmpty == false)

        // Test sentence-cased string
        subject.searchTimezones("Delhi")
        XCTAssert(subject.timezoneFilteredArray.isEmpty == false)

        // Test lower-cased string
        subject.searchTimezones("california")
        XCTAssert(subject.timezoneFilteredArray.isEmpty == false)
    }

    func testCalculateChangesets() {
        setupSubject(searchText: "los")
        setupMockData()

        subject.cleanupFilterArray()
        subject.searchTimezones("los")
        XCTAssertTrue(subject.calculateChangesets())
    }

    func testRetrieveResult() throws {
        setupSubject(searchText: "los")
        setupMockData()

        // 0 will translate to a city search result
        let result1 = subject.retrieveResult(0)
        let unwrap = try XCTUnwrap(result1)
        if let metadata = unwrap as? CoreModelKit.TimezoneData {
            XCTAssert(metadata.timezoneID == "PST")
        }

        // 1 will translate to a timezone search result
        let result2 = subject.retrieveResult(1)
        let unwrap2 = try XCTUnwrap(result2)
        if let metadata = unwrap2 as? TimezoneMetadata {
            XCTAssert(metadata.timezone.name == "America/Tijuana")
        }

        // Test placeForRow
        let rowType = subject.placeForRow(0)
        XCTAssert(rowType == .city)

        let rowType1 = subject.placeForRow(1)
        XCTAssert(rowType1 == .timezone)

        // Test count
        XCTAssertEqual(subject.resultsCount(), 4)

        // Test retrieveFilteredResultFromGoogleAPI
        let firstResult = try XCTUnwrap(subject.retrieveFilteredResultFromGoogleAPI(0))
        XCTAssert(firstResult.timezoneID == "PST")
        // filteredArray should only have a count of 1
        XCTAssertNil(subject.retrieveFilteredResultFromGoogleAPI(1))
    }

    func testTableViewDataSourceMethods() {
        let mockTableView = NSTableView(frame: CGRect.zero)
        setupSubject(searchText: "los")
        setupMockData()

        let resultsCount = subject.numberOfRows(in: mockTableView)
        XCTAssert(resultsCount == 4)
        XCTAssert(subject.tableView(mockTableView, heightOfRow: 0) == 30)
    }

    func testRetrieveSelectedTimezone() {
        setupSubject(searchText: "los")
        setupMockData()

        let result = subject.retrieveSelectedTimezone(0)
        let possibleOutcomes = Set<String>(["PDT", "PST"])
        XCTAssert(possibleOutcomes.contains(result.timezone.abbreviation ?? "NA"),
                  "Result timezone is actually \(result.timezone.abbreviation ?? "NA")")
    }

    func testRetrieveSelectedTimezoneWithEmptySearchField() {
        // Setup subject with an empty search field
        setupSubject(searchText: CLEmptyString)
        subject.searchTimezones("los")
        XCTAssertFalse(subject.calculateChangesets())

        let mockTimezone = TimezoneData()
        mockTimezone.timezoneID = "PST"
        mockTimezone.formattedAddress = "Los Angeles"
        subject.setFilteredArrayValue([mockTimezone])

        subject.searchTimezones("los")
        XCTAssertFalse(subject.calculateChangesets())

        let result = subject.retrieveSelectedTimezone(1)
        XCTAssert(result.timezone.abbreviation == "GMT")
    }

    func testRetrieveSelectedTimezoneWithEmptySearchFieldWithoutSearchResults() {
        // Setup subject with an empty search field
        setupSubject(searchText: "los")
        setupMockData()
        subject.cleanupFilterArray()

        let result = subject.retrieveResult(0)
        XCTAssertNil(result)
    }
}
