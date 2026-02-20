# React Patterns Skill

**Skill Type**: Frontend Development - React
**Version**: 1.0.0
**Parent Agent**: Coding Instructor

---

## Skill Overview

Comprehensive React development patterns, best practices, hooks usage, component design, state management, and performance optimization for building modern web applications.

---

## React Fundamentals

### Component Types

#### Functional Components (Preferred)
```jsx
// Simple functional component
function Welcome({ name }) {
  return <h1>Hello, {name}!</h1>;
}

// Arrow function component
const Welcome = ({ name }) => {
  return <h1>Hello, {name}!</h1>;
};

// With destructuring
const UserCard = ({ user: { name, email, avatar } }) => (
  <div className="user-card">
    <img src={avatar} alt={name} />
    <h2>{name}</h2>
    <p>{email}</p>
  </div>
);
```

---

## React Hooks Patterns

### 1. useState - State Management

#### Basic Usage
```jsx
import { useState } from 'react';

function Counter() {
  const [count, setCount] = useState(0);

  return (
    <div>
      <p>Count: {count}</p>
      <button onClick={() => setCount(count + 1)}>Increment</button>
      <button onClick={() => setCount(count - 1)}>Decrement</button>
      <button onClick={() => setCount(0)}>Reset</button>
    </div>
  );
}
```

#### Multiple State Variables
```jsx
function Form() {
  const [name, setName] = useState('');
  const [email, setEmail] = useState('');
  const [agreed, setAgreed] = useState(false);

  const handleSubmit = (e) => {
    e.preventDefault();
    console.log({ name, email, agreed });
  };

  return (
    <form onSubmit={handleSubmit}>
      <input
        value={name}
        onChange={(e) => setName(e.target.value)}
        placeholder="Name"
      />
      <input
        value={email}
        onChange={(e) => setEmail(e.target.value)}
        placeholder="Email"
      />
      <label>
        <input
          type="checkbox"
          checked={agreed}
          onChange={(e) => setAgreed(e.target.checked)}
        />
        I agree to terms
      </label>
      <button type="submit">Submit</button>
    </form>
  );
}
```

#### Object State
```jsx
function UserProfile() {
  const [user, setUser] = useState({
    name: '',
    email: '',
    age: 0
  });

  const updateField = (field, value) => {
    setUser(prev => ({ ...prev, [field]: value }));
  };

  return (
    <div>
      <input
        value={user.name}
        onChange={(e) => updateField('name', e.target.value)}
      />
      <input
        value={user.email}
        onChange={(e) => updateField('email', e.target.value)}
      />
    </div>
  );
}
```

---

### 2. useEffect - Side Effects

#### Basic Effects
```jsx
import { useState, useEffect } from 'react';

function DocumentTitle() {
  const [count, setCount] = useState(0);

  // Runs after every render
  useEffect(() => {
    document.title = `Count: ${count}`;
  });

  // Runs once on mount (empty dependency array)
  useEffect(() => {
    console.log('Component mounted');
  }, []);

  // Runs when count changes
  useEffect(() => {
    console.log(`Count changed to ${count}`);
  }, [count]);

  return (
    <button onClick={() => setCount(count + 1)}>
      Clicked {count} times
    </button>
  );
}
```

#### Cleanup Effects
```jsx
function Timer() {
  const [seconds, setSeconds] = useState(0);

  useEffect(() => {
    const interval = setInterval(() => {
      setSeconds(s => s + 1);
    }, 1000);

    // Cleanup function
    return () => clearInterval(interval);
  }, []);

  return <div>Seconds: {seconds}</div>;
}
```

#### Fetching Data
```jsx
function UserList() {
  const [users, setUsers] = useState([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState(null);

  useEffect(() => {
    fetch('https://api.example.com/users')
      .then(response => response.json())
      .then(data => {
        setUsers(data);
        setLoading(false);
      })
      .catch(err => {
        setError(err.message);
        setLoading(false);
      });
  }, []);

  if (loading) return <div>Loading...</div>;
  if (error) return <div>Error: {error}</div>;

  return (
    <ul>
      {users.map(user => (
        <li key={user.id}>{user.name}</li>
      ))}
    </ul>
  );
}
```

---

### 3. useContext - Global State

```jsx
import { createContext, useContext, useState } from 'react';

// Create context
const ThemeContext = createContext();

// Provider component
function ThemeProvider({ children }) {
  const [theme, setTheme] = useState('light');

  const toggleTheme = () => {
    setTheme(prev => prev === 'light' ? 'dark' : 'light');
  };

  return (
    <ThemeContext.Provider value={{ theme, toggleTheme }}>
      {children}
    </ThemeContext.Provider>
  );
}

// Consumer component
function ThemedButton() {
  const { theme, toggleTheme } = useContext(ThemeContext);

  return (
    <button
      onClick={toggleTheme}
      style={{
        background: theme === 'light' ? '#fff' : '#333',
        color: theme === 'light' ? '#333' : '#fff'
      }}
    >
      Toggle Theme (Current: {theme})
    </button>
  );
}

// App
function App() {
  return (
    <ThemeProvider>
      <ThemedButton />
    </ThemeProvider>
  );
}
```

---

### 4. useReducer - Complex State

```jsx
import { useReducer } from 'react';

// Reducer function
function cartReducer(state, action) {
  switch (action.type) {
    case 'ADD_ITEM':
      return [...state, action.payload];
    case 'REMOVE_ITEM':
      return state.filter(item => item.id !== action.payload);
    case 'UPDATE_QUANTITY':
      return state.map(item =>
        item.id === action.payload.id
          ? { ...item, quantity: action.payload.quantity }
          : item
      );
    case 'CLEAR_CART':
      return [];
    default:
      return state;
  }
}

function ShoppingCart() {
  const [cart, dispatch] = useReducer(cartReducer, []);

  const addItem = (item) => {
    dispatch({ type: 'ADD_ITEM', payload: item });
  };

  const removeItem = (id) => {
    dispatch({ type: 'REMOVE_ITEM', payload: id });
  };

  return (
    <div>
      {cart.map(item => (
        <div key={item.id}>
          {item.name} - Qty: {item.quantity}
          <button onClick={() => removeItem(item.id)}>Remove</button>
        </div>
      ))}
    </div>
  );
}
```

---

### 5. Custom Hooks

```jsx
// useFetch hook
function useFetch(url) {
  const [data, setData] = useState(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState(null);

  useEffect(() => {
    setLoading(true);
    fetch(url)
      .then(res => res.json())
      .then(data => {
        setData(data);
        setLoading(false);
      })
      .catch(err => {
        setError(err.message);
        setLoading(false);
      });
  }, [url]);

  return { data, loading, error };
}

// Usage
function Users() {
  const { data, loading, error } = useFetch('https://api.example.com/users');

  if (loading) return <div>Loading...</div>;
  if (error) return <div>Error: {error}</div>;

  return (
    <ul>
      {data.map(user => <li key={user.id}>{user.name}</li>)}
    </ul>
  );
}
```

```jsx
// useLocalStorage hook
function useLocalStorage(key, initialValue) {
  const [value, setValue] = useState(() => {
    const stored = localStorage.getItem(key);
    return stored ? JSON.parse(stored) : initialValue;
  });

  useEffect(() => {
    localStorage.setItem(key, JSON.stringify(value));
  }, [key, value]);

  return [value, setValue];
}

// Usage
function App() {
  const [name, setName] = useLocalStorage('userName', '');

  return (
    <input
      value={name}
      onChange={(e) => setName(e.target.value)}
      placeholder="Your name"
    />
  );
}
```

---

## Component Patterns

### 1. Container/Presentational Pattern

```jsx
// Presentational Component (UI only)
function UserCard({ user, onEdit, onDelete }) {
  return (
    <div className="user-card">
      <h3>{user.name}</h3>
      <p>{user.email}</p>
      <button onClick={() => onEdit(user)}>Edit</button>
      <button onClick={() => onDelete(user.id)}>Delete</button>
    </div>
  );
}

// Container Component (logic)
function UserCardContainer({ userId }) {
  const [user, setUser] = useState(null);

  useEffect(() => {
    fetch(`/api/users/${userId}`)
      .then(res => res.json())
      .then(setUser);
  }, [userId]);

  const handleEdit = (user) => {
    console.log('Edit user:', user);
  };

  const handleDelete = (id) => {
    console.log('Delete user:', id);
  };

  if (!user) return <div>Loading...</div>;

  return (
    <UserCard
      user={user}
      onEdit={handleEdit}
      onDelete={handleDelete}
    />
  );
}
```

---

### 2. Compound Components

```jsx
function Tabs({ children }) {
  const [activeIndex, setActiveIndex] = useState(0);

  return (
    <div className="tabs">
      {React.Children.map(children, (child, index) =>
        React.cloneElement(child, {
          isActive: index === activeIndex,
          onClick: () => setActiveIndex(index)
        })
      )}
    </div>
  );
}

function Tab({ label, isActive, onClick, children }) {
  return (
    <div>
      <button
        onClick={onClick}
        className={isActive ? 'active' : ''}
      >
        {label}
      </button>
      {isActive && <div>{children}</div>}
    </div>
  );
}

// Usage
function App() {
  return (
    <Tabs>
      <Tab label="Tab 1">Content 1</Tab>
      <Tab label="Tab 2">Content 2</Tab>
      <Tab label="Tab 3">Content 3</Tab>
    </Tabs>
  );
}
```

---

### 3. Render Props Pattern

```jsx
function DataFetcher({ url, render }) {
  const { data, loading, error } = useFetch(url);

  if (loading) return <div>Loading...</div>;
  if (error) return <div>Error: {error}</div>;

  return render(data);
}

// Usage
function App() {
  return (
    <DataFetcher
      url="/api/users"
      render={(users) => (
        <ul>
          {users.map(user => <li key={user.id}>{user.name}</li>)}
        </ul>
      )}
    />
  );
}
```

---

## Performance Optimization

### 1. useMemo

```jsx
import { useMemo } from 'react';

function ExpensiveComponent({ items }) {
  const sortedItems = useMemo(() => {
    console.log('Sorting items...');
    return items.sort((a, b) => a.name.localeCompare(b.name));
  }, [items]);

  return (
    <ul>
      {sortedItems.map(item => <li key={item.id}>{item.name}</li>)}
    </ul>
  );
}
```

---

### 2. useCallback

```jsx
import { useCallback } from 'react';

function Parent() {
  const [count, setCount] = useState(0);

  const handleClick = useCallback(() => {
    console.log('Button clicked');
  }, []);

  return (
    <div>
      <Child onClick={handleClick} />
      <button onClick={() => setCount(count + 1)}>
        Increment: {count}
      </button>
    </div>
  );
}
```

---

### 3. React.memo

```jsx
import { memo } from 'react';

const ExpensiveChild = memo(function ExpensiveChild({ data }) {
  console.log('Rendering ExpensiveChild');
  return <div>{data}</div>;
});

// Only re-renders when data prop changes
```

---

## Best Practices

### ✅ DO:
1. Use functional components with hooks
2. Keep components small and focused
3. Lift state up when needed
4. Use meaningful component and variable names
5. Extract reusable logic into custom hooks
6. Memoize expensive calculations
7. Use PropTypes or TypeScript for type safety

### ❌ DON'T:
1. Mutate state directly
2. Use indexes as keys in lists
3. Forget dependency arrays in useEffect
4. Create components inside components
5. Overuse useEffect
6. Premature optimization
7. Mix business logic with UI

---

## Common Patterns Summary

| Pattern | Use Case |
|---------|----------|
| useState | Local component state |
| useEffect | Side effects, data fetching |
| useContext | Global state, theming |
| useReducer | Complex state logic |
| Custom Hooks | Reusable stateful logic |
| Container/Presentational | Separate logic from UI |
| Render Props | Share code between components |
| React.memo | Prevent unnecessary re-renders |

---

## Version History

| Version | Date | Changes |
|---------|------|---------|
| 1.0.0 | 2025-12-21 | Initial skill creation |

---

**Skill Status**: Active
**Last Updated**: 2025-12-21
