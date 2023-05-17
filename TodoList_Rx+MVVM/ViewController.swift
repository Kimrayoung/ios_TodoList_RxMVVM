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
    var todoListData: BehaviorRelay<[SectionOfCustomData]> = BehaviorRelay(value: [])
    
    override func viewDidLoad() {
        super.viewDidLoad()
                
        tableView.register(TodoCell.uiNib, forCellReuseIdentifier: TodoCell.reuseIdentifier)
        tableView.register(HeaderView.uiNib, forHeaderFooterViewReuseIdentifier: HeaderView.reuseIdentifier)
        
        tableView.delegate = self
//        nowFetching = false
        
        //MARK: - todosVM의 todoListData와 연결
        todosVM.todoListData
            .bind { data in
                self.todoListData.accept(data)
                print(#fileID, #function, #line, "- todoListData checking: \(self.todoListData.value)")
            }
            .disposed(by: disposeBag)
        
        //MARK: - dataSource생성 -> 어떤 셀을 보여줄건지, 몇개의 row인지 결정
        let dataSource = RxTableViewSectionedReloadDataSource<SectionOfCustomData> { dataSource, tv, indexPath, item in
            guard let cell = tv.dequeueReusableCell(withIdentifier: TodoCell.reuseIdentifier, for: indexPath) as? TodoCell else { return UITableViewCell() }
            print(#fileID, #function, #line, "- item: \(item)")
            print(#fileID, #function, #line, "- indexPath: \(indexPath)")
            cell.todoData = item
            
            cell.settingUI()
            cell.settingTodoTime()
            cell.checkBoxClicked = self.todosVM.editTodo(_:_:_:)
            
            return cell
        }
        
        //MARK: - tableview Section설정
//        dataSource.titleForHeaderInSection = { dataSource, index in
//            let headerString = dataSource.sectionModels[index].header
//            let headerFormate = self.todosVM.headerTime(headerString)
//
//            return headerFormate
//        }
        
        //MARK: - dataSource를 tableView에 꽂아줌
        todoListData.bind(to: tableView.rx.items(dataSource: dataSource))
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
                print(#fileID, #function, #line, "- itemSelected: \(item)")
                let row = item.row
                let section = item.section
                let selectedItem = self.todoListData.value[section].items[row]

                guard let id = selectedItem.id,
                      let title = selectedItem.title,
                      let isDone = selectedItem.isDone else { return }

                guard let modalVC = TodoModal.getInstance() else { return }
                self.present(modalVC, animated: true)
                
                modalVC.modalType = .edit
                modalVC.todoId = id
                modalVC.todoCompletedSwitch.isOn = isDone
                modalVC.modalTitle.text = "할 일 수정"
                modalVC.textViewPlaceHolder = title
                modalVC.editExecuteClosure = self.todosVM.editTodo(_:_:_:)
            })
            .disposed(by: disposeBag)
        
        tableView.rx.didBottomReach
            .filter({ _ in
                self.todosVM.nowFetching == false
            })
            .subscribe { didBottomReach in
                self.tableView.tableFooterView = self.todosVM.createSpinnerFooter(Int(self.tableView.frame.width))
                self.todosVM.nowFetching = true
                self.todosVM.currentPage += 1
                self.todosVM.fetchTodos(self.todosVM.currentPage)
            }
            .disposed(by: disposeBag)
    
    }
}

extension ViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return CGFloat(50.0)
    }
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let headerString = todoListData.value[section].header
        let headerFormate = self.todosVM.headerTime(headerString)
        
        guard let headerView = tableView.dequeueReusableHeaderFooterView(withIdentifier: HeaderView.reuseIdentifier) as? HeaderView else { return UIView() }
        
        headerView.headerLabel.text = headerFormate
        
        return headerView
    }
}
