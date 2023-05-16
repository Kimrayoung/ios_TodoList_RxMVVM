//
//  TodoCell.swift
//  TodoList_Rx+MVVM
//
//  Created by 김라영 on 2023/05/08.
//

import Foundation
import UIKit
import RxSwift
import RxCocoa

class TodoCell: UITableViewCell {
    @IBOutlet weak var checkBox: UIButton!
    
    @IBOutlet weak var todoContent: UILabel!
    @IBOutlet weak var todoTime: UILabel!
    
    var todoData : Todo? = nil
    var checkBoxClicked: ((_ title: String, _ isDone: Bool, _ id: Int) -> Void)? = nil
    
    var disposeBag = DisposeBag()
    
    override func awakeFromNib() {
        checkBox.rx.tap.bind { [weak self] in
            guard let self = self else { return }
            self.handleCheckBox(self.checkBox)
        }
        .disposed(by: disposeBag)
        
        super.awakeFromNib()
    }
    
    //MARK: - cell UI 설정
    func settingUI() {
        guard let isDone = todoData?.isDone,
              let title = todoData?.title else { return }
        todoContent.text = title
        
        settingCheckBoxUI(isDone)
    }
    
    func settingCheckBoxUI(_ isDone: Bool) {
        if isDone {
            if let image = UIImage(systemName: "checkmark.square.fill") {
                self.checkBox.setImage(image, for: .normal)
            }
        } else {
            if let image = UIImage(systemName: "square") {
                self.checkBox.setImage(image, for: .normal)
            }
        }
    }
    
    //MARK: - string에서 Date로 변경
    func settingTodoTime() {
        guard let dateString = todoData?.createdAt else { return }
        let dateFormatter = ISO8601DateFormatter()
        dateFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        
        if let date = dateFormatter.date(from: dateString) {
            let timeFormate = DateFormatter()
            timeFormate.dateFormat = "hh:mm a"
            todoTime.text = timeFormate.string(from: date)
        }
    }
    
    func handleCheckBox(_ sender: UIButton!) {
        guard let title = todoData?.title,
              let id = todoData?.id,
              let isDone = todoData?.isDone else { return }
        
        checkBoxClicked?(title, !isDone, id) //checkBoxClicked를 실행 -> 정의는 MainVC에서
    }
    
}
