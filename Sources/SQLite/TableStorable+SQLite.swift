//
//  TableStorable+SQLite.swift
//  SQLite
//
//  Created by Andrew J Wagner on 12/17/17.
//  Copyright © 2017 Drewag. All rights reserved.
//

import SQL

public let RowId = QualifiedField(name: "rowid")

extension TableStorable {
    public static var rowIdField: QualifiedField {
        return self.field("rowid")
    }
}
