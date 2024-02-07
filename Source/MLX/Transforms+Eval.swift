// Copyright © 2024 Apple Inc.

import Cmlx
import Foundation

/// Evaluate one or more `MLXArray`
///
/// ### See Also
/// - <doc:lazy-evaluation>
public func eval(_ arrays: MLXArray...) {
    let vector_array = new_mlx_vector_array(arrays)
    mlx_eval(vector_array)
    mlx_free(vector_array)
}

/// Evaluate one or more `MLXArray`
///
/// ### See Also
/// - <doc:lazy-evaluation>
public func eval(_ arrays: [MLXArray]) {
    let vector_array = new_mlx_vector_array(arrays)
    mlx_eval(vector_array)
    mlx_free(vector_array)
}

/// Evaluate one or more `MLXArray`.
///
/// This variant allows several structured types:
///
/// ```swift
/// let a: MLXArray
/// let b: [MLXArray]
/// let c: [String:MLXArray]
/// let d: [String:[MLXArray]]
/// let e: (MLXArray, MLXArray)
/// let f: [(String, MLXArray)]
/// let nested: [(MLXArray, [MLXArray])]
///
/// eval(a, b, c, d, e, f)
/// ```
///
/// Other structured types may be supported -- check the implementation.
///
/// ### See Also
/// - <doc:lazy-evaluation>
public func eval(_ values: Any...) {
    var arrays = [MLXArray]()

    for item in values {
        collect(item, into: &arrays)
    }

    eval(arrays)
}

/// Evaluate one or more `MLXArray`.
///
/// See ``eval(_:)``
public func eval(_ values: [Any]) {
    var arrays = [MLXArray]()

    for item in values {
        collect(item, into: &arrays)
    }

    eval(arrays)
}

private func simplify(arrays: [MLXArray]) {
    let vector_array = new_mlx_vector_array(arrays)
    mlx_simplify(vector_array)
    mlx_free(vector_array)
}

/// Simplify the graph that computes the arrays.
///
/// Run a few fast graph simplification operations to reuse computation and
/// reduce memory consumption. This function is meant to be run every time
/// so its overhead should be small, approximately 1ms for a graph with a
/// few thousand nodes.
///
/// For example:
///
/// ```swift
/// import MLX
///
/// func foo(_ x: MLXArray) -> MLXArray {
///     let y = x.matmul(x)
///     let z = x.matmul(x)
///     return y + z
/// }
///
/// let x = MLXArray.ones([10, 10])
/// let y = foo(x)
/// let z = foo(x)
///
/// // computes matmul twice
/// eval(y)
///
/// // computes matmul once
/// simplify(z)
/// eval(z)
/// ```
public func simplify(_ values: Any...) {
    var arrays = [MLXArray]()

    for item in values {
        collect(item, into: &arrays)
    }

    simplify(arrays: arrays)
}

/// Simplify the graph that computes the arrays.
///
/// See ``simplify(_:)-7jbpa``
public func simplify(_ values: [Any]) {
    var arrays = [MLXArray]()

    for item in values {
        collect(item, into: &arrays)
    }

    simplify(arrays: arrays)
}

private func collect(_ item: Any, into arrays: inout [MLXArray]) {
    switch item {
    case let v as NestedDictionary<String, MLXArray>:
        arrays.append(contentsOf: v.flattened().map { $0.1 })

    case let v as MLXArray:
        arrays.append(v)
    case let v as [MLXArray]:
        arrays.append(contentsOf: v)
    case let v as [Any]:
        for item in v {
            collect(item, into: &arrays)
        }
    case let v as [AnyHashable: Any]:
        for item in v.values {
            collect(item, into: &arrays)
        }
    case let v as (Any, Any):
        collect(v.0, into: &arrays)
        collect(v.1, into: &arrays)
    case let v as (Any, Any, Any):
        collect(v.0, into: &arrays)
        collect(v.1, into: &arrays)
        collect(v.2, into: &arrays)
    case let v as (Any, Any, Any, Any):
        collect(v.0, into: &arrays)
        collect(v.1, into: &arrays)
        collect(v.2, into: &arrays)
        collect(v.3, into: &arrays)
    case let v as (Any, Any, Any, Any, Any):
        collect(v.0, into: &arrays)
        collect(v.1, into: &arrays)
        collect(v.2, into: &arrays)
        collect(v.3, into: &arrays)
        collect(v.4, into: &arrays)
    case is String, is any BinaryInteger, is any BinaryFloatingPoint:
        // ignore, e.g. (String, MLXArray)
        break
    default:
        fatalError("Unable to extract MLXArray from \(item)")
    }
}
