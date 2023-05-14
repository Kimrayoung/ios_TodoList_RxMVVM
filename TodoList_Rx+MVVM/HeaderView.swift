//
//  HeaderView.swift
//  TodoList_Rx+MVVM
//
//  Created by 김라영 on 2023/05/08.
//

import UIKit

class HeaderView: UITableViewHeaderFooterView {
    @IBOutlet weak var todoDay: UILabel!
    @IBOutlet weak var hiddenBtn: UIButton!
    /*
    // Only override draw() if you perform custom drawing.
    // An empty implementation adversely affects performance during animation.
    override func draw(_ rect: CGRect) {
        // Drawing code
    }
    */
    override func awakeFromNib() {
        super.awakeFromNib()
    }

}
