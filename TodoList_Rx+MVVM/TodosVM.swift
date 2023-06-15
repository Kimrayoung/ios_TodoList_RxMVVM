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
    let keepingTodoListData: BehaviorRelay<[Todo]> = BehaviorRelay(value: [])
    var disposeBag = DisposeBag()
    
    //BehaviorRelay는 초기값이 있고 PublishRelay는 초기값이 없다
    var nowFetching: BehaviorRelay<Bool> = BehaviorRelay(value: false)
    //현재 searchData를 가지고 오고 있는지
    var nowSearchDataFetching: BehaviorRelay<Bool> = BehaviorRelay(value: false)
    //searchData가 없음
    var notifySearchDataNotFound: PublishRelay<Bool> = PublishRelay()
    //완료 숨기기 버튼 클릭
    var isDoneBtnClicked: BehaviorRelay<Bool> = BehaviorRelay(value: false)
    var currentPage: Int = 1
    var noMoreData: PublishRelay<Bool> = PublishRelay()
    var searchQuery: BehaviorRelay<String> = BehaviorRelay(value: "")
    
    init() {
        print(#fileID, #function, #line, "- ")
        fetchTodosFirst()
        searchQuery.bind { searchText in
            self.searchTodos(searchText)
        }
        .disposed(by: disposeBag)
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
                //완료 숨기기 버튼이 클릭되어있다면
                if vm.isDoneBtnClicked.value == true {
                    let origianlTodoList = newTodoList
                    //완료되지 않은 목록만 필터링
                    let filterdTodoList = newTodoList.filter { aTodo in
                        return aTodo.isDone == false
                    }
                    
                    //그 목록에 이전 할일 목록 넣어주기
                    let mappedTodoList = filterdTodoList.enumerated()
                        .map { (index, aTodo) -> Todo in
                            let previousTodo = index > 0 ? origianlTodoList[index - 1] : nil
                            var presentTodo = aTodo
                            presentTodo.previousTodoDate = previousTodo?.updatedAt
                            
                            return presentTodo
                        }
                    //전체 목록 보기를 눌렀을 때 다시 전체 목록을 보기 위해서 전체 할일 목록 저장
                    vm.keepingTodoListData.accept(origianlTodoList)
                    //isDone = false인 할일목록들로 필터링된 데이터
                    vm.todoListData.accept(mappedTodoList)
                } else {
                    vm.todoListData.accept(newTodoList) //받은 데이터를 todoListData에 넣어준다
                }
                vm.nowFetching.accept(false) //현재 받아오는 중이 아니므로 nowFetching = false
            }
            .disposed(by: disposeBag)
    }
    
    //MARK: - 스크롤이 바닥에 닿았을 떄 새로운 데이터 요청
    func fetchMoreTodos() {
        print(#fileID, #function, #line, "- nowFetching⭐️: \(self.nowFetching.value)")
        print(#fileID, #function, #line, "- nowSearchDataFetching❗️: \(self.nowSearchDataFetching.value)")
        
        if nowFetching.value { return }
        if nowSearchDataFetching.value { return }
        
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
            .bind(onNext: { vm, todoList in
                var existingList: [Todo] = vm.todoListData.value //기존에 있던 데이터
                var originalTodoList : [Todo] = todoList //새로운 데이터 + isDone 필터링 안된 데이터
                originalTodoList[0].previousTodoDate = existingList.last?.updatedAt
                
                if vm.isDoneBtnClicked.value == true {
                    var allTodoList = vm.keepingTodoListData.value //전체 todoData
                    //isDone으로 필터링된 데이터
                    let filterCompleteTodoList : [Todo] = originalTodoList
                        .filter { aTodo in
                            return aTodo.isDone == false
                        }
                    
                    //필터링된 데이터 previousDate넣어주기
                    var mappedTodoList : [Todo] = filterCompleteTodoList
                        .enumerated()
                        .map { (index, aTodo) -> Todo in
                            let previousTodo = index > 0 ? filterCompleteTodoList[index - 1] : nil
                            var presentTodo = aTodo
                            presentTodo.previousTodoDate = previousTodo?.updatedAt
                            
                            return presentTodo
                        }
                    
                    //전체목록 보여주기할 때 사용할 전체 할일 목록 저장
                    allTodoList.append(contentsOf: originalTodoList)
                    vm.keepingTodoListData.accept(allTodoList)
                    
                    //isDone으로 필터링된 할일목록저장
                    mappedTodoList[0].previousTodoDate = existingList.last?.updatedAt
                    existingList.append(contentsOf: mappedTodoList)
                    
                } else {
                    existingList.append(contentsOf: originalTodoList)
                }

                vm.todoListData.accept(existingList)
                vm.nowFetching.accept(false)
            })
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
    
    //MARK: - searchBar에서 입력한 데이터로 검색
    func searchTodos(_ searchText: String) {
        if nowFetching.value { return }
        
        nowFetching.accept(true)
        currentPage += 1
        
        print(#fileID, #function, #line, "- searchTodos: \(searchText)")
        
        TodosRouter.searchTodos(searchText, currentPage)
            .do { response in
                print(#fileID, #function, #line, "- response: \(response.meta)")
                guard let currentPage = response.meta?.currentPage,
                      let lastPage = response.meta?.lastPage else { return }

                let noMoreData = currentPage == lastPage
                print(#fileID, #function, #line, "- noMoreData checking: \(noMoreData)")
                self.noMoreData.accept(noMoreData)
            }
            .withUnretained(self)
            .subscribe(
                onNext: { vm, todoList in
                    print(#fileID, #function, #line, "- search todoData⭐️: \(todoList)")
                    guard let originalTodos = todoList.data else { return }
                    var resultTodoList: [Todo] = originalTodos
                        .enumerated()
                        .map { (index, aTodo) -> Todo in
                            let previousTodo = index > 0 ? originalTodos[index - 1] : nil
                            var presentTodo = aTodo
                            presentTodo.previousTodoDate = previousTodo?.updatedAt
                            return presentTodo
                        }
                    
                    //currentPage가 1이 아닐 경우에는 데이터를 더 불러온 것
                    if vm.currentPage != 1 {
                        var currentTodoList = vm.todoListData.value
                        let previousTodo = currentTodoList.last
                        resultTodoList[0].previousTodoDate = previousTodo?.createdAt
                        
                        currentTodoList.append(contentsOf: resultTodoList)
                        vm.todoListData.accept(currentTodoList)
                    } else {
                        vm.todoListData.accept(resultTodoList)
                    }
                    //현개 검색어 데이터가 있음
                    vm.nowSearchDataFetching.accept(true)
                    vm.notifySearchDataNotFound.accept(false)
                    vm.nowFetching.accept(false)
                }, onError: { err in
                    print(#fileID, #function, #line, "- err: \(err)")
                    self.handleError(err)
                })
            .disposed(by: disposeBag)
    }
    
    //MARK: - 완료버튼을 눌렀을 경우
    func isDoneBtnClickedChecking() {
        print(#fileID, #function, #line, "- todoList: \(todoListData.value)")
        let isDoneBtnChekcing = self.isDoneBtnClicked.value
        //이미 완료 숨기기 버튼이 눌려있다면 -> 전체 목록 보여주기
        if isDoneBtnChekcing {
            self.isDoneBtnClicked.accept(false)

            let allTodoListData = keepingTodoListData.value
            self.todoListData.accept(allTodoListData)
        }
        //완료 숨기기 버튼을 아직 누르지 않은 상태 -> 현재 목록에서 완료된 목록은 숨겨줌
        else {
            self.isDoneBtnClicked.accept(true)
            let nowTodoList = todoListData.value
            //아직 완료하지 않은 목록들만 가지고온다
            let isDoneTodoList = nowTodoList.filter { aTodo -> Bool in
                return aTodo.isDone == false
            }
            
            //아직 완료하지 않은 목록에 이전 todo의 날짜 넣어주기
            let isDonePreviousCheckingTodoList = isDoneTodoList
                .enumerated()
                .map { (index, aTodo) -> Todo in
                    let previousTodo = index > 0 ? isDoneTodoList[index - 1] : nil
                    var presentTodo = aTodo
                    presentTodo.previousTodoDate = previousTodo?.updatedAt
                    
                    return presentTodo
                }

            print(#fileID, #function, #line, "- currentTodoList⭐️: \(nowTodoList)")
            print(#fileID, #function, #line, "- isDonePreviousCheckingTodoList⭐️: \(isDonePreviousCheckingTodoList)")

            self.todoListData.accept(isDonePreviousCheckingTodoList) //아직 완료하지 않은 목록만 보여준다
            self.keepingTodoListData.accept(nowTodoList) //전체보기 눌렀을때 다시 전체 목록을 보여주기 위해서
        }
    }
    
//    func isDoneBtnClicked() {
//        print(#fileID, #function, #line, "- todoList: \(todoListData.value)")
//        let isDoneBtnChekcing = self.nowOnlyIsDoneDataShowing.value
//
//        if isDoneBtnChekcing {
//            self.nowOnlyIsDoneDataShowing.accept(false)
//
//            let nowTodoList = todoListData.value
//            let isDoneTodoList = nowTodoList.map { aTodo -> Todo in
//                var changeTodo = aTodo
//                changeTodo.todoViewIsHidden =  false
//
//                return changeTodo
//            }
//
//            self.todoListData.accept(isDoneTodoList)
//        }
//        else {
//            self.nowOnlyIsDoneDataShowing.accept(true)
//            let nowTodoList = todoListData.value
//            let isDoneTodoList = nowTodoList.map { aTodo -> Todo in
//                var changeTodo = aTodo
//                changeTodo.todoViewIsHidden =  changeTodo.isDone == true ? true : false
//
//                return changeTodo
//            }
//
//            print(#fileID, #function, #line, "- currentTodoList⭐️: \(nowTodoList)")
//            print(#fileID, #function, #line, "- isDoneTodoList⭐️: \(isDoneTodoList)")
//
//            self.todoListData.accept(isDoneTodoList)
//        }
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
    
    //MARK: - TodosVM에서 에러처리(API 에러 처리)
    fileprivate func handleError(_ err: Error) {
        guard let apiError = err as? TodosRouter.ApiError else {
            return
        }
        
        switch apiError {
        case .noContent:
            print(#fileID, #function, #line, "- searchData 없음")
            self.notifySearchDataNotFound.accept(true)
            self.todoListData.accept([])
        case .decodingErr:
            print(#fileID, #function, #line, "- 디코딩 에러입니다")
        default:
            print(#fileID, #function, #line, "- default")
        }
    }
    
}
