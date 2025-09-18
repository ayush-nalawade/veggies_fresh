# VeggieFresh - Vegetable Marketplace App

A comprehensive vegetable marketplace application built with Flutter frontend and Node.js backend, featuring user authentication, product catalog, shopping cart, and payment integration.

## 🚀 Features

### Frontend (Flutter)
- **Splash Screen** with smooth animations
- **Authentication** with Google Sign-In and email/password login
- **Product Catalog** with category navigation and search
- **Product Details** with dynamic quantity selection and price calculation
- **Shopping Cart** with real-time updates
- **Checkout Flow** with address collection and payment processing
- **Order History** and user profile management
- **Modern UI** with Material Design 3

### Backend (Node.js)
- **RESTful API** with TypeScript and Express
- **JWT Authentication** with Google OAuth integration
- **MongoDB** database with Mongoose ODM
- **Razorpay Payment** gateway integration
- **Cart Management** with server-side synchronization
- **Order Processing** with payment verification
- **Security** with Helmet, CORS, and rate limiting

## 📱 Screenshots

The app includes:
- Splash screen with VeggieFresh branding
- Login/Register screens with Google Sign-In
- Home screen with featured products and categories
- Product listing with category filtering
- Product detail with quantity selector
- Shopping cart with item management
- Checkout with address form and payment
- Order history and user profile

## 🛠️ Tech Stack

### Frontend
- **Flutter** - Cross-platform mobile framework
- **Riverpod** - State management
- **Go Router** - Navigation
- **Dio** - HTTP client
- **Google Sign-In** - Authentication
- **Razorpay Flutter** - Payment processing
- **Cached Network Image** - Image caching

### Backend
- **Node.js** - Runtime environment
- **Express** - Web framework
- **TypeScript** - Type safety
- **MongoDB** - Database
- **Mongoose** - ODM
- **JWT** - Authentication tokens
- **Razorpay** - Payment gateway
- **Passport** - Authentication middleware

## 📋 Prerequisites

- Node.js (v16 or higher)
- MongoDB (local or Atlas)
- Flutter SDK (v3.0 or higher)
- Android Studio / Xcode (for mobile development)
- Razorpay account (for payments)
- Google Cloud Console (for OAuth)

## 🚀 Quick Start

### Backend Setup

1. **Navigate to backend directory:**
   ```bash
   cd veggies_backend
   ```

2. **Install dependencies:**
   ```bash
   npm install
   ```

3. **Set up environment variables:**
   ```bash
   cp env.example .env
   ```
   
   Update `.env` with your configuration:
   ```env
   MONGO_URI=mongodb://localhost:27017/veggiefresh
   JWT_SECRET=your-super-secret-jwt-key-here
   GOOGLE_CLIENT_ID=your-google-client-id
   GOOGLE_CLIENT_SECRET=your-google-client-secret
   RAZORPAY_KEY_ID=your-razorpay-key-id
   RAZORPAY_KEY_SECRET=your-razorpay-key-secret
   PORT=3000
   FRONTEND_URL=http://localhost:3000
   ```

4. **Start the development server:**
   ```bash
   npm run dev
   ```

5. **Seed the database (optional):**
   ```bash
   npm run seed
   ```

### Frontend Setup

1. **Navigate to Flutter directory:**
   ```bash
   cd veggies_pro_Frontend
   ```

2. **Install dependencies:**
   ```bash
   flutter pub get
   ```

3. **Update environment configuration:**
   Edit `lib/core/env.dart` with your API base URL and Razorpay key:
   ```dart
   class Env {
     static const String apiBase = 'http://localhost:3000';
     static const String razorpayKeyId = 'YOUR_RAZORPAY_KEY_ID';
     static const String googleClientId = 'YOUR_GOOGLE_CLIENT_ID';
   }
   ```

4. **Run the app:**
   ```bash
   flutter run
   ```

## 🔧 Configuration

### Razorpay Setup
1. Create a Razorpay account at [razorpay.com](https://razorpay.com)
2. Get your API keys from the dashboard
3. Update the keys in both backend `.env` and frontend `env.dart`

### Google OAuth Setup
1. Go to [Google Cloud Console](https://console.cloud.google.com)
2. Create a new project or select existing
3. Enable Google+ API
4. Create OAuth 2.0 credentials
5. Add your app's package name and SHA-1 fingerprint
6. Update the client ID in both backend and frontend

### MongoDB Setup
- **Local:** Install MongoDB locally and use `mongodb://localhost:27017/veggiefresh`
- **Atlas:** Create a cluster on MongoDB Atlas and use the connection string

## 📁 Project Structure

```
veggies_pro/
├── veggies_backend/           # Node.js backend
│   ├── src/
│   │   ├── controllers/      # Route controllers
│   │   ├── models/          # MongoDB models
│   │   ├── routes/          # API routes
│   │   ├── middlewares/     # Custom middlewares
│   │   ├── utils/           # Utility functions
│   │   └── scripts/         # Database seeding
│   ├── package.json
│   └── tsconfig.json
├── veggies_pro_Frontend/     # Flutter frontend
│   ├── lib/
│   │   ├── core/            # Core utilities
│   │   ├── features/        # Feature modules
│   │   ├── models/          # Data models
│   │   └── main.dart
│   └── pubspec.yaml
└── README.md
```

## 🔌 API Endpoints

### Authentication
- `POST /auth/register` - User registration
- `POST /auth/login` - User login
- `GET /auth/google/url` - Google OAuth URL
- `GET /auth/google/callback` - Google OAuth callback

### Products & Categories
- `GET /categories` - Get all categories
- `GET /products` - Get products with filters
- `GET /products/:id` - Get product details

### Cart
- `GET /cart` - Get user cart
- `POST /cart/items` - Add item to cart
- `PATCH /cart/items/:productId` - Update cart item
- `DELETE /cart/items/:productId` - Remove cart item
- `DELETE /cart` - Clear cart

### Checkout
- `POST /checkout/address` - Save delivery address
- `POST /checkout/create-order` - Create Razorpay order
- `POST /checkout/verify-payment` - Verify payment

### Orders
- `GET /orders` - Get user orders
- `GET /orders/:id` - Get order details

## 🎨 UI/UX Features

- **Material Design 3** with custom theme
- **Responsive Design** for different screen sizes
- **Smooth Animations** and transitions
- **Loading States** and error handling
- **Pull-to-refresh** functionality
- **Image Caching** for better performance
- **Offline Support** (basic)

## 🔒 Security Features

- **JWT Authentication** with refresh tokens
- **Input Validation** with Zod schemas
- **Rate Limiting** on authentication routes
- **CORS Protection** with strict origins
- **Helmet Security** headers
- **Password Hashing** with bcrypt
- **Payment Verification** with HMAC signatures

## 🚀 Deployment

### Backend Deployment
1. Build the TypeScript code:
   ```bash
   npm run build
   ```

2. Deploy to your preferred platform (Heroku, AWS, DigitalOcean, etc.)

3. Set environment variables in your deployment platform

### Frontend Deployment
1. Build for your target platform:
   ```bash
   flutter build apk  # Android
   flutter build ios  # iOS
   flutter build web  # Web
   ```

2. Deploy to app stores or web hosting

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch
3. Commit your changes
4. Push to the branch
5. Create a Pull Request

## 📄 License

This project is licensed under the MIT License - see the LICENSE file for details.

## 🆘 Support

For support, email support@veggiefresh.com or create an issue in the repository.

## 🙏 Acknowledgments

- Flutter team for the amazing framework
- Node.js community for excellent packages
- Razorpay for payment integration
- Google for OAuth services
