1) High-level architecture

Frontend (Flutter): Riverpod (or Bloc), go_router, Dio, Google Sign-In, Razorpay Flutter SDK, cached_network_image.

Backend (Node/Express): TypeScript, MongoDB (Atlas), Mongoose, JWT auth, Passport (Google OAuth), Zod for validation, Stripe (optional global cards) or Razorpay (India, UPI + cards) for payments, Cloudinary (images), PM2.

Infra/DevOps: .env + dotenv, CORS, Helmet, Rate-limit, Cloudflared/ngrok for local mobile testing; later deploy on Linux VM + Nginx reverse proxy + Cloudflare proxy.

Storage: MongoDB collections (users, categories, products, carts, orders, payments).

Flows:

Splash → Onboarding → Login (Google/Email)

Browse categories → Product list → Product detail (choose unit & quantity → dynamic price) → Add to cart

Cart → Address → Checkout → Razorpay (UPI/card) → Webhook verifies → Order success

2) Data model (MongoDB)
// user.ts
interface Address { line1:string; line2?:string; city:string; state:string; pincode:string; phone:string; }
export interface User {
  _id: ObjectId;
  name: string;
  email: string;
  googleId?: string;
  passwordHash?: string;
  avatarUrl?: string;
  addresses: Address[];
  role: 'user'|'admin';
  createdAt: Date;
}

// category.ts
export interface Category { _id:ObjectId; name:string; iconUrl?:string; sort:number; isActive:boolean; }

// product.ts
export interface UnitPrice { // supports kg/gm/pcs
  unit: 'kg'|'g'|'pcs'|'bundle';
  step: number;              // e.g. 0.25 for 250g
  baseQty: number;           // 1 kg, 1 pcs
  price: number;             // price for baseQty
  compareAt?: number;        // MRP
  stock: number;             // in base units
}
export interface Product {
  _id:ObjectId; name:string; slug:string; categoryId:ObjectId;
  images: string[]; description?:string; unitPrices: UnitPrice[];
  rating?: number; isActive:boolean; createdAt:Date;
}

// cart.ts
export interface CartItem {
  productId:ObjectId; name:string; image:string;
  unit:'kg'|'g'|'pcs'|'bundle'; qty:number; // qty in chosen unit
  unitPrice:number;                         // price per baseQty
  price:number;                             // computed line total
}
export interface Cart { _id:ObjectId; userId:ObjectId; items:CartItem[]; subtotal:number; }

// order.ts
export interface Order {
  _id:ObjectId; userId:ObjectId; items:CartItem[];
  address: Address; subtotal:number; deliveryFee:number; total:number;
  payment: { provider:'razorpay'|'stripe'; status:'created'|'paid'|'failed'; orderId?:string; paymentId?:string; signature?:string; };
  status:'placed'|'confirmed'|'preparing'|'out_for_delivery'|'delivered'|'cancelled';
  createdAt:Date;
}

Price math (server)

If user selects 750g and base is 1kg at ₹80 → price = 0.75 × 80 = ₹60 (round to 2 decimals).

For ‘pcs’, price = qty × unitPrice.

3) REST API (JWT secured)
POST   /auth/register                  {name,email,password}
POST   /auth/login                     {email,password}
GET    /auth/google/url                → Redirect URL
GET    /auth/google/callback           → sets JWT (mobile: return tokens)

GET    /categories
GET    /products?category=..&q=..&limit=..&page=..
GET    /products/:id

// cart (stored server-side so it syncs across devices)
GET    /cart
POST   /cart/items                     {productId, unit, qty}
PATCH  /cart/items/:productId          {unit?, qty?}
DELETE /cart/items/:productId
DELETE /cart                           (clear)

// checkout
POST   /checkout/address               {address}
POST   /checkout/create-order          → {razorpayOrderId, amount}
POST   /checkout/verify-payment        {razorpayOrderId, paymentId, signature}
GET    /orders
GET    /orders/:id

// admin (optional)
POST   /admin/products
PATCH  /admin/products/:id

4) Payment (UPI + cards for India)

Razorpay recommended: supports UPI, cards, netbanking; has Flutter SDK.

Flow:

Client hits /checkout/create-order with cart; server recalculates amount and calls Razorpay Orders API; returns order_id.

Flutter opens Razorpay checkout with order_id.

On success, Flutter sends {orderId,paymentId,signature} to /checkout/verify-payment.

Server verifies HMAC (secret) → mark Order.payment.status='paid' then respond success.

5) Cursor prompts (backend)

One-shot project scaffold

Create a TypeScript Node.js Express API called "veggiefresh-api".
Use: express, mongoose, zod, jsonwebtoken, bcrypt, cors, helmet, express-rate-limit, passport, passport-google-oauth20, razorpay.
Structure with src/ (config, routes, controllers, models, middlewares, utils).
Add MongoDB models for User, Category, Product, Cart, Order as described below.
Implement JWT auth (email/password + Google OAuth) and all REST endpoints in this spec:
[PASTE the API list from section 3].
Implement price calculation for variable weights (kg/g/pcs) and server-side cart totals.
Add Razorpay createOrder + verify webhook and verifyPayment endpoint.
Protect routes with auth middleware. Use Zod schemas for request validation.
Add .env usage for MONGO_URI, JWT_SECRET, GOOGLE_CLIENT_ID/SECRET, RAZORPAY_KEY_ID/SECRET.
Seed script to insert sample categories/products.
Return consistent JSON {success,data,error}.


Controller starter (paste this part as a file when Cursor asks)

// src/utils/pricing.ts
export const computeLine = (qty:number, unitPrice:number, baseQty=1)=> +(qty/baseQty*unitPrice).toFixed(2);

// src/controllers/checkout.ts
import Razorpay from "razorpay";
import crypto from "crypto";
export const createOrder = async (req,res)=>{
  const userId = req.user._id;
  const cart = await Cart.findOne({userId});
  if(!cart || cart.items.length===0) return res.status(400).json({success:false,error:'Cart empty'});
  const amount = Math.round(cart.subtotal * 100); // paise
  const rzr = new Razorpay({key_id:process.env.RAZORPAY_KEY_ID!, key_secret:process.env.RAZORPAY_KEY_SECRET!});
  const order = await rzr.orders.create({amount, currency:"INR", receipt:`ord_${Date.now()}`});
  // create Order doc with status created
  const ord = await Order.create({userId, items:cart.items, subtotal:cart.subtotal, deliveryFee:0, total:cart.subtotal, payment:{provider:'razorpay',status:'created',orderId:order.id}, status:'placed'});
  res.json({success:true, data:{razorpayOrderId:order.id, amount, orderId: ord._id}});
};
export const verifyPayment = async (req,res)=>{
  const {razorpayOrderId, paymentId, signature, orderId} = req.body;
  const sign = crypto.createHmac("sha256", process.env.RAZORPAY_KEY_SECRET!).update(razorpayOrderId+"|"+paymentId).digest("hex");
  if(sign !== signature) return res.status(400).json({success:false,error:'Invalid signature'});
  await Order.findByIdAndUpdate(orderId, {$set:{payment:{provider:'razorpay',status:'paid',orderId:razorpayOrderId,paymentId,signature}}});
  // optionally clear cart
  await Cart.findOneAndUpdate({userId:req.user._id},{items:[],subtotal:0});
  res.json({success:true});
};

6) Flutter app plan
Packages
flutter_riverpod
go_router
dio
google_sign_in
flutter_secure_storage
razorpay_flutter
cached_network_image
intl

Navigation & screens

Splash → Onboarding/Auth

Login/Register (Google + email)

Home (Categories)

ProductListScreen(category)

ProductDetailScreen(product) with unit selector & quantity stepper → dynamic price

CartScreen

AddressScreen

CheckoutScreen → Razorpay → SuccessScreen

OrdersScreen (history)

Folder structure
lib/
  app.dart, router.dart
  core/ (dio_client.dart, env.dart, theme.dart)
  features/
    auth/
    catalog/
    cart/
    checkout/
    orders/
  models/ (user.dart, product.dart, cart.dart)

Models (Dart)
// product.dart
class UnitPrice { final String unit; final double step; final double baseQty; final double price;
  UnitPrice({required this.unit, required this.step, required this.baseQty, required this.price});
  factory UnitPrice.fromJson(Map j)=>UnitPrice(unit:j['unit'],step:(j['step']+0.0),baseQty:(j['baseQty']+0.0),price:(j['price']+0.0));
}
class Product {
  final String id,name,image; final List<UnitPrice> unitPrices;
  Product({required this.id,required this.name,required this.image,required this.unitPrices});
  factory Product.fromJson(Map j)=>Product(id:j['_id'],name:j['name'],image:j['images'][0],unitPrices:(j['unitPrices'] as List).map((e)=>UnitPrice.fromJson(e)).toList());
}

// cart_item.dart
class CartItem {
  final Product product; final String unit; final double qty;
  final double unitPrice; // server-sent
  CartItem({required this.product, required this.unit, required this.qty, required this.unitPrice});
  double get lineTotal => double.parse(((qty / 1.0) * unitPrice).toStringAsFixed(2));
}

Riverpod: Cart provider
final cartProvider = StateNotifierProvider<CartCtrl, List<CartItem>>((ref)=>CartCtrl());
class CartCtrl extends StateNotifier<List<CartItem>>{
  CartCtrl():super([]);
  void add(CartItem item){
    final i = state.indexWhere((e)=>e.product.id==item.product.id && e.unit==item.unit);
    if(i==-1) state=[...state,item]; else {
      final old = state[i];
      state=[...state]..[i]=CartItem(product:old.product,unit:old.unit,qty:old.qty+item.qty,unitPrice:old.unitPrice);
    }
  }
  void updateQty(String productId,String unit,double qty){
    final i = state.indexWhere((e)=>e.product.id==productId && e.unit==unit);
    if(i!=-1){ final it=state[i]; state=[...state]..[i]=CartItem(product:it.product,unit:it.unit,qty:qty,unitPrice:it.unitPrice); }
  }
  double get subtotal => state.fold(0,(s,it)=>s+it.lineTotal);
}

Quantity & price UI (ProductDetail)
class QtySelector extends ConsumerStatefulWidget {
  final Product p;
  const QtySelector({super.key, required this.p});
  @override _QtySelectorState createState()=>_QtySelectorState();
}
class _QtySelectorState extends ConsumerState<QtySelector>{
  int unitIndex=0; double qty=1; // default 1 * base
  @override Widget build(BuildContext context){
    final u = widget.p.unitPrices[unitIndex];
    final price = ((qty/u.baseQty) * u.price);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 8,
          children: List.generate(widget.p.unitPrices.length, (i){
            final up = widget.p.unitPrices[i];
            return ChoiceChip(label: Text("${up.baseQty} ${up.unit}"), selected: unitIndex==i, onSelected: (_){ setState(()=>unitIndex=i); });
          }),
        ),
        const SizedBox(height: 12),
        Row(
          children:[
            IconButton(onPressed:(){ setState(()=>qty = (qty - u.step).clamp(u.step, 100.0)); }, icon: const Icon(Icons.remove)),
            Text("${qty.toStringAsFixed(qty%1==0?0:2)} ${u.unit}"),
            IconButton(onPressed:(){ setState(()=>qty += u.step); }, icon: const Icon(Icons.add)),
            const Spacer(),
            Text("₹${price.toStringAsFixed(2)}", style: Theme.of(context).textTheme.titleLarge)
          ],
        ),
        const SizedBox(height: 12),
        ElevatedButton(
          onPressed:(){
            ref.read(cartProvider.notifier).add(CartItem(product:widget.p, unit:u.unit, qty:qty, unitPrice:u.price));
          },
          child: const Text("Add to Cart"),
        )
      ],
    );
  }
}

Razorpay checkout (Flutter)
final _razorpay = Razorpay();

void startPayment(BuildContext context, double amountPaise, String orderId, String userEmail, String phone) {
  var options = {
    'key': 'RAZORPAY_KEY_ID',
    'amount': amountPaise, // in paise
    'currency': 'INR',
    'name': 'VeggieFresh',
    'order_id': orderId,
    'prefill': {'email': userEmail, 'contact': phone},
  };
  _razorpay.open(options);
}

// Listen to events
_razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, (PaymentSuccessResponse r) async {
  await dio.post('/checkout/verify-payment', data:{'razorpayOrderId': r.orderId, 'paymentId': r.paymentId, 'signature': r.signature, 'orderId': currentOrderId});
});
_razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, (e){ /* show error */ });

Dio client with JWT
final dio = Dio(BaseOptions(baseUrl: Env.apiBase))
  ..interceptors.add(InterceptorsWrapper(onRequest: (o, h) async {
    final token = await storage.read(key: 'token');
    if(token!=null) o.headers['Authorization'] = 'Bearer $token';
    return h.next(o);
  }));

7) UI mapping (from your screenshot)

Categories grid (image + name). Tapping → ProductList for that category.

Product cards: image, name, min price (“from ₹xx”), add button or tap to open detail.

Bottom nav: Home, Categories, Cart, Orders, Account.

8) Security & production checklist

Validate all inputs (Zod).

Recompute prices server-side at checkout; never trust client totals.

Use HTTPS (Cloudflare → Nginx → Node).

JWT rotation (short-lived access, long-lived refresh).

Webhook endpoint from Razorpay (optional) to cross-verify.

Rate limit auth routes; Helmet + CORS strict origins.

PM2 with ecosystem.config.js, auto-restart on crash.

Logs: morgan + Winston, structured JSON.

9) Seed data (quick start)

Categories: Fruits, Vegetables, Dairy, Ghee, etc.

Products example:

{
 "name":"Tomato",
 "category":"Vegetables",
 "images":["https://.../tomato.png"],
 "unitPrices":[
   {"unit":"kg","step":0.25,"baseQty":1,"price":40,"stock":120},
   {"unit":"g","step":250,"baseQty":1000,"price":40,"stock":120000}
 ]
}

10) Two-line Cursor prompts (handy)

Backend CRUD

Generate Express + Mongoose routes/controllers/models for Category and Product per the schema I provide next. Include pagination, search by name, and isActive filter; return JSON {success,data,meta}.


Auth + Google

Add JWT auth (register/login) with bcrypt and Google OAuth using passport-google-oauth20. Expose /auth/google/url and /auth/google/callback that returns access/refresh tokens for mobile.


Cart logic

Implement server-side cart stored in MongoDB keyed by userId with add/update/delete and subtotal recomputation using computeLine(qty, unitPrice, baseQty). Prevent over-qty beyond stock.


Payments

Integrate Razorpay: /checkout/create-order returns {razorpayOrderId, amount}. /checkout/verify-payment validates HMAC and marks Order paid; also clears cart. Add basic order history endpoints.

11) What to build first (1–2 day MVP)

Backend: Auth → Category/Product read → Cart → CreateOrder/Verify.

Flutter: Auth (Google + email), Categories grid → Product list → Detail with QtySelector → Cart → Razorpay flow.

Ship a tiny admin script (seed JSON) instead of a full admin panel for now.