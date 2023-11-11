import Dependencies
import Fluent
import Vapor

public protocol ApplicationDependency {
    static func live(app: Application) -> Self
}

public protocol RequestDependency {
    static func live(request: Request) -> Self
}

public protocol DatabaseDependency {
    static func live(db: Database) -> Self
}

public final class VaporDependencies {

    fileprivate final class Storage {
        var appDeps: [(inout DependencyValues, Application) -> Void] = []
        var reqDeps: [(inout DependencyValues, Request) -> Void] = []
        var dbDeps:  [(inout DependencyValues, Database) -> Void] = []
    }

    fileprivate init(application: Application) {
        self.application = application
    }

    private let application: Application

    fileprivate var storage: Storage {
        if self.application.storage[DependenciesStorageKey.self] == nil {
            self.application.storage[DependenciesStorageKey.self] = Storage()
        }
        return self.application.storage[DependenciesStorageKey.self]!
    }

    public func add<T>(_ keyPath: WritableKeyPath<DependencyValues, T>) where T: ApplicationDependency {
        self.storage.appDeps.append({ $0[keyPath: keyPath] = .live(app: $1) })
    }
    public func add<T>(_ keyPath: WritableKeyPath<DependencyValues, T>) where T: RequestDependency {
        self.storage.reqDeps.append({ $0[keyPath: keyPath] = .live(request: $1) })
    }
    public func add<T>(_ keyPath: WritableKeyPath<DependencyValues, T>) where T: DatabaseDependency {
        self.storage.dbDeps.append({ $0[keyPath: keyPath] = .live(db: $1) })
    }
}

// TODO: allow user to customize how environment->context happens
fileprivate extension Environment {
    var dependencyContext: DependencyContext {
        switch self {
        case .production: return .live
        case .development: return .live
        case .testing: return .test
        default:
            fatalError("Unknown environment for dependencies: \(self.name)")
        }
    }
}

fileprivate struct DependenciesStorageKey: StorageKey {
    typealias Value = VaporDependencies.Storage
}

fileprivate extension Storage {
    var dependencies: VaporDependencies.Storage? {
        get { self[DependenciesStorageKey.self] }
        set { self[DependenciesStorageKey.self] = newValue }
    }
}

extension Application {
    public var dependencies: VaporDependencies {
        .init(application: self)
    }
}

extension Application {
    func withDependencies(
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
    func withDependencies<R>(
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
    func _yieldDependencies<R>(operation: () async throws -> R) async rethrows -> R {
        guard let c = self.storage.dependenciesContinuation else {
            XCTFail("DependenciesContinuation is not configured. Make sure you have installed VaporDependenciesMiddleware.")
            return try await operation()
        }
        return try await c.yield(operation)
    }
}

public struct VaporDependenciesMiddleware: AsyncMiddleware {
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

fileprivate struct VaporependenciesContinuationStorageKey: StorageKey {
    typealias Value = DependencyValues.Continuation
}

fileprivate extension Storage {
    var dependenciesContinuation: DependencyValues.Continuation? {
        get { self[VaporependenciesContinuationStorageKey.self] }
        set { self[VaporependenciesContinuationStorageKey.self] = newValue }
    }
}

