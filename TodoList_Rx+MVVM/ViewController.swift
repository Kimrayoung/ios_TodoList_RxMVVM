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
//import RxDataSources

class ViewController: UIViewController {
    @IBOutlet weak var searchBar: UISearchBar!
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var todoAddBtn: UIButton!
    
    //뷰모델 주입
    var todosVM: TodoVM = TodoVM()
    var disposeBag = DisposeBag()
    
    override func viewDidLoad() {
        super.viewDidLoad()
                
        tableView.register(TodoCell.uiNib, forCellReuseIdentifier: TodoCell.reuseIdentifier)
        
        //MARK: - todosVM의 todoListData와 tableView연결 연결
        todosVM.todoListData.bind(to: self.tableView.rx.items(cellIdentifier: TodoCell.reuseIdentifier, cellType: TodoCell.self)) {
            index, item, cell in
            print(#fileID, #function, #line, "- item: \(item)")
            cell.todoData = item
            cell.settingUI()
        }
        .disposed(by: disposeBag)
        
        
        //MARK: - 할일 추가 버튼 클릭
        todoAddBtn.rx.tap.subscribe(onNext: {
            guard let modalVC = TodoModal.getInstance() else { return }
            self.present(modalVC, animated: true)
            modalVC.modalType = .add
            modalVC.modalTitle.text = "할 일 추가"
            modalVC.textViewPlaceHolder = "할 일을 간단하게 입력해주세요."
            modalVC.addExecuteClosure = self.todosVM.addTodo(_:_:)
        }).disposed(by: disposeBag)
        
        //MARK: - todo클릭 시 -> 할일 수정 모달 뜸
        tableView.rx.itemSelected
            .subscribe(onNext: { item in
                print(#fileID, #function, #line, "- itemSelected: \(item.row)")
                let row = item.row
                let existingTodos = self.todosVM.todoListData.value
                print(#fileID, #function, #line, "- existingTodos❗️: \(existingTodos)")
                let selectedItem = existingTodos[row]

                guard let id = selectedItem.id,
                      let title = selectedItem.title,
                      let isDone = selectedItem.isDone else { return }

                guard let modalVC = TodoModal.getInstance() else { return }
                self.present(modalVC, animated: true)
                
                modalVC.modalType = .edit
                modalVC.todoId = id
                modalVC.todoRow = row
                modalVC.todoCompletedSwitch.isOn = isDone
                modalVC.modalTitle.text = "할 일 수정"
                modalVC.textViewPlaceHolder = title
                modalVC.editExecuteClosure = self.todosVM.editTodo(_:_:_:)
            })
            .disposed(by: disposeBag)
        
        tableView.rx.didBottomReach
            .debounce(RxTimeInterval.microseconds(300), scheduler: MainScheduler.instance)
            .subscribe { didBottomReach in
                self.todosVM.fetchMoreTodos()
            }
            .disposed(by: disposeBag)
    
        self.todosVM.noMoreData
            .observe(on: MainScheduler.instance)
            .map { $0 ? nil : self.todosVM.createSpinnerFooter(Int(self.tableView.frame.width)) }
            .bind(to: self.tableView.rx.tableFooterView)
            .disposed(by: disposeBag)
    }
}

