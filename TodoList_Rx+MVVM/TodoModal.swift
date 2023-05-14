//
//  TodoModal.swift
//  TodoList_Rx+MVVM
//
//  Created by 김라영 on 2023/05/08.
//

import Foundation
import UIKit
import RxCocoa
import RxRelay
import RxSwift

enum ModalType {
    case add
    case edit
}

class TodoModal: UIViewController {
    @IBOutlet weak var modalTitle: UILabel!
    @IBOutlet weak var textView: UITextView!
    @IBOutlet weak var todoCompletedSwitch: UISwitch!
    @IBOutlet weak var todoCompletedBtn: UIButton!
    
    var textViewPlaceHolder = ""
    var modalType: ModalType? = nil
    let textViewBorderColor = UIColor(named: "textViewBorder")
    let textViewPlaceHolderColor = UIColor(named: "textViewPlaceHolder")
    var disposeBag = DisposeBag()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        todoCompletedSwitch.isOn = false
        textView.delegate = self
        
        todoCompletedBtn.rx.tap.subscribe(onNext: {
            self.dismiss(animated: true)
        })
        .disposed(by: disposeBag)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        textViewSetting()
    }
    
    private func textViewSetting() {
        textView.contentInset = UIEdgeInsets(top: 0, left: 8, bottom: 0, right: 8)
        textView.text = textViewPlaceHolder
        textView.layer.borderWidth = 1
        textView.layer.borderColor = textViewBorderColor?.cgColor
        textView.layer.cornerRadius = 9
        textView.textColor = textViewPlaceHolderColor
    }
    
}

extension TodoModal: UITextViewDelegate {
    func textViewDidBeginEditing(_ textView: UITextView) {
        if textView.text == textViewPlaceHolder {
            print(#fileID, #function, #line, "- textViewPlaceHolder: \(textViewPlaceHolder)")
            textView.text = ""
            textView.textColor = .black
        }
    }
    
    func textViewDidEndEditing(_ textView: UITextView) {
        if textView.text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            textView.text = textViewPlaceHolder
            textView.textColor = textViewPlaceHolderColor
        }
    }
}
