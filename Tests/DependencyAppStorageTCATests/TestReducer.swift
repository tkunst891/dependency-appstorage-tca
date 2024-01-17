import ComposableArchitecture
import DependencyAppStorageTCA

/// Reducer to test three features of the library
///
/// * when action toggleIsSoundEnabled is sent, the corresponting AppStorage value will be toggled
/// * when action bindSettingsToState is sent, then setting AppStorage value isSoundEnabled will be mirrored in the corresponding State variable
/// * when State variable userName is set (using a binding action), the corresponding AppStorage value is set to the same value
@Reducer
struct TestReducer {
	@ObservableState
	struct State: Equatable {
		var isSoundEnabledMirror = TestSettings.shared.isSoundEnabled
		var userName: String?
	}
	
	enum Action: Equatable, BindableAction {
		case toggleIsSoundEnabled
		case bindSettingsToState
		case binding(BindingAction<State>)
	}
	
	var body: some ReducerOf<Self> {
		BindingReducer()
			.toAppStorage(state: \.userName, appStorage: \TestSettings.username)
		Reduce { state, action in
			switch action {
			case .toggleIsSoundEnabled:
				return TestSettings.shared.set(\.isSoundEnabled, to: !TestSettings.shared.isSoundEnabled)
				
			case .bindSettingsToState:
				return TestSettings.shared.$isSoundEnabled.bind(to: \State.isSoundEnabledMirror)
				
			case .binding:
				return .none
			}
		}
	}
}


