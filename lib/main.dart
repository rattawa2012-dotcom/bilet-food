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
  Future<void> go()async{setState(()=>busy=true);try{await db.auth.signInWithPassword(email:e.text.trim(),password:p.text);}catch(x){if(mounted)ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text('Connexion impossible : $x')));}finally{if(mounted)setState(()=>busy=false);}}
  @override void dispose(){e.dispose();p.dispose();super.dispose();}
  @override Widget build(BuildContext c)=>Scaffold(body:Center(child:SizedBox(width:430,child:Card(child:Padding(padding:const EdgeInsets.all(24),child:Column(mainAxisSize:MainAxisSize.min,children:[
    const Icon(Icons.delivery_dining,size:72,color:brand),const Text('BILET FOOD',style:TextStyle(fontSize:28,fontWeight:FontWeight.bold)),const SizedBox(height:20),
    TextField(controller:e,decoration:const InputDecoration(labelText:'E-mail',border:OutlineInputBorder())),const SizedBox(height:10),
    TextField(controller:p,obscureText:true,onSubmitted:(_){if(!busy)go();},decoration:const InputDecoration(labelText:'Mot de passe',border:OutlineInputBorder())),const SizedBox(height:14),
    FilledButton(onPressed:busy?null:go,style:FilledButton.styleFrom(backgroundColor:brand,minimumSize:const Size.fromHeight(50)),child:Text(busy?'Connexion...':'SE CONNECTER'))
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
  int tab=0; List<Map<String,dynamic>> orders=[],notes=[]; RealtimeChannel? oc,nc;
  @override void initState(){super.initState();refresh();oc=db.channel('final-orders').onPostgresChanges(event:PostgresChangeEvent.all,schema:'public',table:'orders',callback:(_)=>loadOrders()).subscribe();nc=db.channel('final-notes').onPostgresChanges(event:PostgresChangeEvent.all,schema:'public',table:'notifications',callback:(_)=>loadNotes()).subscribe();}
  @override void dispose(){if(oc!=null)db.removeChannel(oc!);if(nc!=null)db.removeChannel(nc!);super.dispose();}
  Future<void> refresh()async{await Future.wait([loadOrders(),loadNotes()]);}
  Future<void> loadOrders()async{try{final x=await db.from('orders').select().eq('client_id',db.auth.currentUser!.id).order('created_at',ascending:false);if(mounted)setState(()=>orders=List<Map<String,dynamic>>.from(x));}catch(_){}}
  Future<void> loadNotes()async{try{final x=await db.from('notifications').select().eq('user_id',db.auth.currentUser!.id).order('created_at',ascending:false);if(mounted)setState(()=>notes=List<Map<String,dynamic>>.from(x));}catch(_){}}
  Future<void> pay(dynamic id,String m)async{try{final v=m=='cash'?'Espèces':m=='mobile_money'?'Mobile Money':'Paiement en ligne';await db.from('orders').update({'payment_method':v,'payment_status':'En attente'}).eq('id',id);await loadOrders();if(mounted)ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text('$v sélectionné')));}catch(e){if(mounted)ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text('Erreur paiement : $e')));}}
  Future<void> read(dynamic id)async{await db.from('notifications').update({'is_read':true}).eq('id',id);await loadNotes();}
  String label(String s)=>{'pending':'Commande envoyée','accepted':'Acceptée par le restaurant','rejected':'Refusée','preparing':'En préparation','ready':'Prête pour livraison','courier_assigned':'Livreur assigné','picked_up':'Récupérée par le livreur','on_the_way':'Livreur en route','delivered':'Livrée'}[s]??s;
  double progress(String s)=>{'pending':.1,'accepted':.25,'preparing':.4,'ready':.55,'courier_assigned':.65,'picked_up':.75,'on_the_way':.9,'delivered':1.0,'rejected':0.0}[s]??.05;
  @override Widget build(BuildContext c){
    final pages=[Restaurants(profile:widget.profile,onCreated:()async{await loadOrders();if(mounted)setState(()=>tab=1);}),Orders(orders:orders,label:label,progress:progress),Payments(orders:orders,pay:pay),Notes(notes:notes,read:read)];
    return Scaffold(appBar:AppBar(title:const Text('BILET FOOD'),actions:[IconButton(onPressed:refresh,icon:const Icon(Icons.refresh)),IconButton(onPressed:()=>db.auth.signOut(),icon:const Icon(Icons.logout))]),body:IndexedStack(index:tab,children:pages),bottomNavigationBar:NavigationBar(selectedIndex:tab,onDestinationSelected:(i)=>setState(()=>tab=i),destinations:[
      const NavigationDestination(icon:Icon(Icons.restaurant),label:'Restaurants'),const NavigationDestination(icon:Icon(Icons.receipt_long),label:'Commandes'),const NavigationDestination(icon:Icon(Icons.payments),label:'Paiement'),
      NavigationDestination(icon:Badge(isLabelVisible:notes.any((n)=>n['is_read']!=true),child:const Icon(Icons.notifications)),label:'Notifications')
    ]));
  }
}
class Restaurants extends StatefulWidget{final Map<String,dynamic> profile;final Future<void> Function() onCreated;const Restaurants({super.key,required this.profile,required this.onCreated});@override State<Restaurants> createState()=>_Restaurants();}
class _Restaurants extends State<Restaurants>{
  List<Map<String,dynamic>> rs=[],cats=[],items=[];Map<String,dynamic>? restaurant;final Map<int,Line> cart={};bool loading=true;String? err;
  @override void initState(){super.initState();load();}
  Future<void> load()async{try{final x=await db.from('restaurants').select().eq('is_open',true).order('name');if(mounted)setState((){rs=List<Map<String,dynamic>>.from(x);loading=false;});}catch(e){if(mounted)setState((){err='$e';loading=false;});}}
  Future<void> open(Map<String,dynamic> r)async{try{final c=await db.from('menu_categories').select().eq('restaurant_id',r['id']).order('sort_order');final m=await db.from('menu_items').select().eq('restaurant_id',r['id']).eq('is_available',true).order('name');if(mounted)setState((){restaurant=r;cats=List<Map<String,dynamic>>.from(c);items=List<Map<String,dynamic>>.from(m);cart.clear();});}catch(e){if(mounted)ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text('Erreur catalogue : $e')));}}
  int get subtotal=>cart.values.fold(0,(s,l)=>s+(l.item['price'] as num).toInt()*l.qty);int get count=>cart.values.fold(0,(s,l)=>s+l.qty);
  void add(Map<String,dynamic> i){final id=i['id'] as int;setState((){cart.containsKey(id)?cart[id]!.qty++:cart[id]=Line(i,1);});}
  String cat(dynamic id){for(final c in cats){if(c['id']==id)return '${c['name']}';}return 'Menu';}
  Future<void> checkout()async{
    final a=TextEditingController(text:'${widget.profile['address']??''}'),p=TextEditingController(text:'${widget.profile['phone']??''}');const delivery=500;
    final ok=await showDialog<bool>(context:context,builder:(x)=>AlertDialog(title:const Text('Confirmer la commande'),content:SizedBox(width:420,child:Column(mainAxisSize:MainAxisSize.min,children:[TextField(controller:a,decoration:const InputDecoration(labelText:'Adresse de livraison',border:OutlineInputBorder())),const SizedBox(height:10),TextField(controller:p,decoration:const InputDecoration(labelText:'Téléphone',border:OutlineInputBorder())),const SizedBox(height:15),Text('Sous-total : $subtotal FCFA'),const Text('Livraison : 500 FCFA'),Text('TOTAL : ${subtotal+delivery} FCFA',style:const TextStyle(fontWeight:FontWeight.bold))])),actions:[TextButton(onPressed:()=>Navigator.pop(x,false),child:const Text('ANNULER')),FilledButton(onPressed:()=>Navigator.pop(x,true),child:const Text('COMMANDER'))]));
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
class Payments extends StatelessWidget{final List<Map<String,dynamic>> orders;final Future<void> Function(dynamic,String) pay;const Payments({super.key,required this.orders,required this.pay});@override Widget build(BuildContext c)=>ListView(padding:const EdgeInsets.all(16),children:[const Text('Paiement des commandes',style:TextStyle(fontSize:25,fontWeight:FontWeight.bold)),for(final o in orders)Card(child:Padding(padding:const EdgeInsets.all(12),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Text('${o['order_number']??o['id']}',style:const TextStyle(fontWeight:FontWeight.bold)),Text('Total : ${o['total']} FCFA'),Text('Mode : ${o['payment_method']??'Non choisi'}'),Text('Statut : ${o['payment_status']??'En attente'}'),const SizedBox(height:10),Wrap(spacing:8,runSpacing:8,children:[OutlinedButton(onPressed:()=>pay(o['id'],'cash'),child:const Text('ESPÈCES')),OutlinedButton(onPressed:()=>pay(o['id'],'mobile_money'),child:const Text('MOBILE MONEY')),FilledButton(onPressed:()=>pay(o['id'],'online'),child:const Text('PAIEMENT EN LIGNE'))])])))]);}
class Notes extends StatelessWidget{final List<Map<String,dynamic>> notes;final Future<void> Function(dynamic) read;const Notes({super.key,required this.notes,required this.read});@override Widget build(BuildContext c)=>notes.isEmpty?const Center(child:Text('Aucune notification')):ListView(padding:const EdgeInsets.all(16),children:[const Text('Notifications',style:TextStyle(fontSize:26,fontWeight:FontWeight.bold)),for(final n in notes)Card(child:ListTile(leading:Icon(n['is_read']==true?Icons.notifications_none:Icons.notifications_active),title:Text('${n['title']}'),subtitle:Text('${n['message']}'),trailing:n['is_read']==true?null:TextButton(onPressed:()=>read(n['id']),child:const Text('LU'))))]);}


class RestaurantHome extends StatefulWidget {
  final Map<String,dynamic> profile;
  const RestaurantHome({super.key, required this.profile});
  @override State<RestaurantHome> createState()=>_RestaurantHomeState();
}

class _RestaurantHomeState extends State<RestaurantHome> {
  List<Map<String,dynamic>> orders=[];
  bool loading=true;
  String? error;
  RealtimeChannel? channel;

  @override void initState(){
    super.initState();
    refresh();
    channel=db.channel('final-restaurant-orders-${db.auth.currentUser!.id}')
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
      final rid=widget.profile['restaurant_id'];
      if(rid==null) throw Exception('Aucun restaurant rattaché à ce compte.');
      final x=await db.from('orders')
        .select()
        .eq('restaurant_id',rid)
        .order('created_at',ascending:false);
      if(mounted)setState((){
        orders=List<Map<String,dynamic>>.from(x);
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

  Future<void> setStatus(dynamic id,String status) async {
    try {
      await db.from('orders').update({'status':status}).eq('id',id);
      await refresh();
    } catch(e) {
      if(mounted)ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content:Text('Erreur : $e')),
      );
    }
  }

  Future<List<Map<String,dynamic>>> loadLines(dynamic orderId) async {
    final x = await db
        .from('order_items')
        .select('id, order_id, product_name, quantity, unit_price, line_total')
        .eq('order_id', orderId);
    return List<Map<String,dynamic>>.from(x);
  }

  Future<void> showDetail(Map<String,dynamic> o) async {
    try {
      final lines=await loadLines(o['id']);
      if(!mounted)return;
      showDialog(
        context:context,
        builder:(ctx)=>AlertDialog(
          title:Text('Commande ${o['order_number']??o['id']}'),
          content:SizedBox(
            width:480,
            child:ListView(
              shrinkWrap:true,
              children:[
                Text('Client : ${o['customer_name']??''}'),
                Text('Téléphone : ${o['customer_phone']??''}'),
                Text('Adresse : ${o['delivery_address']??''}'),
                const Divider(),
                if(lines.isEmpty)
                  const Padding(
                    padding:EdgeInsets.symmetric(vertical:12),
                    child:Text(
                      'Aucun détail article enregistré pour cette ancienne commande.',
                      style:TextStyle(fontStyle:FontStyle.italic),
                    ),
                  ),
                for(final i in lines)
                  ListTile(
                    title:Text('${i['product_name']??i['name']??'Article'}'),
                    subtitle:Text('${i['quantity']??i['qty']??0} × ${i['unit_price']??i['price']??0} F'),
                    trailing:Text('${i['line_total']??((i['unit_price']??i['price']??0) as num)*(i['quantity']??i['qty']??0)} F'),
                  ),
                const Divider(),
                Text(
                  'TOTAL : ${o['total']} FCFA',
                  style:const TextStyle(fontWeight:FontWeight.bold),
                ),
              ],
            ),
          ),
          actions:[
            TextButton(
              onPressed:()=>Navigator.pop(ctx),
              child:const Text('FERMER'),
            ),
          ],
        ),
      );
    } catch(e) {
      if(mounted)ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content:Text('Erreur détail : $e')),
      );
    }
  }

  String statusLabel(String s)=>{
    'pending':'Nouvelle commande',
    'accepted':'Acceptée',
    'rejected':'Refusée',
    'preparing':'En préparation',
    'ready':'Prête',
    'courier_assigned':'Livreur assigné',
    'picked_up':'Récupérée',
    'on_the_way':'En livraison',
    'delivered':'Livrée',
  }[s]??s;

  @override Widget build(BuildContext context) {
    if(loading)return const Scaffold(body:Center(child:CircularProgressIndicator()));

    return Scaffold(
      appBar:AppBar(
        title:const Text('BILET FOOD • RESTAURANT'),
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
                  '${widget.profile['business_name']??widget.profile['full_name']??'Restaurant'}',
                  style:const TextStyle(fontSize:26,fontWeight:FontWeight.bold),
                ),
                const SizedBox(height:4),
                const Text('Commandes reçues'),
                const SizedBox(height:12),
                if(orders.isEmpty)
                  const Card(
                    child:Padding(
                      padding:EdgeInsets.all(20),
                      child:Text('Aucune commande reçue.'),
                    ),
                  ),
                for(final o in orders)
                  Card(
                    child:Padding(
                      padding:const EdgeInsets.all(12),
                      child:Column(
                        crossAxisAlignment:CrossAxisAlignment.start,
                        children:[
                          ListTile(
                            contentPadding:EdgeInsets.zero,
                            title:Text(
                              '${o['order_number']??o['id']}',
                              style:const TextStyle(fontWeight:FontWeight.bold),
                            ),
                            subtitle:Text(
                              '${o['customer_name']??'Client'} • ${o['total']} F\n${statusLabel('${o['status']}')}',
                            ),
                            isThreeLine:true,
                            trailing:IconButton(
                              tooltip:'Voir le détail',
                              onPressed:()=>showDetail(o),
                              icon:const Icon(Icons.visibility),
                            ),
                          ),
                          Wrap(
                            spacing:8,
                            runSpacing:8,
                            children:[
                              if(o['status']=='pending') ...[
                                FilledButton(
                                  onPressed:()=>setStatus(o['id'],'accepted'),
                                  child:const Text('ACCEPTER'),
                                ),
                                OutlinedButton(
                                  onPressed:()=>setStatus(o['id'],'rejected'),
                                  child:const Text('REFUSER'),
                                ),
                              ],
                              if(o['status']=='accepted')
                                FilledButton(
                                  onPressed:()=>setStatus(o['id'],'preparing'),
                                  child:const Text('PRÉPARATION'),
                                ),
                              if(o['status']=='preparing')
                                FilledButton(
                                  onPressed:()=>setStatus(o['id'],'ready'),
                                  child:const Text('PRÊTE'),
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


class CourierHome extends StatefulWidget {
  final Map<String,dynamic> profile;
  const CourierHome({super.key, required this.profile});
  @override State<CourierHome> createState()=>_CourierHomeState();
}

class _CourierHomeState extends State<CourierHome> {
  List<Map<String,dynamic>> orders=[];
  bool loading=true;
  String? error;
  RealtimeChannel? channel;

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
  RealtimeChannel? channel;

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
  }

  @override void dispose(){
    if(channel!=null)db.removeChannel(channel!);
    super.dispose();
  }

  Future<void> load() async {
    try {
      await Future.wait([loadOrders(),loadProfiles(),loadRestaurants(),loadSettings()]);
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
    if(mounted)setState(()=>orders=List<Map<String,dynamic>>.from(x));
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
      AdminStats(
        orders:orders,
        commissionPercent:commissionPercent,
      ),
      AdminSettings(
        commissionPercent:commissionPercent,
        deliveryFee:deliveryFee,
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
              '${o['customer_name']??'Client'} • ${o['total']} FCFA\n'
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
  final Future<void> Function() onSaved;
  const AdminSettings({
    super.key,
    required this.commissionPercent,
    required this.deliveryFee,
    required this.onSaved,
  });
  @override State<AdminSettings> createState()=>_AdminSettingsState();
}

class _AdminSettingsState extends State<AdminSettings> {
  late final TextEditingController commission;
  late final TextEditingController delivery;
  bool saving=false;

  @override void initState(){
    super.initState();
    commission=TextEditingController(
      text:widget.commissionPercent.toString().replaceAll('.0',''),
    );
    delivery=TextEditingController(text:'${widget.deliveryFee}');
  }

  @override void dispose(){
    commission.dispose();
    delivery.dispose();
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
      await db.from('bilet_food_settings').upsert({
        'id':1,
        'commission_percent':value,
      });
      await widget.onSaved();
      if(mounted)ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content:Text('Paramètres enregistrés : commission $value % • livraison $fee F.')),
      );
    } catch(e) {
      if(mounted)ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content:Text('Erreur paramètres : $e')),
      );
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
  const AdminManagement({
    super.key,
    required this.profiles,
    required this.restaurants,
    required this.onChanged,
  });
  @override State<AdminManagement> createState()=>_AdminManagementState();
}

class _AdminManagementState extends State<AdminManagement> {
  Future<void> toggleRestaurant(Map<String,dynamic> r) async {
    try {
      await db.from('restaurants').update({
        'is_open':r['is_open']!=true,
      }).eq('id',r['id']);
      await widget.onChanged();
    } catch(e) {
      if(mounted)ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content:Text('Erreur restaurant : $e')),
      );
    }
  }

  String roleLabel(String r)=>{
    'client':'Client',
    'restaurant':'Restaurant',
    'courier':'Livreur',
    'admin':'Administrateur',
  }[r]??r;

  @override Widget build(BuildContext context)=>ListView(
    padding:const EdgeInsets.all(16),
    children:[
      const Text('Gestion',style:TextStyle(fontSize:28,fontWeight:FontWeight.bold)),
      const SizedBox(height:12),
      const Text('Restaurants',style:TextStyle(fontSize:21,fontWeight:FontWeight.bold)),
      for(final r in widget.restaurants)
        Card(
          child:SwitchListTile(
            value:r['is_open']==true,
            onChanged:(_)=>toggleRestaurant(r),
            secondary:const Icon(Icons.restaurant),
            title:Text('${r['name']}'),
            subtitle:Text(r['is_open']==true?'OUVERT':'FERMÉ'),
          ),
        ),
      const SizedBox(height:18),
      const Text('Comptes et profils',style:TextStyle(fontSize:21,fontWeight:FontWeight.bold)),
      for(final p in widget.profiles)
        Card(
          child:ListTile(
            leading:CircleAvatar(
              child:Icon(
                p['role']=='restaurant'?Icons.restaurant:
                p['role']=='courier'?Icons.delivery_dining:
                p['role']=='admin'?Icons.admin_panel_settings:Icons.person,
              ),
            ),
            title:Text('${p['full_name']??p['email']??p['id']}'),
            subtitle:Text(
              '${roleLabel('${p['role']}')}'
              '${p['restaurant_id']!=null?' • Restaurant ID ${p['restaurant_id']}':''}',
            ),
          ),
        ),
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
