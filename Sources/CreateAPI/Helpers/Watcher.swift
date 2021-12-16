// The MIT License (MIT)
//
// Copyright (c) 2021 Alexander Grebenyuk (github.com/kean).

import Foundation
import FileWatcher
import Combine

final class Watcher {
    private let queue = DispatchQueue(label: "com.github.kean.watcher")
    private var isDirty = false
    private var isWorking = false
    private let run: () throws -> Void
    private let didChange = PassthroughSubject<FileWatcherEvent, Never>()
    private var cancellables: Set<AnyCancellable> = []
    
    init(paths: [String], run: @escaping () throws -> Void) throws {
        try run()
        
        self.run = run
                
        let watcher = FileWatcher(paths.map { ($0 as NSString).expandingTildeInPath })
        watcher.queue = queue
        watcher.callback = { event in
            self.didChange.send(event) // Retain self
        }
        watcher.start()
        
        didChange.debounce(for: 0.1, scheduler: queue)
            .sink { [weak self] in self?.didChangeFile($0) }
            .store(in: &cancellables)

        print("Watching file changes...")
    }
    
    private func didChangeFile(_ event: FileWatcherEvent) {
        print("File modified at: \(event.path)")
        
        isDirty = true
        if !isWorking { regenerateIfNeeded() }
    }
    
    private func regenerateIfNeeded() {
        guard isDirty else {
            return
        }
        self.isDirty = false
        self.isWorking = true

        DispatchQueue.global().async {
            do {
                try self.run()
            } catch {
                print("ERROR! \(error)")
            }
            self.queue.async {
                self.isWorking = false
                self.regenerateIfNeeded()
            }
        }
    }
}
