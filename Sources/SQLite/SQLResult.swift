//
//  SQLResult.swift
//  SQLite
//
//  Created by Andrew J Wagner on 12/12/17.
//

import SQL
import SQLite3

public final class SQLiteResultDataProvider: ResultDataProvider {
    let connection: OpaquePointer?
    let handle: OpaquePointer?
    let commitStatus: Int32

    init(connection: OpaquePointer?, handle: OpaquePointer?, commitStatus: Int32) {
        self.connection = connection
        self.handle = handle
        self.commitStatus = commitStatus
    }

    deinit {
        sqlite3_finalize(self.handle)
    }

    lazy var columns: [String:Int32] = {
        var output = [String:Int32]()
        for i in 0 ..< self.numberOfColumns {
            output[self.name(atColumn: i)!] = i
        }
        return output
    }()

    public var countAffected: Int {
        return Int(sqlite3_changes(connection))
    }

    public func rows<Query>() -> RowSequence<Query> where Query : RowReturningQuery {
        return SQLiteRowSequence(resultProvider: self)
    }
}

public final class SQLiteRowSequence<Query: RowReturningQuery>: RowSequence<Query> {
    let resultProvider: SQLiteResultDataProvider
    var isStillOnFirstResult = true

    init(resultProvider: SQLiteResultDataProvider) {
        self.resultProvider = resultProvider

        super.init()
    }

    public override func next() -> Row<Query>? {
        let status: Int32
        if !self.isStillOnFirstResult {
            status = sqlite3_step(self.resultProvider.handle)
        }
        else {
            status = self.resultProvider.commitStatus
            self.isStillOnFirstResult = false
        }
        switch status {
        case SQLITE_ROW:
            return SQLiteRow(resultProvider: self.resultProvider, error: nil)
        case SQLITE_DONE:
            return nil
        default:
            return SQLiteRow(
                resultProvider: self.resultProvider,
                error: SQLError(connection: self.resultProvider.connection, errorCode: status, message: "Error getting next row")
            )
        }
    }
}

extension SQLiteResultDataProvider {
    var numberOfColumns: Int32 {
        return sqlite3_column_count(self.handle)
    }

    func name(atColumn column: Int32) -> String? {
        guard let raw = sqlite3_column_name(self.handle, column) else {
            return nil
        }
        return String(cString: raw)
    }
}
