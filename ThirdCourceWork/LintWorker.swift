//
//  LintWorker.swift
//  ThirdCourceWork
//
//  Created by Тимур Миргалиев on 02.04.2023.
//

import Foundation

struct LintWorker {
    
    func createSwiftlintConfigFile(atPath path: String) {
        let fileManager = FileManager.default
        let configFileName = ".swiftlint.yml"
        let configURL = URL(fileURLWithPath: path).appendingPathComponent(configFileName)

        // Проверяем, существует ли файл .swiftlint.yml
        if fileManager.fileExists(atPath: configURL.path) {
            print("Файл .swiftlint.yml уже существует.")
            return
        }

        // Создаем содержимое файла .swiftlint.yml
        let configFileContent = """
        file_length:
          warning: 500
          error: 1000
        function_body_length:
          warning: 30
          error: 50
        cyclomatic_complexity:
          warning: 10
          error: 15
        unused_declaration:
          warning: true
          error: true
        force_try:
          warning: true
          error: true
        type_body_length:
          warning: 200
          error: 400
        nesting:
          warning: 4
          error: 6
        vertical_whitespace:
          maximum_blank_lines: 2
          ignore_top_level_declarations: true
        closure_body_length:
          warning: 10
          error: 20
        type_body_length:
          warning: 200
          error: 400
        redundant_type_annotation:
          warning: true
          error: true
        trailing_whitespace:
          warning: true
          error: true
        modifier_order:
          severity: warning
          modifiers:
            - private
            - fileprivate
            - internal
            - public
            - open
        redundant_void_return:
          warning: true
          error: true
        statement_position:
          severity: warning
          positions:
            - prefix
            - infix
            - postfix
        """

        // Создаем файл .swiftlint.yml
        do {
            try configFileContent.write(to: configURL, atomically: true, encoding: .utf8)
            print("Файл .swiftlint.yml успешно создан.")
        } catch {
            print("Ошибка при создании файла .swiftlint.yml: \(error.localizedDescription)")
        }
    }

    
    func addRule(rule: String, directory: String) {
        
        let filePath = URL(filePath: directory).appendingPathExtension(".swiftlint.yml")
        
        // Дописываем еще одно правило в файл
        let newRule = rule
        
        // Читаем содержимое файла
        do {
            var existingContent = try String(contentsOf: filePath, encoding: .utf8)
            
            // Проверяем, не содержится ли уже данное правило в файле
            if existingContent.contains(newRule) {
                print("Данное правило уже содержится в файле")
                return
            }
            
            // Дописываем новое правило в конец файла
            existingContent.append("\n" + newRule)
            
            // Записываем обновленное содержимое в файл
            try existingContent.write(to: filePath, atomically: true, encoding: .utf8)
            
            print("Правило '\(newRule)' успешно добавлено в файл swiftlint.yml")
        } catch {
            print("Не удалось дописать правило в файл: \(error.localizedDescription)")
        }
    }
    
    func makeLintFile(path: String?) -> [String] {
        
        guard let path = path else { return [] }
        
        createSwiftlintConfigFile(atPath: getProgectFolder(path: path))
        
        let process = Process()
        let swiftlintPath = "/opt/homebrew/bin/swiftlint" // путь к исполняемому файлу swiftlint
        let projectPath = getProgectFolder(path: path) // путь к вашему проекту
        let configPath = "\(getProgectFolder(path: path))/.swiftlint.yml" // путь к файлу конфигурации swiftlint
        let filePath = path // путь к файлу, который нужно протестировать

        process.currentDirectoryPath = projectPath
        process.launchPath = swiftlintPath
        process.arguments = ["lint", "--config", configPath, "--path", filePath]

        let outputPipe = Pipe()
        process.standardOutput = outputPipe

        process.launch()
        process.waitUntilExit()

        var output = ""
        
        let outputData = outputPipe.fileHandleForReading.readDataToEndOfFile()
        if let outputString = String(data: outputData, encoding: .utf8) {
            output = outputString
        }
        
        let arrayOfWarnings: [String] = output.components(separatedBy: "\n")
        return arrayOfWarnings
    }
    
    func getProgectFolder(path: String) -> String {
        let fileManager = FileManager.default

        var currentPath = path
        while !currentPath.isEmpty {
            currentPath = (currentPath as NSString).deletingLastPathComponent
            let files = try? fileManager.contentsOfDirectory(atPath: currentPath)
            
            guard let files = files else { return "" }
            
            for file in files {
                if file.hasSuffix(".xcodeproj") {
                    return currentPath
                }
            }
        }
        return ""
    }
}
