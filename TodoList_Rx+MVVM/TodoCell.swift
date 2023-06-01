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
    @IBOutlet weak var todoDate: UILabel!
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
    
    //MARK: - <# 설명 #>
    override func prepareForReuse() {
        super.prepareForReuse()
        print(#fileID, #function, #line, "- ")
    }
    
    //MARK: - cell UI 설정
    func settingUI() {
        guard let isDone = todoData?.isDone,
              let title = todoData?.title else { return }
        todoContent.text = title
        
        settingCheckBoxUI(isDone)
        settingTodoTimeAndDate()
    }
    
    //MARK: - cell 초기 checkBox 설정
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
    
    //MARK: - todo 시간, 날짜 설정
    func settingTodoTimeAndDate() {
        guard let currentDateString = todoData?.updatedAt else { return }
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSSSS'Z'"
        
        guard let currentDate = dateFormatter.date(from: currentDateString) else { return }
        
        let timeString = currentDate.formateToString("hh:mm a")
        let dateString = currentDate.formateToString("yyyy.MM.dd")
        
        todoDate.text = dateString
        todoTime.text = timeString
        
        if let previousDateString = todoData?.previousTodoDate,
           let previousDate = dateFormatter.date(from: previousDateString) {
            let isSameDay = previousDate.isSameDay(other: currentDate)
            
            print(#fileID, #function, #line, "- isSameDay checking: \(isSameDay)")
            todoDate.isHidden = isSameDay
        } else {
            todoDate.isHidden = false
        }
    }
    
    //MARK: - checkBox를 눌렀을 때 실행됨
    func handleCheckBox(_ sender: UIButton!) {
        guard let title = todoData?.title,
              let id = todoData?.id,
              let isDone = todoData?.isDone else { return }
        
        checkBoxClicked?(title, !isDone, id) //checkBoxClicked를 실행 -> 정의는 MainVC에서
    }
    
}
