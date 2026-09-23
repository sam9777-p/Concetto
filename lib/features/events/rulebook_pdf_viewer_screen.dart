import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
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
  bool _isLoading = true;
  Uint8List? _pdfMemoryBytes;

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

  Future<void> _loadPdf() async {
    // All official rulebooks from excel are bundled locally in assets/rulebooks/
    setState(() {
      _isLoading = false;
    });
  }

  String get _fallbackAssetPath {
    final url = widget.event.rulebookUrl.trim();
    if (url.isNotEmpty && !url.startsWith('http') && url.endsWith('.pdf')) {
      return url;
    }
    var raw = widget.event.id.toLowerCase().replaceAll('-', '_');
    if (raw == 'aptiquest') raw = 'questree__26';
    if (raw == 'crack_the_crude') raw = 'reservoir_making___iadc';
    if (raw == 'vibehack') raw = 'vibehack__26';
    if (raw == 'sparkathon_2_0') raw = 'sparkathon';
    return 'assets/rulebooks/$raw.pdf';
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).colorScheme.primary;
    const bgDark = Color(0xFF070709);
    const cardBg = Color(0xFF13131A);

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
      ),
      body: Stack(
        children: [
          if (!_isLoading) ...[
            if (_pdfMemoryBytes != null)
              SfPdfViewer.memory(
                _pdfMemoryBytes!,
                controller: _pdfViewerController,
                canShowScrollHead: false,
                canShowScrollStatus: false,
                canShowPaginationDialog: false,
                enableDoubleTapZooming: true,
                pageSpacing: 6,
                onDocumentLoaded: (details) {
                  setState(() {
                    _pageCount = details.document.pages.count;
                  });
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
              SfPdfViewer.asset(
                _fallbackAssetPath,
                controller: _pdfViewerController,
                canShowScrollHead: false,
                canShowScrollStatus: false,
                canShowPaginationDialog: false,
                enableDoubleTapZooming: true,
                pageSpacing: 6,
                onDocumentLoaded: (details) {
                  setState(() {
                    _pageCount = details.document.pages.count;
                  });
                },
                onDocumentLoadFailed: (details) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('No rulebook for this event found'),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                    Navigator.pop(context);
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
          ],
          if (_isLoading)
            Container(
              color: bgDark,
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(color: primaryColor),
                    const SizedBox(height: 16),
                    const Text(
                      'Loading Rulebook in memory...',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 13,
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
              if (_pageCount > 1) ...[
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
}
