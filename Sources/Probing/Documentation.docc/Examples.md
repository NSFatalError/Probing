# Examples

Explore simplified examples from the `ProbingPlayground` sample project to see `Probing` integration in action.

## Download the Sample Project

You can download the `ProbingPlayground` sample project from its [GitHub page](https://github.com/NSFatalError/ProbingPlayground).

## Probing in Async Functions

To verify that an object has changed state while an `async` function is running,  
you can define probes after the state change but before the next `await` statement:

```swift
func uploadImage(_ item: ImageItem) async {
    do {
        uploadState = .uploading
        await #probe() // ADDED
        let image = try await item.loadImage()
        let processedImage = try await processor.processImage(image)
        try await uploader.uploadImage(processedImage)
        uploadState = .success
    } catch {
        uploadState = .error
    }

    await #probe() // ADDED
    try? await Task.sleep(for: .seconds(3))
    uploadState = nil
}
```

This lets you reliably check the `uploadState` before the image is processed and uploaded,
and before the presentation timer fires, reproducing the exact sequence of events users experience in your app.

Similarly, you can install probes after each iteration of an `AsyncSequence` loop:

```swift
func updateLocation() async {
    locationState = .unknown
    await #probe() // ADDED

    do {
        for try await update in locationProvider.getUpdates() {
            try Task.checkCancellation()

            if update.authorizationDenied {
                locationState = .error
            } else if let isNear = update.location?.isNearSanFrancisco() {
                locationState = isNear ? .near : .far
            } else {
                locationState = .unknown
            }
            await #probe() // ADDED
        }
    } catch {
        locationState = .error
    }
}
```

This allows you to reliably verify `locationState` before entering the loop,
after each iteration, or after an error is thrown.

## Probing with Tasks

To control the execution of tasks, you can replace them with equivalent effect macros:

```swift
private var downloadImageEffects = [ImageQuality: any Effect<Void>]() // CHANGED

func downloadImage() {
    downloadImageEffects.values.forEach { $0.cancel() }
    downloadImageEffects.removeAll()
    downloadState = .downloading

    downloadImage(withQuality: .low)
    downloadImage(withQuality: .high)
}

private func downloadImage(withQuality quality: ImageQuality) {
    downloadImageEffects[quality] = #Effect("\(quality)") { // CHANGED
        defer {
            downloadImageEffects[quality] = nil
        }

        do {
            let image = try await downloader.downloadImage(withQuality: quality)
            try Task.checkCancellation()
            imageDownloadSucceeded(with: image, quality: quality)
        } catch is CancellationError {
            return
        } catch {
            imageDownloadFailed()
        }
    }
}
```

This enables you to reliably check the `downloadState` before the downloads start. 
You can also precisely recreate various runtime scenarios, putting your objects into different states
that users might experience, such as:
- low quality download succeeded, while high quality download is pending
- high quality download succeeded, while low quality download is pending
- low quality download succeeded, then high quality download succeeded
- high quality download succeeded, then low quality download succeeded
- low quality download failed, then high quality download succeeded
- high quality download failed, then low quality download succeeded
- low quality download succeeded, then high quality download failed
- high quality download succeeded, then low quality download failed
- low quality download failed, then high quality download failed
- high quality download failed, then low quality download failed
- user requested redownload before either download completed
- user requested redownload before high quality download completed
- user requested redownload before low quality download completed
- etc.

The return values and cancellation states of the effects are also available during testing,
without needing to reference them directly, as they are uniquely identified and can be retrieved.

- SeeAlso: Refer to the `ProbeTesting` documentation for details on accessing probes and controlling effects during tests.
