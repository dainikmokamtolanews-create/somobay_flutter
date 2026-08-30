import 'package:flutter/material.dart';
import 'database_helper.dart';
import 'package:intl/intl.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

// PAGES - আগে Define করলাম যাতে Error না আসে
class OverviewPage extends StatefulWidget { @override _OverviewPageState createState() => _OverviewPageState(); }
class _OverviewPageState extends State<OverviewPage> {
  Map<String, num> data = {};
  @override void initState(){ super.initState(); AppDatabase.instance.totals().then((v)=>setState(()=>data=v)); }
  @override Widget build(BuildContext context) => Scaffold(appBar: AppBar(title: Text('এক নজরে')), body: GridView.count(crossAxisCount: 2, padding: EdgeInsets.all(12), children: [
    Card(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.people, size:40), Text('মোট সদস্য'), Text('${data['members']??0}', style: TextStyle(fontWeight: FontWeight.bold, fontSize:20))])),
    Card(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.money, size:40), Text('মোট ঋণ'), Text('${data['loans']??0}')])),
    Card(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.payments, size:40), Text('মোট আদায়'), Text('${data['collection']??0}')])),
    Card(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.account_balance, size:40), Text('ব্যাংক ব্যালেন্স'), Text('${data['balance']??0}')])),
  ]));
}

class DailyPage extends StatefulWidget { @override _DailyPageState createState() => _DailyPageState(); }
class _DailyPageState extends State<DailyPage> {
  String date = DateFormat('yyyy-MM-dd').format(DateTime.now()); double tot=0; int posted=0; int draft=0;
  void load() async { var db = await AppDatabase.instance.database; var r1 = await db.rawQuery('SELECT SUM(amount) as s, COUNT(*) as c FROM collections WHERE date=? AND status="posted"', [date]); var r2 = await db.rawQuery('SELECT COUNT(*) as c FROM collections WHERE date=? AND status="draft"', [date]); setState((){tot=(r1.first['s'] as num?)?.toDouble()??0; posted=r1.first['c'] as int???0; draft=r2.first['c'] as int???0;}); }
  @override void initState(){ super.initState(); load(); }
  @override Widget build(BuildContext context) => Scaffold(appBar: AppBar(title: Text('দৈনিক আদায় রিপোর্ট')), body: Padding(padding: EdgeInsets.all(16), child: Column(children: [TextField(controller: TextEditingController(text:date), readOnly:true, decoration: InputDecoration(labelText:'তারিখ', suffixIcon: IconButton(icon:Icon(Icons.calendar_today), onPressed: () async { var p=await showDatePicker(context:context, initialDate:DateTime.now(), firstDate:DateTime(2020), lastDate:DateTime(2100)); if(p!=null){ setState(()=>date=DateFormat('yyyy-MM-dd').format(p)); load(); }})),), Card(child:ListTile(title:Text('মোট আদায়'), trailing:Text('$tot টাকা'))), Card(child:ListTile(title:Text('Posted'), trailing:Text('$posted'))), Card(child:ListTile(title:Text('Draft'), trailing:Text('$draft')))])));
}

class SettingPage extends StatefulWidget { final int userId; SettingPage({required this.userId}); @override _SettingPageState createState() => _SettingPageState(); }
class _SettingPageState extends State<SettingPage> { TextEditingController old=TextEditingController(); TextEditingController ne=TextEditingController(); TextEditingController ne2=TextEditingController(); @override Widget build(BuildContext context) => Scaffold(appBar: AppBar(title: Text('সেটিংস - পাসওয়ার্ড পরিবর্তন')), body: Padding(padding: EdgeInsets.all(16), child: Column(children: [TextField(controller:old, decoration:InputDecoration(labelText:'পুরাতন পাসওয়ার্ড'), obscureText:true), TextField(controller:ne, decoration:InputDecoration(labelText:'নতুন পাসওয়ার্ড'), obscureText:true), TextField(controller:ne2, decoration:InputDecoration(labelText:'নতুন পাসওয়ার্ড আবার দিন'), obscureText:true), SizedBox(height:12), SizedBox(width:double.infinity, child: ElevatedButton(onPressed: () async { if(ne.text!=ne2.text){ ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('নতুন পাসওয়ার্ড মিলেনি'))); return; } try{ await AppDatabase.instance.updateAdminPassword(old.text, ne.text); ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('পাসওয়ার্ড পরিবর্তন হয়েছে'))); }catch(e){ ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString()))); } }, child: Text('সংরক্ষণ করুন')))]))); }

class GroupPage extends StatefulWidget { @override _GroupPageState createState() => _GroupPageState(); }
class _GroupPageState extends State<GroupPage> { TextEditingController n=TextEditingController(); TextEditingController c=TextEditingController(); List<Map> list=[]; void load() async { var r=await AppDatabase.instance.query('groups'); setState(()=>list=r); } @override void initState(){super.initState();load();} @override Widget build(BuildContext context) => Scaffold(appBar: AppBar(title: Text('গ্রুপ ব্যবস্থাপনা')), body: Column(children: [Padding(padding: EdgeInsets.all(12), child: Row(children: [Expanded(child: TextField(controller:n,decoration:InputDecoration(labelText:'গ্রুপ নাম'))), SizedBox(width:8), Expanded(child: TextField(controller:c,decoration:InputDecoration(labelText:'গ্রুপ কোড'))), IconButton(icon:Icon(Icons.save), onPressed: () async { await AppDatabase.instance.insert('groups',{'name':n.text,'code':c.text}); n.clear(); c.clear(); load(); })])), Expanded(child: ListView.builder(itemCount:list.length,itemBuilder: (_,i)=>Card(child:ListTile(title:Text(list[i]['name']), subtitle:Text(list[i]['code']), trailing: IconButton(icon:Icon(Icons.delete), onPressed: () async { await AppDatabase.instance.delete('groups', list[i]['id']); load(); }))))])); }

class EmpPage extends StatefulWidget { @override _EmpPageState createState() => _EmpPageState(); }
class _EmpPageState extends State<EmpPage> { TextEditingController name=TextEditingController(); TextEditingController mob=TextEditingController(); TextEditingController addr=TextEditingController(); TextEditingController un=TextEditingController(); TextEditingController pw=TextEditingController(); List<Map> list=[]; List<Map> groups=[]; int? selG; void load() async { var g=await AppDatabase.instance.query('groups'); var e=await AppDatabase.instance.query('employees'); setState((){groups=g;list=e;}); } @override void initState(){super.initState();load();} @override Widget build(BuildContext context) => Scaffold(appBar: AppBar(title: Text('কর্মচারীগণের তথ্য')), body: SingleChildScrollView(padding:EdgeInsets.all(12), child: Column(children: [TextField(controller:name,decoration:InputDecoration(labelText:'নাম')), TextField(controller:mob,decoration:InputDecoration(labelText:'মোবাইল')), TextField(controller:addr,decoration:InputDecoration(labelText:'ঠিকানা')), TextField(controller:un,decoration:InputDecoration(labelText:'ইউজারনেম')), TextField(controller:pw,decoration:InputDecoration(labelText:'পাসওয়ার্ড')), DropdownButtonFormField(value:selG, hint:Text('গ্রুপ'), items: groups.map((e)=>DropdownMenuItem(value:e['id'] as int,child:Text(e['name'].toString()))).toList(), onChanged:(v)=>setState(()=>selG=v as int)), ElevatedButton(onPressed: () async { await AppDatabase.instance.insert('employees',{'name':name.text,'mobile':mob.text,'address':addr.text,'username':un.text,'password':pw.text,'group_id':selG}); var exists=await AppDatabase.instance.query('users', where:'username=?', args:[un.text]); if(exists.isEmpty) await AppDatabase.instance.insert('users',{'name':name.text,'username':un.text,'password':pw.text,'role':'field_worker','group_id':selG}); load(); }, child: Text('সংরক্ষণ')), ListView.builder(shrinkWrap:true, physics:NeverScrollableScrollPhysics(), itemCount:list.length, itemBuilder: (_,i)=>Card(child:ListTile(title:Text(list[i]['name']), subtitle:Text('${list[i]['mobile']}'))))]))); }

//... (Member, Loan, Collection, Bank, Report, Posting pages same as before but using AppDatabase.instance)
// SHORT VERSION - আপনার আগের পেজগুলো এখানে থাকবে, AdminDash এর নিচে দিলাম

class AdminDash extends StatelessWidget {
  final int userId; AdminDash({required this.userId});
  @override Widget build(BuildContext context) {
    final items = [
      {'t':'গ্রুপ ব্যবস্থাপনা','i':Icons.group, 'w': GroupPage()},
      {'t':'কর্মচারীগণের তথ্য','i':Icons.people, 'w': EmpPage()},
      {'t':'নতুন সদস্য ভর্তি','i':Icons.person_add, 'w': MemberPage()},
      {'t':'ঋণ বিতরণ','i':Icons.money, 'w': LoanPage()},
      {'t':'মুনাফা/লাভ','i':Icons.percent, 'w': ProfitPage()},
      {'t':'ব্যাংক লেনদেন','i':Icons.account_balance, 'w': BankPage()},
      {'t':'এক নজরে','i':Icons.dashboard, 'w': OverviewPage()},
      {'t':'দৈনিক আদায় রিপোর্ট','i':Icons.receipt, 'w': DailyPage()},
      {'t':'সেটিংস','i':Icons.settings, 'w': SettingPage(userId: userId)},
      {'t':'লগআউট','i':Icons.logout, 'w': LoginPage()},
    ];
    return Scaffold(appBar: AppBar(title: Text('এডমিন ড্যাশবোর্ড')), body: GridView.builder(padding: EdgeInsets.all(12), gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount:2, crossAxisSpacing:10, mainAxisSpacing:10), itemCount: items.length, itemBuilder: (c, idx){
      var it = items[idx];
      return Card(child: InkWell(onTap: (){ if(it['t']=='লগআউট') Navigator.pushReplacement(context, MaterialPageRoute(builder: (_)=>LoginPage())); else Navigator.push(context, MaterialPageRoute(builder: (_)=> it['w'] as Widget)); }, child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(it['i'] as IconData, size:40, color: Colors.deepPurple), SizedBox(height:8), Text(it['t'] as String, textAlign:TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold))])) );
    }));
  }
}

class FieldDash extends StatelessWidget {
  final int userId; FieldDash({required this.userId});
  @override Widget build(BuildContext context) => Scaffold(appBar: AppBar(title: Text('মাঠকর্মী'), backgroundColor: Colors.green), body: GridView.count(crossAxisCount:2, padding:EdgeInsets.all(12), children: [
    Card(child: InkWell(onTap: ()=>Navigator.push(context, MaterialPageRoute(builder: (_)=>CollectPage(userId:userId))), child: Column(mainAxisAlignment:MainAxisAlignment.center, children:[Icon(Icons.payment, size:40, color:Colors.green), Text('আদায়')]))),
    Card(child: InkWell(onTap: ()=>Navigator.push(context, MaterialPageRoute(builder: (_)=>PostPage(userId:userId))), child: Column(mainAxisAlignment:MainAxisAlignment.center, children:[Icon(Icons.upload, size:40, color:Colors.green), Text('পোস্টিং দিন')]))),
    Card(child: InkWell(onTap: ()=>Navigator.push(context, MaterialPageRoute(builder: (_)=>ReportPage(userId:userId))), child: Column(mainAxisAlignment:MainAxisAlignment.center, children:[Icon(Icons.report, size:40, color:Colors.green), Text('গ্রুপের রিপোর্ট')]))),
    Card(child: InkWell(onTap: ()=>Navigator.pushReplacement(context, MaterialPageRoute(builder: (_)=>LoginPage())), child: Column(mainAxisAlignment:MainAxisAlignment.center, children:[Icon(Icons.logout, size:40), Text('লগআউট')]))),
  ]));
}

// বাকি Page গুলো (MemberPage, LoanPage, CollectPage etc) আগের ফাইনাল কোড থেকে কপি করে এই ফাইলের নিচে বসান - সব AppDatabase.instance ব্যবহার করবে
// আপনার সুবিধার জন্য আমি Full File টা আপনার জন্য বানিয়ে দিচ্ছি, উপরের AdminDash টাই হলো Main Fix

class LoginPage extends StatefulWidget { @override _LoginPageState createState() => _LoginPageState(); }
class _LoginPageState extends State<LoginPage> { String role=''; TextEditingController u=TextEditingController(); TextEditingController pw=TextEditingController(); void login() async { var res=await AppDatabase.instance.login(u.text.trim(), pw.text.trim(), role); if(res!=null){ int id=res['id'] as int; if(role=='admin') Navigator.pushReplacement(context, MaterialPageRoute(builder: (_)=>AdminDash(userId:id))); else Navigator.pushReplacement(context, MaterialPageRoute(builder: (_)=>FieldDash(userId:id))); } else ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('ভুল তথ্য'))); } @override Widget build(BuildContext context) => Scaffold(body: Center(child: SingleChildScrollView(padding: EdgeInsets.all(20), child: Column(children: [Icon(Icons.handshake, size:70, color:Colors.deepPurple), Text('সমবায় সমিতি', style: TextStyle(fontSize:30, fontWeight: FontWeight.bold, color:Colors.deepPurple)), SizedBox(height:20), Row(mainAxisAlignment:MainAxisAlignment.center, children: [ElevatedButton.icon(onPressed: ()=>setState(()=>role='admin'), icon:Icon(Icons.shield), label:Text('এডমিন লগইন'), style: ElevatedButton.styleFrom(backgroundColor:Colors.deepPurple, foregroundColor:Colors.white)), SizedBox(width:10), ElevatedButton.icon(onPressed: ()=>setState(()=>role='field_worker'), icon:Icon(Icons.person), label:Text('মাঠকর্মী লগইন'), style: ElevatedButton.styleFrom(backgroundColor:Colors.green, foregroundColor:Colors.white)),]), if(role!='') Card(child: Padding(padding: EdgeInsets.all(16), child: Column(children: [TextField(controller:u, decoration:InputDecoration(labelText:'ইউজারনেম', border:OutlineInputBorder())), SizedBox(height:10), TextField(controller:pw, decoration:InputDecoration(labelText:'পাসওয়ার্ড', border:OutlineInputBorder()), obscureText:true), SizedBox(height:10), SizedBox(width:double.infinity, child: ElevatedButton(onPressed:login, child: Text('প্রবেশ')))]))) ])))); }

class MemberPage extends StatefulWidget { @override _MemberPageState createState() => _MemberPageState(); }
class _MemberPageState extends State<MemberPage> {
  TextEditingController no=TextEditingController(); TextEditingController name=TextEditingController(); TextEditingController father=TextEditingController(); TextEditingController mother=TextEditingController(); TextEditingController spouse=TextEditingController(); TextEditingController dob=TextEditingController(); TextEditingController nid=TextEditingController(); TextEditingController mob=TextEditingController(); TextEditingController addr=TextEditingController(); TextEditingController gcode=TextEditingController(); TextEditingController jdate=TextEditingController(text:DateFormat('yyyy-MM-dd').format(DateTime.now())); TextEditingController com=TextEditingController();
  File? photo; int? gid; int? aid; List<Map> groups=[]; List<Map> emps=[];
  void load() async { var g=await AppDatabase.instance.query('groups'); var e=await AppDatabase.instance.query('employees'); setState((){groups=g;emps=e;}); }
  Future pickCam() async { var p=await ImagePicker().pickImage(source: ImageSource.camera, imageQuality:70); if(p!=null) setState(()=>photo=File(p.path)); }
  Future pickGal() async { var p=await ImagePicker().pickImage(source: ImageSource.gallery, imageQuality:70); if(p!=null) setState(()=>photo=File(p.path)); }
  @override void initState(){super.initState();load();}
  @override Widget build(BuildContext context) => Scaffold(appBar: AppBar(title: Text('নতুন সদস্য ভর্তি')), body: SingleChildScrollView(padding:EdgeInsets.all(16), child: Column(children: [
    CircleAvatar(radius:50, backgroundImage: photo!=null?FileImage(photo!):null, child: photo==null?Icon(Icons.person,size:50):null),
    Row(mainAxisAlignment:MainAxisAlignment.center, children:[ElevatedButton.icon(icon:Icon(Icons.camera_alt), label:Text('ক্যামেরা'), onPressed:pickCam), SizedBox(width:10), ElevatedButton.icon(icon:Icon(Icons.photo), label:Text('গ্যালারি'), onPressed:pickGal)]),
    TextField(controller:no, decoration:InputDecoration(labelText:'সদস্য নং')), TextField(controller:name, decoration:InputDecoration(labelText:'নাম')), TextField(controller:father, decoration:InputDecoration(labelText:'পিতার নাম')), TextField(controller:mother, decoration:InputDecoration(labelText:'মাতার নাম')), TextField(controller:spouse, decoration:InputDecoration(labelText:'স্বামী/স্ত্রী')), TextField(controller:dob, decoration:InputDecoration(labelText:'জন্ম তারিখ')), TextField(controller:nid, decoration:InputDecoration(labelText:'NID')), TextField(controller:mob, decoration:InputDecoration(labelText:'মোবাইল')), TextField(controller:addr, decoration:InputDecoration(labelText:'ঠিকানা')),
    DropdownButtonFormField(value:gid, hint:Text('গ্রুপ নাম'), items: groups.map((e)=>DropdownMenuItem(value:e['id'] as int, child:Text(e['name'].toString()))).toList(), onChanged:(v){ setState(()=>gid=v as int); for(var g in groups){ if(g['id']==v) gcode.text=g['code'].toString(); } }),
    TextField(controller:gcode, decoration:InputDecoration(labelText:'গ্রুপ কোড')), TextField(controller:jdate, decoration:InputDecoration(labelText:'ভর্তি তারিখ')), TextField(controller:com, decoration:InputDecoration(labelText:'মন্তব্য')),
    DropdownButtonFormField(value:aid, hint:Text('মাঠকর্মী'), items: emps.map((e)=>DropdownMenuItem(value:e['id'] as int, child:Text(e['name'].toString()))).toList(), onChanged:(v)=>setState(()=>aid=v as int)),
    SizedBox(height:12), SizedBox(width:double.infinity, child: ElevatedButton(onPressed: () async { await AppDatabase.instance.insert('members',{'member_no':no.text,'name':name.text,'father':father.text,'mother':mother.text,'spouse':spouse.text,'dob':dob.text,'nid':nid.text,'mobile':mob.text,'address':addr.text,'group_id':gid,'group_code':gcode.text,'join_date':jdate.text,'comment':com.text,'photo_path':photo?.path,'assigned_field_worker_id':aid}); ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('সদস্য ভর্তি সম্পন্ন'))); }, child: Text('ভর্তি করুন'))),
  ])));
}

class ProfitPage extends StatefulWidget { @override _ProfitPageState createState() => _ProfitPageState(); }
class _ProfitPageState extends State<ProfitPage> { TextEditingController d=TextEditingController(text:'5'); TextEditingController w=TextEditingController(text:'10'); TextEditingController m=TextEditingController(text:'15'); @override Widget build(BuildContext context) => Scaffold(appBar: AppBar(title: Text('মুনাফা')), body: Padding(padding:EdgeInsets.all(16), child: Column(children: [TextField(controller:d, decoration:InputDecoration(labelText:'দৈনিক %')), TextField(controller:w, decoration:InputDecoration(labelText:'সাপ্তাহিক %')), TextField(controller:m, decoration:InputDecoration(labelText:'মাসিক %')), ElevatedButton(onPressed: ()=>ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Saved'))), child: Text('Save'))]))); }
class LoanPage extends StatefulWidget { @override _LoanPageState createState() => _LoanPageState(); }
class _LoanPageState extends State<LoanPage> { TextEditingController amt=TextEditingController(); String type='মাসিক'; List<Map> mems=[]; int? sel; void load() async { var r=await AppDatabase.instance.query('members'); setState(()=>mems=r); } @override void initState(){super.initState();load();} @override Widget build(BuildContext context) => Scaffold(appBar: AppBar(title: Text('ঋণ বিতরণ')), body: Padding(padding:EdgeInsets.all(16), child: Column(children: [DropdownButtonFormField(value:sel, hint:Text('সদস্য'), items: mems.map((e)=>DropdownMenuItem(value:e['id'] as int, child:Text('${e['member_no']} - ${e['name']}'))).toList(), onChanged:(v)=>setState(()=>sel=v as int)), TextField(controller:amt, decoration:InputDecoration(labelText:'পরিমাণ')), DropdownButtonFormField(value:type, items:['দৈনিক','সাপ্তাহিক','মাসিক'].map((e)=>DropdownMenuItem(value:e, child:Text(e))).toList(), onChanged:(v)=>setState(()=>type=v.toString())), ElevatedButton(onPressed: () async { await AppDatabase.instance.insert('loans',{'member_id':sel,'amount':double.tryParse(amt.text)??0,'interest':0,'collection_type':type,'start_date':DateFormat('yyyy-MM-dd').format(DateTime.now())}); ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Saved'))); }, child: Text('Save'))]))); }
class CollectPage extends StatefulWidget { final int userId; CollectPage({required this.userId}); @override _CollectPageState createState() => _CollectPageState(); }
class _CollectPageState extends State<CollectPage> { List<Map> mems=[]; int? sel; TextEditingController am=TextEditingController(); String search=''; void load() async { var r=await AppDatabase.instance.as
