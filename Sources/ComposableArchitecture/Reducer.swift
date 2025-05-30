/// A protocol that describes how to evolve the current state of an application to the next state,
/// given an action, and describes what ``Effect``s should be executed later by the store, if any.
public protocol Reducer<State, Action> {
  /// A type that holds the current state of the reducer.
  associatedtype State

  /// A type that holds all possible actions that cause the ``State`` of the reducer to change
  /// and/or kick off a side ``Effect`` that can communicate with the outside world.
  associatedtype Action

  /// A type representing the body of this reducer.
  ///
  /// When you create a custom reducer by implementing the ``body-swift.property``, Swift infers
  /// this type from the value returned.
  ///
  /// If you create a custom reducer by implementing the ``reduce(into:action:)-1t2ri``, Swift
  /// infers this type to be `Never`.
  associatedtype Body

  /// Evolves the current state of the reducer to the next state.
  ///
  /// Implement this requirement for "primitive" reducers, or reducers that work on leaf node
  /// features. To define a reducer by combining the logic of other reducers together, implement the
  /// ``body-swift.property`` requirement instead.
  ///
  /// - Parameters:
  ///   - state: The current state of the reducer.
  ///   - action: An action that can cause the state of the reducer to change, and/or kick off a
  ///     side effect that can communicate with the outside world.
  /// - Returns: An effect that can communicate with the outside world and feed actions back into
  ///   the system.
  func reduce(into state: inout State, action: Action) -> Effect<Action>

  /// The content and behavior of a reducer that is composed from other reducers.
  ///
  /// In the body of a reducer one can compose many reducers together, which will be run in order,
  /// from top to bottom, and usually involves some reducer operations for integrating, such as
  /// `ifLet`, `forEach`, `_printChanges`, etc.:
  ///
  /// ```swift
  /// var body: some ReducerOf<Self> {
  ///   Reduce { state, action in
  ///     …
  ///   }
  ///   .ifLet(\.child, action: \.child) {
  ///     ChildFeature()
  ///   }
  ///   ._printChanges()
  ///
  ///   Analytics()
  /// }
  /// ```
  ///
  /// Do not invoke this property directly.
  ///
  /// > Important: if your reducer implements the ``reduce(into:action:)-1t2ri`` method, it will
  /// > take precedence over this property, and only ``reduce(into:action:)-1t2ri`` will be called
  /// > by the ``Store``. If your reducer assembles a body from other reducers and has additional
  /// > business logic it needs to layer into the system, introduce this logic into the body
  /// > instead, either with ``Reduce``, or with a separate, dedicated conformance.
  @ReducerBuilder<State, Action>
  var body: Body { get }
}

extension Reducer where Body == Never {
  /// A non-existent body.
  ///
  /// > Warning: Do not invoke this property directly. It will trigger a fatal error at runtime.
  @_transparent
  public var body: Body {
    fatalError(
      """
      '\(Self.self)' has no body. …

      Do not access a reducer's 'body' property directly, as it may not exist. To run a reducer, \
      call 'Reducer.reduce(into:action:)', instead.
      """
    )
  }
}

extension Reducer where Body: Reducer<State, Action> {
  /// Invokes the ``Body-40qdd``'s implementation of ``reduce(into:action:)-1t2ri``.
  @inlinable
  @_optimize(none)
  public func reduce(
    into state: inout Body.State, action: Body.Action
  ) -> Effect<Body.Action> {
    self.body.reduce(into: &state, action: action)
  }
}

/// A convenience for constraining a ``Reducer`` conformance.
///
/// This allows you to specify the `body` of a ``Reducer`` conformance like so:
///
/// ```swift
/// var body: some ReducerOf<Self> {
///   // ...
/// }
/// ```
///
/// …instead of the more verbose:
///
/// ```swift
/// var body: some Reducer<State, Action> {
///   // ...
/// }
/// ```
public typealias ReducerOf<R: Reducer> = Reducer<R.State, R.Action>
