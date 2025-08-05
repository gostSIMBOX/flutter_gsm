import 'package:flutter/material.dart';
import '../utils/text_styles.dart';
import '../models/active_call.dart';

class ActiveCallCard extends StatelessWidget {
  final ActiveCall call;

  const ActiveCallCard({
    super.key,
    required this.call,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: const Color(0xFF1A1A1A),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: _getCallDirectionColor(call.direction),
                  child: Icon(
                    call.direction == 'incoming' 
                      ? Icons.call_received 
                      : Icons.call_made,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        call.fromNumber ?? 'Unknown',
                        style: TextStyles.title.copyWith(
                          color: Colors.white,
                          fontSize: 18,
                        ),
                      ),
                      Text(
                        _getCallStatusText(call.status),
                        style: TextStyles.caption.copyWith(
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.orange.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    _formatDuration(call.duration),
                    style: TextStyles.caption.copyWith(
                      color: Colors.orange,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildCallInfo(
                    title: 'Line ID',
                    value: call.lineId,
                    icon: Icons.phone,
                    color: Colors.blue,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildCallInfo(
                    title: 'SIP MOS',
                    value: call.sipMos.toStringAsFixed(1),
                    icon: Icons.assessment,
                    color: Colors.green,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildCallInfo(
                    title: 'GSM MOS',
                    value: call.gsmMos.toStringAsFixed(1),
                    icon: Icons.signal_cellular_alt,
                    color: Colors.orange,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildCallInfo(
                    title: 'SIP Jitter',
                    value: '${call.sipJitter.toStringAsFixed(1)}ms',
                    icon: Icons.trending_up,
                    color: Colors.purple,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildCallInfo(
                    title: 'GSM Jitter',
                    value: '${call.gsmJitter.toStringAsFixed(1)}ms',
                    icon: Icons.trending_down,
                    color: Colors.teal,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildCallInfo(
                    title: 'Latency',
                    value: '${call.sipLatency.toStringAsFixed(1)}ms',
                    icon: Icons.speed,
                    color: Colors.red,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildCallControls(),
          ],
        ),
      ),
    );
  }

  Widget _buildCallInfo({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: color.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 16,
                color: color,
              ),
              const SizedBox(width: 4),
              Text(
                title,
                style: TextStyles.caption.copyWith(
                  color: Colors.grey,
                  fontSize: 10,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyles.body.copyWith(
              color: color,
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCallControls() {
    return Row(
      children: [
        Expanded(
          child: _buildControlButton(
            title: 'End Call',
            icon: Icons.call_end,
            color: Colors.red,
            onPressed: () {
              // TODO: Implement end call
            },
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildControlButton(
            title: 'Hold',
            icon: Icons.pause,
            color: Colors.orange,
            onPressed: () {
              // TODO: Implement hold call
            },
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildControlButton(
            title: 'Mute',
            icon: Icons.mic_off,
            color: Colors.grey,
            onPressed: () {
              // TODO: Implement mute
            },
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildControlButton(
            title: 'Speaker',
            icon: Icons.volume_up,
            color: Colors.blue,
            onPressed: () {
              // TODO: Implement speaker toggle
            },
          ),
        ),
      ],
    );
  }

  Widget _buildControlButton({
    required String title,
    required IconData icon,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: color.withValues(alpha: 0.1),
        foregroundColor: color,
        padding: const EdgeInsets.symmetric(vertical: 8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: BorderSide(
            color: color.withValues(alpha: 0.3),
            width: 1,
          ),
        ),
      ),
      child: Column(
        children: [
          Icon(icon, size: 20),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyles.caption.copyWith(
              color: color,
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }

  Color _getCallDirectionColor(String direction) {
    switch (direction) {
      case 'incoming':
        return Colors.green;
      case 'outgoing':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  String _getCallStatusText(String status) {
    switch (status) {
      case 'connected':
        return 'Connected';
      case 'ringing':
        return 'Ringing';
      case 'dialing':
        return 'Dialing';
      case 'ended':
        return 'Ended';
      default:
        return 'Unknown';
    }
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds.remainder(60);
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }
} 