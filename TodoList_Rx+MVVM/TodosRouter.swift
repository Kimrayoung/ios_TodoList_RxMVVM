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
        case searchTodos

        var endString: String {
            switch self {
            case .fetchTodo(let page): return BASE_URL + "todos?" + "page=\(page)"
            case .addTodo: return BASE_URL + "todos-json"
            case .editTodo(let id): return BASE_URL + "todos-json/" + "\(id)"
            case .deleteTodo(let id): return BASE_URL + "todos/" + "\(id)"
            case let .searchTodos:
                return BASE_URL + "todos/search?"
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
        case noContent //204에러
        case badStatus(code: Int)
        case badUrl
        case unknownErr(err: Error)
        case unauthorized //권한없음
        
        var info : String {
            switch self {
            case .parsingError: return "파싱에러입니다"
            case .encodingErr: return "인코딩에러입니다"
            case .badStatus(let code): return "에러 상태코드: \(code)"
            case .noContent: return "데이터가 없습니다"
            case .decodingErr: return "디코딩에러입니다"
            case .badUrl: return "올바르지 않은 url입니다."
            case .unknownErr(let err): return "알수없는 에러입니다 \(err)"
            case .unauthorized: return "권한이 없습니다."
            }
        }
    }
    
    //MARK: - todoList 불러오개
    static func fetchTodos(_ page: Int = 1) -> Observable<FetchTodo> {
        print(#fileID, #function, #line, "- page: \(page)")
        let urlString = EndPoint.fetchTodo(page: page).endString
        guard let url = URL(string: urlString) else { return Observable.error(ApiError.badUrl) }
        var request = URLRequest(url: url)
        request.httpMethod = HttpMethod.get.rawValue
        request.addValue("application/json", forHTTPHeaderField: "Accept")
            
        return URLSession.shared.rx.data(request: request)
            .decode(type: FetchTodo.self, decoder: JSONDecoder())
            .catch { err in
                print(#fileID, #function, #line, "- err: \(err)")
                if let error = err as? ApiError {
                    throw error
                }
                if let _ = err as? DecodingError {
                    throw ApiError.decodingErr
                }
                throw ApiError.unknownErr(err: err)
            }
    }
    
    //MARK: - 할일 목록 추가하기
    static func addTodo(_ title: String, _ isDone: Bool) -> Observable<TodoModify> {
        let urlString = EndPoint.addTodo.endString
        guard let url = URL(string: urlString) else { return Observable.error(ApiError.badUrl)}
        var request = URLRequest(url: url)
        request.httpMethod = HttpMethod.post.rawValue
        request.addValue("application/json", forHTTPHeaderField: "Accept")
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let dataDic = ["title" : title, "is_done" : "\(isDone)"] as [String : Any]
        
        do {
            let jsonData = try JSONSerialization.data(withJSONObject: dataDic, options: .prettyPrinted)
            request.httpBody = jsonData
        } catch {
            return Observable.error(ApiError.encodingErr)
        }
        
        return URLSession.shared.rx.data(request: request)
            .decode(type: TodoModify.self, decoder: JSONDecoder())
            .catch { err in
                print(#fileID, #function, #line, "- err: \(err)")
                return Observable.error(err)
            }
    }
    
    //MARK: - 할일 목록 수정하기(title 수정, checkbox 눌렀을 떄 완료버튼 수정)
    static func editTodo(_ title: String, _ isDone: Bool, _ id: Int) -> Observable<TodoModify> {
        let urlString = EndPoint.editTodo(id: id).endString
        guard let url = URL(string: urlString) else { return Observable.error(ApiError.badUrl) }
        var request = URLRequest(url: url)
        request.httpMethod = HttpMethod.post.rawValue
        request.addValue("application/json", forHTTPHeaderField: "Accept")
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let dataDic: [String : Any] = ["title" : title, "is_done" : isDone]
        
        do {
            let jsonData = try JSONSerialization.data(withJSONObject: dataDic, options: .prettyPrinted)
            request.httpBody = jsonData
        } catch {
            return Observable.error(ApiError.encodingErr)
        }
        
        return URLSession.shared.rx.data(request: request)
            .decode(type: TodoModify.self, decoder: JSONDecoder())
            .catch { err in
                print(#fileID, #function, #line, "- err: \(err)")
                return Observable.error(err)
            }
    }
    
    static func searchTodos(_ query: String, _ page: Int = 1) -> Observable<FetchTodo> {
        let urlString = EndPoint.searchTodos.endString
        print(#fileID, #function, #line, "- urlString checking: \(urlString)")
        guard var urlComponent = URLComponents(string: urlString) else { return Observable.error(ApiError.badUrl)}
        let urlSearchQueryItem = URLQueryItem(name: "query", value: query)
        let urlPageQueryItem = URLQueryItem(name: "page", value: "\(page)")
        urlComponent.queryItems?.append(urlSearchQueryItem)
        urlComponent.queryItems?.append(urlPageQueryItem)
        
        guard let urlComponentString = urlComponent.string else { return Observable.error(ApiError.badUrl)}
        
        guard let url = URL(string: urlComponentString) else { return Observable.error(ApiError.badUrl)}
        var request = URLRequest(url: url)
        request.httpMethod = HttpMethod.get.rawValue
        request.addValue("application/json", forHTTPHeaderField: "Accept")
        
        return URLSession.shared.rx.response(request: request)
            .map { (response: HTTPURLResponse, data: Data) in
                print(#fileID, #function, #line, "- response Status: \(response)")
                print(#fileID, #function, #line, "- data: \(data)")
                
                //MARK: - 에러처리
                switch response.statusCode {
                case 401:
                    throw ApiError.unauthorized
                case 204:
                    throw ApiError.noContent
                default:
                    print(#fileID, #function, #line, "- default")
                }
                
                if !(200...299).contains(response.statusCode) {
                    throw ApiError.badStatus(code: response.statusCode)
                }
                
                //swift가 사용할 수 있는 모델로 파싱해주기
                do {
                    let data = try JSONDecoder().decode(FetchTodo.self, from: data)
                    return data
                } catch { //디코딩 실패
                    throw ApiError.decodingErr
                }
            }
        
//        return URLSession.shared.rx
//            .data(request: request)
//            .decode(type: FetchTodo.self, decoder: JSONDecoder())
//            .catch { err in
//                print(#fileID, #function, #line, "- err: \(err)")
//                if let error = err as? ApiError {
//                    throw error
//                }
//
//                if let _ = err as? DecodingError {
//                    throw ApiError.decodingErr
//                }
//
//                throw ApiError.unknownErr(err: err)
//            }
    }
    
    
}
