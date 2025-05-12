# Interactions with Swift Concurrency

Learn how `Probing` interacts with Swift’s `Task` APIs and what limitations currently exist.

## Installing Probes and Creating Effects from Tasks

`Task.init`, `TaskGroup.addTask`, and `async let` declarations all start executing concurrent work immediately,
while unblocking the caller. `Probing` has no control over asynchronous tasks created through these APIs,
nor any visibility into their potential influence on your application’s state.

Because of this, `ProbeTesting` cannot guarantee deterministic execution when such APIs are used. 
By default, it treats probes and effects created from these APIs as if they were run outside the test scope. 
This means:
- Probes resume immediately, without suspension.
- Effects behave like regular Swift `Task` instances and are not subjected to any scheduling.

Nesting probes or effects within tasks does not make them testable again. For example:

```swift
func example() async {
    await #probe()

    #Effect("first") {
        await #probe()
        // All probes and effects are testable up to this point.
        // State changes until here are predictable and observable.

        Task {
            // Probes or effects nested here are not testable (by default).
            // State changes inside a task cannot be reliably observed.
            await #probe() 

            #Effect("second") {
                await #probe()
                // ...
            }
        }

        // All probes and effects are testable from this point again.
        // State changes here are predictable, unless they race
        // with mutations from the task above.
        await #probe()
        // ...
    }
}
```

- Important: Wherever applicable, use effect macros instead of `Task` APIs to ensure full test support.

That said, calling `Probing` APIs from within `Task` APIs is completely safe — and vice versa.
Using `Task` APIs only affects testing support, as it does not alter the runtime behavior of your app.

It is fully supported and recommended to use `Task` APIs in non-testable contexts, even if those tasks invoke `Probing` APIs.
For example, you can continue using `Task.init` in a SwiftUI `View`:

```swift
@Observable
final class MyViewModel {
    private(set) var isDownloading = false

    func download() async {
        isDownloading = true
        await #probe()
        // ...
    }
}

struct MyView: View {
    @State private var viewModel = MyViewModel()

    var body: some View {
        Button("Download") {
            Task {
                await viewModel.download()
            }
        }
        // ...
    }
}
```

- SeeAlso: Refer to the `ProbeTesting.ProbingOptions.attemptProbingFromTasks` documentation 
if you need to control tasks using the `Probing` library. As the name of the option suggests, this is not always possible, 
and is generally discouraged.

## Parallel Processing

While `Probing` offers macro equivalents to `Task.init`, it currently lacks counterparts for `TaskGroup.addTask` 
functions. This is intentional, as APIs like `withTaskGroup` are meant to introduce parallelism to your code. 
Since one of `Probing`’s goals is to help you reason about execution flow as a sequence of events, 
flattening parallel hierarchies provides limited value in such cases.

That said, you can still use `Probing` before parallel processing begins, after it ends, and while collecting the results 
from the group’s child tasks. For example:

```swift
// ...
await #probe()

await withTaskGroup(of: Void.self) { group in
    let count = 100
    progress = 0.0

    for _ in 0 ..< count {
        group.addTask { ... }
    }

    for await task in group {
        progress += 1 / Double(count)
        await #probe()
    }
}

await #probe()
// ...
```

To support `Probing` with `async let` declarations, you can leverage the ``Effect/value-677pr`` property of effects.
It allows them to execute concurrently while remaining controllable from tests:

```swift
let effect = #Effect("itJustWorks") { ... }
async let value = effect.value
```
