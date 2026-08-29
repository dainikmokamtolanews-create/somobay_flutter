import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'database.dart';

const purple = Color(0xFF7257C7);
const purpleDark = Color(0xFF35245D);
const purpleSoft = Color(0xFFF0EBFC);
const green = Color(0xFF2F9E72);
const background = Color(0xFFF8F6FC);
const border = Color(0xFFE5DDF2);

String money(num value) =>
    NumberFormat.currency(locale: 'bn_BD', symbol: '৳ ', decimalDigits: 0).format(value);
String today() => DateFormat('yyyy-MM-dd').format(DateTime.now());

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AppDatabase.instance.database;
  runApp(const SomobayApp());
}

class SomobayApp extends StatelessWidget {
  const SomobayApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'সমবায় সমিতি',
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: background,
        colorScheme: ColorScheme.fromSeed(seedColor: purple, brightness: Brightness.light),
        fontFamily: 'NotoSansBengali',
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: border),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: border),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: purple, width: 1.5),
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
        ),
        cardTheme: CardThemeData(
          color: Colors.white,
          elevation: 0,
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        ),
      ),
      home: const LoginPage(),
    );
  }
}

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  String? selectedRole;
  final username = TextEditingController();
  final password = TextEditingController();
  bool loading = false;

  Future<void> signIn() async {
    if (selectedRole == null) {
      _message('একটি লগইন ধরন নির্বাচন করুন');
      return;
    }
    setState(() => loading = true);
    final user = await AppDatabase.instance.login(username.text, password.text, selectedRole!);
    if (!mounted) return;
    setState(() => loading = false);
    if (user == null) {
      _message('ইউজারনেম অথবা পাসওয়ার্ড সঠিক নয়');
      return;
    }
    Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => Dashboard(user: user)));
  }

  void _message(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  void dispose() {
    username.dispose();
    password.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(22),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: Column(
                children: [
                  Container(
                    width: 68,
                    height: 68,
                    decoration: BoxDecoration(
                      color: purple,
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: const Icon(Icons.layers_rounded, color: Colors.white, size: 34),
                  ),
                  const SizedBox(height: 16),
                  const Text('সমবায় সমিতি',
                      style: TextStyle(fontSize: 30, fontWeight: FontWeight.w800, color: purpleDark)),
                  const SizedBox(height: 7),
                  const Text('আপনার সমিতির প্রতিদিনের হিসাব, একসাথে',
                      style: TextStyle(color: Colors.black54)),
                  const SizedBox(height: 34),
                  Row(
                    children: [
                      Expanded(
                        child: _RoleCard(
                          title: 'এডমিন লগইন',
                          subtitle: 'সম্পূর্ণ ব্যবস্থাপনা',
                          icon: Icons.shield_outlined,
                          color: purple,
                          selected: selectedRole == 'admin',
                          onTap: () => setState(() => selectedRole = 'admin'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _RoleCard(
                          title: 'মাঠকর্মী লগইন',
                          subtitle: 'আদায় ও রিপোর্ট',
                          icon: Icons.person_outline,
                          color: green,
                          selected: selectedRole == 'field_worker',
                          onTap: () => setState(() => selectedRole = 'field_worker'),
                        ),
                      ),
                    ],
                  ),
                  if (selectedRole != null) ...[
                    const SizedBox(height: 18),
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(18),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Text(selectedRole == 'admin' ? 'এডমিন অ্যাকাউন্ট' : 'মাঠকর্মী অ্যাকাউন্ট',
                                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 16),
                            TextField(controller: username, decoration: const InputDecoration(labelText: 'ইউজারনেম')),
                            const SizedBox(height: 12),
                            TextField(controller: password, obscureText: true, decoration: const InputDecoration(labelText: 'পাসওয়ার্ড')),
                            const SizedBox(height: 14),
                            FilledButton.icon(
                              onPressed: loading ? null : signIn,
                              icon: const Icon(Icons.arrow_forward_rounded),
                              label: Text(loading ? 'যাচাই হচ্ছে...' : 'লগইন করুন'),
                              style: FilledButton.styleFrom(backgroundColor: selectedRole == 'admin' ? purple : green),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 22),
                  const Text('প্রথম লগইন: admin / 123456   অথবা   field / 1234',
                      style: TextStyle(fontSize: 12, color: Colors.black45)),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _RoleCard extends StatelessWidget {
  const _RoleCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.selected,
    required this.onTap,
  });
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.all(16),
        constraints: const BoxConstraints(minHeight: 148),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: selected ? color : Colors.transparent, width: 2),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(backgroundColor: color, radius: 25, child: Icon(icon, color: Colors.white, size: 27)),
            const Spacer(),
            Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text(subtitle, style: const TextStyle(fontSize: 12, color: Colors.black45)),
          ],
        ),
      ),
    );
  }
}

class Dashboard extends StatelessWidget {
  const Dashboard({super.key, required this.user});
  final Map<String, dynamic> user;

  bool get isAdmin => user['role'] == 'admin';

  void open(BuildContext context, Widget page) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => page));
  }

  @override
  Widget build(BuildContext context) {
    final adminItems = <_MenuItem>[
      _MenuItem('গ্রুপ ব্যবস্থাপনা', Icons.groups_rounded, () => open(context, const GroupsPage())),
      _MenuItem('কর্মচারীগণের তথ্য', Icons.badge_outlined, () => open(context, const EmployeesPage())),
      _MenuItem('নতুন সদস্য ভর্তি', Icons.person_add_alt_1, () => open(context, const MembersPage())),
      _MenuItem('ঋণ বিতরণ', Icons.credit_card_rounded, () => open(context, const LoansPage())),
      _MenuItem('মুনাফা / লাভ', Icons.trending_up_rounded, () => open(context, const ProfitPage())),
      _MenuItem('ব্যাংক লেনদেন', Icons.account_balance_outlined, () => open(context, const BankPage())),
      _MenuItem('এক নজরে', Icons.pie_chart_outline_rounded, () => open(context, const OverviewPage())),
      _MenuItem('দৈনিক আদায় রিপোর্ট', Icons.description_outlined, () => open(context, const DailyReportPage())),
      _MenuItem('সেটিংস', Icons.settings_outlined, () => open(context, const SettingsPage())),
      _MenuItem('লগআউট', Icons.logout_rounded, () => _logout(context)),
    ];
    final workerItems = <_MenuItem>[
      _MenuItem('আদায়', Icons.download_rounded, () => open(context, CollectionPage(worker: user))),
      _MenuItem('পোস্টিং দিন', Icons.upload_rounded, () => open(context, PostingPage(worker: user))),
      _MenuItem('গ্রুপের রিপোর্ট', Icons.bar_chart_rounded, () => open(context, GroupReportPage(worker: user))),
      _MenuItem('লগআউট', Icons.logout_rounded, () => _logout(context)),
    ];
    final items = isAdmin ? adminItems : workerItems;
    return Scaffold(
      appBar: AppBar(
        backgroundColor: background,
        title: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(isAdmin ? 'এডমিন ড্যাশবোর্ড' : 'মাঠকর্মী ড্যাশবোর্ড',
              style: const TextStyle(fontWeight: FontWeight.w800, color: purpleDark)),
          Text('সমবায় সমিতি', style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
        ]),
        actions: [
          IconButton(onPressed: () => _logout(context), icon: const Icon(Icons.logout, color: Colors.redAccent)),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(18, 8, 18, 28),
          children: [
            Card(
              color: purple,
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Row(
                  children: [
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      const Text('স্বাগতম', style: TextStyle(color: Colors.white70)),
                      const SizedBox(height: 4),
                      Text(user['name'] as String,
                          style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4),
                      Text(today(), style: const TextStyle(color: Colors.white70, fontSize: 12)),
                    ])),
                    CircleAvatar(
                      radius: 25,
                      backgroundColor: Colors.white24,
                      child: Text((user['name'] as String).characters.first,
                          style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 10),
            const Text('দ্রুত মেনু', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: purpleDark)),
            const SizedBox(height: 12),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: items.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2, crossAxisSpacing: 11, mainAxisSpacing: 11, childAspectRatio: 1.15,
              ),
              itemBuilder: (_, index) => _MenuCard(item: items[index], danger: items[index].title == 'লগআউট'),
            ),
          ],
        ),
      ),
    );
  }
}

class _MenuItem {
  const _MenuItem(this.title, this.icon, this.onTap);
  final String title;
  final IconData icon;
  final VoidCallback onTap;
}

class _MenuCard extends StatelessWidget {
  const _MenuCard({required this.item, this.danger = false});
  final _MenuItem item;
  final bool danger;

  @override
  Widget build(BuildContext context) {
    final color = danger ? Colors.redAccent : purple;
    return InkWell(
      onTap: item.onTap,
      borderRadius: BorderRadius.circular(18),
      child: Card(
        color: danger ? const Color(0xFFFFF7F8) : Colors.white,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            CircleAvatar(radius: 20, backgroundColor: color.withOpacity(.12), child: Icon(item.icon, color: color)),
            const Spacer(),
            Text(item.title, style: TextStyle(fontWeight: FontWeight.w700, color: danger ? color : purpleDark)),
            const SizedBox(height: 4),
            Icon(Icons.arrow_forward_rounded, size: 16, color: Colors.grey.shade400),
          ]),
        ),
      ),
    );
  }
}

void _logout(BuildContext context) {
  Navigator.of(context).pushAndRemoveUntil(MaterialPageRoute(builder: (_) => const LoginPage()), (_) => false);
}

class AppPage extends StatelessWidget {
  const AppPage({super.key, required this.title, required this.child});
  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, color: purpleDark))),
      body: child,
    );
  }
}

class GroupsPage extends StatefulWidget {
  const GroupsPage({super.key});
  @override
  State<GroupsPage> createState() => _GroupsPageState();
}

class _GroupsPageState extends State<GroupsPage> {
  Future<List<Map<String, dynamic>>> load() => AppDatabase.instance.query('groups', orderBy: 'name');

  Future<void> edit([Map<String, dynamic>? item]) async {
    final name = TextEditingController(text: item?['name'] as String? ?? '');
    final code = TextEditingController(text: item?['code'] as String? ?? '');
    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(item == null ? 'নতুন গ্রুপ' : 'গ্রুপ সম্পাদনা'),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          TextField(controller: name, decoration: const InputDecoration(labelText: 'গ্রুপ নাম')),
          const SizedBox(height: 12),
          TextField(controller: code, decoration: const InputDecoration(labelText: 'গ্রুপ কোড')),
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('বাতিল')),
          FilledButton(onPressed: () async {
            if (name.text.trim().isEmpty || code.text.trim().isEmpty) return;
            final values = {'name': name.text.trim(), 'code': code.text.trim()};
            if (item == null) {
              await AppDatabase.instance.insert('groups', values);
            } else {
              await AppDatabase.instance.update('groups', values, item['id'] as int);
            }
            if (mounted) { Navigator.pop(context); setState(() {}); }
          }, child: const Text('সংরক্ষণ')),
        ],
      ),
    );
    name.dispose();
    code.dispose();
  }

  @override
  Widget build(BuildContext context) => AppPage(
    title: 'গ্রুপ ব্যবস্থাপনা',
    child: FutureBuilder<List<Map<String, dynamic>>>(
      future: load(),
      builder: (_, snap) => ListView(
        padding: const EdgeInsets.all(18),
        children: [
          _TopAction(title: 'গ্রুপ তালিকা', count: snap.data?.length ?? 0, onAdd: () => edit()),
          if (!snap.hasData) const Center(child: CircularProgressIndicator()),
          if (snap.hasData && snap.data!.isEmpty) const _EmptyState(text: 'এখনও কোনো গ্রুপ যোগ করা হয়নি'),
          ...?snap.data?.map((g) => Card(child: ListTile(
            leading: const CircleAvatar(backgroundColor: purpleSoft, child: Icon(Icons.groups, color: purple)),
            title: Text(g['name'] as String, style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text('কোড: ${g['code']}'),
            trailing: Wrap(spacing: 4, children: [
              IconButton(onPressed: () => edit(g), icon: const Icon(Icons.edit_outlined, color: purple)),
              IconButton(onPressed: () async { await AppDatabase.instance.delete('groups', g['id'] as int); setState(() {}); },
                  icon: const Icon(Icons.delete_outline, color: Colors.redAccent)),
            ]),
          ))),
        ],
      ),
    ),
  );
}

class EmployeesPage extends StatefulWidget {
  const EmployeesPage({super.key});
  @override
  State<EmployeesPage> createState() => _EmployeesPageState();
}

class _EmployeesPageState extends State<EmployeesPage> {
  Future<List<Map<String, dynamic>>> load() =>
      AppDatabase.instance.query('users', where: 'role = ?', args: ['field_worker'], orderBy: 'name');

  Future<List<Map<String, dynamic>>> groups() => AppDatabase.instance.query('groups', orderBy: 'name');

  Future<void> edit([Map<String, dynamic>? item]) async {
    final name = TextEditingController(text: item?['name'] as String? ?? '');
    final mobile = TextEditingController(text: item?['mobile'] as String? ?? '');
    final address = TextEditingController(text: item?['address'] as String? ?? '');
    final username = TextEditingController(text: item?['username'] as String? ?? '');
    final password = TextEditingController(text: item?['password'] as String? ?? '');
    final availableGroups = await groups();
    int? groupId = item?['group_id'] as int?;
    if (!mounted) return;
    await showDialog(
      context: context,
      builder: (_) => StatefulBuilder(builder: (context, setDialog) => AlertDialog(
        title: Text(item == null ? 'নতুন কর্মচারী' : 'কর্মচারী সম্পাদনা'),
        content: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, children: [
          TextField(controller: name, decoration: const InputDecoration(labelText: 'নাম')),
          const SizedBox(height: 10),
          TextField(controller: mobile, decoration: const InputDecoration(labelText: 'মোবাইল')),
          const SizedBox(height: 10),
          TextField(controller: address, decoration: const InputDecoration(labelText: 'ঠিকানা')),
          const SizedBox(height: 10),
          TextField(controller: username, decoration: const InputDecoration(labelText: 'ইউজারনেম')),
          const SizedBox(height: 10),
          TextField(controller: password, obscureText: true, decoration: const InputDecoration(labelText: 'পাসওয়ার্ড')),
          const SizedBox(height: 10),
          DropdownButtonFormField<int>(
            value: availableGroups.any((g) => g['id'] == groupId) ? groupId : null,
            decoration: const InputDecoration(labelText: 'গ্রুপ অ্যাসাইন'),
            items: availableGroups.map((g) => DropdownMenuItem<int>(value: g['id'] as int, child: Text(g['name'] as String))).toList(),
            onChanged: (v) => setDialog(() => groupId = v),
          ),
        ])),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('বাতিল')),
          FilledButton(onPressed: () async {
            if (name.text.trim().isEmpty || username.text.trim().isEmpty || password.text.isEmpty) return;
            final values = {'name': name.text.trim(), 'mobile': mobile.text.trim(), 'address': address.text.trim(),
              'username': username.text.trim(), 'password': password.text, 'role': 'field_worker', 'group_id': groupId};
            if (item == null) await AppDatabase.instance.insert('users', values);
            else await AppDatabase.instance.update('users', values, item['id'] as int);
            if (mounted) { Navigator.pop(context); setState(() {}); }
          }, child: const Text('সংরক্ষণ')),
        ],
      )),
    );
    for (final c in [name, mobile, address, username, password]) { c.dispose(); }
  }

  @override
  Widget build(BuildContext context) => AppPage(
    title: 'কর্মচারীগণের তথ্য',
    child: FutureBuilder<List<Map<String, dynamic>>>(
      future: load(),
      builder: (_, snap) => ListView(padding: const EdgeInsets.all(18), children: [
        _TopAction(title: 'মাঠকর্মী তালিকা', count: snap.data?.length ?? 0, onAdd: () => edit()),
        ...?snap.data?.map((u) => Card(child: ListTile(
          leading: const CircleAvatar(backgroundColor: Color(0xFFE4F6EE), child: Icon(Icons.badge_outlined, color: green)),
          title: Text(u['name'] as String, style: const TextStyle(fontWeight: FontWeight.bold)),
          subtitle: Text('@${u['username']} · ${u['mobile'] ?? ''}'),
          trailing: IconButton(onPressed: () => edit(u), icon: const Icon(Icons.edit_outlined, color: purple)),
        ))),
      ]),
    ),
  );
}

class MembersPage extends StatefulWidget {
  const MembersPage({super.key});
  @override
  State<MembersPage> createState() => _MembersPageState();
}

class _MembersPageState extends State<MembersPage> {
  String search = '';
  Future<List<Map<String, dynamic>>> load() => AppDatabase.instance.database.then((db) => db.rawQuery('''
    SELECT m.*, g.name AS group_name FROM members m LEFT JOIN groups g ON g.id=m.group_id
    WHERE m.name LIKE ? OR m.member_no LIKE ? ORDER BY m.name
  ''', ['%$search%', '%$search%']));

  Future<void> edit([Map<String, dynamic>? item]) async {
    final fields = <String, TextEditingController>{
      'member_no': TextEditingController(text: item?['member_no'] as String? ?? ''),
      'name': TextEditingController(text: item?['name'] as String? ?? ''),
      'father': TextEditingController(text: item?['father'] as String? ?? ''),
      'mother': TextEditingController(text: item?['mother'] as String? ?? ''),
      'spouse': TextEditingController(text: item?['spouse'] as String? ?? ''),
      'dob': TextEditingController(text: item?['dob'] as String? ?? ''),
      'nid': TextEditingController(text: item?['nid'] as String? ?? ''),
      'mobile': TextEditingController(text: item?['mobile'] as String? ?? ''),
      'address': TextEditingController(text: item?['address'] as String? ?? ''),
      'join_date': TextEditingController(text: item?['join_date'] as String? ?? today()),
      'comment': TextEditingController(text: item?['comment'] as String? ?? ''),
    };
    final gs = await AppDatabase.instance.query('groups', orderBy: 'name');
    final workers = await AppDatabase.instance.query('users', where: 'role = ?', args: ['field_worker'], orderBy: 'name');
    int? groupId = item?['group_id'] as int?;
    int? workerId = item?['assigned_field_worker_id'] as int?;
    if (!mounted) return;
    await showDialog(
      context: context,
      builder: (_) => StatefulBuilder(builder: (context, setDialog) => AlertDialog(
        title: Text(item == null ? 'নতুন সদস্য ভর্তি' : 'সদস্য সম্পাদনা'),
        content: SizedBox(width: 500, child: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, children: [
          for (final f in [
            ['member_no', 'সদস্য নং'], ['name', 'নাম'], ['father', 'পিতার নাম'], ['mother', 'মাতার নাম'],
            ['spouse', 'স্বামী/স্ত্রী'], ['dob', 'জন্ম তারিখ'], ['nid', 'NID'], ['mobile', 'মোবাইল'],
          ]) ...[TextField(controller: fields[f[0]], decoration: InputDecoration(labelText: f[1])), const SizedBox(height: 10)],
          TextField(controller: fields['address'], maxLines: 2, decoration: const InputDecoration(labelText: 'ঠিকানা')),
          const SizedBox(height: 10),
          DropdownButtonFormField<int>(
            value: gs.any((g) => g['id'] == groupId) ? groupId : null,
            decoration: const InputDecoration(labelText: 'গ্রুপ নাম'),
            items: gs.map((g) => DropdownMenuItem<int>(value: g['id'] as int, child: Text(g['name'] as String))).toList(),
            onChanged: (v) => setDialog(() => groupId = v),
          ),
          const SizedBox(height: 10),
          DropdownButtonFormField<int>(
            value: workers.any((w) => w['id'] == workerId) ? workerId : null,
            decoration: const InputDecoration(labelText: 'অ্যাসাইন মাঠকর্মী'),
            items: workers.map((w) => DropdownMenuItem<int>(value: w['id'] as int, child: Text(w['name'] as String))).toList(),
            onChanged: (v) => setDialog(() => workerId = v),
          ),
          const SizedBox(height: 10),
          TextField(controller: fields['join_date'], decoration: const InputDecoration(labelText: 'ভর্তি তারিখ')),
          const SizedBox(height: 10),
          TextField(controller: fields['comment'], maxLines: 2, decoration: const InputDecoration(labelText: 'মন্তব্য')),
        ]))),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('বাতিল')),
          FilledButton(onPressed: () async {
            if (fields['member_no']!.text.trim().isEmpty || fields['name']!.text.trim().isEmpty) return;
            final matchingGroups = gs.where((g) => g['id'] == groupId).toList();
            final group = matchingGroups.isEmpty ? null : matchingGroups.first;
            final values = <String, Object?>{
              for (final e in fields.entries) e.key: e.value.text.trim(),
              'group_id': groupId, 'group_code': group?['code'] ?? '', 'assigned_field_worker_id': workerId,
            };
            if (item == null) await AppDatabase.instance.insert('members', values);
            else await AppDatabase.instance.update('members', values, item['id'] as int);
            if (mounted) { Navigator.pop(context); setState(() {}); }
          }, child: const Text('সংরক্ষণ')),
        ],
      )),
    );
    for (final c in fields.values) { c.dispose(); }
  }

  @override
  Widget build(BuildContext context) => AppPage(
    title: 'নতুন সদস্য ভর্তি',
    child: FutureBuilder<List<Map<String, dynamic>>>(
      future: load(),
      builder: (_, snap) => ListView(padding: const EdgeInsets.all(18), children: [
        Row(children: [
          Expanded(child: TextField(onChanged: (v) => setState(() => search = v), decoration: const InputDecoration(
            prefixIcon: Icon(Icons.search), hintText: 'নাম বা সদস্য নং দিয়ে খুঁজুন'))),
          const SizedBox(width: 10),
          FloatingActionButton.small(heroTag: 'member-add', onPressed: () => edit(), backgroundColor: purple,
              child: const Icon(Icons.add, color: Colors.white)),
        ]),
        const SizedBox(height: 14),
        ...?snap.data?.map((m) => Card(child: ListTile(
          leading: const CircleAvatar(backgroundColor: purpleSoft, child: Icon(Icons.person_outline, color: purple)),
          title: Text(m['name'] as String, style: const TextStyle(fontWeight: FontWeight.bold)),
          subtitle: Text('সদস্য নং ${m['member_no']} · ${m['group_name'] ?? 'গ্রুপ নেই'}'),
          trailing: IconButton(onPressed: () => edit(m), icon: const Icon(Icons.edit_outlined, color: purple)),
        ))),
      ]),
    ),
  );
}

class LoansPage extends StatefulWidget {
  const LoansPage({super.key});
  @override
  State<LoansPage> createState() => _LoansPageState();
}

class _LoansPageState extends State<LoansPage> {
  int? memberId;
  String type = 'দিন';
  final amount = TextEditingController();
  final interest = TextEditingController();
  Future<List<Map<String, dynamic>>> members() => AppDatabase.instance.query('members', orderBy: 'name');

  Future<void> save() async {
    if (memberId == null || amount.text.trim().isEmpty) return;
    await AppDatabase.instance.insert('loans', {
      'member_id': memberId, 'amount': double.tryParse(amount.text) ?? 0,
      'interest': double.tryParse(interest.text) ?? 0, 'collection_type': type, 'start_date': today(),
    });
    amount.clear(); interest.clear();
    if (mounted) { setState(() {}); ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('ঋণ বিতরণ সংরক্ষণ হয়েছে'))); }
  }

  @override
  Widget build(BuildContext context) => AppPage(title: 'ঋণ বিতরণ', child: FutureBuilder<List<Map<String, dynamic>>>(
    future: members(),
    builder: (_, snap) => ListView(padding: const EdgeInsets.all(18), children: [
      Card(child: Padding(padding: const EdgeInsets.all(17), child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        const Text('নতুন ঋণ বিতরণ', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 14),
        DropdownButtonFormField<int>(
          value: snap.data?.any((m) => m['id'] == memberId) == true ? memberId : null,
          decoration: const InputDecoration(labelText: 'সদস্য নির্বাচন'),
          items: snap.data?.map((m) => DropdownMenuItem<int>(value: m['id'] as int, child: Text('${m['name']} · ${m['member_no']}'))).toList(),
          onChanged: (v) => setState(() => memberId = v),
        ),
        const SizedBox(height: 12),
        TextField(controller: amount, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'ঋণের পরিমাণ')),
        const SizedBox(height: 12),
        TextField(controller: interest, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'মুনাফা / সুদ (%)')),
        const SizedBox(height: 12),
        _ChoiceRow(label: 'আদায়ের ধরন', value: type, options: const ['দিন', 'সপ্তাহ', 'মাস'], onChanged: (v) => setState(() => type = v)),
        const SizedBox(height: 12),
        Text('শুরুর তারিখ: $today()', style: const TextStyle(color: Colors.black54)),
        const SizedBox(height: 12),
        FilledButton.icon(onPressed: save, icon: const Icon(Icons.save_outlined), label: const Text('ঋণ সংরক্ষণ করুন')),
      ]))),
      const SizedBox(height: 6),
      const Text('ঋণের তালিকা', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
      FutureBuilder<List<Map<String, dynamic>>>(
        future: AppDatabase.instance.database.then((db) => db.rawQuery('''
          SELECT l.*, m.name AS member_name, m.member_no FROM loans l LEFT JOIN members m ON m.id=l.member_id ORDER BY l.id DESC
        ''')),
        builder: (_, loans) => Column(children: [...?loans.data?.map((l) => Card(child: ListTile(
          leading: const Icon(Icons.credit_card, color: purple),
          title: Text(l['member_name'] as String? ?? 'সদস্য'),
          subtitle: Text('${money(l['amount'] as num)} · ${l['collection_type']}'),
          trailing: Text('${l['interest']}%', style: const TextStyle(color: green, fontWeight: FontWeight.bold)),
        )))])
      ),
    ]),
  ));
}

class CollectionPage extends StatefulWidget {
  const CollectionPage({super.key, required this.worker});
  final Map<String, dynamic> worker;
  @override
  State<CollectionPage> createState() => _CollectionPageState();
}

class _CollectionPageState extends State<CollectionPage> {
  int? memberId;
  final amount = TextEditingController();
  Future<List<Map<String, dynamic>>> load() => AppDatabase.instance.assignedMembers(widget.worker['id'] as int);

  Future<void> save() async {
    if (memberId == null || amount.text.trim().isEmpty) return;
    await AppDatabase.instance.insert('collections', {
      'member_id': memberId, 'amount': double.tryParse(amount.text) ?? 0,
      'date': today(), 'installment_no': 1, 'status': 'draft',
    });
    amount.clear();
    if (mounted) { setState(() {}); ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('ড্রাফট হিসেবে সংরক্ষণ হয়েছে'))); }
  }

  @override
  Widget build(BuildContext context) => AppPage(title: 'আদায়', child: FutureBuilder<List<Map<String, dynamic>>>(
    future: load(),
    builder: (_, snap) {
      final members = snap.data ?? [];
      return ListView(padding: const EdgeInsets.all(18), children: [
        Card(child: Padding(padding: const EdgeInsets.all(17), child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          const Text('আজকের আদায়', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          Text('আপনার অ্যাসাইন করা ${members.length} জন সদস্য', style: const TextStyle(color: Colors.black54)),
          const SizedBox(height: 14),
          DropdownButtonFormField<int>(
            value: members.any((m) => m['id'] == memberId) ? memberId : null,
            decoration: const InputDecoration(labelText: 'সদস্য নির্বাচন'),
            items: members.map((m) => DropdownMenuItem<int>(value: m['id'] as int, child: Text('${m['name']} · ${m['member_no']}'))).toList(),
            onChanged: (v) => setState(() => memberId = v),
          ),
          const SizedBox(height: 12),
          FutureBuilder<List<Map<String, dynamic>>>(
            future: AppDatabase.instance.database.then((db) => db.rawQuery(
              "SELECT COALESCE(SUM(amount),0) AS total FROM loans WHERE member_id = ?", [memberId ?? -1])),
            builder: (_, due) => Text('এই সদস্যের বকেয়া: ${money((due.data?.first['total'] as num?) ?? 0)}',
                style: const TextStyle(color: purple, fontWeight: FontWeight.bold)),
          ),
          const SizedBox(height: 12),
          TextField(controller: amount, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'আদায়ের টাকা')),
          const SizedBox(height: 12),
          FilledButton.icon(style: FilledButton.styleFrom(backgroundColor: green), onPressed: save,
              icon: const Icon(Icons.download_rounded), label: const Text('আদায় ড্রাফট করুন')),
        ]))),
      ];
    },
  ));
}

class PostingPage extends StatefulWidget {
  const PostingPage({super.key, required this.worker});
  final Map<String, dynamic> worker;
  @override
  State<PostingPage> createState() => _PostingPageState();
}

class _PostingPageState extends State<PostingPage> {
  Future<List<Map<String, dynamic>>> drafts() => AppDatabase.instance.database.then((db) => db.rawQuery('''
    SELECT c.*, m.name AS member_name, m.member_no FROM collections c
    LEFT JOIN members m ON m.id=c.member_id WHERE c.status='draft' ORDER BY c.date DESC
  '''));
  Future<void> post(int id) async {
    await AppDatabase.instance.update('collections', {'status': 'posted'}, id);
    setState(() {});
  }
  @override
  Widget build(BuildContext context) => AppPage(title: 'পোস্টিং দিন', child: FutureBuilder<List<Map<String, dynamic>>>(
    future: drafts(),
    builder: (_, snap) => ListView(padding: const EdgeInsets.all(18), children: [
      Card(color: purpleSoft, child: const ListTile(leading: Icon(Icons.info_outline, color: purple),
          title: Text('ড্রাফট যাচাই করে পোস্ট করুন'), subtitle: Text('পোস্ট হলে রিপোর্টে যুক্ত হবে।'))),
      if (snap.hasData && snap.data!.isEmpty) const _EmptyState(text: 'কোনো ড্রাফট নেই'),
      ...?snap.data?.map((c) => Card(child: ListTile(
        title: Text(c['member_name'] as String? ?? 'সদস্য', style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text('${c['date']} · ${money(c['amount'] as num)}'),
        trailing: FilledButton(onPressed: () => post(c['id'] as int), child: const Text('পোস্ট')),
      ))),
    ]),
  ));
}

class GroupReportPage extends StatefulWidget {
  const GroupReportPage({super.key, required this.worker});
  final Map<String, dynamic> worker;
  @override
  State<GroupReportPage> createState() => _GroupReportPageState();
}

class _GroupReportPageState extends State<GroupReportPage> {
  String from = '';
  String to = '';
  int? memberId;
  Future<List<Map<String, dynamic>>> report() => AppDatabase.instance.database.then((db) => db.rawQuery('''
    SELECT c.*, m.name AS member_name, m.member_no, m.father FROM collections c
    LEFT JOIN members m ON m.id=c.member_id
    WHERE c.status='posted' AND (m.assigned_field_worker_id=? OR (?=0 AND m.assigned_field_worker_id IS NULL))
    AND (?='' OR c.date>=?) AND (?='' OR c.date<=?) AND (? IS NULL OR c.member_id=?)
    ORDER BY c.date DESC
  ''', [widget.worker['id'], widget.worker['id'], from, from, to, to, memberId, memberId]));

  @override
  Widget build(BuildContext context) => AppPage(title: 'গ্রুপের রিপোর্ট', child: FutureBuilder<List<Map<String, dynamic>>>(
    future: report(),
    builder: (_, snap) {
      final rows = snap.data ?? [];
      return ListView(padding: const EdgeInsets.all(18), children: [
        Card(child: Padding(padding: const EdgeInsets.all(16), child: Column(children: [
          Row(children: [
            Expanded(child: TextField(decoration: const InputDecoration(labelText: 'From Date', hintText: 'YYYY-MM-DD'),
                onChanged: (v) => setState(() => from = v))),
            const SizedBox(width: 10),
            Expanded(child: TextField(decoration: const InputDecoration(labelText: 'To Date', hintText: 'YYYY-MM-DD'),
                onChanged: (v) => setState(() => to = v))),
          ]),
          const SizedBox(height: 12),
          FutureBuilder<List<Map<String, dynamic>>>(
            future: AppDatabase.instance.assignedMembers(widget.worker['id'] as int),
            builder: (_, members) => DropdownButtonFormField<int>(
              value: members.data?.any((m) => m['id'] == memberId) == true ? memberId : null,
              decoration: const InputDecoration(labelText: 'সদস্য নাম / সদস্য নং'),
              items: [const DropdownMenuItem<int>(value: null, child: Text('সব সদস্য')),
                ...?members.data?.map((m) => DropdownMenuItem<int>(value: m['id'] as int, child: Text('${m['name']} · ${m['member_no']}')))],
              onChanged: (v) => setState(() => memberId = v),
            ),
          ),
        ]))),
        Card(child: Column(children: [
          const Padding(padding: EdgeInsets.all(14), child: Row(children: [
            Expanded(child: Text('তারিখ', style: TextStyle(fontWeight: FontWeight.bold))),
            Expanded(child: Text('সদস্য', style: TextStyle(fontWeight: FontWeight.bold))),
            Text('আদায়', style: TextStyle(fontWeight: FontWeight.bold)),
          ])),
          ...rows.map((r) => Padding(padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
            child: Row(children: [
              Expanded(child: Text(r['date'] as String)), Expanded(child: Text('${r['member_no']} ${r['member_name']}')),
              Text(money(r['amount'] as num)),
            ]))),
          if (rows.isEmpty) const _EmptyState(text: 'এই সময়ে কোনো পোস্টেড আদায় নেই'),
        ])),
        Row(children: [
          Expanded(child: _SummaryCard(title: 'মোট আদায়', value: money(rows.fold<num>(0, (s, r) => s + (r['amount'] as num))))),
          const SizedBox(width: 8),
          Expanded(child: _SummaryCard(title: 'মোট সদস্য', value: '${rows.map((r) => r['member_id']).toSet().length}')),
        ]),
        FilledButton.icon(onPressed: () => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('আদায়ের শীট প্রস্তুত হয়েছে'))),
            icon: const Icon(Icons.description_outlined), label: const Text('আদায়ের শীট দেখাবে')),
      ];
    },
  ));
}

class BankPage extends StatefulWidget {
  const BankPage({super.key});
  @override
  State<BankPage> createState() => _BankPageState();
}

class _BankPageState extends State<BankPage> {
  String kind = 'জমা';
  String personType = 'মাঠকর্মী';
  int? personId;
  final amount = TextEditingController();
  Future<List<Map<String, dynamic>>> people() => AppDatabase.instance.query(
    personType == 'মাঠকর্মী' ? 'users' : 'members',
    where: personType == 'মাঠকর্মী' ? 'role = ?' : null,
    args: personType == 'মাঠকর্মী' ? ['field_worker'] : null,
    orderBy: 'name',
  );
  Future<void> save(List<Map<String, dynamic>> list) async {
    if (personId == null || amount.text.trim().isEmpty) return;
    final p = list.firstWhere((x) => x['id'] == personId);
    await AppDatabase.instance.insert('bank_transactions', {
      'kind': kind, 'person_type': personType, 'person_id': personId,
      'person_name': p['name'], 'amount': double.tryParse(amount.text) ?? 0, 'date': today(),
    });
    amount.clear(); setState(() {});
  }
  @override
  Widget build(BuildContext context) => AppPage(title: 'ব্যাংক লেনদেন', child: FutureBuilder<List<Map<String, dynamic>>>(
    future: AppDatabase.instance.database.then((db) => db.rawQuery(
      "SELECT COALESCE(SUM(CASE WHEN kind='জমা' THEN amount ELSE -amount END),0) AS balance FROM bank_transactions")),
    builder: (_, balance) => FutureBuilder<List<Map<String, dynamic>>>(
      future: people(),
      builder: (_, list) => ListView(padding: const EdgeInsets.all(18), children: [
        Card(color: purple, child: Padding(padding: const EdgeInsets.all(18), child: Column(crossAxisAlignment: CrossAxisAlignment.start,
          children: [const Text('নতুন ব্যালেন্স', style: TextStyle(color: Colors.white70)), Text(money((balance.data?.first['balance'] as num?) ?? 0),
              style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold)), const Text('মোট জমা − মোট উত্তোলন',
              style: TextStyle(color: Colors.white70, fontSize: 12))] ))),
        _ChoiceRow(label: 'লেনদেন', value: kind, options: const ['জমা', 'উত্তোলন'], onChanged: (v) => setState(() => kind = v)),
        _ChoiceRow(label: 'ধরণ', value: personType, options: const ['মাঠকর্মী', 'সদস্য'], onChanged: (v) => setState(() { personType = v; personId = null; })),
        DropdownButtonFormField<int>(
          value: list.data?.any((x) => x['id'] == personId) == true ? personId : null,
          decoration: const InputDecoration(labelText: 'নাম'),
          items: list.data?.map((p) => DropdownMenuItem<int>(value: p['id'] as int, child: Text(p['name'] as String))).toList(),
          onChanged: (v) => setState(() => personId = v),
        ),
        const SizedBox(height: 12),
        TextField(controller: amount, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'টাকা')),
        const SizedBox(height: 12),
        Text('তারিখ: ${today()}'),
        const SizedBox(height: 12),
        FilledButton.icon(onPressed: list.hasData ? () => save(list.data!) : null, icon: const Icon(Icons.save_outlined), label: const Text('লেনদেন সংরক্ষণ করুন')),
      ]),
    ),
  ));
}

class OverviewPage extends StatelessWidget {
  const OverviewPage({super.key});
  @override
  Widget build(BuildContext context) => AppPage(title: 'এক নজরে', child: FutureBuilder<Map<String, num>>(
    future: AppDatabase.instance.totals(),
    builder: (_, snap) {
      final t = snap.data ?? {};
      return ListView(padding: const EdgeInsets.all(18), children: [
        Wrap(spacing: 10, runSpacing: 10, children: [
          _SummaryCard(title: 'মোট সদস্য', value: '${t['members'] ?? 0}'),
          _SummaryCard(title: 'মোট ঋণ', value: money(t['loans'] ?? 0)),
          _SummaryCard(title: 'মোট আদায়', value: money(t['collection'] ?? 0)),
          _SummaryCard(title: 'ব্যাংক ব্যালেন্স', value: money(t['balance'] ?? 0)),
        ]),
      ];
    },
  ));
}

class ProfitPage extends StatelessWidget {
  const ProfitPage({super.key});
  @override
  Widget build(BuildContext context) => AppPage(title: 'মুনাফা / লাভ', child: FutureBuilder<Map<String, num>>(
    future: AppDatabase.instance.database.then((db) async {
      final loans = (await db.rawQuery("SELECT COALESCE(SUM(amount),0) AS x FROM loans")).first['x'] as num;
      final profit = (await db.rawQuery("SELECT COALESCE(SUM(amount * interest / 100),0) AS x FROM loans")).first['x'] as num;
      final collection = (await db.rawQuery("SELECT COALESCE(SUM(amount),0) AS x FROM collections WHERE status='posted'")).first['x'] as num;
      return {'loans': loans, 'profit': profit, 'collection': collection};
    }),
    builder: (_, snap) {
      final d = snap.data ?? {};
      return ListView(padding: const EdgeInsets.all(18), children: [
        Card(color: purple, child: Padding(padding: const EdgeInsets.all(18), child: Column(crossAxisAlignment: CrossAxisAlignment.start,
          children: [const Text('মোট প্রত্যাশিত মুনাফা', style: TextStyle(color: Colors.white70)), Text(money(d['profit'] ?? 0),
              style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold))] ))),
        Row(children: [Expanded(child: _SummaryCard(title: 'মোট ঋণ', value: money(d['loans'] ?? 0))),
          const SizedBox(width: 10), Expanded(child: _SummaryCard(title: 'মোট আদায়', value: money(d['collection'] ?? 0)))]),
      ];
    },
  ));
}

class DailyReportPage extends StatefulWidget {
  const DailyReportPage({super.key});
  @override
  State<DailyReportPage> createState() => _DailyReportPageState();
}

class _DailyReportPageState extends State<DailyReportPage> {
  String date = today();
  Future<Map<String, num>> totals() => AppDatabase.instance.database.then((db) async {
    final posted = (await db.rawQuery("SELECT COALESCE(SUM(amount),0) AS x FROM collections WHERE date=? AND status='posted'", [date])).first['x'] as num;
    final draft = (await db.rawQuery("SELECT COALESCE(SUM(amount),0) AS x FROM collections WHERE date=? AND status='draft'", [date])).first['x'] as num;
    return {'posted': posted, 'draft': draft};
  });
  @override
  Widget build(BuildContext context) => AppPage(title: 'দৈনিক আদায় রিপোর্ট', child: FutureBuilder<Map<String, num>>(
    future: totals(),
    builder: (_, snap) {
      final d = snap.data ?? {};
      return ListView(padding: const EdgeInsets.all(18), children: [
        TextField(decoration: const InputDecoration(labelText: 'রিপোর্টের তারিখ', hintText: 'YYYY-MM-DD'),
            controller: TextEditingController(text: date), onChanged: (v) => setState(() => date = v)),
        const SizedBox(height: 16),
        Wrap(spacing: 10, runSpacing: 10, children: [
          _SummaryCard(title: 'মোট আদায়', value: money((d['posted'] ?? 0) + (d['draft'] ?? 0))),
          _SummaryCard(title: 'পোস্টেড', value: money(d['posted'] ?? 0)),
          _SummaryCard(title: 'ড্রাফট', value: money(d['draft'] ?? 0)),
        ]),
      ];
    },
  ));
}

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});
  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final old = TextEditingController();
  final fresh = TextEditingController();
  final again = TextEditingController();
  Future<void> save() async {
    if (fresh.text != again.text || fresh.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('নতুন পাসওয়ার্ড দুটি একই হতে হবে')));
      return;
    }
    try {
      await AppDatabase.instance.updateAdminPassword(old.text, fresh.text);
      old.clear(); fresh.clear(); again.clear();
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('পাসওয়ার্ড পরিবর্তন হয়েছে')));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))));
    }
  }
  @override
  Widget build(BuildContext context) => AppPage(title: 'সেটিংস', child: ListView(padding: const EdgeInsets.all(18), children: [
    Card(child: Padding(padding: const EdgeInsets.all(18), child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      const Text('পাসওয়ার্ড পরিবর্তন', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
      const SizedBox(height: 6),
      const Text('এডমিন অ্যাকাউন্টের নিরাপত্তা বজায় রাখুন', style: TextStyle(color: Colors.black54)),
      const SizedBox(height: 16),
      TextField(controller: old, obscureText: true, decoration: const InputDecoration(labelText: 'পুরাতন পাসওয়ার্ড')),
      const SizedBox(height: 12),
      TextField(controller: fresh, obscureText: true, decoration: const InputDecoration(labelText: 'নতুন পাসওয়ার্ড')),
      const SizedBox(height: 12),
      TextField(controller: again, obscureText: true, decoration: const InputDecoration(labelText: 'নতুন পাসওয়ার্ড আবার দিন')),
      const SizedBox(height: 14),
      FilledButton.icon(onPressed: save, icon: const Icon(Icons.lock_outline), label: const Text('পাসওয়ার্ড সংরক্ষণ করুন')),
    ]))),
  ]));
}

class _TopAction extends StatelessWidget {
  const _TopAction({required this.title, required this.count, required this.onAdd});
  final String title;
  final int count;
  final VoidCallback onAdd;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 14),
    child: Row(children: [
      Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: purpleDark)),
      const Spacer(),
      Text('$count টি', style: const TextStyle(color: Colors.black45)),
      const SizedBox(width: 8),
      FilledButton.icon(onPressed: onAdd, icon: const Icon(Icons.add, size: 17), label: const Text('নতুন যোগ')),
    ]),
  );
}

class _ChoiceRow extends StatelessWidget {
  const _ChoiceRow({required this.label, required this.value, required this.options, required this.onChanged});
  final String label;
  final String value;
  final List<String> options;
  final ValueChanged<String> onChanged;
  @override
  Widget build(BuildContext context) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.black54)),
    const SizedBox(height: 7),
    Wrap(spacing: 8, children: options.map((o) => ChoiceChip(label: Text(o), selected: value == o, onSelected: (_) => onChanged(o))).toList()),
  ]);
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({required this.title, required this.value});
  final String title;
  final String value;
  @override
  Widget build(BuildContext context) => SizedBox(
    width: 178,
    child: Card(child: Padding(padding: const EdgeInsets.all(14), child: Column(crossAxisAlignment: CrossAxisAlignment.start,
      children: [Text(title, style: const TextStyle(color: Colors.black54, fontSize: 12)), const SizedBox(height: 6),
        Text(value, style: const TextStyle(color: purple, fontSize: 20, fontWeight: FontWeight.bold))])),
  );
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.text});
  final String text;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.all(36),
    child: Column(children: [Icon(Icons.inbox_outlined, color: Colors.grey.shade400, size: 35), const SizedBox(height: 8),
      Text(text, style: const TextStyle(color: Colors.black54))]),
  );
}
