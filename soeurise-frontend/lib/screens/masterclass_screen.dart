import 'package:flutter/material.dart';
import '../constants.dart';

// Conditional imports for platform-specific WebView
import 'masterclass_webview_stub.dart'
    if (dart.library.html) 'masterclass_webview_web.dart'
    if (dart.library.io) 'masterclass_webview_mobile.dart' as platform_view;

class MasterclassScreen extends StatefulWidget {
  const MasterclassScreen({super.key});

  @override
  State<MasterclassScreen> createState() => _MasterclassScreenState();
}

class _MasterclassScreenState extends State<MasterclassScreen> {
  static const String _websiteUrl = 'https://soeurise.com/';

  bool _isLoading = true;
  bool _hasError = false;
  int _loadingProgress = 0;
  Key _webViewKey = UniqueKey();

  void onLoadStart() {
    if (mounted) {
      setState(() {
        _isLoading = true;
        _hasError = false;
        _loadingProgress = 0;
      });
    }
  }

  void onProgress(int progress) {
    if (mounted) {
      setState(() => _loadingProgress = progress);
    }
  }

  void onLoadFinished() {
    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  void onError() {
    if (mounted) {
      setState(() {
        _hasError = true;
        _isLoading = false;
      });
    }
  }

  void _reload() {
    setState(() {
      _hasError = false;
      _isLoading = true;
      _webViewKey = UniqueKey();
    });
  }

  void _handleExit() {
    final navigator = Navigator.of(context);
    if (navigator.canPop()) {
      navigator.pop();
      return;
    }
    _reload();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Retour au catalogue des masterclass'),
        backgroundColor: AppColors.primary,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          onPressed: _handleExit,
          icon: const Icon(
            Icons.close_rounded,
            color: AppColors.textPrimary,
          ),
          tooltip: 'Quitter',
        ),
        title: Text(
          'Masterclass',
          style: AppTextStyles.headline3,
        ),
        actions: [
          IconButton(
            onPressed: _reload,
            icon: const Icon(
              Icons.refresh_rounded,
              color: AppColors.primary,
            ),
            tooltip: 'Rafraîchir',
          ),
        ],
        bottom: _isLoading
            ? PreferredSize(
                preferredSize: const Size.fromHeight(3),
                child: LinearProgressIndicator(
                  value: _loadingProgress > 0 ? _loadingProgress / 100 : null,
                  backgroundColor: AppColors.beige,
                  valueColor: const AlwaysStoppedAnimation<Color>(
                    AppColors.primary,
                  ),
                  minHeight: 3,
                ),
              )
            : null,
      ),
      body: _hasError ? _buildErrorView() : _buildWebView(),
    );
  }

  Widget _buildWebView() {
    final bottomInset = MediaQuery.of(context).padding.bottom + 78;
    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: platform_view.buildWebView(
        key: _webViewKey,
        url: _websiteUrl,
        onLoadStart: onLoadStart,
        onProgress: onProgress,
        onLoadFinished: onLoadFinished,
        onError: onError,
      ),
    );
  }

  Widget _buildErrorView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppColors.primary.withAlpha(20),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.wifi_off_rounded,
                size: 40,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Impossible de charger la page',
              style: AppTextStyles.headline3,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              'Vérifiez votre connexion internet\net réessayez.',
              style: AppTextStyles.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: 200,
              height: 48,
              child: ElevatedButton.icon(
                onPressed: _reload,
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Réessayer'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppBorderRadius.pill),
                  ),
                  textStyle: AppTextStyles.button,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
