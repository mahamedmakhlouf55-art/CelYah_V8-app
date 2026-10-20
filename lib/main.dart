
import 'dart:async';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:flutter_tts/flutter_tts.dart';
import 'package:flutter/material.dart';
import 'robot_link.dart';

void main() { WidgetsFlutterBinding.ensureInitialized(); runApp(const CelyahApp()); }
const bg = Color(0xFF0D0B15), panel = Color(0xFF1B1629);
const lavender = Color(0xFFF08DEB), soft = Color(0xFFB9AEC9);

class CelyahApp extends StatelessWidget {
  const CelyahApp({super.key});
  @override Widget build(BuildContext context) => MaterialApp(
    debugShowCheckedModeBanner:false, title:'Celyah Robot',
    theme:ThemeData(useMaterial3:true,brightness:Brightness.dark,
      scaffoldBackgroundColor:bg,colorScheme:ColorScheme.fromSeed(seedColor:lavender,brightness:Brightness.dark),
      fontFamily:'sans-serif', inputDecorationTheme:InputDecorationTheme(
      filled:true,fillColor:panel,border:OutlineInputBorder(borderRadius:BorderRadius.circular(22),borderSide:BorderSide.none))),
    home:const Dashboard());
}
class Dashboard extends StatefulWidget {
  const Dashboard({super.key});
  @override State<Dashboard> createState()=>_DashboardState();
}
class _DashboardState extends State<Dashboard> {
  final RobotLink link=RobotLink();
  final TextEditingController chat=TextEditingController();
  final TextEditingController camera=TextEditingController(text:'http://192.168.1.100');
  StreamSubscription<String>? incoming;
  int tab=0;
  bool busy=false;
  final stt.SpeechToText speech = stt.SpeechToText();
  final FlutterTts tts = FlutterTts();
  bool listening=false;
  String robotState='idle';
  bool speakReplies=true;
  Future<void> listen() async {
    if(listening){await speech.stop();if(mounted)setState(()=>listening=false);return;}
    final ok=await speech.initialize(onError:(e){if(mounted){setState(()=>listening=false);_notice('الميكروفون: $e');}},
      onStatus:(status){if(mounted&&status=='done')setState(()=>listening=false);});
    if(!ok){_notice('التعرف على الكلام غير متاح على الجهاز');return;}
    if(link.connected) await link.sendState('listening');
    setState((){listening=true;face='curious';robotState='listening';});
    await speech.listen(localeId:'ar_EG',onResult:(r){
      if(mounted){setState(()=>chat.text=r.recognizedWords);}
      if(r.finalResult){setState(()=>listening=false);_chat();}
    });
  }
  Future<void> readAloud(String text) async {
    if(!speakReplies)return;
    await tts.setLanguage('ar-EG');
    await tts.setSpeechRate(.48);
    await tts.speak(text);
  }

  final List<(bool,String)> messages=[(false,'أهلاً! أنا Celyah 💜 اتصلي بيا عشان نبدأ مغامرتنا.')];
  String face='normal';
  @override void initState(){super.initState();link.addListener(_refresh);
    incoming=link.lines.listen((line){if(!mounted)return;
      setState((){messages.add((false,line));face='happy';robotState='speaking';});
      if(!line.startsWith('BAT:')) readAloud(line);
    });}
  void _refresh(){if(mounted)setState((){});}
  Future<void> command(String cmd) async {
    if(!link.connected){_notice('وصّلي الروبوت بالبلوتوث الأول');return;}
    try{await link.send(cmd);_notice('تم إرسال الأمر: $cmd');}
    catch(e){_notice('فشل إرسال الأمر: $e');}
  }
  Widget _brand()=>Row(mainAxisSize:MainAxisSize.min,children:[
    const Text('Celyah',style:TextStyle(fontSize:31,fontWeight:FontWeight.w800,letterSpacing:-1.8)),
    const Text('♡',style:TextStyle(color:lavender,fontSize:29)),
    const SizedBox(width:9),
    const Text('R O B O T',style:TextStyle(color:soft,fontSize:9,letterSpacing:1.2))
  ]);
  void _notice(String s){if(mounted)ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text(s)));}
  Future<void> _chat() async {
    final s=chat.text.trim();if(s.isEmpty)return;
    setState((){messages.add((true,s));chat.clear();});
    if(!link.connected){setState(()=>messages.add((false,'الروبوت غير متصل. اتصلي به أولاً.')));return;}
    try{await link.send(s);}catch(e){setState(()=>messages.add((false,'تعذّر الإرسال: $e')));}
  }
  @override void dispose(){speech.cancel();tts.stop();incoming?.cancel();link.removeListener(_refresh);link.dispose();chat.dispose();camera.dispose();super.dispose();}
  Widget _card(Widget child,{EdgeInsets? pad})=>Container(
    padding:pad??const EdgeInsets.all(20),decoration:BoxDecoration(color:panel,borderRadius:BorderRadius.circular(26),
      border:Border.all(color:lavender.withValues(alpha:.12))),child:child);
  Widget _button(String label,IconData icon,VoidCallback tap,{bool primary=false})=>FilledButton.icon(
    onPressed:tap,icon:Icon(icon,size:19),label:Text(label),
    style:FilledButton.styleFrom(backgroundColor:primary?lavender:const Color(0xFF30253F),
      foregroundColor:primary?bg:Colors.white,padding:const EdgeInsets.symmetric(horizontal:17,vertical:14)));
  Widget _title(String t,String subtitle)=>Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
    Text(t,style:const TextStyle(fontSize:25,fontWeight:FontWeight.w700)),
    const SizedBox(height:5),Text(subtitle,style:const TextStyle(color:soft)),const SizedBox(height:20)]);
  @override Widget build(BuildContext context)=>Scaffold(
    appBar:AppBar(backgroundColor:bg,toolbarHeight:76,
      title:_brand(),
      actions:[Padding(padding:const EdgeInsets.only(right:16),child:Icon(link.connected?Icons.bluetooth_connected:Icons.bluetooth_disabled,
        color:link.connected?lavender:soft))]),
    body:SafeArea(child:IndexedStack(index:tab,children:[_home(),_messages(),_vision(),_control(),_settings()])),
    bottomNavigationBar:NavigationBar(backgroundColor:panel,indicatorColor:lavender.withValues(alpha:.22),
      selectedIndex:tab,onDestinationSelected:(v)=>setState(()=>tab=v),
      destinations:const [
        NavigationDestination(icon:Icon(Icons.favorite_border),selectedIcon:Icon(Icons.favorite),label:'Celyah'),
        NavigationDestination(icon:Icon(Icons.chat_bubble_outline),label:'شات'),
        NavigationDestination(icon:Icon(Icons.visibility_outlined),label:'الرؤية'),
        NavigationDestination(icon:Icon(Icons.gamepad_outlined),label:'تحكم'),
        NavigationDestination(icon:Icon(Icons.tune),label:'إعدادات'),
      ]));
  Widget _home()=>ListView(padding:const EdgeInsets.all(18),children:[
    _card(Column(children:[
      Container(width:260,height:235,decoration:BoxDecoration(color:Colors.black,borderRadius:BorderRadius.circular(36),
        border:Border.all(color:lavender.withValues(alpha:.45),width:2),
        boxShadow:[BoxShadow(color:lavender.withValues(alpha:.12),blurRadius:30)]),
        child:CustomPaint(painter:EyePainter(face))),
      const SizedBox(height:20),
      const Text('Hi! I’m Celyah ♡',style:TextStyle(fontSize:23,fontWeight:FontWeight.w700)),
      const SizedBox(height:5),
      const Text('Your little companion with a big heart',textAlign:TextAlign.center,
        style:TextStyle(color:soft,fontSize:13)),
      const SizedBox(height:18),
      Row(mainAxisAlignment:MainAxisAlignment.center,children:[
        Icon(Icons.circle,size:10,color:link.connected?Colors.greenAccent:Colors.orangeAccent),
        const SizedBox(width:8),Text(link.status),
      ]),
      const SizedBox(height:14),
      _button(link.connected?'فصل الاتصال':'اتصال بالروبوت',Icons.bluetooth,
        ()async{if(link.connected){await link.disconnect();}else{await link.connect();}},primary:true)
    ])),
    const SizedBox(height:18),
    Row(children:[
      Expanded(child:_quickTile('Talk',Icons.mic,()=>setState(()=>tab=1))),
      const SizedBox(width:8),
      Expanded(child:_quickTile('Vision',Icons.visibility_outlined,()=>setState(()=>tab=2))),
      const SizedBox(width:8),
      Expanded(child:_quickTile('Control',Icons.gamepad_outlined,()=>setState(()=>tab=3))),
    ]),
    const SizedBox(height:22),
    _title('شخصية Celyah','اختاري إحساسها وشوفي عيونها بتتغير'),
    Wrap(spacing:8,runSpacing:8,children:[
      for(final f in [('normal','عادي'),('happy','سعيدة'),('love','حب'),('curious','فضولية'),('sleepy','نعسانة'),('angry','غضبانة')])
        ActionChip(label:Text(f.$2),backgroundColor:face==f.$1?lavender.withValues(alpha:.25):panel,
          onPressed:(){setState(()=>face=f.$1);command('FACE:${f.$1}');})
    ]),
    const SizedBox(height:22),
    _card(const Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
      Text('Celyah Vision',style:TextStyle(fontSize:19,fontWeight:FontWeight.bold)),
      SizedBox(height:8),Text('الرؤية والتعرف على الأشخاص وتجنب العوائق قيد التطوير. '
        'لا تشغّلي الحركة الذاتية قبل اختبار الأمان.',style:TextStyle(color:soft))
    ])),
  ]);
  Widget _quickTile(String label,IconData icon,VoidCallback action)=>InkWell(
    onTap:action,borderRadius:BorderRadius.circular(20),
    child:Container(padding:const EdgeInsets.symmetric(vertical:18,horizontal:5),
      decoration:BoxDecoration(color:panel,borderRadius:BorderRadius.circular(20)),
      child:Column(children:[Icon(icon,color:lavender,size:27),const SizedBox(height:8),Text(label)])));
  Widget _messages()=>Column(children:[
    Padding(padding:const EdgeInsets.fromLTRB(18,8,18,4),
      child:Row(children:[
        Container(width:55,height:55,decoration:BoxDecoration(color:Colors.black,borderRadius:BorderRadius.circular(16)),
          child:CustomPaint(painter:EyePainter(face))),
        const SizedBox(width:12),
        Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
          const Text('Celyah ♡',style:TextStyle(fontWeight:FontWeight.bold,fontSize:18)),
          Text(listening?'بتسمعك دلوقتي...':robotState=='speaking'?'بترد عليك...':'جاهزة للكلام',
            style:const TextStyle(color:soft,fontSize:12))]),
      ])),
    Expanded(child:ListView.builder(reverse:true,padding:const EdgeInsets.all(18),itemCount:messages.length,
      itemBuilder:(context,i){final m=messages[messages.length-1-i];
        return Align(alignment:m.$1?Alignment.centerRight:Alignment.centerLeft,
          child:Container(margin:const EdgeInsets.only(bottom:12),padding:const EdgeInsets.all(15),
            constraints:BoxConstraints(maxWidth:MediaQuery.sizeOf(context).width*.8),
            decoration:BoxDecoration(color:m.$1?const Color(0xFF503467):panel,
              borderRadius:BorderRadius.circular(20)),child:Text(m.$2)));})),
    Padding(padding:const EdgeInsets.all(12),child:Row(children:[
      Expanded(child:TextField(controller:chat,onSubmitted:(_)=>_chat(),textInputAction:TextInputAction.send,
        decoration:const InputDecoration(hintText:'اكتبي رسالة لـ Celyah...'))),
      const SizedBox(width:5),
      IconButton.filledTonal(onPressed:listen,icon:Icon(listening?Icons.stop:Icons.mic,color:lavender)),
      IconButton.filled(onPressed:_chat,icon:const Icon(Icons.send))
    ]))
  ]);
  Widget _vision()=>ListView(padding:const EdgeInsets.all(18),children:[
    _title('Celyah Vision','عيون Celyah — رؤية العالم حولها'),
    Container(height:215,decoration:BoxDecoration(color:Colors.black,borderRadius:BorderRadius.circular(24),
      border:Border.all(color:lavender.withValues(alpha:.35))),
      child:const Column(mainAxisAlignment:MainAxisAlignment.center,children:[
        Icon(Icons.videocam_off_outlined,color:lavender,size:52),
        SizedBox(height:12),Text('LIVE VIEW • OFFLINE',style:TextStyle(color:soft,letterSpacing:2)),
        SizedBox(height:6),Text('بانتظار بث الكاميرا من الروبوت',style:TextStyle(color:soft))
      ])),
    const SizedBox(height:18),
    _card(Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
      const Icon(Icons.videocam_outlined,color:lavender,size:42),
      const SizedBox(height:14),
      const Text('الكاميرا غير مفعّلة بعد',style:TextStyle(fontSize:20,fontWeight:FontWeight.bold)),
      const SizedBox(height:10),
      const Text('إصدار firmware الحالي لا يوفّر بثًا مؤكّدًا للصور. '
        'سنربط هذه الصفحة بعنوان البث بعد إصلاح تهيئة الكاميرا.',style:TextStyle(color:soft)),
      const SizedBox(height:16),TextField(controller:camera,
        decoration:const InputDecoration(labelText:'عنوان الروبوت على الشبكة',hintText:'http://192.168.1.100')),
      const SizedBox(height:14),
      _button('اختبار الكاميرا (CAM)',Icons.camera_alt_outlined,()=>command('CAM'))
    ])),
    const SizedBox(height:18),
    _card(const Text('مهم: كشف الحواف بكاميرا واحدة لا يضمن منع السقوط. '
      'لا تختبري الحركة قرب سلالم أو حواف مكشوفة.',style:TextStyle(color:soft)))
  ]);
  Widget _control()=>ListView(padding:const EdgeInsets.all(18),children:[
    _title('Celyah Control','لوحة التحكم في الحركة والتعبيرات'),
    _card(Column(children:[
      const Icon(Icons.pan_tool_alt_outlined,color:lavender,size:38),
      const SizedBox(height:10),
      const Text('حركة العجلتين لم تُفعّل بعد',style:TextStyle(fontWeight:FontWeight.bold,fontSize:18)),
      const SizedBox(height:8),
      const Text('كود V7 لا يوفّر بعد أوامر قيادة مؤكدة لسيرفوين FS90R. '
        'لن نرسل أوامر حركة غير مدعومة.',textAlign:TextAlign.center,style:TextStyle(color:soft)),
      const SizedBox(height:20),
      _button('إيقاف / إلغاء',Icons.stop_circle_outlined,()=>command('CANCEL'),primary:true),
      const SizedBox(height:15),
      _button('اختبار الذراع 45°',Icons.front_hand_outlined,()=>command('SERVO:45')),
      const SizedBox(height:10),
      _button('الذراع 90°',Icons.back_hand_outlined,()=>command('SERVO:90')),
      const SizedBox(height:10),
      _button('الذراع 135°',Icons.pan_tool_outlined,()=>command('SERVO:135')),
    ]))
  ]);
  Widget _settings()=>ListView(padding:const EdgeInsets.all(18),children:[
    _title('إعدادات Celyah','الربط والتشخيص'),
    _card(Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
      Text('Bluetooth: ${link.status}'),
      const SizedBox(height:16),
      _button(link.connected?'قطع الاتصال':'البحث والاتصال',Icons.bluetooth,
        ()async{if(link.connected){await link.disconnect();}else{await link.connect();}}),
      const Divider(height:32),
      const Text('Gemini',style:TextStyle(fontSize:18,fontWeight:FontWeight.bold)),
      const SizedBox(height:8),
      SwitchListTile(contentPadding:EdgeInsets.zero,title:const Text('قراءة ردود الروبوت بصوت'),
        subtitle:const Text('استخدام تحويل النص إلى كلام على الموبايل',style:TextStyle(color:soft)),
        value:speakReplies,onChanged:(v)=>setState(()=>speakReplies=v)),
      const Text('هذه النسخة ترسل الرسائل إلى firmware عبر BLE. '
        'لا تحفظ مفاتيح API داخل التطبيق أو الكود. أضف إدارة آمنة للمفتاح في مرحلة التكامل.',
        style:TextStyle(color:soft)),
      const Divider(height:32),
      const Text('إصدار V8 — واجهة أولية',style:TextStyle(color:soft)),
      const Text('تم الحفاظ على بروتوكول Nordic UART الخاص بـ V7.',style:TextStyle(color:soft))
    ]))
  ]);
}
class EyePainter extends CustomPainter {
  final String face; EyePainter(this.face);
  @override void paint(Canvas canvas,Size size){
    final p=Paint()..color=lavender..style=PaintingStyle.fill;
    final glow=Paint()..color=lavender.withValues(alpha:.18)..maskFilter=const MaskFilter.blur(BlurStyle.normal,12);
    final y=size.height*.48;
    for(final x in [size.width*.33,size.width*.67]){
      if(face=='happy'||face=='sleepy'){
        final path=Path()..moveTo(x-21,y+7)..quadraticBezierTo(x,y-23,x+21,y+7);
        canvas.drawPath(path,Paint()..color=lavender..style=PaintingStyle.stroke..strokeWidth=6..strokeCap=StrokeCap.round);
      } else if(face=='love'){
        final path=Path()..moveTo(x,y+17)..cubicTo(x-34,y-5,x-15,y-22,x,y-8)
          ..cubicTo(x+15,y-22,x+34,y-5,x,y+17);
        canvas.drawPath(path,p);
      } else {
        canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromCenter(center:Offset(x,y),width:31,height:45),
          const Radius.circular(14)),glow);
        canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromCenter(center:Offset(x,y),width:27,height:40),
          const Radius.circular(12)),p);
        canvas.drawCircle(Offset(x+5,y-7),5,Paint()..color=Colors.black);
        canvas.drawCircle(Offset(x+3,y-10),2,Paint()..color=Colors.white);
      }
    }
    if(face=='curious'||face=='angry'){
      final b=Paint()..color=lavender..strokeWidth=3..strokeCap=StrokeCap.round;
      canvas.drawLine(Offset(size.width*.22,y-37),Offset(size.width*.4,y-42),b);
      canvas.drawLine(Offset(size.width*.6,y-42),Offset(size.width*.78,y-37),b);
    }
  }
  @override bool shouldRepaint(covariant EyePainter old)=>old.face!=face;
}
