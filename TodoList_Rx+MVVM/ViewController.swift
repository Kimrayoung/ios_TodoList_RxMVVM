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
//    var todoVM: TodoVM = TodoVM()
    
    var disposeBag = DisposeBag()
    var todoListData: BehaviorRelay<[Todo]> = BehaviorRelay(value: [])
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
                
        tableView.register(TodoCell.uiNib, forCellReuseIdentifier: TodoCell.reuseIdentifier)
        tableView.register(HeaderView.uiNib, forCellReuseIdentifier: HeaderView.reuseIdentifier)
        
        TodosRouter.fetchTodos()
        
        
        //MARK: - dataSource를 tableView에 꽂아줌
        todoListData.bind(to: tableView.rx.items(cellIdentifier: TodoCell.reuseIdentifier, cellType: TodoCell.self)) {
            (row, element, cell) in
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy-MM-ddTHH:mm:ss.SSSSSS'Z'"
            
            if let createdAt = element.createdAt {
                let todoTime = dateFormatter.date(from: createdAt)
                            
                guard let todoTime = todoTime else { return }
                print(#fileID, #function, #line, "- todoTime: \(todoTime)")
                cell.todoTime.text = dateFormatter.string(from: todoTime)
            }
    
            //MARK: - checkbox를 클릭했을 경우
            cell.checkBox.rx.tap.subscribe(onNext: {
                if !cell.checkBoxChecked {
                    if let image = UIImage(systemName: "checkmark.square.fill") {
                        cell.checkBox.setImage(image, for: .normal)
                        cell.checkBoxChecked = true
                    }
                } else {
                    if let image = UIImage(systemName: "square") {
                        cell.checkBox.setImage(image, for: .normal)
                        cell.checkBoxChecked = false
                    }
                }
            })
            .disposed(by: self.disposeBag)
            
            cell.todoContent.text = element.title
            
        }
        .disposed(by: disposeBag)
        
        //MARK: - 할일 추가 버튼 클릭
        todoAddBtn.rx.tap.subscribe(onNext: {
            guard let modalVC = TodoModal.getInstance() else { return }
            self.present(modalVC, animated: true)
            modalVC.modalType = .add
            modalVC.modalTitle.text = "할 일 추가"
            modalVC.textViewPlaceHolder = "할 일을 간단하게 입력해주세요."
            
            //MARK: - 모달에서 완료버튼 클릭시 (addTodo api 호출)
            modalVC.todoCompletedBtn.rx.tap.subscribe(onNext: {
                print(#fileID, #function, #line, "- todoCompletedBtnClicked")
                guard let title = modalVC.textView.text else { return }
                let isDone = modalVC.todoCompletedSwitch.isOn
                
                guard let modalType = modalVC.modalType else { return }
                if modalType == .add {
                    TodosRouter.addTodo(title, isDone) { result in
                        switch result {
                        case .success(let data):
                            if let todo = data.data {
                                print(#fileID, #function, #line, "- addTodo checking: \(todo)")
                                var todoListData = self.todoListData.value
                                todoListData.insert(todo, at: 0)
                                self.todoListData.accept(todoListData)
                                DispatchQueue.main.async {
                                    self.tableView.reloadData()
                                }
                            }
                        case .failure(let err):
                            print(#fileID, #function, #line, "- err: \(err)")
                        }
                    }
                }
            }).disposed(by: self.disposeBag)
        })
        .disposed(by: disposeBag)
        
        tableView.rx.itemSelected
            .subscribe(onNext: { item in //[section, row]
                print(#fileID, #function, #line, "- itemSelected: \(item)")
                let row = item.row
                let selectedItem = self.todoListData.value[row]
                
                guard let id = selectedItem.id,
                      let title = selectedItem.title,
                      let isDone = selectedItem.isDone else { return }
                
                guard let modalVC = TodoModal.getInstance() else { return }
                self.present(modalVC, animated: true)
                modalVC.modalType = .edit
                modalVC.modalTitle.text = "할 일 수정"
                modalVC.textViewPlaceHolder = title
                
                //MARK: - 모달에서 완료버튼 클릭시 (addTodo api 호출)
                modalVC.todoCompletedBtn.rx.tap.subscribe(onNext: {
                    print(#fileID, #function, #line, "- todoCompletedBtnClicked")
                    guard let editTitle = modalVC.textView.text else { return }
                    let editIsDone = modalVC.todoCompletedSwitch.isOn
                    
                    guard let modalType = modalVC.modalType else { return }
                    if modalType == .edit {
                        TodosRouter.editTodo(editTitle, editIsDone, id) { result in
                            switch result {
                            case .success(let data):
                                if let todo = data.data {
                                    print(#fileID, #function, #line, "- addTodo checking: \(todo)")
                                    var nowTodoListData = self.todoListData.value
                                    
                                    nowTodoListData[row].title = editTitle
                                    self.todoListData.accept(nowTodoListData)
                                    DispatchQueue.main.async {
                                        self.tableView.reloadRows(at: [IndexPath(row: row, section: 0)], with: .fade)
                                    }
                                }
                            case .failure(let err):
                                print(#fileID, #function, #line, "- err: \(err)")
                            }
                        }
                    }
                }).disposed(by: self.disposeBag)
            })
            .disposed(by: disposeBag)
    }

}

