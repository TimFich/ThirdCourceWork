//
//  ViewControllerDataSource.swift
//  ThirdCourceWork
//
//  Created by Тимур Миргалиев on 25.01.2023.
//

import Foundation

class ViewControllerDataSource {

    var aggregateByFile = false {
        didSet {
            processData()
        }
    }

    var filter = "" {
        didSet {
            processData()
        }
    }

    var sortDescriptors = [NSSortDescriptor]() {
        didSet {
            processData()
        }
    }

    private var originalData = [CompileMeasure]()
    private var processedData = [CompileMeasure]()

    func resetSourceData(newSourceData: [CompileMeasure]) {
        originalData = newSourceData
        processData()
    }

    func isEmpty() -> Bool {
        return processedData.isEmpty
    }

    func count() -> Int {
        return processedData.count
    }

    func measure(index: Int) -> CompileMeasure? {
        guard index < processedData.count && index >= 0 else { return nil }
        return processedData[index]
    }

    // MARK: - Private methods

    private func processData() {
        var newProcessedData = aggregateIfNeeded(originalData)
        newProcessedData = applySortingIfNeeded(newProcessedData)
        newProcessedData = applyFilteringIfNeeded(newProcessedData)

        processedData = newProcessedData
    }

    private func aggregateIfNeeded(_ input: [CompileMeasure]) -> [CompileMeasure] {
        guard aggregateByFile else { return input }
        var fileTimes: [String: CompileMeasure] = [:]
        for measure in input {
            if let fileMeasure = fileTimes[measure.path] {
                fileMeasure.time += measure.time
                fileTimes[measure.path] = fileMeasure
            } else {
                let newFileMeasure = CompileMeasure(rawPath: measure.path, time: measure.time)
                fileTimes[measure.path] = newFileMeasure
            }
        }
        return Array(fileTimes.values)
    }

    private func applySortingIfNeeded(_ input: [CompileMeasure]) -> [CompileMeasure] {
        if sortDescriptors.isEmpty { return input }
        return (input as NSArray).sortedArray(using: sortDescriptors) as! Array
    }

    private func applyFilteringIfNeeded(_ input: [CompileMeasure]) -> [CompileMeasure] {
        guard !filter.isEmpty else { return input }
        return input.filter{ textContains($0.code, pattern: filter) || textContains($0.filename, pattern: filter) }
    }

    private func textContains(_ text: String, pattern: String) -> Bool {
        return text.lowercased().contains(pattern.lowercased())
    }
}
