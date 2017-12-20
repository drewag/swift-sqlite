//
//  TableStorable+FullTextSearch.swift
//  SQLite
//
//  Created by Andrew Wagner on 12/17/17.
//  Copyright © 2017 Drewag. All rights reserved.
//

import SQL

extension TableStorable {
    public static func createFullTextSearch(ifNotExists: Bool = false, fields: [Fields], extra: [QualifiedField] = []) -> CreateFullTextSearchTable {
        return CreateFullTextSearchTable(name: self.tableName, ifNotExists: ifNotExists, fields: fields.map({$0.stringValue}) + extra.flatMap({$0.name}))
    }

    public static func createFullTextSearch(ifNotExists: Bool = false, fields: [QualifiedField]) -> CreateFullTextSearchTable {
        return CreateFullTextSearchTable(name: self.tableName, ifNotExists: ifNotExists, fields: fields.map({$0.name}))
    }
}

public struct CreateFullTextSearchTable: DatabaseChange {
    let name: String
    let fields: [String]
    let ifNotExists: Bool

    public init(name: String, ifNotExists: Bool = false, fields: [String]) {
        self.name = name.lowercased()
        self.fields = fields
        self.ifNotExists = ifNotExists
    }

    public var forwardQueries: [AnyQuery] {
        var query = "CREATE VIRTUAL TABLE"
        if self.ifNotExists {
            query += " IF NOT EXISTS"
        }
        query += " \(name) USING FTS4("
        query += self.fields.joined(separator: ",")
        query += ")"
        return [RawEmptyQuery(sql: query)]
    }

    public var revertQueries: [AnyQuery]? {
        return [RawEmptyQuery(sql: "DROP TABLE \(self.name)")]
    }
}

