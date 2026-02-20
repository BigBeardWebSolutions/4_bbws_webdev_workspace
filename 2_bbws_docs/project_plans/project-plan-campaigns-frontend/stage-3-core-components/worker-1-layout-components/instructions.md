# Worker Instructions: Layout Components

**Worker ID**: worker-1-layout-components
**Stage**: Stage 3 - Core Components Development
**Project**: project-plan-campaigns-frontend

---

## Task

Validate and enhance the layout components (PageLayout, Navigation) to ensure they support all routes and provide consistent styling and navigation across the application.

---

## Inputs

**Primary Inputs**:
- `/Users/tebogotseka/Documents/agentic_work/2_1_bbws_web_public/campaigns/src/components/layout/PageLayout.tsx`
- `/Users/tebogotseka/Documents/agentic_work/2_1_bbws_web_public/campaigns/src/components/layout/Navigation.tsx`

**Supporting Inputs**:
- Stage 2 outputs (routing configuration)
- Stage 1 Gap Analysis output
- Existing test files

---

## Deliverables

Create `output.md` documenting:

### 1. Component Analysis

For each layout component:
- Current implementation review
- Props interface
- Styling approach
- Accessibility features

### 2. PageLayout Component

Validate:
- Consistent page wrapper
- Navigation inclusion
- Back button support
- Footer (if applicable)
- Responsive design

### 3. Navigation Component

Validate:
- Logo display
- Menu items
- Active state indication
- Mobile responsiveness
- External link handling

### 4. Enhancement Recommendations

Document any improvements needed:
- Accessibility enhancements
- Responsive breakpoints
- Animation/transitions
- Error states

---

## Expected Output Format

```markdown
# Layout Components Output

## 1. Component Analysis

### PageLayout.tsx
- **Location**: src/components/layout/PageLayout.tsx
- **Purpose**: Main page wrapper
- **Props**:
  - `children: React.ReactNode`
  - `showBackButton?: boolean`
- **Styling**: Inline styles
- **Accessibility**: ARIA labels present/missing

### Navigation.tsx
- **Location**: src/components/layout/Navigation.tsx
- **Purpose**: Site navigation header
- **Props**: None
- **Styling**: Inline styles
- **Accessibility**: ARIA navigation present/missing

## 2. PageLayout Component

### Current Implementation
```tsx
interface PageLayoutProps {
  children: React.ReactNode;
  showBackButton?: boolean;
}

const PageLayout: React.FC<PageLayoutProps> = ({ children, showBackButton = true }) => {
  return (
    <div style={containerStyles}>
      <Navigation />
      {showBackButton && <BackButton />}
      <main style={mainStyles}>
        {children}
      </main>
      <Footer />
    </div>
  );
};
```

### Validation Checklist
- [ ] Wraps all page content
- [ ] Includes Navigation
- [ ] Back button conditional display
- [ ] Main content area defined
- [ ] Footer present (if required)
- [ ] Responsive layout

### Recommended Enhancements
- [ ] Add skip-to-main-content link
- [ ] Ensure ARIA landmarks
- [ ] Add scroll-to-top on route change

## 3. Navigation Component

### Current Implementation
```tsx
const Navigation: React.FC = () => {
  return (
    <nav style={navStyles}>
      <Logo />
      <MenuItems />
    </nav>
  );
};
```

### Menu Items
| Item | Link | Type |
|------|------|------|
| Home | https://bigbeard.co.za | External |
| About | https://bigbeard.co.za/about | External |
| Services | https://bigbeard.co.za/services | External |
| Contact | https://bigbeard.co.za/contact | External |

### Validation Checklist
- [ ] Logo clickable (links to home)
- [ ] Menu items render correctly
- [ ] External links open in new tab
- [ ] Responsive mobile menu
- [ ] ARIA navigation role

### Recommended Enhancements
- [ ] Add aria-label to nav
- [ ] Mobile hamburger menu
- [ ] Active link styling

## 4. Enhancement Recommendations

### Accessibility (A11y)
1. Add `<main>` landmark
2. Add skip navigation link
3. Ensure focus management on route change

### Responsive Design
1. Stack navigation on mobile
2. Adjust padding/margins
3. Touch-friendly tap targets

### Performance
1. Lazy load logo image
2. Minimize inline style recalculations

## 5. Test Coverage

### Existing Tests
- PageLayout.test.tsx: Present/Missing
- Navigation.test.tsx: Present/Missing

### Test Cases Needed
- [ ] PageLayout renders children
- [ ] PageLayout shows/hides back button
- [ ] Navigation renders all menu items
- [ ] Navigation logo links correctly
```

---

## Success Criteria

- [ ] PageLayout component validated
- [ ] Navigation component validated
- [ ] All props documented
- [ ] Accessibility reviewed
- [ ] Responsive design verified
- [ ] Test coverage documented
- [ ] Output.md created with all sections

---

## Execution Steps

1. Read PageLayout.tsx
2. Document props and implementation
3. Read Navigation.tsx
4. Document navigation items and links
5. Review accessibility features
6. Check responsive design
7. Review existing tests
8. Document enhancement recommendations
9. Create output.md with all sections
10. Update work.state to COMPLETE

---

**Status**: PENDING
**Created**: 2026-01-18
