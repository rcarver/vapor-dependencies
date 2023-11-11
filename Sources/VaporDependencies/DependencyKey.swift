import Dependencies
import Fluent
import Vapor

public protocol ApplicationDependencyKey {
    static func live(app: Application) -> Self
}

public protocol RequestDependencyKey {
    static func live(request: Request) -> Self
}

public protocol DatabaseDependencyKey {
    static func live(db: Database) -> Self
}

extension VaporDependencies {

    public func add<T>(_ keyPath: WritableKeyPath<DependencyValues, T>) where T: ApplicationDependencyKey {
        self.storage.appDeps.append({ $0[keyPath: keyPath] = .live(app: $1) })
    }

    public func add<T>(_ keyPath: WritableKeyPath<DependencyValues, T>) where T: RequestDependencyKey {
        self.storage.reqDeps.append({ $0[keyPath: keyPath] = .live(request: $1) })
    }

    public func add<T>(_ keyPath: WritableKeyPath<DependencyValues, T>) where T: DatabaseDependencyKey {
        self.storage.dbDeps.append({ $0[keyPath: keyPath] = .live(db: $1) })
    }
}
