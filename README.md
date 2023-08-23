# Dependendy.AppStorage extensions for Composable Architecture

Extension of *AppStorage* in the package [Dependencies Additions](https://github.com/tgrapperon/swift-dependencies-additions.git) for use with the [Composable Architecture](https://github.com/pointfreeco/swift-composable-architecture)

The library aims to help with the following issues:
1. In the Composable Architecture a reducer is not supposed to perform side effects, such as updating a @Dependency.AppStorage variable directly. The reducer should delegate this to an Effect. You would need this for example when you implement a feature for editing user defaults.
2. Views should only depend on State, not on other variables. So we need a method to synchronize State with AppStorage. When the AppStorage changes (e.g. a UserDefault is updated), State should automatically be updated to reflect the new value.

## Build an object to keep all your settings

This library suggests that you group all your UserDefaults settings into one object, which will be a singleton:
```swift
final class MySettings: DependencySettings {
    @Dependency.AppStorage("username") var username: String?
    @Dependency.AppStorage("isSoundEnabled") var isSoundEnabled: Bool = false
}
```

The protocol `DependencySettings` enforces that your class has a default initializer and will automatically create a static instance `.shared`. So you can access the setting for example in your reducer:
```swift
if MySettings.shared.isSoundEnabled {
    ...
}
```
The protocol also adds a `set` method to your DependencySettings class, which helps with issue #1. above.
```swift
MySettings.shared.set(\.isSoundEnabled, to: true)
```
However, this method will not set the AppStorage's value directly. Instead, it will return an Effect that you can return from your reducer:
```swift
switch action {
case .enableSoundButtonPressed:
    return MySettings.shared.set(\.isSoundEnabled, to: true)
}
```
The Effect returned by the `set` method is a `.run` Effect, which will be executed by the Store.

## Using BindableState to edit user settings
If you use a `BindingReducer`and `BindableState` to let the user edit some settings, you could do this in the following way:
```swift
struct State {
    @BindableState username: String = MySettings.shared.userName
    ... other state
}
enum Action: BindableAction {
    case binding(BindingAction<State>)
    ... other actions
}

var body: some ReducerProtocol<State, Action> {
    BindingReducer()
    Reduce { state, action in
        switch action {
        case .binding(\.$username):
            return MySettings.shared.set(\.username, to: state.username)
        ... other cases
        }
    }
```
This way, any time the user changes the value in the form, the reducer catches the `.binding` action and sets the corresponding AppStorage variable.

This can be further simplified, as the library provides a higher-level BindingReducer:
```swift
var body: some ReducerProtocol<State, Action> {
    BindingReducer()
        .toAppStorage(from: \.$username, to: \MySettings.username)
```
The `.toAppStorage` methods can be chained:
```swift
var body: some ReducerProtocol<State, Action> {
    BindingReducer()
        .toAppStorage(from: \.$username, to: \MySettings.username)
        .toAppStorage(from: \.$isSoundEnabled, to: \MySettings.isSoundEnabled)
```

## Synchronizing State with AppStorage

You might have the idea that you could make an AppStorage variable part of your State, for example to display it in a view:
```swift
struct State {
    @Dependency.AppStorage("username") var username: String?
}
```
But this is not a good solution:
- `@Dependency.AppStorage` is not `Equatable`, and it would not make sense to make it Equatable by some extension.
- Therefore the view can not detect a change of the value.

A better solution is to have an ordinary variable in your State, which always reflects the value of the corresponding AppStorage variable.

The library provides a way to create a long-lived Effect which automatically synchronizes some `BindableState` with an AppStorage variable. It takes advantage of the fact that @Dependency.AppStorage provides a projected value which is an AsyncStream.
```swift
MySettings.shared.$isSoundEnabled.bind(to: \.$isSoundEnabled)
```
The `.bind` method returns a long-lived Effect of type `.run` which will send a `.binding(.set(\.$isSoundEnabled, newValue))` action, anytime the AppStorage variable changes its value.

So the setup of a feature reducer which wants to synchronize some state to an AppStorage variable looks like this:
```swift
struct State {
    @BindableState isSoundEnabled: String = MySettings.shared.isSoundEnabled
    ... other state
}
enum Action: BindableAction {
    case binding(BindingAction<State>)
    case bindSettings // this action will be used to create the long-lived Effect
    ... other actions
}

var body: some ReducerProtocol<State, Action> {
    BindingReducer()
    Reduce { state, action in
        switch action {
        case .bindSettings:
            return MySettings.shared.$isSoundEnabled.bind(to: \.$isSoundEnabled)
            ... other cases
        }
    }
```
The action which creates the Effect (in the above case the action `.bindSettings`, but you can choose any name) can for example be sent from the view which wants to display the state, using a `.task` modifier:
```swift
.task {
    viewStore.send(.bindSettings)
}
```
This way, the long-lived Effect will be bound to the lifetime of the view: it will automatically be canceled, when the view ceases to exist.

If you want to synchronize more than one setting to your State, use the `.merge` Effect to merge the synchronizing effects:
```swift
case .bindSettings:
    return .merge(
        MySettings.shared.$isSoundEnabled.bind(to: \.$isSoundEnabled),
        MySettings.shared.$username.bind(to: \.$username)
    )
```
