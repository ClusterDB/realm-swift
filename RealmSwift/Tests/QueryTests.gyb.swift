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
import XCTest
@testable import RealmSwift

%{
    # How to use:
    #
    # $ wget https://github.com/apple/swift/raw/main/utils/gyb
    # $ wget https://github.com/apple/swift/raw/main/utils/gyb.py
    # $ chmod +x gyb
    #
    # ./YOUR_GYB_LOCATION/gyb --line-directive '' -o QueryTests2.swift QueryTests.gyb.swift
}%
%{
    import sys
    reload(sys)
    sys.setdefaultencoding('utf-8')

    class Property:
        def __init__(self, colName, values, type, category, enumName=None):
            self.colName = colName
            self.values = values
            self.type = type
            self.category = category
            self.enumName = enumName

    properties = [
        Property('boolCol', ['true', 'false'], 'Bool', 'bool'),
        Property('intCol', [5, 6, 7], 'Int', 'numeric'),
        Property('int8Col', ['Int8(8)', 'Int8(9)', 'Int8(10)'], 'Int8', 'numeric'),
        Property('int16Col', ['Int16(16)', 'Int16(17)', 'Int16(18)'], 'Int16', 'numeric'),
        Property('int32Col', ['Int32(32)', 'Int32(33)', 'Int32(34)'], 'Int32', 'numeric'),
        Property('int64Col', ['Int64(64)', 'Int64(65)', 'Int64(66)'], 'Int64', 'numeric'),
        Property('floatCol', ['Float(5.55444333)', 'Float(6.55444333)', 'Float(7.55444333)'], 'Float', 'numeric'),
        Property('doubleCol', [5.55444333, 6.55444333, 7.55444333], 'Double', 'numeric'),
        Property('stringCol', ['"Foo"', '"Foó"', '"foo"'], 'String', 'string'),
        Property('binaryCol', ['Data(count: 64)', 'Data(count: 128)'], 'Data', 'binary'),
        Property('dateCol', ['Date(timeIntervalSince1970: 1000000)', 'Date(timeIntervalSince1970: 2000000)', 'Date(timeIntervalSince1970: 3000000)'], 'Date', 'numeric'),
        Property('decimalCol', ['Decimal128(123.456)', 'Decimal128(234.456)', 'Decimal128(345.456)'], 'Decimal128', 'numeric'),
        Property('objectIdCol', ['ObjectId("61184062c1d8f096a3695046")', 'ObjectId("61184062c1d8f096a3695045")'], 'ObjectId', 'objectId'),
        Property('intEnumCol', ['.value1', '.value2'], 'Int', 'numeric', 'ModernIntEnum.value2.rawValue'),
        Property('stringEnumCol', ['.value1', '.value2'], 'String', 'string', 'ModernStringEnum.value2.rawValue'),
        Property('uuidCol', ['UUID(uuidString: "33041937-05b2-464a-98ad-3910cbe0d09e")!', 'UUID(uuidString: "33041937-05b2-464a-98ad-3910cbe0d09f")!'], 'UUID', 'uuid')
    ]

    optProperties = [
        Property('optBoolCol', ['true', 'false'], 'Bool?', 'bool'),
        Property('optIntCol', [5, 6, 7], 'Int?', 'numeric'),
        Property('optInt8Col', ['Int8(8)', 'Int8(9)', 'Int8(10)'], 'Int8?', 'numeric'),
        Property('optInt16Col', ['Int16(16)', 'Int16(17)', 'Int16(18)'], 'Int16?', 'numeric'),
        Property('optInt32Col', ['Int32(32)', 'Int32(33)', 'Int32(34)'], 'Int32?', 'numeric'),
        Property('optInt64Col', ['Int64(64)', 'Int64(65)', 'Int64(66)'], 'Int64?', 'numeric'),
        Property('optFloatCol', ['Float(5.55444333)', 'Float(6.55444333)', 'Float(7.55444333)'], 'Float?', 'numeric'),
        Property('optDoubleCol', [5.55444333, 6.55444333, 7.55444333], 'Double?', 'numeric'),
        Property('optStringCol', ['"Foo"', '"Foó"', '"foo"'], 'String?', 'string'),
        Property('optBinaryCol', ['Data(count: 64)', 'Data(count: 128)'], 'Data?', 'binary'),
        Property('optDateCol', ['Date(timeIntervalSince1970: 1000000)', 'Date(timeIntervalSince1970: 2000000)', 'Date(timeIntervalSince1970: 3000000)'], 'Date?', 'numeric'),
        Property('optDecimalCol', ['Decimal128(123.456)', 'Decimal128(234.456)', 'Decimal128(345.456)'], 'Decimal128?', 'numeric'),
        Property('optObjectIdCol', ['ObjectId("61184062c1d8f096a3695046")', 'ObjectId("61184062c1d8f096a3695045")'], 'ObjectId?', 'objectId'),
        Property('optIntEnumCol', ['.value1', '.value2'], 'Int?', 'numeric', 'ModernIntEnum.value2.rawValue'),
        Property('optStringEnumCol', ['.value1', '.value2'], 'String?', 'string', 'ModernStringEnum.value2.rawValue'),
        Property('optUuidCol', ['UUID(uuidString: "33041937-05b2-464a-98ad-3910cbe0d09e")!', 'UUID(uuidString: "33041937-05b2-464a-98ad-3910cbe0d09f")!'], 'UUID?', 'uuid')
    ]

    listProperties = [
        Property('arrayBool', ['true', 'true', 'false'], 'Bool', 'bool'),
        Property('arrayInt', [1, 2, 3], 'Int', 'numeric'),
        Property('arrayInt8', ['Int8(8)', 'Int8(9)', 'Int8(10)'], 'Int8', 'numeric'),
        Property('arrayInt16', ['Int16(16)', 'Int16(17)', 'Int16(18)'], 'Int16', 'numeric'),
        Property('arrayInt32', ['Int32(32)', 'Int32(33)', 'Int32(34)'], 'Int32', 'numeric'),
        Property('arrayInt64', ['Int64(64)', 'Int64(65)', 'Int64(66)'], 'Int64', 'numeric'),
        Property('arrayFloat', ['Float(5.55444333)', 'Float(6.55444333)', 'Float(7.55444333)'], 'Float', 'numeric'),
        Property('arrayDouble', [123.456, 234.456, 345.567], 'Double', 'numeric'),
        Property('arrayString', ['"Foo"', '"Bar"', '"Baz"'], 'String', 'string'),
        Property('arrayBinary', ['Data(count: 64)', 'Data(count: 128)', 'Data(count: 256)'], 'Data', 'binary'),
        Property('arrayDate', ['Date(timeIntervalSince1970: 1000000)', 'Date(timeIntervalSince1970: 2000000)', 'Date(timeIntervalSince1970: 3000000)'], 'Date', 'numeric'),
        Property('arrayDecimal', ['Decimal128(123.456)', 'Decimal128(456.789)', 'Decimal128(963.852)'], 'Decimal128', 'numeric'),
        Property('arrayObjectId', ['ObjectId("61184062c1d8f096a3695046")', 'ObjectId("61184062c1d8f096a3695045")', 'ObjectId("61184062c1d8f096a3695044")'], 'ObjectId', 'objectId'),
        Property('arrayUuid', ['UUID(uuidString: "33041937-05b2-464a-98ad-3910cbe0d09e")!', 'UUID(uuidString: "33041937-05b2-464a-98ad-3910cbe0d09f")!', 'UUID(uuidString: "33041937-05b2-464a-98ad-3910cbe0d08e")!'], 'UUID', 'uuid'),
        Property('arrayAny', ['AnyRealmValue.objectId(ObjectId("61184062c1d8f096a3695046"))', 'AnyRealmValue.string("Hello")', 'AnyRealmValue.int(123)'], 'AnyRealmValue', 'any'),
    ]

    optListProperties = [
        Property('arrayOptBool', ['true', 'true', 'false'], 'Bool?', 'bool'),
        Property('arrayOptInt', [1, 2, 3], 'Int?', 'numeric'),
        Property('arrayOptInt8', ['Int8(8)', 'Int8(9)', 'Int8(10)'], 'Int8?', 'numeric'),
        Property('arrayOptInt16', ['Int16(16)', 'Int16(17)', 'Int16(18)'], 'Int16?', 'numeric'),
        Property('arrayOptInt32', ['Int32(32)', 'Int32(33)', 'Int32(34)'], 'Int32?', 'numeric'),
        Property('arrayOptInt64', ['Int64(64)', 'Int64(65)', 'Int64(66)'], 'Int64?', 'numeric'),
        Property('arrayOptFloat', ['Float(5.55444333)', 'Float(6.55444333)', 'Float(7.55444333)'], 'Float?', 'numeric'),
        Property('arrayOptDouble', [123.456, 234.456, 345.567], 'Double?', 'numeric'),
        Property('arrayOptString', ['"Foo"', '"Bar"', '"Baz"'], 'String?', 'string'),
        Property('arrayOptBinary', ['Data(count: 64)', 'Data(count: 128)', 'Data(count: 256)'], 'Data?', 'binary'),
        Property('arrayOptDate', ['Date(timeIntervalSince1970: 1000000)', 'Date(timeIntervalSince1970: 2000000)', 'Date(timeIntervalSince1970: 3000000)'], 'Date?', 'numeric'),
        Property('arrayOptDecimal', ['Decimal128(123.456)', 'Decimal128(456.789)', 'Decimal128(963.852)'], 'Decimal128?', 'numeric'),
        Property('arrayOptUuid', ['UUID(uuidString: "33041937-05b2-464a-98ad-3910cbe0d09e")!', 'UUID(uuidString: "33041937-05b2-464a-98ad-3910cbe0d09f")!', 'UUID(uuidString: "33041937-05b2-464a-98ad-3910cbe0d08e")!'], 'UUID?', 'uuid'),
        Property('arrayOptObjectId', ['ObjectId("61184062c1d8f096a3695046")', 'ObjectId("61184062c1d8f096a3695045")', 'ObjectId("61184062c1d8f096a3695044")'], 'ObjectId?', 'objectId'),
    ]

    setProperties = [
        Property('setBool', ['true', 'true', 'false'], 'Bool', 'bool'),
        Property('setInt', [1, 2, 3], 'Int', 'numeric'),
        Property('setInt8', ['Int8(8)', 'Int8(9)', 'Int8(10)'], 'Int8', 'numeric'),
        Property('setInt16', ['Int16(16)', 'Int16(17)', 'Int16(18)'], 'Int16', 'numeric'),
        Property('setInt32', ['Int32(32)', 'Int32(33)', 'Int32(34)'], 'Int32', 'numeric'),
        Property('setInt64', ['Int64(64)', 'Int64(65)', 'Int64(66)'], 'Int64', 'numeric'),
        Property('setFloat', ['Float(5.55444333)', 'Float(6.55444333)', 'Float(7.55444333)'], 'Float', 'numeric'),
        Property('setDouble', [123.456, 234.456, 345.567], 'Double', 'numeric'),
        Property('setString', ['"Foo"', '"Bar"', '"Baz"'], 'String', 'string'),
        Property('setBinary', ['Data(count: 64)', 'Data(count: 128)', 'Data(count: 256)'], 'Data', 'binary'),
        Property('setDate', ['Date(timeIntervalSince1970: 1000000)', 'Date(timeIntervalSince1970: 2000000)', 'Date(timeIntervalSince1970: 3000000)'], 'Date', 'numeric'),
        Property('setDecimal', ['Decimal128(123.456)', 'Decimal128(456.789)', 'Decimal128(963.852)'], 'Decimal128', 'numeric'),
        Property('setObjectId', ['ObjectId("61184062c1d8f096a3695046")', 'ObjectId("61184062c1d8f096a3695045")', 'ObjectId("61184062c1d8f096a3695044")'], 'ObjectId', 'objectId'),
        Property('setUuid', ['UUID(uuidString: "33041937-05b2-464a-98ad-3910cbe0d09e")!', 'UUID(uuidString: "33041937-05b2-464a-98ad-3910cbe0d09f")!', 'UUID(uuidString: "33041937-05b2-464a-98ad-3910cbe0d08e")!'], 'UUID', 'uuid'),
        Property('setAny', ['AnyRealmValue.objectId(ObjectId("61184062c1d8f096a3695046"))', 'AnyRealmValue.string("Hello")', 'AnyRealmValue.int(123)'], 'AnyRealmValue', 'any'),
    ]

    optSetProperties = [
        Property('setOptBool', ['true', 'true', 'false'], 'Bool?', 'bool'),
        Property('setOptInt', [1, 2, 3], 'Int?', 'numeric'),
        Property('setOptInt8', ['Int8(8)', 'Int8(9)', 'Int8(10)'], 'Int8?', 'numeric'),
        Property('setOptInt16', ['Int16(16)', 'Int16(17)', 'Int16(18)'], 'Int16?', 'numeric'),
        Property('setOptInt32', ['Int32(32)', 'Int32(33)', 'Int32(34)'], 'Int32?', 'numeric'),
        Property('setOptInt64', ['Int64(64)', 'Int64(65)', 'Int64(66)'], 'Int64?', 'numeric'),
        Property('setOptFloat', ['Float(5.55444333)', 'Float(6.55444333)', 'Float(7.55444333)'], 'Float?', 'numeric'),
        Property('setOptDouble', [123.456, 234.456, 345.567], 'Double?', 'numeric'),
        Property('setOptString', ['"Foo"', '"Bar"', '"Baz"'], 'String?', 'string'),
        Property('setOptBinary', ['Data(count: 64)', 'Data(count: 128)', 'Data(count: 256)'], 'Data?', 'binary'),
        Property('setOptDate', ['Date(timeIntervalSince1970: 1000000)', 'Date(timeIntervalSince1970: 2000000)', 'Date(timeIntervalSince1970: 3000000)'], 'Date?', 'numeric'),
        Property('setOptDecimal', ['Decimal128(123.456)', 'Decimal128(456.789)', 'Decimal128(963.852)'], 'Decimal128?', 'numeric'),
        Property('setOptUuid', ['UUID(uuidString: "33041937-05b2-464a-98ad-3910cbe0d09e")!', 'UUID(uuidString: "33041937-05b2-464a-98ad-3910cbe0d09f")!', 'UUID(uuidString: "33041937-05b2-464a-98ad-3910cbe0d08e")!'], 'UUID?', 'uuid'),
        Property('setOptObjectId', ['ObjectId("61184062c1d8f096a3695046")', 'ObjectId("61184062c1d8f096a3695045")', 'ObjectId("61184062c1d8f096a3695044")'], 'ObjectId?', 'objectId'),
    ]

    anyRealmValues = [
        ('.none', 'NSNull()', 'null'),
        ('.int(123)', '123', 'numeric'),
        ('.bool(true)', 'true', 'bool'),
        ('.float(123.456)', 'Float(123.456)', 'numeric'),
        ('.double(123.456)', '123.456', 'numeric'),
        ('.string("FooBar")', '"FooBar"', 'string'),
        ('.data(Data(count: 64))', 'Data(count: 64)', 'binary'),
        ('.date(Date(timeIntervalSince1970: 1000000))', 'Date(timeIntervalSince1970: 1000000)', 'numeric'),
        ('.object(circleObject)', 'circleObject', 'object'),
        ('.objectId(ObjectId("61184062c1d8f096a3695046"))', 'ObjectId("61184062c1d8f096a3695046")', 'objectId'),
        ('.decimal128(123.456)', 'Decimal128(123.456)', 'numeric'),
        ('.uuid(UUID(uuidString: "33041937-05b2-464a-98ad-3910cbe0d09e")!)', 'UUID(uuidString: "33041937-05b2-464a-98ad-3910cbe0d09e")!', 'uuid'),
    ]
}%
/// This file is generated from a template. Do not edit directly.
class QueryTests_: TestCase {

    private func objects() -> Results<ModernAllTypesObject> {
        realmWithTestPath().objects(ModernAllTypesObject.self)
    }

    private func setAnyRealmValueCol(with value: AnyRealmValue, object: ModernAllTypesObject) {
        let realm = realmWithTestPath()
        try! realm.write {
            object.anyCol = value
        }
    }

    private var circleObject: ModernCircleObject {
        let realm = realmWithTestPath()
        if let object = realm.objects(ModernCircleObject.self).first {
            return object
        } else {
            let object = ModernCircleObject()
            try! realm.write {
                realm.add(object)
            }
            return object
        }
    }

    override func setUp() {
        let realm = realmWithTestPath()
        try! realm.write {
            let object = ModernAllTypesObject()

            % for property in properties + optProperties:
            object.${property.colName} = ${property.values[1]}
            % end

            % for property in listProperties + optListProperties:
            object.${property.colName}.append(objectsIn: [${property.values[0]}, ${property.values[1]}])
            % end

            % for property in setProperties + optSetProperties:
            object.${property.colName}.insert(objectsIn: [${property.values[0]}, ${property.values[1]}])
            % end

            realm.add(object)
        }
    }

    private func assertQuery<T: Equatable>(predicate: String,
                                           values: [T],
                                           expectedCount: Int,
                                           _ query: ((Query<ModernAllTypesObject>) -> Query<ModernAllTypesObject>)) {
        let results = objects().query(query)
        XCTAssertEqual(results.count, expectedCount)

        let constructedPredicate = query(Query<ModernAllTypesObject>()).constructPredicate()
        XCTAssertEqual(constructedPredicate.0,
                       predicate)

        for (e1, e2) in zip(constructedPredicate.1, values) {
            if let e1 = e1 as? Object, let e2 = e2 as? Object {
                assertEqual(e1, e2)
            } else {
                XCTAssertEqual(e1 as! T, e2)
            }
        }
    }

    func testEquals() {
        % for property in properties:

        // ${property.colName}
        % if property.enumName != None:
        assertQuery(predicate: "${property.colName} == %@", values: [${property.enumName}], expectedCount: 1) {
            $0.${property.colName} == ${property.values[1]}
        }
        % else:
        assertQuery(predicate: "${property.colName} == %@", values: [${property.values[1]}], expectedCount: 1) {
            $0.${property.colName} == ${property.values[1]}
        }
        % end
        % end
    }


    func testEqualsOptional() {
        % for property in optProperties:
        // ${property.colName}

        % if property.enumName != None:
        assertQuery(predicate: "${property.colName} == %@", values: [${property.enumName}], expectedCount: 1) {
            $0.${property.colName} == ${property.values[1]}
        }
        % else:
        assertQuery(predicate: "${property.colName} == %@", values: [${property.values[1]}], expectedCount: 1) {
            $0.${property.colName} == ${property.values[1]}
        }
        % end
        % end

        // Test for `nil`
        % for property in optProperties:

        // ${property.colName}
        assertQuery(predicate: "${property.colName} == %@", values: [NSNull()], expectedCount: 0) {
            $0.${property.colName} == nil
        }
        % end
    }

    func testEqualAnyRealmValue() {
        % for value in anyRealmValues:

        setAnyRealmValueCol(with: AnyRealmValue${value[0]}, object: objects()[0])
        assertQuery(predicate: "anyCol == %@", values: [${value[1]}], expectedCount: 1) {
            $0.anyCol == ${value[0]}
        }
        % end
    }

    func testEqualObject() {
        let nestedObject = ModernAllTypesObject()
        let object = objects().first!
        let realm = realmWithTestPath()
        try! realm.write {
            object.objectCol = nestedObject
        }
        assertQuery(predicate: "objectCol == %@", values: [nestedObject], expectedCount: 1) {
            $0.objectCol == nestedObject
        }
    }

    func testEqualEmbeddedObject() {
        let object = ModernEmbeddedParentObject()
        let nestedObject = ModernEmbeddedTreeObject1()
        nestedObject.value = 123
        object.object = nestedObject
        let realm = realmWithTestPath()
        try! realm.write {
            realm.add(object)
        }

        let result1 = realm.objects(ModernEmbeddedParentObject.self).query {
            $0.object == nestedObject
        }
        XCTAssertEqual(result1.count, 1)

        let nestedObject2 = ModernEmbeddedTreeObject1()
        nestedObject2.value = 123
        let result2 = realm.objects(ModernEmbeddedParentObject.self).query {
            $0.object == nestedObject2
        }
        XCTAssertEqual(result2.count, 0)
    }

    func testNotEquals() {
        % for property in properties:
        // ${property.colName}

        % if property.enumName != None:
        assertQuery(predicate: "${property.colName} != %@", values: [${property.enumName}], expectedCount: 0) {
            $0.${property.colName} != ${property.values[1]}
        }
        % else:
        assertQuery(predicate: "${property.colName} != %@", values: [${property.values[1]}], expectedCount: 0) {
            $0.${property.colName} != ${property.values[1]}
        }
        % end
        % end
    }

    func testNotEqualsOptional() {
        % for property in optProperties:
        // ${property.colName}

        % if property.enumName != None:
        assertQuery(predicate: "${property.colName} != %@", values: [${property.enumName}], expectedCount: 0) {
            $0.${property.colName} != ${property.values[1]}
        }
        % else:
        assertQuery(predicate: "${property.colName} != %@", values: [${property.values[1]}], expectedCount: 0) {
            $0.${property.colName} != ${property.values[1]}
        }
        % end
        % end

        // Test for `nil`
        % for property in optProperties:

        // ${property.colName}
        assertQuery(predicate: "${property.colName} != %@", values: [NSNull()], expectedCount: 1) {
            $0.${property.colName} != nil
        }
        % end
    }

    func testNotEqualAnyRealmValue() {
        % for value in anyRealmValues:
        setAnyRealmValueCol(with: AnyRealmValue${value[0]}, object: objects()[0])
        assertQuery(predicate: "anyCol != %@", values: [${value[1]}], expectedCount: 0) {
            $0.anyCol != ${value[0]}
        }
        % end
    }

    func testNotEqualObject() {
        let nestedObject = ModernAllTypesObject()
        let object = objects().first!
        let realm = realmWithTestPath()
        try! realm.write {
            object.objectCol = nestedObject
        }
        // Count will be one because nestedObject.objectCol will be nil
        assertQuery(predicate: "objectCol != %@", values: [nestedObject], expectedCount: 1) {
            $0.objectCol != nestedObject
        }
    }

    func testNotEqualEmbeddedObject() {
        let object = ModernEmbeddedParentObject()
        let nestedObject = ModernEmbeddedTreeObject1()
        nestedObject.value = 123
        object.object = nestedObject
        let realm = realmWithTestPath()
        try! realm.write {
            realm.add(object)
        }

        let result1 = realm.objects(ModernEmbeddedParentObject.self).query {
            $0.object != nestedObject
        }
        XCTAssertEqual(result1.count, 0)

        let nestedObject2 = ModernEmbeddedTreeObject1()
        nestedObject2.value = 123
        let result2 = realm.objects(ModernEmbeddedParentObject.self).query {
            $0.object != nestedObject2
        }
        XCTAssertEqual(result2.count, 1)
    }

    func testGreaterThan() {
        % for property in properties:
        % if property.enumName != None and property.category == 'numeric':
        // ${property.colName}
        assertQuery(predicate: "${property.colName} > %@", values: [${property.enumName}], expectedCount: 0) {
            $0.${property.colName} > ${property.values[1]}
        }
        assertQuery(predicate: "${property.colName} >= %@", values: [${property.enumName}], expectedCount: 1) {
            $0.${property.colName} >= ${property.values[1]}
        }
        % elif property.category == 'numeric':
        // ${property.colName}
        assertQuery(predicate: "${property.colName} > %@", values: [${property.values[1]}], expectedCount: 0) {
            $0.${property.colName} > ${property.values[1]}
        }
        assertQuery(predicate: "${property.colName} >= %@", values: [${property.values[1]}], expectedCount: 1) {
            $0.${property.colName} >= ${property.values[1]}
        }
        % end
        % end
    }

    func testGreaterThanOptional() {
        % for property in optProperties:
        % if property.enumName != None and property.category == 'numeric':
        // ${property.colName}
        assertQuery(predicate: "${property.colName} > %@", values: [${property.enumName}], expectedCount: 0) {
            $0.${property.colName} > ${property.values[1]}
        }
        assertQuery(predicate: "${property.colName} >= %@", values: [${property.enumName}], expectedCount: 1) {
            $0.${property.colName} >= ${property.values[1]}
        }
        % elif property.category == 'numeric':
        // ${property.colName}
        assertQuery(predicate: "${property.colName} > %@", values: [${property.values[1]}], expectedCount: 0) {
            $0.${property.colName} > ${property.values[1]}
        }
        assertQuery(predicate: "${property.colName} >= %@", values: [${property.values[1]}], expectedCount: 1) {
            $0.${property.colName} >= ${property.values[1]}
        }
        % end
        % end

        // Test for `nil`
        % for property in optProperties:
        % if property.enumName != None and property.category == 'numeric':
        // ${property.colName}
        assertQuery(predicate: "${property.colName} > %@", values: [NSNull()], expectedCount: 0) {
            $0.${property.colName} > nil
        }
        assertQuery(predicate: "${property.colName} >= %@", values: [NSNull()], expectedCount: 0) {
            $0.${property.colName} >= nil
        }
        % elif property.category == 'numeric':
        // ${property.colName}
        assertQuery(predicate: "${property.colName} > %@", values: [NSNull()], expectedCount: 0) {
            $0.${property.colName} > nil
        }
        assertQuery(predicate: "${property.colName} >= %@", values: [NSNull()], expectedCount: 0) {
            $0.${property.colName} >= nil
        }
        % end
        % end
    }

    func testGreaterThanAnyRealmValue() {
        % for value in anyRealmValues:
        % if value[2] == 'numeric':
        setAnyRealmValueCol(with: AnyRealmValue${value[0]}, object: objects()[0])
        assertQuery(predicate: "anyCol > %@", values: [${value[1]}], expectedCount: 0) {
            $0.anyCol > ${value[0]}
        }
        assertQuery(predicate: "anyCol >= %@", values: [${value[1]}], expectedCount: 1) {
            $0.anyCol >= ${value[0]}
        }
        % end
        % end
    }

    func testLessThan() {
        % for property in properties:
        % if property.enumName != None and property.category == 'numeric':
        // ${property.colName}
        assertQuery(predicate: "${property.colName} < %@", values: [${property.enumName}], expectedCount: 0) {
            $0.${property.colName} < ${property.values[1]}
        }
        assertQuery(predicate: "${property.colName} <= %@", values: [${property.enumName}], expectedCount: 1) {
            $0.${property.colName} <= ${property.values[1]}
        }
        % elif property.category == 'numeric':
        // ${property.colName}
        assertQuery(predicate: "${property.colName} < %@", values: [${property.values[1]}], expectedCount: 0) {
            $0.${property.colName} < ${property.values[1]}
        }
        assertQuery(predicate: "${property.colName} <= %@", values: [${property.values[1]}], expectedCount: 1) {
            $0.${property.colName} <= ${property.values[1]}
        }
        % end
        % end
    }

    func testLessThanOptional() {
        % for property in optProperties:
        % if property.enumName != None and property.category == 'numeric':
        // ${property.colName}
        assertQuery(predicate: "${property.colName} < %@", values: [${property.enumName}], expectedCount: 0) {
            $0.${property.colName} < ${property.values[1]}
        }
        assertQuery(predicate: "${property.colName} <= %@", values: [${property.enumName}], expectedCount: 1) {
            $0.${property.colName} <= ${property.values[1]}
        }
        % elif property.category == 'numeric':
        // ${property.colName}
        assertQuery(predicate: "${property.colName} < %@", values: [${property.values[1]}], expectedCount: 0) {
            $0.${property.colName} < ${property.values[1]}
        }
        assertQuery(predicate: "${property.colName} <= %@", values: [${property.values[1]}], expectedCount: 1) {
            $0.${property.colName} <= ${property.values[1]}
        }
        % end
        % end

        // Test for `nil`
        % for property in optProperties:
        % if property.enumName != None and property.category == 'numeric':
        // ${property.colName}
        assertQuery(predicate: "${property.colName} < %@", values: [NSNull()], expectedCount: 0) {
            $0.${property.colName} < nil
        }
        assertQuery(predicate: "${property.colName} <= %@", values: [NSNull()], expectedCount: 0) {
            $0.${property.colName} <= nil
        }
        % elif property.category == 'numeric':
        // ${property.colName}
        assertQuery(predicate: "${property.colName} < %@", values: [NSNull()], expectedCount: 0) {
            $0.${property.colName} < nil
        }
        assertQuery(predicate: "${property.colName} <= %@", values: [NSNull()], expectedCount: 0) {
            $0.${property.colName} <= nil
        }
        % end
        % end
    }

    func testLessThanAnyRealmValue() {
        % for value in anyRealmValues:
        % if value[2] == 'numeric':
        setAnyRealmValueCol(with: AnyRealmValue${value[0]}, object: objects()[0])
        assertQuery(predicate: "anyCol < %@", values: [${value[1]}], expectedCount: 0) {
            $0.anyCol < ${value[0]}
        }
        assertQuery(predicate: "anyCol <= %@", values: [${value[1]}], expectedCount: 1) {
            $0.anyCol <= ${value[0]}
        }
        % end
        % end
    }

    func testNumericContains() {
        % for property in properties + optProperties:
        % if property.enumName == None and property.category == 'numeric':
        assertQuery(predicate: "${property.colName} >= %@ && ${property.colName} < %@",
                    values: [${property.values[0]}, ${property.values[2]}], expectedCount: 1) {
            $0.${property.colName}.contains(${property.values[0]}..<${property.values[2]})
        }

        assertQuery(predicate: "${property.colName} >= %@ && ${property.colName} < %@",
                    values: [${property.values[0]}, ${property.values[1]}], expectedCount: 0) {
            $0.${property.colName}.contains(${property.values[0]}..<${property.values[1]})
        }

        assertQuery(predicate: "${property.colName} BETWEEN {%@, %@}",
                    values: [${property.values[0]}, ${property.values[2]}], expectedCount: 1) {
            $0.${property.colName}.contains(${property.values[0]}...${property.values[2]})
        }

        assertQuery(predicate: "${property.colName} BETWEEN {%@, %@}",
                    values: [${property.values[0]}, ${property.values[1]}], expectedCount: 1) {
            $0.${property.colName}.contains(${property.values[0]}...${property.values[1]})
        }

        % end
        % end
    }

    func testListContainsElement() {
        % for property in listProperties:
        assertQuery(predicate: "%@ IN ${property.colName}", values: [${property.values[0]}], expectedCount: 1) {
            $0.${property.colName}.contains(${property.values[0]})
        }
        assertQuery(predicate: "%@ IN ${property.colName}", values: [${property.values[2]}], expectedCount: 0) {
            $0.${property.colName}.contains(${property.values[2]})
        }

        % end
        % for property in optListProperties:
        assertQuery(predicate: "%@ IN ${property.colName}", values: [${property.values[0]}], expectedCount: 1) {
            $0.${property.colName}.contains(${property.values[0]})
        }
        assertQuery(predicate: "%@ IN ${property.colName}", values: [${property.values[2]}], expectedCount: 0) {
            $0.${property.colName}.contains(${property.values[2]})
        }
        assertQuery(predicate: "%@ IN ${property.colName}", values: [${property.type}.none], expectedCount: 0) {
            $0.${property.colName}.contains(nil)
        }

        % end
    }

    func testListContainsRange() {
        % for property in listProperties + optListProperties:
        % if property.category == 'numeric':
        assertQuery(predicate: "${property.colName}.@min >= %@ && ${property.colName}.@max <= %@",
                    values: [${property.values[0]}, ${property.values[1]}], expectedCount: 1) {
            $0.${property.colName}.contains(${property.values[0]}...${property.values[1]})
        }
        assertQuery(predicate: "${property.colName}.@min >= %@ && ${property.colName}.@max < %@",
                    values: [${property.values[0]}, ${property.values[1]}], expectedCount: 0) {
            $0.${property.colName}.contains(${property.values[0]}..<${property.values[1]})
        }

        % end
        % end
    }

    func testSetContainsElement() {
        % for property in setProperties:
        assertQuery(predicate: "%@ IN ${property.colName}", values: [${property.values[0]}], expectedCount: 1) {
            $0.${property.colName}.contains(${property.values[0]})
        }
        assertQuery(predicate: "%@ IN ${property.colName}", values: [${property.values[2]}], expectedCount: 0) {
            $0.${property.colName}.contains(${property.values[2]})
        }

        % end
        % for property in optSetProperties:
        assertQuery(predicate: "%@ IN ${property.colName}", values: [${property.values[0]}], expectedCount: 1) {
            $0.${property.colName}.contains(${property.values[0]})
        }
        assertQuery(predicate: "%@ IN ${property.colName}", values: [${property.values[2]}], expectedCount: 0) {
            $0.${property.colName}.contains(${property.values[2]})
        }
        assertQuery(predicate: "%@ IN ${property.colName}", values: [${property.type}.none], expectedCount: 0) {
            $0.${property.colName}.contains(nil)
        }

        % end
    }

    func testSetContainsRange() {
        % for property in setProperties:
        % if property.category == 'numeric':
        assertQuery(predicate: "${property.colName}.@min >= %@ && ${property.colName}.@max <= %@",
                    values: [${property.values[0]}, ${property.values[1]}], expectedCount: 1) {
            $0.${property.colName}.contains(${property.values[0]}...${property.values[1]})
        }
        assertQuery(predicate: "${property.colName}.@min >= %@ && ${property.colName}.@max < %@",
                    values: [${property.values[0]}, ${property.values[1]}], expectedCount: 0) {
            $0.${property.colName}.contains(${property.values[0]}..<${property.values[1]})
        }

        % end
        % end
        % for property in optSetProperties:
        % if property.category == 'numeric':
        assertQuery(predicate: "${property.colName}.@min >= %@ && ${property.colName}.@max <= %@",
                    values: [${property.values[0]}, ${property.values[1]}], expectedCount: 1) {
            $0.${property.colName}.contains(${property.values[0]}...${property.values[1]})
        }
        assertQuery(predicate: "${property.colName}.@min >= %@ && ${property.colName}.@max < %@",
                    values: [${property.values[0]}, ${property.values[1]}], expectedCount: 0) {
            $0.${property.colName}.contains(${property.values[0]}..<${property.values[1]})
        }

        % end
        % end
    }
}
