//
//  Date+Formatter.swift
//  ClearBudget
//
//  Created by Khan on 3/5/20.
//  Copyright © 2020 WindChillMedia. All rights reserved.
//

import Foundation


extension Date {
    
    /// Returns: Jan 3rd
    
    func timeString() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        return formatter.string(from: self)
    }
    func longStringFormat() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = #"h:mm a, M-dd-yy"#
        return formatter.string(from: self)
    }
}
