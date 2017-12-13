//
//  SQLiteRow.swift
//  SQLite
//
//  Created by Andrew J Wagner on 12/12/17.
//

import Foundation
import SQL
import SQLite3

public final class SQLiteRow<Query: RowReturningQuery>: Row<Query> {
    let resultProvider: SQLiteResultDataProvider
    let error: SQLError?

    init(resultProvider: SQLiteResultDataProvider, error: SQLError?) {
        self.resultProvider = resultProvider
        self.error = error

        super.init()
    }

    public override var columns: [String] {
        return Array(self.resultProvider.columns.keys)
    }

    public override func data(forColumnNamed name: String) throws -> Data? {
        if let error = self.error {
            throw error
        }

        guard let column = self.resultProvider.columns[name] else {
            return nil
        }

        switch sqlite3_column_type(self.resultProvider.handle, column) {
        case SQLITE_NULL:
            return nil
        case SQLITE_INTEGER, SQLITE_FLOAT, SQLITE_TEXT, SQLITE_BLOB:
            break
        default:
            throw SQLError(message: "Unexpected type for column '\(name)'")
        }

        let length = sqlite3_column_bytes(self.resultProvider.handle, column)
        guard length > 0, let raw = sqlite3_column_blob(self.resultProvider.handle, column) else {
            return Data()
        }

        return Data(bytes: raw, count: Int(length))
    }
}
