import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:video_player/video_player.dart';
import 'package:freelance_app/utils/app_design_system.dart';
import 'package:freelance_app/widgets/common/hints_wrapper.dart';
import 'package:freelance_app/widgets/common/app_app_bar.dart';

class VideoResumeViewerScreen extends StatefulWidget {
  final String videoUrl;
  final String title;

  const VideoResumeViewerScreen({
    super.key,
    required this.videoUrl,
    this.title = 'Video Resume',
  });

  @override
  State<VideoResumeViewerScreen> createState() => _VideoResumeViewerScreenState();
}

class _VideoResumeViewerScreenState extends State<VideoResumeViewerScreen> {
  VideoPlayerController? _controller;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    try {
      final controller = VideoPlayerController.networkUrl(Uri.parse(widget.videoUrl));
      await controller.initialize();
      controller.setLooping(true);
      setState(() {
        _controller = controller;
        _isLoading = false;
      });
      await controller.play();
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  Future<void> _download() async {
    final uri = Uri.tryParse(widget.videoUrl);
    if (uri == null) return;
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    final controller = _controller;

    return HintsWrapper(
      screenId: 'video_resume_viewer',
      child: Scaffold(
      appBar: AppAppBar(
        title: widget.title,
        variant: AppBarVariant.primary,
        actions: [
          IconButton(
            tooltip: 'Download',
            icon: const Icon(Icons.download_outlined),
            onPressed: _download,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Padding(
                    padding: AppDesignSystem.paddingM,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.error_outline, size: 48),
                        AppDesignSystem.verticalSpace(AppDesignSystem.spaceM),
                        const Text('Could not play this video in-app.'),
                        AppDesignSystem.verticalSpace(AppDesignSystem.spaceS),
                        Text(
                          _error!,
                          textAlign: TextAlign.center,
                        ),
                        AppDesignSystem.verticalSpace(AppDesignSystem.spaceM),
                        ElevatedButton.icon(
                          onPressed: _download,
                          icon: const Icon(Icons.open_in_new),
                          label: const Text('Open/Download Externally'),
                        ),
                      ],
                    ),
                  ),
                )
              : controller == null
                  ? const Center(child: Text('No video'))
                  : Column(
                      children: [
                        AspectRatio(
                          aspectRatio: controller.value.aspectRatio,
                          child: VideoPlayer(controller),
                        ),
                        AppDesignSystem.verticalSpace(AppDesignSystem.spaceM),
                        Wrap(
                          spacing: 12,
                          children: [
                            IconButton(
                              tooltip: controller.value.isPlaying ? 'Pause' : 'Play',
                              icon: Icon(
                                controller.value.isPlaying
                                    ? Icons.pause_circle_outline
                                    : Icons.play_circle_outline,
                              ),
                              onPressed: () {
                                setState(() {
                                  controller.value.isPlaying
                                      ? controller.pause()
                                      : controller.play();
                                });
                              },
                            ),
                            IconButton(
                              tooltip: 'Restart',
                              icon: const Icon(Icons.replay),
                              onPressed: () async {
                                await controller.seekTo(Duration.zero);
                                await controller.play();
                                setState(() {});
                              },
                            ),
                          ],
                        ),
                      ],
                    ),
      ),
    );
  }
}
