# MobiLedger CRUD Operations & Authentication Guide

## 📋 Overview
This document describes all CRUD operations and authentication workflows implemented in the MobiLedger app.

---

## 🛍️ PRODUCT CRUD OPERATIONS

### 1. CREATE Product ✅
**Location**: `lib/presentation/screens/products/product_screens.dart` - `AddProductScreen`

**How to Use**:
1. Navigate to "My Products" tab
2. Click the "+" button or "Add Product" button
3. Fill in product details:
   - Product Name (required)
   - Category (dropdown with 10 options)
   - Price in RWF (required, numeric)
   - Stock Quantity (required, numeric)
   - Description (optional)
   - Mark as expense (optional checkbox)
4. Click "Save Product"

**Features**:
- ✅ Form validation on all required fields
- ✅ Automatic shop name and owner details
- ✅ Timestamp recording (createdAt, updatedAt)
- ✅ Success notification on save
- ✅ Error handling with detailed messages
- ✅ Auto-increments shop's productCount in Firebase

**Code Flow**:
```
AddProductScreen → ProductProvider.addProduct() 
→ ProductRepository.addProduct() → Firebase Firestore
```

---

### 2. READ Products ✅
**Location**: `lib/presentation/screens/products/product_screens.dart` - `MyProductsScreen`

**Features**:
- ✅ Real-time stream of user's products using `watchMyProducts()`
- ✅ Search functionality (case-insensitive on name/category)
- ✅ Status indicators: Active, Low Stock, Out of Stock
- ✅ Stock statistics at top (Active count, Low Stock count, Out count)
- ✅ Empty state with helpful message
- ✅ Pull-to-refresh capability

**Display Information**:
- Product name and category
- Price and stock quantity
- Stock status badge (color-coded)
- Edit, Delete, and View buttons

**Code Flow**:
```
ProductProvider.watchMyProducts() 
→ ProductRepository.watchOwnerProducts() 
→ Real-time Firestore Stream
```

---

### 3. UPDATE Product ✅
**Location**: `lib/presentation/screens/products/product_screens.dart` - `EditProductScreen`

**How to Use**:
1. From "My Products", click the "Edit" button on any product
2. Modify any of these fields:
   - Product Name
   - Category
   - Price
   - Stock Quantity
   - Description
3. Click "Save Changes"

**Features**:
- ✅ Pre-filled form with current product data
- ✅ Form validation on all required fields
- ✅ Quantity stepper (+/- buttons) for easy adjustment
- ✅ Success notification with confirmation
- ✅ Error handling with detailed messages
- ✅ Automatic updatedAt timestamp on save
- ✅ Product image placeholder (ready for implementation)

**Code Flow**:
```
EditProductScreen → ProductProvider.updateProduct() 
→ ProductRepository.updateProduct() → Firebase Firestore
```

---

### 4. DELETE Product ✅
**Location**: `lib/presentation/screens/products/product_screens.dart` - `_ProductCard`

**How to Use**:
1. From "My Products", click the "Delete" button on a product
2. Confirmation dialog appears
3. Click "Delete" to confirm (or "Cancel" to abort)
4. Product is permanently deleted

**Features**:
- ✅ Confirmation dialog with warning icon
- ✅ Cannot undo message
- ✅ Success/Error notifications
- ✅ Auto-decrements shop's productCount
- ✅ Real-time list updates

**Code Flow**:
```
_ProductCard → ProductProvider.deleteProduct() 
→ ProductRepository.deleteProduct() → Firebase Firestore
```

---

## 🔐 AUTHENTICATION OPERATIONS

### 1. SIGNUP (Register) ✅
**Location**: `lib/presentation/screens/auth/auth_screens.dart` - `SignUpScreen`

**How to Use**:
1. On Login screen, click "Sign Up"
2. Fill in:
   - Full Name (required)
   - Email Address (required, valid email)
   - Password (required, min 6 characters)
   - Confirm Password (required, must match)
3. Click "Sign Up"
4. Email verification dialog appears
5. Check email for verification link

**Features**:
- ✅ Real-time form validation
- ✅ Password strength indicators
- ✅ Email verification requirement
- ✅ Automatic user profile creation
- ✅ Default shop creation for new users
- ✅ Firebase Authentication integration
- ✅ Error handling (duplicate email, weak password, etc.)
- ✅ Email trimming to prevent whitespace issues

**Validation Rules**:
- Email: Must be valid email format
- Password: Minimum 6 characters
- Confirm Password: Must exactly match password field
- Full Name: Required, non-empty

**After Signup**:
- Verification email sent automatically
- User can access app even before email verification
- Some features may be restricted until verified
- "Verify Email" prompt in profile with resend option

**Code Flow**:
```
SignUpScreen → AuthProvider.registerWithEmail() 
→ AuthRepository.registerWithEmail() 
→ Firebase Auth + Firestore
→ Default shop creation
```

---

### 2. LOGIN ✅
**Location**: `lib/presentation/screens/auth/auth_screens.dart` - `LoginScreen`

**How to Use**:
1. Enter Email Address
2. Enter Password
3. Click "Login"

**Alternative (Google Sign-In)**:
- Click "Google Sign-In" button
- Select your Google account
- Automatic verification (Google accounts are pre-verified)

**Features**:
- ✅ Email/Password authentication
- ✅ Google Sign-In integration
- ✅ Remember-me-style persistent login
- ✅ Form validation
- ✅ Error messages (user not found, wrong password, etc.)
- ✅ Email trimming
- ✅ Auto-initialization of data providers

**Code Flow**:
```
LoginScreen → AuthProvider.signInWithEmail() 
→ AuthRepository.signInWithEmail() 
→ Firebase Auth
→ Auto-start watching products, orders, shops, etc.
```

---

### 3. LOGOUT ✅
**Location**: Two locations:
- `lib/presentation/screens/profile_settings_learn_sales.dart` - `ProfileScreen` & `SettingsScreen`

**How to Use**:
1. Navigate to Profile or Settings
2. Click "Log Out" button
3. Confirmation dialog appears
4. Click "Log Out" to confirm
5. User is redirected to Login screen

**Features**:
- ✅ Confirmation dialog to prevent accidental logout
- ✅ Clear user data from memory
- ✅ Sign out from Firebase and Google
- ✅ Reset authentication status
- ✅ Automatic redirect to Login screen
- ✅ Error handling

**Code Flow**:
```
ProfileScreen/SettingsScreen 
→ AuthProvider.signOut() 
→ AuthRepository.signOut() 
→ Firebase Auth signOut() + Google signOut()
→ Navigate to AppRoutes.login
```

---

### 4. PASSWORD RESET ✅
**Location**: `lib/presentation/screens/auth/auth_screens.dart` - `ForgotPasswordScreen`

**How to Use**:
1. On Login screen, click "Forgot Password?"
2. Enter your email address
3. Click "Send Reset Email"
4. Check your email for password reset link
5. Follow link to reset password

**Features**:
- ✅ Email validation
- ✅ Firebase password reset email
- ✅ User-friendly confirmation
- ✅ Error handling
- ✅ Automatic return to login after success

---

## ⚙️ SETTINGS & PROFILE

### Profile Management ✅
**Location**: `lib/presentation/screens/profile_settings_learn_sales.dart` - `EditProfileScreen`

**Editable Fields**:
- Full Name
- Shop Name
- Username
- Phone Number
- Location

**Stored Information** (read-only display):
- Email
- Account creation date
- Email verification status
- Photo URL (with camera upload placeholder)

---

### Settings Screen ✅
**Location**: `lib/presentation/screens/profile_settings_learn_sales.dart` - `SettingsScreen`

**Settings Available**:
- 🌐 App Language (English/Kinyarwanda)
- 💱 Currency (RWF/USD)
- 🌙 Dark Mode toggle
- 🔄 Auto Sync toggle
- 🔔 Notifications toggle
- 📊 Data Saver toggle
- 📁 Cache management
- 📋 Profile edit link
- 🚪 Logout button

**Data Persistence**:
- All settings saved to SharedPreferences
- Persists across app restarts
- Clear cache option available

---

## 🧪 TESTING CHECKLIST

### Product CRUD Testing
- [ ] **Create**: Add a new product with all fields, verify it appears in list
- [ ] **Create**: Test validation (empty name, invalid price, etc.)
- [ ] **Read**: Open My Products, verify all products display correctly
- [ ] **Read**: Test search functionality with product names
- [ ] **Read**: Test stock status indicators (Active, Low, Out)
- [ ] **Update**: Edit a product, change values, verify updates
- [ ] **Update**: Test quantity stepper buttons
- [ ] **Delete**: Delete a product, confirm dialog appears
- [ ] **Delete**: Verify product is removed from list

### Authentication Testing
- [ ] **Signup**: Create new account with valid email, verify email sent
- [ ] **Signup**: Test validation (duplicate email, weak password, etc.)
- [ ] **Login**: Login with new account credentials
- [ ] **Login**: Test "Remember Me" across app restarts
- [ ] **Google Auth**: Test Google Sign-In flow
- [ ] **Logout**: Logout from Profile tab, verify login screen
- [ ] **Logout**: Logout from Settings tab, verify login screen
- [ ] **Logout**: Logout confirmation dialog appears before logout
- [ ] **Password Reset**: Test forgot password flow
- [ ] **Profile**: Edit profile information and verify updates

### Settings Testing
- [ ] Change app language and verify UI updates
- [ ] Toggle Dark Mode and verify theme changes
- [ ] Toggle all switches and verify persistence
- [ ] Clear cache and verify app still works
- [ ] Change currency setting

---

## 🔄 ERROR HANDLING

All CRUD operations include comprehensive error handling:

### Product Operations
- ✅ Missing required fields
- ✅ Invalid number formats
- ✅ Network failures
- ✅ Firebase permission errors
- ✅ Duplicate product handling

### Authentication
- ✅ Invalid email format
- ✅ Weak passwords
- ✅ User not found
- ✅ Wrong password
- ✅ Duplicate email registration
- ✅ Network connectivity issues
- ✅ Too many login attempts

---

## 📱 User Flows

### First-Time User Flow
```
App Launch 
→ Splash Screen 
→ Login/SignUp 
→ SignUp Process 
→ Email Verification Dialog 
→ Home Screen
```

### Returning User Flow
```
App Launch 
→ Splash Screen 
→ Check Auth State 
→ If Authenticated: Home Screen 
→ If Not: Login Screen
```

### Product Management Flow
```
Home → My Products 
→ Add/Edit/Delete/View Products 
→ Real-time updates
```

### Logout Flow
```
Profile/Settings 
→ Click Logout 
→ Confirmation Dialog 
→ Logout Process 
→ Login Screen
```

---

## 🎯 Key Features Implemented

✅ Real-time Firestore updates with streams  
✅ Form validation with helpful error messages  
✅ Error recovery and user guidance  
✅ Loading states and spinners  
✅ Success/Error notifications (SnackBars)  
✅ Confirmation dialogs for destructive actions  
✅ Email verification system  
✅ Google Sign-In integration  
✅ Password reset flow  
✅ Persistent settings with SharedPreferences  
✅ Automatic provider initialization on login  
✅ Thread-safe async operations  
✅ Proper cleanup on logout  

---

## 🚀 Ready to Test!

The app is now fully functional with:
- ✅ Complete CRUD for products
- ✅ Complete authentication workflow
- ✅ Settings and profile management
- ✅ Error handling throughout
- ✅ User-friendly confirmations and feedback

Start by creating a test account and adding a product!
