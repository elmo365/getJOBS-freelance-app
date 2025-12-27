import 'package:flutter/material.dart';
import 'dart:io';
import 'package:freelance_app/utils/app_design_system.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:video_player/video_player.dart';
import 'package:freelance_app/services/firebase/firebase_auth_service.dart';
import 'package:freelance_app/services/firebase/firebase_storage_service.dart';
import 'package:freelance_app/services/connectivity_service.dart';
import 'package:freelance_app/screens/common/video_resume_viewer_screen.dart';
import 'package:freelance_app/widgets/common/hints_wrapper.dart';
import 'package:freelance_app/widgets/common/app_app_bar.dart';

class VideoResumeScreen extends StatefulWidget {
  const VideoResumeScreen({super.key});

  @override
  State<VideoResumeScreen> createState() => _VideoResumeScreenState();
}

class _VideoResumeScreenState extends State<VideoResumeScreen>
    with ConnectivityAware {
  String? _videoPath;
  VideoPlayerController? _videoPlayerController;
  bool _isUploading = false;
  double _uploadProgress = 0.0;
  String? _existingVideoUrl;

  @override
  void initState() {
    super.initState();
    _loadExistingVideoUrl();
  }

  Future<void> _loadExistingVideoUrl() async {
    final user = FirebaseAuthService().getCurrentUser();
    if (user == null) return;

    try {
      final firestore = FirebaseFirestore.instance;
      final cvsQuery = await firestore
          .collection('cvs')
          .where('userId', isEqualTo: user.uid)
          .limit(1)
          .get();
      final cvData = cvsQuery.docs.isNotEmpty ? cvsQuery.docs.first.data() : null;
      final fromCv = (cvData?['videoResumeUrl'] ?? cvData?['video_resume_url'])?.toString();

      final userDoc = await firestore.collection('users').doc(user.uid).get();
      final userData = userDoc.data();
      final fromUser = (userData?['videoResumeUrl'] ?? userData?['video_resume_url'])?.toString();

      final url = (fromCv != null && fromCv.trim().isNotEmpty)
          ? fromCv.trim()
          : (fromUser != null && fromUser.trim().isNotEmpty)
              ? fromUser.trim()
              : null;

      if (!mounted) return;
      setState(() => _existingVideoUrl = url);
    } catch (_) {
      // Best-effort only.
    }
  }

  @override
  void dispose() {
    _videoPlayerController?.dispose();
    super.dispose();
  }

  Future<void> _pickVideo() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.video,
        allowMultiple: false,
      );

      final path = result?.files.single.path;
      if (path == null || path.isEmpty) return;

      // Enforce MP4 for best Android ExoPlayer compatibility
      final ext = path.split('.').isNotEmpty
          ? path.split('.').last.toLowerCase()
          : '';
      if (ext != 'mp4') {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'This video format may not play reliably. Please upload an MP4 video (H.264/AAC) for best compatibility.',
            ),
          ),
        );
        return;
      }

      setState(() => _videoPath = path);
      _playVideo(path);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to pick video: $e')),
      );
    }
  }

  void _playVideo(String path) {
    _videoPlayerController?.dispose();
    _videoPlayerController = VideoPlayerController.file(
      File(path),
    );
    _videoPlayerController!.initialize().then((_) {
      setState(() {});
      _videoPlayerController!.play();
    });
  }

  @override
  Widget build(BuildContext context) {
    return HintsWrapper(
      screenId: 'video_resume',
      child: Scaffold(
      appBar: AppAppBar(
        title: 'Video Resume',
        variant: AppBarVariant.primary,
        actions: [
          if (_videoPath == null)
            IconButton(
              icon: const Icon(Icons.video_file_outlined),
              tooltip: 'Choose video',
              onPressed: _pickVideo,
            ),
          if ((_existingVideoUrl ?? '').trim().isNotEmpty)
            IconButton(
              icon: const Icon(Icons.play_circle_outline),
              tooltip: 'Play uploaded',
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => VideoResumeViewerScreen(
                      videoUrl: _existingVideoUrl!,
                      title: 'My Video Resume',
                    ),
                  ),
                );
              },
            ),
          if (_videoPath != null)
            IconButton(
              icon: const Icon(Icons.upload),
              onPressed: () {
                _uploadVideo();
              },
            ),
        ],
      ),
      body: SafeArea(
        child: Column(
        children: [
          Expanded(
              child:
                  _videoPath != null ? _buildVideoPreview() : _buildEmpty(),
          ),
          _buildControls(),
        ],
        ),
      ),
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Padding(
        padding: AppDesignSystem.paddingL,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.video_file_outlined, size: 48, color: AppDesignSystem.primary(context)),
            AppDesignSystem.verticalSpace(AppDesignSystem.spaceM),
            const Text('Choose a video file to upload as your video resume.'),
            AppDesignSystem.verticalSpace(AppDesignSystem.spaceM),
            ElevatedButton.icon(
              onPressed: _pickVideo,
              icon: const Icon(Icons.folder_open),
              label: const Text('Select Video'),
            ),
            if ((_existingVideoUrl ?? '').trim().isNotEmpty) ...[
              AppDesignSystem.verticalSpace(AppDesignSystem.spaceM),
              OutlinedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => VideoResumeViewerScreen(
                        videoUrl: _existingVideoUrl!,
                        title: 'My Video Resume',
                      ),
                    ),
                  );
                },
                icon: const Icon(Icons.play_circle_outline),
                label: const Text('Play Uploaded Video'),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildVideoPreview() {
    if (_videoPlayerController == null ||
        !_videoPlayerController!.value.isInitialized) {
      return const Center(child: CircularProgressIndicator());
    }

    return AspectRatio(
      aspectRatio: _videoPlayerController!.value.aspectRatio,
      child: VideoPlayer(_videoPlayerController!),
    );
  }

  Widget _buildControls() {

    return Container(
      padding: AppDesignSystem.paddingL,
      color: AppDesignSystem.surface(context),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (_isUploading) ...[
            const SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(strokeWidth: 3),
            ),
            AppDesignSystem.horizontalSpace(AppDesignSystem.spaceM),
            Text('${(_uploadProgress * 100).toStringAsFixed(0)}%'),
            AppDesignSystem.horizontalSpace(AppDesignSystem.spaceL),
          ],
          if (_videoPath == null)
            ElevatedButton.icon(
              onPressed: _pickVideo,
              icon: const Icon(Icons.folder_open),
              label: const Text('Select Video'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppDesignSystem.primary(context),
                foregroundColor: AppDesignSystem.onPrimary(context),
                padding: AppDesignSystem.paddingSymmetric(
                  horizontal: AppDesignSystem.spaceL,
                  vertical: AppDesignSystem.spaceM,
                ),
              ),
            )
          else
            Row(
              children: [
                OutlinedButton.icon(
                  onPressed: _pickVideo,
                  icon: const Icon(Icons.swap_horiz),
                  label: const Text('Choose Different'),
                ),
                AppDesignSystem.horizontalSpace(AppDesignSystem.spaceM),
                ElevatedButton.icon(
                  onPressed: _uploadVideo,
                  icon: const Icon(Icons.upload),
                  label: const Text('Upload Video Resume'),
                ),
              ],
            ),
        ],
      ),
    );
  }

  Future<void> _uploadVideo() async {
    if (_videoPath == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please record a video first')),
      );
      return;
    }

    setState(() => _isUploading = true);

    final auth = FirebaseAuthService();
    final storage = FirebaseStorageService();

    final user = auth.getCurrentUser();
    if (user == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content:
                  Text('You need to be logged in to upload a video resume.')),
        );
        setState(() => _isUploading = false);
      }
      return;
    }

    try {
      final url = await storage.uploadVideoResume(
        filePath: _videoPath!,
        userId: user.uid,
        onProgress: (progress) {
          if (mounted) {
            setState(() => _uploadProgress = progress);
          }
        },
      );

      // Persist a record of the uploaded video resume.
      // Preferred: attach to the user's existing `cvs` document (where('userId'==uid)).
      // Fallback: store it on the user's profile doc so it isn't "lost" even if they haven't built a CV yet.
      final firestore = FirebaseFirestore.instance;
      final cvsQuery = await firestore
          .collection('cvs')
          .where('userId', isEqualTo: user.uid)
          .limit(1)
          .get();

      final now = FieldValue.serverTimestamp();
      final payload = <String, dynamic>{
        'videoResumeUrl': url,
        'video_resume_url': url, // backward/alternate key
        'videoResumeUpdatedAt': now,
      };

      if (cvsQuery.docs.isNotEmpty) {
        await cvsQuery.docs.first.reference.set(payload, SetOptions(merge: true));
      } else {
        await firestore
            .collection('users')
            .doc(user.uid)
            .set(payload, SetOptions(merge: true));
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Video resume uploaded')),
        );
      }

      if (mounted) {
        setState(() => _existingVideoUrl = url);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Upload failed: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isUploading = false);
      }
    }
  }
}
