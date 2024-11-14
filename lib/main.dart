// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// ignore_for_file: public_member_api_docs, avoid_print, use_build_context_synchronously

/// An example of using the plugin, controlling lifecycle and playback of the
/// video.
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:video_player_avplay/video_player.dart';
import 'package:video_player_avplay/video_player_platform_interface.dart';

void main() {
  runApp(
    MaterialApp(
      home: _App(),
    ),
  );
}

class _App extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 7,
      child: Scaffold(
        key: const ValueKey<String>('home_page'),
        appBar: AppBar(
          title: const Text('Video player example'),
          bottom: const TabBar(
            isScrollable: true,
            tabs: <Widget>[
              //Tab(icon: Icon(Icons.cloud), text: 'MP4'),
              //Tab(icon: Icon(Icons.cloud), text: 'HLS'),
              //Tab(icon: Icon(Icons.cloud), text: 'Dash'),
              Tab(icon: Icon(Icons.cloud), text: 'DRM Widevine'),
              //Tab(icon: Icon(Icons.cloud), text: 'DRM PlayReady'),
              //Tab(icon: Icon(Icons.cloud), text: 'Track'),
              //Tab(icon: Icon(Icons.cloud), text: 'Asset'),
            ],
          ),
        ),
        body: TabBarView(
          children: <Widget>[
            //_Mp4RemoteVideo(),
            // _HlsRomoteVideo(),
            //_DashRomoteVideo(),
            _DrmRemoteVideo(),
            // _DrmRemoteVideo2(),
            // _TrackTest(),
            // _AssetVideo(),
          ],
        ),
      ),
    );
  }
}

class _DrmRemoteVideo extends StatefulWidget {
  @override
  State<_DrmRemoteVideo> createState() => _DrmRemoteVideoState();
}

class _DrmRemoteVideoState extends State<_DrmRemoteVideo> {
  late VideoPlayerController _controller;

  @override
  void initState() {
    super.initState();

    _controller = VideoPlayerController.network(
      'http://wp1-vxtoken-obc0304-hzn-ci.t1.lab.dyncdn.dmdsdp.com/dash/GO-AVC-DASH/NPO2_HD_CI/manifest.mpd',
      drmConfigs: DrmConfigs(
        type: DrmType.playready,
        licenseCallback: (Uint8List challenge) async {
          final http.Response response = await http.post(
            Uri.parse(
                'https://lgilab5aitc.test.ott.irdeto.com/licenseServer/playready/v1/lgilab5aitc/license?contentId=LV-nPRM-GRP2'),
            body: challenge,
          );
          return response.bodyBytes;
        },
      ),
      formatHint: VideoFormat.dash,
    );

    _controller.addListener(() {
      if (_controller.value.hasError) {
        print(_controller.value.errorDescription);
      }
      setState(() {});
    });
    _controller.initialize().then((_) {
      setState(() {});
      DurationRange range = _controller.value.duration;
      print('duration: $range');
      _controller.seekTo(range.start + Duration(seconds: 300));
      print('seekTo: ${range.start + Duration(seconds: 300)}}');
    });
    _controller.play();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        children: <Widget>[
          Container(padding: const EdgeInsets.only(top: 20.0)),
          const Text('Play DRM Widevine'),
          Container(
            padding: const EdgeInsets.all(20),
            child: AspectRatio(
              aspectRatio: _controller.value.aspectRatio,
              child: Stack(
                alignment: Alignment.bottomCenter,
                children: <Widget>[
                  VideoPlayer(_controller),
                  ClosedCaption(text: _controller.value.caption.text),
                  _ControlsOverlay(controller: _controller),
                  VideoProgressIndicator(_controller, allowScrubbing: true),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ControlsOverlay extends StatelessWidget {
  const _ControlsOverlay({required this.controller});

  static const List<Duration> _exampleCaptionOffsets = <Duration>[
    Duration(seconds: -10),
    Duration(seconds: -3),
    Duration(seconds: -1, milliseconds: -500),
    Duration(milliseconds: -250),
    Duration.zero,
    Duration(milliseconds: 250),
    Duration(seconds: 1, milliseconds: 500),
    Duration(seconds: 3),
    Duration(seconds: 10),
  ];
  static const List<double> _examplePlaybackRates = <double>[
    0.25,
    0.5,
    1.0,
    1.5,
    2.0,
    3.0,
    5.0,
    10.0,
  ];

  final VideoPlayerController controller;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: <Widget>[
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 50),
          reverseDuration: const Duration(milliseconds: 200),
          child: controller.value.isPlaying
              ? const SizedBox.shrink()
              : const ColoredBox(
                  color: Colors.black26,
                  child: Center(
                    child: Icon(
                      Icons.play_arrow,
                      color: Colors.white,
                      size: 100.0,
                      semanticLabel: 'Play',
                    ),
                  ),
                ),
        ),
        GestureDetector(
          onTap: () {
            controller.value.isPlaying ? controller.pause() : controller.play();
          },
        ),
        Align(
          alignment: Alignment.topLeft,
          child: PopupMenuButton<Duration>(
            initialValue: controller.value.captionOffset,
            tooltip: 'Caption Offset',
            onSelected: (Duration delay) {
              controller.setCaptionOffset(delay);
            },
            itemBuilder: (BuildContext context) {
              return <PopupMenuItem<Duration>>[
                for (final Duration offsetDuration in _exampleCaptionOffsets)
                  PopupMenuItem<Duration>(
                    value: offsetDuration,
                    child: Text('${offsetDuration.inMilliseconds}ms'),
                  )
              ];
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(
                // Using less vertical padding as the text is also longer
                // horizontally, so it feels like it would need more spacing
                // horizontally (matching the aspect ratio of the video).
                vertical: 12,
                horizontal: 16,
              ),
              child: Text('${controller.value.captionOffset.inMilliseconds}ms'),
            ),
          ),
        ),
        Align(
          alignment: Alignment.topRight,
          child: PopupMenuButton<double>(
            initialValue: controller.value.playbackSpeed,
            tooltip: 'Playback speed',
            onSelected: (double speed) {
              controller.setPlaybackSpeed(speed);
            },
            itemBuilder: (BuildContext context) {
              return <PopupMenuItem<double>>[
                for (final double speed in _examplePlaybackRates)
                  PopupMenuItem<double>(
                    value: speed,
                    child: Text('${speed}x'),
                  )
              ];
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(
                // Using less vertical padding as the text is also longer
                // horizontally, so it feels like it would need more spacing
                // horizontally (matching the aspect ratio of the video).
                vertical: 12,
                horizontal: 16,
              ),
              child: Text('${controller.value.playbackSpeed}x'),
            ),
          ),
        ),
      ],
    );
  }
}
