import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../models/event_item.dart';
import '../../core/services/pdf_cache_service.dart';

class RulebookPdfViewerScreen extends StatefulWidget {
  final EventItem event;

  const RulebookPdfViewerScreen({
    super.key,
    required this.event,
  });

  @override
  State<RulebookPdfViewerScreen> createState() => _RulebookPdfViewerScreenState();
}

class _RulebookPdfViewerScreenState extends State<RulebookPdfViewerScreen> {
  late PdfViewerController _pdfViewerController;
  int _pageCount = 0;
  int _currentPage = 1;
  bool _loadFailed = false;
  bool _isLoading = true;
  double _downloadProgress = 0.0;
  Uint8List? _pdfBytes;

  @override
  void initState() {
    super.initState();
    _pdfViewerController = PdfViewerController();
    _loadPdf();
  }

  @override
  void dispose() {
    _pdfViewerController.dispose();
    super.dispose();
  }

  /// Normalizes various PDF URL formats into a direct-download URL.
  /// Handles: Cloudinary raw URLs, Google Drive share links, Google Docs links,
  /// and plain https://.../*.pdf URLs.
  String get _normalizedPdfUrl {
    final raw = widget.event.rulebookUrl.trim();
    if (raw.isEmpty) return '';

    // Google Drive /file/d/<id>  →  direct download
    if (raw.contains('drive.google.com/file/d/')) {
      final match = RegExp(r'/file/d/([a-zA-Z0-9_-]+)').firstMatch(raw);
      if (match != null && match.groupCount >= 1) {
        final fileId = match.group(1);
        return 'https://drive.google.com/uc?export=download&id=$fileId';
      }
    }

    // Google Drive /open?id=<id>
    if (raw.contains('drive.google.com/open?id=')) {
      final match = RegExp(r'[?&]id=([a-zA-Z0-9_-]+)').firstMatch(raw);
      if (match != null && match.groupCount >= 1) {
        final fileId = match.group(1);
        return 'https://drive.google.com/uc?export=download&id=$fileId';
      }
    }

    // Google Docs /document/d/<id>  →  PDF export
    if (raw.contains('docs.google.com/document/d/')) {
      final match = RegExp(r'/document/d/([a-zA-Z0-9_-]+)').firstMatch(raw);
      if (match != null && match.groupCount >= 1) {
        final docId = match.group(1);
        return 'https://docs.google.com/document/d/$docId/export?format=pdf';
      }
    }

    return raw;
  }

  /// Downloads the PDF via PdfCacheService (memory → disk → network)
  /// and loads it into the viewer as raw bytes.
  Future<void> _loadPdf() async {
    final url = _normalizedPdfUrl;
    if (url.isEmpty || !url.startsWith('http')) {
      if (mounted) {
        setState(() {
          _loadFailed = false;
          _isLoading = false;
          _pdfBytes = null; // no source at all → show "coming soon"
        });
      }
      return;
    }

    setState(() {
      _isLoading = true;
      _loadFailed = false;
      _downloadProgress = 0.0;
      _pdfBytes = null;
    });

    try {
      final bytes = await PdfCacheService.getOrFetchPdf(
        url,
        onProgress: (progress) {
          if (mounted) {
            setState(() => _downloadProgress = progress);
          }
        },
      );

      if (bytes != null && bytes.isNotEmpty) {
        if (mounted) {
          setState(() {
            _pdfBytes = bytes;
            _isLoading = false;
          });
        }
      } else {
        if (mounted) {
          setState(() {
            _loadFailed = true;
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      debugPrint('RulebookPdfViewer: PDF load error: $e');
      if (mounted) {
        setState(() {
          _loadFailed = true;
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).colorScheme.primary;
    final cardBg = Theme.of(context).colorScheme.surface;
    final bgDark = Theme.of(context).scaffoldBackgroundColor;

    final url = _normalizedPdfUrl;
    final hasSource = url.isNotEmpty && url.startsWith('http');

    return Scaffold(
      backgroundColor: bgDark,
      appBar: AppBar(
        backgroundColor: cardBg,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.event.title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
              ),
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 2),
            Text(
              'OFFICIAL RULEBOOK & SYNOPSIS',
              style: TextStyle(
                color: primaryColor,
                fontSize: 10,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.2,
              ),
            ),
          ],
        ),
        actions: [
          // Open externally if user wants to download/share
          if (hasSource && !_isLoading)
            IconButton(
              icon: const Icon(Icons.open_in_new, color: Colors.white70, size: 20),
              tooltip: 'Open in Browser',
              onPressed: () async {
                try {
                  await launchUrl(Uri.parse(widget.event.rulebookUrl.trim()),
                      mode: LaunchMode.externalApplication);
                } catch (_) {}
              },
            ),
        ],
      ),
      body: Stack(
        children: [
          if (!hasSource && !_isLoading)
            _buildEmptyState(
              title: 'RULEBOOK ANNOUNCEMENT SOON',
              subtitle:
                  'The official rulebook guidelines for ${widget.event.title} are being finalized by the organizing society and will be available here shortly.',
            )
          else if (_loadFailed)
            _buildLoadFailedState()
          else if (_pdfBytes != null)
            SfPdfViewer.memory(
              _pdfBytes!,
              controller: _pdfViewerController,
              canShowScrollHead: false,
              canShowScrollStatus: false,
              canShowPaginationDialog: false,
              enableDoubleTapZooming: true,
              pageSpacing: 6,
              onDocumentLoaded: (details) {
                if (mounted) {
                  setState(() {
                    _pageCount = details.document.pages.count;
                  });
                }
              },
              onDocumentLoadFailed: (details) {
                if (mounted) {
                  setState(() {
                    _loadFailed = true;
                  });
                }
              },
              onPageChanged: (details) {
                if (mounted && _currentPage != details.newPageNumber) {
                  setState(() {
                    _currentPage = details.newPageNumber;
                  });
                }
              },
            ),

          // Loading overlay with download progress
          if (_isLoading && hasSource)
            Container(
              color: bgDark.withValues(alpha: 0.85),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      width: 44,
                      height: 44,
                      child: CircularProgressIndicator(
                        value: _downloadProgress > 0 && _downloadProgress < 1.0
                            ? _downloadProgress
                            : null,
                        color: primaryColor,
                        strokeWidth: 3,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      _downloadProgress > 0 && _downloadProgress < 1.0
                          ? 'DOWNLOADING ${(_downloadProgress * 100).toInt()}%'
                          : 'LOADING RULEBOOK…',
                      style: GoogleFonts.rajdhani(
                        color: Colors.white60,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.0,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: cardBg,
          border: Border(
            top: BorderSide(color: Colors.white.withValues(alpha: 0.08)),
          ),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Page slider if multiple pages
              if (_pageCount > 1 && !_loadFailed) ...[
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.chevron_left, color: Colors.white70, size: 22),
                      tooltip: 'Previous Page',
                      visualDensity: VisualDensity.compact,
                      onPressed: _currentPage > 1
                          ? () => _pdfViewerController.previousPage()
                          : null,
                    ),
                    Expanded(
                      child: SliderTheme(
                        data: SliderTheme.of(context).copyWith(
                          activeTrackColor: primaryColor,
                          inactiveTrackColor: Colors.white.withValues(alpha: 0.15),
                          thumbColor: primaryColor,
                          overlayColor: primaryColor.withValues(alpha: 0.2),
                          thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 5),
                          overlayShape: const RoundSliderOverlayShape(overlayRadius: 12),
                          trackHeight: 2.5,
                        ),
                        child: Slider(
                          value: _currentPage.toDouble().clamp(1.0, _pageCount.toDouble()),
                          min: 1.0,
                          max: _pageCount.toDouble(),
                          divisions: _pageCount > 1 ? _pageCount - 1 : 1,
                          onChanged: (val) {
                            final targetPage = val.round();
                            if (targetPage != _currentPage) {
                              setState(() => _currentPage = targetPage);
                              _pdfViewerController.jumpToPage(targetPage);
                            }
                          },
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.chevron_right, color: Colors.white70, size: 22),
                      tooltip: 'Next Page',
                      visualDensity: VisualDensity.compact,
                      onPressed: _currentPage < _pageCount
                          ? () => _pdfViewerController.nextPage()
                          : null,
                    ),
                    Text(
                      '$_currentPage / $_pageCount',
                      style: GoogleFonts.rajdhani(
                        color: Colors.white70,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
              ],
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (widget.event.venue.isNotEmpty)
                          Text(
                            'Venue: ${widget.event.venue}',
                            style: const TextStyle(color: Colors.white70, fontSize: 11),
                            overflow: TextOverflow.ellipsis,
                          ),
                        if (widget.event.time.isNotEmpty)
                          Text(
                            'Time: ${widget.event.time}',
                            style: TextStyle(
                                color: primaryColor,
                                fontSize: 11,
                                fontWeight: FontWeight.w600),
                            overflow: TextOverflow.ellipsis,
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState({
    required String title,
    required String subtitle,
  }) {
    final primaryColor = Theme.of(context).colorScheme.primary;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.04),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white12),
              ),
              child: Icon(Icons.menu_book_outlined,
                  size: 42, color: primaryColor.withValues(alpha: 0.6)),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: GoogleFonts.orbitron(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                letterSpacing: 1.0,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              style: GoogleFonts.rajdhani(
                fontSize: 13,
                color: Colors.white60,
                height: 1.4,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadFailedState() {
    final primaryColor = Theme.of(context).colorScheme.primary;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.description_outlined,
                size: 42, color: primaryColor.withValues(alpha: 0.7)),
            const SizedBox(height: 14),
            Text(
              'UNABLE TO LOAD RULEBOOK',
              style: GoogleFonts.orbitron(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                letterSpacing: 1.0,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'The document could not be loaded. This can happen with Google Drive links that require sign-in or have restricted sharing. Try opening externally.',
              style: GoogleFonts.rajdhani(
                fontSize: 13,
                color: Colors.white60,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 18),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                OutlinedButton.icon(
                  onPressed: _loadPdf,
                  icon: const Icon(Icons.refresh, size: 16),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: primaryColor.withValues(alpha: 0.5)),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8)),
                  ),
                  label: Text(
                    'RETRY',
                    style: GoogleFonts.rajdhani(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                OutlinedButton.icon(
                  onPressed: () async {
                    final rawUrl = widget.event.rulebookUrl.trim();
                    if (rawUrl.isNotEmpty) {
                      try {
                        await launchUrl(Uri.parse(rawUrl),
                            mode: LaunchMode.externalApplication);
                      } catch (_) {}
                    }
                  },
                  icon: const Icon(Icons.open_in_new, size: 16),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: Colors.white24),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8)),
                  ),
                  label: Text(
                    'OPEN EXTERNALLY',
                    style: GoogleFonts.rajdhani(
                      color: Colors.white70,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
