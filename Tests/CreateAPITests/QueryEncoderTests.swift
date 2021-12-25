// The MIT License (MIT)
//
// Copyright (c) 2021 Alexander Grebenyuk (github.com/kean).

import XCTest
@testable import CreateAPI

final class QueryEncoderTests: XCTestCase {
    // MARK: Style: Form, Explode: True
    
    func testStyleFormExplodeTruePrimitive() {
        // GIVEN
        let id = 5
        
        // THEN
        var query: [(String, String?)] = []
        query.addQueryItem("id", id)
        
        // THEN
        XCTAssertEqual(query.asQuery(), "id=5")
    }

    func testStyleFormExplodeTrueArray() {
        // GIVEN
        let ids = [3, 4, 5]
        
        // WHEN
        var query: [(String, String?)] = []
        ids.forEach { query.addQueryItem("id", $0) }
        
        // THEN
        XCTAssertEqual(query.asQuery(), "id=3&id=4&id=5")
    }
    
    func testStyleFormExplodeTrueObject() {
        // GIVEN
        let user = User(role: "admin", name: "kean")
        
        // WHEN
        var query: [(String, String?)] = []
        query += user.asQuery
        
        // THEN
        XCTAssertEqual(query.asQuery(), "role=admin&name=kean")
    }
    
    // MARK: Style: Form, Explode: False
    
    func testStyleFormExplodeFalsePrimitive() {
        // GIVEN
        let id = 5
        
        // THEN
        var query: [(String, String?)] = []
        query.addQueryItem("id", id)
        
        // THEN
        XCTAssertEqual(query.asQuery(), "id=5")
    }

    func testStyleFormExplodeFalseArray() {
        // GIVEN
        let ids = [3, 4, 5]
        
        // WHEN
        var query: [(String, String?)] = []
        query.addQueryItem("id", ids.map(\.asQueryValue).joined(separator: ","))
        
        // THEN
        XCTAssertEqual(query.asQuery(), "id=3,4,5")
    }
    
    func testStyleFormExplodeFalseObject() {
        // GIVEN
        let user = User(role: "admin", name: "kean")
        
        // WHEN
        var query: [(String, String?)] = []
        query.addQueryItem("id", user.asQuery.asCompactQuery)
        
        // THEN
        XCTAssertEqual(query.asQuery(), "id=role,admin,name,kean")
    }
    
    // MARK: Style: SpaceDelimited
    
    // The rest of the combinations are invalid (the tool need to validate for that)

    // The same as "form"
    func testStyleSpaceDelimitedExplodeTrue() {
        // GIVEN
        let ids = [3, 4, 5]
        
        // WHEN
        var query: [(String, String?)] = []
        ids.forEach { query.addQueryItem("id", $0) }
        
        // THEN
        XCTAssertEqual(query.asQuery(), "id=3&id=4&id=5")
    }
    
    func testStyleSpaceDelimitedExplodeFalse() {
        // GIVEN
        let ids = [3, 4, 5]
        
        // WHEN
        var query: [(String, String?)] = []
        query.addQueryItem("id", ids.map(\.asQueryValue).joined(separator: " "))
        
        // THEN
        XCTAssertEqual(query.asQuery(), "id=3%204%205")
        XCTAssertEqual(query.asQuery()?.removingPercentEncoding, "id=3 4 5")
    }
    
    // MARK: Style: PipeDelimited
    
    // The rest of the combinations are invalid (the tool need to validate for that)

    // The same as "form"
    func testStylePipeDelimitedExplodeTrue() {
        // GIVEN
        let ids = [3, 4, 5]
        
        // WHEN
        var query: [(String, String?)] = []
        ids.forEach { query.addQueryItem("id", $0) }
        
        // THEN
        XCTAssertEqual(query.asQuery(), "id=3&id=4&id=5")
    }
    
    func testStylePipeDelimitedExplodeFalse() {
        // GIVEN
        let ids = [3, 4, 5]
        
        // WHEN
        var query: [(String, String?)] = []
        query.addQueryItem("id", ids.map(\.asQueryValue).joined(separator: "|"))
        
        // THEN
        XCTAssertEqual(query.asQuery(), "id=3%7C4%7C5")
        XCTAssertEqual(query.asQuery()?.removingPercentEncoding, "id=3|4|5")
    }
    
    // MARK: Style: DeepObject
    
    func testStyleDeepObject() {
        // GIVEN
        let user = User(role: "admin", name: "kean")
        
        // WHEN
        var query: [(String, String?)] = []
        query.addDeepObject("id", user.asQuery)
        
        // THEN
        XCTAssertEqual(query.asQuery(), "id%5Brole%5D=admin&id%5Bname%5D=kean")
        XCTAssertEqual(query.asQuery()?.removingPercentEncoding, "id[role]=admin&id[name]=kean")
    }
}

struct User {
    var role: String
    var name: String
    
    var asQuery: [(String, String?)] {
        var query: [(String, String?)] = []
        query.addQueryItem("role", role)
        query.addQueryItem("name", name)
        return query
    }
}
     
extension Array where Element == (String, String?) {
    func asQuery() -> String? {
        var components = URLComponents()
        components.queryItems = map(URLQueryItem.init)
        return components.percentEncodedQuery
    }
}

// This code is added to Paths.

protocol QueryEncodable {
    var asQueryValue: String { get }
}

extension Int: QueryEncodable {
    var asQueryValue: String { String(self) }
}

extension String: QueryEncodable {
    var asQueryValue: String { self }
}

extension Array where Element == (String, String?) {
    mutating func addQueryItem<T: RawRepresentable>(_ name: String, _ value: T?) where T.RawValue == String {
        addQueryItem(name, value?.rawValue)
    }
    
    mutating func addQueryItem(_ name: String, _ value: QueryEncodable?) {
        guard let value = value?.asQueryValue, !value.isEmpty else { return }
        append((name, value))
    }
    
    mutating func addDeepObject(_ name: String, _ query: [(String, String?)]) {
        for (key, value) in query {
            addQueryItem("\(name)[\(key)]", value)
        }
    }

    var asPercentEncodedQuery: String {
        var components = URLComponents()
        components.queryItems = self.map(URLQueryItem.init)
        return components.percentEncodedQuery ?? ""
    }
    
    // [("role", "admin"), ("name": "kean)] -> "role,admin,name,kean"
    var asCompactQuery: String {
        flatMap { [$0, $1] }.compactMap { $0 }.joined(separator: ",")
    }
}
