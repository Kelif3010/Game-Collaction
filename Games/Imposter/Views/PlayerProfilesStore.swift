import Foundation

// MARK: - PlayerProfile

/// A model representing a player profile.
public struct PlayerProfile: Codable, Hashable, Identifiable {
    public let id: UUID
    public var name: String
    public var lastUsed: Date
    public var usageCount: Int

    /// Initializes a new player profile with a given name.
    /// - Parameter name: The name of the player.
    public init(name: String) {
        self.id = UUID()
        self.name = name
        self.lastUsed = Date()
        self.usageCount = 0
    }

    /// A normalized version of the name by trimming whitespace and newlines.
    var normalizedName: String {
        name.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}

// MARK: - PlayerProfilesStoring

/// A protocol defining a storage interface for player profiles.
/// 
/// Implementers provide synchronous, main-thread-friendly methods to load, save,
/// add, remove, and clear player profiles. Profiles are managed primarily by their normalized names.
/// 
/// Future implementations may support persistence in different mediums (e.g. database, file, cloud)
/// and asynchronous operations if needed.
protocol PlayerProfilesStoring: AnyObject {
    /// Loads all player profiles currently stored.
    /// - Returns: An array of stored `PlayerProfile` objects.
    func loadAll() -> [PlayerProfile]

    /// Saves an array of player profiles, replacing existing stored data.
    /// - Parameter profiles: The profiles to save.
    func save(_ profiles: [PlayerProfile])

    /// Adds a player profile with the given name.
    /// If a profile with the normalized name exists, it updates its usage info.
    /// - Parameter name: The name of the player to add.
    func add(name: String)

    /// Adds multiple player profiles by their names.
    /// - Parameter names: The names to add.
    func add(names: [String])

    /// Removes the player profile with the matching normalized name.
    /// - Parameter name: The name of the player to remove.
    func remove(name: String)

    /// Clears all stored player profiles.
    func clear()

    /// Marks the given player names as used, updating their lastUsed date and usage count.
    /// This is a convenience method and may have a default implementation in conforming classes.
    /// - Parameter names: The names to mark as used.
    func markUsed(names: [String])
}

// MARK: - UserDefaultsPlayerProfilesStore

/// A concrete player profiles storage implementation backed by `UserDefaults`.
///
/// This store keeps an in-memory cache of profiles for performance and synchronizes changes
/// immediately to UserDefaults. It supports adding, removing, clearing, and marking profiles as used.
/// 
/// Sorting order for loaded profiles is by lastUsed (descending), usageCount (descending),
/// then name (ascending, case-insensitive).
@MainActor
final class UserDefaultsPlayerProfilesStore: PlayerProfilesStoring {
    /// The shared singleton instance for global access.
    static let shared = UserDefaultsPlayerProfilesStore()

    private let defaults = UserDefaults.standard
    private let key = "player_profiles_store_v1"
    private var cache: [PlayerProfile] = []

    private let encoder: JSONEncoder = {
        let e = JSONEncoder()
        e.dateEncodingStrategy = .iso8601
        return e
    }()

    private let decoder: JSONDecoder = {
        let d = JSONDecoder()
        d.dateDecodingStrategy = .iso8601
        return d
    }()

    /// Initializes the store and loads existing profiles from UserDefaults.
    private init() {
        loadFromDefaults()
    }

    func loadAll() -> [PlayerProfile] {
        cache.sorted {
            if $0.lastUsed != $1.lastUsed {
                return $0.lastUsed > $1.lastUsed
            }
            if $0.usageCount != $1.usageCount {
                return $0.usageCount > $1.usageCount
            }
            return $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending
        }
    }

    func save(_ profiles: [PlayerProfile]) {
        // Deduplicate by normalized name (case-insensitive), keep last occurrence
        var uniqueProfilesDict = [String: PlayerProfile]()
        for profile in profiles {
            let key = profile.normalizedName.lowercased()
            uniqueProfilesDict[key] = profile
        }
        cache = Array(uniqueProfilesDict.values)
        persist()
    }

    func add(name: String) {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        if let index = indexOfName(trimmed) {
            // Exists: update lastUsed and usageCount
            var existing = cache[index]
            existing.lastUsed = Date()
            existing.usageCount += 1
            cache[index] = existing
        } else {
            // New profile
            let newProfile = PlayerProfile(name: trimmed)
            cache.append(newProfile)
        }
        persist()
    }

    func add(names: [String]) {
        for name in names {
            add(name: name)
        }
    }

    func remove(name: String) {
        let normalized = name.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        cache.removeAll { $0.normalizedName.lowercased() == normalized }
        persist()
    }

    func clear() {
        cache.removeAll()
        defaults.removeObject(forKey: key)
    }

    func markUsed(names: [String]) {
        let now = Date()
        var updated = false
        for name in names {
            let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !trimmed.isEmpty else { continue }
            if let index = indexOfName(trimmed) {
                var profile = cache[index]
                profile.lastUsed = now
                profile.usageCount += 1
                cache[index] = profile
                updated = true
            }
        }
        if updated {
            persist()
        }
    }

    // MARK: - Private Helpers

    private func persist() {
        do {
            let data = try encoder.encode(cache)
            defaults.set(data, forKey: key)
        } catch {
            // Failure to save silently ignored
        }
    }

    private func loadFromDefaults() {
        guard let data = defaults.data(forKey: key) else {
            cache = []
            return
        }
        do {
            cache = try decoder.decode([PlayerProfile].self, from: data)
        } catch {
            cache = []
        }
    }

    private func indexOfName(_ name: String) -> Int? {
        let normalized = name.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        return cache.firstIndex { $0.normalizedName.lowercased() == normalized }
    }
}
