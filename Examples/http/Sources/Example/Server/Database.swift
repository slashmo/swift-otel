import Foundation
import Logging
import Hummingbird
import Tracing

actor Database {
    private let logger = Logger(label: "Database")

    private var users = [User.ID: User]()

    func user(byID id: User.ID) async throws -> User {
        try await InstrumentationSystem.tracer.withSpan("SELECT example.users", ofKind: .client) { [users] span in
            self.logger.debug("Query user by ID.")

            span.attributes["db.system"] = "postgresql"
            span.attributes["db.connection_string"] = "postgresql://hopefully_not_root@localhost:5432/example"
            span.attributes["db.user"] = "hopefully_not_root"
            span.attributes["db.name"] = "example"
            span.attributes["db.statement"] = "SELECT * FROM users WHERE id = '\(id)'"
            span.attributes["db.operation"] = "SELECT"
            span.attributes["db.sql.table"] = "users"
            span.attributes["net.sock.peer.addr"] = "::1"
            span.attributes["net.peer.port"] = 5432
            span.attributes["net.transport"] = "IP.TCP"

            try await Task.sleep(nanoseconds: 200_000_000 * UInt64.random(in: 1 ..< 10))
            guard let user = users[id] else {
                let error = DatabaseError.userNotFound(id: id)
                span.setStatus(.init(code: .error))
                throw error
            }
            return user
        }
    }

    func createUser(name: String) async throws -> User {
        return try await InstrumentationSystem.tracer.withSpan("INSERT example.users", ofKind: .client) { span in
            self.logger.debug("Insert new user.")

            let id = UUID()

            span.attributes["db.system"] = "postgresql"
            span.attributes["db.connection_string"] = "postgresql://hopefully_not_root@localhost:5432/example"
            span.attributes["db.user"] = "hopefully_not_root"
            span.attributes["db.name"] = "example"
            span.attributes["db.statement"] = "INSERT INTO users (id, name) VALUES ('\(id)', '\(name)')"
            span.attributes["db.operation"] = "INSERT"
            span.attributes["db.sql.table"] = "users"
            span.attributes["net.sock.peer.addr"] = "::1"
            span.attributes["net.peer.port"] = 5432
            span.attributes["net.transport"] = "IP.TCP"

            try await Task.sleep(nanoseconds: 200_000_000 * UInt64.random(in: 1 ..< 10))
            let user = User(id: id, name: name)
            self.insertUser(user)
            return user
        }
    }

    private func insertUser(_ user: User) {
        self.users[user.id] = user
    }
}

enum DatabaseError: Error {
    case userNotFound(id: User.ID)
}

struct User: Identifiable, Codable {
    let id: UUID
    let name: String
}

extension HBApplication {
    var db: Database {
        get { self.extensions.get(\.db) }
        set {
            self.extensions.set(\.db, value: newValue)
        }
    }
}

extension HBRequest {
    var db: Database {
        get { self.application.db }
    }
}
