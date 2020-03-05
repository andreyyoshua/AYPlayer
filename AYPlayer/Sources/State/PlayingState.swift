//
//  PlayingState.swift
//  AYPlayer
//
//  Created by Andrey Yoshua on 03/03/20.
//

import AVFoundation

final class PlayingState: AYPlayerStateProtocol {
    // MARK: - Inputs

    unowned let manager: AYPlayerManager
    private var itemPlaybackObservingService: AYPlaybackObservingServiceProtocol
    private let routeAudioService: AYPlayerRouteAudioService
    private var interruptionAudioService: AYInterruptionAudioServiceProtocol
    private var playerStatusService: AYPlayerTimeControlStatusProtocol?
    private var playerBufferService: AYPlayerBufferObservingService?
    private let audioSession: AVAudioSession
    private var periodicPlayingTime: CMTime {
        manager.config.periodicPlayingTime
    }

    // MARK: - Variables

    public let type: AYPlayerManager.State = .playing
    private var optTimerObserver: Any?

    // MARK: - Lifecycle

    init(manager: AYPlayerManager,
         itemPlaybackObservingService: AYPlaybackObservingServiceProtocol,
         routeAudioService: AYPlayerRouteAudioService = AYPlayerRouteAudioService(),
         interruptionAudioService: AYInterruptionAudioServiceProtocol = AYPlayerInterruptionAudioService(),
         audioSession: AVAudioSession = AVAudioSession.sharedInstance()) {
        AYPlayerLogger.instance.log(message: "Init", domain: .lifecycleState)
        self.manager = manager
        self.itemPlaybackObservingService = itemPlaybackObservingService
        self.routeAudioService = routeAudioService
        self.interruptionAudioService = interruptionAudioService
        self.audioSession = audioSession
        setTimerObserver()

        self.routeAudioService.onRouteChanged = { [weak self] in self?.routeAudioChanged(reason: $0) }
        setupPlaybackObservingCallback()
        setupInterruptionCallback()
        setupPlayerStatus()
    }

    func managerUpdated() {}

    deinit {
        AYPlayerLogger.instance.log(message: "Deinit", domain: .lifecycleState)
    }

    func load(media: AYPlayerMediaProtocol, autostart: Bool, position: Double?) {
        let state = LoadingState(manager: manager, media: media, autostart: autostart, position: position)
        changeState(state: state)
    }

    func pause() {
        changeState(state: PausedState(manager: manager))
    }

    func play() {
        let debug = "Already playing"
        AYPlayerLogger.instance.log(message: debug, domain: .unavailableCommand)
        manager.delegate?.playerManager(unavailableActionReason: .alreadyPlaying)
    }

    func seek(position: Double) {
        let state = BufferingState(manager: manager)
        changeState(state: state)
        state.seekCommand(position: position)
    }

    func stop() {
        changeState(state: StoppedState(manager: manager))
    }

    // MARK: - Playback Observing Service

    private func setupPlaybackObservingCallback() {
        itemPlaybackObservingService.onPlaybackStalled = { [weak self] in
            self?.redirectToBufferingState()
        }
        itemPlaybackObservingService.onFailedToPlayToEndTime = { [weak self] in
            self?.redirectToBufferingState()
        }
        itemPlaybackObservingService.onPlayToEndTime = { [weak self] in
            guard let self = self else { return }
            self.manager.delegate?.playerManager(didItemPlayToEndTime: self.manager.currentTime)
            if self.manager.loopMode {
                self.seek(position: 0)
            } else {
                self.stop()
            }
        }
    }

    // MARK: - Player Status

    private func setupPlayerStatus() {
        playerStatusService = AYPlayerTimeControlStatus(player: manager.player)
        playerStatusService?.onPause = {
            print("🚥", "On Pause")
        }

        playerStatusService?.onPlay = {
            print("🚥", "On Play")
        }

        playerStatusService?.onLoading = {
            print("🚥", "On Loading")
        }

        guard let currentItem = manager.currentItem else {
            return
        }
        playerBufferService = AYPlayerBufferObservingService(item: currentItem, callback: { [manager] duration in
            manager.delegate?.playerManager(didForwardBufferToDuration: duration)
        })
    }

    private func redirectToBufferingState() {
        let state = BufferingState(manager: manager)
        changeState(state: state)
        state.play()
    }

    // MARK: - Interruption Service

    private func setupInterruptionCallback() {
        interruptionAudioService.onInterruptionBegan = { [weak self] in
            self?.pauseByInterruption()
        }
    }

    /*
     Do not set any call back on interruption ended when user play from another app
     */
    private func pauseByInterruption() {
        // TODO:
        let state = PausedState(manager: manager)
        if !audioSession.secondaryAudioShouldBeSilencedHint {
            state.onInterruptionEnded = { [weak state] in state?.play() }
        }
        changeState(state: state)
    }

    // MARK: - Private actions

    private func changeState(state: AYPlayerStateProtocol) {
        removeTimeObserver()
        manager.changeState(state: state)
    }

    private func setTimerObserver() {
        optTimerObserver = manager.player.addPeriodicTimeObserver(
            forInterval: periodicPlayingTime,
            queue: nil
        ) { [weak manager] _ in

            guard let manager = manager else { return }
            manager.delegate?.playerManager(didCurrentTimeChange: manager.currentTime, withTotalDuration: manager.itemDuration)
//            manager?.nowPlaying.overrideInfoCenter(for: MPNowPlayingInfoPropertyElapsedPlaybackTime,
//                                                   value: time.seconds)
        }
    }

    private func removeTimeObserver() {
        if let timerObserver = optTimerObserver {
            manager.player.removeTimeObserver(timerObserver)
        }
    }

    private func routeAudioChanged(reason: AVAudioSession.RouteChangeReason) {
        switch reason {
        case .oldDeviceUnavailable, .unknown:
            // TODO: Add Pause State and change manager state to Pause state
            changeState(state: PausedState(manager: manager))
        default:
            break
        }
    }
}
