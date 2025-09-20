# VeggieFresh API Documentation

## Overview
VeggieFresh is a vegetable marketplace API built with Node.js, Express, TypeScript, and MongoDB. This API provides endpoints for user authentication, product management, shopping cart functionality, and payment processing.

## Base URL
```
http://localhost:3000
```

## Authentication
Most endpoints require JWT authentication. Include the access token in the Authorization header:
```
Authorization: Bearer <access_token>
```

## Response Format
All API responses follow this format:
```json
{
  "success": true|false,
  "data": {...},
  "error": "error message",
  "meta": {...} // for paginated responses
}
```

---

## 🔐 Authentication Endpoints

### Register User
**POST** `/auth/register`

Register a new user with email and password.

**Request Body:**
```json
{
  "name": "John Doe",
  "email": "john@example.com",
  "password": "password123"
}
```

**Response:**
```json
{
  "success": true,
  "data": {
    "user": {
      "id": "user_id",
      "name": "John Doe",
      "email": "john@example.com",
      "role": "user"
    },
    "accessToken": "jwt_access_token",
    "refreshToken": "jwt_refresh_token"
  }
}
```

### Login User
**POST** `/auth/login`

Login with email and password.

**Request Body:**
```json
{
  "email": "john@example.com",
  "password": "password123"
}
```

**Response:**
```json
{
  "success": true,
  "data": {
    "user": {
      "id": "user_id",
      "name": "John Doe",
      "email": "john@example.com",
      "role": "user"
    },
    "accessToken": "jwt_access_token",
    "refreshToken": "jwt_refresh_token"
  }
}
```

### Get Google Auth URL
**GET** `/auth/google/url`

Get Google OAuth authentication URL.

**Response:**
```json
{
  "success": true,
  "data": {
    "authUrl": "https://accounts.google.com/o/oauth2/v2/auth?..."
  }
}
```

### Google OAuth Callback
**GET** `/auth/google/callback?code=<authorization_code>`

Handle Google OAuth callback.

**Query Parameters:**
- `code` (string, required): Authorization code from Google

**Response:**
```json
{
  "success": true,
  "data": {
    "user": {
      "id": "user_id",
      "name": "John Doe",
      "email": "john@example.com",
      "role": "user"
    },
    "accessToken": "jwt_access_token",
    "refreshToken": "jwt_refresh_token"
  }
}
```

---

## 🏷️ Categories Endpoints

### Get All Categories
**GET** `/categories`

Get all active categories.

**Response:**
```json
{
  "success": true,
  "data": [
    {
      "_id": "category_id",
      "name": "Fruits",
      "iconUrl": "https://example.com/icon.png"
    },
    {
      "_id": "category_id_2",
      "name": "Vegetables",
      "iconUrl": "https://example.com/icon2.png"
    }
  ]
}
```

---

## 🛍️ Products Endpoints

### Get All Products
**GET** `/products`

Get products with optional filtering and pagination.

**Query Parameters:**
- `category` (string, optional): Filter by category ID
- `q` (string, optional): Search query
- `limit` (number, optional): Number of items per page (default: 20)
- `page` (number, optional): Page number (default: 1)

**Example:**
```
GET /products?category=category_id&limit=10&page=1
```

**Response:**
```json
{
  "success": true,
  "data": [
    {
      "_id": "product_id",
      "name": "Fresh Tomatoes",
      "slug": "fresh-tomatoes",
      "images": ["https://example.com/tomato.jpg"],
      "unitPrices": [
        {
          "unit": "kg",
          "step": 0.25,
          "baseQty": 1,
          "price": 40,
          "stock": 50
        }
      ],
      "rating": 4.5
    }
  ],
  "meta": {
    "total": 100,
    "page": 1,
    "limit": 20,
    "pages": 5
  }
}
```

### Get Product by ID
**GET** `/products/:id`

Get detailed information about a specific product.

**Path Parameters:**
- `id` (string, required): Product ID

**Response:**
```json
{
  "success": true,
  "data": {
    "_id": "product_id",
    "name": "Fresh Tomatoes",
    "slug": "fresh-tomatoes",
    "categoryId": {
      "_id": "category_id",
      "name": "Vegetables"
    },
    "images": ["https://example.com/tomato.jpg"],
    "description": "Fresh, juicy tomatoes perfect for salads and cooking",
    "unitPrices": [
      {
        "unit": "kg",
        "step": 0.25,
        "baseQty": 1,
        "price": 40,
        "stock": 50
      },
      {
        "unit": "g",
        "step": 250,
        "baseQty": 1000,
        "price": 40,
        "stock": 50000
      }
    ],
    "rating": 4.5,
    "isActive": true
  }
}
```

---

## 🛒 Cart Endpoints

*All cart endpoints require authentication.*

### Get Cart
**GET** `/cart`

Get user's shopping cart.

**Headers:**
```
Authorization: Bearer <access_token>
```

**Response:**
```json
{
  "success": true,
  "data": {
    "_id": "cart_id",
    "userId": "user_id",
    "items": [
      {
        "productId": "product_id",
        "name": "Fresh Tomatoes",
        "image": "https://example.com/tomato.jpg",
        "unit": "kg",
        "qty": 1.5,
        "unitPrice": 40,
        "price": 60
      }
    ],
    "subtotal": 60
  }
}
```

### Add Item to Cart
**POST** `/cart/items`

Add a product to the cart.

**Headers:**
```
Authorization: Bearer <access_token>
Content-Type: application/json
```

**Request Body:**
```json
{
  "productId": "product_id",
  "unit": "kg",
  "qty": 1.5
}
```

**Response:**
```json
{
  "success": true,
  "data": {
    "_id": "cart_id",
    "userId": "user_id",
    "items": [
      {
        "productId": "product_id",
        "name": "Fresh Tomatoes",
        "image": "https://example.com/tomato.jpg",
        "unit": "kg",
        "qty": 1.5,
        "unitPrice": 40,
        "price": 60
      }
    ],
    "subtotal": 60
  }
}
```

### Update Cart Item
**PATCH** `/cart/items/:productId`

Update quantity or unit of a cart item.

**Path Parameters:**
- `productId` (string, required): Product ID

**Headers:**
```
Authorization: Bearer <access_token>
Content-Type: application/json
```

**Request Body:**
```json
{
  "qty": 2.0,
  "unit": "kg"
}
```

### Remove Item from Cart
**DELETE** `/cart/items/:productId`

Remove a specific item from the cart.

**Path Parameters:**
- `productId` (string, required): Product ID

**Headers:**
```
Authorization: Bearer <access_token>
```

### Clear Cart
**DELETE** `/cart`

Clear all items from the cart.

**Headers:**
```
Authorization: Bearer <access_token>
```

---

## 💳 Checkout Endpoints

*All checkout endpoints require authentication.*

### Save Address
**POST** `/checkout/address`

Save delivery address for checkout.

**Headers:**
```
Authorization: Bearer <access_token>
Content-Type: application/json
```

**Request Body:**
```json
{
  "line1": "123 Main Street",
  "line2": "Apt 4B",
  "city": "Mumbai",
  "state": "Maharashtra",
  "pincode": "400001",
  "phone": "9876543210"
}
```

### Create Order
**POST** `/checkout/create-order`

Create a new order and Razorpay order.

**Headers:**
```
Authorization: Bearer <access_token>
Content-Type: application/json
```

**Request Body:**
```json
{
  "address": {
    "line1": "123 Main Street",
    "line2": "Apt 4B",
    "city": "Mumbai",
    "state": "Maharashtra",
    "pincode": "400001",
    "phone": "9876543210"
  }
}
```

**Response:**
```json
{
  "success": true,
  "data": {
    "razorpayOrderId": "order_1234567890",
    "amount": 6000,
    "orderId": "order_database_id"
  }
}
```

### Verify Payment
**POST** `/checkout/verify-payment`

Verify Razorpay payment and mark order as paid.

**Headers:**
```
Authorization: Bearer <access_token>
Content-Type: application/json
```

**Request Body:**
```json
{
  "razorpayOrderId": "order_1234567890",
  "paymentId": "pay_1234567890",
  "signature": "payment_signature",
  "orderId": "order_database_id"
}
```

**Response:**
```json
{
  "success": true,
  "data": {
    "order": {
      "_id": "order_database_id",
      "userId": "user_id",
      "items": [...],
      "address": {...},
      "subtotal": 60,
      "deliveryFee": 0,
      "total": 60,
      "payment": {
        "provider": "razorpay",
        "status": "paid",
        "orderId": "order_1234567890",
        "paymentId": "pay_1234567890",
        "signature": "payment_signature"
      },
      "status": "confirmed"
    }
  }
}
```

---

## 📦 Orders Endpoints

*All order endpoints require authentication.*

### Get User Orders
**GET** `/orders`

Get user's order history with pagination.

**Headers:**
```
Authorization: Bearer <access_token>
```

**Query Parameters:**
- `page` (number, optional): Page number (default: 1)
- `limit` (number, optional): Number of items per page (default: 10)

**Response:**
```json
{
  "success": true,
  "data": [
    {
      "_id": "order_id",
      "userId": "user_id",
      "items": [...],
      "address": {...},
      "subtotal": 60,
      "deliveryFee": 0,
      "total": 60,
      "payment": {
        "provider": "razorpay",
        "status": "paid"
      },
      "status": "confirmed",
      "createdAt": "2025-01-18T00:00:00.000Z"
    }
  ],
  "meta": {
    "total": 5,
    "page": 1,
    "limit": 10,
    "pages": 1
  }
}
```

### Get Order by ID
**GET** `/orders/:id`

Get detailed information about a specific order.

**Path Parameters:**
- `id` (string, required): Order ID

**Headers:**
```
Authorization: Bearer <access_token>
```

---

## 🏥 Health Check

### Health Check
**GET** `/health`

Check if the API server is running.

**Response:**
```json
{
  "success": true,
  "message": "VeggieFresh API is running!"
}
```

---

## 📝 Data Models

### User
```typescript
interface User {
  _id: ObjectId;
  name: string;
  email: string;
  googleId?: string;
  passwordHash?: string;
  avatarUrl?: string;
  addresses: Address[];
  role: 'user' | 'admin';
  createdAt: Date;
}
```

### Address
```typescript
interface Address {
  line1: string;
  line2?: string;
  city: string;
  state: string;
  pincode: string;
  phone: string;
}
```

### Category
```typescript
interface Category {
  _id: ObjectId;
  name: string;
  iconUrl?: string;
  sort: number;
  isActive: boolean;
}
```

### Product
```typescript
interface Product {
  _id: ObjectId;
  name: string;
  slug: string;
  categoryId: ObjectId;
  images: string[];
  description?: string;
  unitPrices: UnitPrice[];
  rating?: number;
  isActive: boolean;
}
```

### UnitPrice
```typescript
interface UnitPrice {
  unit: 'kg' | 'g' | 'pcs' | 'bundle';
  step: number;
  baseQty: number;
  price: number;
  compareAt?: number;
  stock: number;
}
```

### Cart
```typescript
interface Cart {
  _id: ObjectId;
  userId: ObjectId;
  items: CartItem[];
  subtotal: number;
}
```

### CartItem
```typescript
interface CartItem {
  productId: ObjectId;
  name: string;
  image: string;
  unit: 'kg' | 'g' | 'pcs' | 'bundle';
  qty: number;
  unitPrice: number;
  price: number;
}
```

### Order
```typescript
interface Order {
  _id: ObjectId;
  userId: ObjectId;
  items: CartItem[];
  address: Address;
  subtotal: number;
  deliveryFee: number;
  total: number;
  payment: Payment;
  status: 'placed' | 'confirmed' | 'preparing' | 'out_for_delivery' | 'delivered' | 'cancelled';
  createdAt: Date;
}
```

### Payment
```typescript
interface Payment {
  provider: 'razorpay' | 'stripe';
  status: 'created' | 'paid' | 'failed';
  orderId?: string;
  paymentId?: string;
  signature?: string;
}
```

---

## 🚨 Error Responses

### 400 Bad Request
```json
{
  "success": false,
  "error": "Validation error",
  "details": ["Field is required"]
}
```

### 401 Unauthorized
```json
{
  "success": false,
  "error": "Access token required"
}
```

### 403 Forbidden
```json
{
  "success": false,
  "error": "Invalid token"
}
```

### 404 Not Found
```json
{
  "success": false,
  "error": "Product not found"
}
```

### 500 Internal Server Error
```json
{
  "success": false,
  "error": "Internal server error"
}
```

---

## 🔧 Environment Variables

Create a `.env` file in the backend root directory:

```env
# Database
MONGO_URI=mongodb://localhost:27017/veggiefresh

# JWT
JWT_SECRET=your-super-secret-jwt-key-here
JWT_EXPIRES_IN=7d

# Google OAuth
GOOGLE_CLIENT_ID=your-google-client-id
GOOGLE_CLIENT_SECRET=your-google-client-secret

# Razorpay
RAZORPAY_KEY_ID=your-razorpay-key-id
RAZORPAY_KEY_SECRET=your-razorpay-key-secret

# Server
PORT=3000
NODE_ENV=development

# CORS
FRONTEND_URL=http://localhost:3000
```

---

## 🚀 Getting Started

1. **Install dependencies:**
   ```bash
   npm install
   ```

2. **Set up environment variables:**
   ```bash
   cp env.example .env
   # Edit .env with your configuration
   ```

3. **Start the development server:**
   ```bash
   npm run dev
   ```

4. **Seed the database (optional):**
   ```bash
   npm run seed
   ```

5. **Import the Postman collection:**
   - Import `VeggieFresh_API.postman_collection.json` into Postman
   - Set the `base_url` variable to `http://localhost:3000`
   - Start testing the APIs!

---

## 📋 Testing Workflow

1. **Health Check** - Verify server is running
2. **Register/Login** - Get access token
3. **Get Categories** - Browse available categories
4. **Get Products** - View products
5. **Add to Cart** - Add items to cart
6. **Create Order** - Initiate checkout
7. **Verify Payment** - Complete payment (mock for development)
8. **Get Orders** - View order history

---

## 🔒 Security Features

- JWT authentication with access and refresh tokens
- Password hashing with bcrypt
- Input validation with Zod schemas
- Rate limiting on authentication routes
- CORS protection
- Helmet security headers
- Payment signature verification

---

## 📞 Support

For API support or questions, please refer to the project documentation or create an issue in the repository.
