import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:csv/csv.dart';

void main() {
  runApp(const SwatCliApp());
}

class SwatCliApp extends StatelessWidget {
  const SwatCliApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Swat Rural CLI Manager',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.indigo,
        useMaterial3: true,
      ),
      home: const SetupScreen(),
    );
  }
}

// ============ SETUP SCREEN ============
class SetupScreen extends StatefulWidget {
  const SetupScreen({super.key});

  @override
  State<SetupScreen> createState() => _SetupScreenState();
}

class _SetupScreenState extends State<SetupScreen> {
  final TextEditingController _urlController = TextEditingController();

  void connect() {
    final url = _urlController.text.trim();
    final match = RegExp(r'/d/([a-zA-Z0-9-_]+)').firstMatch(url);
    if (match == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Invalid Google Sheet URL'), backgroundColor: Colors.red),
      );
      return;
    }
    final sheetId = match.group(1)!;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => RoleScreen(sheetId: sheetId)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF667eea), Color(0xFF764ba2)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 40),
                const Icon(Icons.phone_android, size: 60, color: Colors.white),
                const SizedBox(height: 20),
                const Text(
                  'Swat Rural CLI Manager',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white),
                ),
                const SizedBox(height: 40),
                Card(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Setup', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 10),
                        const Text(
                          '1. Create Google Sheet with columns:\nExchange, MDN, Tag-In, Tag-Out, DC-Number, DC-Pair, DP-Number, DP-Pair\n\n2. Share → Anyone with link can view\n\n3. Paste URL below:',
                          style: TextStyle(fontSize: 13, color: Colors.grey),
                        ),
                        const SizedBox(height: 16),
                        TextField(
                          controller: _urlController,
                          decoration: InputDecoration(
                            labelText: 'Google Sheet URL',
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: connect,
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                            child: const Text('Connect', style: TextStyle(fontSize: 16)),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ============ ROLE SCREEN ============
class RoleScreen extends StatelessWidget {
  final String sheetId;
  const RoleScreen({super.key, required this.sheetId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF667eea), Color(0xFF764ba2)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    'Select Role',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                  const SizedBox(height: 30),
                  _roleButton(context, 'Admin', Icons.admin_panel_settings, Colors.indigo, () {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => AdminScreen(sheetId: sheetId)));
                  }),
                  const SizedBox(height: 16),
                  _roleButton(context, 'Staff', Icons.engineering, Colors.teal, () {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => StaffScreen(sheetId: sheetId)));
                  }),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _roleButton(BuildContext context, String title, IconData icon, Color color, VoidCallback onTap) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: onTap,
        icon: Icon(icon, size: 28),
        label: Text(title, style: const TextStyle(fontSize: 18)),
        style: ElevatedButton.styleFrom(
          foregroundColor: color,
          backgroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 20),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
    );
  }
}

// ============ DATA SERVICE ============
class SheetService {
  static Future<List<Map<String, String>>> fetchData(String sheetId) async {
    final url = 'https://docs.google.com/spreadsheets/d/$sheetId/export?format=csv';
    final response = await http.get(Uri.parse(url));
    if (response.statusCode != 200) throw Exception('Failed to load');
    
    final csv = const CsvToListConverter().convert(response.body);
    if (csv.isEmpty) return [];
    
    final headers = csv[0].map((h) => h.toString()).toList();
    final rows = <Map<String, String>>[];
    
    for (int i = 1; i < csv.length; i++) {
      final row = <String, String>{};
      for (int j = 0; j < headers.length && j < csv[i].length; j++) {
        row[headers[j]] = csv[i][j].toString();
      }
      rows.add(row);
    }
    return rows;
  }
}

// ============ ADMIN SCREEN ============
class AdminScreen extends StatefulWidget {
  final String sheetId;
  const AdminScreen({super.key, required this.sheetId});

  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen> {
  List<Map<String, String>> data = [];
  bool loading = true;
  String selectedExchange = '';

  final exchanges = [
    'Mangalawar MSAG 51IP', 'Qandil MSAG', 'Madyan MSAG', 'Fatepur MSAG',
    'Mangalawar MSAG 50IP', 'Damana MSAG', 'Baidara MSAG 18 IP', 'Shalpin MSAG',
    'Shakardara MSAG', 'Baidara MSAG 19 IP', 'Bishband Exchange', 'Charbagh',
    'Khwazakhela 46IP', 'Barshawr Exchange', 'Matta 42 IP', 'Gwaleral Exchange',
    'Miankally Exchange', 'Chuprial Exchange', 'Duruskhela exchange',
    'Khwazakhela 174IP', 'Barabandai Exchange', 'Fatepur Exchange',
    'Miandam Exchange', 'Banjot Exchange', 'Matta 54IP', 'Sattal Exchange',
    'Karora Exchange', 'Alpuri Exchange', 'Puran Exchange',
    'Damorai Exchange', 'Chakisar Exchange'
  ];

  @override
  void initState() {
    super.initState();
    loadData();
  }

  Future<void> loadData() async {
    setState(() => loading = true);
    try {
      data = await SheetService.fetchData(widget.sheetId);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
    setState(() => loading = false);
  }

  @override
  Widget build(BuildContext context) {
    final filtered = selectedExchange.isEmpty
        ? data
        : data.where((r) => r['Exchange'] == selectedExchange).toList();

    return Scaffold(
      appBar: AppBar(title: const Text('Admin Panel')),
      body: RefreshIndicator(
        onRefresh: loadData,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              DropdownButtonFormField<String>(
                value: selectedExchange.isEmpty ? null : selectedExchange,
                hint: const Text('Select Exchange'),
                items: exchanges.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                onChanged: (v) => setState(() => selectedExchange = v ?? ''),
                decoration: InputDecoration(border: OutlineInputBorder(borderRadius: BorderRadius.circular(10))),
              ),
              const SizedBox(height: 12),
              Card(
                color: Colors.indigo,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Text('${filtered.length}', style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white)),
                      const Text('Records', style: TextStyle(color: Colors.white70)),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: loading
                    ? const Center(child: CircularProgressIndicator())
                    : filtered.isEmpty
                        ? const Center(child: Text('No records'))
                        : ListView.builder(
                            itemCount: filtered.length,
                            itemBuilder: (_, i) {
                              final r = filtered[i];
                              return Card(
                                child: ListTile(
                                  title: Text(r['MDN'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold)),
                                  subtitle: Text('${r['Exchange']} | Tag-In: ${r['Tag-In']} | Tag-Out: ${r['Tag-Out']}'),
                                  trailing: Text('DC: ${r['DC-Number'] ?? '-'}', style: const TextStyle(color: Colors.grey)),
                                ),
                              );
                            },
                          ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ============ STAFF SCREEN ============
class StaffScreen extends StatefulWidget {
  final String sheetId;
  const StaffScreen({super.key, required this.sheetId});

  @override
  State<StaffScreen> createState() => _StaffScreenState();
}

class _StaffScreenState extends State<StaffScreen> {
  List<Map<String, String>> data = [];
  List<Map<String, String>> filtered = [];
  bool loading = true;
  String selectedExchange = '';
  String searchQuery = '';
  Map<String, String>? selectedMdn;

  @override
  void initState() {
    super.initState();
    loadData();
  }

  Future<void> loadData() async {
    setState(() => loading = true);
    try {
      data = await SheetService.fetchData(widget.sheetId);
      applyFilter();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
    setState(() => loading = false);
  }

  void applyFilter() {
    filtered = data;
    if (selectedExchange.isNotEmpty) {
      filtered = filtered.where((r) => r['Exchange'] == selectedExchange).toList();
    }
    if (searchQuery.isNotEmpty) {
      filtered = filtered.where((r) => (r['MDN'] ?? '').contains(searchQuery)).toList();
    }
  }

  @override
  Widget build(BuildContext context) {
    final exchanges = data.map((r) => r['Exchange']).whereType<String>().toSet().toList()..sort();

    return Scaffold(
      appBar: AppBar(title: const Text('Staff Panel')),
      body: selectedMdn != null
          ? _buildEditView()
          : _buildListView(exchanges),
    );
  }

  Widget _buildListView(List<String> exchanges) {
    return RefreshIndicator(
      onRefresh: loadData,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            DropdownButtonFormField<String>(
              value: selectedExchange.isEmpty ? null : selectedExchange,
              hint: const Text('Select Exchange'),
              items: exchanges.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
              onChanged: (v) {
                setState(() {
                  selectedExchange = v ?? '';
                  applyFilter();
                });
              },
              decoration: InputDecoration(border: OutlineInputBorder(borderRadius: BorderRadius.circular(10))),
            ),
            const SizedBox(height: 12),
            TextField(
              decoration: InputDecoration(
                hintText: 'Search MDN...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onChanged: (v) {
                setState(() {
                  searchQuery = v;
                  applyFilter();
                });
              },
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: loadData,
              icon: const Icon(Icons.refresh),
              label: const Text('Load Data'),
              style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14)),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: loading
                  ? const Center(child: CircularProgressIndicator())
                  : filtered.isEmpty
                      ? const Center(child: Text('No matching MDNs'))
                      : ListView.builder(
                          itemCount: filtered.length,
                          itemBuilder: (_, i) {
                            final r = filtered[i];
                            final hasDc = (r['DC-Number'] ?? '').isNotEmpty;
                            return Card(
                              child: ListTile(
                                leading: CircleAvatar(
                                  backgroundColor: hasDc ? Colors.green : Colors.orange,
                                  child: Icon(hasDc ? Icons.check : Icons.pending, color: Colors.white),
                                ),
                                title: Text(r['MDN'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold)),
                                subtitle: Text('Tag-In: ${r['Tag-In']} | Tag-Out: ${r['Tag-Out']}'),
                                trailing: const Icon(Icons.arrow_forward_ios),
                                onTap: () => setState(() => selectedMdn = r),
                              ),
                            );
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEditView() {
    final r = selectedMdn!;
    final dcNumber = TextEditingController(text: r['DC-Number'] ?? '');
    final dcPair = TextEditingController(text: r['DC-Pair'] ?? '');
    final dpNumber = TextEditingController(text: r['DP-Number'] ?? '');
    final dpPair = TextEditingController(text: r['DP-Pair'] ?? '');

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Card(
            color: Colors.indigo.shade50,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _infoRow('Exchange', r['Exchange'] ?? ''),
                  _infoRow('MDN', r['MDN'] ?? ''),
                  _infoRow('Tag-In', r['Tag-In'] ?? ''),
                  _infoRow('Tag-Out', r['Tag-Out'] ?? ''),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          const Text('Enter DC/DP Data', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          TextField(controller: dcNumber, decoration: const InputDecoration(labelText: 'DC Number', border: OutlineInputBorder())),
          const SizedBox(height: 8),
          TextField(controller: dcPair, decoration: const InputDecoration(labelText: 'DC Pair', border: OutlineInputBorder())),
          const SizedBox(height: 8),
          TextField(controller: dpNumber, decoration: const InputDecoration(labelText: 'DP Number', border: OutlineInputBorder())),
          const SizedBox(height: 8),
          TextField(controller: dpPair, decoration: const InputDecoration(labelText: 'DP Pair', border: OutlineInputBorder())),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: () {
              setState(() {
                r['DC-Number'] = dcNumber.text;
                r['DC-Pair'] = dcPair.text;
                r['DP-Number'] = dpNumber.text;
                r['DP-Pair'] = dpPair.text;
                selectedMdn = null;
              });
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Saved! Update Google Sheet with new values.')),
              );
            },
            icon: const Icon(Icons.save),
            label: const Text('Save'),
            style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
          ),
          const SizedBox(height: 8),
          OutlinedButton(
            onPressed: () => setState(() => selectedMdn = null),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.indigo, fontWeight: FontWeight.w600)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        ],
      ),
    );
  }
}
