//
//  Promise.swift
//  Aerodramus
//
//  Created by 金晓龙 on 2017/7/28.
//  Copyright © 2017年 Zodiac.com. All rights reserved.
//

import Foundation

private enum PromiseSettled<T> {
    case resolved(T?)
    case rejected(Error?)
}

extension PromiseSettled : CustomStringConvertible {
    var description: String {
        switch self {
        case .resolved(let value):
            return ".resolved(\(String(describing: value)))"
        case .rejected(let error):
            return ".rejected(\(String(describing: error)))"
        }
    }
}

private enum PromiseStates<T> {
    case pending
    case settled(PromiseSettled<T>)
}

extension PromiseStates : CustomStringConvertible {
    var description: String {
        switch self {
        case .pending:
            return ".pending"
        case .settled(let settled):
            return ".settled(\(settled))"
        }
    }
}


public class Promise<Result> {
    
    private var state: PromiseStates<Result> = .pending
    
    fileprivate var tuples = (
        doneFilters: Callbacks<Result?, Void>(options: [.once, .memory]),
        failFilters: Callbacks<Error?, Void>(options: [.once, .memory]),
        progressFilters: Callbacks<Progress?, Void>(options: [.memory])
    )
    
    fileprivate init() {
        tuples.doneFilters.add({ [weak self] in self?.state = .settled(.resolved($0)) })
            .add({ [weak self] _ in self?.tuples.failFilters.disable() })
            .add({ [weak self] _ in self?.tuples.progressFilters.lock() })
        
        tuples.failFilters.add({ [weak self] in self?.state = .settled(.rejected($0)) })
            .add({ [weak self] _ in self?.tuples.doneFilters.disable() })
            .add({ [weak self] _ in self?.tuples.progressFilters.lock() })
    }
    
    @discardableResult
    public func done(_ filter: @escaping (Result?) -> Void) -> Self {
        tuples.doneFilters.add(filter)
        return self
    }
    
    @discardableResult
    public func fail(_ filter: @escaping (Error?) -> Void) -> Self {
        tuples.failFilters.add(filter)
        return self
    }
    
    @discardableResult
    public func progress(_ filter: @escaping (Progress?) -> Void) -> Self {
        tuples.progressFilters.add(filter)
        return self
    }
    
    @discardableResult
    public func always(_ filter: @escaping (Result?, Error?) -> Void) -> Self {
        return done({ filter($0, nil) }).fail({ filter(nil, $0) })
    }
    
    @discardableResult
    public func then<T>(_ doneFilter: @escaping (Result?) throws -> T?,
                        _ failFilter: ((Error?) -> Error?)! = nil,
                        _ progressFilter: ((Progress?) -> Progress?)! = nil) -> Promise<T> {
        return Deferred<T>({ [weak self] newDefer in
            self?.done({
                do {
                    let returned = try doneFilter($0)
                    newDefer.resolve(with: returned)
                }
                catch {
                    newDefer.reject(with: error)
                }
            }).fail({
                newDefer.reject(with: failFilter?($0))
            }).progress({
                newDefer.notify(with: progressFilter?($0))
            })
            
        }).promise()
    }
    
    @discardableResult
    public func then<T>(_ doneFilter: @escaping (Result?) throws -> Promise<T>,
                        _ failFilter: ((Error?) -> Error?)! = nil,
                        _ progressFilter: ((Progress?) -> Progress?)! = nil) -> Promise<T> {
        return Deferred<T>({ [weak self] newDefer in
            self?.done({ result in
                do {
                    let returned = try doneFilter(result)
                    returned.promise().done({ newDefer.resolve(with: $0) })
                        .fail({ newDefer.reject(with: $0) })
                        .progress({ newDefer.notify(with: $0) })
                }
                catch {
                    newDefer.reject(with: error)
                }
            }).fail({
                newDefer.reject(with: failFilter?($0))
            }).progress({
                newDefer.notify(with: progressFilter($0))
            })
        }).promise()
    }
    
    public func promise() -> Promise<Result> {
        return self
    }
    
}

// MARK: - Prmose State
public extension Promise {
    
    public func isPending() -> Bool {
        switch state {
        case .pending:
            return true
        default:
            return false
        }
    }
    
    public func isSettled() -> Bool {
        return !isPending()
    }
    
    public func isResolved() -> Bool {
        switch state {
        case .settled(let settled):
            switch settled {
            case .resolved(_):
                return true
            default:
                return false
            }
        default:
            return false
        }
    }
    
    public func isRejected() -> Bool {
        return isSettled() && !isResolved()
    }
    
}

extension Promise : CustomStringConvertible {
    
    public var description: String {
        return "<\(type(of: self)): \(Unmanaged.passUnretained(self).toOpaque()); state = \(state)>"
    }
    
}


public class Deferred<Result> : Promise<Result> {
    
    deinit {
        print("deinit \(self)")
    }
    
    public init(_ operation: ((_ deferred: Deferred<Result>) -> Void)! = nil) {
        super.init()
        operation?(self)
    }
    
    @discardableResult
    public func resolve(with result: Result?) -> Self {
        tuples.doneFilters.fire(with: result)
        return self
    }
    
    @discardableResult
    public func reject(with error: Error?) -> Self {
        tuples.failFilters.fire(with: error)
        return self
    }
    
    @discardableResult
    public func notify(with progress: Progress?) -> Self {
        tuples.progressFilters.fire(with: progress)
        return self
    }
    
}

public extension Deferred {
    
    public class func when<T>(_ subordinates: Promise<T> ...) -> Promise<[T?]> {
        return Deferred<[T?]>({ deferred in
            var remaining = subordinates.count
            var results = [T?](repeating: nil, count: remaining)
            
            for (index, subordinate) in subordinates.enumerated() {
                subordinate.done({
                    results[index] = $0
                    remaining -= 1
                    if remaining == 0 {
                        deferred.resolve(with: results)
                    }
                }).fail({
                    deferred.reject(with: $0)
                }).progress({
                  deferred.notify(with: $0)
                })
            }
        }).promise()
    }
    
}

// MARK: - Initialization
public extension Deferred {
    
    convenience init(result: Result) {
        self.init { deferred in
            deferred.resolve(with: result)
        }
    }
    
    convenience init(error: Error) {
        self.init({ deferred in
            deferred.reject(with: error)
        })
    }
    
}
