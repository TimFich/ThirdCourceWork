//
//  RawMeasure.swift
//  ThirdCourceWork
//
//  Created by Тимур Миргалиев on 20.02.2023.
//

import Foundation

class RawMeasure {
    var time: Double
    var text: String
    var references: Int
    
    init(time: Double, text: String) {
        self.time = time
        self.text = text
        self.references = 1
    }
}

// MARK: - Equatable

extension RawMeasure: Equatable {}

func ==(lhs: RawMeasure, rhs: RawMeasure) -> Bool {
    return lhs.time == rhs.time && lhs.text == rhs.text
}

// MARK: Hashable

extension RawMeasure: Hashable {

    func hash(into hasher: inout Hasher) {
        hasher.combine(time)
        hasher.combine(text)
    }
}
