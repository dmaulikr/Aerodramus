//
//  Callbacks.swift
//  Aerodramus
//
//  Created by 金晓龙 on 2017/7/28.
//  Copyright © 2017年 Zodiac.com. All rights reserved.
//

import Foundation

public struct CallbacksOptions : OptionSet {
    
    public let rawValue: UInt
    public init(rawValue value: UInt) {
        rawValue = value
    }
    
    public static let none          = CallbacksOptions(rawValue: 0)
    /// Once: will ensure the callback list can only be fired once
    public static let once          = CallbacksOptions(rawValue: 1 << 0)
    /// Memory: will keep track of previous values and will call any
    /// callback added after the list has been fired right away with
    /// the latest 'memorized' values
    public static let memory        = CallbacksOptions(rawValue: 1 << 1)
    /// StopOnFalse: interrupt callings when a callback returns false
    public static let stopOnFalse   = CallbacksOptions(rawValue: 1 << 2)
    
}

extension CallbacksOptions : CustomStringConvertible {
    
    /// A textual representation of this instance
    public var description: String {
        let optionDescriptionMap = [
            (CallbacksOptions.once, ".once"),
            (CallbacksOptions.memory, ".memory"),
            (CallbacksOptions.stopOnFalse, ".stopOnFalse")
        ]
        
        let optionDescrition = optionDescriptionMap.filter({
            self.contains($0.0)
        }).map({
            $0.1
        }).joined(separator: "|")
        return "[\(optionDescrition)]"
    }
    
}

private struct CallbacksFlags : OptionSet {
    
    let rawValue: UInt
    init(rawValue value: UInt) {
        rawValue = value
    }
    
    static let none     = CallbacksFlags(rawValue: 0)
    /// Fired: flag to know if list was already fired
    static let fired    = CallbacksFlags(rawValue: 1 << 0)
    /// Firing: flag to know if list is currently firing
    static let firing   = CallbacksFlags(rawValue: 1 << 1)
    /// Locked: flag to prevent firing
    static let locked   = CallbacksFlags(rawValue: 1 << 2)
    
}

public class Callbacks<Argument, Result> {
    
    public typealias CallbackClosure = (Argument) -> Result
    
    public private(set) var options: CallbacksOptions
    
//    deinit {
//        print("deinit \(self)")
//    }
    
    /// Create a callback list using CallbackOptions
    public init(options opts: CallbacksOptions) {
        options = opts
    }
    
    /// Flags to know the status of callback list
    private var flags = CallbacksFlags.none
    /// Actual callback list
    fileprivate var callbackList: [CallbackClosure]! = []
    /// Queue of execution data for repeatable lists (has not .once option)
    private var argumentQueue: [Argument] = []
    /// After fired, lastArgument will nerver be nil, even Argument is an optional type.
    /// The predication: .Some(.None) == nil is always false
    private var lastArgument: Argument? = nil
    /// Index of currently firing callback (modified by add/remove as needed)
    private var firingIndex: Int = 0
    
    /// Firing callbacks
    private func fire() {
        // Enforce single-firing
        if options.contains(.once) {
            flags.insert(.locked)
        }
        
        flags.insert([.fired, .firing])
        while argumentQueue.count > 0 {
            firingIndex = 0
            let memory = argumentQueue.removeFirst()
            lastArgument = memory
            
            while firingIndex < (callbackList?.count ?? 0) {
                if let _ = callbackList {
                    // Run callback and check for early termination
                    let resultIsFalse =  !(callbackList[firingIndex](memory) as? Bool ?? true)
                    if resultIsFalse && options.contains(.stopOnFalse) {
                        // Jump to end and forget the data so add function doesn't re-fire
                        firingIndex = callbackList.count
                        lastArgument = nil
                    }
                }
                firingIndex += 1
            }
        }
        
        flags.remove(.firing)
        if !options.contains(.memory) {
            lastArgument = nil
        }
        
        // Clean up if we're done firing for good
        if flags.contains(.locked) {
            // Keep an empty list if we have data for future add calls
            // otherwise the callback list is spent, set it with nil
            callbackList = lastArgument != nil ? [] : nil
        }
    }
    
    /// Add a callback to the list
    @discardableResult
    public func add(_ callback: @escaping CallbackClosure) -> Self {
        if let _ = callbackList {
            callbackList.append(callback)
            
            // if we have memory from a past run,
            // we should fire after adding
            if !flags.contains(.firing) {
                if let memory = lastArgument {
                    firingIndex = callbackList.count - 1
                    argumentQueue.append(memory)
                    fire()
                }
            }
        }
        return self
    }
    
    /// Remove all callback from the callback list
    @discardableResult
    public func removeAll() -> Self {
        callbackList?.removeAll()
        return self
    }
    
    /// Check whether the callback list is empty
    public func isEmpty() -> Bool {
        return callbackList?.isEmpty ?? true
    }
    
    /// Disable function .fire() and .add()
    /// Abort any current/pending executions
    /// Clear all callbacks and arguments
    @discardableResult
    public func disable() -> Self {
        flags.insert(.locked)
        lastArgument = nil
        callbackList = nil
        argumentQueue = []
        return self
    }
    
    public func isDisable() -> Bool {
        return callbackList == nil
    }
    
    /// Disable function .fire()
    /// Also disable function .add() unless we have option .memory
    /// Abort any pending executions
    @discardableResult
    public func lock() -> Self {
        flags.insert(.locked)
        if lastArgument == nil {
            disable()
        }
        return self
    }
    
    public func isLocked() -> Bool {
        return flags.contains(.locked)
    }
    
    /// Call all callbacks with the given argument
    @discardableResult
    public func fire(with argument: Argument) -> Self {
        if !flags.contains(.locked) {
            argumentQueue.append(argument)
            if !flags.contains(.firing) {
                fire()
            }
        }
        return self
    }
    
    /// To known whether the callbacks have already been called at least once
    public func isFired() -> Bool {
        return flags.contains(.fired)
    }
    
}

extension Callbacks : CustomDebugStringConvertible {
    
    /// A textual representation of this instance, suitable for debugging.
    public var debugDescription: String {
        return "<\(type(of: self)): \(Unmanaged.passUnretained(self).toOpaque()); options = \(options)>"
    }
    
}



