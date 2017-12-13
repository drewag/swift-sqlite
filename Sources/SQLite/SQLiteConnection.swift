//
//  SQLiteConnection.swift
//  SQLite
//
//  Created by Andrew J Wagner on 12/11/17.
//

import Foundation
import SQL
import SQLite3
import Swiftlier

public final class SQLiteConnection: Connection {
    var pointer: OpaquePointer?

    let path: Path

    public var isConnected: Bool {
        return self.pointer != nil
    }

    init(path: Path) {
        self.path = path
    }

    deinit {
        self.disconnect()
    }

    public func connect() throws {
        guard !self.isConnected else {
            return
        }

        var newConnection: OpaquePointer?
        let status = sqlite3_open(self.path.url.relativePath, &newConnection)
        guard SQLITE_OK == status else {
            sqlite3_close(newConnection)
            throw SQLError(connection: newConnection, errorCode: status)
        }

        self.pointer = newConnection
    }

    public func disconnect() {
        guard let pointer = self.pointer else {
            return
        }

        sqlite3_close(pointer)
        self.pointer = nil
    }

    public func error(_ message: String?) -> SQLError {
        return SQLError(connection: self.pointer, errorCode: nil, message: message)
    }

    public func run(statement: String, arguments: [Value]) throws {
        let (status, handle) = try self.execute(statement: statement, arguments: arguments)
        switch status {
        case SQLITE_ROW, SQLITE_DONE, SQLITE_OK:
            break
        default:
            throw SQLError(connection: self.pointer, errorCode: status)
        }
        sqlite3_finalize(handle)
    }

    public func run<Query>(statement: String, arguments: [Value]) throws -> Result<Query> where Query : AnyQuery {
        let (status, handle) = try self.execute(statement: statement, arguments: arguments)
        let provider = SQLiteResultDataProvider(connection: self.pointer, handle: handle)
        if Query.self is RowReturningQuery.Type {
            switch status {
            case SQLITE_ROW, SQLITE_DONE:
                return Result(dataProvider: provider)
            default:
                throw SQLError(connection: self.pointer, errorCode: status)
            }
        }
        else {
            switch status {
            case SQLITE_DONE, SQLITE_OK:
                return Result(dataProvider: provider)
            default:
                throw SQLError(connection: self.pointer, errorCode: status)
            }
        }
    }
}

private let SQLITE_STATIC = unsafeBitCast(0, to: sqlite3_destructor_type.self)
private let SQLITE_TRANSIENT = unsafeBitCast(-1, to: sqlite3_destructor_type.self)

private extension SQLiteConnection {
    func execute(statement: String, arguments: [Value]) throws -> (Int32,OpaquePointer?) {
        try self.connect()

        let sql = statement.replacingOccurrences(of: "%@", with: "?")
        var handle: OpaquePointer?
        var status = sqlite3_prepare_v2(self.pointer, sql, Int32(sql.utf8.count), &handle, nil)
        guard SQLITE_OK == status else {
            sqlite3_finalize(handle)
            throw SQLError(connection: self.pointer, errorCode: status, message: "Error preparing statement")
        }

        for (index, argument) in arguments.enumerated() {
            let index = Int32(index + 1)
            let status: Int32
            switch argument {
            case .null:
                status = sqlite3_bind_null(handle, index)
            case .string(let string):
                status = sqlite3_bind_text(handle, index, string, -1, SQLITE_STATIC)
            case .data(let data):
                status = data.withUnsafeBytes { bytes in
                    return sqlite3_bind_blob(handle, index, bytes, Int32(data.count), SQLITE_STATIC)
                }
            case .bool(let bool):
                status = sqlite3_bind_int64(handle, index, bool ? 1 : 0)
            case .float(let value):
                status = sqlite3_bind_double(handle, index, Double(value))
            case .double(let value):
                status = sqlite3_bind_double(handle, index, Double(value))
            case .int(let value):
                status = sqlite3_bind_int(handle, index, Int32(value))
            case .int8(let value):
                status = sqlite3_bind_int(handle, index, Int32(value))
            case .int16(let value):
                status = sqlite3_bind_int(handle, index, Int32(value))
            case .int32(let value):
                status = sqlite3_bind_int(handle, index, Int32(value))
            case .int64(let value):
                status = sqlite3_bind_int64(handle, index, value)
            case .uint(let value):
                status = sqlite3_bind_int(handle, index, Int32(value))
            case .uint8(let value):
                status = sqlite3_bind_int(handle, index, Int32(value))
            case .uint16(let value):
                status = sqlite3_bind_int(handle, index, Int32(value))
            case .uint32(let value):
                status = sqlite3_bind_int64(handle, index, Int64(value))
            case .uint64(let value):
                status = sqlite3_bind_int64(handle, index, Int64(value))
            }

            guard status == SQLITE_OK else {
                sqlite3_finalize(handle)
                throw SQLError(connection: self.pointer, errorCode: status, message: "Error binding arguments")
            }
        }

        status = sqlite3_step(handle)
        guard SQLITE_OK == status else {
            sqlite3_finalize(handle)
            throw SQLError(connection: self.pointer, errorCode: status, message: "Committing statement")
        }

        return (sqlite3_step(handle), handle)
    }
}
