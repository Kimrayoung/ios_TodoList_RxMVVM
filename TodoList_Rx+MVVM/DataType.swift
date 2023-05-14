//
//  DataType.swift
//  TodoList_Rx+MVVM
//
//  Created by 김라영 on 2023/05/09.
//

import Foundation

// MARK: - Dodge
struct FetchTodo: Codable {
    let data: [Todo]?
    let meta: PageData?
    let message: String?
}

struct TodoModify: Codable {
    var data: Todo?
    let message: String?
}

// MARK: - Datum
struct Todo: Codable {
    let id: Int?
    var title: String?
    var isDone: Bool?
    var createdAt, updatedAt: String?

    enum CodingKeys: String, CodingKey {
        case id, title
        case isDone = "is_done"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}

// MARK: - Meta
struct PageData: Codable {
    let currentPage, from, lastPage, perPage: Int?
    let to, total: Int?

    enum CodingKeys: String, CodingKey {
        case currentPage = "current_page"
        case from
        case lastPage = "last_page"
        case perPage = "per_page"
        case to, total
    }
}
