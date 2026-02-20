# SPA Developer Skill

**Version**: 1.0
**Created**: 2025-12-17
**Purpose**: Single Page Application development with React, Vue, modern component libraries, state management, and interactive user experiences

---

## Skill Identity

**Name**: SPA Developer
**Type**: Modern web application development skill
**Domain**: React, Vue.js, component architecture, state management, API integration, animation libraries, routing, authentication, and modern SPA patterns

---

## Purpose

The SPA Developer skill brings modern single-page application development capabilities to the Content Manager agent. While static sites excel at content delivery, SPAs provide rich, app-like user experiences:

- **React Development**: Components, hooks, Context API, modern patterns
- **Vue.js Development**: Composition API, reactivity, Vue ecosystem
- **Component Libraries**: Material UI, Chakra UI, Shadcn/UI, Ant Design
- **State Management**: Redux, Zustand, Pinia, Context patterns
- **API Integration**: REST, GraphQL, real-time (WebSockets)
- **Animation Libraries**: Framer Motion, GSAP, React Spring
- **Routing**: React Router, Vue Router, navigation patterns
- **Authentication**: OAuth, JWT, session management
- **Modern Tooling**: Vite, TypeScript, ESLint, Prettier

**Value Provided**:
- **Rich Interactivity**: Complex UI interactions, real-time updates
- **App-Like Experience**: Smooth transitions, instant navigation
- **Component Reusability**: Build once, use everywhere
- **Developer Experience**: Hot reload, TypeScript, modern tooling
- **Performance**: Code splitting, lazy loading, optimized bundles
- **Scalability**: Maintainable architecture for large applications

**When to Use SPAs**:
- ✅ User dashboards, admin panels
- ✅ Real-time collaboration tools
- ✅ Interactive data visualizations
- ✅ Complex forms and workflows
- ✅ Social media platforms
- ❌ Simple marketing sites (use static instead)
- ❌ SEO-critical content (use SSR/SSG)
- ❌ Content-heavy blogs (use WordPress/static)

---

## Behavioral Approach

### Patient Guidance

**Framework Selection Consultation**:
```
"Let's choose the right approach for your application.
I'll walk you through the key decisions:

Decision 1: Framework Choice
  React: Most popular, huge ecosystem, job market leader
    Pros: Massive community, libraries for everything
    Cons: More boilerplate, multiple ways to do things
    Best for: Complex apps, team experience, job opportunities

  Vue: Progressive, gentle learning curve, elegant API
    Pros: Easier to learn, clear documentation, less boilerplate
    Cons: Smaller ecosystem than React
    Best for: Medium complexity, developer happiness, faster development

  Which appeals to you? (Or would you like more context?)

[Wait for response]

Decision 2: Component Library
  Material UI: Google Material Design, comprehensive
  Chakra UI: Accessibility-first, highly customizable
  Shadcn/UI: Copy-paste components, full control
  Ant Design: Enterprise-focused, business apps

  What's most important to you?
    A) Beautiful out-of-box (Material UI, Ant Design)
    B) Accessibility focus (Chakra UI)
    C) Full customization (Shadcn/UI)

[Wait for response]

Decision 3: State Management
  Simple app: Context API (built-in)
  Medium app: Zustand (minimal boilerplate)
  Complex app: Redux (robust, debugging tools)

Based on your answers, I recommend: [Recommendation]

Shall we proceed with this stack?"
```

### Courteous Interaction

**Skill Level Adaptation**:
```
Beginner:
"We'll start with a simple component-based approach. Think of components
like LEGO blocks - each piece does one thing well, and we combine them
to build the full application. I'll explain each concept as we go."

Intermediate:
"I'll set up a modern React project with TypeScript, configure routing,
and show you how to integrate a component library. We'll use hooks for
state management and implement a clean architecture."

Advanced:
"I'll scaffold a production-ready SPA with TypeScript, Redux Toolkit for
state management, RTK Query for API calls, implement advanced patterns
like compound components, and set up testing with React Testing Library."
```

### Gentle Guidance

**Learning Path - SPA Development**:
```
Phase 1: Component Fundamentals (Week 1-2)
  ✓ Understand components, props, and state
  ✓ Master JSX syntax
  ✓ Practice component composition
  ✓ Build: Simple todo list app
  [CHECKPOINT: Functional component-based app]

Phase 2: Hooks & Side Effects (Week 3-4)
  ✓ useState, useEffect basics
  ✓ Custom hooks for reusability
  ✓ API data fetching
  ✓ Build: Weather dashboard with API
  [CHECKPOINT: Data-driven application]

Phase 3: Routing & Navigation (Week 5)
  ✓ React Router setup
  ✓ Dynamic routes, params
  ✓ Protected routes
  ✓ Build: Multi-page dashboard
  [CHECKPOINT: Full navigation flow]

Phase 4: State Management (Week 6-7)
  ✓ Context API for global state
  ✓ Zustand for simpler apps
  ✓ Redux for complex state
  ✓ Build: Shopping cart application
  [CHECKPOINT: Complex state handling]

Phase 5: Production Patterns (Week 8+)
  ✓ TypeScript integration
  ✓ Error boundaries
  ✓ Performance optimization
  ✓ Testing strategies
  ✓ Build: Production-ready app
  [CHECKPOINT: Deploy to production]

"You're currently in Phase 1. Take your time mastering these fundamentals
before moving forward. Would you like me to explain any of these concepts?"
```

### Technical Depth

**Performance Optimization Analysis**:
```
"I've analyzed your SPA's performance. Here's what I found:

Bundle Analysis:
  Total bundle size: 1.2MB (should be <500KB)
  Main chunk: 850KB (too large)
  Vendor chunk: 350KB (acceptable)

Performance Metrics:
  First Contentful Paint: 3.1s (target <1.8s)
  Time to Interactive: 5.2s (target <3.5s)
  Total Blocking Time: 890ms (target <300ms)

Root Causes:
1. Material UI imported entirely (adds 300KB unused code)
2. No code splitting (all routes loaded upfront)
3. Lodash imported without tree-shaking (95KB)
4. Unoptimized images in components

Optimization Strategy:
  Priority 1: Tree-shake Material UI imports
    // ❌ import { Button } from '@mui/material';
    // ✅ import Button from '@mui/material/Button';
    Impact: -180KB bundle size

  Priority 2: Implement route-based code splitting
    // Use React.lazy() for routes
    Impact: -400KB initial bundle

  Priority 3: Replace lodash with lodash-es
    Impact: -70KB bundle size

  Priority 4: Lazy load images with Intersection Observer
    Impact: Faster initial load

Expected result: Bundle <500KB, FCP <1.8s, TTI <3s

Shall we start with Priority 1 (Material UI tree-shaking)?"
```

---

## Core Capabilities

### 1. React Development

#### Modern Component Patterns

**Functional Components with Hooks**:
```tsx
import React, { useState, useEffect } from 'react';

interface UserProfileProps {
  userId: string;
}

export const UserProfile: React.FC<UserProfileProps> = ({ userId }) => {
  const [user, setUser] = useState<User | null>(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    async function fetchUser() {
      try {
        setLoading(true);
        const response = await fetch(`/api/users/${userId}`);
        const data = await response.json();
        setUser(data);
      } catch (err) {
        setError('Failed to load user');
      } finally {
        setLoading(false);
      }
    }

    fetchUser();
  }, [userId]);

  if (loading) return <div>Loading...</div>;
  if (error) return <div>Error: {error}</div>;
  if (!user) return <div>User not found</div>;

  return (
    <div className="user-profile">
      <img src={user.avatar} alt={user.name} />
      <h2>{user.name}</h2>
      <p>{user.bio}</p>
    </div>
  );
};
```

**Custom Hooks for Reusability**:
```tsx
// hooks/useApi.ts
import { useState, useEffect } from 'react';

export function useApi<T>(url: string) {
  const [data, setData] = useState<T | null>(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<Error | null>(null);

  useEffect(() => {
    let cancelled = false;

    async function fetchData() {
      try {
        const response = await fetch(url);
        if (!response.ok) throw new Error('Failed to fetch');
        const json = await response.json();
        if (!cancelled) {
          setData(json);
          setError(null);
        }
      } catch (err) {
        if (!cancelled) {
          setError(err as Error);
        }
      } finally {
        if (!cancelled) {
          setLoading(false);
        }
      }
    }

    fetchData();

    return () => {
      cancelled = true;
    };
  }, [url]);

  return { data, loading, error };
}

// Usage
function UserList() {
  const { data: users, loading, error } = useApi<User[]>('/api/users');

  if (loading) return <div>Loading...</div>;
  if (error) return <div>Error: {error.message}</div>;

  return (
    <ul>
      {users?.map(user => (
        <li key={user.id}>{user.name}</li>
      ))}
    </ul>
  );
}
```

**Compound Components Pattern**:
```tsx
// components/Card.tsx
interface CardProps {
  children: React.ReactNode;
}

interface CardHeaderProps {
  children: React.ReactNode;
}

interface CardBodyProps {
  children: React.ReactNode;
}

const Card = ({ children }: CardProps) => {
  return <div className="card">{children}</div>;
};

const CardHeader = ({ children }: CardHeaderProps) => {
  return <div className="card-header">{children}</div>;
};

const CardBody = ({ children }: CardBodyProps) => {
  return <div className="card-body">{children}</div>;
};

// Export as compound component
Card.Header = CardHeader;
Card.Body = CardBody;

export { Card };

// Usage
<Card>
  <Card.Header>
    <h2>User Profile</h2>
  </Card.Header>
  <Card.Body>
    <p>Profile content here</p>
  </Card.Body>
</Card>
```

#### Code Splitting & Lazy Loading

**Route-Based Code Splitting**:
```tsx
import React, { Suspense, lazy } from 'react';
import { BrowserRouter, Routes, Route } from 'react-router-dom';

// Lazy load route components
const Home = lazy(() => import('./pages/Home'));
const Dashboard = lazy(() => import('./pages/Dashboard'));
const Profile = lazy(() => import('./pages/Profile'));

function App() {
  return (
    <BrowserRouter>
      <Suspense fallback={<div>Loading...</div>}>
        <Routes>
          <Route path="/" element={<Home />} />
          <Route path="/dashboard" element={<Dashboard />} />
          <Route path="/profile/:id" element={<Profile />} />
        </Routes>
      </Suspense>
    </BrowserRouter>
  );
}
```

**Component-Based Lazy Loading**:
```tsx
import React, { Suspense, lazy } from 'react';

const HeavyChart = lazy(() => import('./components/HeavyChart'));

function Dashboard() {
  const [showChart, setShowChart] = useState(false);

  return (
    <div>
      <h1>Dashboard</h1>
      <button onClick={() => setShowChart(true)}>
        Show Chart
      </button>

      {showChart && (
        <Suspense fallback={<div>Loading chart...</div>}>
          <HeavyChart />
        </Suspense>
      )}
    </div>
  );
}
```

### 2. Component Libraries

#### Material UI Implementation

**Setup**:
```bash
npm install @mui/material @mui/icons-material @emotion/react @emotion/styled
```

**Theme Configuration**:
```tsx
// theme.ts
import { createTheme } from '@mui/material/styles';

export const theme = createTheme({
  palette: {
    primary: {
      main: '#0281a0', // Big Beard teal
    },
    secondary: {
      main: '#f50057',
    },
  },
  typography: {
    fontFamily: 'Inter, sans-serif',
    h1: {
      fontSize: '3rem',
      fontWeight: 800,
    },
  },
  components: {
    MuiButton: {
      styleOverrides: {
        root: {
          textTransform: 'uppercase',
          borderRadius: 0,
          fontWeight: 600,
        },
      },
    },
  },
});

// App.tsx
import { ThemeProvider } from '@mui/material/styles';
import CssBaseline from '@mui/material/CssBaseline';

function App() {
  return (
    <ThemeProvider theme={theme}>
      <CssBaseline />
      <YourApp />
    </ThemeProvider>
  );
}
```

**Tree-Shaken Imports** (for smaller bundle):
```tsx
// ❌ Bad: Imports entire library
import { Button, TextField, Box } from '@mui/material';

// ✅ Good: Tree-shaken imports
import Button from '@mui/material/Button';
import TextField from '@mui/material/TextField';
import Box from '@mui/material/Box';
```

#### Chakra UI Implementation

**Setup**:
```bash
npm install @chakra-ui/react @emotion/react @emotion/styled framer-motion
```

**Configuration**:
```tsx
// App.tsx
import { ChakraProvider, extendTheme } from '@chakra-ui/react';

const theme = extendTheme({
  colors: {
    brand: {
      50: '#f0f9ff',
      500: '#0281a0',
      900: '#0c4a6e',
    },
  },
  fonts: {
    heading: 'Inter, sans-serif',
    body: 'Inter, sans-serif',
  },
});

function App() {
  return (
    <ChakraProvider theme={theme}>
      <YourApp />
    </ChakraProvider>
  );
}
```

**Component Usage**:
```tsx
import {
  Box,
  Heading,
  Text,
  Button,
  VStack,
  HStack,
} from '@chakra-ui/react';

function Hero() {
  return (
    <Box bg="gray.50" py={20}>
      <VStack spacing={6} maxW="container.xl" mx="auto" px={4}>
        <Heading
          as="h1"
          size="3xl"
          fontWeight="extrabold"
          lineHeight="shorter"
        >
          Beautiful Web Design
        </Heading>
        <Text fontSize="xl" color="gray.600">
          Elegant, modern, and highly interactive
        </Text>
        <HStack spacing={4}>
          <Button colorScheme="brand" size="lg">
            Get Started
          </Button>
          <Button variant="outline" size="lg">
            Learn More
          </Button>
        </HStack>
      </VStack>
    </Box>
  );
}
```

#### Shadcn/UI Implementation

**Setup**:
```bash
npx shadcn-ui@latest init
npx shadcn-ui@latest add button
npx shadcn-ui@latest add card
```

**Component Usage** (you own the code):
```tsx
// components/ui/button.tsx is now in your project
import { Button } from '@/components/ui/button';
import { Card, CardHeader, CardTitle, CardContent } from '@/components/ui/card';

function Dashboard() {
  return (
    <Card>
      <CardHeader>
        <CardTitle>Dashboard</CardTitle>
      </CardHeader>
      <CardContent>
        <p>Your content here</p>
        <Button variant="default">Click me</Button>
      </CardContent>
    </Card>
  );
}
```

### 3. State Management

#### Context API (Built-in)

**Simple Global State**:
```tsx
// contexts/AuthContext.tsx
import React, { createContext, useContext, useState } from 'react';

interface User {
  id: string;
  name: string;
  email: string;
}

interface AuthContextType {
  user: User | null;
  login: (user: User) => void;
  logout: () => void;
}

const AuthContext = createContext<AuthContextType | undefined>(undefined);

export function AuthProvider({ children }: { children: React.ReactNode }) {
  const [user, setUser] = useState<User | null>(null);

  const login = (user: User) => setUser(user);
  const logout = () => setUser(null);

  return (
    <AuthContext.Provider value={{ user, login, logout }}>
      {children}
    </AuthContext.Provider>
  );
}

export function useAuth() {
  const context = useContext(AuthContext);
  if (!context) {
    throw new Error('useAuth must be used within AuthProvider');
  }
  return context;
}

// Usage
function App() {
  return (
    <AuthProvider>
      <YourApp />
    </AuthProvider>
  );
}

function UserProfile() {
  const { user, logout } = useAuth();

  return (
    <div>
      <p>Welcome, {user?.name}</p>
      <button onClick={logout}>Logout</button>
    </div>
  );
}
```

#### Zustand (Minimal Boilerplate)

**Setup**:
```bash
npm install zustand
```

**Store Definition**:
```tsx
// stores/userStore.ts
import { create } from 'zustand';
import { devtools, persist } from 'zustand/middleware';

interface User {
  id: string;
  name: string;
  email: string;
}

interface UserStore {
  user: User | null;
  isLoading: boolean;
  error: string | null;
  login: (email: string, password: string) => Promise<void>;
  logout: () => void;
}

export const useUserStore = create<UserStore>()(
  devtools(
    persist(
      (set) => ({
        user: null,
        isLoading: false,
        error: null,
        login: async (email, password) => {
          set({ isLoading: true, error: null });
          try {
            const response = await fetch('/api/login', {
              method: 'POST',
              body: JSON.stringify({ email, password }),
            });
            const user = await response.json();
            set({ user, isLoading: false });
          } catch (error) {
            set({ error: 'Login failed', isLoading: false });
          }
        },
        logout: () => set({ user: null }),
      }),
      { name: 'user-storage' }
    )
  )
);

// Usage
function LoginForm() {
  const { login, isLoading, error } = useUserStore();

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    await login(email, password);
  };

  return (
    <form onSubmit={handleSubmit}>
      {/* form fields */}
      {error && <p>{error}</p>}
      <button disabled={isLoading}>Login</button>
    </form>
  );
}
```

#### Redux Toolkit (Complex State)

**Setup**:
```bash
npm install @reduxjs/toolkit react-redux
```

**Store Configuration**:
```tsx
// store/index.ts
import { configureStore } from '@reduxjs/toolkit';
import { TypedUseSelectorHook, useDispatch, useSelector } from 'react-redux';
import userReducer from './slices/userSlice';
import postsReducer from './slices/postsSlice';

export const store = configureStore({
  reducer: {
    user: userReducer,
    posts: postsReducer,
  },
});

export type RootState = ReturnType<typeof store.getState>;
export type AppDispatch = typeof store.dispatch;

export const useAppDispatch: () => AppDispatch = useDispatch;
export const useAppSelector: TypedUseSelectorHook<RootState> = useSelector;
```

**Slice Definition**:
```tsx
// store/slices/userSlice.ts
import { createSlice, createAsyncThunk } from '@reduxjs/toolkit';

interface User {
  id: string;
  name: string;
  email: string;
}

interface UserState {
  user: User | null;
  isLoading: boolean;
  error: string | null;
}

const initialState: UserState = {
  user: null,
  isLoading: false,
  error: null,
};

export const loginUser = createAsyncThunk(
  'user/login',
  async ({ email, password }: { email: string; password: string }) => {
    const response = await fetch('/api/login', {
      method: 'POST',
      body: JSON.stringify({ email, password }),
    });
    return response.json();
  }
);

const userSlice = createSlice({
  name: 'user',
  initialState,
  reducers: {
    logout: (state) => {
      state.user = null;
    },
  },
  extraReducers: (builder) => {
    builder
      .addCase(loginUser.pending, (state) => {
        state.isLoading = true;
        state.error = null;
      })
      .addCase(loginUser.fulfilled, (state, action) => {
        state.isLoading = false;
        state.user = action.payload;
      })
      .addCase(loginUser.rejected, (state, action) => {
        state.isLoading = false;
        state.error = action.error.message || 'Login failed';
      });
  },
});

export const { logout } = userSlice.actions;
export default userSlice.reducer;

// Usage
function LoginForm() {
  const dispatch = useAppDispatch();
  const { user, isLoading, error } = useAppSelector((state) => state.user);

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    await dispatch(loginUser({ email, password }));
  };

  return (
    <form onSubmit={handleSubmit}>
      {/* form fields */}
    </form>
  );
}
```

### 4. Animation Libraries

#### Framer Motion (React)

**Setup**:
```bash
npm install framer-motion
```

**Basic Animations**:
```tsx
import { motion } from 'framer-motion';

function Hero() {
  return (
    <motion.div
      initial={{ opacity: 0, y: 50 }}
      animate={{ opacity: 1, y: 0 }}
      transition={{ duration: 0.6, ease: 'easeOut' }}
    >
      <h1>Welcome</h1>
    </motion.div>
  );
}
```

**Staggered Animations** (Big Beard Style):
```tsx
import { motion } from 'framer-motion';

const container = {
  hidden: { opacity: 0 },
  show: {
    opacity: 1,
    transition: {
      staggerChildren: 0.2, // 200ms delay between children
    },
  },
};

const item = {
  hidden: { opacity: 0, x: -50 },
  show: { opacity: 1, x: 0 },
};

function FeatureList() {
  return (
    <motion.ul variants={container} initial="hidden" animate="show">
      <motion.li variants={item}>Feature 1</motion.li>
      <motion.li variants={item}>Feature 2</motion.li>
      <motion.li variants={item}>Feature 3</motion.li>
    </motion.ul>
  );
}
```

**Hover & Tap Animations**:
```tsx
<motion.button
  whileHover={{ scale: 1.05, letterSpacing: '2px' }}
  whileTap={{ scale: 0.95 }}
  transition={{ type: 'spring', stiffness: 400, damping: 10 }}
>
  Click Me
</motion.button>
```

#### GSAP (Complex Animations)

**Setup**:
```bash
npm install gsap
```

**ScrollTrigger Animations**:
```tsx
import { useEffect, useRef } from 'react';
import { gsap } from 'gsap';
import { ScrollTrigger } from 'gsap/ScrollTrigger';

gsap.registerPlugin(ScrollTrigger);

function AnimatedSection() {
  const sectionRef = useRef(null);

  useEffect(() => {
    const element = sectionRef.current;

    gsap.fromTo(
      element,
      { opacity: 0, y: 100 },
      {
        opacity: 1,
        y: 0,
        duration: 1,
        scrollTrigger: {
          trigger: element,
          start: 'top 80%',
          end: 'bottom 20%',
          toggleActions: 'play none none reverse',
        },
      }
    );
  }, []);

  return (
    <section ref={sectionRef}>
      <h2>Animated Content</h2>
    </section>
  );
}
```

### 5. API Integration

#### Fetch with Error Handling

**Utility Function**:
```tsx
// utils/api.ts
export async function apiRequest<T>(
  url: string,
  options?: RequestInit
): Promise<T> {
  const response = await fetch(url, {
    ...options,
    headers: {
      'Content-Type': 'application/json',
      ...options?.headers,
    },
  });

  if (!response.ok) {
    const error = await response.json().catch(() => ({}));
    throw new Error(error.message || 'API request failed');
  }

  return response.json();
}

// Usage
const users = await apiRequest<User[]>('/api/users');
```

#### React Query (TanStack Query)

**Setup**:
```bash
npm install @tanstack/react-query
```

**Configuration**:
```tsx
// App.tsx
import { QueryClient, QueryClientProvider } from '@tanstack/react-query';

const queryClient = new QueryClient({
  defaultOptions: {
    queries: {
      staleTime: 1000 * 60 * 5, // 5 minutes
      cacheTime: 1000 * 60 * 10, // 10 minutes
      retry: 3,
    },
  },
});

function App() {
  return (
    <QueryClientProvider client={queryClient}>
      <YourApp />
    </QueryClientProvider>
  );
}
```

**Usage**:
```tsx
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';

function UserList() {
  const { data: users, isLoading, error } = useQuery({
    queryKey: ['users'],
    queryFn: async () => {
      const response = await fetch('/api/users');
      return response.json();
    },
  });

  if (isLoading) return <div>Loading...</div>;
  if (error) return <div>Error: {error.message}</div>;

  return (
    <ul>
      {users.map((user) => (
        <li key={user.id}>{user.name}</li>
      ))}
    </ul>
  );
}

// Mutation example
function CreateUserForm() {
  const queryClient = useQueryClient();

  const mutation = useMutation({
    mutationFn: async (newUser: User) => {
      const response = await fetch('/api/users', {
        method: 'POST',
        body: JSON.stringify(newUser),
      });
      return response.json();
    },
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['users'] });
    },
  });

  const handleSubmit = (e: React.FormEvent) => {
    e.preventDefault();
    mutation.mutate({ name, email });
  };

  return <form onSubmit={handleSubmit}>{/* form fields */}</form>;
}
```

---

## Component Library Comparison

| Library | Stars | Bundle Size | Accessibility | Customization | Best For |
|---------|-------|-------------|---------------|---------------|----------|
| **Material UI** | 89.3k | Large | ⭐⭐⭐⭐ | ⭐⭐⭐ | Enterprise apps |
| **Chakra UI** | 34.7k | Medium | ⭐⭐⭐⭐⭐ | ⭐⭐⭐⭐⭐ | Accessible apps |
| **Shadcn/UI** | 45k+ | Small | ⭐⭐⭐⭐ | ⭐⭐⭐⭐⭐ | Full control |
| **Ant Design** | 88k | Large | ⭐⭐⭐ | ⭐⭐ | Business apps |

**Recommendation**: Chakra UI for most projects (accessibility + customization)

---

## Success Criteria

### Development Quality
- ✅ TypeScript for type safety
- ✅ Components are reusable and composable
- ✅ Proper error boundaries implemented
- ✅ Loading and error states handled
- ✅ Accessibility (keyboard navigation, ARIA labels)

### Performance
- ✅ Bundle size < 500KB (initial load)
- ✅ Code splitting implemented
- ✅ Lazy loading for routes and heavy components
- ✅ Optimized re-renders (React.memo, useMemo)

### User Experience
- ✅ Smooth animations (60fps)
- ✅ Responsive design (mobile, tablet, desktop)
- ✅ Fast navigation between routes
- ✅ Accessible to all users

---

## Version History

- **v1.0** (2025-12-17): Initial SPA Developer skill with React, Vue, component libraries, state management, animations, and API integration
