import XCTest
import _AppStorageDependency
import ComposableArchitecture
@testable import DependencyAppStorageTCA

final class DependencyAppStorage_TCATests: XCTestCase {
	func testBasicSettings() throws {
		withDependencies {
			$0.userDefaults = .ephemeral()
		} operation: {
			// given: default settings
			// when: TestSettings are used without further initialization
			// expect: shared TestSettings exist and value of a boolean setting is false
			XCTAssertEqual(TestSettings.shared.isSoundEnabled, false)
			// when: settings is set
			TestSettings.shared.isSoundEnabled = true
			// expect: value is changed
			XCTAssertEqual(TestSettings.shared.isSoundEnabled, true)
		}
	}
	
	@MainActor
	func testSetReducerEffect() async throws {
		// given: userDefaults on default values
		await withDependencies {
			$0.userDefaults = .ephemeral()
		} operation: {
			let store: TestStoreOf<TestReducer> = TestStore<TestReducer.State, TestReducer.Action> (
				initialState: TestReducer.State(),
				reducer: { TestReducer() }
			)
			// expect: isSoundEnabled is false
			XCTAssertEqual(TestSettings.shared.isSoundEnabled, false)
			// when: action is sent to Reducer
			await store.send(.toggleIsSoundEnabled)
			// expect: setting is changed asynchronously
			XCTAssertEqual(TestSettings.shared.isSoundEnabled, true)
		}
	}
	
	@MainActor
	func testBindToState() async throws {
		await withDependencies {
			$0.userDefaults = .ephemeral()
		} operation: {
			let store: TestStoreOf<TestReducer> = TestStore<TestReducer.State, TestReducer.Action> (
				initialState: TestReducer.State(),
				reducer: { TestReducer() }
			)
			// given: bindSettingsToState action is sent to Reducer
			let effect = await store.send(.bindSettingsToState)
			
			// when: AppStorage setting is changed
			TestSettings.shared.isSoundEnabled = true
			// expect: the corresponding state variable is synchronized with a binding action
			await store.receive(.binding(.set(\.isSoundEnabledMirror, true))) {
				$0.isSoundEnabledMirror = true
			}
			// clean up
			await effect.cancel()
		}
	}
	
	@MainActor
	func testBindToAppStorage() async throws {
		await withDependencies {
			$0.userDefaults = .ephemeral()
		} operation: {
			let store: TestStoreOf<TestReducer> = TestStore<TestReducer.State, TestReducer.Action> (
				initialState: TestReducer.State(),
				reducer: { TestReducer() }
			)
			
			// when: binding action is sent to set userName
			await store.send(.binding(.set(\.userName, "User Tom"))) {
				$0.userName = "User Tom"
			}
			// expect: the corresponding AppStorage value is set to the same value
			XCTAssertEqual(TestSettings.shared.username, "User Tom")
		}
	}
}
