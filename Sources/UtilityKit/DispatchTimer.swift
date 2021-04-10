//
//  DispatchTimer.swift
//  
//
//  Created by Maddie Schipper on 4/10/21.
//

import Foundation
import Combine

/// DispatchTimer provides a Combine interface for a DispatchSourceTimer
public final class DispatchTimer {
    private let source = DispatchSource.makeTimerSource()
    
    private let timerQueue = DispatchQueue(label: ApplicationIdentifier + ".DispatchTimer-State")
    
    private enum State {
        case running
        case suspended
    }
    
    private var state: State = .suspended
    
    public init(deadline: DispatchTime, interval: DispatchTimeInterval = .never, leeway: DispatchTimeInterval = .nanoseconds(0)) {
        self.source.schedule(deadline: deadline, repeating: interval, leeway: leeway)
        self.source.setEventHandler { [weak self] in
            self?.trigger()
        }
    }
    
    deinit {
        self.suspend()
        self.source.cancel()
    }
    
    public func resume() {
        self.timerQueue.sync {
            guard self.state == .suspended else {
                return
            }
            self.source.resume()
            self.state = .running
        }
    }
    
    public func suspend() {
        self.timerQueue.sync {
            guard self.state == .running else {
                return
            }
            self.source.suspend()
            self.state = .suspended
        }
    }
    
    private let _publisher = PassthroughSubject<DispatchTime, Never>()
    
    public var publisher: AnyPublisher<DispatchTime, Never> {
        return self._publisher.eraseToAnyPublisher()
    }
    
    private func trigger() {
        let time = DispatchTime.now()
        
        self.timerQueue.async {
            self._publisher.send(time)
        }
    }
}

