import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../utils/text_styles.dart';
import '../providers/gateway_provider.dart';
import '../services/smpp_logger.dart';

class SmppLogsScreen extends StatefulWidget {
  const SmppLogsScreen({Key? key}) : super(key: key);

  @override
  State<SmppLogsScreen> createState() => _SmppLogsScreenState();
}

class _SmppLogsScreenState extends State<SmppLogsScreen> {
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();
  List<String> _filteredLogs = [];
  String _searchQuery = '';
  SmppLogLevel _selectedLogLevel = SmppLogLevel.info;

  @override
  void initState() {
    super.initState();
    _loadLogs();
    _searchController.addListener(_filterLogs);
  }

  void _loadLogs() {
    final logs = SmppLogger().getLogs();
    _filteredLogs = List.from(logs);
    setState(() {});
  }

  void _filterLogs() {
    final query = _searchController.text.toLowerCase();
    final logs = SmppLogger().getLogs();
    
    _filteredLogs = logs.where((log) {
      final matchesSearch = query.isEmpty || log.toLowerCase().contains(query);
      final matchesLevel = _selectedLogLevel == SmppLogLevel.info || 
          log.contains('[${_selectedLogLevel.name.toUpperCase()}]');
      return matchesSearch && matchesLevel;
    }).toList();
    
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A1A1A),
        elevation: 0,
        title: Text(
          'SMPP Logs',
          style: AppTextStyles.poppins(
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: _loadLogs,
          ),
          IconButton(
            icon: const Icon(Icons.clear, color: Colors.white),
            onPressed: _clearLogs,
          ),
        ],
      ),
      body: Column(
        children: [
          _buildSearchBar(),
          _buildLogLevelFilter(),
          Expanded(
            child: _buildLogsList(),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: TextField(
        controller: _searchController,
        style: AppTextStyles.poppins(color: Colors.white),
        decoration: InputDecoration(
          hintText: 'Search logs...',
          hintStyle: AppTextStyles.poppins(color: Colors.grey[400]),
          prefixIcon: Icon(Icons.search, color: Colors.grey[400]),
          suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(
                  icon: Icon(Icons.clear, color: Colors.grey[400]),
                  onPressed: () {
                    _searchController.clear();
                    _filterLogs();
                  },
                )
              : null,
          enabledBorder: OutlineInputBorder(
            borderSide: BorderSide(color: Colors.grey[600]!),
            borderRadius: BorderRadius.circular(8),
          ),
          focusedBorder: OutlineInputBorder(
            borderSide: BorderSide(color: Colors.blue),
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
    );
  }

  Widget _buildLogLevelFilter() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Text(
            'Log Level: ',
            style: AppTextStyles.poppins(color: Colors.white),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: SmppLogLevel.values.map((level) {
                  final isSelected = _selectedLogLevel == level;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: FilterChip(
                      label: Text(
                        level.name.toUpperCase(),
                        style: AppTextStyles.poppins(
                          color: isSelected ? Colors.white : Colors.grey[400],
                          fontSize: 12,
                        ),
                      ),
                      selected: isSelected,
                      onSelected: (selected) {
                        setState(() {
                          _selectedLogLevel = level;
                        });
                        _filterLogs();
                      },
                      backgroundColor: Colors.grey[800],
                      selectedColor: _getLogLevelColor(level),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _getLogLevelColor(SmppLogLevel level) {
    switch (level) {
      case SmppLogLevel.debug:
        return Colors.blue;
      case SmppLogLevel.info:
        return Colors.green;
      case SmppLogLevel.warning:
        return Colors.orange;
      case SmppLogLevel.error:
        return Colors.red;
    }
  }

  Widget _buildLogsList() {
    if (_filteredLogs.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.info_outline,
              size: 64,
              color: Colors.grey[600],
            ),
            const SizedBox(height: 16),
            Text(
              'No logs found',
              style: AppTextStyles.poppins(
                color: Colors.grey[600],
                fontSize: 18,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Try adjusting your search or log level filter',
              style: AppTextStyles.poppins(
                color: Colors.grey[500],
                fontSize: 14,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.all(16),
      itemCount: _filteredLogs.length,
      itemBuilder: (context, index) {
        final log = _filteredLogs[index];
        final logLevel = _extractLogLevel(log);
        
        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFF1A1A1A),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: _getLogLevelColor(logLevel).withOpacity(0.3),
              width: 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: _getLogLevelColor(logLevel),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    logLevel.name.toUpperCase(),
                    style: AppTextStyles.poppins(
                      color: _getLogLevelColor(logLevel),
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    _extractTimestamp(log),
                    style: AppTextStyles.poppins(
                      color: Colors.grey[500],
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                _extractMessage(log),
                style: AppTextStyles.poppins(
                  color: Colors.white,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  SmppLogLevel _extractLogLevel(String log) {
    if (log.contains('[DEBUG]')) return SmppLogLevel.debug;
    if (log.contains('[INFO]')) return SmppLogLevel.info;
    if (log.contains('[WARNING]')) return SmppLogLevel.warning;
    if (log.contains('[ERROR]')) return SmppLogLevel.error;
    return SmppLogLevel.info;
  }

  String _extractTimestamp(String log) {
    final match = RegExp(r'\[(.*?)\]').firstMatch(log);
    return match?.group(1) ?? '';
  }

  String _extractMessage(String log) {
    final parts = log.split(']: ');
    return parts.length > 1 ? parts.sublist(1).join(']: ') : log;
  }

  void _clearLogs() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A1A),
        title: Text(
          'Clear Logs',
          style: AppTextStyles.poppins(color: Colors.white),
        ),
        content: Text(
          'Are you sure you want to clear all SMPP logs?',
          style: AppTextStyles.poppins(color: Colors.grey[300]),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: AppTextStyles.poppins(color: Colors.grey[400]),
            ),
          ),
          TextButton(
            onPressed: () {
              SmppLogger().clearLogs();
              _loadLogs();
              Navigator.pop(context);
            },
            child: Text(
              'Clear',
              style: AppTextStyles.poppins(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }
}
