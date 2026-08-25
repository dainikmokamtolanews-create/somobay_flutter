import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'database/database_helper.dart';

void main() => runApp(const SomobayApp());

class SomobayApp extends StatelessWidget {
  const SomobayApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'সমবায়',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF087F5B),
          brightness: Brightness.light,
        ),
        scaffoldBackgroundColor: const Color(0xFFF5F8F7),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide.none,
          ),
        ),
      ),
      home: const HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});
  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int tab = 0;
  List<Map<String, Object?>> members = [];
  List<Map<String, Object?>> payments = [];
  double total = 0;
  bool loading = true;

  @override
  void initState() {
    super.initState();
    refresh();
  }

  Future<void> refresh() async {
    final db = DatabaseHelper.instance;
    final results = await Future.wait([db.members(), db.installments(), db.totalCollected()]);
    if (!mounted) return;
    setState(() {
      members = results[0] as List<Map<String, Object?>>;
      payments = results[1] as List<Map<String, Object?>>;
      total = results[2] as double;
      loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final titles = ['ড্যাশবোর্ড', 'সদস্যবৃন্দ', 'কিস্তি', 'রিপোর্ট'];
    return Scaffold(
      appBar: AppBar(
        title: Text(titles[tab], style: const TextStyle(fontWeight: FontWeight.w800)),
        actions: [
          IconButton(onPressed: refresh, icon: const Icon(Icons.sync_rounded), tooltip: 'আপডেট'),
        ],
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : IndexedStack(index: tab, children: [
              Dashboard(members: members, payments: payments, total: total),
              MembersPage(members: members, onChanged: refresh),
              InstallmentsPage(members: members, payments: payments, onChanged: refresh),
              ReportsPage(members: members, payments: payments, total: total),
            ]),
      bottomNavigationBar: NavigationBar(
        selectedIndex: tab,
        onDestinationSelected: (value) => setState(() => tab = value),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.grid_view_rounded), label: 'হোম'),
          NavigationDestination(icon: Icon(Icons.people_alt_outlined), label: 'সদস্য'),
          NavigationDestination(icon: Icon(Icons.payments_outlined), label: 'কিস্তি'),
          NavigationDestination(icon: Icon(Icons.bar_chart_rounded), label: 'রিপোর্ট'),
        ],
      ),
      floatingActionButton: tab == 1
          ? FloatingActionButton.extended(
              onPressed: () => showMemberDialog(context),
              icon: const Icon(Icons.person_add_alt_1),
              label: const Text('সদস্য যোগ'),
            )
          : tab == 2
              ? FloatingActionButton.extended(
                  onPressed: members.isEmpty ? null : () => showPaymentDialog(context),
                  icon: const Icon(Icons.add_card),
                  label: const Text('কিস্তি নিন'),
                )
              : null,
    );
  }

  Future<void> showMemberDialog(BuildContext context) async {
    final formKey = GlobalKey<FormState>();
    final name = TextEditingController();
    final phone = TextEditingController();
    final address = TextEditingController();
    final shares = TextEditingController(text: '1');
    final saved = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('নতুন সদস্য'),
        content: Form(
          key: formKey,
          child: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, children: [
            TextFormField(controller: name, decoration: const InputDecoration(labelText: 'সদস্যের নাম'), validator: required),
            const SizedBox(height: 12),
            TextFormField(controller: phone, keyboardType: TextInputType.phone, decoration: const InputDecoration(labelText: 'মোবাইল নম্বর'), validator: required),
            const SizedBox(height: 12),
            TextFormField(controller: address, decoration: const InputDecoration(labelText: 'ঠিকানা (ঐচ্ছিক)')),
            const SizedBox(height: 12),
            TextFormField(controller: shares, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'শেয়ার সংখ্যা')),
          ])),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('বাতিল')),
          FilledButton(onPressed: () async {
            if (!formKey.currentState!.validate()) return;
            await DatabaseHelper.instance.addMember({
              'name': name.text.trim(), 'phone': phone.text.trim(), 'address': address.text.trim(),
              'share_count': int.tryParse(shares.text) ?? 1, 'joined_at': DateTime.now().toIso8601String(),
            });
            if (context.mounted) Navigator.pop(context, true);
          }, child: const Text('সংরক্ষণ')),
        ],
      ),
    );
    if (saved == true) refresh();
  }

  Future<void> showPaymentDialog(BuildContext context) async {
    final formKey = GlobalKey<FormState>();
    int? selected = int.tryParse(members.first['id'].toString());
    final amount = TextEditingController();
    final note = TextEditingController();
    final saved = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(builder: (context, setDialog) => AlertDialog(
        title: const Text('কিস্তি গ্রহণ'),
        content: Form(key: formKey, child: Column(mainAxisSize: MainAxisSize.min, children: [
          DropdownButtonFormField<int>(
            value: selected, decoration: const InputDecoration(labelText: 'সদস্য নির্বাচন'),
            items: members.map((m) => DropdownMenuItem(value: int.parse(m['id'].toString()), child: Text(m['name'].toString()))).toList(),
            onChanged: (value) => setDialog(() => selected = value),
          ),
          const SizedBox(height: 12),
          TextFormField(controller: amount, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'টাকার পরিমাণ'), validator: required),
          const SizedBox(height: 12),
          TextFormField(controller: note, decoration: const InputDecoration(labelText: 'নোট (ঐচ্ছিক)')),
        ])),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('বাতিল')),
          FilledButton(onPressed: () async {
            if (!formKey.currentState!.validate() || selected == null) return;
            await DatabaseHelper.instance.addInstallment({'member_id': selected, 'amount': double.tryParse(amount.text) ?? 0, 'note': note.text.trim(), 'paid_at': DateTime.now().toIso8601String()});
            if (context.mounted) Navigator.pop(context, true);
          }, child: const Text('জমা দিন')),
        ],
      )),
    );
    if (saved == true) refresh();
  }
}

String? required(String? value) => value == null || value.trim().isEmpty ? 'এই তথ্যটি প্রয়োজন' : null;
String money(num value) => '৳${NumberFormat('#,##0.00', 'en_US').format(value)}';

class Dashboard extends StatelessWidget {
  final List<Map<String, Object?>> members, payments;
  final double total;
  const Dashboard({super.key, required this.members, required this.payments, required this.total});
  @override
  Widget build(BuildContext context) => RefreshIndicator(
    onRefresh: () async {},
    child: ListView(padding: const EdgeInsets.all(18), children: [
      Text('আসসালামু আলাইকুম', style: Theme.of(context).textTheme.titleMedium),
      const Text('সমিতির আজকের চিত্র', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900)),
      const SizedBox(height: 20),
      Row(children: [
        Expanded(child: StatCard(label: 'মোট সদস্য', value: '${members.length}', icon: Icons.people_alt_rounded, color: const Color(0xFF087F5B))),
        const SizedBox(width: 12),
        Expanded(child: StatCard(label: 'মোট সঞ্চয়', value: money(total), icon: Icons.account_balance_wallet_rounded, color: const Color(0xFFCE6A25))),
      ]),
      const SizedBox(height: 14),
      StatCard(label: 'মোট কিস্তি', value: '${payments.length} টি', icon: Icons.receipt_long_rounded, color: const Color(0xFF4D63B8)),
      const SizedBox(height: 26),
      const Text('সাম্প্রতিক কিস্তি', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
      const SizedBox(height: 8),
      if (payments.isEmpty) const EmptyState(text: 'এখনও কোনো কিস্তি জমা হয়নি'),
      ...payments.take(5).map((p) => PaymentTile(payment: p)),
    ]),
  );
}

class StatCard extends StatelessWidget {
  final String label, value; final IconData icon; final Color color;
  const StatCard({super.key, required this.label, required this.value, required this.icon, required this.color});
  @override
  Widget build(BuildContext context) => Card(
    elevation: 0, color: color, child: Padding(padding: const EdgeInsets.all(17), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Icon(icon, color: Colors.white.withOpacity(.9)), const SizedBox(height: 12),
      Text(value, style: const TextStyle(color: Colors.white, fontSize: 23, fontWeight: FontWeight.w900)),
      Text(label, style: TextStyle(color: Colors.white.withOpacity(.85))),
    ])),
  );
}

class MembersPage extends StatelessWidget {
  final List<Map<String, Object?>> members; final VoidCallback onChanged;
  const MembersPage({super.key, required this.members, required this.onChanged});
  @override
  Widget build(BuildContext context) => ListView(padding: const EdgeInsets.fromLTRB(16, 12, 16, 90), children: [
    Text('${members.length} জন সদস্য', style: Theme.of(context).textTheme.titleMedium),
    const SizedBox(height: 10),
    if (members.isEmpty) const EmptyState(text: 'সদস্য তালিকা খালি'),
    ...members.map((m) => Card(elevation: 0, child: ListTile(
      leading: CircleAvatar(child: Text(m['name'].toString().substring(0, 1))),
      title: Text(m['name'].toString(), style: const TextStyle(fontWeight: FontWeight.w700)),
      subtitle: Text('${m['phone']}  •  ${m['share_count']} শেয়ার'),
      trailing: IconButton(icon: const Icon(Icons.delete_outline), onPressed: () async {
        await DatabaseHelper.instance.deleteMember(int.parse(m['id'].toString())); onChanged();
      }),
    ))),
  ]);
}

class InstallmentsPage extends StatelessWidget {
  final List<Map<String, Object?>> members, payments; final VoidCallback onChanged;
  const InstallmentsPage({super.key, required this.members, required this.payments, required this.onChanged});
  @override
  Widget build(BuildContext context) => ListView(padding: const EdgeInsets.fromLTRB(16, 12, 16, 90), children: [
    Text('${payments.length} টি লেনদেন', style: Theme.of(context).textTheme.titleMedium),
    const SizedBox(height: 10),
    if (payments.isEmpty) const EmptyState(text: 'কিস্তির হিসাব এখানে দেখা যাবে'),
    ...payments.map((p) => PaymentTile(payment: p)),
  ]);
}

class PaymentTile extends StatelessWidget {
  final Map<String, Object?> payment;
  const PaymentTile({super.key, required this.payment});
  @override
  Widget build(BuildContext context) {
    final date = DateTime.tryParse(payment['paid_at'].toString());
    return Card(elevation: 0, child: ListTile(
      leading: const CircleAvatar(child: Icon(Icons.arrow_downward_rounded)),
      title: Text(payment['member_name'].toString(), style: const TextStyle(fontWeight: FontWeight.w700)),
      subtitle: Text(date == null ? '' : DateFormat('dd MMM yyyy, hh:mm a', 'bn').format(date)),
      trailing: Text(money(payment['amount'] as num), style: TextStyle(color: Theme.of(context).colorScheme.primary, fontWeight: FontWeight.w800)),
    ));
  }
}

class ReportsPage extends StatelessWidget {
  final List<Map<String, Object?>> members, payments; final double total;
  const ReportsPage({super.key, required this.members, required this.payments, required this.total});
  @override
  Widget build(BuildContext context) {
    final average = payments.isEmpty ? 0 : total / payments.length;
    return ListView(padding: const EdgeInsets.all(18), children: [
      const Text('সমিতির সারাংশ', style: TextStyle(fontSize: 25, fontWeight: FontWeight.w900)),
      const SizedBox(height: 18),
      ReportRow(label: 'মোট সদস্য', value: '${members.length} জন'),
      ReportRow(label: 'মোট কিস্তি', value: '${payments.length} টি'),
      ReportRow(label: 'মোট সংগ্রহ', value: money(total)),
      ReportRow(label: 'গড় কিস্তি', value: money(average)),
      const SizedBox(height: 20),
      Card(color: Theme.of(context).colorScheme.primaryContainer, elevation: 0, child: const Padding(
        padding: EdgeInsets.all(18), child: Text('এই অ্যাপের সব তথ্য ফোনেই সংরক্ষিত থাকে। ইন্টারনেট ছাড়াই সদস্য ও কিস্তির হিসাব পরিচালনা করুন।'),
      )),
    ]);
  }
}

class ReportRow extends StatelessWidget {
  final String label, value;
  const ReportRow({super.key, required this.label, required this.value});
  @override
  Widget build(BuildContext context) => Card(elevation: 0, child: ListTile(title: Text(label), trailing: Text(value, style: const TextStyle(fontWeight: FontWeight.w800))));
}

class EmptyState extends StatelessWidget {
  final String text;
  const EmptyState({super.key, required this.text});
  @override
  Widget build(BuildContext context) => Padding(padding: const EdgeInsets.symmetric(vertical: 45), child: Center(child: Column(children: [
    Icon(Icons.inbox_outlined, size: 48, color: Theme.of(context).colorScheme.primary.withOpacity(.5)),
    const SizedBox(height: 10), Text(text, style: const TextStyle(color: Colors.black54)),
  ])));
}