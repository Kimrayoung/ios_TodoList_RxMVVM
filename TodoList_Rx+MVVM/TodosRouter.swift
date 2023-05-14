//
//  TodosRouter.swift
//  TodoList_Rx+MVVM
//
//  Created by 김라영 on 2023/05/09.
//

import Foundation
import UIKit
import RxSwift
import RxCocoa

var BASE_URL = "https://phplaravel-574671-2962113.cloudwaysapps.com/api/v1/"

enum TodosRouter {
    enum EndPoint {
        case fetchTodo(page: Int)
        case addTodo
        case editTodo(id: Int)
        case deleteTodo(id: Int)

        var endString: String {
            switch self {
            case .fetchTodo(let page): return BASE_URL + "todos?" + "page=\(page)"
            case .addTodo: return BASE_URL + "todos-json"
            case .editTodo(let id): return BASE_URL + "todos/" + "\(id)"
            case .deleteTodo(let id): return BASE_URL + "todos/" + "\(id)"
            }
        }
    }
    
    enum HttpMethod: String {
        case get = "GET"
        case post = "POST"
        case delete = "DELETE"
        case update = "UPDATE"
        case put = "PUT"
    }
    
    enum ApiError : Error {
        case decodingErr
        case encodingErr
        case parsingError
        case noContent
        case badStatus(code: Int)
        case badUrl
        
        var info : String {
            switch self {
            case .parsingError: return "파싱에러입니다"
            case .encodingErr: return "인코딩에러입니다"
            case .badStatus(let code): return "에러 상태코드: \(code)"
            case .noContent: return "데이터가 없습니다"
            case .decodingErr: return "디코딩에러입니다"
            case .badUrl: return "올바르지 않은 url입니다."
            }
        }
    }
    
    static func fetchTodos(_ page: Int = 1) -> Observable<FetchTodo> {
        let urlString = EndPoint.fetchTodo(page: page).endString
        guard let url = URL(string: urlString) else { return Observable.error(ApiError.badUrl) }
        var request = URLRequest(url: url)
        request.httpMethod = HttpMethod.get.rawValue
        request.addValue("application/json", forHTTPHeaderField: "Accept")
            
        return URLSession.shared.rx.data(request: request)
            .decode(type: FetchTodo.self, decoder: JSONDecoder())
            .catch { err in
                print(#fileID, #function, #line, "- err: \(err)")
                return Observable.error(err)
            }
    }
    
    static func addTodo(_ title: String, _ isDone: Bool, _ completion: @escaping (Result<TodoModify, ApiError>) -> Void) {
        let urlString = EndPoint.addTodo.endString
        guard let url = URL(string: urlString) else { return }
        var request = URLRequest(url: url)
        request.httpMethod = HttpMethod.post.rawValue
        request.addValue("application/json", forHTTPHeaderField: "Accept")
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let dataDic = ["title" : title, "is_done" : "\(isDone)"] as [String : Any]
        
        do {
            let jsonData = try JSONSerialization.data(withJSONObject: dataDic, options: .prettyPrinted)
            request.httpBody = jsonData
        } catch {
            return completion(.failure(.encodingErr))
        }
        
        URLSession.shared.dataTask(with: request) { data, urlResponse, err in
            guard let data = data else { return }
            let decoder = JSONDecoder()
            do {
                let addTodo = try decoder.decode(TodoModify.self, from: Data(data))
                completion(.success(addTodo))
            } catch {
                completion(.failure(.parsingError))
            }
        }.resume()
    }
    
    static func editTodo(_ title: String, _ isDone: Bool, _ id: Int, _ completion: @escaping (Result<TodoModify, ApiError>) -> ()) {
        let urlString = EndPoint.editTodo(id: id).endString
        guard let url = URL(string: urlString) else { return }
        var request = URLRequest(url: url)
        request.httpMethod = HttpMethod.put.rawValue
        request.addValue("application/json", forHTTPHeaderField: "Accept")
        request.addValue("x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        
        let dataDic: [String : Any] = ["title" : title, "is_done" : isDone]
        
        do {
            let jsonData = try JSONSerialization.data(withJSONObject: dataDic, options: .prettyPrinted)
            request.httpBody = jsonData
        } catch {
            return completion(.failure(.encodingErr))
        }
        
        URLSession.shared.dataTask(with: request) { data, urlResponse, err in
            guard let data = data else { return }
            let decoder = JSONDecoder()
            
            do {
                let editTodo = try decoder.decode(TodoModify.self, from: Data(data))
                completion(.success(editTodo))
            } catch {
                completion(.failure(.parsingError))
            }
        }.resume()
    }
    
    
}
