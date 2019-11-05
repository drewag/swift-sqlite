//
//  SQLiteConnection.swift
//  SQLite
//
//  Created by Andrew J Wagner on 12/11/17.
//

import Foundation
import SQL
#if os(Linux)
    import CSQLite
#else
    import SQLite3
#endif
import Swiftlier

public final class SQLiteConnection: Connection {
    var pointer: OpaquePointer?

    let path: Path

    public var isConnected: Bool {
        return self.pointer != nil
    }

    public init(path: Path) {
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

    public func run(_ statement: String, arguments: [Value]) throws {
        let (status, handle) = try self.execute(statement: statement, arguments: arguments)
        switch status {
        case SQLITE_ROW, SQLITE_DONE, SQLITE_OK:
            break
        default:
            throw SQLError(connection: self.pointer, errorCode: status)
        }
        sqlite3_finalize(handle)
    }

    public func execute<Query>(_ query: Query) throws -> Result<Query> where Query : AnyQuery {
        let (status, handle) = try self.execute(statement: query.statement, arguments: query.arguments)
        let provider = SQLiteResultDataProvider(connection: self.pointer, handle: handle, commitStatus: status)
        if Query.self is RowReturningQuery.Type {
            switch status {
            case SQLITE_ROW, SQLITE_DONE:
                return Result(dataProvider: provider, query: query)
            default:
                throw SQLError(connection: self.pointer, errorCode: status)
            }
        }
        else {
            switch status {
            case SQLITE_DONE, SQLITE_OK:
                return Result(dataProvider: provider, query: query)
            default:
                throw SQLError(connection: self.pointer, errorCode: status)
            }
        }
    }

    public var lastInsertedRowId: Int64 {
        return sqlite3_last_insert_rowid(self.pointer)
    }
}

//private let SQLITE_STATIC = unsafeBitCast(0, to: sqlite3_destructor_type.self)
private let SQLITE_TRANSIENT = unsafeBitCast(-1, to: sqlite3_destructor_type.self)

private extension SQLiteConnection {
    func execute(statement: String, arguments: [Value]) throws -> (Int32,OpaquePointer?) {
        try self.connect()

        let sql = statement
            .replacingOccurrences(of: "====to_timestamp====", with: "datetime")
            .replacingOccurrences(of: "%@", with: "?")
            .replacingOccurrences(of: "====data_type====", with: "data")
//        print(sql)
//        print(arguments)
        var handle: OpaquePointer?
        let status = sqlite3_prepare_v2(self.pointer, sql, Int32(sql.utf8.count), &handle, nil)
        guard SQLITE_OK == status else {
            let message: String
            if let error = sqlite3_errmsg(self.pointer) {
                message = String(cString: error)
            }
            else {
                message = "Unknown error"
            }
            sqlite3_finalize(handle)
            throw SQLError(connection: self.pointer, errorCode: status, message: "Error preparing statement: \(message)")
        }

        for (index, argument) in arguments.enumerated() {
            let index = Int32(index + 1)
            let status: Int32
            switch argument {
            case .null:
                status = sqlite3_bind_null(handle, index)
            case .string(let string):
                status = sqlite3_bind_text(handle, index, string, -1, SQLITE_TRANSIENT)
            case .data(let data):
                status = data.withUnsafeBytes { bytes in
                    return sqlite3_bind_blob(handle, index, bytes, Int32(data.count), SQLITE_TRANSIENT)
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
            case .point(let x, let y):
                let string = #"{"x":\#(x),"y":\#(y)"}"#
                status = sqlite3_bind_text(handle, index, string, -1, SQLITE_TRANSIENT)
            case .time(let hour, let minute, let second):
                let string = "\(hour):\(minute):\(second)"
                status = sqlite3_bind_text(handle, index, string, -1, SQLITE_TRANSIENT)
            }

            guard status == SQLITE_OK else {
                sqlite3_finalize(handle)
                throw SQLError(connection: self.pointer, errorCode: status, message: "Error binding arguments")
            }
        }

        return (sqlite3_step(handle), handle)
    }
}
