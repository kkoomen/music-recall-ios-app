import AVFoundation
import Foundation

/// AVFoundation adapter that plays one local asset at a time.
///
/// Main-actor isolated because `AVPlayer`, `AVPlayerItem`, and the audio
/// session are not thread-safe. Prepares an asset before a round begins,
/// always plays from the beginning, and stops on demand.
@MainActor
final class AVPlayerAudioPlayer: AudioPlaying {
    var onPlaybackInterruption: (() -> Void)?

    private let player = AVPlayer()
    private var interruptionTask: Task<Void, Never>?
    private var routeChangeTask: Task<Void, Never>?

    init() {
        configureAudioSession()
        startObservingSystemEvents()
    }

    deinit {
        interruptionTask?.cancel()
        routeChangeTask?.cancel()
    }

    var isPlaying: Bool {
        player.timeControlStatus == .playing
    }

    func prepare(assetURL: URL) async throws {
        let asset = AVURLAsset(url: assetURL)
        let isPlayable = (try? await asset.load(.isPlayable)) ?? false
        guard isPlayable else {
            throw PlaybackError.assetUnavailable
        }
        player.replaceCurrentItem(with: AVPlayerItem(asset: asset))
        await player.seek(to: .zero, toleranceBefore: .zero, toleranceAfter: .zero)
    }

    func playFromStart() {
        Task { @MainActor [weak self] in
            guard let self else { return }
            await self.player.seek(to: .zero, toleranceBefore: .zero, toleranceAfter: .zero)
            self.player.play()
        }
    }

    func loadDuration(of assetURL: URL) async throws -> TimeInterval {
        let asset = AVURLAsset(url: assetURL)
        let duration = try await asset.load(.duration)
        guard duration.isNumeric, duration.seconds.isFinite, duration.seconds > 0 else {
            throw PlaybackError.assetUnavailable
        }
        return duration.seconds
    }

    func playSample(assetURL: URL, at offset: TimeInterval) async throws {
        let asset = AVURLAsset(url: assetURL)
        let isPlayable = (try? await asset.load(.isPlayable)) ?? false
        guard isPlayable else {
            throw PlaybackError.assetUnavailable
        }
        player.replaceCurrentItem(with: AVPlayerItem(asset: asset))
        let time = CMTime(seconds: max(0, offset), preferredTimescale: 600)
        await player.seek(to: time, toleranceBefore: .zero, toleranceAfter: .zero)
        player.play()
    }

    func stop() {
        player.pause()
        player.replaceCurrentItem(with: nil)
    }

    private func configureAudioSession() {
        let session = AVAudioSession.sharedInstance()
        try? session.setCategory(.playback, mode: .default)
        try? session.setActive(true)
    }

    private func startObservingSystemEvents() {
        interruptionTask = Task { [weak self] in
            for await notification in NotificationCenter.default
                .notifications(named: AVAudioSession.interruptionNotification)
            {
                self?.handleInterruption(notification)
            }
        }
        routeChangeTask = Task { [weak self] in
            for await notification in NotificationCenter.default
                .notifications(named: AVAudioSession.routeChangeNotification)
            {
                self?.handleRouteChange(notification)
            }
        }
    }

    private func handleInterruption(_ notification: Notification) {
        guard
            let rawType = notification.userInfo?[AVAudioSessionInterruptionTypeKey] as? UInt,
            AVAudioSession.InterruptionType(rawValue: rawType) == .began
        else { return }
        stop()
        onPlaybackInterruption?()
    }

    private func handleRouteChange(_ notification: Notification) {
        guard
            let rawReason = notification.userInfo?[AVAudioSessionRouteChangeReasonKey] as? UInt,
            AVAudioSession.RouteChangeReason(rawValue: rawReason) == .oldDeviceUnavailable
        else { return }
        stop()
        onPlaybackInterruption?()
    }
}
