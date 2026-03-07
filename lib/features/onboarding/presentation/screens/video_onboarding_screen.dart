import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:video_player/video_player.dart';
import 'package:sponti/config/routes/app_router.dart';
import 'package:sponti/features/onboarding/data/datasources/onboarding_local_datasource.dart';

class VideoOnboardingScreen extends StatefulWidget {
  const VideoOnboardingScreen({super.key});

  @override
  State<VideoOnboardingScreen> createState() => _VideoOnboardingScreenState();
}

class _VideoOnboardingScreenState extends State<VideoOnboardingScreen> {
  late VideoPlayerController _videoController;
  bool _isVideoFinished = false;

  @override
  void initState() {
    super.initState();
    print('🎬 VideoOnboardingScreen initState called');
    
    // TEMPORARY: Reset onboarding for testing
    // Remove this after testing is complete
    _resetOnboardingForTesting();
    
    _initializeVideo();
  }

  Future<void> _resetOnboardingForTesting() async {
    final datasource = OnboardingLocalDatasourceImpl();
    await datasource.resetOnboarding();
    print('🔄 Onboarding reset for testing');
  }

  Future<void> _initializeVideo() async {
    print('🎬 Initializing video...');
    _videoController = VideoPlayerController.asset('assets/videos/onboarding.mp4')
      ..initialize().then((_) {
        print('Video initialized successfully');
        setState(() {});
        _videoController.play();
        print('Video started playing');
      }).catchError((error) {
        print('Video initialization error: $error');
      });

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

  void _goToLogin() async {
    final datasource = OnboardingLocalDatasourceImpl();
    await datasource.markOnboardingAsCompleted();
    
    if (mounted) {
      context.go(Routes.signIn);
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
                SizedBox.expand(
                  child: VideoPlayer(_videoController),
                ),
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
                            const SizedBox(width: 8),
                            const Icon(Icons.arrow_forward, size: 18),
                          ],
                        ),
                      ),
                    ),
                  ),
              ],
            )
          : const Center(
              child: CircularProgressIndicator(),
            ),
    );
  }
}
