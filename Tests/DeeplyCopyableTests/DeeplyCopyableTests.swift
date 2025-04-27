//
//  DeeplyCopyableTests.swift
//  Probing
//
//  Created by Kamil Strzelecki on 23/01/2025.
//  Copyright © 2025 Kamil Strzelecki. All rights reserved.
//

import DeeplyCopyable
import EquatableObject
import Foundation
import Testing

internal struct DeeplyCopyableTests {

    @Test
    func testData() {
        var data = Data([0, 1, 2, 3])
        let copy = data.deepCopy()
        #expect(data == copy)

        data[0] = 4
        #expect(data != copy)
    }

    @Test
    func testString() throws {
        var string = "string"
        let copy = string.deepCopy()
        #expect(string == copy)

        let range = try #require(string.range(of: "s"))
        string.replaceSubrange(range, with: "S")
        #expect(string != copy)
    }

    @Test
    func testSubstring() throws {
        let string = "string"
        var substring = string[...]
        let copy = substring.deepCopy()
        #expect(substring == copy)

        let range = try #require(substring.range(of: "s"))
        substring.replaceSubrange(range, with: "S")
        #expect(substring != copy)
    }

    @Test
    func testArray() {
        let person = Person(id: 1)
        let array = [person, Person(id: 2)]
        let copy = array.deepCopy()
        #expect(array == copy)

        person.age += 1
        #expect(array != copy)
    }

    @Test
    func testArraySlice() {
        let person = Person(id: 1)
        let array = [person, Person(id: 2)]
        let slice = array[...]
        let copy = slice.deepCopy()
        #expect(slice == copy)

        person.age += 1
        #expect(slice != copy)
    }

    @Test
    func testSet() {
        let person = Person(id: 1)
        let set: Set = [person, Person(id: 2)]
        let copy = set.deepCopy()
        #expect(set == copy)

        person.age += 1
        #expect(set != copy)
    }

    @Test
    func testDictionary() {
        let person = Person(id: 1)
        let dictionary = ["a": person, "b": Person(id: 2)]
        let copy = dictionary.deepCopy()
        #expect(dictionary == copy)

        person.age += 1
        #expect(dictionary != copy)
    }

    @Test
    func testRange() {
        let person = Person(id: 0)
        let range = person ..< Person(id: 1)
        let copy = range.deepCopy()
        #expect(range == copy)

        person.age += 1
        #expect(range != copy)
    }

    @Test
    func testClosedRange() {
        let person = Person(id: 0)
        let range = person ... Person(id: 1)
        let copy = range.deepCopy()
        #expect(range == copy)

        person.age += 1
        #expect(range != copy)
    }

    @Test
    func testPartialRangeFrom() {
        let person = Person(id: 0)
        let range = person...
        let copy = range.deepCopy()
        #expect(range.lowerBound == copy.lowerBound)

        person.age += 1
        #expect(range.lowerBound != copy.lowerBound)
    }

    @Test
    func testPartialRangeThrough() {
        let person = Person(id: 0)
        let range = ...person
        let copy = range.deepCopy()
        #expect(range.upperBound == copy.upperBound)

        person.age += 1
        #expect(range.upperBound != copy.upperBound)
    }

    @Test
    func testPartialRangeUpTo() {
        let person = Person(id: 0)
        let range = ..<person
        let copy = range.deepCopy()
        #expect(range.upperBound == copy.upperBound)

        person.age += 1
        #expect(range.upperBound != copy.upperBound)
    }

    @Test
    func testRangeSet() {
        let person = Person(id: 0)
        let range = person ..< Person(id: 1)
        let rangeSet = RangeSet(range)
        let copy = rangeSet.deepCopy()
        #expect(rangeSet == copy)

        person.age += 1
        #expect(rangeSet != copy)
    }

    @Test
    func testOptional() {
        let person: Person? = Person(id: 0)
        let copy = person.deepCopy()
        #expect(person == copy)

        person?.age += 1
        #expect(person != copy)
    }

    @Test
    func testRawRepresentable() {
        struct PersonRepresentable: DeeplyCopyable, RawRepresentable {
            let rawValue: Person
        }

        let person = Person(id: 0)
        let source = PersonRepresentable(rawValue: person)
        let copy = source.deepCopy()
        #expect(source == copy)

        person.age += 1
        #expect(source != copy)
    }
}

extension DeeplyCopyableTests {

    @Test
    func testEnum() {
        let person = Person()
        let source = Choice.fourth(arg2: .zero, person)
        let copy = source.deepCopy()
        #expect(source == copy)

        person.age += 1
        #expect(source != copy)
    }

    @Test
    func testStruct() {
        let recipient = Person()
        let source = Order(id: .zero, address: "Kraków", recipient: recipient)
        let copy = source.deepCopy()
        #expect(source == copy)

        recipient.age += 1
        #expect(source != copy)
    }

    @Test
    func testClass() {
        let source = Person()
        let copy = source.deepCopy()
        #expect(source == copy)

        copy.age += 1
        #expect(source != copy)
    }
}

extension DeeplyCopyableTests {

    @DeeplyCopyable
    fileprivate enum Choice: Equatable {

        case first
        case second(Int)
        case third(arg1: Int)
        case fourth(arg2: Int, Person)
    }

    @DeeplyCopyable
    fileprivate struct Order: Equatable {

        let id: UInt
        var address: String
        var recipient: Person?

        var description: String {
            "\(id) - \(address)"
        }
    }

    @DeeplyCopyable @EquatableObject
    fileprivate final class Person: Hashable, Comparable {

        let id: UInt
        var age = 25
        var name = "John"
        var surname = "Doe"

        var fullName: String {
            "\(name) \(surname)"
        }

        init(id: UInt = .zero) {
            self.id = id
        }

        func hash(into hasher: inout Hasher) {
            hasher.combine(id)
            hasher.combine(age)
            hasher.combine(name)
            hasher.combine(surname)
        }

        static func < (lhs: Person, rhs: Person) -> Bool {
            lhs.id < rhs.id
        }
    }
}
