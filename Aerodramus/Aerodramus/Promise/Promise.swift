//
//  Promise.swift
//  Aerodramus
//
//  Created by 金晓龙 on 2017/7/28.
//  Copyright © 2017年 Zodiac.com. All rights reserved.
//

import Foundation

private enum PromiseSettled<T> {
    
    case resolved(T)
    case rejected(Error)

}

extension PromiseSettled : CustomStringConvertible {
    
    var description: String {
        switch self {
        case .resolved(let value):
            return ".resolved(\(value))"
        case .rejected(let error):
            return ".rejected(\(error))"
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
            return "\(settled)"
        }
    }
    
}


open class Promise<Result> {
    
//    deinit {
//        print("deinit \(self)")
//    }
    
    private var state: PromiseStates<Result> = .pending
    
    private var tuples = (
        doneFilters: Callbacks<Result, Void>(options: [.once, .memory]),
        failFilters: Callbacks<Error, Void>(options: [.once, .memory]),
        progressFilters: Callbacks<Progress, Void>(options: [.memory])
    )
    
    public typealias Deferred = (
        resolve: (_ result: Result) -> Void,
        reject: (_ error: Error) -> Void,
        notify: (_ progress: Progress) -> Void
    )
    
    public init(_ operation: (_ deferred: Deferred) -> Void) {
        tuples.doneFilters.add({ [weak self] in self?.state = .settled(.resolved($0)) })
            .add({ [weak self] _ in self?.tuples.failFilters.disable() })
            .add({ [weak self] _ in self?.tuples.progressFilters.lock() })
        
        tuples.failFilters.add({ [weak self] in self?.state = .settled(.rejected($0)) })
            .add({ [weak self] _ in self?.tuples.doneFilters.disable() })
            .add({ [weak self] _ in self?.tuples.progressFilters.lock() })

        operation((
            { self.tuples.doneFilters.fire(with: $0) },
            { self.tuples.failFilters.fire(with: $0) },
            { self.tuples.progressFilters.fire(with: $0) }
        ))
    }
    
    @discardableResult
    public func done(_ filter: @escaping (Result) -> Void) -> Self {
        tuples.doneFilters.add(filter)
        return self
    }
    
    @discardableResult
    public func fail(_ filter: @escaping (Error) -> Void) -> Self {
        tuples.failFilters.add(filter)
        return self
    }
    
    @discardableResult
    public func progress(_ filter: @escaping (Progress) -> Void) -> Self {
        tuples.progressFilters.add(filter)
        return self
    }
    
    @discardableResult
    public func always(_ filter: @escaping (Result?, Error?) -> Void) -> Self {
        return done({ filter($0, nil) }).fail({ filter(nil, $0) })
    }
    
    @discardableResult
    public func then<T>(_ doneFilter: @escaping (Result) throws -> T,
                        _ failFilter: @escaping (Error) -> Error = { $0 },
                        _ progressFilter: @escaping (Progress) -> Progress = { $0 }) -> Promise<T> {
        return Promise<T>({ [weak self] newDefer in
            self?.done({
                do {
                    let returned = try doneFilter($0)
                    newDefer.resolve(returned)
                }
                catch {
                    newDefer.reject(error)
                }
            }).fail({
                newDefer.reject(failFilter($0))
            }).progress({
                newDefer.notify(progressFilter($0))
            })
        })
    }
    
    @discardableResult
    public func then<T>(_ doneFilter: @escaping (Result) throws -> Promise<T>,
                        _ failFilter: @escaping (Error) -> Error = { $0 },
                        _ progressFilter: @escaping (Progress) -> Progress = { $0 }) -> Promise<T> {
        return Promise<T>({ [weak self] newDefer in
            self?.done({ result in
                do {
                    let returned = try doneFilter(result)
                    returned.done({ newDefer.resolve($0) })
                        .fail({ newDefer.reject($0) })
                        .progress({ newDefer.notify($0) })
                }
                catch {
                    newDefer.reject(error)
                }
            }).fail({
                newDefer.reject(failFilter($0))
            }).progress({
                newDefer.notify(progressFilter($0))
            })
        })
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

public extension Promise {
    
    public class final func when<T>(_ subordinates: Promise<T> ...) -> Promise<[T?]> {
        return Promise<[T?]>({ deferred in
            var remaining = subordinates.count
            var results = [T?](repeating: nil, count: remaining)
            
            for (index, subordinate) in subordinates.enumerated() {
                subordinate.done({
                    results[index] = $0
                    remaining -= 1
                    if remaining == 0 {
                        deferred.resolve(results)
                    }
                }).fail({
                    deferred.reject($0)
                }).progress({
                  deferred.notify($0)
                })
            }
        })
    }

}

// MARK: - Initialization
public extension Promise {
    
    convenience init(result: Result) {
        self.init({ $0.resolve(result) })
    }
    
    convenience init(error: Error) {
        self.init({ $0.reject(error) })
    }
    
}
