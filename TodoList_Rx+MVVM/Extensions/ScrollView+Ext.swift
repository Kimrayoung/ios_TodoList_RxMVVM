//
//  ScrollViewExt.swift
//  TodoList_Rx+MVVM
//
//  Created by 김라영 on 2023/05/18.
//

import Foundation
import UIKit
import RxSwift
import RxCocoa

extension Reactive where Base: UIScrollView {
    var didBottomReach: Observable<Bool> {
        return contentOffset
            .map{ $0.y }
            .map{
                //현재 y축의 위치가 특정 위치에 도달했을 때 api를 더 호출해준다
                return $0 > (self.base.contentSize.height - 30 - self.base.frame.size.height)
            }
            .filter{
                //map의 결과가 true일 경우에만 데이터 호출함
                $0 == true
            }
    }
}
