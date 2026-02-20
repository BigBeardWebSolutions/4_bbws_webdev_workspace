# Worker Instructions: Form Handling

**Worker ID**: worker-3-form-handling
**Stage**: Stage 5 - Checkout Flow
**Project**: project-plan-campaigns-frontend

---

## Task

Validate and enhance form handling components (CustomerForm, FormField) with proper validation, error display, and accessibility features.

---

## Inputs

**Primary Inputs**:
- `/Users/tebogotseka/Documents/agentic_work/2_1_bbws_web_public/campaigns/src/components/checkout/CustomerForm.tsx`
- `/Users/tebogotseka/Documents/agentic_work/2_1_bbws_web_public/campaigns/src/components/checkout/FormField.tsx`
- `/Users/tebogotseka/Documents/agentic_work/2_1_bbws_web_public/campaigns/src/utils/validation.ts`

**Supporting Inputs**:
- Form types (`src/types/form.ts`)
- Stage 4 outputs

---

## Deliverables

Create `output.md` documenting:

### 1. CustomerForm Component

Validate:
- Field definitions
- Form state management
- Submission handling
- Error display

### 2. FormField Component

Validate:
- Label and input
- Error state display
- Accessibility features
- Input types support

### 3. Validation Logic

Document:
- Field validation rules
- Real-time validation
- Form-level validation
- Error messages

### 4. Form Data Structure

Document the customer data collected:
- Required fields
- Optional fields
- Field types

---

## Expected Output Format

```markdown
# Form Handling Output

## 1. CustomerForm Component

### Current Implementation
```tsx
interface CustomerFormProps {
  onSubmit: (data: CustomerFormData) => void;
  isSubmitting?: boolean;
}

interface CustomerFormData {
  firstName: string;
  lastName: string;
  email: string;
  phone: string;
  company?: string;
}

const CustomerForm: React.FC<CustomerFormProps> = ({ onSubmit, isSubmitting }) => {
  const [formData, setFormData] = useState<CustomerFormData>({
    firstName: '',
    lastName: '',
    email: '',
    phone: '',
    company: ''
  });
  const [errors, setErrors] = useState<Partial<CustomerFormData>>({});

  const handleChange = (field: keyof CustomerFormData, value: string) => {
    setFormData(prev => ({ ...prev, [field]: value }));
    // Clear error on change
    if (errors[field]) {
      setErrors(prev => ({ ...prev, [field]: undefined }));
    }
  };

  const handleSubmit = (e: React.FormEvent) => {
    e.preventDefault();

    const validationErrors = validateForm(formData);
    if (Object.keys(validationErrors).length > 0) {
      setErrors(validationErrors);
      return;
    }

    onSubmit(formData);
  };

  return (
    <form onSubmit={handleSubmit}>
      <FormField
        label="First Name"
        value={formData.firstName}
        onChange={(v) => handleChange('firstName', v)}
        error={errors.firstName}
        required
      />
      {/* More fields... */}
      <button type="submit" disabled={isSubmitting}>
        {isSubmitting ? 'Processing...' : 'Continue to Payment'}
      </button>
    </form>
  );
};
```

### Form Fields
| Field | Type | Required | Validation |
|-------|------|----------|------------|
| firstName | text | Yes | Min 2 chars |
| lastName | text | Yes | Min 2 chars |
| email | email | Yes | Valid email |
| phone | tel | Yes | Valid phone |
| company | text | No | None |

### Validation Checklist
- [ ] All fields render
- [ ] Required fields marked
- [ ] Validation on submit
- [ ] Error display works
- [ ] Submit button states
- [ ] Disabled during submit

## 2. FormField Component

### Current Implementation
```tsx
interface FormFieldProps {
  label: string;
  value: string;
  onChange: (value: string) => void;
  error?: string;
  required?: boolean;
  type?: 'text' | 'email' | 'tel';
  placeholder?: string;
}

const FormField: React.FC<FormFieldProps> = ({
  label,
  value,
  onChange,
  error,
  required,
  type = 'text',
  placeholder
}) => {
  const inputId = `field-${label.toLowerCase().replace(/\s/g, '-')}`;

  return (
    <div style={fieldStyles}>
      <label htmlFor={inputId} style={labelStyles}>
        {label}
        {required && <span style={requiredStyles}>*</span>}
      </label>

      <input
        id={inputId}
        type={type}
        value={value}
        onChange={(e) => onChange(e.target.value)}
        placeholder={placeholder}
        aria-invalid={!!error}
        aria-describedby={error ? `${inputId}-error` : undefined}
        style={error ? inputErrorStyles : inputStyles}
      />

      {error && (
        <span id={`${inputId}-error`} role="alert" style={errorStyles}>
          {error}
        </span>
      )}
    </div>
  );
};
```

### Validation Checklist
- [ ] Label associated with input
- [ ] Required indicator shown
- [ ] Error state styling
- [ ] ARIA attributes present
- [ ] Role="alert" on errors
- [ ] Placeholder support

## 3. Validation Logic

### validation.ts
```typescript
export interface ValidationRule {
  test: (value: string) => boolean;
  message: string;
}

export const validationRules: Record<string, ValidationRule[]> = {
  firstName: [
    { test: (v) => v.length >= 2, message: 'First name must be at least 2 characters' }
  ],
  lastName: [
    { test: (v) => v.length >= 2, message: 'Last name must be at least 2 characters' }
  ],
  email: [
    { test: (v) => /^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(v), message: 'Please enter a valid email' }
  ],
  phone: [
    { test: (v) => /^[\d\s+-]{10,}$/.test(v), message: 'Please enter a valid phone number' }
  ]
};

export const validateField = (field: string, value: string): string | undefined => {
  const rules = validationRules[field];
  if (!rules) return undefined;

  for (const rule of rules) {
    if (!rule.test(value)) {
      return rule.message;
    }
  }
  return undefined;
};

export const validateForm = (data: CustomerFormData): Partial<CustomerFormData> => {
  const errors: Partial<CustomerFormData> = {};

  Object.entries(data).forEach(([field, value]) => {
    const error = validateField(field, value);
    if (error) {
      errors[field as keyof CustomerFormData] = error;
    }
  });

  return errors;
};
```

### Validation Rules
| Field | Rule | Error Message |
|-------|------|---------------|
| firstName | length >= 2 | "First name must be at least 2 characters" |
| lastName | length >= 2 | "Last name must be at least 2 characters" |
| email | valid email regex | "Please enter a valid email" |
| phone | valid phone regex | "Please enter a valid phone number" |

## 4. Form Data Structure

### CustomerFormData
```typescript
interface CustomerFormData {
  /** Customer first name (required) */
  firstName: string;

  /** Customer last name (required) */
  lastName: string;

  /** Customer email (required, validated) */
  email: string;

  /** Customer phone number (required, validated) */
  phone: string;

  /** Company name (optional) */
  company?: string;
}
```

## 5. Enhancement Recommendations

### Validation
- [ ] Add real-time validation (on blur)
- [ ] Add phone number formatting
- [ ] Add email domain validation
- [ ] Add password field (if needed)

### UX Improvements
- [ ] Auto-focus first field
- [ ] Tab navigation order
- [ ] Clear form on success
- [ ] Persist in sessionStorage

### Accessibility
- [ ] Add form description
- [ ] Screen reader announcements
- [ ] Error summary at top
- [ ] Focus first error field

## 6. Test Cases

### CustomerForm Tests
- [ ] Renders all fields
- [ ] Validates required fields
- [ ] Shows validation errors
- [ ] Calls onSubmit with valid data
- [ ] Disables submit during processing

### FormField Tests
- [ ] Renders label and input
- [ ] Associates label with input
- [ ] Shows error message
- [ ] Applies error styling
- [ ] Required indicator works
```

---

## Success Criteria

- [ ] CustomerForm validates correctly
- [ ] FormField displays errors properly
- [ ] Validation rules documented
- [ ] Form data structure defined
- [ ] Accessibility features present
- [ ] Output.md created with all sections

---

## Execution Steps

1. Read CustomerForm.tsx
2. Document form fields and state
3. Read FormField.tsx
4. Document accessibility features
5. Read validation.ts
6. Document validation rules
7. Create output.md with all sections
8. Update work.state to COMPLETE

---

**Status**: PENDING
**Created**: 2026-01-18
