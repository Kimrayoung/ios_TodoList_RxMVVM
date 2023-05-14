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
    var checkBoxChecked: Bool = false
    @IBOutlet weak var todoContent: UILabel!
    @IBOutlet weak var todoTime: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
    }
    
}
