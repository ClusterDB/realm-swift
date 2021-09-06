////////////////////////////////////////////////////////////////////////////
//
// Copyright 2021 Realm Inc.
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
// http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
//
////////////////////////////////////////////////////////////////////////////
import Foundation
import Realm

public enum StringOptions {
    case caseInsensitive
    case diacriticInsensitive
}

/// :nodoc:
private enum QueryExpression {
    enum BasicComparision: String {
        case equal = "==" // TODO: @"string1 ==[c] string1"
        case notEqual = "!="
        case lessThan = "<"
        case greaterThan = ">"
        case greaterThenOrEqual = ">="
        case lessThanOrEqual = "<="
        case not = "NOT"
    }

    enum Comparision {
        case between(low: _QueryNumeric, high: _QueryNumeric, closedRange: Bool)
        case contains(_RealmSchemaDiscoverable?) // `IN` operator.
    }

    enum Compound: String {
        case and = "&&"
        case or = "||"
    }

    enum StringSearch {
        case contains(String, Set<StringOptions>?)
        case like(String, Set<StringOptions>?)
        case beginsWith(String, Set<StringOptions>?)
        case endsWith(String, Set<StringOptions>?)
    }

    enum CollectionAggregation: String {
        case min = ".@min"
        case max = ".@max"
        case avg = ".@avg.doubleValue"
        case sum = ".@sum"
        case count = ".@count"
        // Map only
        case allKeys = ".@allKeys"
        case allValues = ".@allValues"
    }

    case keyPath(name: String, isCollection: Bool = false)
    case comparison(Comparision)
    case basicComparison(BasicComparision)
    case compound(Compound)
    case rhs(_RealmSchemaDiscoverable?)
    case subquery(String, String, [Any])
    case stringSearch(StringSearch)
    case collectionAggregation(CollectionAggregation)
}

/**
 `Query` is a class used to create type-safe query predicates.

 With `Query` you are given the ability to create Swift style query expression that will then
 be constructed into an `NSPredicate`. The `Query` class should not be instantiated directly
 and should be only used as a paramater within a closure that takes a query expression as an argument.
 Example:
 ```swift
 public func query(_ query: ((Query<Element>) -> Query<Element>)) -> Results<Element>
 ```

 You would then use the above function like so:
 ```swift
 let results = realm.objects(Person.self).query {
    $0.name == "Foo" || $0.name == "Bar" && $0.age >= 21
 }
 ```

 ## Supported predicate types

 ### Comparisions
 - Equals `==`
 - Not Equals `!=`
 - Greater Than `>`
 - Less Than `<`
 - Greater Than or Equal `>=`
 - Less Than or Equal `<=`
 - Between `.contains(_ range:)`

 ### Collections
 - IN `.contains(_ element:)`
 - Between `.contains(_ range:)`

 ### Compound
 - AND `&&`
 - OR `||`
 */
@dynamicMemberLookup
public struct Query<T: _Persistable> {

    private var tokens: [QueryExpression] = []

    public init() { }
    private init(expression: [QueryExpression]) {
        tokens = expression
    }

    private func append<V>(tokens: [QueryExpression]) -> Query<V> {
        return Query<V>(expression: self.tokens + tokens)
    }

    // MARK: NOT

    public static prefix func ! (_ rhs: Query) -> Query {
        var tokensCopy = rhs.tokens
        tokensCopy.insert(.basicComparison(.not), at: 0)
        return Query(expression: tokensCopy)
    }

    // MARK: Comparable

    public static func == <V>(_ lhs: Query<V>, _ rhs: V) -> Query where V: _QueryComparable {
        return lhs.append(tokens: [.basicComparison(.equal), .rhs(rhs)])
    }

    public static func != <V>(_ lhs: Query<V>, _ rhs: V) -> Query where V: _QueryComparable {
        return lhs.append(tokens: [.basicComparison(.notEqual), .rhs(rhs)])
    }

    // MARK: Numerics

    public static func > <V>(_ lhs: Query<V>, _ rhs: V) -> Query where V: _QueryNumeric {
        return lhs.append(tokens: [.basicComparison(.greaterThan), .rhs(rhs)])
    }

    public static func >= <V>(_ lhs: Query<V>, _ rhs: V) -> Query where V: _QueryNumeric {
        return lhs.append(tokens: [.basicComparison(.greaterThenOrEqual), .rhs(rhs)])
    }

    public static func < <V>(_ lhs: Query<V>, _ rhs: V) -> Query where V: _QueryNumeric {
        return lhs.append(tokens: [.basicComparison(.lessThan), .rhs(rhs)])
    }

    public static func <= <V>(_ lhs: Query<V>, _ rhs: V) -> Query where V: _QueryNumeric {
        return lhs.append(tokens: [.basicComparison(.lessThanOrEqual), .rhs(rhs)])
    }

    // MARK: Compound

    public static func && (_ lhs: Query, _ rhs: Query) -> Query {
        return lhs.append(tokens: [.compound(.and)] + rhs.tokens)
    }

    public static func || (_ lhs: Query, _ rhs: Query) -> Query {
        return lhs.append(tokens: [.compound(.or)] + rhs.tokens)
    }

    // MARK: Subscript

    public subscript<V>(dynamicMember member: KeyPath<T, V>) -> Query<V> where T: ObjectBase {
        let name = _name(for: member)
        return append(tokens: [.keyPath(name: name)])
    }

    public subscript<V: RealmCollectionBase>(dynamicMember member: KeyPath<T, V>) -> Query<V> where T: ObjectBase {
        let name = _name(for: member)
        return append(tokens: [.keyPath(name: name, isCollection: true)])
    }

    // MARK: Query Construction

    public func _constructPredicate(_ isSubquery: Bool = false) -> (String, [Any]) {
        var predicateString: [String] = []
        var arguments: [Any] = []

        func optionsStr(_ options: Set<StringOptions>?) -> String {
            guard let o = options else {
                return ""
            }
            var str = "["
            if o.contains(.caseInsensitive) {
                str += "c"
            }
            if o.contains(.diacriticInsensitive) {
                str += "d"
            }
            str += "]"
            return str
        }

        for (idx, token) in tokens.enumerated() {
            switch token {
            case let .basicComparison(op):
                if idx == 0 {
                    predicateString.append(op.rawValue)
                } else {
                    predicateString.append(" \(op.rawValue)")
                }
            case let .comparison(comp):
                switch comp {
                case let .between(low, high, closedRange):
                    if closedRange {
                        predicateString.append(" BETWEEN {%@, %@}")
                        arguments.append(contentsOf: [low, high])
                    } else if idx > 0, case let .keyPath(name, _) = tokens[idx-1] {
                        predicateString.append(" >= %@")
                        arguments.append(low)
                        predicateString.append(" && \(name) <\(closedRange ? "=" : "") %@")
                        arguments.append(high)
                    } else {
                        throwRealmException("Could not construct .contains(_:) predicate")
                    }
                case let .contains(val):
                    predicateString.insert("%@ IN ", at: predicateString.count-1)
                        arguments.append(val.objCValue)
                }
            case let .compound(comp):
                predicateString.append(" \(comp.rawValue) ")
            case let .keyPath(name, isCollection):
                // For the non verbose subqery
                if isCollection && isSubquery {
                    predicateString.append("$obj")
                    continue
                }
                // Anything below the verbose subquery uses
                var needsDot = false
                if idx > 0, case .keyPath = tokens[idx-1] {
                    needsDot = true
                }
                if needsDot {
                    predicateString.append(".")
                }
                predicateString.append("\(name)")
            case let .stringSearch(s):
                switch s {
                case let .contains(str, options):
                    predicateString.append(" CONTAINS\(optionsStr(options)) %@")
                    arguments.append(str)
                case let .like(str, options):
                    predicateString.append(" LIKE\(optionsStr(options)) %@")
                    arguments.append(str)
                case let .beginsWith(str, options):
                    predicateString.append(" BEGINSWITH\(optionsStr(options)) %@")
                    arguments.append(str)
                case let .endsWith(str, options):
                    predicateString.append(" ENDSWITH\(optionsStr(options)) %@")
                    arguments.append(str)
                }
            case let .rhs(v):
                predicateString.append(" %@")
                    arguments.append(v.objCValue)
            case let .subquery(col, str, args):
                predicateString.append("SUBQUERY(\(col), $obj, \(str)).@count")
                arguments.append(contentsOf: args)
            case let .collectionAggregation(agg):
                predicateString.append(agg.rawValue)
            }
        }

        return (predicateString.joined(), arguments)
    }

    internal var predicate: NSPredicate {
        let predicate = _constructPredicate()
        return NSPredicate(format: predicate.0, argumentArray: predicate.1)
    }

    private func aggregateContains<U: _QueryNumeric, V>(_ lowerBound: U,
                                                        _ upperBound: U,
                                                        isClosedRange: Bool=false) -> Query<V> {
        guard let keyPath = tokens.first else {
            throwRealmException("Could not construct aggregate query, key path is missing.")
        }
        return append(tokens: [.collectionAggregation(.min),
                               .basicComparison(.greaterThenOrEqual),
                               .rhs(lowerBound),
                               .compound(.and),
                               keyPath,
                               .collectionAggregation(.max),
                               .basicComparison(isClosedRange ? .lessThanOrEqual : .lessThan),
                               .rhs(upperBound)])
    }
}

// MARK: OptionalProtocol

extension Query where T: OptionalProtocol {
    public subscript<V>(dynamicMember member: KeyPath<T.Wrapped, V>) -> Query<V> where T.Wrapped: ObjectBase {
        let name = _name(for: member)
        return append(tokens: [.keyPath(name: name)])
    }
}

// MARK: RealmCollection

extension Query where T: RealmCollection {
    public subscript<V>(dynamicMember member: KeyPath<T.Element, V>) -> Query<V> where T.Element: ObjectBase {
        let name = _name(for: member)
        return append(tokens: [.keyPath(name: name)])
    }
}

extension Query where T: RealmCollection, T.Element: _Persistable {
    /// Checks if an element exists in this collection.
    public func contains<V>(_ value: T.Element) -> Query<V> {
        return append(tokens: [.comparison(.contains(value))])
    }
}

extension Query where T: RealmCollection, T.Element: _QueryNumeric {
    /// Checks for all elements in this collection that are within a given range.
    public func contains<V>(_ range: Range<T.Element>) -> Query<V> {
        return aggregateContains(range.lowerBound, range.upperBound)
    }

    /// Checks for all elements in this collection that are within a given range.
    public func contains<V>(_ range: ClosedRange<T.Element>) -> Query<V> {
        return aggregateContains(range.lowerBound, range.upperBound, isClosedRange: true)
    }
}

extension Query where T: RealmCollection, T.Element: OptionalProtocol, T.Element.Wrapped: _QueryNumeric {
    /// Checks for all elements in this collection that are within a given range.
    public func contains<V>(_ range: Range<T.Element.Wrapped>) -> Query<V> {
        return aggregateContains(range.lowerBound, range.upperBound)
    }

    /// Checks for all elements in this collection that are within a given range.
    public func contains<V>(_ range: ClosedRange<T.Element.Wrapped>) -> Query<V> {
        return aggregateContains(range.lowerBound, range.upperBound, isClosedRange: true)
    }
}

// MARK: RealmKeyedCollection

extension Query where T: RealmKeyedCollection, T.Key: _Persistable, T.Value: _Persistable {

    public func contains<V>(_ value: T.Value) -> Query<V> {
        return append(tokens: [.comparison(.contains(value))])
    }

    public var values: Query<T.Value> {
        return append(tokens: [.collectionAggregation(.allValues)])
    }

    public subscript(member: T.Key) -> Query<T.Value> {
        fatalError()
    }
}

extension Query where T: RealmKeyedCollection, T.Value: OptionalProtocol, T.Value.Wrapped: _Persistable {
    public var values: Query<T.Value.Wrapped> {
        return append(tokens: [.collectionAggregation(.allValues)])
    }
}

extension Query where T: RealmKeyedCollection, T.Value: OptionalProtocol, T.Value.Wrapped: ObjectBase {
    public subscript<V>(dynamicMember member: KeyPath<T.Value.Wrapped, V>) -> Query<V> where T.Value.Wrapped: ObjectBase {
        let name = _name(for: member)
        return append(tokens: [.collectionAggregation(.allValues), .keyPath(name: name)])
    }
}

extension Query where T: RealmKeyedCollection, T.Key == String {
    public var keys: Query<String> {
        return append(tokens: [.collectionAggregation(.allKeys)])
    }
}

extension Query where T: RealmKeyedCollection, T.Value: _QueryNumeric {
    /// Checks for all elements in this collection that are within a given range.
    public func contains<V>(_ range: Range<T.Value>) -> Query<V> {
        return aggregateContains(range.lowerBound, range.upperBound)
    }

    /// Checks for all elements in this collection that are within a given range.
    public func contains<V>(_ range: ClosedRange<T.Value>) -> Query<V> {
        return aggregateContains(range.lowerBound, range.upperBound, isClosedRange: true)
    }
}

extension Query where T: RealmKeyedCollection, T.Value: OptionalProtocol, T.Value.Wrapped: _QueryNumeric {
    /// Checks for all elements in this collection that are within a given range.
    public func contains<V>(_ range: Range<T.Value.Wrapped>) -> Query<V> {
        return aggregateContains(range.lowerBound, range.upperBound)
    }

    /// Checks for all elements in this collection that are within a given range.
    public func contains<V>(_ range: ClosedRange<T.Value.Wrapped>) -> Query<V> {
        return aggregateContains(range.lowerBound, range.upperBound, isClosedRange: true)
    }
}


// MARK: String

extension Query where T == String {
    public func like<V>(_ value: String, caseInsensitive: Bool = false) -> Query<V> {
        return append(tokens: [.stringSearch(.like(value, caseInsensitive ? [.caseInsensitive] : nil))])
    }

    public func contains<V>(_ value: String, options: Set<StringOptions>? = nil) -> Query<V> {
        return append(tokens: [.stringSearch(.contains(value, options))])
    }

    public func starts<V>(with value: String, options: Set<StringOptions>? = nil) -> Query<V> {
        return append(tokens: [.stringSearch(.beginsWith(value, options))])
    }

    public func ends<V>(with value: String, options: Set<StringOptions>? = nil) -> Query<V> {
        return append(tokens: [.stringSearch(.endsWith(value, options))])
    }
}

// MARK: PersistableEnum

extension Query where T: PersistableEnum, T.RawValue: _Persistable {
    public static func == <V>(_ lhs: Query<T>, _ rhs: T) -> Query<V> {
        return lhs.append(tokens: [.basicComparison(.equal), .rhs(rhs.rawValue)])
    }

    public static func != <V>(_ lhs: Query<T>, _ rhs: T) -> Query<V> {
        return lhs.append(tokens: [.basicComparison(.notEqual), .rhs(rhs.rawValue)])
    }

    public static func > <V>(_ lhs: Query<T>, _ rhs: T) -> Query<V> where T.RawValue: _QueryNumeric {
        return lhs.append(tokens: [.basicComparison(.greaterThan), .rhs(rhs.rawValue)])
    }

    public static func >= <V>(_ lhs: Query<T>, _ rhs: T) -> Query<V> where T.RawValue: _QueryNumeric {
        return lhs.append(tokens: [.basicComparison(.greaterThenOrEqual), .rhs(rhs.rawValue)])
    }

    public static func < <V>(_ lhs: Query<T>, _ rhs: T) -> Query<V> where T.RawValue: _QueryNumeric {
        return lhs.append(tokens: [.basicComparison(.lessThan), .rhs(rhs.rawValue)])
    }

    public static func <= <V>(_ lhs: Query<T>, _ rhs: T) -> Query<V> where T.RawValue: _QueryNumeric {
        return lhs.append(tokens: [.basicComparison(.lessThanOrEqual), .rhs(rhs.rawValue)])
    }
}

// MARK: Optional

extension Query where T: OptionalProtocol,
                      T.Wrapped: PersistableEnum,
                      T.Wrapped.RawValue: _QueryComparable,
                      T.Wrapped.RawValue: _RealmSchemaDiscoverable {
    public static func == <V>(_ lhs: Query<T>, _ rhs: T) -> Query<V> {
        if case Optional<Any>.none = rhs as Any {
            return lhs.append(tokens: [.basicComparison(.equal), .rhs(nil)])
        } else {
            return lhs.append(tokens: [.basicComparison(.equal), .rhs(rhs._rlmInferWrappedType().rawValue)])
        }
    }

    public static func != <V>(_ lhs: Query<T>, _ rhs: T) -> Query<V> {
        if case Optional<Any>.none = rhs as Any {
            return lhs.append(tokens: [.basicComparison(.notEqual), .rhs(nil)])
        } else {
            return lhs.append(tokens: [.basicComparison(.notEqual), .rhs(rhs._rlmInferWrappedType().rawValue)])
        }
    }
}

extension Query where T: OptionalProtocol, T.Wrapped: PersistableEnum, T.Wrapped.RawValue: _QueryNumeric {

    public static func > <V>(_ lhs: Query<T>, _ rhs: T) -> Query<V> {
        if case Optional<Any>.none = rhs as Any {
            return lhs.append(tokens: [.basicComparison(.greaterThan), .rhs(nil)])
        } else {
            return lhs.append(tokens: [.basicComparison(.greaterThan), .rhs(rhs._rlmInferWrappedType().rawValue)])
        }
    }

    public static func >= <V>(_ lhs: Query<T>, _ rhs: T) -> Query<V> {
        if case Optional<Any>.none = rhs as Any {
            return lhs.append(tokens: [.basicComparison(.greaterThenOrEqual), .rhs(nil)])
        } else {
            return lhs.append(tokens: [.basicComparison(.greaterThenOrEqual), .rhs(rhs._rlmInferWrappedType().rawValue)])
        }
    }

    public static func < <V>(_ lhs: Query<T>, _ rhs: T) -> Query<V> {
        if case Optional<Any>.none = rhs as Any {
            return lhs.append(tokens: [.basicComparison(.lessThan), .rhs(nil)])
        } else {
            return lhs.append(tokens: [.basicComparison(.lessThan), .rhs(rhs._rlmInferWrappedType().rawValue)])
        }
    }

    public static func <= <V>(_ lhs: Query<T>, _ rhs: T) -> Query<V> {
        if case Optional<Any>.none = rhs as Any {
            return lhs.append(tokens: [.basicComparison(.lessThanOrEqual), .rhs(nil)])
        } else {
            return lhs.append(tokens: [.basicComparison(.lessThanOrEqual), .rhs(rhs._rlmInferWrappedType().rawValue)])
        }
    }
}

// MARK: _QueryNumeric

extension Query where T: _QueryNumeric {
    /// Checks for all elements in this collection that are within a given range.
    public func contains<V>(_ range: Range<T>) -> Query<V> {
        return append(tokens: [.comparison(.between(low: range.lowerBound,
                                                    high: range.upperBound, closedRange: false))])
    }

    /// Checks for all elements in this collection that are within a given range.
    public func contains<V>(_ range: ClosedRange<T>) -> Query<V> {
        return append(tokens: [.comparison(.between(low: range.lowerBound,
                                                    high: range.upperBound, closedRange: true))])
    }
}

extension Query where T: OptionalProtocol, T.Wrapped: _QueryNumeric {
    /// Checks for all elements in this collection that are within a given range.
    public func contains<V>(_ range: Range<T.Wrapped>) -> Query<V> {
        return append(tokens: [.comparison(.between(low: range.lowerBound,
                                                    high: range.upperBound, closedRange: false))])
    }

    /// Checks for all elements in this collection that are within a given range.
    public func contains<V>(_ range: ClosedRange<T.Wrapped>) -> Query<V> {
        return append(tokens: [.comparison(.between(low: range.lowerBound,
                                                    high: range.upperBound, closedRange: true))])
    }
}

// MARK: Bool

extension Query where T == Bool {
    /// Completes a subquery expression.
    /// ```
    /// ($0.myCollection.age >= 21).count > 0
    /// ```
    public func count() -> Query<Int> {
        let collections = Set(tokens.filter {
            if case let .keyPath(_, isCollection) = $0 {
                return isCollection ? true : false
            }
            return false
        }.map { kp -> String in
            if case let .keyPath(name, _) = kp {
                return name
            }
            fatalError()
        })

        if collections.count > 1 {
            throwRealmException("Subquery predicates will only work on one collection at a time, split your query up.")
        }
        let queryStr = _constructPredicate(true)
        return append(tokens: [.subquery(collections.first!, queryStr.0, queryStr.1)])
    }
}

extension Results where Element: Object {
    public func query(_ query: ((Query<Element>) -> Query<Element>)) -> Results<Element> {
        let predicate = query(Query()).predicate
        return filter(predicate)
    }
}


/// Tag protocol for all numeric types.
public protocol _QueryNumeric: _RealmSchemaDiscoverable { }
extension Int: _QueryNumeric { }
extension Int8: _QueryNumeric { }
extension Int16: _QueryNumeric { }
extension Int32: _QueryNumeric { }
extension Int64: _QueryNumeric { }
extension Float: _QueryNumeric { }
extension Double: _QueryNumeric { }
extension Decimal128: _QueryNumeric { }
extension Date: _QueryNumeric { }
extension AnyRealmValue: _QueryNumeric { }
extension Optional: _QueryNumeric where Wrapped: _QueryNumeric { }

/// Tag protocol for all types that are compatible with `Query`.
public protocol _QueryComparable { }
extension Bool: _QueryComparable { }
extension Int: _QueryComparable { }
extension Int8: _QueryComparable { }
extension Int16: _QueryComparable { }
extension Int32: _QueryComparable { }
extension Int64: _QueryComparable { }
extension Float: _QueryComparable { }
extension Double: _QueryComparable { }
extension Decimal128: _QueryComparable { }
extension Date: _QueryComparable { }
extension Data: _QueryComparable { }
extension UUID: _QueryComparable { }
extension ObjectId: _QueryComparable { }
extension String: _QueryComparable { }
extension AnyRealmValue: _QueryComparable { }
extension ObjectBase: _QueryComparable { }
extension Optional: _QueryComparable where Wrapped: _QueryComparable { }
