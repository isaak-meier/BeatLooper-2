//
//  SceneDelegate.swift
//  BeatLooper 2
//
//  Created by Isaak Meier on 4/2/21.
//  Migrated to Swift
//

import UIKit

class SceneDelegate: UIResponder, UIWindowSceneDelegate {
    
    // MARK: - Properties
    var window: UIWindow?
    private var coordinator: Coordinator?
    
    // MARK: - Scene Lifecycle
    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        // Use this method to optionally configure and attach the UIWindow `window` to the provided UIWindowScene `scene`.
        // If using a storyboard, the `window` property will automatically be initialized and attached to the scene.
        // This delegate does not imply the connecting scene or session are new (see `application:configurationForConnectingSceneSession` instead).
        
        guard let windowScene = (scene as? UIWindowScene) else { return }
        
        // Create UIWindow using bounds of screen, give it UIScene as UIWindowScene for "windowScene" property
        let frame = UIScreen.main.bounds
        let window = UIWindow(frame: frame)
        window.windowScene = windowScene
        
        // Init Coordinator using instance of window
        coordinator = Coordinator(window: window)
        
        // Kickoff application
        coordinator?.start()
        
        self.window = window
    }
    
    func sceneDidDisconnect(_ scene: UIScene) {
        // Called as the scene is being released by the system.
        // This occurs shortly after the scene enters the background, or when its session is discarded.
        // Release any resources associated with this scene that can be re-created the next time the scene connects.
        // The scene may re-connect later, as its session was not necessarily discarded (see `application:didDiscardSceneSessions` instead).
    }
    
    func sceneDidBecomeActive(_ scene: UIScene) {
        // Called when the scene has moved from an inactive state to an active state.
        // Use this method to restart any tasks that were paused (or not yet started) when the scene was inactive.
    }
    
    func sceneWillResignActive(_ scene: UIScene) {
        // Called when the scene will move from an active state to an inactive state.
        // This may occur due to temporary interruptions (ex. an incoming phone call).
    }
    
    func sceneWillEnterForeground(_ scene: UIScene) {
        // Called as the scene transitions from the background to the foreground.
        // Use this method to undo the changes made on entering the background.
    }
    
    func sceneDidEnterBackground(_ scene: UIScene) {
        // Called as the scene transitions from the foreground to the background.
        // Use this method to save data, release shared resources, and store enough scene-specific state information
        // to restore the scene back to its current state.
    }
    
    // MARK: - URL Handling
    /*
     Called when a user opens a file with this app. May be .mp3 or .wav format
     
     Save into Core Data and refresh app.
     
     TODO: this doesn't work when app is first opening on device only
     */
    func scene(_ scene: UIScene, openURLContexts URLContexts: Set<UIOpenURLContext>) {
        guard let openedFileURL = URLContexts.first?.url else { return }
        
        DispatchQueue.global(qos: .utility).async { [weak self] in
            let model = BeatModel()
            
            DispatchQueue.main.async {
                if model.saveSongFromURL(openedFileURL) {
                    self?.coordinator?.songAdded()
                } else {
                    self?.coordinator?.failedToAddSong()
                }
            }
        }
    }
}
