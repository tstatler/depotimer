import Foundation

public enum DepoFormat {
    public static func seconds(_ totalSec: Int) -> String {
        let h = totalSec / 3600
        let m = (totalSec % 3600) / 60
        let s = totalSec % 60
        if h > 0 { return "\(h)h \(m)m \(s)s" }
        if m > 0 { return "\(m)m \(s)s" }
        return "\(s)s"
    }

    public static func time(_ date: Date) -> String {
        let f = DateFormatter()
        f.dateFormat = "h:mm:ss a"
        return f.string(from: date)
    }
}
