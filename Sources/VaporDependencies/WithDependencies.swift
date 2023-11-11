import Dependencies
import Vapor

extension Application {
    public func withDependencies(
        _ updateValuesForOperation: (inout DependencyValues) throws -> Void,
        operation: @Sendable () async throws -> Void
    ) async throws {
        try await Dependencies.withDependencies { deps in
            deps.context = self.environment.dependencyContext
            self.dependencies.storage.appDeps.forEach { $0(&deps, self) }
            self.dependencies.storage.dbDeps.forEach  { $0(&deps, self.db) }
            try updateValuesForOperation(&deps)
        } operation: {
            try await operation()
        }
    }
}

extension Request {
    public  func withDependencies<R>(
        _ updateValuesForOperation: (inout DependencyValues) throws -> Void,
        operation: @Sendable () async throws -> R
    ) async throws -> R {
        try await Dependencies.withDependencies { deps in
            deps.context = self.application.environment.dependencyContext
            self.application.dependencies.storage.reqDeps.forEach { $0(&deps, self) }
            self.application.dependencies.storage.dbDeps.forEach  { $0(&deps, self.db) }
            try updateValuesForOperation(&deps)
        } operation: {
            try await operation()
        }
    }

    /// Execute some operation with the dependencies resolved for this request.
    ///
    /// This is required for response handling that happens within a SwiftNIO
    /// execution context which does not use swift concurrenty.
    func yieldDependencies<R>(operation: () async throws -> R) async rethrows -> R {
        guard let c = self.storage.dependenciesContinuation else {
            XCTFail("DependenciesContinuation is not configured. Make sure you have installed DependenciesMiddleware.")
            return try await operation()
        }
        return try await c.yield(operation)
    }
}

public struct DependenciesMiddleware: AsyncMiddleware {
    let updateValuesForRequest: (Request, inout DependencyValues) throws -> Void

    public init(
        _ updateValuesForRequest: @escaping (Request, inout DependencyValues) throws -> Void = { _, _ in }
    ) {
        self.updateValuesForRequest = updateValuesForRequest
    }

    public func respond(to request: Request, chainingTo next: AsyncResponder) async throws -> Response {
        try await request.withDependencies { deps in
            try self.updateValuesForRequest(request, &deps)
        } operation: {
            try await withEscapedDependencies { continuation in
                request.storage.dependenciesContinuation = continuation
                return try await next.respond(to: request)
            }
        }
    }
}
