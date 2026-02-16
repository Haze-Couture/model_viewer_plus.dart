import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;

import 'html_builder.dart';
import 'model_viewer_plus.dart';
import 'shim/dart_ui_web_fake.dart'
    if (dart.library.ui_web) 'dart:ui_web'
    as ui_web;
import 'shim/dart_web_fake.dart'
    if (dart.library.js_interop) 'package:web/web.dart'
    as web;
import 'shim/dart_web_fake.dart' if (dart.library.js_interop) 'dart:js_interop';

class ModelViewerState extends State<ModelViewer> {
  bool _isLoading = true;
  final String _uniqueViewType = UniqueKey().toString();

  @override
  void initState() {
    super.initState();
    unawaited(generateModelViewerHtml());
  }

  /// To generate the HTML code for using the model viewer.
  Future<void> generateModelViewerHtml() async {
    debugPrint('[model_viewer_plus] web: loading template and building HTML (src=${widget.src})');
    final String htmlTemplate = await rootBundle.loadString(
      'packages/model_viewer_plus/assets/template.html',
    );

    final String html = _buildHTML(htmlTemplate);
    debugPrint('[model_viewer_plus] web: HTML length=${html.length}, contains model-viewer=${html.contains('<model-viewer')}, contains <script>=${html.contains('<script')}');

    final String viewType = 'model-viewer-html-$_uniqueViewType';
    ui_web.platformViewRegistry.registerViewFactory(
      viewType,
      (viewId) {
        debugPrint('[model_viewer_plus] web: view factory called for viewType=$viewType viewId=$viewId');
        // Use a div container so the parser creates <model-viewer> as a normal child.
        // (Using HTMLHtmlElement can lead to the custom element not appearing in the DOM.)
        final element = web.HTMLDivElement()
          ..style.border = 'none'
          ..style.height = '100%'
          ..style.width = '100%'
          ..innerHTML = html.toJS;
        final int childCount = element.childNodes.length;
        final bool hasModelViewer = element.querySelector('model-viewer') != null;
        debugPrint('[model_viewer_plus] web: after innerHTML, childCount=$childCount, has model-viewer=$hasModelViewer');
        return element;
      },
    );

    debugPrint('[model_viewer_plus] web: registered viewType=$viewType, setState loading=false');
    setState(() => _isLoading = false);
  }

  @override
  Widget build(final BuildContext context) {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(
          semanticsLabel: 'Loading Model Viewer...',
        ),
      );
    } else {
      return HtmlElementView(viewType: 'model-viewer-html-$_uniqueViewType');
    }
  }

  String _buildHTML(final String htmlTemplate) {
    if (widget.src.startsWith('file://')) {
      // Local file URL can't be used in Flutter web.
      debugPrint("file:// URL scheme can't be used in Flutter web.");
      throw ArgumentError("file:// URL scheme can't be used in Flutter web.");
    }

    // On web, the template HTML is set via innerHTML on a platform-view div that
    // lives inside the Flutter document. We must strip <meta>, <style>, and
    // <script> tags that are only meant for the mobile WebView (a standalone
    // document). Leaving them in causes global CSS rules (e.g. body {…}) to leak
    // into the Flutter host and interfere with platform-view positioning —
    // especially on mobile browsers inside an iframe where it triggers viewport
    // resize/reflow that pushes the platform view off-screen.
    var processedTemplate = htmlTemplate
        .replaceFirst(
          '<script type="module" src="model-viewer.min.js" defer></script>',
          '',
        );
    // Strip <meta …> tags (viewport meta in the body is invalid & can confuse mobile browsers)
    processedTemplate = processedTemplate.replaceAll(RegExp(r'<meta[^>]*/?>', caseSensitive: false), '');
    // Strip <style …>…</style> blocks (the body{} rule leaks into the Flutter document)
    processedTemplate = processedTemplate.replaceAll(RegExp(r'<style[^>]*>.*?</style>', caseSensitive: false, dotAll: true), '');

    return HTMLBuilder.build(
      htmlTemplate: processedTemplate,
      // Attributes
      src: widget.src,
      alt: widget.alt,
      poster: widget.poster,
      loading: widget.loading,
      reveal: widget.reveal,
      withCredentials: widget.withCredentials,
      // AR Attributes
      ar: widget.ar,
      arModes: widget.arModes,
      // arScale: widget.arScale,
      // arPlacement: widget.arPlacement,
      iosSrc: widget.iosSrc,
      xrEnvironment: widget.xrEnvironment,
      // Staing & Cameras Attributes
      cameraControls: widget.cameraControls,
      disablePan: widget.disablePan,
      disableTap: widget.disableTap,
      touchAction: widget.touchAction,
      disableZoom: widget.disableZoom,
      orbitSensitivity: widget.orbitSensitivity,
      autoRotate: widget.autoRotate,
      autoRotateDelay: widget.autoRotateDelay,
      rotationPerSecond: widget.rotationPerSecond,
      interactionPrompt: widget.interactionPrompt,
      interactionPromptStyle: widget.interactionPromptStyle,
      interactionPromptThreshold: widget.interactionPromptThreshold,
      cameraOrbit: widget.cameraOrbit,
      cameraTarget: widget.cameraTarget,
      fieldOfView: widget.fieldOfView,
      maxCameraOrbit: widget.maxCameraOrbit,
      minCameraOrbit: widget.minCameraOrbit,
      maxFieldOfView: widget.maxFieldOfView,
      minFieldOfView: widget.minFieldOfView,
      interpolationDecay: widget.interpolationDecay,
      // Lighting & Env Attributes
      skyboxImage: widget.skyboxImage,
      environmentImage: widget.environmentImage,
      exposure: widget.exposure,
      shadowIntensity: widget.shadowIntensity,
      shadowSoftness: widget.shadowSoftness,
      // Animation Attributes
      animationName: widget.animationName,
      animationCrossfadeDuration: widget.animationCrossfadeDuration,
      autoPlay: widget.autoPlay,
      // Materials & Scene Attributes
      variantName: widget.variantName,
      orientation: widget.orientation,
      scale: widget.scale,

      // CSS Styles
      backgroundColor: widget.backgroundColor,

      // Annotations CSS
      minHotspotOpacity: widget.minHotspotOpacity,
      maxHotspotOpacity: widget.maxHotspotOpacity,

      // Others
      innerModelViewerHtml: widget.innerModelViewerHtml,
      relatedCss: widget.relatedCss,
      relatedJs: widget.relatedJs,
      meshoptDecoderPath: widget.meshoptDecoderPath,
      id: widget.id,
      containerId: 'model-viewer-container-$_uniqueViewType'
          .replaceAll(RegExp(r'[^a-zA-Z0-9\-_.]'), '_'),
      debugLogging: widget.debugLogging,
    );
  }
}
