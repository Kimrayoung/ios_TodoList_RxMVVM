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

class ViewController: UIViewController, UISearchBarDelegate {
    @IBOutlet weak var searchBar: UISearchBar!
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var todoAddBtn: UIButton!
    @IBOutlet weak var isDoneBtn: UIButton!
    
    //뷰모델 주입
    var todosVM: TodoVM = TodoVM()
    var disposeBag = DisposeBag()
    
    //검색결과를 찾지 못함 view
    lazy var searchDataNotFoundView: UIView = {
        let view = UIView(frame: CGRect(x: 0, y: 0, width: self.tableView.bounds.width, height: 300))
        
        let label = UILabel()
        label.text = "❗️입력하신 검색어 데이터를 찾을 수 없습니다❗️"
        label.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(label)
        NSLayoutConstraint.activate([
            label.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            label.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])
        return view
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
                
        tableView.register(TodoCell.uiNib, forCellReuseIdentifier: TodoCell.reuseIdentifier)
        
        //MARK: - 할일 목록 검색
        searchBar.rx.searchButtonClicked
            .withUnretained(self)
            .filter({ vc, element in
                return vc.todosVM.nowSearchDataFetching.value == false
            })
            .bind { vc, element in
                vc.searchBar.resignFirstResponder()
                guard let searchText = vc.searchBar.text else { return }
                print(#fileID, #function, #line, "- controlEvent ⭐️text: \(searchText)")
                
                print(#fileID, #function, #line, "- nowSearchDataFetching: \(self.todosVM.nowSearchDataFetching.value)")
                vc.todosVM.notifySearchDataNotFound.accept(false)
                vc.todosVM.searchQuery.accept(searchText)
                vc.todosVM.currentPage = 0
                vc.tableView.tableFooterView = nil
                vc.tableView.scrollsToTop = true
                
            }
            .disposed(by: disposeBag)
        
        //MARK: - 할일목록에 x를 눌렀을 때(즉, 검색어 없앴을 때)
        searchBar.searchTextField.rx.text
            .orEmpty
            .withUnretained(self)
            .subscribe(onNext: { vc, _ in
                print(#fileID, #function, #line, "- empty")
                vc.todosVM.nowSearchDataFetching.accept(false)
                vc.todosVM.notifySearchDataNotFound.accept(false)
                vc.todosVM.currentPage = 1
                vc.todosVM.fetchTodosFirst()
            })
            .disposed(by: disposeBag)
        
        //MARK: - 검색어 데이터가 없을 경우
        self.todosVM.notifySearchDataNotFound
            .withUnretained(self)
            .bind { vc, notFound in
                print(#fileID, #function, #line, "- notFound: \(notFound)")
                if notFound == true {
                    DispatchQueue.main.async {
                        vc.tableView.backgroundView = vc.searchDataNotFoundView
                    }
                }
            }
            .disposed(by: disposeBag)
        
        //MARK: - 완료 숨기기 버튼 클릭시 todoList데이터 변경
        isDoneBtn.rx.tap
            .withUnretained(self)
            .bind { _ in
                self.todosVM.isDoneBtnClickedChecking()
            }
            .disposed(by: disposeBag)
        
        //MARK: - 완료 숨기기 버튼 text변경해주기
        todosVM.isDoneBtnClicked
            .withUnretained(self)
            .bind { vc, isDoneBtnClicked in
            print(#fileID, #function, #line, "- isDoneBtnClicked⭐️: \(isDoneBtnClicked)")
            //완료목록은 숨겼을 때
            if isDoneBtnClicked {
                vc.isDoneBtn.setTitle("전체 목록 보기", for: .normal)
            } else {
                vc.isDoneBtn.setTitle("완료 숨기기", for: .normal)
            }
        }
        .disposed(by: disposeBag)
        
        
        //MARK: - todosVM의 todoListData와 tableView연결 연결
        todosVM.todoListData.bind(to: self.tableView.rx.items(cellIdentifier: TodoCell.reuseIdentifier, cellType: TodoCell.self)) {
            index, item, cell in
            print(#fileID, #function, #line, "- item: \(item)")
            cell.todoData = item
            cell.settingUI()
            cell.checkBoxClicked = self.todosVM.editTodo(_:_:_:)
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
            .withUnretained(self)
            .debounce(RxTimeInterval.microseconds(300), scheduler: MainScheduler.instance)
            .subscribe { vc, didBottomReach in
                print(#fileID, #function, #line, "- moreDataFetching")
                if vc.todosVM.nowSearchDataFetching.value == true {
                    let searchQuery = vc.todosVM.searchQuery.value
                    vc.todosVM.searchTodos(searchQuery)
                }
                vc.todosVM.fetchMoreTodos()
            }
            .disposed(by: disposeBag)
        
        
        self.todosVM.noMoreData
            .observe(on: MainScheduler.instance)
            .subscribe(onNext: { noMoreData in
                if noMoreData {
                    self.tableView.tableFooterView = nil
                    self.tableView.alwaysBounceVertical = false
                } else {
                    let footer = self.todosVM.createSpinnerFooter(Int(self.tableView.frame.width))
                    self.tableView.tableFooterView = footer
                }
            })
            .disposed(by: disposeBag)
    }
}
