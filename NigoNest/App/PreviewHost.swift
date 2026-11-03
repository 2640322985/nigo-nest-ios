#if DEBUG
import SwiftUI

// Production views, local transport. No duplicate screenshot-only screens.
struct PreviewHost: View {
    var page: String
    @StateObject private var session = SessionStore(preview: true)
    private var selection: Int {
        switch page {
        case "plaza": 1
        case "messages": 2
        case "profile": 3
        default: 0
        }
    }
    var body: some View {
        Group {
            if page == "login" { LoginView() }
            else if page == "schedule" { CampusNavigation { ScheduleView() } }
            else if page == "themes" { CampusNavigation { ThemeSettingsView() } }
            else { RootView(initialTab: selection) }
        }.environmentObject(session)
    }
}

enum PreviewFixtures {
    static var courses: [CampusCourse] {
        [
            CampusCourse(id: "math", name: "高等数学", weekday: 2, start: 1, end: 2, place: "同和楼 A203", teacher: "陈老师", noteKey: "math", note: "带上练习册"),
            CampusCourse(id: "english", name: "大学英语", weekday: 2, start: 3, end: 4, place: "厚学楼 B305", teacher: "李老师", noteKey: "english", note: ""),
            CampusCourse(id: "physics", name: "大学物理", weekday: 2, start: 5, end: 6, place: "弘毅楼 C102", teacher: "王老师", noteKey: "physics", note: "")
        ]
    }
    static func response(_ request: URLRequest) throws -> Data {
        let path = request.url?.path ?? ""
        let object: [String: Any]
        switch path {
        case "/api/posts":
            object = ["totalPages": 1, "posts": [
                ["id": 1, "studentId": "20260002", "nickname": "昨天的风", "content": "今天的校园好适合散步，下课一起走走吗？", "likeCount": 24, "commentCount": 6],
                ["id": 2, "studentId": "20260001", "nickname": "小林同学", "content": "同和楼有安静的空教室吗？下午想找个地方复习。", "likeCount": 12, "commentCount": 3],
                ["id": 3, "studentId": "20260003", "nickname": "阿澈", "content": "晚上有同学一起打羽毛球吗？", "likeCount": 8, "commentCount": 2]
            ]]
        case "/api/checkin":
            object = ["points": 128, "streak": 7, "checkedInToday": request.httpMethod == "POST", "nextAward": 5, "awarded": 5]
        case "/api/user/me":
            object = ["name": "小林同学", "nickname": "小林同学", "wornTitle": ["text": "校园常驻"]]
        case "/api/app/features":
            object = ["features": ["emptyClassroom": true, "courseGrab": true, "yxExam": true, "safetyExam": true]]
        case "/api/friends/unread-count": object = ["unreadCount": 2]
        case "/api/notifications/unread-count": object = ["unreadCount": 5]
        case "/api/friends":
            object = ["friends": [["studentId": "20260003", "nickname": "阿澈", "lastMessage": "晚上一起打羽毛球吗？", "unreadCount": 2]], "incoming": []]
        case "/api/notifications":
            object = ["notifications": [["id": 1, "title": "昨天的风赞了你的动态", "content": "同和楼有安静的空教室吗？", "type": "like", "read": false]]]
        case "/api/app/version": object = [:]
        default: throw APIError.message("演示模式不连接服务器；此操作请登录真实账号后使用。")
        }
        return try JSONSerialization.data(withJSONObject: object)
    }
}
#endif
