//
//  Storyboarded.swift
//  TodoList_Rx+MVVM
//
//  Created by 김라영 on 2023/05/10.
//

import Foundation
import UIKit

protocol Storyboarded {
    static func getInstance(_ storyboardName: String?) -> Self?
}

extension Storyboarded {
    static func getInstance(_ storyboardName: String? = nil) -> Self? {
        let name = storyboardName ?? String(describing: self)
        let storyboard = UIStoryboard(name: name, bundle: Bundle.main)
        
        return storyboard.instantiateViewController(withIdentifier: String(describing: self)) as? Self
    }
}

extension UIViewController: Storyboarded {}
