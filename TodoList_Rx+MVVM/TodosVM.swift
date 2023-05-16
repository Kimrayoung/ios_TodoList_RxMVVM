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
    
    var todoListData: BehaviorRelay<[String : [Todo]]> = BehaviorRelay(value: [:])
    var disposeBag = DisposeBag()
    
    init() {
        print(#fileID, #function, #line, "- ")
        fetchTodos(1)
    } //init
    
    //1. 비지니스 로직을 가져온다 -> 문제 : TodoVM 클래스에는 todoListData와 tableview가 없다
    //문제 해결 방법 : view와 연결시켜준다다
        //1. ViewController에서 todosVM을 메모리에 올려준다(ex. todosVM = TodosVM()
        //2. fetchTodo를 불러서 todosVM의 todoListData에 넣어준다
        //3. ViewController의 todoListData에 bind를 이용해서 꽂아준다
    //2.
    //MARK: - 모든 할일 목록 불러오기(api 호출)
    fileprivate func fetchTodos(_ page: Int) {
        TodosRouter.fetchTodos()
            .subscribe(onNext: { data in
                print(#fileID, #function, #line, "- data: \(data)")
                guard let todos = data.data else { return }
                let groupingTodos = Dictionary(grouping: todos, by: { $0.createdAt?.components(separatedBy: "T")[0] ?? "0" })
                
                self.todoListData.accept(groupingTodos)
            }, onError: { err in
                print(#fileID, #function, #line, "- err: \(err)")
            })
            .disposed(by: disposeBag)
    }
    
    fileprivate func headerTime() {
        
    }
    
    func editTodo(_ title: String,_ isDone: Bool,_ id: Int) {
        print(#fileID, #function, #line, "- <#comment#>")
//        TodosRouter.editTodo(title, isDone, id)
//            .subscribe (onNext: { data in
//                var currentTodos = self.todoListData.value //현재 todo데이터(데이터 변경 전)
//                guard let changeTodo = data.data else { return }
//
//                let changeTodoId = changeTodo.id
//                guard let changeTodoIndex = currentTodos.firstIndex(where: { data in
//                    data.id == changeTodoId
//                }) else { return }
//
//                currentTodos[changeTodoIndex] = changeTodo
//
//                self.todoListData.accept(currentTodos)
//                print(#fileID, #function, #line, "- self.todoListData change: \(self.todoListData.value[changeTodoIndex])")
//            })
//            .disposed(by: disposeBag)
    }
}
