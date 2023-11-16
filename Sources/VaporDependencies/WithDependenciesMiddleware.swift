import Dependencies
import Vapor

/// This middleware installs the configured dependencies for the current request.
///
/// Use ``request.yieldDependencies`` to perform operations using those dependencies.
public struct WithDependenciesMiddleware: AsyncMiddleware {

    public init() {}

    public func respond(to request: Request, chainingTo next: AsyncResponder) async throws -> Response {
        try await request.withDependencies {
            try await withEscapedDependencies { continuation in
                request.storage.dependenciesContinuation = continuation
                return try await next.respond(to: request)
            }
        }
    }
}
