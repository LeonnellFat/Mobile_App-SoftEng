# Real-Time Architecture Diagram

## System Flow

```
┌─────────────────────────────────────────────────────────────────┐
│                      FLUTTER APP                                │
├─────────────────────────────────────────────────────────────────┤
│                                                                  │
│  ┌────────────────────────────────────────────────────────┐    │
│  │  main.dart                                              │    │
│  │  ├─ Initialize Supabase                                │    │
│  │  ├─ Load initial products & categories                 │    │
│  │  ├─ Initialize real-time listeners ✨ NEW             │    │
│  │  └─ Wrap with AppLifecycleWrapper ✨ NEW              │    │
│  └────────────────────────────────────────────────────────┘    │
│                            ↓                                     │
│  ┌────────────────────────────────────────────────────────┐    │
│  │  MultiProvider                                          │    │
│  │  ├─ AdminProvider (manages products/categories)        │    │
│  │  ├─ AuthProvider                                       │    │
│  │  └─ CartProvider                                       │    │
│  └────────────────────────────────────────────────────────┘    │
│                            ↓                                     │
│  ┌────────────────────────────────────────────────────────┐    │
│  │  AppLifecycleWrapper ✨ NEW                             │    │
│  │  ├─ Monitors app state                                 │    │
│  │  ├─ On resume: refresh data                            │    │
│  │  └─ On pause: no action                                │    │
│  └────────────────────────────────────────────────────────┘    │
│                            ↓                                     │
│  ┌────────────────────────────────────────────────────────┐    │
│  │  Screens (ProductsScreen, CategoriesScreen, etc.)      │    │
│  │  ├─ Use Consumer<AdminProvider>                        │    │
│  │  ├─ Auto-rebuild on data change                        │    │
│  │  └─ Display products/categories in real-time           │    │
│  └────────────────────────────────────────────────────────┘    │
│                                                                  │
└─────────────────────────────────────────────────────────────────┘
                             ↕↕↕ REAL-TIME SYNC ↕↕↕
┌─────────────────────────────────────────────────────────────────┐
│                      SUPABASE (DATABASE)                        │
├─────────────────────────────────────────────────────────────────┤
│                                                                  │
│  Tables:                                                         │
│  ┌──────────────────┐      ┌──────────────────┐                │
│  │  products        │      │  categories      │                │
│  ├──────────────────┤      ├──────────────────┤                │
│  │ id (PK)          │      │ id (PK)          │                │
│  │ name             │      │ name             │                │
│  │ description      │      │ description      │                │
│  │ price            │      │ created_at       │                │
│  │ image            │      │ updated_at       │                │
│  │ category_id (FK) │      │                  │                │
│  │ created_at       │      │                  │                │
│  │ updated_at       │      │                  │                │
│  └──────────────────┘      └──────────────────┘                │
│         ↑                           ↑                            │
│         └───────────────┬───────────┘                           │
│                         │                                        │
│                    Realtime                                     │
│                 (PostgreSQL                                     │
│                 Change Notify)                                  │
│                                                                  │
└─────────────────────────────────────────────────────────────────┘
```

---

## Real-Time Update Flow

```
┌─────────────────────────────────────────┐
│    Admin changes product in Supabase    │
│  (via Dashboard, API, or other tool)    │
└──────────────────┬──────────────────────┘
                   │
                   ↓
┌─────────────────────────────────────────┐
│   Supabase Database triggers change     │
│     (INSERT/UPDATE/DELETE event)        │
└──────────────────┬──────────────────────┘
                   │
                   ↓
┌─────────────────────────────────────────┐
│  Supabase broadcasts via Realtime       │
│   (WebSocket to all connected clients)  │
└──────────────────┬──────────────────────┘
                   │
                   ↓
┌─────────────────────────────────────────┐
│  App receives Realtime notification     │
│  (via SupabaseService listener)         │
└──────────────────┬──────────────────────┘
                   │
                   ↓
┌─────────────────────────────────────────┐
│  App fetches updated data from Supabase │
│  (SupabaseService.fetchProducts())      │
└──────────────────┬──────────────────────┘
                   │
                   ↓
┌─────────────────────────────────────────┐
│  AdminProvider.setProducts() called      │
│  (updates internal list)                │
└──────────────────┬──────────────────────┘
                   │
                   ↓
┌─────────────────────────────────────────┐
│  notifyListeners() broadcasts update    │
│  (to all Consumer widgets)              │
└──────────────────┬──────────────────────┘
                   │
                   ↓
┌─────────────────────────────────────────┐
│  Consumer<AdminProvider> rebuilds       │
│  (re-runs builder with new data)        │
└──────────────────┬──────────────────────┘
                   │
                   ↓
┌─────────────────────────────────────────┐
│  UI displays updated products           │
│  (ProductCard shows new data)           │
└─────────────────────────────────────────┘

TIME: ~200-500ms (depending on network)
```

---

## Component Communication

```
┌──────────────────────┐
│   main.dart          │
│  (App Startup)       │
└──────────────┬───────┘
               │
               │ creates
               ↓
┌──────────────────────────────────┐
│  AdminProvider                   │
│  ├─ products list                │
│  ├─ categories list              │
│  ├─ initializeRealtimeListeners()│ ✨
│  ├─ refreshProducts()            │ ✨
│  ├─ refreshCategories()          │ ✨
│  └─ _handle*Change()             │ ✨
└──────────────┬────────────────────┘
               │
               │ calls
               ↓
┌──────────────────────────────────┐
│  SupabaseService                 │
│  ├─ fetchProducts()              │
│  ├─ fetchCategories()            │
│  ├─ subscribeToProductChanges()  │ ✨
│  ├─ subscribeToCategoryChanges() │ ✨
│  └─ unsubscribe*()               │ ✨
└──────────────┬────────────────────┘
               │
               │ manages
               ↓
┌──────────────────────────────────┐
│  Supabase Client (Realtime)      │
│  ├─ products:* channel            │ ✨
│  └─ categories:* channel          │ ✨
└──────────────┬────────────────────┘
               │
               │ broadcasts
               ↓
┌──────────────────────────────────┐
│  PostgreSQL Database             │
│  ├─ products table               │
│  └─ categories table             │
└──────────────────────────────────┘
```

---

## Lifecycle State Machine

```
                    App Start
                        │
                        ↓
            ┌───────────────────┐
            │  Initialize       │
            │  Real-time        │
            │  Listeners        │
            └────────┬──────────┘
                     │
                     ↓
        ┌────────────────────────┐
        │  App Running           │
        │  (Listening for        │
        │   real-time changes)   │
        └────────┬─────────┬─────┘
                 │         │
            Paused     Resumed
        (minimize)     (open app)
            │              │
            ↓              ↓
        ┌────────┐    ┌──────────────┐
        │Pause   │    │Resume        │
        │State   │    │State         │
        │        │    │Auto-refresh  │
        │        │    │data          │
        │        │    │              │
        └────┬───┘    └──────┬───────┘
             │               │
             └───────┬───────┘
                     │
                     ↓
        ┌────────────────────────┐
        │  App Still Listening   │
        │  for Real-time Updates │
        │  (continuous)          │
        └────────┬─────────┬─────┘
                 │         │
            Paused     Resumed
                └─── Loop ───┘
                     │
                     ↓
            ┌────────────────────┐
            │  App Closed        │
            │  Cancel Listeners  │
            │  (cleanup)         │
            └────────────────────┘
```

---

## Data Flow: Initial Load vs Real-Time Update

### Initial Load (App Start)
```
App Start
  │
  ├─ fetchProducts() → returns List<Product>
  │
  ├─ fetchCategories() → returns List<Category>
  │
  └─ initializeRealtimeListeners()
      ├─ subscribeToProductChanges(callback)
      └─ subscribeToCategoryChanges(callback)
```

### Real-Time Update (While App Running)
```
Database Change
  │
  └─ Supabase Realtime Event
      │
      └─ callback function triggered
          │
          ├─ fetchProducts() → returns updated List<Product>
          │
          └─ _handleProductChange(updatedProducts)
              │
              └─ setProducts(updatedProducts)
                  │
                  └─ notifyListeners()
                      │
                      └─ UI Rebuilds
```

### Manual Refresh
```
User taps Refresh Button
  │
  └─ refreshProducts()
      │
      ├─ fetchProducts() → returns List<Product>
      │
      └─ setProducts(products)
          │
          └─ notifyListeners()
              │
              └─ UI Rebuilds
```

---

## Network & Storage

```
┌──────────────────────────────────────┐
│  Flutter App (Device/Emulator)       │
│                                      │
│  ┌────────────────────────────────┐ │
│  │  Provider State Management      │ │
│  │  (In-Memory)                    │ │
│  │                                 │ │
│  │  AdminProvider {                │ │
│  │    _products: List<Product>    │ │
│  │    _categories: List<Category> │ │
│  │  }                              │ │
│  └────────────────────────────────┘ │
│                                      │
└──────────────────┬───────────────────┘
                   │
        WebSocket (Real-time)
        HTTP (Fetch/Refresh)
                   │
                   ↓
┌──────────────────────────────────────┐
│  Supabase (Backend)                  │
│                                      │
│  ┌────────────────────────────────┐ │
│  │  PostgreSQL Database            │ │
│  │                                 │ │
│  │  Products Table                 │ │
│  │  Categories Table               │ │
│  └────────────────────────────────┘ │
│                                      │
│  ┌────────────────────────────────┐ │
│  │  Realtime Server                │ │
│  │  (PostgreSQL Change Notify)     │ │
│  └────────────────────────────────┘ │
│                                      │
└──────────────────────────────────────┘
```

---

## Legend

✨ = New feature added
↕↕↕ = Bi-directional communication
→ = One-way data flow
↓ = Sequential process
```

---

For detailed implementation, see: [DETAILED_CHANGES_REFERENCE.md](DETAILED_CHANGES_REFERENCE.md)
