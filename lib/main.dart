import 'dart:io';
import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart' as p;
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

void main() => runApp(SomobayApp());

class SomobayApp extends StatelessWidget {
  @override Widget build(BuildContext context) {
    return MaterialApp(
      title: 'সমবায় সমিতি',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(primarySwatch: Colors.deepPurple, scaffoldBackgroundColor: Color(0xFFF5F0FF), cardTheme: CardThemeData(elevation: 2, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)))),
      home: LoginPage(),
    );
  }
}

class DBHelper {
  static Database? _db;
  static Future<Database> getDB() async {
    if(_db!=null) return _db!;
    String path = p.join(await getDatabasesPath(), 'somobay_final.db');
    _db = await openDatabase(path, version: 1, onCreate: (db, v) async {
      await db.execute('CREATE TABLE users(id INTEGER PRIMARY KEY, username TEXT, password TEXT, role TEXT)');
      await db.execute('CREATE TABLE groups(id INTEGER PRIMARY KEY AUTOINCREMENT, name TEXT, code TEXT)');
      await db.execute('CREATE TABLE employees(id INTEGER PRIMARY KEY AUTOINCREMENT, name TEXT, mobile TEXT, address TEXT, username TEXT, password TEXT, group_name TEXT)');
      await db.execute('CREATE TABLE members(id INTEGER PRIMARY KEY AUTOINCREMENT, member_no TEXT, name TEXT, father TEXT, mother TEXT, spouse TEXT, dob TEXT, nid TEXT, mobile TEXT, address TEXT, group_name TEXT, group_code TEXT, join_date TEXT, comment TEXT, photo_path TEXT, assigned_id INTEGER, assigned_name TEXT)');
      await db.execute('CREATE TABLE loans(id INTEGER PRIMARY KEY AUTOINCREMENT, member_id INTEGER, member_no TEXT, member_name TEXT, amount REAL, interest REAL, total REAL, type TEXT, date TEXT)');
      await db.execute('CREATE TABLE collections(id INTEGER PRIMARY KEY AUTOINCREMENT, member_id INTEGER, member_no TEXT, member_name TEXT, father TEXT, group_name TEXT, amount REAL, date TEXT, status TEXT, worker_id INTEGER)');
      await db.execute('CREATE TABLE bank_tx(id INTEGER PRIMARY KEY AUTOINCREMENT, tx_type TEXT, party_type TEXT, party_name TEXT, amount REAL, date TEXT)');
      await db.execute('CREATE TABLE settings(key TEXT PRIMARY KEY, value TEXT)');
      await db.insert('users', {'username':'admin','password':'123456','role':'admin'});
      await db.insert('users', {'username':'field','password':'1234','role':'field_worker'});
      await db.insert('settings', {'key':'daily','value':'5'});
      await db.insert('settings', {'key':'weekly','value':'10'});
      await db.insert('settings', {'key':'monthly','value':'15'});
    });
    return _db!;
  }
}

// LOGIN
class LoginPage extends StatefulWidget { @override _LoginPageState createState() => _LoginPageState(); }
class _LoginPageState extends State<LoginPage> {
  String role=''; TextEditingController u=TextEditingController(); TextEditingController pw=TextEditingController();
  void login() async {
    var db=await DBHelper.getDB();
    var r=await db.query('users', where: 'username=? AND password=? AND role=?', whereArgs: [u.text.trim(), pw.text.trim(), role]);
    if(r.isNotEmpty){ int id=r.first['id'] as int; if(role=='admin') Navigator.pushReplacement(context, MaterialPageRoute(builder: (_)=>AdminDash(userId:id))); else Navigator.pushReplacement(context, MaterialPageRoute(builder: (_)=>FieldDash(userId:id))); }
    else ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('ভুল তথ্য')));
  }
  @override Widget build(BuildContext context) => Scaffold(body: Center(child: SingleChildScrollView(padding: EdgeInsets.all(20), child: Column(children: [
    Icon(Icons.handshake, size:70, color: Colors.deepPurple), Text('সমবায় সমিতি', style: TextStyle(fontSize:30, fontWeight: FontWeight.bold, color: Colors.deepPurple)), SizedBox(height:20),
    Row(mainAxisAlignment: MainAxisAlignment.center, children: [
      ElevatedButton.icon(onPressed: ()=>setState(()=>role='admin'), icon: Icon(Icons.shield), label: Text('এডমিন লগইন'), style: ElevatedButton.styleFrom(backgroundColor: Colors.deepPurple, foregroundColor: Colors.white, side: BorderSide(color: role=='admin'?Colors.yellow:Colors.transparent, width:2))),
      SizedBox(width:10),
      ElevatedButton.icon(onPressed: ()=>setState(()=>role='field_worker'), icon: Icon(Icons.person), label: Text('মাঠকর্মী লগইন'), style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white, side: BorderSide(color: role=='field_worker'?Colors.yellow:Colors.transparent, width:2))),
    ]),
    if(role!='') Card(child: Padding(padding: EdgeInsets.all(16), child: Column(children: [
      TextField(controller: u, decoration: InputDecoration(labelText: 'ইউজারনেম', border: OutlineInputBorder())), SizedBox(height:10),
      TextField(controller: pw, decoration: InputDecoration(labelText: 'পাসওয়ার্ড', border: OutlineInputBorder()), obscureText: true), SizedBox(height:10),
      SizedBox(width: double.infinity, child: ElevatedButton(onPressed: login, child: Text('প্রবেশ'))),
    ]))),
  ]))));
}

// ADMIN DASH - 11 BUTTONS
class AdminDash extends StatelessWidget {
  final int userId; AdminDash({required this.userId});
  @override Widget build(BuildContext context) {
    var items=[
      {'t':'গ্রুপ ব্যবস্থাপনা','i':Icons.group,'w':GroupPage()},
      {'t':'কর্মচারীগণের তথ্য','i':Icons.people,'w':EmpPage()},
      {'t':'নতুন সদস্য ভর্তি','i':Icons.person_add,'w':MemberPage()},
      {'t':'ঋণ বিতরণ','i':Icons.money,'w':LoanPage()},
      {'t':'মুনাফা/লাভ','i':Icons.percent,'w':ProfitPage()},
      {'t':'ব্যাংক লেনদেন','i':Icons.account_balance,'w':BankPage()},
      {'t':'এক নজরে','i':Icons.dashboard,'w':OverviewPage()},
      {'t':'দৈনিক আদায় রিপোর্ট','i':Icons.receipt,'w':DailyPage()},
      {'t':'সেটিংস','i':Icons.settings,'w':SettingPage(userId:userId)},
      {'t':'লগআউট','i':Icons.logout,'w':LoginPage()},
    ];
    return Scaffold(appBar: AppBar(title: Text('এডমিন ড্যাশবোর্ড - আদায় করতে পারবে না')), body: GridView.builder(padding: EdgeInsets.all(12), gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount:2, crossAxisSpacing:10, mainAxisSpacing:10), itemCount: items.length, itemBuilder: (c, idx){
      var it=items[idx]; return Card(child: InkWell(onTap: (){ if(it['t']=='লগআউট') Navigator.pushReplacement(context, MaterialPageRoute(builder: (_)=>LoginPage())); else Navigator.push(context, MaterialPageRoute(builder: (_)=>it['w'] as Widget)); }, child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(it['i'] as IconData, size:40, color: Colors.deepPurple), SizedBox(height:8), Text(it['t'] as String, textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold))])) );
    }));
  }
}

class FieldDash extends StatelessWidget {
  final int userId; FieldDash({required this.userId});
  @override Widget build(BuildContext context) => Scaffold(appBar: AppBar(title: Text('মাঠকর্মী ড্যাশবোর্ড'), backgroundColor: Colors.green), body: GridView.count(crossAxisCount:2, padding: EdgeInsets.all(12), children: [
    _b(context,'আদায়',Icons.payment, CollectPage(userId:userId)),
    _b(context,'পোস্টিং দিন',Icons.upload, PostPage(userId:userId)),
    _b(context,'গ্রুপের রিপোর্ট',Icons.report, ReportPage(userId:userId)),
    _b(context,'লগআউট',Icons.logout,LoginPage(), logout:true),
  ]));
  Widget _b(BuildContext ctx,String t,IconData ic,Widget w,{bool logout=false}) => Card(child: InkWell(onTap: (){ if(logout) Navigator.pushReplacement(ctx, MaterialPageRoute(builder: (_)=>LoginPage())); else Navigator.push(ctx, MaterialPageRoute(builder: (_)=>w)); }, child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(ic,size:40,color:Colors.green), Text(t,style:TextStyle(fontWeight: FontWeight.bold))]) ));
}

// 1. GROUP
class GroupPage extends StatefulWidget { @override _GroupPageState createState() => _GroupPageState(); }
class _GroupPageState extends State<GroupPage> { TextEditingController n=TextEditingController(); TextEditingController c=TextEditingController(); List<Map> list=[]; void load() async { var db=await DBHelper.getDB(); var r=await db.query('groups'); setState(()=>list=r); } @override void initState(){super.initState();load();} @override Widget build(BuildContext context) => Scaffold(appBar: AppBar(title: Text('গ্রুপ ব্যবস্থাপনা')), body: Column(children: [Padding(padding: EdgeInsets.all(12), child: Row(children: [Expanded(child: TextField(controller:n,decoration:InputDecoration(labelText:'গ্রুপ নাম'))), SizedBox(width:8), Expanded(child: TextField(controller:c,decoration:InputDecoration(labelText:'গ্রুপ কোড'))), IconButton(icon:Icon(Icons.save), onPressed: () async { var db=await DBHelper.getDB(); await db.insert('groups',{'name':n.text,'code':c.text}); n.clear(); c.clear(); load(); })])), Expanded(child: ListView.builder(itemCount:list.length,itemBuilder: (_,i)=>Card(child:ListTile(title:Text(list[i]['name']), subtitle:Text(list[i]['code']), trailing: IconButton(icon:Icon(Icons.delete), onPressed: () async { var db=await DBHelper.getDB(); await db.delete('groups',where:'id=?',whereArgs:[list[i]['id']]); load(); })))))])); }

// 2. EMP
class EmpPage extends StatefulWidget { @override _EmpPageState createState() => _EmpPageState(); }
class _EmpPageState extends State<EmpPage> { TextEditingController name=TextEditingController(); TextEditingController mob=TextEditingController(); TextEditingController addr=TextEditingController(); TextEditingController un=TextEditingController(); TextEditingController pw=TextEditingController(); List<Map> list=[]; List<Map> groups=[]; String? selG; void load() async { var db=await DBHelper.getDB(); var g=await db.query('groups'); var e=await db.query('employees'); setState((){groups=g;list=e;}); } @override void initState(){super.initState();load();} @override Widget build(BuildContext context) => Scaffold(appBar: AppBar(title: Text('কর্মচারীগণের তথ্য')), body: SingleChildScrollView(padding:EdgeInsets.all(12), child: Column(children: [TextField(controller:name,decoration:InputDecoration(labelText:'নাম')), TextField(controller:mob,decoration:InputDecoration(labelText:'মোবাইল')), TextField(controller:addr,decoration:InputDecoration(labelText:'ঠিকানা')), TextField(controller:un,decoration:InputDecoration(labelText:'ইউজারনেম')), TextField(controller:pw,decoration:InputDecoration(labelText:'পাসওয়ার্ড')), DropdownButtonFormField(value:selG,hint:Text('গ্রুপ অ্যাসাইন'), items: groups.map((e)=>DropdownMenuItem(value:e['name'].toString(),child:Text(e['name'].toString()))).toList(), onChanged:(v)=>setState(()=>selG=v.toString())), ElevatedButton(onPressed: () async { var db=await DBHelper.getDB(); await db.insert('employees',{'name':name.text,'mobile':mob.text,'address':addr.text,'username':un.text,'password':pw.text,'group_name':selG}); var exists=await db.query('users',where:'username=?',whereArgs:[un.text]); if(exists.isEmpty) await db.insert('users',{'username':un.text,'password':pw.text,'role':'field_worker'}); load(); }, child: Text('সংরক্ষণ')), ListView.builder(shrinkWrap:true, physics:NeverScrollableScrollPhysics(), itemCount:list.length, itemBuilder: (_,i)=>Card(child:ListTile(title:Text(list[i]['name']), subtitle:Text('${list[i]['group_name']} - ${list[i]['mobile']}'))))]))); }

// 3. MEMBER 13 FIELDS + PHOTO
class MemberPage extends StatefulWidget { @override _MemberPageState createState() => _MemberPageState(); }
class _MemberPageState extends State<MemberPage> {
  TextEditingController no=TextEditingController(); TextEditingController name=TextEditingController(); TextEditingController father=TextEditingController(); TextEditingController mother=TextEditingController(); TextEditingController spouse=TextEditingController(); TextEditingController dob=TextEditingController(); TextEditingController nid=TextEditingController(); TextEditingController mob=TextEditingController(); TextEditingController addr=TextEditingController(); TextEditingController gname=TextEditingController(); TextEditingController gcode=TextEditingController(); TextEditingController jdate=TextEditingController(text: DateFormat('yyyy-MM-dd').format(DateTime.now())); TextEditingController comment=TextEditingController();
  File? photo; List<Map> emps=[]; int? aid; String? aname; List<Map> groups=[];
  void load() async { var db=await DBHelper.getDB(); var e=await db.query('employees'); var g=await db.query('groups'); setState((){emps=e;groups=g;}); }
  Future pickCam() async { var p=await ImagePicker().pickImage(source: ImageSource.camera, imageQuality:70); if(p!=null) setState(()=>photo=File(p.path)); }
  Future pickGal() async { var p=await ImagePicker().pickImage(source: ImageSource.gallery, imageQuality:70); if(p!=null) setState(()=>photo=File(p.path)); }
  @override void initState(){super.initState();load();}
  @override Widget build(BuildContext context) => Scaffold(appBar: AppBar(title: Text('নতুন সদস্য ভর্তি - 13 ফিল্ড')), body: SingleChildScrollView(padding: EdgeInsets.all(16), child: Column(children: [
    CircleAvatar(radius:50, backgroundImage: photo!=null?FileImage(photo!):null, child: photo==null?Icon(Icons.person,size:50):null),
    Row(mainAxisAlignment: MainAxisAlignment.center, children: [ElevatedButton.icon(icon:Icon(Icons.camera_alt),label:Text('ক্যামেরা'),onPressed:pickCam), SizedBox(width:10), ElevatedButton.icon(icon:Icon(Icons.photo),label:Text('গ্যালারি'),onPressed:pickGal)]),
    SizedBox(height:10),
    TextField(controller:no,decoration:InputDecoration(labelText:'সদস্য নং')), TextField(controller:name,decoration:InputDecoration(labelText:'নাম')), TextField(controller:father,decoration:InputDecoration(labelText:'পিতার নাম')), TextField(controller:mother,decoration:InputDecoration(labelText:'মাতার নাম')), TextField(controller:spouse,decoration:InputDecoration(labelText:'স্বামী/স্ত্রী')), TextField(controller:dob,decoration:InputDecoration(labelText:'জন্ম তারিখ', suffixIcon: IconButton(icon:Icon(Icons.calendar_today), onPressed: () async { var p=await showDatePicker(context:context,initialDate:DateTime.now(),firstDate:DateTime(1950),lastDate:DateTime.now()); if(p!=null) setState(()=>dob.text=DateFormat('yyyy-MM-dd').format(p)); }))), TextField(controller:nid,decoration:InputDecoration(labelText:'NID')), TextField(controller:mob,decoration:InputDecoration(labelText:'মোবাইল')), TextField(controller:addr,decoration:InputDecoration(labelText:'ঠিকানা')),
    DropdownButtonFormField(value: gname.text.isEmpty?null:gname.text, hint:Text('গ্রুপ নাম'), items: groups.map((e)=>DropdownMenuItem(value:e['name'].toString(),child:Text(e['name'].toString()))).toList(), onChanged:(v){ setState((){gname.text=v.toString(); for(var g in groups){ if(g['name']==v) gcode.text=g['code'].toString(); }}); }),
    TextField(controller:gcode,decoration:InputDecoration(labelText:'গ্রুপ কোড')), TextField(controller:jdate,decoration:InputDecoration(labelText:'ভর্তি তারিখ')), TextField(controller:comment,decoration:InputDecoration(labelText:'মন্তব্য')),
    DropdownButtonFormField(value:aid, hint:Text('মাঠকর্মী অ্যাসাইন'), items: emps.map((e)=>DropdownMenuItem(value:e['id'] as int,child:Text(e['name'].toString()))).toList(), onChanged:(v){ setState(()=>aid=v as int); for(var e in emps){ if(e['id']==v) aname=e['name'].toString(); } }),
    SizedBox(height:12), SizedBox(width:double.infinity, child: ElevatedButton(onPressed: () async { var db=await DBHelper.getDB(); await db.insert('members',{'member_no':no.text,'name':name.text,'father':father.text,'mother':mother.text,'spouse':spouse.text,'dob':dob.text,'nid':nid.text,'mobile':mob.text,'address':addr.text,'group_name':gname.text,'group_code':gcode.text,'join_date':jdate.text,'comment':comment.text,'photo_path':photo?.path,'assigned_id':aid,'assigned_name':aname}); ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('সদস্য ভর্তি সম্পন্ন'))); }, child: Text('ভর্তি করুন'))),
  ])));
}

// 4. LOAN
class LoanPage extends StatefulWidget { @override _LoanPageState createState() => _LoanPageState(); }
class _LoanPageState extends State<LoanPage> {
  TextEditingController amt=TextEditingController(); TextEditingController date=TextEditingController(text:DateFormat('yyyy-MM-dd').format(DateTime.now())); String type='মাসিক'; double inter=0; double tot=0; List<Map> mems=[]; int? selId; String? selNo; String? selName; String search='';
  void load() async { var db=await DBHelper.getDB(); var r=await db.query('members'); setState(()=>mems=r); }
  void calc() async { var db=await DBHelper.getDB(); String k=type=='দৈনিক'?'daily':type=='সাপ্তাহিক'?'weekly':'monthly'; var rs=await db.query('settings',where:'key=?',whereArgs:[k]); double per=double.tryParse(rs.first['value'].toString())??0; double a=double.tryParse(amt.text)??0; setState((){inter=a*per/100;tot=a+inter;}); }
  @override void initState(){super.initState();load();}
  @override Widget build(BuildContext context) {
    var filtered=mems.where((m)=>m['name'].toString().contains(search) || m['member_no'].toString().contains(search)).toList();
    return Scaffold(appBar: AppBar(title: Text('ঋণ বিতরণ - ADMIN ONLY'), actions: [IconButton(icon:Icon(Icons.list), onPressed: ()=>Navigator.push(context, MaterialPageRoute(builder: (_)=>LoanListPage())))]), body: SingleChildScrollView(padding:EdgeInsets.all(16), child: Column(children: [
      TextField(decoration:InputDecoration(labelText:'Search নাম/সদস্য নং', prefixIcon:Icon(Icons.search)), onChanged:(v)=>setState(()=>search=v)),
      DropdownButtonFormField(value:selId, hint:Text('সদস্য নির্বাচন'), items: filtered.map((e)=>DropdownMenuItem(value:e['id'] as int,child:Text('${e['member_no']} - ${e['name']}'))).toList(), onChanged:(v){ setState(()=>selId=v as int); for(var e in mems){ if(e['id']==v){ selNo=e['member_no'].toString(); selName=e['name'].toString(); } } }),
      TextField(controller:amt,decoration:InputDecoration(labelText:'ঋণের পরিমাণ'), keyboardType:TextInputType.number, onChanged:(v)=>calc()),
      DropdownButtonFormField(value:type, items:['দৈনিক','সাপ্তাহিক','মাসিক'].map((e)=>DropdownMenuItem(value:e,child:Text(e))).toList(), onChanged:(v){ setState(()=>type=v.toString()); calc(); }),
      TextField(controller:date,decoration:InputDecoration(labelText:'শুরুর তারিখ')),
      Card(child:ListTile(title:Text('মুনাফা'),trailing:Text('$inter'))), Card(color:Colors.green[100],child:ListTile(title:Text('মোট'),trailing:Text('$tot'))),
      SizedBox(width:double.infinity, child: ElevatedButton(onPressed: () async { var db=await DBHelper.getDB(); await db.insert('loans',{'member_id':selId,'member_no':selNo,'member_name':selName,'amount':double.tryParse(amt.text)??0,'interest':inter,'total':tot,'type':type,'date':date.text}); ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('ঋণ সংরক্ষণ'))); }, child: Text('সংরক্ষণ'))),
    ])));
  }
}
class LoanListPage extends StatefulWidget { @override _LoanListPageState createState() => _LoanListPageState(); }
class _LoanListPageState extends State<LoanListPage> { List<Map> list=[]; void load() async { var db=await DBHelper.getDB(); var r=await db.query('loans',orderBy:'id DESC'); setState(()=>list=r); } @override void initState(){super.initState();load();} @override Widget build(BuildContext context) => Scaffold(appBar: AppBar(title: Text('ঋণ তালিকা')), body: ListView.builder(itemCount:list.length,itemBuilder: (_,i)=>Card(child:ListTile(title:Text('${list[i]['member_no']} - ${list[i]['member_name']}'),subtitle:Text('মোট: ${list[i]['total']} | ${list[i]['type']}'),trailing:Text(list[i]['date'].toString()))))); }

// 5. COLLECTION - FIELD ONLY
class CollectPage extends StatefulWidget { final int userId; CollectPage({required this.userId}); @override _CollectPageState createState() => _CollectPageState(); }
class _CollectPageState extends State<CollectPage> {
  List<Map> mems=[]; List<Map> loans=[]; int? selId; String? selN
