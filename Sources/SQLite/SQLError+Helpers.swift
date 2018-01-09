//
//  SQLError+Helpers.swift
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

extension SQLError {
    init(connection: OpaquePointer?, errorCode: Int32?, message: String? = nil) {
        let moreInformation: String?
        if let info = sqlite3_errmsg(connection) {
            moreInformation = String(cString: info)
        }
        else {
            moreInformation = nil
        }

        if let message = message {
            self.message = message
            self.moreInformation = moreInformation
        }
        else {
            self.message = moreInformation ?? "Unknown Error"
            self.moreInformation = nil
        }
    }
}
