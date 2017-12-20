//
//  QualifiedField+JSON.swift
//  SQLite
//
//  Created by Andrew Wagner on 12/19/17.
//  Copyright © 2017 Drewag. All rights reserved.
//

import SQL

extension QualifiedField {
    public func jsonExtract(_ key: String) -> Function {
        return .custom(name: "json_extract", params: [self,Value.string("$.\(key)")])
    }
}
