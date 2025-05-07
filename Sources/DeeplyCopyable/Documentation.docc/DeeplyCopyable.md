# ``DeeplyCopyable-module``

Create copies of objects without sharing underlying storage, while remaining otherwise value-equal.

## Overview

In Swift, we can recognize three groups of `Copyable` types:
- Value types that don't store any reference types (directly or indirectly):
    - Basic types, like `Bool`, `Int`, etc.
    - Enums without associated values, or with associated values that don't hold any reference types.
    - Structs without stored properties, or with stored properties that don't hold any reference types.
- Value types that store reference types (directly or indirectly), optionally implementing copy-on-write mechanisms:
    - Many standard collection types, like `String`, `Array`, `Dictionary`, `Set`, etc.
    - Enums with associated values that hold reference types.
    - Structs with stored properties that hold reference types.
- Reference types:
    - Classes
    - Actors

Instances of these types can be copied either explicitly (by assigning them to another variable) or implicitly (by passing them as arguments to functions).
However, only the first group of types supports copying without sharing any underlying storage - in other words, they can be **deeply copied**.

Conformance to the ``DeeplyCopyable-protocol`` protocol indicates that a type can create a deep copy of itself, even if it stores reference types or is a reference type.
The easiest way to add this functionality is to apply the ``DeeplyCopyable()`` macro to the type’s declaration:

```swift
@DeeplyCopyable
final class Person {
    let name: String
    var age: Int

    init(name: String, age: Int) {
        self.name = name
        self.age = age
    }
}

let person = Person(name: "Kamil", age: 25)
let deepCopy = person.deepCopy()

person.age += 1
print(person.age) // 26
print(deepCopy.age) // 25
```

## Topics

### Making Deep Copies

- ``DeeplyCopyable()``
- ``DeeplyCopyable-protocol``
