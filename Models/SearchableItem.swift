import Foundation

/// Represents an object type that can be searched for using the camera.
/// `aliases` lists the exact label strings the YOLO model may emit for this item.
struct SearchableItem: Identifiable, Hashable {
    let id = UUID()
    let name: String
    let iconName: String  // SF Symbol name
    /// Model label strings (case-insensitive exact-word match)
    let aliases: [String]

    /// Returns true if a model detection label matches this item
    func matches(label: String) -> Bool {
        let candidate = label.lowercased()
            .replacingOccurrences(of: "_", with: " ")  // handle snake_case labels
        return aliases.contains { alias in
            candidate == alias
            || candidate.contains(alias)
            || alias.contains(candidate)
        }
    }

    /// Predefined list of searchable household objects.
    /// Aliases are drawn from COCO/Objects365/YOLO common class names.
    static let allItems: [SearchableItem] = [
        SearchableItem(name: "Keys",       iconName: "key.fill",
                       aliases: ["keys", "key"]),
        SearchableItem(name: "Wallet",     iconName: "wallet.pass.fill",
                       aliases: ["wallet", "purse"]),
        SearchableItem(name: "Remote",     iconName: "tv.and.mediabox",
                       aliases: ["remote", "remote control"]),
        SearchableItem(name: "Phone",      iconName: "iphone",
                       aliases: ["cell phone", "mobile phone", "phone", "smartphone"]),
        SearchableItem(name: "Glasses",    iconName: "eyeglasses",
                       aliases: ["glasses", "sunglasses", "eyeglasses"]),
        SearchableItem(name: "Watch",      iconName: "applewatch",
                       aliases: ["watch", "wristwatch", "clock"]),
        SearchableItem(name: "Headphones", iconName: "headphones",
                       aliases: ["headphones", "earphones", "earbuds", "headset"]),
        SearchableItem(name: "Bottle",     iconName: "waterbottle.fill",
                       aliases: ["bottle", "water bottle"]),
        SearchableItem(name: "Book",       iconName: "book.fill",
                       aliases: ["book", "notebook"]),
        SearchableItem(name: "Bag",        iconName: "bag.fill",
                       aliases: ["handbag", "bag", "backpack", "suitcase", "purse"]),
        SearchableItem(name: "Cup",        iconName: "cup.and.saucer.fill",
                       aliases: ["cup", "mug", "coffee cup"]),
        SearchableItem(name: "Scissors",   iconName: "scissors",
                       aliases: ["scissors"])
    ]
}
