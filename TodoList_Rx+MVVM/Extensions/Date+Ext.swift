//
//  Date+Ext.swift
//  TodoList_Rx+MVVM
//
//  Created by 김라영 on 2023/06/02.
//

import Foundation
import UIKit

extension Date {
    func formateToString(_ formate: String) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = formate
        
        return dateFormatter.string(from: self)
    }
    
    func isSameDay(other: Date) -> Bool {
        let diff = Calendar.current.dateComponents([.day], from: self, to: other)
        return diff.day == 0 ? true : false
    }
}
