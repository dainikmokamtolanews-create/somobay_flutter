import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:intl/intl.dart';

void main() => runApp(SomobayApp());

class SomobayApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'সমবায় সমিতি',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.deepPurple,
        scaffoldBackgroundColor: const Color(0xFFF5F0FF),
        cardTheme: CardThemeData(
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
      home: LoginPage(),
    );
  }
}

// DB Helper
class DBHelper {
  static Database? _db;
  static Future<Database> getDB() async {
    if (_db!= null) return _db!;
    _db = await openDatabase(
      join(await getDatabasesPath(), 'somobay_final_v1.db'),
      version: 1,
      onCreate: (db, v) async {
        await db.execute('CREATE TABLE users(id INTEGER PRIMARY KEY, username TEXT, password TEXT, role TEXT)');
        await db.execute('CREATE TABLE groups(id INTEGER PRIMARY KEY AUTOINCREMENT, name TEXT, code TEXT)');
        await db.execute('CREATE TABLE employees(id INTEGER PRIMARY KEY AUTOINCREMENT, name TEXT, mobile TEXT, address TEXT, username TEXT, password TEXT, group_id INTEGER, group_name TEXT)');
        await db.execute('CREATE TABLE members(id INTEGER PRIMARY KEY AUTOINCREMENT, member_no TEXT, name TEXT, father TEXT, mother TEXT, spouse TEXT, dob TEXT, nid TEXT, mobile TEXT, address TEXT, group_id INTEGER, group_name TEXT, group_code TEXT, join_date TEXT, comment TEXT, assigned_field_worker_id INTEGER, assigned_name TEXT)');
        await db.execute('CREATE TABLE loans(id INTEGER PRIMARY KEY AUTOINCREMENT, member_id INTEGER, member_no TEXT, member_name TEXT, loan_amount REAL, interest_percent REAL, interest_amount REAL, total_payable REAL, collection_type TEXT, loan_date TEXT)');
        await db.execute('CREATE TABLE collections(id INTEGER PRIMARY KEY AUTOINCREMENT, loan_id INTEGER, member_id INTEGER, member_no TEXT, member_name TEXT, amount REAL, collection_date TEXT, status TEXT, field_worker_id INTEGER, group_name TEXT)');
        await db.execute('CREATE TABLE bank_transactions(id INTEGER PRIMARY KEY AUTOINCREMENT, type TEXT, party_type TEXT, party_name TEXT, amount REAL, date TEXT)');
        await db.execute('CREATE TABLE settings(key TEXT PRIMARY KEY, value TEXT)');
        await db.insert('users', {'username': 'admin', 'password': '123456', 'role': 'admin'});
        await db.insert('users', {'username': 'field', 'password': '1234', 'role': 'field_worker'});
        await db.insert('settings', {'key': 'daily', 'value': '5'});
        await db.insert('settings', {'key': 'weekly', 'value': '10'});
        await db.insert('settings', {'key': 'monthly', 'value': '15'});
      },
    );
    return _db!;
  }
}

// LOGIN
class LoginPage extends StatefulWidget {
  @override State<LoginPage> createState() => _LoginPageState();
}
class _LoginPageState extends State<LoginPage> {
  String role = '';
  final u = TextEditingController();
  final p = TextEditingController();
  login() async {
    var db = await DBHelper.getDB();
    var res = await db.query('users', where: 'username=? AND password=? AND role=?', whereArgs: [u.text.trim(), p.text.trim(), role]);
    if (res.isNotEmpty) {
      if (role == 'admin') {
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => AdminDashboard(userId: res.first['id'] as int)));
      } else {
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => FieldDashboard(userId: res.first['id'] as int)));
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('ভুল তথ্য!')));
    }
  }
  @override Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            const Icon(Icons.handshake, size: 70, color: Colors.deepPurple),
            const Text('সমবায় সমিতি', style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.deepPurple)),
            const SizedBox(height: 20),
            Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              ElevatedButton.icon(icon: const Icon(Icons.shield), label: const Text('এডমিন লগইন'), style: ElevatedButton.styleFrom(backgroundColor: Colors.deepPurple, foregroundColor: Colors.white, side: BorderSide(color: role=='admin'?Colors.yellow:Colors.transparent, width: 3)), onPressed: () => setState(() => role = 'admin')),
              const SizedBox(width: 10),
              ElevatedButton.icon(icon: const Icon(Icons.person), label: const Text('মাঠকর্মী লগইন'), style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white, side: BorderSide(color: role=='field_worker'?Colors.yellow:Colors.transparent, width: 3)), onPressed: () => setState(() => role = 'field_worker')),
            ]),
            if (role!= '')...[
              const SizedBox(height: 20),
              Card(child: Padding(padding: const EdgeInsets.all(16), child: Column(children: [
                TextField(controller: u, decoration: const InputDecoration(labelText: 'ইউজারনেম', border: OutlineInputBorder())),
                const SizedBox(height: 10),
                TextField(controller: p, decoration: const InputDecoration(labelText: 'পাসওয়ার্ড', border: OutlineInputBorder()), obscureText: true),
                const SizedBox(height: 10),
                SizedBox(width: double.infinity, child: ElevatedButton(onPressed: login, child: const Text('প্রবেশ করুন'))),
              ]))),
            ]
          ]),
        ),
      ),
    );
  }
}

// ADMIN DASHBOARD - 10 Buttons
class AdminDashboard extends StatelessWidget {
  final int userId;
  AdminDashboard({required this.userId});
  @override Widget build(BuildContext context) {
    List<Map<String, dynamic>> btns = [
      {'title':'গ্রুপ ব্যবস্থাপনা','icon':Icons.group,'page': GroupPage()},
      {'title':'কর্মচারীগণের তথ্য','icon':Icons.people,'page': EmployeePage()},
      {'title':'নতুন সদস্য ভর্তি','icon':Icons.person_add,'page': MemberPage()},
      {'title':'ঋণ বিতরণ','icon':Icons.money,'page': LoanDistributionPage()},
      {'title':'মুনাফা/লাভ','icon':Icons.percent,'page': ProfitPage()},
      {'title':'ব্যাংক লেনদেন','icon':Icons.account_balance,'page': BankPage()},
      {'title':'এক নজরে','icon':Icons.dashboard,'page': OverviewPage()},
      {'title':'দৈনিক আদায় রিপোর্ট','icon':Icons.receipt,'page': DailyReportPage()},
      {'title':'সেটিংস','icon':Icons.settings,'page': SettingsPage(userId: userId)},
      {'title':'লগআউট','icon':Icons.logout,'page': LoginPage()},
    ];
    return Scaffold(
      appBar: AppBar(title: const Text('এডমিন ড্যাশবোর্ড'), backgroundColor: Colors.deepPurple, foregroundColor: Colors.white),
      body: GridView.count(crossAxisCount: 2, padding: const EdgeInsets.all(12), children: btns.map((b) => Card(child: InkWell(onTap: () {
        if (b['title']=='লগআউট') { Navigator.pushReplacement(context, MaterialPageRoute(builder: (_)=> LoginPage())); }
        else { Navigator.push(context, MaterialPageRoute(builder: (_)=> b['page'])); }
      }, child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(b['icon'] as IconData, size: 40, color: Colors.deepPurple), const SizedBox(height: 8), Text(b['title'], textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.bold))])))).toList()),
    );
  }
}

// FIELD DASHBOARD
class FieldDashboard extends StatelessWidget {
  final int userId;
  FieldDashboard({required this.userId});
  @override Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('মাঠকর্মী ড্যাশবোর্ড'), backgroundColor: Colors.green, foregroundColor: Colors.white),
      body: GridView.count(crossAxisCount: 2, padding: const EdgeInsets.all(12), children: [
        _card(context, 'আদায়', Icons.payment, CollectionPage(userId: userId)),
        _card(context, 'পোস্টিং দিন', Icons.upload, PostingPage(userId: userId)),
        _card(context, 'গ্রুপের রিপোর্ট', Icons.report, GroupReportPage(userId: userId)),
        _card(context, 'লগআউট', Icons.logout, LoginPage(), isLogout: true),
      ]),
    );
  }
  Widget _card(BuildContext c, String t, IconData ic, Widget page, {bool isLogout=false}) => Card(child: InkWell(onTap: (){
    if(isLogout) Navigator.pushReplacement(c, MaterialPageRoute(builder: (_)=> LoginPage()));
    else Navigator.push(c, MaterialPageRoute(builder: (_)=> page));
  }, child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(ic, size: 40, color: Colors.green), Text(t, style: const TextStyle(fontWeight: FontWeight.bold))])) );
}

// OTHER PAGES - Simplified working versions
class GroupPage extends StatefulWidget { @override State<GroupPage> createState() => _GroupPageState(); }
class _GroupPageState extends State<GroupPage> {
  final n = TextEditingController(); final code = TextEditingController(); List<Map> list=[];
  load() async { var db=await DBHelper.getDB(); var r=await db.query('groups'); setState(()=>list=r); }
  @override void initState(){ super.initState(); load(); }
  @override Widget build(BuildContext c)=> Scaffold(appBar: AppBar(title: const Text('গ্রুপ ব্যবস্থাপনা')), body: Column(children: [Padding(padding: const EdgeInsets.all(12), child: Row(children: [Expanded(child: TextField(controller: n, decoration: const InputDecoration(labelText: 'গ্রুপ নাম'))), const SizedBox(width: 8), Expanded(child: TextField(controller: code, decoration: const InputDecoration(labelText: 'কোড'))), IconButton(icon: const Icon(Icons.save), onPressed: () async { var db=await DBHelper.getDB(); await db.insert('groups', {'name':n.text,'code':code.text}); n.clear(); code.clear(); load(); })])), Expanded(child: ListView.builder(itemCount: list.length, itemBuilder: (_,i)=> ListTile(title: Text(list[i]['name']), subtitle: Text(list[i]['code']))))]));
}

class EmployeePage extends StatefulWidget { @override State<EmployeePage> createState() => _EmployeePageState(); }
class _EmployeePageState extends State<EmployeePage> {
  final name=TextEditingController(); final mobile=TextEditingController(); List<Map> groups=[]; List<Map> emps=[]; String? selGroup;
  load() async { var db=await DBHelper.getDB(); var g=await db.query('groups'); var e=await db.query('employees'); setState((){groups=g; emps=e;}); }
  @override void initState(){ super.initState(); load(); }
  @override Widget build(BuildContext c)=> Scaffold(appBar: AppBar(title: const Text('কর্মচারীগণের তথ্য')), body: Column(children: [Padding(padding: const EdgeInsets.all(12), child: Column(children: [TextField(controller: name, decoration: const InputDecoration(labelText: 'নাম')), TextField(controller: mobile, decoration: const InputDecoration(labelText: 'মোবাইল')), DropdownButtonFormField(value: selGroup, hint: const Text('গ্রুপ নির্বাচন'), items: groups.map((g)=> DropdownMenuItem(value: g['name'].toString(), child: Text(g['name']))).toList(), onChanged: (v)=> setState(()=>selGroup=v as String)), ElevatedButton(onPressed: () async { var db=await DBHelper.getDB(); await db.insert('employees', {'name':name.text,'mobile':mobile.text,'group_name':selGroup,'username':'field_${DateTime.now().millisecond}','password':'1234'}); load(); }, child: const Text('সংরক্ষণ'))])), Expanded(child: ListView.builder(itemCount: emps.length, itemBuilder: (_,i)=> ListTile(title: Text(emps[i]['name']), subtitle: Text('গ্রুপ: ${emps[i]['group_name']} | ${emps[i]['mobile']}'))))]));
}

class MemberPage extends StatefulWidget { @override State<MemberPage> createState() => _MemberPageState(); }
class _MemberPageState extends State<MemberPage> {
  final memberNo=TextEditingController(); final name=TextEditingController(); final father=TextEditingController(); final mobile=TextEditingController(); List<Map> emps=[]; int? assignedId; String? assignedName;
  load() async { var db=await DBHelper.getDB(); var e=await db.query('employees'); setState(()=>emps=e); }
  @override void initState(){ super.initState(); load(); }
  @override Widget build(BuildContext c)=> Scaffold(appBar: AppBar(title: const Text('নতুন সদস্য ভর্তি - 13 ফিল্ড')), body: SingleChildScrollView(padding: const EdgeInsets.all(16), child: Column(children: [
    TextField(controller: memberNo, decoration: const InputDecoration(labelText: 'সদস্য নং')),
    TextField(controller: name, decoration: const InputDecoration(labelText: 'নাম')),
    TextField(controller: father, decoration: const InputDecoration(labelText: 'পিতার নাম')),
    TextField(controller: mobile, decoration: const InputDecoration(labelText: 'মোবাইল')),
    DropdownButtonFormField(value: assignedId, hint: const Text('মাঠকর্মী অ্যাসাইন'), items: emps.map((e)=> DropdownMenuItem(value: e['id'] as int, child: Text(e['name']))).toList(), onChanged: (v){ setState((){ assignedId=v as int; assignedName = emps.firstWhere((x)=> x['id']==v)['name']; }); }),
    const SizedBox(height: 12),
    ElevatedButton(onPressed: () async { var db=await DBHelper.getDB(); await db.insert('members', {'member_no':memberNo.text,'name':name.text,'father':father.text,'mobile':mobile.text,'assigned_field_worker_id':assignedId,'assigned_name':assignedName,'join_date':DateFormat('yyyy-MM-dd').format(DateTime.now())}); ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('সদস্য ভর্তি সম্পন্ন'))); }, child: const Text('ভর্তি করুন'))
  ])));
}

class ProfitPage extends StatefulWidget { @override State<ProfitPage> createState() => _ProfitPageState(); }
class _ProfitPageState extends State<ProfitPage> {
  final d=TextEditingController(); final w=TextEditingController(); final m=TextEditingController();
  @override void initState(){ super.initState(); _load(); }
  _load() async { var db=await DBHelper.getDB(); var dr=await db.query('settings', where: 'key=?', whereArgs: ['daily']); var wr=await db.query('settings', where: 'key=?', whereArgs: ['weekly']); var mr=await db.query('settings', where: 'key=?', whereArgs: ['monthly']); setState((){ d.text=dr.first['value'].toString(); w.text=wr.first['value'].toString(); m.text=mr.first['value'].toString(); }); }
  save() async { var db=await DBHelper.getDB(); await db.update('settings', {'value':d.text}, where: 'key=?', whereArgs: ['daily']); await db.update('settings', {'value':w.text}, where: 'key=?', whereArgs: ['weekly']); await db.update('settings', {'value':m.text}, where: 'key=?', whereArgs: ['monthly']); ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('সংরক্ষণ হয়েছে'))); }
  @override Widget build(BuildContext c)=> Scaffold(appBar: AppBar(title: const Text('মুনাফা / লাভ')), body: Padding(padding: const EdgeInsets.all(16), child: Column(children: [TextField(controller: d, decoration: const InputDecoration(labelText: 'দৈনিক ঋণ মুনাফা %'), keyboardType: TextInputType.number), TextField(controller: w, decoration: const InputDecoration(labelText: 'সাপ্তাহিক মুনাফা %'), keyboardType: TextInputType.number), TextField(controller: m, decoration: const InputDecoration(labelText: 'মাসিক মুনাফা %'), keyboardType: TextInputType.number), const SizedBox(height: 12), ElevatedButton(onPressed: save
