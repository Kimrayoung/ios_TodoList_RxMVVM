//
//  ViewController.swift
//  TodoList_Rx+MVVM
//
//  Created by 김라영 on 2023/05/08.
//
import Foundation
import UIKit
import RxCocoa
import RxRelay
import RxSwift
import RxDataSources

class ViewController: UIViewController {
    @IBOutlet weak var searchBar: UISearchBar!
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var todoAddBtn: UIButton!
    
    //뷰모델 주입
    var todosVM: TodoVM = TodoVM()
    
    var disposeBag = DisposeBag()
    var todoListData: BehaviorRelay<[String : [Todo]]> = BehaviorRelay(value: [:])
    
    override func viewDidLoad() {
        super.viewDidLoad()
                
        tableView.register(TodoCell.uiNib, forCellReuseIdentifier: TodoCell.reuseIdentifier)
        
        //MARK: - todosVM의 todoListData와 연결
        todosVM.todoListData
            .bind(onNext: { data in
                self.todoListData.accept(data)
                print(#fileID, #function, #line, "- todoListData checking: \(self.todoListData.value)")
            })
            .disposed(by: disposeBag)
        
        //MARK: - dataSource를 tableView에 꽂아줌
//        todoListData.bind(to: tableView.rx.items(cellIdentifier: TodoCell.reuseIdentifier, cellType: TodoCell.self)) {
//            (row, element, cell) in
//            print(#fileID, #function, #line, "- element title: \(element.title)")
//            cell.todoData = element.value
//
//            cell.settingUI()
//            cell.settingTodoTime()
//            cell.checkBoxClicked = self.todosVM.editTodo(_:_:_:) //checkBoxClicked의 정의는 TodosVM에 있기 때문에 그걸 불러온다
//        }
//        .disposed(by: disposeBag)
        
        //MARK: - 할일 추가 버튼 클릭
//        todoAddBtn.rx.tap.subscribe(onNext: {
//            guard let modalVC = TodoModal.getInstance() else { return }
//            self.present(modalVC, animated: true)
//            modalVC.modalType = .add
//            modalVC.modalTitle.text = "할 일 추가"
//            modalVC.textViewPlaceHolder = "할 일을 간단하게 입력해주세요."
//
//            //MARK: - 모달에서 완료버튼 클릭시 (addTodo api 호출)
//            modalVC.todoCompletedBtn.rx.tap.subscribe(onNext: {
//                print(#fileID, #function, #line, "- todoCompletedBtnClicked")
//                guard let title = modalVC.textView.text else { return }
//                let isDone = modalVC.todoCompletedSwitch.isOn
//
//                guard let modalType = modalVC.modalType else { return }
//                if modalType == .add {
//                    TodosRouter.addTodo(title, isDone).subscribe { data in
//                        guard let addTodo = data.data else { return }
//                        print(#fileID, #function, #line, "- data")
//                        var currentTodoListData = self.todoListData.value
//                        currentTodoListData.insert(addTodo, at: 0)
//                        self.todoListData.accept(currentTodoListData)
//                        DispatchQueue.main.async {
//                            self.tableView.reloadData()
//                        }
//                    }
//                }
//            })
//        }).disposed(by: disposeBag)
        

        
//        tableView.rx.itemSelected
//            .subscribe(onNext: { item in //[section, row]
//                print(#fileID, #function, #line, "- itemSelected: \(item)")
//                let row = item.row
//                let selectedItem = self.todoListData.value[row]
//
//                guard let id = selectedItem.id,
//                      let title = selectedItem.title,
//                      let isDone = selectedItem.isDone else { return }
//
//                guard let modalVC = TodoModal.getInstance() else { return }
//                self.present(modalVC, animated: true)
//                modalVC.modalType = .edit
//                modalVC.modalTitle.text = "할 일 수정"
//                modalVC.textViewPlaceHolder = title
//
//                //MARK: - 모달에서 완료버튼 클릭시 (addTodo api 호출)
//                modalVC.todoCompletedBtn.rx.tap.subscribe(onNext: {
//                    print(#fileID, #function, #line, "- todoCompletedBtnClicked")
//                    guard let editTitle = modalVC.textView.text else { return }
//                    let editIsDone = modalVC.todoCompletedSwitch.isOn
//
//                    guard let modalType = modalVC.modalType else { return }
//                    if modalType == .edit {
//                        TodosRouter.editTodo(editTitle, editIsDone, id).subscribe { data in
//                            guard let editTodo = data.data else { return }
//                            print(#fileID, #function, #line, "- editTata: \(editTodo)")
//                            print(#fileID, #function, #line, "- row checking: \(row)")
//                        }
//                    }
//                }).disposed(by: self.disposeBag)
//            })
//            .disposed(by: disposeBag)
    }

}

