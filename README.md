# VaporDependencies

Use [Dependencies](https://github.com/pointfreeco/swift-dependencies) with [Vapor](https://vapor.codes).

Status: Experimental / In Progress

### Define Dependencies

You can define a dependency to require the `Application`, `Request` or `Database` to be created.

```swift
extension AnalyzerDependency: ApplicationDependencyKey {
  public static func live(app: Application) -> Self { ... }
}
extension SearchDependency: RequestDependencyKey {
  static func live(request: Request) -> Self { ... }
}
extension TopicsClient: DatabaseDependencyKey {
  public static func live(db: Database) -> Self { ... }
}
```

### Configure

```swift
// Configure custom dependencies to use
app.dependencies.use(\.analyzer)
app.dependencies.use(\.search)
app.dependencies.use(\.topicsClient)

// Wrap requests in middleware
app.middleware.use(WithDependenciesMiddleware())
```

### Use in a Request

```swift
// Gain access to configured dependencies during a request.
try await request.yieldDependencies {
  // do work, all dependencies are here!
}
```

### Use in an Application

```swift
// Use outside of request context, for example with Commands.
try await application.withDependencies {
  // do work, all dependencies are here!
}
```

## License 

This library is released under the MIT license. See LICENSE for details.
