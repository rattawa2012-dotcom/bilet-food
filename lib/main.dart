import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

const supabaseUrl='https://nvqeefqswhwpisflauic.supabase.co';
const supabaseKey='sb_publishable_ygYxI7UefyR6o_OcAFItIg_2yhjsEZW';
const brand=Color(0xFFFF6900);
final db=Supabase.instance.client;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Supabase.initialize(url:supabaseUrl,publishableKey:supabaseKey);
  runApp(const App());
}
class App extends StatelessWidget{
  const App({super.key});
  @override Widget build(BuildContext c)=>MaterialApp(debugShowCheckedModeBanner:false,theme:ThemeData(useMaterial3:true,colorScheme:ColorScheme.fromSeed(seedColor:brand)),home:const Gate());
}
class Gate extends StatelessWidget{
  const Gate({super.key});
  @override Widget build(BuildContext c)=>StreamBuilder<AuthState>(stream:db.auth.onAuthStateChange,builder:(_,__)=>db.auth.currentSession==null?const Login():const Router());
}
class Login extends StatefulWidget{const Login({super.key});@override State<Login> createState()=>_Login();}
class _Login extends State<Login>{
  final e=TextEditingController(),p=TextEditingController(); bool busy=false;

  Future<void> go()async{
    setState(()=>busy=true);
    try{
      await db.auth.signInWithPassword(email:e.text.trim(),password:p.text);
    }catch(x){
      if(mounted)ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:Text('E-mail ou mot de passe incorrect. Utilisez « Compte oublié ? » si nécessaire.')));
    }finally{if(mounted)setState(()=>busy=false);}
  }

  Future<void> forgotPassword()async{
    final mail=TextEditingController(text:e.text.trim());
    final ok=await showDialog<bool>(context:context,builder:(c)=>AlertDialog(
      title:const Text('Mot de passe oublié'),
      content:SizedBox(width:420,child:Column(mainAxisSize:MainAxisSize.min,crossAxisAlignment:CrossAxisAlignment.start,children:[
        const Text('Saisissez l’adresse e-mail du compte. BILET FOOD enverra un lien sécurisé pour choisir un nouveau mot de passe.'),
        const SizedBox(height:14),
        TextField(controller:mail,keyboardType:TextInputType.emailAddress,decoration:const InputDecoration(labelText:'E-mail du compte',border:OutlineInputBorder())),
      ])),
      actions:[
        TextButton(onPressed:()=>Navigator.pop(c,false),child:const Text('ANNULER')),
        FilledButton(onPressed:()=>Navigator.pop(c,true),child:const Text('ENVOYER LE LIEN')),
      ],
    ));
    if(ok==true&&mail.text.trim().isNotEmpty){
      try{
        await db.auth.resetPasswordForEmail(mail.text.trim());
        if(mounted)showDialog(context:context,builder:(c)=>AlertDialog(
          title:const Text('Demande envoyée'),
          content:Text('Un message de récupération a été envoyé à ${mail.text.trim()}. Vérifiez aussi les courriers indésirables.'),
          actions:[FilledButton(onPressed:()=>Navigator.pop(c),child:const Text('OK'))],
        ));
      }catch(x){
        if(mounted)ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text('Récupération impossible : $x')));
      }
    }
    mail.dispose();
  }

  Future<void> forgotIdentifier()async{
    await showDialog(context:context,builder:(c)=>AlertDialog(
      title:const Text('Identifiant / e-mail oublié'),
      content:const SizedBox(width:430,child:Text(
        'Votre identifiant BILET FOOD est votre adresse e-mail.\n\n'
        'Pour protéger les comptes, l’application n’affiche pas une adresse e-mail à partir d’un simple nom ou numéro de téléphone.\n\n'
        'Si vous êtes Restaurant ou Livreur, demandez à l’administrateur BILET FOOD de consulter votre compte dans « Gestion > Comptes et profils » et de vous communiquer l’adresse e-mail enregistrée.\n\n'
        'Si vous êtes Client et ne retrouvez plus votre e-mail, contactez l’assistance BILET FOOD.'
      )),
      actions:[FilledButton(onPressed:()=>Navigator.pop(c),child:const Text('COMPRIS'))],
    ));
  }

  Future<void> recoveryMenu()async{
    final choice=await showModalBottomSheet<String>(context:context,builder:(c)=>SafeArea(child:Padding(
      padding:const EdgeInsets.all(16),
      child:Column(mainAxisSize:MainAxisSize.min,children:[
        const Text('Récupération de compte',style:TextStyle(fontSize:20,fontWeight:FontWeight.bold)),
        const SizedBox(height:8),
        ListTile(leading:const Icon(Icons.lock_reset),title:const Text('Mot de passe oublié'),subtitle:const Text('Recevoir un lien de réinitialisation par e-mail'),onTap:()=>Navigator.pop(c,'password')),
        ListTile(leading:const Icon(Icons.alternate_email),title:const Text('Identifiant / e-mail oublié'),subtitle:const Text('Retrouver la procédure adaptée au compte'),onTap:()=>Navigator.pop(c,'identifier')),
      ]),
    )));
    if(choice=='password')await forgotPassword();
    if(choice=='identifier')await forgotIdentifier();
  }

  @override void dispose(){e.dispose();p.dispose();super.dispose();}
  @override Widget build(BuildContext c)=>Scaffold(body:Center(child:SizedBox(width:430,child:Card(child:Padding(padding:const EdgeInsets.all(24),child:Column(mainAxisSize:MainAxisSize.min,children:[
    const Icon(Icons.delivery_dining,size:72,color:brand),
    const Text('BILET FOOD',style:TextStyle(fontSize:28,fontWeight:FontWeight.bold)),
    const SizedBox(height:20),
    TextField(controller:e,keyboardType:TextInputType.emailAddress,decoration:const InputDecoration(labelText:'E-mail',border:OutlineInputBorder())),
    const SizedBox(height:10),
    TextField(controller:p,obscureText:true,onSubmitted:(_){if(!busy)go();},decoration:const InputDecoration(labelText:'Mot de passe',border:OutlineInputBorder())),
    const SizedBox(height:14),
    FilledButton(onPressed:busy?null:go,style:FilledButton.styleFrom(backgroundColor:brand,minimumSize:const Size.fromHeight(50)),child:Text(busy?'Connexion...':'SE CONNECTER')),
    const SizedBox(height:8),
    TextButton.icon(onPressed:busy?null:recoveryMenu,icon:const Icon(Icons.help_outline),label:const Text('COMPTE OUBLIÉ ?')),
  ]))))));
}
class Router extends StatefulWidget{const Router({super.key});@override State<Router> createState()=>_Router();}
class _Router extends State<Router>{
  Map<String,dynamic>? profile; bool load=true; String? err;
  @override void initState(){super.initState();go();}
  Future<void> go()async{try{final x=await db.from('profiles').select().eq('id',db.auth.currentUser!.id).single();if(mounted)setState((){profile=Map<String,dynamic>.from(x);load=false;});}catch(e){if(mounted)setState((){err='$e';load=false;});}}
  @override Widget build(BuildContext c){
    if(load)return const Scaffold(body:Center(child:CircularProgressIndicator()));
    if(err!=null)return Scaffold(body:Center(child:Text('Erreur profil : $err')));
    final r='${profile?['role']??''}'.trim().toLowerCase();
    if(r=='client')return ClientHome(profile:profile!);
    if(r=='restaurant')return RestaurantHome(profile:profile!);
    if(r=='courier')return CourierHome(profile:profile!);
    if(r=='admin')return AdminHome(profile:profile!);
    const title='PROFIL NON RECONNU';
    return Scaffold(appBar:AppBar(title:const Text('BILET FOOD'),actions:[IconButton(onPressed:()=>db.auth.signOut(),icon:const Icon(Icons.logout))]),body:Center(child:Text('$title\nProfil ${r.isEmpty?'inconnu':r} reconnu\nConnexion BILET FOOD FINAL réussie.',textAlign:TextAlign.center,style:const TextStyle(fontSize:22))));
  }
}
class Line{final Map<String,dynamic> item;int qty;Line(this.item,this.qty);}
class ClientHome extends StatefulWidget{final Map<String,dynamic> profile;const ClientHome({super.key,required this.profile});@override State<ClientHome> createState()=>_ClientHome();}
class _ClientHome extends State<ClientHome>{
  int tab=0; List<Map<String,dynamic>> orders=[],notes=[]; RealtimeChannel? oc,nc,rc;
  @override void initState(){super.initState();refresh();oc=db.channel('final-orders').onPostgresChanges(event:PostgresChangeEvent.all,schema:'public',table:'orders',callback:(_)=>loadOrders()).subscribe();nc=db.channel('final-notes').onPostgresChanges(event:PostgresChangeEvent.all,schema:'public',table:'notifications',callback:(_)=>loadNotes()).subscribe();
    rc=db.channel('final-client-restaurants').onPostgresChanges(event:PostgresChangeEvent.all,schema:'public',table:'restaurants',callback:(_){if(mounted)setState((){});}).subscribe();}
  @override void dispose(){if(oc!=null)db.removeChannel(oc!);if(nc!=null)db.removeChannel(nc!);if(rc!=null)db.removeChannel(rc!);super.dispose();}
  Future<void> refresh()async{await Future.wait([loadOrders(),loadNotes()]);}
  Future<void> loadOrders()async{try{final x=await db.from('orders').select().eq('client_id',db.auth.currentUser!.id).order('created_at',ascending:false);if(mounted)setState(()=>orders=List<Map<String,dynamic>>.from(x));}catch(_){}}
  Future<void> loadNotes()async{try{final x=await db.from('notifications').select().eq('user_id',db.auth.currentUser!.id).order('created_at',ascending:false);if(mounted)setState(()=>notes=List<Map<String,dynamic>>.from(x));}catch(_){}}
  Future<void> read(dynamic id)async{await db.from('notifications').update({'is_read':true}).eq('id',id);await loadNotes();}
  String label(String s)=>{'pending':'Commande envoyée','accepted':'Acceptée par le restaurant','rejected':'Refusée','preparing':'En préparation','ready':'Prête pour livraison','courier_assigned':'Livreur assigné','picked_up':'Récupérée par le livreur','on_the_way':'Livreur en route','delivered':'Livrée'}[s]??s;
  double progress(String s)=>{'pending':.1,'accepted':.25,'preparing':.4,'ready':.55,'courier_assigned':.65,'picked_up':.75,'on_the_way':.9,'delivered':1.0,'rejected':0.0}[s]??.05;
  @override Widget build(BuildContext c){
    final pages=[Restaurants(profile:widget.profile,onCreated:()async{await loadOrders();if(mounted)setState(()=>tab=1);}),Orders(orders:orders,label:label,progress:progress),IndependentPaymentPage(orders:orders),Notes(notes:notes,read:read)];
    return Scaffold(appBar:AppBar(title:const Text('BILET FOOD'),actions:[IconButton(onPressed:refresh,icon:const Icon(Icons.refresh)),IconButton(onPressed:()=>db.auth.signOut(),icon:const Icon(Icons.logout))]),body:IndexedStack(index:tab,children:pages),bottomNavigationBar:NavigationBar(selectedIndex:tab,onDestinationSelected:(i)=>setState(()=>tab=i),destinations:[
      const NavigationDestination(icon:Icon(Icons.restaurant),label:'Restaurants'),const NavigationDestination(icon:Icon(Icons.receipt_long),label:'Commandes'),const NavigationDestination(icon:Icon(Icons.payments),label:'Paiement'),
      NavigationDestination(icon:Badge(isLabelVisible:notes.any((n)=>n['is_read']!=true),child:const Icon(Icons.notifications)),label:'Notifications')
    ]));
  }
}
class Restaurants extends StatefulWidget{final Map<String,dynamic> profile;final Future<void> Function() onCreated;const Restaurants({super.key,required this.profile,required this.onCreated});@override State<Restaurants> createState()=>_Restaurants();}
class _Restaurants extends State<Restaurants>{
  List<Map<String,dynamic>> rs=[],cats=[],items=[];Map<String,dynamic>? restaurant;final Map<int,Line> cart={};bool loading=true;String? err;
  RealtimeChannel? restaurantChannel,menuChannel;
  @override void initState(){
    super.initState();load();
    restaurantChannel=db.channel('client-restaurants-live').onPostgresChanges(event:PostgresChangeEvent.all,schema:'public',table:'restaurants',callback:(_)=>load()).subscribe();
    menuChannel=db.channel('client-menu-live').onPostgresChanges(event:PostgresChangeEvent.all,schema:'public',table:'menu_items',callback:(_){
      if(restaurant!=null)open(restaurant!);
    }).subscribe();
  }
  @override void dispose(){
    if(restaurantChannel!=null)db.removeChannel(restaurantChannel!);
    if(menuChannel!=null)db.removeChannel(menuChannel!);
    super.dispose();
  }
  Future<void> load()async{try{final x=await db.from('restaurants').select().eq('is_open',true).order('name');if(mounted)setState((){rs=List<Map<String,dynamic>>.from(x);loading=false;});}catch(e){if(mounted)setState((){err='$e';loading=false;});}}
  Future<void> open(Map<String,dynamic> r)async{try{final c=await db.from('menu_categories').select().eq('restaurant_id',r['id']).order('sort_order');final m=await db.from('menu_items').select().eq('restaurant_id',r['id']).eq('is_available',true).order('name');if(mounted)setState((){restaurant=r;cats=List<Map<String,dynamic>>.from(c);items=List<Map<String,dynamic>>.from(m);cart.clear();});}catch(e){if(mounted)ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text('Erreur catalogue : $e')));}}
  int get subtotal=>cart.values.fold(0,(s,l)=>s+(l.item['price'] as num).toInt()*l.qty);int get count=>cart.values.fold(0,(s,l)=>s+l.qty);
  void add(Map<String,dynamic> i){final id=i['id'] as int;setState((){cart.containsKey(id)?cart[id]!.qty++:cart[id]=Line(i,1);});}
  String cat(dynamic id){for(final c in cats){if(c['id']==id)return '${c['name']}';}return 'Menu';}
  Future<void> checkout()async{
    final a=TextEditingController(text:'${widget.profile['address']??''}'),p=TextEditingController(text:'${widget.profile['phone']??''}');
    int delivery=500;
    try{
      final s=await db.from('bilet_food_settings').select().eq('id',1).single();
      delivery=int.tryParse('${s['delivery_fee']??s['minimum_delivery_fee']??500}')??500;
    }catch(_){}
    final ok=await showDialog<bool>(context:context,builder:(x)=>AlertDialog(title:const Text('Confirmer la commande'),content:SizedBox(width:420,child:Column(mainAxisSize:MainAxisSize.min,children:[TextField(controller:a,decoration:const InputDecoration(labelText:'Adresse de livraison',border:OutlineInputBorder())),const SizedBox(height:10),TextField(controller:p,decoration:const InputDecoration(labelText:'Téléphone',border:OutlineInputBorder())),const SizedBox(height:15),Text('Sous-total : $subtotal FCFA'),Text('Livraison : $delivery FCFA'),Text('TOTAL : ${subtotal+delivery} FCFA',style:const TextStyle(fontWeight:FontWeight.bold))])),actions:[TextButton(onPressed:()=>Navigator.pop(x,false),child:const Text('ANNULER')),FilledButton(onPressed:()=>Navigator.pop(x,true),child:const Text('COMMANDER'))]));
    if(ok==true&&a.text.trim().isNotEmpty&&restaurant!=null){try{final number='BF-${DateTime.now().millisecondsSinceEpoch}';final o=await db.from('orders').insert({'order_number':number,'client_id':db.auth.currentUser!.id,'restaurant_id':restaurant!['id'],'customer_name':'${widget.profile['full_name']??db.auth.currentUser?.email??'Client BILET FOOD'}','status':'pending','subtotal':subtotal,'delivery_fee':delivery,'total':subtotal+delivery,'delivery_address':a.text.trim(),'customer_phone':p.text.trim(),'payment_method':'Espèces','payment_status':'En attente'}).select('id').single();await db.from('order_items').insert([for(final l in cart.values){'order_id':o['id'],'product_name':l.item['name'],'quantity':l.qty,'unit_price':l.item['price'],'line_total':(l.item['price'] as num).toInt()*l.qty}]);if(mounted){setState(()=>cart.clear());ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text('Commande $number envoyée au restaurant.')));await widget.onCreated();}}catch(e){if(mounted)ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text('Commande non envoyée : $e')));}}
    a.dispose();p.dispose();
  }
  Future<void> basket()async{await showModalBottomSheet(context:context,isScrollControlled:true,builder:(x)=>StatefulBuilder(builder:(x,sheet)=>SafeArea(child:Padding(padding:const EdgeInsets.all(18),child:Column(mainAxisSize:MainAxisSize.min,children:[const Text('Votre panier',style:TextStyle(fontSize:24,fontWeight:FontWeight.bold)),for(final e in cart.entries.toList())ListTile(title:Text('${e.value.item['name']}'),subtitle:Text('${e.value.item['price']} F × ${e.value.qty}'),leading:IconButton(icon:const Icon(Icons.remove_circle_outline),onPressed:(){setState((){e.value.qty--;if(e.value.qty<=0)cart.remove(e.key);});sheet((){});if(cart.isEmpty)Navigator.pop(x);}),trailing:IconButton(icon:const Icon(Icons.add_circle_outline),onPressed:(){setState(()=>e.value.qty++);sheet((){});})),const Divider(),Text('Sous-total : $subtotal FCFA'),const SizedBox(height:10),FilledButton(onPressed:cart.isEmpty?null:(){Navigator.pop(x);checkout();},child:const Text('VALIDER LA COMMANDE'))])))));}
  @override Widget build(BuildContext c){
    if(loading)return const Center(child:CircularProgressIndicator());if(err!=null)return Center(child:Text('Erreur : $err'));
    if(restaurant==null)return ListView(padding:const EdgeInsets.all(18),children:[Text('Bonjour ${widget.profile['full_name']??'Client'}',style:const TextStyle(fontSize:24,fontWeight:FontWeight.bold)),const Text('Choisissez un restaurant'),const SizedBox(height:12),if(rs.isEmpty)const Card(child:Padding(padding:EdgeInsets.all(20),child:Text('Aucun restaurant ouvert.'))),for(final r in rs)Card(child:ListTile(leading:const CircleAvatar(child:Icon(Icons.storefront)),title:Text('${r['name']}'),trailing:const Icon(Icons.chevron_right),onTap:()=>open(r)))]);
    return Scaffold(appBar:AppBar(automaticallyImplyLeading:false,leading:IconButton(onPressed:()=>setState((){restaurant=null;cart.clear();}),icon:const Icon(Icons.arrow_back)),title:Text('${restaurant!['name']}'),actions:[IconButton(onPressed:cart.isEmpty?null:basket,icon:Badge(label:Text('$count'),isLabelVisible:count>0,child:const Icon(Icons.shopping_cart)))]),body:ListView(padding:const EdgeInsets.all(18),children:[const Text('Menu',style:TextStyle(fontSize:26,fontWeight:FontWeight.bold)),if(items.isEmpty)const Card(child:Padding(padding:EdgeInsets.all(20),child:Text('Aucun plat disponible.'))),for(final i in items)Card(child:ListTile(leading:const CircleAvatar(child:Icon(Icons.restaurant)),title:Text('${i['name']}'),subtitle:Text('${cat(i['category_id'])}\n${i['description']??''}'),isThreeLine:true,trailing:Column(mainAxisAlignment:MainAxisAlignment.center,children:[Text('${i['price']} F',style:const TextStyle(fontWeight:FontWeight.bold)),IconButton(onPressed:()=>add(i),icon:const Icon(Icons.add_circle,color:brand))])))]),bottomNavigationBar:cart.isEmpty?null:SafeArea(child:Padding(padding:const EdgeInsets.all(10),child:FilledButton(onPressed:basket,child:Padding(padding:const EdgeInsets.all(14),child:Text('PANIER • $count article(s) • $subtotal FCFA'))))));
  }
}
class Orders extends StatelessWidget{final List<Map<String,dynamic>> orders;final String Function(String) label;final double Function(String) progress;const Orders({super.key,required this.orders,required this.label,required this.progress});@override Widget build(BuildContext c)=>ListView(padding:const EdgeInsets.all(16),children:[const Text('Mes commandes',style:TextStyle(fontSize:26,fontWeight:FontWeight.bold)),if(orders.isEmpty)const Card(child:Padding(padding:EdgeInsets.all(20),child:Text('Aucune commande.'))),for(final o in orders)Card(child:Padding(padding:const EdgeInsets.all(16),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Text('${o['order_number']??o['id']}',style:const TextStyle(fontWeight:FontWeight.bold)),const SizedBox(height:8),LinearProgressIndicator(value:progress('${o['status']}')),const SizedBox(height:8),Text(label('${o['status']}'),style:const TextStyle(fontWeight:FontWeight.bold)),Text('Total : ${o['total']} FCFA'),Text('Adresse : ${o['delivery_address']??''}')])))]);}
class Notes extends StatelessWidget{final List<Map<String,dynamic>> notes;final Future<void> Function(dynamic) read;const Notes({super.key,required this.notes,required this.read});@override Widget build(BuildContext c)=>notes.isEmpty?const Center(child:Text('Aucune notification')):ListView(padding:const EdgeInsets.all(16),children:[const Text('Notifications',style:TextStyle(fontSize:26,fontWeight:FontWeight.bold)),for(final n in notes)Card(child:ListTile(leading:Icon(n['is_read']==true?Icons.notifications_none:Icons.notifications_active),title:Text('${n['title']}'),subtitle:Text('${n['message']}'),trailing:n['is_read']==true?null:TextButton(onPressed:()=>read(n['id']),child:const Text('LU'))))]);}


class RestaurantHome extends StatefulWidget {
  final Map<String,dynamic> profile;
  const RestaurantHome({super.key,required this.profile});
  @override State<RestaurantHome> createState()=>_RestaurantHomeState();
}

class _RestaurantHomeState extends State<RestaurantHome> {
  int tab=0;
  List<Map<String,dynamic>> orders=[],categories=[],items=[];
  bool loading=true;
  String? error;
  RealtimeChannel? ordersChannel,catalogChannel;

  dynamic get rid=>widget.profile['restaurant_id'];

  @override void initState(){
    super.initState();
    refresh();
    ordersChannel=db.channel('restaurant-orders-${db.auth.currentUser!.id}')
      .onPostgresChanges(event:PostgresChangeEvent.all,schema:'public',table:'orders',callback:(_)=>loadOrders())
      .subscribe();
    catalogChannel=db.channel('restaurant-catalog-${db.auth.currentUser!.id}')
      .onPostgresChanges(event:PostgresChangeEvent.all,schema:'public',table:'menu_items',callback:(_)=>loadCatalog())
      .subscribe();
  }

  @override void dispose(){
    if(ordersChannel!=null)db.removeChannel(ordersChannel!);
    if(catalogChannel!=null)db.removeChannel(catalogChannel!);
    super.dispose();
  }

  Future<void> refresh()async{
    if(rid==null){
      if(mounted)setState((){error='Aucun restaurant rattaché à ce compte.';loading=false;});
      return;
    }
    await Future.wait([loadOrders(),loadCatalog()]);
    if(mounted)setState(()=>loading=false);
  }

  Future<void> loadOrders()async{
    try{
      final x=await db.from('orders').select().eq('restaurant_id',rid).order('created_at',ascending:false);
      if(mounted)setState((){orders=List<Map<String,dynamic>>.from(x);error=null;});
    }catch(e){if(mounted)setState(()=>error='$e');}
  }

  Future<void> loadCatalog()async{
    try{
      final c=await db.from('menu_categories').select().eq('restaurant_id',rid).order('sort_order');
      final m=await db.from('menu_items').select().eq('restaurant_id',rid).order('name');
      if(mounted)setState((){
        categories=List<Map<String,dynamic>>.from(c);
        items=List<Map<String,dynamic>>.from(m);
      });
    }catch(e){
      if(mounted)ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text('Erreur catalogue : $e')));
    }
  }

  Future<void> setStatus(dynamic id,String status)async{
    try{
      await db.from('orders').update({'status':status}).eq('id',id);
      await loadOrders();
    }catch(e){if(mounted)ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text('Erreur : $e')));}
  }

  Future<List<Map<String,dynamic>>> loadLines(dynamic orderId)async{
    final x=await db.from('order_items').select('id, order_id, product_name, quantity, unit_price, line_total').eq('order_id',orderId);
    return List<Map<String,dynamic>>.from(x);
  }

  Future<void> showDetail(Map<String,dynamic> o)async{
    try{
      final ls=await loadLines(o['id']);
      if(!mounted)return;
      showDialog(context:context,builder:(ctx)=>AlertDialog(
        title:Text('Commande ${o['order_number']??o['id']}'),
        content:SizedBox(width:480,child:ListView(shrinkWrap:true,children:[
          Text('Client : ${o['customer_name']??''}'),
          Text('Téléphone : ${o['customer_phone']??''}'),
          Text('Adresse : ${o['delivery_address']??''}'),
          const Divider(),
          if(ls.isEmpty)const Text('Aucun détail article enregistré.',style:TextStyle(fontStyle:FontStyle.italic)),
          for(final i in ls)ListTile(
            title:Text('${i['product_name']??'Article'}'),
            subtitle:Text('${i['quantity']??0} × ${i['unit_price']??0} F'),
            trailing:Text('${i['line_total']??0} F'),
          ),
          const Divider(),
          Text('TOTAL : ${o['total']} FCFA',style:const TextStyle(fontWeight:FontWeight.bold)),
        ])),
        actions:[TextButton(onPressed:()=>Navigator.pop(ctx),child:const Text('FERMER'))],
      ));
    }catch(e){if(mounted)ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text('Erreur détail : $e')));}
  }

  String statusLabel(String s)=>{
    'pending':'Nouvelle commande','accepted':'Acceptée','rejected':'Refusée',
    'preparing':'En préparation','ready':'Prête','courier_assigned':'Livreur assigné',
    'picked_up':'Récupérée','on_the_way':'En livraison','delivered':'Livrée',
  }[s]??s;

  String categoryName(dynamic id){
    for(final c in categories){if(c['id']==id)return '${c['name']}';}
    return 'Sans catégorie';
  }

  Future<void> addCategory()async{
    final name=TextEditingController();
    final ok=await showDialog<bool>(context:context,builder:(c)=>AlertDialog(
      title:const Text('Nouvelle catégorie'),
      content:TextField(controller:name,decoration:const InputDecoration(labelText:'Nom de la catégorie',border:OutlineInputBorder())),
      actions:[
        TextButton(onPressed:()=>Navigator.pop(c,false),child:const Text('ANNULER')),
        FilledButton(onPressed:()=>Navigator.pop(c,true),child:const Text('AJOUTER')),
      ],
    ));
    if(ok==true&&name.text.trim().isNotEmpty){
      try{
        await db.from('menu_categories').insert({
          'restaurant_id':rid,'name':name.text.trim(),'sort_order':categories.length,
        });
        await loadCatalog();
      }catch(e){if(mounted)ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text('Erreur catégorie : $e')));}
    }
    name.dispose();
  }

  Future<void> productDialog([Map<String,dynamic>? item])async{
    if(categories.isEmpty){
      if(mounted)ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:Text('Créez d’abord une catégorie.')));
      return;
    }
    final name=TextEditingController(text:'${item?['name']??''}');
    final desc=TextEditingController(text:'${item?['description']??''}');
    final price=TextEditingController(text:item==null?'':'${item['price']}');
    dynamic categoryId=item?['category_id']??categories.first['id'];
    bool available=item?['is_available']??true;

    final ok=await showDialog<bool>(context:context,builder:(c)=>StatefulBuilder(builder:(c,setD)=>AlertDialog(
      title:Text(item==null?'Ajouter un produit':'Modifier le produit'),
      content:SizedBox(width:440,child:SingleChildScrollView(child:Column(mainAxisSize:MainAxisSize.min,children:[
        TextField(controller:name,decoration:const InputDecoration(labelText:'Nom du produit',border:OutlineInputBorder())),
        const SizedBox(height:10),
        TextField(controller:desc,decoration:const InputDecoration(labelText:'Description',border:OutlineInputBorder())),
        const SizedBox(height:10),
        TextField(controller:price,keyboardType:TextInputType.number,decoration:const InputDecoration(labelText:'Prix FCFA',border:OutlineInputBorder())),
        const SizedBox(height:10),
        DropdownButtonFormField<dynamic>(
          initialValue:categoryId,
          decoration:const InputDecoration(labelText:'Catégorie',border:OutlineInputBorder()),
          items:[for(final cat in categories)DropdownMenuItem(value:cat['id'],child:Text('${cat['name']}'))],
          onChanged:(v)=>setD(()=>categoryId=v),
        ),
        SwitchListTile(contentPadding:EdgeInsets.zero,value:available,onChanged:(v)=>setD(()=>available=v),title:const Text('Produit disponible')),
      ]))),
      actions:[
        TextButton(onPressed:()=>Navigator.pop(c,false),child:const Text('ANNULER')),
        FilledButton(onPressed:()=>Navigator.pop(c,true),child:Text(item==null?'AJOUTER':'ENREGISTRER')),
      ],
    )));
    if(ok==true){
      final amount=num.tryParse(price.text.trim());
      if(name.text.trim().isEmpty||amount==null){
        if(mounted)ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:Text('Nom et prix valides obligatoires.')));
      }else{
        try{
          final data={
            'restaurant_id':rid,'category_id':categoryId,'name':name.text.trim(),
            'description':desc.text.trim(),'price':amount,'is_available':available,
          };
          if(item==null){
            await db.from('menu_items').insert(data);
          }else{
            await db.from('menu_items').update(data).eq('id',item['id']);
          }
          await loadCatalog();
        }catch(e){if(mounted)ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text('Erreur produit : $e')));}
      }
    }
    name.dispose();desc.dispose();price.dispose();
  }

  Future<void> toggleProduct(Map<String,dynamic> item,bool value)async{
    try{
      await db.from('menu_items').update({'is_available':value}).eq('id',item['id']);
      await loadCatalog();
    }catch(e){if(mounted)ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text('Erreur disponibilité : $e')));}
  }

  Widget ordersPage()=>RefreshIndicator(
    onRefresh:loadOrders,
    child:ListView(padding:const EdgeInsets.all(16),children:[
      const Text('Commandes reçues',style:TextStyle(fontSize:26,fontWeight:FontWeight.bold)),
      const SizedBox(height:12),
      if(orders.isEmpty)const Card(child:Padding(padding:EdgeInsets.all(20),child:Text('Aucune commande reçue.'))),
      for(final o in orders)Card(child:Padding(padding:const EdgeInsets.all(12),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
        ListTile(
          contentPadding:EdgeInsets.zero,
          title:Text('${o['order_number']??o['id']}',style:const TextStyle(fontWeight:FontWeight.bold)),
          subtitle:Text('${o['customer_name']??'Client'} • ${o['total']} F\n${statusLabel('${o['status']}')}'),
          isThreeLine:true,
          trailing:IconButton(onPressed:()=>showDetail(o),icon:const Icon(Icons.visibility)),
        ),
        Wrap(spacing:8,runSpacing:8,children:[
          if(o['status']=='pending')...[
            FilledButton(onPressed:()=>setStatus(o['id'],'accepted'),child:const Text('ACCEPTER')),
            OutlinedButton(onPressed:()=>setStatus(o['id'],'rejected'),child:const Text('REFUSER')),
          ],
          if(o['status']=='accepted')FilledButton(onPressed:()=>setStatus(o['id'],'preparing'),child:const Text('PRÉPARATION')),
          if(o['status']=='preparing')FilledButton(onPressed:()=>setStatus(o['id'],'ready'),child:const Text('PRÊTE')),
        ]),
      ]))),
    ]),
  );

  Widget catalogPage()=>RefreshIndicator(
    onRefresh:loadCatalog,
    child:ListView(padding:const EdgeInsets.all(16),children:[
      Row(children:[
        const Expanded(child:Text('Catalogue',style:TextStyle(fontSize:26,fontWeight:FontWeight.bold))),
        OutlinedButton.icon(onPressed:addCategory,icon:const Icon(Icons.category),label:const Text('CATÉGORIE')),
        const SizedBox(width:8),
        FilledButton.icon(onPressed:()=>productDialog(),icon:const Icon(Icons.add),label:const Text('AJOUTER PRODUIT')),
      ]),
      const SizedBox(height:12),
      if(categories.isEmpty)const Card(child:Padding(padding:EdgeInsets.all(18),child:Text('Aucune catégorie. Créez une catégorie avant d’ajouter un produit.'))),
      if(items.isEmpty)const Card(child:Padding(padding:EdgeInsets.all(18),child:Text('Aucun produit enregistré.'))),
      for(final i in items)Card(child:ListTile(
        leading:CircleAvatar(child:Icon(i['is_available']==true?Icons.restaurant:Icons.block)),
        title:Text('${i['name']}'),
        subtitle:Text('${categoryName(i['category_id'])} • ${i['price']} F\n${i['description']??''}'),
        isThreeLine:true,
        trailing:SizedBox(width:125,child:Row(mainAxisAlignment:MainAxisAlignment.end,children:[
          Switch(value:i['is_available']==true,onChanged:(v)=>toggleProduct(i,v)),
          IconButton(onPressed:()=>productDialog(i),icon:const Icon(Icons.edit)),
        ])),
      )),
    ]),
  );

  @override Widget build(BuildContext context){
    if(loading)return const Scaffold(body:Center(child:CircularProgressIndicator()));
    if(error!=null)return Scaffold(appBar:AppBar(actions:[IconButton(onPressed:()=>db.auth.signOut(),icon:const Icon(Icons.logout))]),body:Center(child:Text('Erreur : $error')));
    final pages=[ordersPage(),catalogPage()];
    return Scaffold(
      appBar:AppBar(
        title:Text('BILET FOOD • ${widget.profile['business_name']??widget.profile['full_name']??'RESTAURANT'}'),
        actions:[IconButton(onPressed:refresh,icon:const Icon(Icons.refresh)),IconButton(onPressed:()=>db.auth.signOut(),icon:const Icon(Icons.logout))],
      ),
      body:IndexedStack(index:tab,children:pages),
      bottomNavigationBar:NavigationBar(
        selectedIndex:tab,
        onDestinationSelected:(i)=>setState(()=>tab=i),
        destinations:const[
          NavigationDestination(icon:Icon(Icons.receipt_long),label:'Commandes'),
          NavigationDestination(icon:Icon(Icons.restaurant_menu),label:'Catalogue'),
        ],
      ),
    );
  }
}

class CourierHome extends StatefulWidget {
  final Map<String,dynamic> profile;
  const CourierHome({super.key, required this.profile});
  @override State<CourierHome> createState()=>_CourierHomeState();
}

class _CourierHomeState extends State<CourierHome> {
  List<Map<String,dynamic>> orders=[];
  bool loading=true;
  String? error;
  RealtimeChannel? channel,restaurantsChannel,settingsChannel;

  @override void initState(){
    super.initState();
    refresh();
    channel=db.channel('final-courier-orders-${db.auth.currentUser!.id}')
      .onPostgresChanges(
        event:PostgresChangeEvent.all,
        schema:'public',
        table:'orders',
        callback:(_)=>refresh(),
      ).subscribe();
  }

  @override void dispose(){
    if(channel!=null) db.removeChannel(channel!);
    super.dispose();
  }

  Future<void> refresh() async {
    try {
      final uid=db.auth.currentUser!.id;

      final available=await db
          .from('orders')
          .select()
          .eq('status','ready')
          .order('created_at',ascending:false);

      final mine=await db
          .from('orders')
          .select()
          .eq('courier_id',uid)
          .inFilter('status',[
            'courier_assigned',
            'picked_up',
            'on_the_way',
            'delivered'
          ])
          .order('created_at',ascending:false);

      final all=<Map<String,dynamic>>[];
      final seen=<String>{};

      for(final raw in [...available,...mine]){
        final o=Map<String,dynamic>.from(raw);
        final k='${o['id']}';
        if(seen.add(k)) all.add(o);
      }

      if(mounted)setState((){
        orders=all;
        loading=false;
        error=null;
      });
    } catch(e) {
      if(mounted)setState((){
        error='$e';
        loading=false;
      });
    }
  }

  Future<void> accept(Map<String,dynamic> o) async {
    try {
      await db.from('orders').update({
        'courier_id':db.auth.currentUser!.id,
        'status':'courier_assigned',
      }).eq('id',o['id']).eq('status','ready');

      await refresh();

      if(mounted)ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content:Text('Livraison acceptée.')),
      );
    } catch(e) {
      if(mounted)ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content:Text('Erreur : $e')),
      );
    }
  }

  Future<void> reject(Map<String,dynamic> o) async {
    if(mounted)ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content:Text('Livraison refusée.')),
    );
    setState(()=>orders.removeWhere((x)=>x['id']==o['id']));
  }

  Future<void> status(dynamic id,String value) async {
    try {
      await db.from('orders').update({'status':value})
        .eq('id',id)
        .eq('courier_id',db.auth.currentUser!.id);
      await refresh();
    } catch(e) {
      if(mounted)ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content:Text('Erreur : $e')),
      );
    }
  }

  String label(String s)=>{
    'ready':'Prête à être livrée',
    'courier_assigned':'Livraison acceptée',
    'picked_up':'Commande récupérée',
    'on_the_way':'En route vers le client',
    'delivered':'Livrée',
  }[s]??s;

  @override Widget build(BuildContext context){
    if(loading)return const Scaffold(
      body:Center(child:CircularProgressIndicator()),
    );

    return Scaffold(
      appBar:AppBar(
        title:const Text('BILET FOOD • LIVREUR'),
        actions:[
          IconButton(onPressed:refresh,icon:const Icon(Icons.refresh)),
          IconButton(onPressed:()=>db.auth.signOut(),icon:const Icon(Icons.logout)),
        ],
      ),
      body:error!=null
        ? Center(child:Text('Erreur : $error'))
        : RefreshIndicator(
            onRefresh:refresh,
            child:ListView(
              padding:const EdgeInsets.all(16),
              children:[
                Text(
                  '${widget.profile['full_name']??'Livreur'}',
                  style:const TextStyle(fontSize:26,fontWeight:FontWeight.bold),
                ),
                const Text('Livraisons'),
                const SizedBox(height:12),
                if(orders.isEmpty)
                  const Card(
                    child:Padding(
                      padding:EdgeInsets.all(20),
                      child:Text('Aucune livraison disponible.'),
                    ),
                  ),
                for(final o in orders)
                  Card(
                    child:Padding(
                      padding:const EdgeInsets.all(12),
                      child:Column(
                        crossAxisAlignment:CrossAxisAlignment.start,
                        children:[
                          Text(
                            '${o['order_number']??o['id']}',
                            style:const TextStyle(
                              fontSize:18,
                              fontWeight:FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height:5),
                          Text('Client : ${o['customer_name']??''}'),
                          Text('Téléphone : ${o['customer_phone']??''}'),
                          Text('Adresse : ${o['delivery_address']??''}'),
                          Text('Total : ${o['total']} FCFA'),
                          Text(
                            label('${o['status']}'),
                            style:const TextStyle(fontWeight:FontWeight.bold),
                          ),
                          const SizedBox(height:10),
                          Wrap(
                            spacing:8,
                            runSpacing:8,
                            children:[
                              if(o['status']=='ready') ...[
                                FilledButton(
                                  onPressed:()=>accept(o),
                                  child:const Text('ACCEPTER'),
                                ),
                                OutlinedButton(
                                  onPressed:()=>reject(o),
                                  child:const Text('REFUSER'),
                                ),
                              ],
                              if(o['status']=='courier_assigned')
                                FilledButton(
                                  onPressed:()=>status(o['id'],'picked_up'),
                                  child:const Text('RÉCUPÉRÉE'),
                                ),
                              if(o['status']=='picked_up')
                                FilledButton(
                                  onPressed:()=>status(o['id'],'on_the_way'),
                                  child:const Text('EN ROUTE'),
                                ),
                              if(o['status']=='on_the_way')
                                FilledButton(
                                  onPressed:()=>status(o['id'],'delivered'),
                                  child:const Text('LIVRÉE'),
                                ),
                              if(o['status']=='delivered')
                                const Chip(
                                  avatar:Icon(Icons.check_circle),
                                  label:Text('LIVRAISON TERMINÉE'),
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
    );
  }
}


class AdminHome extends StatefulWidget {
  final Map<String,dynamic> profile;
  const AdminHome({super.key,required this.profile});
  @override State<AdminHome> createState()=>_AdminHomeState();
}

class _AdminHomeState extends State<AdminHome> {
  int tab=0;
  bool loading=true;
  String? error;
  List<Map<String,dynamic>> orders=[];
  List<Map<String,dynamic>> profiles=[];
  List<Map<String,dynamic>> restaurantsList=[];
  double commissionPercent=10;
  int deliveryFee=500;
  bool cashEnabled=true, orangeEnabled=false, mtnEnabled=false, waveEnabled=false, moovEnabled=false;
  String orangeNumber='', mtnNumber='', waveNumber='', moovNumber='';
  RealtimeChannel? channel, restaurantsChannel, settingsChannel;

  @override void initState(){
    super.initState();
    load();
    channel=db.channel('final-admin-orders')
      .onPostgresChanges(
        event:PostgresChangeEvent.all,
        schema:'public',
        table:'orders',
        callback:(_)=>loadOrders(),
      ).subscribe();
    restaurantsChannel=db.channel('final-admin-restaurants')
      .onPostgresChanges(event:PostgresChangeEvent.all,schema:'public',table:'restaurants',callback:(_)=>loadRestaurants())
      .subscribe();
    settingsChannel=db.channel('final-admin-settings')
      .onPostgresChanges(event:PostgresChangeEvent.all,schema:'public',table:'bilet_food_settings',callback:(_)=>loadSettings())
      .subscribe();
  }

  @override void dispose(){
    if(channel!=null)db.removeChannel(channel!);
    if(restaurantsChannel!=null)db.removeChannel(restaurantsChannel!);
    if(settingsChannel!=null)db.removeChannel(settingsChannel!);
    super.dispose();
  }

  Future<void> load() async {
    try {
      // Charger d'abord les paramètres : loadOrders utilise le taux de commission courant.
      await loadSettings();
      await Future.wait([loadOrders(),loadProfiles(),loadRestaurants()]);
      if(mounted)setState((){
        loading=false;
        error=null;
      });
    } catch(e) {
      if(mounted)setState((){
        loading=false;
        error='$e';
      });
    }
  }

  Future<void> loadOrders() async {
    final x=await db.from('orders').select().order('created_at',ascending:false);
    final loaded=List<Map<String,dynamic>>.from(x);
    final rs=await db.from('restaurants').select('id,name');
    final restaurantNames=<String,String>{
      for(final r in List<Map<String,dynamic>>.from(rs))
        '${r['id']}':'${r['name']}'
    };

    for(final o in loaded){
      o['restaurant_name']=restaurantNames['${o['restaurant_id']}']??'Restaurant #${o['restaurant_id']}';
      final total=num.tryParse('${o['total']??0}')??0;
      final settled=o['settlement_status']=='paid';
      final expectedCommission=(total*commissionPercent/100).round();
      final expectedNet=total-expectedCommission;
      final mobile=o['payment_method']=='Mobile Money';
      final normalizedPayment=mobile &&
          (o['payment_status']==null || o['payment_status']=='pending')
          ? 'verification_pending'
          : o['payment_status'];

      if(!settled && total>0){
        o['commission_amount']=expectedCommission;
        o['restaurant_net_amount']=expectedNet;
      }
      o['payment_status']=normalizedPayment;

      // Synchroniser la base pour que Finances et Règlements lisent les mêmes valeurs.
      final needsFinance=!settled && total>0 &&
          ((num.tryParse('${o['commission_amount']??0}')??0)!=expectedCommission ||
           (num.tryParse('${o['restaurant_net_amount']??0}')??0)!=expectedNet);
      final dbCommission=num.tryParse('${List<Map<String,dynamic>>.from(x).firstWhere((z)=>z['id']==o['id'])['commission_amount']??0}')??0;
      final dbNet=num.tryParse('${List<Map<String,dynamic>>.from(x).firstWhere((z)=>z['id']==o['id'])['restaurant_net_amount']??0}')??0;
      final dbPayment=List<Map<String,dynamic>>.from(x).firstWhere((z)=>z['id']==o['id'])['payment_status'];
      final update=<String,dynamic>{};
      if(!settled && total>0 && (dbCommission!=expectedCommission || dbNet!=expectedNet)){
        update['commission_amount']=expectedCommission;
        update['restaurant_net_amount']=expectedNet;
      }
      if(normalizedPayment!=dbPayment)update['payment_status']=normalizedPayment;
      if(update.isNotEmpty){
        try{await db.from('orders').update(update).eq('id',o['id']);}catch(_){}
      }
    }
    if(mounted)setState(()=>orders=loaded);
  }

  Future<void> loadProfiles() async {
    final x=await db.from('profiles').select();
    if(mounted)setState(()=>profiles=List<Map<String,dynamic>>.from(x));
  }

  Future<void> loadRestaurants() async {
    final x=await db.from('restaurants').select().order('name');
    if(mounted)setState(()=>restaurantsList=List<Map<String,dynamic>>.from(x));
  }

  Future<void> loadSettings() async {
    try {
      final s=await db.from('bilet_food_settings').select().eq('id',1).single();
      if(mounted)setState((){
        commissionPercent=double.tryParse('${s['commission_percent']}')??10;
        deliveryFee=int.tryParse('${s['delivery_fee']??s['minimum_delivery_fee']??500}')??500;
        cashEnabled=s['cash_enabled']??true;
        orangeEnabled=s['orange_money_enabled']??false;
        mtnEnabled=s['mtn_momo_enabled']??false;
        waveEnabled=s['wave_enabled']??false;
        moovEnabled=s['moov_money_enabled']??false;
        orangeNumber='${s['orange_money_number']??''}';
        mtnNumber='${s['mtn_momo_number']??''}';
        waveNumber='${s['wave_number']??''}';
        moovNumber='${s['moov_money_number']??''}';
      });
    } catch(_) {}
  }

  Future<void> calculate(dynamic id) async {
    try {
      await db.rpc('bilet_compute_order_finance',params:{'p_order_id':id});
      await loadOrders();
      if(mounted)ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content:Text('Commission calculée avec succès.')),
      );
    } catch(e) {
      if(mounted)ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content:Text('Erreur calcul commission : $e')),
      );
    }
  }

  int countRole(String role)=>
      profiles.where((p)=>'${p['role']}'.toLowerCase()==role).length;

  num get totalSales=>orders.fold<num>(
    0,(s,o)=>s+((o['total']??0) as num),
  );

  @override Widget build(BuildContext context) {
    if(loading)return const Scaffold(
      body:Center(child:CircularProgressIndicator()),
    );

    final pages=[
      AdminDashboard(
        clients:countRole('client'),
        restaurants:countRole('restaurant'),
        couriers:countRole('courier'),
        orders:orders.length,
        totalSales:totalSales,
        commissionPercent:commissionPercent,
      ),
      AdminOrders(orders:orders),
      AdminManagement(
        profiles:profiles,
        restaurants:restaurantsList,
        onChanged:load,
      ),
      AdminFinance(
        orders:orders,
        commissionPercent:commissionPercent,
        calculate:calculate,
      ),
      AdminSettlements(
        orders:orders,
        onChanged:load,
      ),
      AdminStats(
        orders:orders,
        commissionPercent:commissionPercent,
      ),
      AdminSettings(
        commissionPercent:commissionPercent,
        deliveryFee:deliveryFee,
        cashEnabled:cashEnabled,
        orangeEnabled:orangeEnabled,
        mtnEnabled:mtnEnabled,
        waveEnabled:waveEnabled,
        moovEnabled:moovEnabled,
        orangeNumber:orangeNumber,
        mtnNumber:mtnNumber,
        waveNumber:waveNumber,
        moovNumber:moovNumber,
        onSaved:load,
      ),
    ];

    return Scaffold(
      appBar:AppBar(
        title:const Text('BILET FOOD • ADMIN'),
        actions:[
          IconButton(onPressed:load,icon:const Icon(Icons.refresh)),
          IconButton(onPressed:()=>db.auth.signOut(),icon:const Icon(Icons.logout)),
        ],
      ),
      body:error!=null
        ? Center(child:Text('Erreur : $error'))
        : IndexedStack(index:tab,children:pages),
      bottomNavigationBar:NavigationBar(
        selectedIndex:tab,
        onDestinationSelected:(i)=>setState(()=>tab=i),
        destinations:const[
          NavigationDestination(
            icon:Icon(Icons.dashboard),
            label:'Tableau de bord',
          ),
          NavigationDestination(
            icon:Icon(Icons.receipt_long),
            label:'Commandes',
          ),
          NavigationDestination(
            icon:Icon(Icons.manage_accounts),
            label:'Gestion',
          ),
          NavigationDestination(
            icon:Icon(Icons.account_balance_wallet),
            label:'Finances',
          ),
          NavigationDestination(
            icon:Icon(Icons.account_balance),
            label:'Règlements',
          ),
          NavigationDestination(
            icon:Icon(Icons.bar_chart),
            label:'Stats',
          ),
          NavigationDestination(
            icon:Icon(Icons.settings),
            label:'Paramètres',
          ),
        ],
      ),
    );
  }
}

class AdminDashboard extends StatelessWidget {
  final int clients,restaurants,couriers,orders;
  final num totalSales;
  final double commissionPercent;
  const AdminDashboard({
    super.key,
    required this.clients,
    required this.restaurants,
    required this.couriers,
    required this.orders,
    required this.totalSales,
    required this.commissionPercent,
  });

  Widget box(String title,String value,IconData icon)=>Card(
    child:Padding(
      padding:const EdgeInsets.all(18),
      child:SizedBox(
        width:210,
        child:Column(
          crossAxisAlignment:CrossAxisAlignment.start,
          children:[
            Icon(icon,size:34,color:brand),
            const SizedBox(height:10),
            Text(value,style:const TextStyle(fontSize:27,fontWeight:FontWeight.bold)),
            Text(title),
          ],
        ),
      ),
    ),
  );

  @override Widget build(BuildContext context)=>ListView(
    padding:const EdgeInsets.all(18),
    children:[
      const Text(
        'Tableau de bord',
        style:TextStyle(fontSize:28,fontWeight:FontWeight.bold),
      ),
      const SizedBox(height:14),
      Wrap(
        spacing:12,
        runSpacing:12,
        children:[
          box('Clients','$clients',Icons.people),
          box('Restaurants','$restaurants',Icons.restaurant),
          box('Livreurs','$couriers',Icons.delivery_dining),
          box('Commandes','$orders',Icons.receipt_long),
          box('Volume commandes','$totalSales FCFA',Icons.payments),
          box('Commission','$commissionPercent %',Icons.percent),
        ],
      ),
    ],
  );
}

class AdminOrders extends StatelessWidget {
  final List<Map<String,dynamic>> orders;
  const AdminOrders({super.key,required this.orders});

  String label(String s)=>{
    'pending':'Envoyée',
    'accepted':'Acceptée',
    'rejected':'Refusée',
    'preparing':'En préparation',
    'ready':'Prête',
    'courier_assigned':'Livreur assigné',
    'picked_up':'Récupérée',
    'on_the_way':'En route',
    'delivered':'Livrée',
  }[s]??s;

  @override Widget build(BuildContext context)=>ListView(
    padding:const EdgeInsets.all(16),
    children:[
      const Text(
        'Toutes les commandes',
        style:TextStyle(fontSize:26,fontWeight:FontWeight.bold),
      ),
      const SizedBox(height:10),
      if(orders.isEmpty)
        const Card(
          child:Padding(
            padding:EdgeInsets.all(20),
            child:Text('Aucune commande.'),
          ),
        ),
      for(final o in orders)
        Card(
          child:ListTile(
            title:Text(
              '${o['order_number']??o['id']}',
              style:const TextStyle(fontWeight:FontWeight.bold),
            ),
            subtitle:Text(
              '${o['restaurant_name']??'Restaurant'} • ${o['total']} FCFA\n'
              '${label('${o['status']}')} • '
              '${o['payment_method']??'Paiement non choisi'} • '
              '${o['payment_status']??'En attente'}',
            ),
            isThreeLine:true,
          ),
        ),
    ],
  );
}

class AdminFinance extends StatelessWidget {
  final List<Map<String,dynamic>> orders;
  final double commissionPercent;
  final Future<void> Function(dynamic) calculate;

  const AdminFinance({
    super.key,
    required this.orders,
    required this.commissionPercent,
    required this.calculate,
  });

  @override Widget build(BuildContext context)=>ListView(
    padding:const EdgeInsets.all(16),
    children:[
      Text(
        'Finances • Commission $commissionPercent %',
        style:const TextStyle(fontSize:26,fontWeight:FontWeight.bold),
      ),
      const SizedBox(height:10),
      for(final o in orders)
        Card(
          child:Padding(
            padding:const EdgeInsets.all(12),
            child:Column(
              crossAxisAlignment:CrossAxisAlignment.start,
              children:[
                Text(
                  '${o['order_number']??o['id']} • ${o['total']} F',
                  style:const TextStyle(fontWeight:FontWeight.bold),
                ),
                const SizedBox(height:6),
                Text('Commission : ${o['commission_amount']??0} F'),
                Text('Net restaurant : ${o['restaurant_net_amount']??0} F'),
                Text('Règlement : ${o['settlement_status']??'pending'}'),
                const SizedBox(height:8),
                FilledButton(
                  onPressed:()=>calculate(o['id']),
                  child:const Text('CALCULER'),
                ),
              ],
            ),
          ),
        ),
    ],
  );
}


class AdminSettings extends StatefulWidget {
  final double commissionPercent;
  final int deliveryFee;
  final bool cashEnabled,orangeEnabled,mtnEnabled,waveEnabled,moovEnabled;
  final String orangeNumber,mtnNumber,waveNumber,moovNumber;
  final Future<void> Function() onSaved;
  const AdminSettings({
    super.key,
    required this.commissionPercent,
    required this.deliveryFee,
    required this.cashEnabled,
    required this.orangeEnabled,
    required this.mtnEnabled,
    required this.waveEnabled,
    required this.moovEnabled,
    required this.orangeNumber,
    required this.mtnNumber,
    required this.waveNumber,
    required this.moovNumber,
    required this.onSaved,
  });
  @override State<AdminSettings> createState()=>_AdminSettingsState();
}

class _AdminSettingsState extends State<AdminSettings> {
  late final TextEditingController commission;
  late final TextEditingController delivery,orange,mtn,wave,moov;
  late bool cashOn,orangeOn,mtnOn,waveOn,moovOn;
  bool saving=false;

  @override void initState(){
    super.initState();
    commission=TextEditingController(
      text:widget.commissionPercent.toString().replaceAll('.0',''),
    );
    delivery=TextEditingController(text:'${widget.deliveryFee}');
    orange=TextEditingController(text:widget.orangeNumber);
    mtn=TextEditingController(text:widget.mtnNumber);
    wave=TextEditingController(text:widget.waveNumber);
    moov=TextEditingController(text:widget.moovNumber);
    cashOn=widget.cashEnabled; orangeOn=widget.orangeEnabled;
    mtnOn=widget.mtnEnabled; waveOn=widget.waveEnabled; moovOn=widget.moovEnabled;
  }

  @override void dispose(){
    commission.dispose();
    delivery.dispose(); orange.dispose(); mtn.dispose(); wave.dispose(); moov.dispose();
    super.dispose();
  }

  Future<void> save() async {
    final value=double.tryParse(commission.text.trim().replaceAll(',','.'));
    final fee=int.tryParse(delivery.text.trim());

    if(value==null || value<0 || value>100){
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content:Text('Entrez une commission entre 0 et 100 %.')),
      );
      return;
    }
    if(fee==null || fee<0){
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content:Text('Entrez des frais de livraison valides.')),
      );
      return;
    }

    setState(()=>saving=true);
    try {
      final rows=await db
          .from('bilet_food_settings')
          .update({
            'commission_percent':value,
            'minimum_delivery_fee':fee,
            'cash_enabled':cashOn,
            'orange_money_enabled':orangeOn,
            'orange_money_number':orange.text.trim(),
            'mtn_momo_enabled':mtnOn,
            'mtn_momo_number':mtn.text.trim(),
            'wave_enabled':waveOn,
            'wave_number':wave.text.trim(),
            'moov_money_enabled':moovOn,
            'moov_money_number':moov.text.trim(),
          })
          .eq('id',1)
          .select('id, commission_percent');

      if(rows.isEmpty){
        throw Exception(
          'Aucun paramètre modifié. Vérifiez les droits Admin Supabase.',
        );
      }

      await widget.onSaved();

      if(mounted){
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content:Text(
              'Paramètres enregistrés • Commission $value % • Paiements mis à jour.',
            ),
          ),
        );
      }
    } catch(e) {
      if(mounted){
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content:Text('Erreur paramètres : $e')),
        );
      }
    } finally {
      if(mounted)setState(()=>saving=false);
    }
  }

  @override Widget build(BuildContext context)=>ListView(
    padding:const EdgeInsets.all(18),
    children:[
      const Text(
        'Paramètres',
        style:TextStyle(fontSize:28,fontWeight:FontWeight.bold),
      ),
      const SizedBox(height:8),
      const Text(
        'Réglages commerciaux de BILET FOOD',
        style:TextStyle(fontSize:16),
      ),
      const SizedBox(height:20),
      Card(
        child:Padding(
          padding:const EdgeInsets.all(18),
          child:SizedBox(
            width:480,
            child:Column(
              crossAxisAlignment:CrossAxisAlignment.start,
              children:[
                const Text(
                  'Commission BILET FOOD',
                  style:TextStyle(fontSize:20,fontWeight:FontWeight.bold),
                ),
                const SizedBox(height:6),
                const Text(
                  'Pourcentage prélevé sur les commandes pour le calcul des finances.',
                ),
                const SizedBox(height:16),
                TextField(
                  controller:commission,
                  keyboardType:const TextInputType.numberWithOptions(decimal:true),
                  decoration:const InputDecoration(
                    labelText:'Commission (%)',
                    suffixText:'%',
                    border:OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height:14),
                TextField(
                  controller:delivery,
                  keyboardType:TextInputType.number,
                  decoration:const InputDecoration(
                    labelText:'Frais minimum de livraison (FCFA)',
                    suffixText:'F',
                    border:OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height:14),
                const Divider(height:32),
                const Text('Moyens de paiement',style:TextStyle(fontSize:20,fontWeight:FontWeight.bold)),
                SwitchListTile(contentPadding:EdgeInsets.zero,value:cashOn,onChanged:(v)=>setState(()=>cashOn=v),title:const Text('Espèces')),
                SwitchListTile(contentPadding:EdgeInsets.zero,value:orangeOn,onChanged:(v)=>setState(()=>orangeOn=v),title:const Text('Orange Money')),
                if(orangeOn) TextField(controller:orange,decoration:const InputDecoration(labelText:'Numéro Orange Money',border:OutlineInputBorder())),
                SwitchListTile(contentPadding:EdgeInsets.zero,value:mtnOn,onChanged:(v)=>setState(()=>mtnOn=v),title:const Text('MTN MoMo')),
                if(mtnOn) TextField(controller:mtn,decoration:const InputDecoration(labelText:'Numéro MTN MoMo',border:OutlineInputBorder())),
                SwitchListTile(contentPadding:EdgeInsets.zero,value:waveOn,onChanged:(v)=>setState(()=>waveOn=v),title:const Text('Wave')),
                if(waveOn) TextField(controller:wave,decoration:const InputDecoration(labelText:'Numéro Wave',border:OutlineInputBorder())),
                SwitchListTile(contentPadding:EdgeInsets.zero,value:moovOn,onChanged:(v)=>setState(()=>moovOn=v),title:const Text('Moov Money')),
                if(moovOn) TextField(controller:moov,decoration:const InputDecoration(labelText:'Numéro Moov Money',border:OutlineInputBorder())),
                const SizedBox(height:14),
                FilledButton.icon(
                  onPressed:saving?null:save,
                  icon:const Icon(Icons.save),
                  label:Text(saving?'ENREGISTREMENT...':'ENREGISTRER'),
                ),
              ],
            ),
          ),
        ),
      ),
      const SizedBox(height:12),
      const Card(
        child:ListTile(
          leading:Icon(Icons.info_outline),
          title:Text('Application du nouveau taux'),
          subtitle:Text(
            'Le nouveau pourcentage sera utilisé lors du prochain calcul de commission des commandes.',
          ),
        ),
      ),
    ],
  );
}


class AdminManagement extends StatefulWidget {
  final List<Map<String,dynamic>> profiles;
  final List<Map<String,dynamic>> restaurants;
  final Future<void> Function() onChanged;
  const AdminManagement({super.key,required this.profiles,required this.restaurants,required this.onChanged});
  @override State<AdminManagement> createState()=>_AdminManagementState();
}

class _AdminManagementState extends State<AdminManagement> {
  Future<void> toggleRestaurant(Map<String,dynamic> r)async{
    try{
      await db.from('restaurants').update({'is_open':r['is_open']!=true}).eq('id',r['id']);
      await widget.onChanged();
    }catch(e){if(mounted)ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text('Erreur restaurant : $e')));}
  }

  Future<void> restaurantDialog([Map<String,dynamic>? r])async{
    final name=TextEditingController(text:'${r?['name']??''}');
    final address=TextEditingController(text:'${r?['address']??''}');
    final phone=TextEditingController(text:'${r?['phone']??''}');
    bool open=r?['is_open']??true;
    final ok=await showDialog<bool>(context:context,builder:(c)=>StatefulBuilder(builder:(c,setD)=>AlertDialog(
      title:Text(r==null?'Ajouter un restaurant':'Modifier le restaurant'),
      content:SizedBox(width:460,child:SingleChildScrollView(child:Column(mainAxisSize:MainAxisSize.min,children:[
        TextField(controller:name,decoration:const InputDecoration(labelText:'Nom du restaurant',border:OutlineInputBorder())),
        const SizedBox(height:10),
        TextField(controller:address,decoration:const InputDecoration(labelText:'Adresse',border:OutlineInputBorder())),
        const SizedBox(height:10),
        TextField(controller:phone,decoration:const InputDecoration(labelText:'Téléphone',border:OutlineInputBorder())),
        SwitchListTile(contentPadding:EdgeInsets.zero,value:open,onChanged:(v)=>setD(()=>open=v),title:const Text('Restaurant ouvert / visible chez le client')),
      ]))),
      actions:[
        TextButton(onPressed:()=>Navigator.pop(c,false),child:const Text('ANNULER')),
        FilledButton(onPressed:()=>Navigator.pop(c,true),child:Text(r==null?'AJOUTER':'ENREGISTRER')),
      ],
    )));
    if(ok==true&&name.text.trim().isNotEmpty){
      try{
        final data={'name':name.text.trim(),'address':address.text.trim(),'phone':phone.text.trim(),'is_open':open};
        if(r==null){await db.from('restaurants').insert(data);}
        else{await db.from('restaurants').update(data).eq('id',r['id']);}
        await widget.onChanged();
        if(mounted)ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text(r==null?'Restaurant ajouté.':'Restaurant modifié.')));
      }catch(e){if(mounted)ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text('Erreur restaurant : $e')));}
    }
    name.dispose();address.dispose();phone.dispose();
  }

  Future<void> linkRestaurant(Map<String,dynamic> p)async{
    if(widget.restaurants.isEmpty){
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:Text('Créez d’abord un restaurant.')));
      return;
    }
    dynamic selected=p['restaurant_id']??widget.restaurants.first['id'];
    final ok=await showDialog<bool>(context:context,builder:(c)=>StatefulBuilder(builder:(c,setD)=>AlertDialog(
      title:Text('Rattacher ${p['full_name']??p['email']??'le compte'}'),
      content:DropdownButtonFormField<dynamic>(
        initialValue:selected,
        decoration:const InputDecoration(labelText:'Restaurant',border:OutlineInputBorder()),
        items:[for(final r in widget.restaurants)DropdownMenuItem(value:r['id'],child:Text('${r['name']}'))],
        onChanged:(v)=>setD(()=>selected=v),
      ),
      actions:[
        TextButton(onPressed:()=>Navigator.pop(c,false),child:const Text('ANNULER')),
        FilledButton(onPressed:()=>Navigator.pop(c,true),child:const Text('RATTACHER')),
      ],
    )));
    if(ok==true){
      try{
        await db.from('profiles').update({'role':'restaurant','restaurant_id':selected}).eq('id',p['id']);
        final check=await db.from('profiles').select('id,role,restaurant_id').eq('id',p['id']).single();
        final savedId=check['restaurant_id'];
        if(savedId==null || savedId.toString()!=selected.toString()){
          throw Exception('Le rattachement n’a pas été enregistré dans Supabase.');
        }
        await widget.onChanged();
        if(mounted){
          final rn=restaurantName(savedId);
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text('Compte rattaché à $rn.')));
        }
      }catch(e){if(mounted)ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text('Erreur rattachement : $e')));}
    }
  }

  Future<void> setCourier(Map<String,dynamic> p)async{
    try{
      await db.from('profiles').update({'role':'courier','restaurant_id':null}).eq('id',p['id']);
      await widget.onChanged();
      if(mounted)ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:Text('Compte défini comme LIVREUR.')));
    }catch(e){if(mounted)ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text('Erreur compte : $e')));}
  }

  Future<void> setClient(Map<String,dynamic> p)async{
    try{
      await db.from('profiles').update({'role':'client','restaurant_id':null}).eq('id',p['id']);
      await widget.onChanged();
      if(mounted)ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:Text('Compte défini comme CLIENT.')));
    }catch(e){if(mounted)ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text('Erreur compte : $e')));}
  }

  String roleLabel(String r)=>{'client':'Client','restaurant':'Restaurant','courier':'Livreur','admin':'Administrateur'}[r]??r;
  String restaurantName(dynamic id){
    for(final r in widget.restaurants){if(r['id'].toString()==id?.toString())return '${r['name']}';}
    return 'Non rattaché';
  }

  @override Widget build(BuildContext context)=>ListView(
    padding:const EdgeInsets.all(16),
    children:[
      Row(children:[
        const Expanded(child:Text('Gestion',style:TextStyle(fontSize:28,fontWeight:FontWeight.bold))),
        FilledButton.icon(onPressed:()=>restaurantDialog(),icon:const Icon(Icons.add_business),label:const Text('AJOUTER RESTAURANT')),
      ]),
      const SizedBox(height:12),
      const Text('Restaurants',style:TextStyle(fontSize:21,fontWeight:FontWeight.bold)),
      for(final r in widget.restaurants)Card(child:ListTile(
        leading:Icon(r['is_open']==true?Icons.storefront:Icons.storefront_outlined),
        title:Text('${r['name']}'),
        subtitle:Text('${r['address']??''}${('${r['phone']??''}').isNotEmpty?' • ${r['phone']}':''}\n${r['is_open']==true?'OUVERT • visible chez le client':'FERMÉ • masqué chez le client'}'),
        isThreeLine:true,
        trailing:SizedBox(width:145,child:Row(mainAxisAlignment:MainAxisAlignment.end,children:[
          Switch(value:r['is_open']==true,onChanged:(_)=>toggleRestaurant(r)),
          IconButton(onPressed:()=>restaurantDialog(r),icon:const Icon(Icons.edit)),
        ])),
      )),
      const SizedBox(height:18),
      const Text('Comptes et profils',style:TextStyle(fontSize:21,fontWeight:FontWeight.bold)),
      const SizedBox(height:4),
      const Text('Utilisez le menu ⋮ pour rattacher un compte à un restaurant ou le définir comme Livreur/Client.'),
      for(final p in widget.profiles)Card(child:ListTile(
        leading:CircleAvatar(child:Icon(p['role']=='restaurant'?Icons.restaurant:p['role']=='courier'?Icons.delivery_dining:p['role']=='admin'?Icons.admin_panel_settings:Icons.person)),
        title:Text('${p['full_name']??p['email']??p['id']}'),
        subtitle:Text(
          '${roleLabel('${p['role']}')}'
          '${p['role']=='restaurant'?' • ${restaurantName(p['restaurant_id'])}':''}',
        ),
        trailing:p['role']=='admin'?const Chip(label:Text('ADMIN')):PopupMenuButton<String>(
          tooltip:'Gérer le compte',
          onSelected:(v){
            if(v=='restaurant')linkRestaurant(p);
            if(v=='courier')setCourier(p);
            if(v=='client')setClient(p);
          },
          itemBuilder:(_)=>const[
            PopupMenuItem(value:'restaurant',child:Text('RATTACHER À UN RESTAURANT')),
            PopupMenuItem(value:'courier',child:Text('DÉFINIR COMME LIVREUR')),
            PopupMenuItem(value:'client',child:Text('DÉFINIR COMME CLIENT')),
          ],
        ),
      )),
    ],
  );
}

class AdminStats extends StatelessWidget {
  final List<Map<String,dynamic>> orders;
  final double commissionPercent;
  const AdminStats({
    super.key,
    required this.orders,
    required this.commissionPercent,
  });

  num sumWhere(bool Function(Map<String,dynamic>) test)=>
      orders.where(test).fold<num>(0,(s,o)=>s+((o['total']??0) as num));

  @override Widget build(BuildContext context) {
    final delivered=orders.where((o)=>o['status']=='delivered').length;
    final pending=orders.where((o)=>o['status']=='pending').length;
    final rejected=orders.where((o)=>o['status']=='rejected').length;
    final deliveredSales=sumWhere((o)=>o['status']=='delivered');
    final estimatedCommission=deliveredSales*commissionPercent/100;

    Widget stat(String title,String value,IconData icon)=>Card(
      child:ListTile(
        leading:Icon(icon,size:34,color:brand),
        title:Text(value,style:const TextStyle(fontSize:22,fontWeight:FontWeight.bold)),
        subtitle:Text(title),
      ),
    );

    return ListView(
      padding:const EdgeInsets.all(16),
      children:[
        const Text('Statistiques',style:TextStyle(fontSize:28,fontWeight:FontWeight.bold)),
        const SizedBox(height:12),
        stat('Commandes totales','${orders.length}',Icons.receipt_long),
        stat('Commandes livrées','$delivered',Icons.check_circle),
        stat('Commandes en attente','$pending',Icons.hourglass_top),
        stat('Commandes refusées','$rejected',Icons.cancel),
        stat('CA des commandes livrées','$deliveredSales FCFA',Icons.payments),
        stat(
          'Commission estimée à $commissionPercent %',
          '${estimatedCommission.round()} FCFA',
          Icons.percent,
        ),
      ],
    );
  }
}


class AdminSettlements extends StatefulWidget {
  final List<Map<String,dynamic>> orders;
  final Future<void> Function() onChanged;
  const AdminSettlements({
    super.key,
    required this.orders,
    required this.onChanged,
  });
  @override State<AdminSettlements> createState()=>_AdminSettlementsState();
}

class _AdminSettlementsState extends State<AdminSettlements> {
  bool busy=false;
  RealtimeChannel? paymentChannel;

  @override void initState(){
    super.initState();
    paymentChannel=db.channel('admin-payments-live')
      .onPostgresChanges(
        event:PostgresChangeEvent.all,
        schema:'public',
        table:'orders',
        callback:(_)=>widget.onChanged(),
      ).subscribe();
  }

  @override void dispose(){
    if(paymentChannel!=null)db.removeChannel(paymentChannel!);
    super.dispose();
  }

  num n(dynamic v)=>v is num?v:(num.tryParse('$v')??0);

  num get totalCommission=>widget.orders.fold<num>(
    0,(s,o)=>s+n(o['commission_amount']),
  );

  num get recoveredCommission=>widget.orders
      .where((o)=>o['settlement_status']=='paid')
      .fold<num>(0,(s,o)=>s+n(o['commission_amount']));

  num get commissionToRecover=>widget.orders
      .where((o)=>o['settlement_status']!='paid')
      .fold<num>(0,(s,o)=>s+n(o['commission_amount']));

  num get restaurantToPay=>widget.orders
      .where((o)=>o['settlement_status']!='paid')
      .fold<num>(0,(s,o)=>s+n(o['restaurant_net_amount']));

  Future<void> verifyPayment(Map<String,dynamic> o) async {
    setState(()=>busy=true);
    try {
      final uid=db.auth.currentUser!.id;
      final rows=await db.from('orders').update({
        'payment_status':'paid',
        'payment_verified_at':DateTime.now().toUtc().toIso8601String(),
        'payment_verified_by':uid,
      }).eq('id',o['id']).select('id,payment_status');

      if(rows.isEmpty){
        throw Exception('Paiement non modifié. Vérifiez les droits Admin.');
      }
      await widget.onChanged();
      if(mounted)ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content:Text('PAIEMENT REÇU confirmé.')),
      );
    } catch(e) {
      if(mounted)ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content:Text('Erreur vérification paiement : $e')),
      );
    } finally {
      if(mounted)setState(()=>busy=false);
    }
  }

  Future<void> markPaid(Map<String,dynamic> o) async {
    setState(()=>busy=true);
    try {
      await db.from('orders').update({
        'settlement_status':'paid',
      }).eq('id',o['id']);

      await widget.onChanged();

      if(mounted)ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content:Text(
            'Règlement enregistré • Commission ${n(o['commission_amount'])} F.',
          ),
        ),
      );
    } catch(e) {
      if(mounted)ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content:Text('Erreur règlement : $e')),
      );
    } finally {
      if(mounted)setState(()=>busy=false);
    }
  }

  Widget amountCard(String title,num amount,IconData icon)=>Card(
    child:Padding(
      padding:const EdgeInsets.all(16),
      child:SizedBox(
        width:230,
        child:Column(
          crossAxisAlignment:CrossAxisAlignment.start,
          children:[
            Icon(icon,size:32,color:brand),
            const SizedBox(height:8),
            Text(
              '${amount.round()} FCFA',
              style:const TextStyle(fontSize:23,fontWeight:FontWeight.bold),
            ),
            Text(title),
          ],
        ),
      ),
    ),
  );

  @override Widget build(BuildContext context) {
    return ListView(
      padding:const EdgeInsets.all(16),
      children:[
        const Text(
          'Règlements & commissions',
          style:TextStyle(fontSize:28,fontWeight:FontWeight.bold),
        ),
        const SizedBox(height:6),
        const Text(
          'Suivi des commissions BILET FOOD et des montants nets dus aux restaurants.',
        ),
        const SizedBox(height:14),
        Wrap(
          spacing:10,
          runSpacing:10,
          children:[
            amountCard(
              'Commission calculée',
              totalCommission,
              Icons.percent,
            ),
            amountCard(
              'Commission récupérée',
              recoveredCommission,
              Icons.savings,
            ),
            amountCard(
              'Commission à récupérer',
              commissionToRecover,
              Icons.pending_actions,
            ),
            amountCard(
              'Net restaurants à régler',
              restaurantToPay,
              Icons.restaurant,
            ),
          ],
        ),
        const SizedBox(height:18),
        const Text(
          'Détail des règlements',
          style:TextStyle(fontSize:21,fontWeight:FontWeight.bold),
        ),
        const SizedBox(height:8),
        for(final o in widget.orders.where(
          (o)=>o['status']=='delivered' ||
               n(o['commission_amount'])>0 ||
               n(o['restaurant_net_amount'])>0 ||
               o['payment_status']=='verification_pending' ||
               o['payment_status']=='paid' ||
               o['payment_method']=='Mobile Money',
        ))
          Card(
            child:Padding(
              padding:const EdgeInsets.all(12),
              child:Column(
                crossAxisAlignment:CrossAxisAlignment.start,
                children:[
                  Text(
                    '${o['order_number']??o['id']}',
                    style:const TextStyle(
                      fontSize:17,
                      fontWeight:FontWeight.bold,
                    ),
                  ),
                  Text('Montant commande : ${n(o['total'])} F'),
                  Text('Commission BILET FOOD : ${n(o['commission_amount'])} F'),
                  Text('Net restaurant : ${n(o['restaurant_net_amount'])} F'),
                  Text(
                    'Mode client : ${o['payment_method']??'Non renseigné'}',
                  ),
                  Text('Opérateur : ${o['payment_operator']??'-'}'),
                  Text('Référence : ${o['payment_reference']??'-'}'),
                  Text(
                    'Paiement : ${o['payment_status']=='verification_pending'?'À vérifier':
                    o['payment_status']=='paid'?'Payé':
                    o['payment_status']=='cash_on_delivery'?'Paiement à la livraison':
                    o['payment_status']??'En attente'}',
                    style:const TextStyle(fontWeight:FontWeight.bold),
                  ),
                  Text(
                    'Statut règlement : ${o['settlement_status']??'pending'}',
                    style:const TextStyle(fontWeight:FontWeight.bold),
                  ),
                  const SizedBox(height:8),
                  Wrap(
                    spacing:8,
                    runSpacing:8,
                    children:[
                      if(o['payment_status']=='verification_pending')
                        FilledButton.icon(
                          onPressed:busy?null:()=>verifyPayment(o),
                          icon:const Icon(Icons.verified),
                          label:const Text('CONFIRMER PAIEMENT REÇU'),
                        ),
                      if(o['payment_status']=='paid' && o['settlement_status']!='paid')
                        FilledButton.icon(
                          onPressed:busy?null:()=>markPaid(o),
                          icon:const Icon(Icons.check),
                          label:const Text('MARQUER RÉGLÉ'),
                        ),
                      if(o['settlement_status']=='paid')
                        const Chip(
                          avatar:Icon(Icons.check_circle),
                          label:Text('RÈGLEMENT TERMINÉ'),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        const SizedBox(height:14),
        const Card(
          child:ListTile(
            leading:Icon(Icons.info_outline),
            title:Text('Paiement indépendant BILET FOOD'),
            subtitle:Text(
              'Les paiements Mobile Money sont vérifiés par l’administrateur à partir '
              'de la référence fournie par le client. Les paiements en espèces sont '
              'encaissés à la livraison.',
            ),
          ),
        ),
      ],
    );
  }
}


class IndependentPaymentPage extends StatefulWidget {
  final List<Map<String,dynamic>> orders;
  const IndependentPaymentPage({super.key,required this.orders});
  @override State<IndependentPaymentPage> createState()=>_IndependentPaymentPageState();
}
class _IndependentPaymentPageState extends State<IndependentPaymentPage>{
  Map<String,dynamic>? settings; bool loading=true;
  RealtimeChannel? settingsChannel;
  @override void initState(){
    super.initState();
    load();
    settingsChannel=db.channel('client-payment-settings-live')
      .onPostgresChanges(
        event:PostgresChangeEvent.all,
        schema:'public',
        table:'bilet_food_settings',
        callback:(_)=>load(),
      ).subscribe();
  }
  @override void dispose(){
    if(settingsChannel!=null)db.removeChannel(settingsChannel!);
    super.dispose();
  }
  Future<void> load()async{
    final s=await db.from('bilet_food_settings').select().eq('id',1).single();
    if(mounted)setState((){settings=s;loading=false;});
  }
  Future<void> choose(Map<String,dynamic> o,String op,String number)async{
    final ref=TextEditingController();
    if(!mounted)return;
    await showDialog(context:context,builder:(c)=>AlertDialog(
      title:Text(op=='cash'?'Paiement en espèces':'Paiement $op'),
      content:Column(mainAxisSize:MainAxisSize.min,crossAxisAlignment:CrossAxisAlignment.start,children:[
        if(op=='cash')const Text('Vous paierez en espèces à la livraison.')
        else ...[
          Text('Envoyez ${o['total']} FCFA au :',style:const TextStyle(fontWeight:FontWeight.bold)),
          SelectableText(number,style:const TextStyle(fontSize:22,fontWeight:FontWeight.bold)),
          const SizedBox(height:12),
          TextField(controller:ref,decoration:const InputDecoration(labelText:'Référence de transaction',border:OutlineInputBorder())),
        ]
      ]),
      actions:[
        TextButton(onPressed:()=>Navigator.pop(c),child:const Text('ANNULER')),
        FilledButton(onPressed:()async{
          if(op!='cash'&&ref.text.trim().isEmpty)return;
          await db.from('orders').update({
            'payment_method':op=='cash'?'Espèces':'Mobile Money',
            'payment_operator':op=='cash'?null:op,
            'payment_reference':op=='cash'?null:ref.text.trim(),
            'payment_status':op=='cash'?'cash_on_delivery':'verification_pending',
          }).eq('id',o['id']);
          if(c.mounted)Navigator.pop(c);
          if(mounted)ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text(op=='cash'?'Espèces sélectionné.':'Paiement envoyé pour vérification.')));
        },child:const Text('VALIDER'))
      ],
    ));
  }
  @override Widget build(BuildContext context){
    if(loading)return const Center(child:CircularProgressIndicator());
    final s=settings!;
    final methods=<Map<String,String>>[];
    if(s['cash_enabled']==true)methods.add({'op':'cash','label':'ESPÈCES','number':''});
    if(s['orange_money_enabled']==true)methods.add({'op':'Orange Money','label':'ORANGE MONEY','number':'${s['orange_money_number']??''}'});
    if(s['mtn_momo_enabled']==true)methods.add({'op':'MTN MoMo','label':'MTN MOMO','number':'${s['mtn_momo_number']??''}'});
    if(s['wave_enabled']==true)methods.add({'op':'Wave','label':'WAVE','number':'${s['wave_number']??''}'});
    if(s['moov_money_enabled']==true)methods.add({'op':'Moov Money','label':'MOOV MONEY','number':'${s['moov_money_number']??''}'});
    return ListView(padding:const EdgeInsets.all(16),children:[
      const Text('Paiement',style:TextStyle(fontSize:26,fontWeight:FontWeight.bold)),
      const Text('BILET FOOD • Paiement indépendant'),
      const SizedBox(height:12),
      for(final o in widget.orders.where((x)=>x['status']!='rejected'))
        Card(child:Padding(padding:const EdgeInsets.all(12),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
          Text('${o['order_number']??o['id']} • ${o['total']} FCFA',style:const TextStyle(fontWeight:FontWeight.bold)),
          Text(
            'Statut : ${o['payment_status']=='verification_pending'?'À vérifier':
            o['payment_status']=='paid'?'Payé':
            o['payment_status']=='cash_on_delivery'?'Paiement à la livraison':
            o['payment_status']??'Non payé'}',
          ),
          if(o['payment_reference']!=null)Text('Référence : ${o['payment_reference']}'),
          const SizedBox(height:8),
          Wrap(
            spacing:8,
            runSpacing:8,
            children:[
              for(final m in methods)
                OutlinedButton(
                  onPressed:()=>choose(o,m['op']!,m['number']!),
                  child:Text(m['label']!),
                ),
            ],
          ),
        ],
      ),
    ),
  ),
    ]);
  }
}
