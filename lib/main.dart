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
        cardTheme: const CardThemeData(elevation: 2, shape: RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(12)))),
      ),
      home: LoginPage(),
    );
  }
}

class DBHelper {
  static Database? _db;
  static Future<Database> getDB() async {
    if (_db!= null) return _db!;
    _db = await openDatabase(
      join(await getDatabasesPath(), 'somobay_final_v2.db'),
      version: 1,
      onCreate: (db, v) async {
        await db.execute('CREATE TABLE users(id INTEGER PRIMARY KEY, username TEXT, password TEXT, role TEXT)');
        await db.execute('CREATE TABLE groups(id INTEGER PRIMARY KEY AUTOINCREMENT, name TEXT, code TEXT)');
        await db.execute('CREATE TABLE employees(id INTEGER PRIMARY KEY AUTOINCREMENT, name TEXT, mobile TEXT, address TEXT, username TEXT, password TEXT, group_id INTEGER, group_name TEXT)');
        await db.execute('CREATE TABLE members(id INTEGER PRIMARY KEY AUTOINCREMENT, member_no TEXT, name TEXT, father TEXT, mother TEXT, spouse TEXT, dob TEXT, nid TEXT, mobile TEXT, address TEXT, group_id INTEGER, group_name TEXT, group_code TEXT, join_date TEXT, comment TEXT, assigned_field_worker_id INTEGER, assigned_name TEXT)');
        await db.execute('CREATE TABLE loans(id INTEGER PRIMARY KEY AUTOINCREMENT, member_id INTEGER, member_no TEXT, member_name TEXT, loan_amount REAL, interest_amount REAL, total_payable REAL, collection_type TEXT, loan_date TEXT)');
        await db.execute('CREATE TABLE collections(id INTEGER PRIMARY KEY AUTOINCREMENT, member_id INTEGER, member_no TEXT, member_name TEXT, amount REAL, collection_date TEXT, status TEXT, field_worker_id INTEGER)');
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

// ALL REPORT / LIST PAGES FIRST - So Dashboard can find them
class GroupReportPage extends StatefulWidget {
  final int userId;
  GroupReportPage({required this.userId});
  @override State<GroupReportPage> createState() => _GroupReportPageState();
}
class _GroupReportPageState extends State<GroupReportPage> {
  List<Map> data=[]; double total=0;
  @override void initState(){ super.initState(); load(); }
  load() async { var db=await DBHelper.getDB(); var r=await db.query('collections', where: 'field_worker_id=? AND status=?', whereArgs: [widget.userId,'posted']); double t=0; for(var e in r) t+= (e['amount'] as num).toDouble(); setState((){ data=r; total=t; }); }
  @override Widget build(BuildContext c)=> Scaffold(appBar: AppBar(title: const Text('গ্রুপের রিপোর্ট')), body: Column(children: [Expanded(child: ListView.builder(itemCount: data.length, itemBuilder: (_,i)=> ListTile(title: Text('${data[i]['member_no']} - ${data[i]['member_name']}'), subtitle: Text('তারিখ: ${data[i]['collection_date']}'), trailing: Text('${data[i]['amount']} টাকা')))), Card(color: Colors.green[100], child: ListTile(title: const Text('মোট আদায়'), trailing: Text('$total টাকা', style: const TextStyle(fontWeight: FontWeight.bold))))]));
}

class PostingPage extends StatefulWidget { final int userId; PostingPage({required this.userId}); @override State<PostingPage> createState() => _PostingPageState(); }
class _PostingPageState extends State<PostingPage> {
  List<Map> drafts=[];
  load() async { var db=await DBHelper.getDB(); var r=await db.query('collections', where: 'status=?', whereArgs: ['draft']); setState(()=> drafts=r); }
  @override void initState(){ super.initState(); load(); }
  @override Widget build(BuildContext c)=> Scaffold(appBar: AppBar(title: const Text('পোস্টিং দিন')), body: Column(children: [Expanded(child: ListView.builder(itemCount: drafts.length, itemBuilder: (_,i)=> ListTile(title: Text('${drafts[i]['member_no']} - ${drafts[i]['member_name']}'), subtitle: Text('${drafts[i]['amount']} টাকা'), trailing: ElevatedButton(onPressed: () async { var db=await DBHelper.getDB(); await db.update('collections', {'status':'posted'}, where: 'id=?', whereArgs: [drafts[i]['id']]); load(); }, child: const Text('Post'))))), ElevatedButton(onPressed: () async { var db=await DBHelper.getDB(); await db.update('collections', {'status':'posted'}, where: 'status=?', whereArgs: ['draft']); load(); }, child: const Text('সব পোস্ট করুন'))]));
}

class CollectionPage extends StatefulWidget { final int userId; CollectionPage({required this.userId}); @override State<CollectionPage> createState() => _CollectionPageState(); }
class _CollectionPageState extends State<CollectionPage> {
  List<Map> members=[]; int? selId; final amt=TextEditingController();
  @override void initState(){ super.initState(); _load(); }
  _load() async { var db=await DBHelper.getDB(); var r=await db.query('members', where: 'assigned_field_worker_id=?', whereArgs: [widget.userId]); setState(()=> members=r); }
  @override Widget build(BuildContext c)=> Scaffold(appBar: AppBar(title: const Text('আদায়')), body: Padding(padding: const EdgeInsets.all(16), child: Column(children: [
    DropdownButtonFormField(value: selId, hint: const Text('সদস্য নির্বাচন'), items: members.map((m)=> DropdownMenuItem(value: m['id'] as int, child: Text('${m['member_no']} - ${m['name']}'))).toList(), onChanged: (v)=> setState(()=> selId=v as int)),
    TextField(controller: amt, decoration: const InputDecoration(labelText: 'আদায়ের পরিমাণ'), keyboardType: TextInputType.number),
    const SizedBox(height: 12),
    SizedBox(width: double.infinity, child: ElevatedButton(onPressed: () async { var mem=members.firstWhere((x)=> x['id']==selId); var db=await DBHelper.getDB(); await db.insert('collections', {'member_id':selId,'member_no':mem['member_no'],'member_name':mem['name'],'amount':double.tryParse(amt.text)??0,'collection_date':DateFormat('yyyy-MM-dd').format(DateTime.now()),'status':'draft','field_worker_id':widget.userId}); ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Draft সেভ হয়েছে'))); }, child: const Text('Draft হিসেবে সংরক্ষণ'))),
  ])));
}

class LoanListPage extends StatefulWidget { @override State<LoanListPage> createState() => _LoanListPageState(); }
class _LoanListPageState extends State<LoanListPage> {
  List<Map> list=[];
  @override void initState(){ super.initState(); _load(); }
  _load() async { var db=await DBHelper.getDB(); var r=await db.query('loans', orderBy: 'id DESC'); setState(()=> list=r); }
  @override Widget build(BuildContext c)=> Scaffold(appBar: AppBar(title: const Text('ঋণ তালিকা')), body: ListView.builder(itemCount: list.length, itemBuilder: (_,i)=> Card(child: ListTile(title: Text('${list[i]['member_no']} - ${list[i]['member_name']}'), subtitle: Text('মোট: ${list[i]['total_payable']}'), trailing: Text(list[i]['loan_date'].toString())))));
}

class BankListPage extends StatefulWidget { @override State<BankListPage> createState() => _BankListPageState(); }
class _BankListPageState extends State<BankListPage> {
  List<Map> list=[];
  @override void initState(){ super.initState(); _load(); }
  _load() async { var db=await DBHelper.getDB(); var r=await db.query('bank_transactions', orderBy: 'id DESC'); setState(()=> list=r); }
  @override Widget build(BuildContext c)=> Scaffold(appBar: AppBar(title: const Text('ব্যাংক লেনদেন তালিকা')), body: ListView.builder(itemCount: list.length, itemBuilder: (_,i)=> Card(child: ListTile(title: Text('${list[i]['type']} - ${list[i]['party_name']}'), trailing: Text('${list[i]['amount']} টাকা')))));
}

class GroupPage extends StatefulWidget { @override State<GroupPage> createState() => _GroupPageState(); }
class _GroupPageState extends State<GroupPage> {
  final n=TextEditingController(); final code=TextEditingController(); List<Map> list=[];
  load() async { var db=await DBHelper.getDB(); var r=await db.query('groups'); setState(()=> list=r); }
  @override void initState(){ super.initState(); load(); }
  @override Widget build(BuildContext c)=> Scaffold(appBar: AppBar(title: const Text('গ্রুপ ব্যবস্থাপনা')), body: Column(children: [Padding(padding: const EdgeInsets.all(12), child: Row(children: [Expanded(child: TextField(controller: n, decoration: const InputDecoration(labelText: 'গ্রুপ নাম'))), const SizedBox(width: 8), Expanded(child: TextField(controller: code, decoration: const InputDecoration(labelText: 'কোড'))), IconButton(icon: const Icon(Icons.save), onPressed: () async { var db=await DBHelper.getDB(); await db.insert('groups', {'name':n.text,'code':code.text}); n.clear(); code.clear(); load(); })])), Expanded(child: ListView.builder(itemCount: list.length, itemBuilder: (_,i)=> ListTile(title: Text(list[i]['name']), subtitle: Text(list[i]['code']))))]));
}

class EmployeePage extends StatefulWidget { @override State<EmployeePage> createState() => _EmployeePageState(); }
class _EmployeePageState extends State<EmployeePage> {
  final name=TextEditingController(); final mobile=TextEditingController(); List<Map> groups=[]; List<Map> emps=[]; String? selGroup;
  load() async { var db=await DBHelper.getDB(); var g=await db.query('groups'); var e=await db.query('employees'); setState((){groups=g; emps=e;}); }
  @override void initState(){ super.initState(); load(); }
  @override Widget build(BuildContext c)=> Scaffold(appBar: AppBar(title: const Text('কর্মচারী')), body: Column(children: [Padding(padding: const EdgeInsets.all(12), child: Column(children: [TextField(controller: name, decoration: const InputDecoration(labelText: 'নাম')), TextField(controller: mobile, decoration: const InputDecoration(labelText: 'মোবাইল')), DropdownButtonFormField(value: selGroup, hint: const Text('গ্রুপ'), items: groups.map((g)=> DropdownMenuItem(value: g['name'].toString(), child: Text(g['name']))).toList(), onChanged: (v)=> setState(()=> selGroup=v as String),), ElevatedButton(onPressed: () async { var db=await DBHelper.getDB(); await db.insert('employees', {'name':name.text,'mobile':mobile.text,'group_name':selGroup,'username':'field_${DateTime.now().millisecond}','password':'1234'}); load(); }, child: const Text('সংরক্ষণ'))])), Expanded(child: ListView.builder(itemCount: emps.length, itemBuilder: (_,i)=> ListTile(title: Text(emps[i]['name']), subtitle: Text('${emps[i]['group_name']} | ${emps[i]['mobile']}'))))]));
}

class MemberPage extends StatefulWidget { @override State<MemberPage> createState() => _MemberPageState(); }
class _MemberPageState extends State<MemberPage> {
  final memberNo=TextEditingController(); final name=TextEditingController(); final father=TextEditingController(); final mobile=TextEditingController(); List<Map> emps=[]; int? assignedId; String? assignedName;
  load() async { var db=await DBHelper.getDB(); var e=await db.query('employees'); setState(()=> emps=e); }
  @override void initState(){ super.initState(); load(); }
  @override Widget build(BuildContext c)=> Scaffold(appBar: AppBar(title: const Text('নতুন সদস্য ভর্তি')), body: SingleChildScrollView(padding: const EdgeInsets.all(16), child: Column(children: [TextField(controller: memberNo, decoration: const InputDecoration(labelText: 'সদস্য নং')), TextField(controller: name, decoration: const InputDecoration(labelText: 'নাম')), TextField(controller: father, decoration: const InputDecoration(labelText: 'পিতার নাম')), TextField(controller: mobile, decoration: const InputDecoration(labelText: 'মোবাইল')), DropdownButtonFormField(value: assignedId, hint: const Text('মাঠকর্মী অ্যাসাইন'), items: emps.map((e)=> DropdownMenuItem(value: e['id'] as int, child: Text(e['name']))).toList(), onChanged: (v){ setState((){ assignedId=v as int; assignedName=emps.firstWhere((x)=> x['id']==v)['name']; }); }), ElevatedButton(onPressed: () async { var db=await DBHelper.getDB(); await db.insert('members', {'member_no':memberNo.text,'name':name.text,'father':father.text,'mobile':mobile.text,'assigned_field_worker_id':assignedId,'assigned_name':assignedName,'join_date':DateFormat('yyyy-MM-dd').format(DateTime.now())}); ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('সদস্য ভর্তি সম্পন্ন'))); }, child: const Text('ভর্তি করুন'))])));
}

class ProfitPage extends StatefulWidget { @override State<ProfitPage> createState() => _ProfitPageState(); }
class _ProfitPageState extends State<ProfitPage> {
  final d=TextEditingController(); final w=TextEditingController(); final m=TextEditingController();
  @override void initState(){ super.initState(); _load(); }
  _load() async { var db=await DBHelper.getDB(); var dr=await db.query('settings', where: 'key=?', whereArgs: ['daily']); var wr=await db.query('settings', where: 'key=?', whereArgs: ['weekly']); var mr=await db.query('settings', where: 'key=?', whereArgs: ['monthly']); setState((){ d.text=dr.first['value'].toString(); w.text=wr.first['value'].toString(); m.text=mr.first['value'].toString(); }); }
  save() async { var db=await DBHelper.getDB(); await db.update('settings', {'value':d.text}, where: 'key=?', whereArgs: ['daily']); await db.update('settings', {'value':w.text}, where: 'key=?', whereArgs: ['weekly']); await db.update('settings', {'value':m.text}, where: 'key=?', whereArgs: ['monthly']); ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('সংরক্ষণ হয়েছে'))); }
  @override Widget build(BuildContext c)=> Scaffold(appBar: AppBar(title: const Text('মুনাফা / লাভ')), body: Padding(padding: const EdgeInsets.all(16), child: Column(children: [TextField(controller: d, decoration: const InputDecoration(labelText: 'দৈনিক %')), TextField(controller: w, decoration: const InputDecoration(labelText: 'সাপ্তাহিক %')), TextField(controller: m, decoration: const InputDecoration(labelText: 'মাসিক %')), ElevatedButton(onPressed: save, child: const Text('সংরক্ষণ'))])));
}

class LoanDistributionPage extends StatefulWidget { @override State<LoanDistributionPage> createState() => _LoanDistributionPageState(); }
class _LoanDistributionPageState extends State<LoanDistributionPage> {
  final amount=TextEditingController(); final date=TextEditingController(text: DateFormat('yyyy-MM-dd').format(DateTime.now())); String collectionType='মাসিক'; double interest=0,total=0; List<Map> members=[]; int? selMemberId; String? selMemberNo; String? selMemberName;
  @override void initState(){ super.initState(); _loadMembers(); calculate(); }
  _loadMembers() async { var db=await DBHelper.getDB(); var r=await db.query('members'); setState(()=> members=r); }
  calculate() async { var db=await DBHelper.getDB(); var res=await db.query('settings', where: 'key=?', whereArgs: [collectionType=='দৈনিক'?'daily':collectionType=='সাপ্তাহিক'?'weekly':'monthly']); double percent=double.tryParse(res.first['value'].toString())??0; double amt=double.tryParse(amount.text)??0; setState((){ interest=amt*percent/100; total=amt+interest; }); }
  @override Widget build(BuildContext c)=> Scaffold(appBar: AppBar(title: const Text('ঋণ বিতরণ'), actions: [IconButton(icon: const Icon(Icons.list_alt), onPressed: ()=> Navigator.push(c, MaterialPageRoute(builder: (_)=> LoanListPage())))]), body: SingleChildScrollView(padding: const EdgeInsets.all(16), child: Column(children: [DropdownButtonFormField(value: selMemberId, hint: const Text('সদস্য নির্বাচন'), items: members.map((m)=> DropdownMenuItem(value: m['id'] as int, child: Text('${m['member_no']} - ${m['name']}'))).toList(), onChanged: (v){ var mem=members.firstWhere((x)=> x['id']==v); setState((){ selMemberId=v as int; selMemberNo=mem['member_no']; selMemberName=mem['name']; }); }), TextField(controller: amount, decoration: const InputDecoration(labelText: 'ঋণের পরিমাণ'), keyboardType: TextInputType.number, onChanged: (_)=> calculate()), DropdownButtonFormField(value: collectionType, items: ['দৈনিক','সাপ্তাহিক','মাসিক'].map((e)=> DropdownMenuItem(value: e, child: Text(e))).toList(), onChanged: (v){ setState(()=> collectionType=v!); calculate(); }), const SizedBox(height: 12), Card(child: ListTile(title: const Text('মুনাফা'), trailing: Text('$interest টাকা'))), Card(color: Colors.green[100], child: ListTile(title: const Text('মোট পরিশোধযোগ্য', style: TextStyle(fontWeight: FontWeight.bold)), trailing: Text('$total টাকা'))), SizedBox(width: double.infinity, child: ElevatedButton(onPressed: () async { if(selMemberId==null) return; var db=await DBHelper.getDB(); await db.insert('loans', {'member_id':selMemberId,'member_no':selMemberNo,'member_name':selMemberName,'loan_amount':double.tryParse(amount.text)??0,'interest_amount':interest,'total_payable':total,'collection_type':collectionType,'loan_date':date.text}); ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('ঋণ সংরক্ষণ হয়েছে'))); }, child: const Text('ঋণ সংরক্ষণ')))])));
}

class BankPage extends StatefulWidget { @override State<BankPage> createState() => _BankPageState(); }
class _BankPageState extends State<BankPage> {
  String trType='জমা'; String partyType='মাঠকর্মী'; List<Map> parties=[]; int? partyId; String? partyName; final amt=TextEditingController(); final date=TextEditingController(text: DateFormat('yyyy-MM-dd').format(DateTime.now())); double balance=0;
  @override void initState(){ super.initState(); loadParties(); loadBalance(); }
  loadParties() async { var db=await DBHelper.getDB(); var r= partyType=='মাঠকর্মী'? await db.query('employees') : await db.query('members'); setState(()=> parties=r); }
  loadBalance() async { var db=await DBHelper.getDB(); var dep=await db.rawQuery("SELECT SUM(amount) as s FROM bank_transactions WHERE type='জমা'"); var wit=await db.rawQuery("SELECT SUM(amount) as s FROM bank_transactions WHERE type='উত্তোলন'"); double d=(dep.first['s'] as num?)?.toDouble()??0; double w=(wit.first['s'] as num?)?.toDouble()??0; setState(()=> balance=d-w); }
  @override Widget build(BuildContext c)=> Scaffold(appBar: AppBar(title: const Text('ব্যাংক লেনদেন'), actions: [IconButton(icon: const Icon(Icons.list), onPressed: ()=> Navigator.push(c, MaterialPageRoute(builder: (_)=> BankListPage())))]), body: SingleChildScrollView(padding: const EdgeInsets.all(16), child: Column(children: [Card(color: Colors.blue[100], child: ListTile(title: const Text('ব্যালেন্স'), subtitle: Text('$balance টাকা', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)))), DropdownButtonFormField(value: trType, items: ['জমা','উত্তোলন'].map((e)=> DropdownMenuItem(value: e, child: Text(e))).toList(), onChanged: (v)=> setState(()=> trType=v!)), DropdownButtonFormField(value: partyType, items: ['মাঠকর্মী','সদস্য'].map((e)=> DropdownMenuItem(value: e, child: Text(e))).toList(), onChanged: (v){ setState(()=> partyType=v!); loadParties(); }), DropdownButtonFormField(value: partyId, hint: const Text('নাম'), items: parties.map((p)=> DropdownMenuItem(value: p['id'] as int, child: Text(p['name']))).toList(), onChanged: (v){ setState((){ partyId=v as int; partyName=parties.firstWhere((x)=> x['id']==v)['name']; }); }), TextField(controller: amt, decoration: const InputDecoration(labelText: 'টাকা'), keyboardType: TextInputType.number), const SizedBox(height: 12), SizedBox(width: double.infinity, child: ElevatedButton(onPressed: () async { var
