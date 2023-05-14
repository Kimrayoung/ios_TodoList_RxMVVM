//
//  TodoVM.swift
//  TodoList_Rx+MVVM
//
//  Created by 김라영 on 2023/05/10.
//

import Foundation
import UIKit
import RxCocoa
import RxRelay
import RxSwift

class TodoVM {
    
    var todoListData: BehaviorRelay<[Todo]> = BehaviorRelay(value: [])
    
    init() {
        print(#fileID, #function, #line, "- ")
    } //init
    
    //1. 비지니스 로직을 가져온다 -> 문제 : TodoVM 클래스에는 todoListData와 tableview가 없다
    //문제 해결 방법 : view와 연결시켜주다  -> 어떻게,,,?
    //2.
    fileprivate func fetchTodos(_ page: Int) {
        //MARK: - 모든 할일 목록 불러오기(api 호출)
        TodosRouter.fetchTodos { result in
            switch result {
            case .success(let fetchTodo):
                if let todos = fetchTodo.data {
                    self.todoListData.accept(todos)
                }
            case .failure(let err):
                print(#fileID, #function, #line, "- err: \(err)")
            }
        }

    }
}
