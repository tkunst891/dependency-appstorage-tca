import DependencyAppStorageTCA
import _AppStorageDependency

final class TestSettings: DependencySettings {
	@Dependency.AppStorage("username") var username: String?
	@Dependency.AppStorage("isSoundEnabled") var isSoundEnabled: Bool = false
}


