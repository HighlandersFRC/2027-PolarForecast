import 'dart:typed_data';

import 'package:app/APIService.dart';
import 'package:app/services/auth_service.dart';
import 'package:app/widgets/PolarForecastAppBar.dart';
import 'package:app/widgets/matte_theme.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

class RobotImageCapturePage extends StatefulWidget {
  final int teamNumber;
  final String eventCode;

  const RobotImageCapturePage({
    super.key,
    required this.teamNumber,
    required this.eventCode,
  });

  @override
  State<RobotImageCapturePage> createState() => _RobotImageCapturePageState();
}

class _RobotImageCapturePageState extends State<RobotImageCapturePage> {
  final ImagePicker _imagePicker = ImagePicker();

  Uint8List? _photoBytes;
  String _contentType = 'image/jpeg';
  String _captureSource = 'camera';
  bool _isPicking = false;
  bool _isSubmitting = false;

  Future<void> _pickPhoto(ImageSource source) async {
    if (_isPicking || _isSubmitting) return;
    setState(() => _isPicking = true);

    try {
      final picked = await _imagePicker.pickImage(
        source: source,
        preferredCameraDevice: CameraDevice.rear,
        maxWidth: 2048,
        maxHeight: 2048,
        imageQuality: 92,
        requestFullMetadata: false,
      );
      if (picked == null) return;

      final bytes = await picked.readAsBytes();
      if (bytes.length > 8 * 1024 * 1024) {
        _showMessage('That photo is larger than 8 MB. Please try again.');
        return;
      }

      final detectedType = _detectImageContentType(bytes);
      if (detectedType == null) {
        _showMessage('Please choose a JPEG, PNG, or WebP image.');
        return;
      }

      if (!mounted) return;
      setState(() {
        _photoBytes = bytes;
        _contentType = detectedType;
        _captureSource = source == ImageSource.camera ? 'camera' : 'upload';
      });
    } catch (error) {
      if (mounted) _showMessage('Could not open the camera: $error');
    } finally {
      if (mounted) setState(() => _isPicking = false);
    }
  }

  String? _detectImageContentType(Uint8List bytes) {
    if (bytes.length >= 3 &&
        bytes[0] == 0xFF &&
        bytes[1] == 0xD8 &&
        bytes[2] == 0xFF) {
      return 'image/jpeg';
    }
    if (bytes.length >= 8 &&
        bytes[0] == 0x89 &&
        bytes[1] == 0x50 &&
        bytes[2] == 0x4E &&
        bytes[3] == 0x47) {
      return 'image/png';
    }
    if (bytes.length >= 12 &&
        String.fromCharCodes(bytes.sublist(0, 4)) == 'RIFF' &&
        String.fromCharCodes(bytes.sublist(8, 12)) == 'WEBP') {
      return 'image/webp';
    }
    return null;
  }

  Future<void> _submit() async {
    final bytes = _photoBytes;
    if (bytes == null) {
      _showMessage('Take or choose a robot photo first.');
      return;
    }

    final auth = context.read<AuthService>();
    final groupId = auth.groupId?.trim();
    final username = auth.username?.trim();
    if (groupId == null ||
        groupId.isEmpty ||
        username == null ||
        username.isEmpty) {
      _showMessage('Log in and join a scouting group before adding photos.');
      return;
    }

    setState(() => _isSubmitting = true);
    final api = APIService();
    try {
      await api.submitRobotImage(
        groupId: groupId,
        event: widget.eventCode,
        team: widget.teamNumber,
        scoutInfo: {
          'userId': username,
          'firstName': auth.firstName ?? '',
          'username': username,
          'team': auth.team.toString(),
        },
        bytes: bytes,
        contentType: _contentType,
        captureSource: _captureSource,
      );

      if (!mounted) return;
      _showMessage('Robot photo saved for Team ${widget.teamNumber}.');
      Navigator.of(context).pop(true);
    } catch (error) {
      if (mounted) _showMessage('Could not save robot photo: $error');
    } finally {
      api.dispose();
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: PolarForecastAppBar(),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            MattePanel(
              padding: const EdgeInsets.all(20),
              tint: const Color(0xFFB388FF),
              borderRadius: BorderRadius.circular(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color:
                              const Color(0xFFB388FF).withValues(alpha: 0.13),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Icon(
                          Icons.add_a_photo_rounded,
                          color: Color(0xFFC8A7FF),
                        ),
                      ),
                      const SizedBox(width: 13),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Team ${widget.teamNumber} Robot Image',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 19,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 3),
                            const Text(
                              'Separate image data collection',
                              style: TextStyle(color: Colors.white54),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  Container(
                    padding: const EdgeInsets.all(13),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFB74D).withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: const Color(0xFFFFB74D).withValues(alpha: 0.24),
                      ),
                    ),
                    child: const Text(
                      'For the best photo: use landscape orientation, include the entire robot, keep the lens level, use good lighting, and avoid people blocking it.',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 13,
                        height: 1.45,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  AspectRatio(
                    aspectRatio: 16 / 10,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(15),
                      child: ColoredBox(
                        color: const Color(0xFF0B0D11),
                        child: _photoBytes == null
                            ? const Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.photo_camera_back_outlined,
                                    color: Colors.white30,
                                    size: 52,
                                  ),
                                  SizedBox(height: 10),
                                  Text(
                                    'No image collected',
                                    style: TextStyle(color: Colors.white38),
                                  ),
                                ],
                              )
                            : Image.memory(
                                _photoBytes!,
                                fit: BoxFit.contain,
                                filterQuality: FilterQuality.high,
                              ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 15),
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final camera = FilledButton.icon(
                        onPressed: _isPicking || _isSubmitting
                            ? null
                            : () => _pickPhoto(ImageSource.camera),
                        icon: const Icon(Icons.photo_camera_rounded),
                        label: Text(
                          _photoBytes == null ? 'Take Photo' : 'Retake',
                        ),
                      );
                      final upload = OutlinedButton.icon(
                        onPressed: _isPicking || _isSubmitting
                            ? null
                            : () => _pickPhoto(ImageSource.gallery),
                        icon: const Icon(Icons.upload_file_rounded),
                        label: const Text('Choose Existing'),
                      );

                      if (constraints.maxWidth < 430) {
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [camera, const SizedBox(height: 9), upload],
                        );
                      }
                      return Row(
                        children: [
                          Expanded(child: camera),
                          const SizedBox(width: 10),
                          Expanded(child: upload),
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed:
                          _photoBytes == null || _isSubmitting ? null : _submit,
                      icon: _isSubmitting
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.cloud_upload_rounded),
                      label: Text(
                        _isSubmitting ? 'Saving...' : 'Save Robot Image',
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
