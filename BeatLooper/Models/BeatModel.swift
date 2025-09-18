//
//  BeatModel.swift
//  BeatLooper 2
//
//  Created by Isaak Meier on 4/2/21.
//  Migrated to Swift
//

import Foundation
import CoreData
import AVFoundation
import CoreMedia

class BeatModel {
    
    // MARK: - Properties
    private let persistentContainer: NSPersistentContainer
    
    // MARK: - Initialization
    init() {
        // Get the persistent container from AppDelegate
        guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else {
            fatalError("Unable to get AppDelegate")
        }
        self.persistentContainer = appDelegate.container
    }
    
    // For testing purposes - do not use in production
    init(container: NSPersistentContainer) {
        self.persistentContainer = container
    }
    
    // MARK: - Core Data Context
    private var context: NSManagedObjectContext {
        return persistentContainer.viewContext
    }
    
    // MARK: - Public Methods
    
    /// Get all songs from Core Data
    func getAllSongs() -> [Beat] {
        let request: NSFetchRequest<Beat> = Beat.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(key: "songName", ascending: true)]
        
        do {
            return try context.fetch(request)
        } catch {
            print("Error fetching songs: \(error)")
            return []
        }
    }
    
    /// Get URL for cached song
    func getURLForCachedSong(songID: NSManagedObjectID) -> URL? {
        guard let song = try? context.existingObject(with: songID) as? Beat else {
            return nil
        }
        return song.songURL
    }
    
    /// Get song by name
    func getSongFromSongName(_ songName: String) -> Beat? {
        let request: NSFetchRequest<Beat> = Beat.fetchRequest()
        request.predicate = NSPredicate(format: "songName == %@", songName)
        request.fetchLimit = 1
        
        do {
            let results = try context.fetch(request)
            return results.first
        } catch {
            print("Error fetching song by name: \(error)")
            return nil
        }
    }
    
    /// Get song by unique ID
    func getSongForUniqueID(_ songID: NSManagedObjectID) -> Beat? {
        return try? context.existingObject(with: songID) as? Beat
    }
    
    /// Save song from URL
    func saveSongFromURL(_ songURL: URL) -> Bool {
        // Check if song already exists
        let songName = songURL.lastPathComponent
        if getSongFromSongName(songName) != nil {
            print("Song already exists: \(songName)")
            return false
        }
        
        // Create new Beat entity
        let beat = Beat(context: context)
        beat.songName = songName
        beat.songURL = songURL
        beat.uniqueID = UUID()
        beat.tempo = 120 // Default tempo
        
        do {
            try context.save()
            return true
        } catch {
            print("Error saving song: \(error)")
            return false
        }
    }
    
    /// Save tempo for song
    func saveTempo(_ tempo: Int, forSong songID: NSManagedObjectID) {
        guard let song = try? context.existingObject(with: songID) as? Beat else {
            print("Song not found for ID: \(songID)")
            return
        }
        
        song.tempo = Int32(tempo)
        
        do {
            try context.save()
        } catch {
            print("Error saving tempo: \(error)")
        }
    }
    
    /// Delete song
    func deleteSong(_ song: Beat) {
        context.delete(song)
        
        do {
            try context.save()
        } catch {
            print("Error deleting song: \(error)")
        }
    }
    
    /// Delete all entities
    func deleteAllEntities() {
        let request: NSFetchRequest<NSFetchRequestResult> = Beat.fetchRequest()
        let deleteRequest = NSBatchDeleteRequest(fetchRequest: request)
        
        do {
            try context.execute(deleteRequest)
            try context.save()
        } catch {
            print("Error deleting all entities: \(error)")
        }
    }
    
    /// Update paths of all entities (for file system changes)
    func updatePathsOfAllEntities() {
        let songs = getAllSongs()
        
        for song in songs {
            if let currentURL = song.songURL {
                // Check if file still exists at current path
                if !FileManager.default.fileExists(atPath: currentURL.path) {
                    // Try to find the file in the app bundle
                    let fileName = currentURL.lastPathComponent
                    if let bundleURL = Bundle.main.url(forResource: fileName, withExtension: nil) {
                        song.songURL = bundleURL
                    }
                }
            }
        }
        
        do {
            try context.save()
        } catch {
            print("Error updating entity paths: \(error)")
        }
    }
    
    // MARK: - Static Methods
    
    /// Create time range from bars
    static func timeRangeFromBars(startBar: Int, endBar: Int, tempo: Int) -> CMTimeRange {
        let beatsPerBar = 4.0
        let secondsPerBeat = 60.0 / Double(tempo)
        let secondsPerBar = beatsPerBar * secondsPerBeat
        
        let startTime = CMTime(seconds: Double(startBar - 1) * secondsPerBar, preferredTimescale: 600)
        let duration = CMTime(seconds: Double(endBar - startBar + 1) * secondsPerBar, preferredTimescale: 600)
        
        return CMTimeRange(start: startTime, duration: duration)
    }
    
    /// Get song name from AVPlayerItem
    static func getSongNameFrom(_ playerItem: AVPlayerItem) -> String? {
        guard let asset = playerItem.asset as? AVURLAsset else {
            return nil
        }
        return asset.url.lastPathComponent
    }
}
