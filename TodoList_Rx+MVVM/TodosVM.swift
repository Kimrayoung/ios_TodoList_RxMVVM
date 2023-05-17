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
    
    let todoListData: BehaviorRelay<[SectionOfCustomData]> = BehaviorRelay(value: [])
    var disposeBag = DisposeBag()
    var nowFetching: Bool = true
    var currentPage: Int = 1
    
    init() {
        print(#fileID, #function, #line, "- ")
        fetchTodos(currentPage)
    } //init
    
    //1. 비지니스 로직을 가져온다 -> 문제 : TodoVM 클래스에는 todoListData와 tableview가 없다
    //문제 해결 방법 : view와 연결시켜준다다
        //1. ViewController에서 todosVM을 메모리에 올려준다(ex. todosVM = TodosVM()
        //2. fetchTodo를 불러서 todosVM의 todoListData에 넣어준다
        //3. ViewController의 todoListData에 bind를 이용해서 꽂아준다
    //2.
    //MARK: - 모든 할일 목록 불러오기(api 호출)
    func fetchTodos(_ page: Int) {
        TodosRouter.fetchTodos(page)
            .subscribe(onNext: { data in
                print(#fileID, #function, #line, "- data: \(data)")
                guard let todos = data.data else { return }
                //딕셔너리 그룹핑
                let groupingTodos = Dictionary(grouping: todos, by: { $0.createdAt?.components(separatedBy: "T")[0] ?? "0" })
                
                var currentTodos = self.todoListData.value
                
                //그룹핑된 데이터 listData에 넣어주기 -> 이미 존재하는 header라면 해당 header에 append해주고 새로운 header라면 listData자체에 append
                for (key, value) in groupingTodos {
                    let temp: SectionOfCustomData = SectionOfCustomData(header: key, items: value)
                    
                    if let headerIndex = currentTodos.firstIndex(where: { sectionData in
                        return sectionData.header == temp.header
                    }) {
                        currentTodos[headerIndex].items.append(contentsOf: temp.items)
                    } else {
                        currentTodos.append(temp)
                    }
                }
                
                //최신 날짜의 데이터부터 나오도록 셋팅
                currentTodos.sort { first, second in
                    first.header > second.header
                }
                
                self.todoListData.accept(currentTodos)
                self.nowFetching = false
            }, onError: { err in
                print(#fileID, #function, #line, "- err: \(err)")
            })
            .disposed(by: disposeBag)
    }
    
    func moreFetchTodos(_ page: Int) {
        
    }
    
    func headerTime(_ dateString: String) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-mm-dd"
        
        guard let date = dateFormatter.date(from: dateString) else { return "" }
        let headerDateFormate = DateFormatter()
        headerDateFormate.dateFormat = "yyyy.mm.dd"
        return headerDateFormate.string(from: date)
    }
    
    func addTodo(_ title: String, _ isDone: Bool) {
        TodosRouter.addTodo(title, isDone).subscribe { data in
            guard let addTodo = data.data else { return }
            print(#fileID, #function, #line, "- data: \(data)")
            guard let todoCreatedAt = addTodo.createdAt?.components(separatedBy: "T")[0] else { return }
            print(#fileID, #function, #line, "- todoCreatedAt: \(todoCreatedAt)")
            var currentTodoListData = self.todoListData.value
            if let headerIndex = currentTodoListData.firstIndex(where: { sectionData in
                return sectionData.header == todoCreatedAt
            }) {
                currentTodoListData[headerIndex].items.insert(addTodo, at: 0)
            } else {
                let temp: SectionOfCustomData = SectionOfCustomData(header: todoCreatedAt, items: [addTodo])
                currentTodoListData.append(temp)
            }
            
            currentTodoListData.sort { first, second in
                first.header > second.header
            }
            self.todoListData.accept(currentTodoListData)
        }
        .disposed(by: disposeBag)
    }
    
    
    func editTodo(_ title: String,_ isDone: Bool,_ id: Int) {
        TodosRouter.editTodo(title, isDone, id)
            .subscribe (onNext: { data in
                var currentTodos = self.todoListData.value //현재 todo데이터(데이터 변경 전)
                guard let changeTodo = data.data else { return }

                let changeTodoId = changeTodo.id
                
                for data in currentTodos {
                    let todos = data.items
                    let header = data.header
                    
                    guard let headerIndex = currentTodos.firstIndex(where: { sectionData in
                        return sectionData.header == header
                    }) else { return }
                        
                    if let changeTodoIndex = todos.firstIndex(where: { data in
                        print(#fileID, #function, #line, "- data :\(data)")
                        return data.id == changeTodoId
                    }) {
                        currentTodos[headerIndex].items[changeTodoIndex] = changeTodo
                        print(#fileID, #function, #line, "- currentTodos change: \(currentTodos[headerIndex].items[changeTodoIndex])")
                    }
                }
                
                currentTodos.sort { first, second in
                    first.header > second.header
                }

                self.todoListData.accept(currentTodos)
            })
            .disposed(by: disposeBag)
    }
    
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
