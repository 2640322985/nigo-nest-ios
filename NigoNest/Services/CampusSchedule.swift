import Foundation

struct CampusCourse: Codable, Identifiable {
    var id: String
    var name: String
    var weekday: Int
    var start: Int
    var end: Int
    var place: String
    var teacher: String
    var noteKey: String
    var note: String
}

enum CampusSchedule {
    static func key(_ student: String) -> String { "nigo.schedule.\(student)" }
    static func load(student: String) -> [CampusCourse] {
        guard let data = UserDefaults.standard.data(forKey: key(student)) else { return [] }
        return (try? JSONDecoder().decode([CampusCourse].self, from: data)) ?? []
    }
    static func save(_ courses: [CampusCourse], student: String) {
        guard let data = try? JSONEncoder().encode(courses) else { return }
        UserDefaults.standard.set(data, forKey: key(student))
    }
    static func weekday(_ date: Date) -> Int {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "Asia/Shanghai")!
        let value = calendar.component(.weekday, from: date)
        return value == 1 ? 7 : value - 1
    }
}
