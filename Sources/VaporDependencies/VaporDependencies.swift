import Dependencies
import Fluent
import Vapor

extension Application {
    public var dependencies: VaporDependencies {
        .init(application: self)
    }
}

public final class VaporDependencies {

    final class Storage {
        var appDeps: [(inout DependencyValues, Application) -> Void] = []
        var reqDeps: [(inout DependencyValues, Request) -> Void] = []
        var reqAppDeps: [(inout DependencyValues, Application) -> Void] = []
        var dbDeps:  [(inout DependencyValues, Database) -> Void] = []
    }

    init(application: Application) {
        self.application = application
    }

    let application: Application

    var storage: Storage {
        if self.application.storage[VaporDependenciesStorageKey.self] == nil {
            self.application.storage[VaporDependenciesStorageKey.self] = Storage()
        }
        return self.application.storage[VaporDependenciesStorageKey.self]!
    }
}

// TODO: allow user to customize how environment->context happens
extension Environment {
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

struct VaporDependenciesStorageKey: StorageKey {
    typealias Value = VaporDependencies.Storage
}

extension Storage {
    var dependencies: VaporDependencies.Storage? {
        get { self[VaporDependenciesStorageKey.self] }
        set { self[VaporDependenciesStorageKey.self] = newValue }
    }
}

struct VaporDependenciesContinuationStorageKey: StorageKey {
    typealias Value = DependencyValues.Continuation
}

extension Storage {
    public var dependenciesContinuation: DependencyValues.Continuation? {
        get { self[VaporDependenciesContinuationStorageKey.self] }
        set { self[VaporDependenciesContinuationStorageKey.self] = newValue }
    }
}
