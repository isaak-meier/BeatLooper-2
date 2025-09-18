//
//  Coordinator.swift
//  BeatLooper 2
//
//  Created by Isaak Meier on 4/4/21.
//  Migrated to Swift
//

import UIKit
import CoreMedia

class Coordinator {
    
    // MARK: - Properties
    private let window: UIWindow
    private let navigationController: UINavigationController
    private var playerController: PlayerViewController?
    private var looperController: LooperViewController?
    private var homeController: HomeViewController?
    
    // MARK: - Initialization
    init(window: UIWindow) {
        self.window = window
        self.navigationController = UINavigationController()
        self.window.rootViewController = navigationController
    }
    
    // MARK: - Public Methods
    
    /// Start the application
    func start() {
        // Initialize home view controller
        let homeViewController = HomeViewController(coordinator: self, inAddSongsMode: false)
        navigationController.pushViewController(homeViewController, animated: false)
        window.makeKeyAndVisible()
        
        checkForFirstTimeUserOrUpdate()
        homeViewController.refreshSongsAndReloadData(shouldReloadData: true)
        self.homeController = homeViewController
    }
    
    /// Handle song added successfully
    func songAdded() {
        navigationController.popToRootViewController(animated: true)
        if let homeVC = navigationController.visibleViewController as? HomeViewController {
            homeVC.refreshSongsAndReloadData(shouldReloadData: true)
        }
    }
    
    /// Handle failed to add song
    func failedToAddSong() {
        navigationController.popToRootViewController(animated: true)
        
        let alert = UIAlertController(
            title: "Error Adding Song",
            message: "For some reason, we couldn't add this song. Please try again...?",
            preferredStyle: .alert
        )
        
        let okAction = UIAlertAction(title: "Haha, Ok", style: .default) { _ in
            // Handle action
        }
        alert.addAction(okAction)
        
        navigationController.present(alert, animated: true)
    }
    
    /// Show add songs view
    func showAddSongsView() {
        let addSongsView = HomeViewController(coordinator: self, inAddSongsMode: true)
        addSongsView.modalPresentationStyle = .pageSheet
        navigationController.present(addSongsView, animated: true)
    }
    
    /// Add song to queue
    func addSongToQueue(_ song: Beat) {
        navigationController.dismiss(animated: true) {
            self.playerController?.addSongToQueue(song)
        }
    }
    
    /// Open player with songs
    func openPlayerWithSongs(_ songsForQueue: [Beat]) {
        if playerController == nil {
            let playerViewController = PlayerViewController(coordinator: self)
            
            let delegates: [PlayerDelegate] = [playerViewController, homeController!]
            let player = Player(delegates: delegates, songs: songsForQueue)
            playerViewController.setup(player: player)
            self.playerController = playerViewController
        } else if !songsForQueue.isEmpty {
            let songTapped = songsForQueue[0]
            playerController?.changeCurrentSongTo(songTapped)
        }
        openPlayerWithoutSong()
    }
    
    /// Open player without song
    func openPlayerWithoutSong() {
        navigationController.pushViewController(playerController!, animated: true)
    }
    
    /// Open looper view for song
    func openLooperViewForSong(_ song: Beat, isLooping: Bool) {
        if looperController == nil || looperController?.song.objectID != song.objectID {
            if song.objectID != nil {
                let looperController = LooperViewController(song: song, isLooping: isLooping)
                looperController.modalPresentationStyle = .pageSheet
                looperController.coordinator = self
                self.looperController = looperController
            } else {
                print("Couldn't find song by name")
            }
        }
        navigationController.present(looperController!, animated: true)
    }
    
    /// Dismiss looper view and begin looping
    func dismissLooperViewAndBeginLoopingTimeRange(_ timeRange: CMTimeRange) {
        navigationController.dismiss(animated: true) {
            self.playerController?.startLoopWithTimeRange(timeRange)
        }
    }
    
    /// Dismiss looper view and stop loop
    func dismissLooperViewAndStopLoop() {
        navigationController.dismiss(animated: true) {
            self.playerController?.stopLooping()
        }
    }
    
    /// Clear looper view
    func clearLooperView() {
        looperController = nil
    }
    
    /// Handle player view controller requests death
    func playerViewControllerRequestsDeath() {
        playerController = nil
    }
    
    // MARK: - Private Methods
    
    /// Check for first time user or update
    private func checkForFirstTimeUserOrUpdate() {
        let userDefaults = UserDefaults.standard
        let isFirstTime = !userDefaults.bool(forKey: "firstTime?")
        let shouldSetUpSampleSongs = true // Always set up sample songs for now
        let applicationDidUpdate = didSongDirectoryPathChange()
        
        if isFirstTime {
            presentOnboardingAlert()
        }
        
        if shouldSetUpSampleSongs {
            setupSampleSongs()
            userDefaults.set(true, forKey: "addSampleSongs")
        }
        
        if applicationDidUpdate {
            print("Need to update all the damn paths")
            BeatModel().updatePathsOfAllEntities()
        }
    }
    
    /// Present onboarding alert
    private func presentOnboardingAlert() {
        let alert = UIAlertController(
            title: "Hello There",
            message: "Congrats on downloading this app. I hope you're having a wonderful day. To add songs, you need to open the file (mp3 or wav only) in this app, from the share sheet. For example, from Files, select the share button and select Beatlooper 2 in the list of apps. In Google Drive, select 'Open In', and then select Beatlooper 2 in the list of apps. Basically you need to tap on Beatlooper 2 from a different app that's holding the file to import it. \n I've added some sample beats for you, try looping dunevibes or Touching!\n Ok, that's all from me. Take it easy and enjoy.",
            preferredStyle: .alert
        )
        
        let okAction = UIAlertAction(title: "Got it.", style: .default) { _ in
            UserDefaults.standard.set(true, forKey: "firstTime?")
        }
        
        let notOkAction = UIAlertAction(title: "Maybe show me that one more time next time.", style: .default) { _ in
            UserDefaults.standard.set(false, forKey: "firstTime?")
        }
        
        alert.addAction(okAction)
        alert.addAction(notOkAction)
        
        navigationController.present(alert, animated: true)
    }
    
    /// Setup sample songs
    private func setupSampleSongs() {
        let model = BeatModel()
        model.deleteAllEntities() // Clear out existing songs
        
        let mainBundle = Bundle.main
        let audioExtensions = ["mp3", "wav", "m4a", "aac"]
        
        for extension in audioExtensions {
            if let audioFiles = mainBundle.paths(forResourcesOfType: extension, inDirectory: nil) {
                for audioPath in audioFiles {
                    let url = URL(fileURLWithPath: audioPath)
                    model.saveSongFromURL(url)
                }
            }
        }
        
        // Can update tempo here if you want
        // model.saveTempo(120, forSong: song.objectID)
    }
    
    /// Check if song directory path changed
    private func didSongDirectoryPathChange() -> Bool {
        let songs = BeatModel().getAllSongs()
        if !songs.isEmpty {
            if let path = songs[0].fileUrl {
                let fileManager = FileManager.default
                if fileManager.fileExists(atPath: path) {
                    print("File Exists at Path")
                    return false
                } else {
                    print("We Updated... nothing exists at Path")
                    return true
                }
            }
        }
        return false
    }
}
