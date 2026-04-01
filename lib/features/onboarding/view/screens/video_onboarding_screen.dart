import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:sponti/config/routes/route_name.dart';
import 'package:sponti/features/onboarding/viewmodel/onboarding_viewmodel.dart';
import 'package:video_player/video_player.dart';

class VideoOnboardingScreen extends ConsumerStatefulWidget {
  const VideoOnboardingScreen({super.key});

  @override
  ConsumerState<VideoOnboardingScreen> createState() =>
      _VideoOnboardingScreenState();
}

class _VideoOnboardingScreenState extends ConsumerState<VideoOnboardingScreen> {
  late VideoPlayerController _videoController;
  bool _isVideoFinished = false;

  @override
  void initState() {
    super.initState();
    _initializeVideo();
  }

  Future<void> _initializeVideo() async {
    _videoController =
        VideoPlayerController.asset('assets/videos/onboarding.mp4');
    
    try {
      await _videoController.initialize();
      if (!mounted) return;
      setState(() {});
      await _videoController.play();
    } catch (error) {
      debugPrint('Video initialization failed: $error');
      // Navigate to login on video error so user isn't stuck
      if (mounted) {
        _goToLogin();
      }
    }

    _videoController.addListener(_onVideoStatusChanged);
  }

  void _onVideoStatusChanged() {
    if (!mounted) return;

    final isPlaying = _videoController.value.isPlaying;
    final position = _videoController.value.position;
    final duration = _videoController.value.duration;

    if (duration != Duration.zero && position >= duration && !isPlaying) {
      setState(() {
        _isVideoFinished = true;
      });
    }
  }

  Future<void> _goToLogin() async {
    await ref.read(onboardingViewModelProvider.notifier).markCompleted();

    if (mounted) {
      context.go(RouteName.signin);
    }
  }

  @override
  void dispose() {
    _videoController.removeListener(_onVideoStatusChanged);
    _videoController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: _videoController.value.isInitialized
          ? Stack(
              fit: StackFit.expand,
              children: [
                SizedBox.expand(child: VideoPlayer(_videoController)),
                if (_isVideoFinished)
                  Positioned(
                    bottom: 60,
                    left: 0,
                    right: 0,
                    child: Center(
                      child: ElevatedButton(
                        onPressed: _goToLogin,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: Colors.black,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 40,
                            vertical: 14,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Text(
                              'Start Exploring',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
              ],
            )
          : const Center(child: CircularProgressIndicator()),
    );
  }
}
