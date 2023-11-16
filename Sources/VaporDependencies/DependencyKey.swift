import Dependencies
import Fluent
import Vapor

/// A dependency that requires the Vapor ``Application`` in order to be created.
public protocol ApplicationDependencyKey {
    static func live(app: Application) -> Self
}

/// A dependency that requires the current Vapor ``Request`` in order to be created.
public protocol RequestDependencyKey {
    static func live(request: Request) -> Self
}

/// A dependency that requires the current Fluent ``Database`` in order to be created.
public protocol DatabaseDependencyKey {
    static func live(db: Database) -> Self
}

extension VaporDependencies {

    /// Use a dependency that can be created using the ``Application`` or the current ``Request``.
    public func use<T>(_ keyPath: WritableKeyPath<DependencyValues, T>) where T: ApplicationDependencyKey, T: RequestDependencyKey {
        self.storage.reqDeps.append({ $0[keyPath: keyPath] = .live(request: $1) })
        self.storage.reqAppDeps.append({ $0[keyPath: keyPath] = .live(app: $1) })
    }

    /// Use a dependency that can be created using the ``Application``.
    public func use<T>(_ keyPath: WritableKeyPath<DependencyValues, T>) where T: ApplicationDependencyKey {
        self.storage.appDeps.append({ $0[keyPath: keyPath] = .live(app: $1) })
    }

    /// Use a dependency that can be created using the current ``Request``.
    public func use<T>(_ keyPath: WritableKeyPath<DependencyValues, T>) where T: RequestDependencyKey {
        self.storage.reqDeps.append({ $0[keyPath: keyPath] = .live(request: $1) })
    }

    /// Use a dependency that can be created using the current ``Database``.
    public func use<T>(_ keyPath: WritableKeyPath<DependencyValues, T>) where T: DatabaseDependencyKey {
        self.storage.dbDeps.append({ $0[keyPath: keyPath] = .live(db: $1) })
    }
}
