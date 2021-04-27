//
//  JobQueue.swift
//  
//
//  Created by Maddie Schipper on 4/27/21.
//

import Foundation
import Combine



public protocol _UTKJob {
    associatedtype Result
    
    var qos: DispatchQoS { get }
    
    var flags: DispatchWorkItemFlags { get }
    
    func scheduled()
    
    func perform() throws -> Result
}

public final class JobQueue {
    public typealias Job = _UTKJob
    
    private let semaphore: DispatchSemaphore
    private let workQueue: DispatchQueue
    
    public let concurrentJobs: Int
    
    public init(concurrentJobs: Int? = nil, target: DispatchQueue? = nil) {
        let finalConcurrentJobs = concurrentJobs ?? ProcessInfo.processInfo.activeProcessorCount

        precondition(finalConcurrentJobs > 0, "Must provide at least one concurrent job")
        
        self.concurrentJobs = finalConcurrentJobs
        self.semaphore = DispatchSemaphore(value: finalConcurrentJobs)
        self.workQueue = DispatchQueue(label: ApplicationIdentifier + ".JobQueue", attributes: .concurrent, autoreleaseFrequency: .workItem, target: target)
    }
    
    @discardableResult
    public func submit<WorkItem : Job>(_ job: WorkItem, group: DispatchGroup? = nil) -> Future<WorkItem.Result, Error> {
        return Future { promise in
            self.workQueue.async(group: group, qos: job.qos, flags: job.flags) {
                job.scheduled()
                
                self.semaphore.wait()
                defer { self.semaphore.signal() }
                
                do {
                    let result = try job.perform()
                    promise(.success(result))
                } catch {
                    promise(.failure(error))
                }
            }
        }
    }
    
    @discardableResult
    public func submitAndWait<WorkItem : Job>(_ job: WorkItem) throws -> WorkItem.Result {
        return try self.workQueue.sync {
            job.scheduled()
            
            self.semaphore.wait()
            defer { self.semaphore.signal() }
            
            return try job.perform()
        }
    }
    
    public func wait() {
        self.workQueue.sync(flags: .barrier) {}
    }
}

extension JobQueue.Job {
    public var qos: DispatchQoS { .unspecified }
    
    public var flags: DispatchWorkItemFlags { [] }
    
    public func scheduled() {}
}

extension JobQueue {
    public struct BlockItem<Result> : Job {
        private let block: () throws -> Result
        
        public init(_ block: @escaping () throws -> Result) {
            self.block = block
        }
        
        public func perform() throws -> Result {
            return try self.block()
        }
    }
    
    @discardableResult
    public func submit<Result>(_ block: @escaping () throws -> Result, group: DispatchGroup? = nil) -> Future<Result, Error> {
        return self.submit(BlockItem(block), group: group)
    }
}
