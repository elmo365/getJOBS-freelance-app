import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:freelance_app/widgets/common/hints_wrapper.dart';
import 'package:freelance_app/widgets/common/app_app_bar.dart';

class CvDocumentViewerScreen extends StatelessWidget {
  final String cvUrl;
  final String title;

  const CvDocumentViewerScreen({
    super.key,
    required this.cvUrl,
    this.title = 'CV',
  });

  Future<void> _download() async {
    final uri = Uri.tryParse(cvUrl);
    if (uri == null) return;
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    return HintsWrapper(
      screenId: 'cv_document_viewer',
      child: Scaffold(
      appBar: AppAppBar(
        title: title,
        variant: AppBarVariant.primary,
        actions: [
          IconButton(
            tooltip: 'Download',
            icon: const Icon(Icons.download_outlined),
            onPressed: _download,
          ),
        ],
      ),
      body: SfPdfViewer.network(
        cvUrl,
        canShowPaginationDialog: true,
        onDocumentLoadFailed: (details) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Could not open in-app PDF: ${details.error}')),
          );
        },
      ),
      ),
    );
  }
}
