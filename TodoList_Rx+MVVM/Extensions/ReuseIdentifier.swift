//
//  ReuseIdentifier.swift
//  TodoList_Rx+MVVM
//
//  Created by 김라영 on 2023/05/10.
//

import Foundation
import UIKit

//Nib파일 이름 가져오기
protocol ReuseIdentifier {
    static var reuseIdentifier: String { get }
}

extension ReuseIdentifier {
    static var reuseIdentifier: String {
        return String(describing: Self.self)
    }
}

extension UITableViewCell: ReuseIdentifier {}
extension UITableViewHeaderFooterView: ReuseIdentifier {}

