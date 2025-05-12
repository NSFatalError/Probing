# ``EquatableObject``

Automatically generate property-wise `Equatable` conformance for `final` classes using a macro.

## Overview

Swift automatically synthesizes `Equatable` conformance for structs and enums, but not for classes.
The ``EquatableObject()`` macro provides this functionality for `final` classes, allowing you to compare instances based on their stored properties.

## Topics

### Adding Equatable Conformance

- ``EquatableObject()``
