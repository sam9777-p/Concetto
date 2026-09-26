import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
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
  bool _loadFailed = false;
  bool _isLoading = true;

  // Bundled asset rulebooks map
  static const Map<String, String> _bundledRulebooks = {
    'aethera': 'assets/rulebooks/aethera.pdf',
    'code_wars': 'assets/rulebooks/code_wars.pdf',
    'edge_ai_challenge': 'assets/rulebooks/edge_ai_challenge.pdf',
    'equity_auction': 'assets/rulebooks/equity_auction.pdf',
    'fault_hunt': 'assets/rulebooks/fault_hunt.pdf',
    'logic_odyssey': 'assets/rulebooks/logic_odyssey.pdf',
    'mathalon': 'assets/rulebooks/mathalon.pdf',
    'questree__26': 'assets/rulebooks/questree__26.pdf',
    'pmx180dc_caseblitz': 'assets/rulebooks/questree__26.pdf',
    'reservoir_making___iadc': 'assets/rulebooks/reservoir_making___iadc.pdf',
    'sparkathon': 'assets/rulebooks/sparkathon.pdf',
    'vibehack__26': 'assets/rulebooks/vibehack__26.pdf',
  };

  @override
  void initState() {
    super.initState();
    _pdfViewerController = PdfViewerController();
  }

  @override
  void dispose() {
    _pdfViewerController.dispose();
    super.dispose();
  }

  String? get _bundledAssetPath {
    final id = widget.event.id.toLowerCase().trim();
    if (_bundledRulebooks.containsKey(id)) {
      return _bundledRulebooks[id];
    }
    // Check partial matches
    for (final entry in _bundledRulebooks.entries) {
      if (id.contains(entry.key) || entry.key.contains(id)) {
        return entry.value;
      }
    }
    return null;
  }

  String get _normalizedPdfUrl {
    final raw = widget.event.rulebookUrl.trim();
    if (raw.isEmpty) return '';

    // Google Drive direct export
    if (raw.contains('drive.google.com/file/d/')) {
      final match = RegExp(r'/file/d/([a-zA-Z0-9_-]+)').firstMatch(raw);
      if (match != null && match.groupCount >= 1) {
        final fileId = match.group(1);
        return 'https://drive.google.com/uc?export=download&id=$fileId';
      }
    }

    // Google Docs PDF export
    if (raw.contains('docs.google.com/document/d/')) {
      final match = RegExp(r'/document/d/([a-zA-Z0-9_-]+)').firstMatch(raw);
      if (match != null && match.groupCount >= 1) {
        final docId = match.group(1);
        return 'https://docs.google.com/document/d/$docId/export?format=pdf';
      }
    }

    return raw;
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).colorScheme.primary;
    final cardBg = Theme.of(context).colorScheme.surface;
    final bgDark = Theme.of(context).scaffoldBackgroundColor;

    final assetPath = _bundledAssetPath;
    final effectiveUrl = _normalizedPdfUrl;
    final hasSource = assetPath != null || (effectiveUrl.isNotEmpty && effectiveUrl.startsWith('http'));

    return Scaffold(
      backgroundColor: bgDark,
      appBar: AppBar(
        backgroundColor: cardBg,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        // Title gets maximum space with zero crowding
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
        actions: const [], // Zero redundant buttons or page numbers to keep header clean and spacious
      ),
      body: Stack(
        children: [
          if (!hasSource)
            _buildEmptyState(
              title: 'RULEBOOK ANNOUNCEMENT SOON',
              subtitle: 'The official rulebook guidelines for ${widget.event.title} are being finalized by the organizing society and will be available here shortly.',
            )
          else if (_loadFailed)
            _buildLoadFailedState()
          else if (assetPath != null)
            SfPdfViewer.asset(
              assetPath,
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
                    _isLoading = false;
                  });
                }
              },
              onDocumentLoadFailed: (details) {
                // If local asset failed, try network fallback if URL exists
                if (effectiveUrl.isNotEmpty && effectiveUrl.startsWith('http')) {
                  setState(() {
                    _isLoading = true;
                  });
                } else {
                  if (mounted) {
                    setState(() {
                      _loadFailed = true;
                      _isLoading = false;
                    });
                  }
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
                    _isLoading = false;
                  });
                }
              },
              onDocumentLoadFailed: (details) {
                if (mounted) {
                  setState(() {
                    _loadFailed = true;
                    _isLoading = false;
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

          // Clean, quiet loading spinner with NO noisy text
          if (_isLoading && hasSource && !_loadFailed)
            Container(
              color: bgDark.withValues(alpha: 0.7),
              child: Center(
                child: SizedBox(
                  width: 36,
                  height: 36,
                  child: CircularProgressIndicator(
                    color: primaryColor,
                    strokeWidth: 2.5,
                  ),
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
                            style: TextStyle(color: primaryColor, fontSize: 11, fontWeight: FontWeight.w600),
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
              child: Icon(Icons.menu_book_outlined, size: 42, color: primaryColor.withValues(alpha: 0.6)),
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
            Icon(Icons.description_outlined, size: 42, color: primaryColor.withValues(alpha: 0.7)),
            const SizedBox(height: 14),
            Text(
              'RULEBOOK ACCESS UPDATING',
              style: GoogleFonts.orbitron(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                letterSpacing: 1.0,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'The document is being synced from the festival repository. Please try again shortly.',
              style: GoogleFonts.rajdhani(
                fontSize: 13,
                color: Colors.white60,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 18),
            OutlinedButton(
              onPressed: () {
                setState(() {
                  _loadFailed = false;
                  _isLoading = true;
                });
              },
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: primaryColor.withValues(alpha: 0.5)),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: Text(
                'RETRY ACCESS',
                style: GoogleFonts.rajdhani(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
