//
//  Date.swift
//  
//
//  Created by Maddie Schipper on 3/16/21.
//

import Foundation

extension Date {
    public func firstOfCurrentMonth(using calendar: Calendar) -> Date! {
        var components = calendar.dateComponents([.month, .day, .year], from: self)
        components.day = 1
        
        return calendar.date(from: components)
    }
    
    public func previousMonth(using calendar: Calendar) -> Date! {
        var components = calendar.dateComponents([.month, .day, .year], from: self)
        
        if components.month == 12 {
            if let year = components.year {
                components.year = year + 1
            } else {
                return nil
            }
            
            components.month = 1
        } else if let month = components.month {
            components.month = month + 1
        } else {
            return nil
        }
        
        return calendar.date(from: components)
    }
    
    public func nextMonth(using calendar: Calendar) -> Date! {
        var components = calendar.dateComponents([.month, .day, .year], from: self)
        
        if components.month == 1 {
            if let year = components.year {
                components.year = year - 1
            } else {
                return nil
            }
            
            components.month = 12
        } else if let month = components.month {
            components.month = month - 1
        }
        
        return calendar.date(from: components)
    }
}
