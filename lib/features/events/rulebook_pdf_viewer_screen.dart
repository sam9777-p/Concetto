import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/services/pdf_cache_service.dart';
import '../../core/theme/app_theme.dart';
import '../../models/event_item.dart';

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

  Uint8List? _cachedPdfBytes;
  bool _isFetchingPdf = false;
  double _downloadProgress = 0.0;

  @override
  void initState() {
    super.initState();
    _pdfViewerController = PdfViewerController();

    final url = _normalizedPdfUrl;
    if (url.isNotEmpty && url.startsWith('http')) {
      final memBytes = PdfCacheService.getFromMemory(url);
      if (memBytes != null) {
        _cachedPdfBytes = memBytes;
      } else {
        _fetchAndCachePdf(url);
      }
    }
  }

  Future<void> _fetchAndCachePdf(String url) async {
    setState(() {
      _isFetchingPdf = true;
      _downloadProgress = 0.0;
    });

    try {
      final bytes = await PdfCacheService.getOrFetchPdf(
        url,
        onProgress: (p) {
          if (mounted) {
            setState(() => _downloadProgress = p);
          }
        },
      );

      if (mounted) {
        setState(() {
          _isFetchingPdf = false;
          _cachedPdfBytes = bytes;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isFetchingPdf = false);
      }
    }
  }

  @override
  void dispose() {
    _pdfViewerController.dispose();
    super.dispose();
  }

  String get _normalizedPdfUrl {
    final raw = widget.event.rulebookUrl.trim();
    if (raw.isEmpty) return '';

    // If it's a Google Drive file link, convert to direct export link
    if (raw.contains('drive.google.com/file/d/')) {
      final match = RegExp(r'/file/d/([a-zA-Z0-9_-]+)').firstMatch(raw);
      if (match != null && match.groupCount >= 1) {
        final fileId = match.group(1);
        return 'https://drive.google.com/uc?export=download&id=$fileId';
      }
    }
    return raw;
  }

  Future<void> _openExternalLink(String url) async {
    final uri = Uri.tryParse(url.trim());
    if (uri != null && await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not open link: $url')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).colorScheme.primary;
    const bgDark = Color(0xFF070709);
    const cardBg = Color(0xFF13131A);

    final rawUrl = widget.event.rulebookUrl.trim();
    final effectiveUrl = _normalizedPdfUrl;
    final hasUrl = rawUrl.isNotEmpty && rawUrl.startsWith('http');

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
          if (hasUrl)
            IconButton(
              icon: const Icon(Icons.open_in_new, color: AppTheme.cyberAmber),
              tooltip: 'Open in Browser / External App',
              onPressed: () => _openExternalLink(rawUrl),
            ),
          if (_pageCount > 0)
            Container(
              margin: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
              ),
              child: Center(
                child: Text(
                  '$_currentPage / $_pageCount',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          if (hasUrl && !_loadFailed) ...[
            IconButton(
              icon: const Icon(Icons.zoom_in, color: Colors.white70),
              tooltip: 'Zoom In',
              onPressed: () {
                _pdfViewerController.zoomLevel = (_pdfViewerController.zoomLevel + 0.25).clamp(1.0, 3.0);
              },
            ),
            IconButton(
              icon: const Icon(Icons.zoom_out, color: Colors.white70),
              tooltip: 'Zoom Out',
              onPressed: () {
                _pdfViewerController.zoomLevel = (_pdfViewerController.zoomLevel - 0.25).clamp(1.0, 3.0);
              },
            ),
          ],
        ],
      ),
      body: Stack(
        children: [
          if (!hasUrl)
            _buildEmptyState(
              title: 'NO RULEBOOK ATTACHED YET',
              subtitle: 'The organizing club has not uploaded an official rulebook PDF for this event yet.',
              icon: Icons.menu_book_outlined,
            )
          else if (_loadFailed)
            _buildLoadFailedState(rawUrl)
          else if (_cachedPdfBytes != null)
            SfPdfViewer.memory(
              _cachedPdfBytes!,
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
                    _loadFailed = false;
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
            )
          else
            SfPdfViewer.network(
              effectiveUrl,
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
                    _loadFailed = false;
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

          // Downloading & Caching Progress Overlay
          if (_isFetchingPdf && _cachedPdfBytes == null)
            Container(
              color: Colors.black.withValues(alpha: 0.85),
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                  margin: const EdgeInsets.symmetric(horizontal: 32),
                  decoration: BoxDecoration(
                    color: const Color(0xFF140604),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: primaryColor.withValues(alpha: 0.4), width: 1.2),
                    boxShadow: [
                      BoxShadow(
                        color: primaryColor.withValues(alpha: 0.15),
                        blurRadius: 16,
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircularProgressIndicator(
                        value: _downloadProgress > 0 ? _downloadProgress : null,
                        color: primaryColor,
                        strokeWidth: 3,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        _downloadProgress > 0
                            ? 'Downloading Rulebook: ${(_downloadProgress * 100).toInt()}%'
                            : 'Fetching & Caching Rulebook...',
                        style: GoogleFonts.rajdhani(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Stored locally in cache for instant future access',
                        style: GoogleFonts.rajdhani(
                          color: Colors.white54,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: cardBg,
          border: Border(
            top: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
          ),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Smooth Hardware-Accelerated Page Scrubber / Slider
              if (_pageCount > 1 && !_loadFailed) ...[
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.chevron_left, color: Colors.white70, size: 22),
                      tooltip: 'Previous Page',
                      visualDensity: VisualDensity.compact,
                      onPressed: _currentPage > 1
                          ? () {
                              _pdfViewerController.previousPage();
                            }
                          : null,
                    ),
                    Expanded(
                      child: SliderTheme(
                        data: SliderTheme.of(context).copyWith(
                          activeTrackColor: primaryColor,
                          inactiveTrackColor: Colors.white.withValues(alpha: 0.15),
                          thumbColor: primaryColor,
                          overlayColor: primaryColor.withValues(alpha: 0.2),
                          thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                          overlayShape: const RoundSliderOverlayShape(overlayRadius: 14),
                          trackHeight: 3,
                        ),
                        child: Slider(
                          value: _currentPage.toDouble().clamp(1.0, _pageCount.toDouble()),
                          min: 1.0,
                          max: _pageCount.toDouble(),
                          divisions: _pageCount > 1 ? _pageCount - 1 : 1,
                          onChanged: (val) {
                            final targetPage = val.round();
                            if (targetPage != _currentPage) {
                              setState(() {
                                _currentPage = targetPage;
                              });
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
                          ? () {
                              _pdfViewerController.nextPage();
                            }
                          : null,
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: primaryColor.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: primaryColor.withValues(alpha: 0.3)),
                      ),
                      child: Text(
                        'P. $_currentPage/$_pageCount',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
              ],
              Row(
                children: [
                  Expanded(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Venue: ${widget.event.venue}',
                          style: const TextStyle(color: Colors.white70, fontSize: 11),
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          'Time: ${widget.event.time}',
                          style: TextStyle(color: primaryColor, fontSize: 11, fontWeight: FontWeight.w600),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  ElevatedButton.icon(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.check_circle_outline, size: 16, color: Colors.white),
                    label: const Text('GOT IT', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryColor,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
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
    required IconData icon,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.05),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white12),
              ),
              child: Icon(icon, size: 48, color: Colors.white38),
            ),
            const SizedBox(height: 18),
            Text(
              title,
              style: GoogleFonts.orbitron(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                letterSpacing: 1.1,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              style: GoogleFonts.rajdhani(
                fontSize: 13,
                color: AppTheme.metallicSilver,
                height: 1.4,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 22),
            OutlinedButton.icon(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.arrow_back, size: 16, color: Colors.white70),
              label: Text(
                'RETURN TO EVENT DETAILS',
                style: GoogleFonts.rajdhani(fontWeight: FontWeight.bold, color: Colors.white),
              ),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Colors.white24),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadFailedState(String originalUrl) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Container(
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            color: const Color(0xFF140806),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppTheme.neonOrange.withValues(alpha: 0.5)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.picture_as_pdf_outlined, color: AppTheme.neonOrange, size: 48),
              const SizedBox(height: 14),
              Text(
                'DOCUMENT LINK READY',
                style: GoogleFonts.orbitron(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  letterSpacing: 1.1,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'This rulebook is hosted externally (e.g. Google Drive/Docs). Click below to view the official document in your browser or drive reader.',
                style: GoogleFonts.rajdhani(
                  fontSize: 13,
                  color: AppTheme.metallicSilver,
                  height: 1.4,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => _openExternalLink(originalUrl),
                  icon: const Icon(Icons.open_in_new, color: Colors.black, size: 18),
                  label: Text(
                    'OPEN OFFICIAL RULEBOOK',
                    style: GoogleFonts.rajdhani(
                      fontWeight: FontWeight.w800,
                      fontSize: 14,
                      color: Colors.black,
                      letterSpacing: 1,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.neonOrange,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
