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
    let todoListData: BehaviorRelay<[Todo]> = BehaviorRelay(value: [])
    var disposeBag = DisposeBag()
    
    //BehaviorRelay는 초기값이 있고 PublishRelay는 초기값이 없다
    var nowFetching: BehaviorRelay<Bool> = BehaviorRelay(value: false)
    var currentPage: Int = 1
    var noMoreData: PublishRelay<Bool> = PublishRelay()
    
    init() {
        print(#fileID, #function, #line, "- ")
//        fetchTodos(currentPage)
        fetchTodosFirst()
    } //init
    
    //MARK: - Todo 앱 진입시 가장 처음 데이터를 불러오는 api
    func fetchTodosFirst() {
        TodosRouter.fetchTodos()
            .compactMap{ $0.data } //Todo데이터들만 가지고 온다
            .map { (todoList: [Todo]) -> [Todo] in
                print(#fileID, #function, #line, "- todo앱에 진입 시 최초 데이터 가지고 오기⭐️ - \(todoList)")
                let resultTodoList = todoList
                    .enumerated()
                    .map { (index, aTodo) -> Todo in
                        let previousTodo = index > 0 ? todoList[index - 1] : nil
                        var presentTodo = aTodo
                        presentTodo.previousTodoDate = previousTodo?.updatedAt
                        return presentTodo
                    }
                return resultTodoList
            }
            .withUnretained(self)
            .bind { vm, newTodoList in
                vm.todoListData.accept(newTodoList) //받은 데이터를 todoListData에 넣어준다
                vm.nowFetching.accept(false) //현재 받아오는 중이 아니므로 nowFetching = false
            }
            .disposed(by: disposeBag)
    }
    
    //MARK: - 스크롤이 바닥에 닿았을 떄 새로운 데이터 요청
    func fetchMoreTodos() {
        print(#fileID, #function, #line, "- nowFetching⭐️: \(self.nowFetching.value)")
        
        if nowFetching.value { return }
        
        currentPage += 1
        nowFetching.accept(true)
        
        TodosRouter.fetchTodos(currentPage)
            .do { response in
                guard let currentPage = response.meta?.currentPage,
                      let lastPage = response.meta?.lastPage else { return }
                
                let noMoreData = currentPage == lastPage
                print(#fileID, #function, #line, "- noMoreData checking: \(noMoreData)")
                self.noMoreData.accept(noMoreData)
            }
            .compactMap { $0.data }
            .map { (todoList: [Todo]) -> [Todo] in
                let originalTodoList = todoList
                let resultTodoList = todoList
                    .enumerated()
                    .map { (index, aTodo) -> Todo in
                        let previousTodo = index > 0 ? originalTodoList[index - 1] : nil
                        var presentTodo = aTodo
                        presentTodo.previousTodoDate = previousTodo?.updatedAt
                        
                        return presentTodo
                    }
                return resultTodoList
            }
            .withUnretained(self)
            .bind { vm, todoList in
                var existingList: [Todo] = vm.todoListData.value
                var appendingList : [Todo] = todoList
                
                appendingList[0].previousTodoDate = existingList.last?.updatedAt
                existingList.append(contentsOf: appendingList)
                
                vm.todoListData.accept(existingList)
                vm.nowFetching.accept(false)
            }
            .disposed(by: disposeBag)
    }
    
    func headerTime(_ dateString: String) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-mm-dd"
        
        guard let date = dateFormatter.date(from: dateString) else { return "" }
        let headerDateFormate = DateFormatter()
        headerDateFormate.dateFormat = "yyyy.mm.dd"
        return headerDateFormate.string(from: date)
    }
    
    //MARK: - 할일 추가 버튼 눌렀을 경우
    /// 원래 fetchTodos(api 호출)을 하는게 아니라 그냥 기존의 데이터를 불러와서 거기에 새로운 todo만 Insert해주는 식으로 하고 싶었는데 그러면 header표시가 곤란해져서 그냥 fetchTodos함수호출
    func addTodo(_ title: String, _ isDone: Bool) {
        TodosRouter.addTodo(title, isDone)
            .subscribe(onNext: { _ in
                self.fetchTodosFirst()
            })
            .disposed(by: disposeBag)
    }
    
//    func addTodo(_ title: String, _ isDone: Bool) {
//        TodosRouter.addTodo(title, isDone)
//            .compactMap{ $0.data }
//            .map{ (aTodo: Todo) -> Todo in
//                //현재 입력한 데이터가 가장 최신의 데이터가 된다 -> 즉 현재 todoList에서 첫번째 데이터의 previousTodo가 현재 addTodo한 데이터
//                guard var exsitingFirstTodo = self.todoListData.value.first else { return aTodo }
//                var resultTodo = aTodo
//                exsitingFirstTodo.previousTodoDate = resultTodo.updatedAt
//
//                return resultTodo
//            }
//            .bind { newTodo in
//                var existingTodos = self.todoListData.value
//                existingTodos.insert(newTodo, at: 0)
//
//                self.todoListData.accept(existingTodos)
//            }
//            .disposed(by: disposeBag)
//
//    }
    
    //MARK: - Todo데이터 수정
    ///createdAt이 기준이 아니라 updatedAt이 기준이므로 header라벨이 변경됨 -> fetchTodos를 해서 새롭게 데이터를 가지고 온다
    func editTodo(_ title: String,_ isDone: Bool,_ id: Int) {
        TodosRouter.editTodo(title, isDone, id)
            .bind(onNext: { _ in
                print(#fileID, #function, #line, "- ")
                self.fetchTodosFirst()
            })
            .disposed(by: disposeBag)
    }
  
    
//    func editTodo(_ title: String,_ isDone: Bool,_ id: Int,_ row: Int) {
//        TodosRouter.editTodo(title, isDone, id)
//            .compactMap{ $0.data }
//            .bind(onNext: { modifyTodo in
//                print(#fileID, #function, #line, "- modifyTodo⭐️: \(modifyTodo)")
//                var existingTodos = self.todoListData.value
//                let previousTodo = row > 0 ? existingTodos[row - 1] : nil
//                var resultModifyTodo = modifyTodo
//                resultModifyTodo.previousTodoDate = previousTodo?.updatedAt
//
//                existingTodos[row] = resultModifyTodo
//
//                self.todoListData.accept(existingTodos)
//            })
//            .disposed(by: disposeBag)
//    }
    
    //MARK: - spinner 만들기
    func createSpinnerFooter(_ widthSize: Int) -> UIView {
        let footerView = UIView(frame:CGRect(x: 0, y: 0, width: widthSize, height: 70))
        
        let spinner = UIActivityIndicatorView()
        spinner.center = footerView.center
        footerView.addSubview(spinner)
        spinner.startAnimating()
        
        return footerView
    }
    
    func makeHeaderUIView(_ headerTitle: String) -> UIView? {
        let headerView = UIView()
        
        let headerLabel = UILabel()
        headerLabel.frame = CGRect(x: 20, y: 0, width: 297, height: 25)
        headerLabel.font = UIFont.boldSystemFont(ofSize: 34)
        headerLabel.text = headerTitle
        
        headerView.addSubview(headerLabel)
        
        return headerView
    }
}
