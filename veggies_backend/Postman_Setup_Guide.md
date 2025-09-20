# Postman Setup Guide for VeggieFresh API

## 📥 Import Files

1. **Import Collection:**
   - Open Postman
   - Click "Import" button
   - Select `VeggieFresh_API.postman_collection.json`
   - Click "Import"

2. **Import Environment:**
   - Click "Import" button again
   - Select `VeggieFresh_Environment.postman_environment.json`
   - Click "Import"

3. **Select Environment:**
   - In the top-right corner, select "VeggieFresh Environment" from the environment dropdown

## 🚀 Quick Start Testing

### Step 1: Health Check
1. Open "Health Check" request
2. Click "Send"
3. Should return: `{"success":true,"message":"VeggieFresh API is running!"}`

### Step 2: Register a User
1. Open "Authentication" → "Register User"
2. Update the request body with your details:
   ```json
   {
     "name": "Your Name",
     "email": "your@email.com",
     "password": "yourpassword"
   }
   ```
3. Click "Send"
4. Copy the `accessToken` from the response
5. Go to Environment variables and set `access_token` to the copied token

### Step 3: Get Categories
1. Open "Categories" → "Get All Categories"
2. Click "Send"
3. Copy a `_id` from the response
4. Set `category_id` in environment variables

### Step 4: Get Products
1. Open "Products" → "Get All Products"
2. Click "Send"
3. Copy a product `_id` from the response
4. Set `product_id` in environment variables

### Step 5: Add to Cart
1. Open "Cart" → "Add Item to Cart"
2. The request body should already have the correct `product_id`
3. Click "Send"

### Step 6: Create Order
1. Open "Checkout" → "Create Order"
2. Update the address in the request body
3. Click "Send"
4. Copy the `orderId` from the response
5. Set `order_id` in environment variables

## 🔧 Environment Variables

The following variables are automatically managed:

| Variable | Description | Example |
|----------|-------------|---------|
| `base_url` | API base URL | `http://localhost:3000` |
| `access_token` | JWT access token | `eyJhbGciOiJIUzI1NiIs...` |
| `user_id` | Current user ID | `68cb5893aeda0c269acde4a2` |
| `product_id` | Selected product ID | `68cb58d467222d3046f07e40` |
| `category_id` | Selected category ID | `68cb58d467222d3046f07e39` |
| `order_id` | Created order ID | `68cb58d467222d3046f07e41` |

## 📋 Testing Checklist

- [ ] Health check returns success
- [ ] User registration works
- [ ] User login works
- [ ] Categories are retrieved
- [ ] Products are retrieved
- [ ] Products can be filtered by category
- [ ] Products can be searched
- [ ] Cart operations work (add, update, remove, clear)
- [ ] Order creation works
- [ ] Payment verification works (mock)
- [ ] Order history is retrieved

## 🐛 Troubleshooting

### Common Issues:

1. **Connection Error:**
   - Ensure backend server is running on `http://localhost:3000`
   - Check if MongoDB is running

2. **401 Unauthorized:**
   - Make sure you've set the `access_token` in environment variables
   - Token might be expired, try logging in again

3. **404 Not Found:**
   - Check if the resource ID exists
   - Ensure you're using the correct endpoint

4. **400 Bad Request:**
   - Check request body format
   - Ensure all required fields are provided

## 🔄 Automated Testing

You can create Postman tests to automate the testing process:

### Example Test Script (for Register User):
```javascript
pm.test("Status code is 201", function () {
    pm.response.to.have.status(201);
});

pm.test("Response has success field", function () {
    var jsonData = pm.response.json();
    pm.expect(jsonData.success).to.eql(true);
});

pm.test("Response has access token", function () {
    var jsonData = pm.response.json();
    pm.expect(jsonData.data.accessToken).to.exist;
    
    // Set access token in environment
    pm.environment.set("access_token", jsonData.data.accessToken);
    pm.environment.set("user_id", jsonData.data.user.id);
});
```

## 📊 Collection Structure

```
VeggieFresh API
├── Health Check
├── Authentication
│   ├── Register User
│   ├── Login User
│   ├── Get Google Auth URL
│   └── Google OAuth Callback
├── Categories
│   └── Get All Categories
├── Products
│   ├── Get All Products
│   ├── Get Products by Category
│   ├── Search Products
│   └── Get Product by ID
├── Cart
│   ├── Get Cart
│   ├── Add Item to Cart
│   ├── Update Cart Item
│   ├── Remove Item from Cart
│   └── Clear Cart
├── Checkout
│   ├── Save Address
│   ├── Create Order
│   └── Verify Payment
└── Orders
    ├── Get User Orders
    └── Get Order by ID
```

## 🎯 Best Practices

1. **Always test Health Check first** to ensure server is running
2. **Register/Login before testing protected endpoints**
3. **Use environment variables** for dynamic data
4. **Test error scenarios** (invalid data, missing fields)
5. **Verify response structure** matches documentation
6. **Clean up test data** after testing

## 📝 Notes

- The API uses JWT tokens for authentication
- Tokens expire after 15 minutes (access) and 7 days (refresh)
- All cart and order operations require authentication
- Payment verification is mocked for development
- The API follows RESTful conventions
- All responses include a `success` field indicating operation status

Happy testing! 🚀
