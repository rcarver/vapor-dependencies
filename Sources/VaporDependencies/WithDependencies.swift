import Dependencies
import Vapor

extension Application {
    /// Apply configured dependencies at the ``Application`` level.
    public func withDependencies<R>(
        _ updateValuesForOperation: (inout DependencyValues) throws -> Void = { _ in },
        operation: @Sendable () async throws -> R
    ) async throws {
        try await Dependencies.withDependencies { deps in
            deps.context = self.environment.dependencyContext
            self.dependencies.storage.appDeps.forEach { $0(&deps, self) }
            self.dependencies.storage.reqAppDeps.forEach { $0(&deps, self) }
            self.dependencies.storage.dbDeps.forEach  { $0(&deps, self.db) }
            try updateValuesForOperation(&deps)
        } operation: {
            try await operation()
        }
    }
}

extension Request {
    /// Apply configured dependencies at the ``Request`` level.
    public func withDependencies<R>(
        _ updateValuesForOperation: (inout DependencyValues) throws -> Void = { _ in },
        operation: @Sendable () async throws -> R
    ) async throws -> R {
        try await Dependencies.withDependencies { deps in
            deps.context = self.application.environment.dependencyContext
            self.application.dependencies.storage.reqAppDeps.forEach { $0(&deps, self.application) }
            self.application.dependencies.storage.reqDeps.forEach { $0(&deps, self) }
            self.application.dependencies.storage.dbDeps.forEach  { $0(&deps, self.db) }
            try updateValuesForOperation(&deps)
        } operation: {
            try await operation()
        }
    }

    /// Execute some operation with dependencies configured on this request.
    ///
    /// This is required for response handling that happens within a SwiftNIO
    /// execution context which does not use swift concurrenty.
    public func yieldDependencies<R>(operation: () async throws -> R) async rethrows -> R {
        guard let c = self.storage.dependenciesContinuation else {
            XCTFail("DependenciesContinuation is not configured. Make sure you have installed DependenciesMiddleware.")
            return try await operation()
        }
        return try await c.yield(operation)
    }
}
