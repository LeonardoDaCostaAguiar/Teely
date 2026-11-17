import Foundation

struct Localizer {
    let bundle: Bundle

    static let main = Localizer(bundle: .main)

    func string(_ key: String) -> String {
        bundle.localizedString(forKey: key, value: nil, table: nil)
    }

    func string(_ key: String, _ arguments: CVarArg...) -> String {
        String(format: string(key), arguments: arguments)
    }
}
