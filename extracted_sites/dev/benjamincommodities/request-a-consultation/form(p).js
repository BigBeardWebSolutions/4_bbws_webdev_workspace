/**
 * Generic Form Handler for Forms Manager API
 *
 * Auto-discovers form fields and submits to Lambda API Gateway
 * Works with all 39 form schemas without code modifications
 * Supports Gravity Forms, Contact Form 7, and custom HTML forms
 *
 * CONFIGURATION REQUIRED PER SITE:
 * 1. Set API endpoint (API_ENDPOINT constant below)
 * 2. Specify customerId via one of:
 *    - Script tag: <script src="form.js" data-customer-id="bigbeard"></script>
 *    - Global variable: window.FORM_CUSTOMER_ID = 'bigbeard';
 *    - Data attribute on form: <form data-customer-id="bigbeard">
 *
 * OPTIONAL: Manual field mapping via data attributes:
 *    <input id="input_1_3" data-field-name="phoneNumber">
 *
 * NO Python Lambda modifications required - sends proper payload format
 */

(function () {
    'use strict';

    // ========================================
    // CONFIGURATION
    // ========================================
    const CONFIG = {
        // TODO: Replace with your actual API Gateway endpoint
        API_ENDPOINT: 'https://2724gp3iv3.execute-api.af-south-1.amazonaws.com/prod/forms',

        // Enable debug logging (set to false in production)
        DEBUG: true
    };

    // ========================================
    // FIELD NAME MAPPING PATTERNS
    // ========================================
    const FIELD_PATTERNS = {
        // Name field variations (matches 'name' in Lambda schemas)
        name: [
            'name', 'fullname', 'full_name', 'custname', 'firstname', 'first_name',
            'fullName', 'Name', 'customer_name', 'your-name', 'yourname'
        ],

        // Surname/lastname (matches 'surname' and 'lastname' in Lambda schemas)
        surname: ['surname', 'last_name', 'Surname', 'lastName', 'your-surname'],
        lastname: ['lastname', 'last_name', 'lastName'],

        // Email field variations (matches 'email', 'Email', 'emailAddress' in Lambda)
        email: [
            'email', 'emailaddress', 'email_address', 'Email', 'emailAddress',
            'your-email', 'youremail', 'e-mail'
        ],

        // Phone field variations (matches 'phoneNumber', 'phone', 'tel', 'contactNumber' in Lambda)
        phoneNumber: [
            'phone', 'phonenumber', 'phone_number', 'tel', 'telephone', 'mobile',
            'contactnumber', 'contact_number', 'phoneNumber', 'contactNumber',
            'your-phone', 'yourphone', 'cell', 'cellphone'
        ],

        // Message/details field variations (matches 'message', 'details', 'enquiry', 'enquiryType' in Lambda)
        message: [
            'message', 'details', 'enquiry', 'comment', 'comments', 'enquirytype',
            'enquiry_type', 'Message', 'your-message', 'yourmessage', 'description'
        ],

        // Subject field (matches 'subject' in Lambda schemas)
        subject: ['subject', 'Subject', 'your-subject', 'title'],

        // Scholar name (panoramas specific)
        scholar_name: ['scholar_name', 'scholarname', 'scholar', 'student_name', 'studentname'],

        // Special fields (exact matches preferred)
        designation: ['designation', 'position', 'title', 'job_title'],
        quoteCategory: ['quotecategory', 'quote_category', 'quoteCategory', 'category'],
        acknowledgment: ['acknowledgment', 'acknowledgement', 'consent', 'agree', 'terms'],
        companyId: ['companyid', 'company_id', 'companyId', 'company'],
        area: ['area', 'location', 'region', 'province'],
        age: ['age'],
        country: ['country', 'nation'],
        searchText: ['searchtext', 'search_text', 'search', 'query', 'searchText', 'q'],
        additionalText: ['additionaltext', 'additional_text', 'additionalText', 'website', 'url', 'link']
    };

    // ========================================
    // GRAVITY FORMS SUPPORT
    // ========================================

    /**
     * Check if form is a Gravity Form
     */
    function isGravityForm(form) {
        return form.id && form.id.startsWith('gform_');
    }

    /**
     * Extract Gravity Forms field by looking for input_X_Y pattern
     */
    function getGravityFormFields(form) {
        const fields = {};
        const elements = form.querySelectorAll('input, textarea, select');

        elements.forEach(element => {
            if (element.id && element.id.match(/^input_\d+_/)) {
                fields[element.id] = element;
            }
        });

        return fields;
    }

    // ========================================
    // UTILITY FUNCTIONS
    // ========================================

    function log(...args) {
        if (CONFIG.DEBUG) {
            console.log('[FormsManager]', ...args);
        }
    }

    function getCustomerId() {
        // Method 1: Check script tag data attribute
        const scriptTag = document.querySelector('script[data-customer-id]');
        if (scriptTag) {
            const customerId = scriptTag.getAttribute('data-customer-id');
            log('Customer ID from script tag:', customerId);
            return customerId;
        }

        // Method 2: Check global variable
        if (window.FORM_CUSTOMER_ID) {
            log('Customer ID from global variable:', window.FORM_CUSTOMER_ID);
            return window.FORM_CUSTOMER_ID;
        }

        // Method 3: Check form data attribute (will be checked per form later)
        // Method 4: Try to extract from domain (fallback)
        const hostname = window.location.hostname;
        const match = hostname.match(/([a-z0-9]+)\.(co\.za|com|org|net)/i);
        if (match) {
            const domainCustomerId = match[1].toLowerCase();
            log('Customer ID extracted from domain:', domainCustomerId);
            return domainCustomerId;
        }

        log('WARNING: Could not determine customer ID');
        return null;
    }

    function normalizeFieldName(name) {
        // Remove common prefixes and clean field names
        // Handles: input_1, input_3, input_1_1, input_1_3, etc.
        return name
            .replace(/^input_/i, '')  // Remove "input_" prefix first
            .replace(/^\d+$/, '')      // If it's just a number after removing input_, keep it for now
            .replace(/^(field_|form_|gform_|your-|your_)/i, '')
            .replace(/[_\-\s]/g, '')
            .toLowerCase();
    }

    function matchFieldToPattern(fieldName) {
        // Special handling for Gravity Forms numeric field names (input_1, input_3, etc.)
        // Based on common Gravity Forms field order
        const gravityNumericMap = {
            'input_1': 'name',
            '1': 'name',
            'input_2': 'surname',
            '2': 'surname',
            'input_3': 'phoneNumber',
            '3': 'phoneNumber',
            'input_4': 'email',
            '4': 'email',
            'input_5': 'subject',
            '5': 'subject',
            'input_6': 'message',
            '6': 'message',

            // Additional common basic fields
            'input_7': 'phoneNumber',
            '7': 'company',
            'input_8': 'website',
            '8': 'website',
            'input_9': 'date',
            '9': 'date',
            'input_10': 'time',
            '10': 'time',
            'input_11': 'comments',
            '11': 'comments',
            'input_12': 'organization',
            '12': 'organization',

            
        };

        // Check if it's a numeric Gravity Forms field
        if (gravityNumericMap[fieldName]) {
            return gravityNumericMap[fieldName];
        }

        const normalized = normalizeFieldName(fieldName);

        // Try exact matches first
        for (const [targetField, patterns] of Object.entries(FIELD_PATTERNS)) {
            if (patterns.some(pattern => normalized === pattern.toLowerCase().replace(/[_\-\s]/g, ''))) {
                return targetField;
            }
        }

        // Try partial matches for longer field names
        for (const [targetField, patterns] of Object.entries(FIELD_PATTERNS)) {
            if (patterns.some(pattern => {
                const cleanPattern = pattern.toLowerCase().replace(/[_\-\s]/g, '');
                return normalized.includes(cleanPattern) || cleanPattern.includes(normalized);
            })) {
                return targetField;
            }
        }

        return null;
    }

    function extractFormFields(form) {
        const formData = {};
        const elements = form.elements;
        const isGravity = isGravityForm(form);

        log('Extracting fields from', elements.length, 'form elements');
        if (isGravity) {
            log('Detected Gravity Forms format');
        }

        for (let i = 0; i < elements.length; i++) {
            const element = elements[i];

            // Skip buttons and submit inputs
            if (element.type === 'submit' || element.type === 'button') {
                continue;
            }

            // Skip elements without name or id
            if (!element.name && !element.id) {
                continue;
            }

            // Skip hidden fields (except for Gravity Forms hidden fields that might have data)
            if (element.type === 'hidden' && !element.id.match(/^input_\d+_/)) {
                continue;
            }

            // Get field identifier (prefer name for Gravity Forms, fallback to id)
            const fieldIdentifier = element.name || element.id;

            // Check for explicit data attribute mapping
            const explicitMapping = element.getAttribute('data-field-name');
            let targetField;

            if (explicitMapping) {
                targetField = explicitMapping;
                log('Using explicit mapping:', fieldIdentifier, '→', targetField);
            } else {
                // For Gravity Forms, try to match by the field identifier
                targetField = matchFieldToPattern(fieldIdentifier);
                if (targetField) {
                    log('Auto-mapped:', fieldIdentifier, '→', targetField);
                }
            }

            if (targetField) {
                // Extract value based on element type
                let value;
                if (element.type === 'checkbox') {
                    value = element.checked;
                } else if (element.type === 'radio') {
                    if (element.checked) {
                        value = element.value;
                    } else {
                        continue; // Skip unchecked radios
                    }
                } else {
                    value = element.value.trim();
                }

                // Only add non-empty values (but allow false for checkboxes)
                if (value !== '' || value === false) {
                    // Avoid overwriting already-set fields (first match wins)
                    if (!formData.hasOwnProperty(targetField)) {
                        formData[targetField] = value;
                    }
                }
            } else {
                log('Could not map field:', fieldIdentifier);
            }
        }

        return formData;
    }

    async function submitToAPI(customerId, formData) {
        const payload = {
            customerId: customerId,
            formData: formData
        };

        log('Submitting payload:', payload);

        const response = await fetch(CONFIG.API_ENDPOINT, {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json'
            },
            body: JSON.stringify(payload)
        });

        if (!response.ok) {
            const errorData = await response.json().catch(() => ({}));
            log('API error response:', errorData);
            throw new Error(errorData.error || 'Form submission failed');
        }

        const result = await response.json();
        log('API success response:', result);
        return result;
    }

    function showSuccessMessage(form, result) {
        // For Gravity Forms, look for the form wrapper
        let container = form;
        if (isGravityForm(form)) {
            const wrapper = form.closest('.gform_wrapper') || form.parentElement;
            container = wrapper;
        }

        // Hide the form
        form.style.display = 'none';

        // Create success message
        const successDiv = document.createElement('div');
        successDiv.className = 'form-success-message';
        successDiv.style.cssText = `
            padding: 30px;
            background: #d4edda;
            border: 2px solid #c3e6cb;
            border-radius: 8px;
            text-align: center;
            margin: 20px 0;
        `;
        successDiv.innerHTML = `
            <h3 style="color: #155724; margin: 0 0 10px 0;">Thank You!</h3>
            <p style="color: #155724; margin: 0;">
                We have received your message and will get back to you shortly.
            </p>
            ${CONFIG.DEBUG ? `<p style="color: #155724; margin-top: 10px; font-size: 12px;">Form ID: ${result.formId}</p>` : ''}
        `;

        // Insert success message after form
        if (container.nextSibling) {
            container.parentNode.insertBefore(successDiv, container.nextSibling);
        } else {
            container.parentNode.appendChild(successDiv);
        }
    }

    function showErrorMessage(form, message) {
        // Check if error message already exists
        let errorDiv = form.querySelector('.form-error-message');

        if (!errorDiv) {
            errorDiv = document.createElement('div');
            errorDiv.className = 'form-error-message';
            errorDiv.style.cssText = `
                padding: 15px;
                background: #f8d7da;
                border: 2px solid #f5c6cb;
                border-radius: 8px;
                margin: 10px 0;
                color: #721c24;
            `;
            form.insertBefore(errorDiv, form.firstChild);
        }

        errorDiv.textContent = message;

        // Auto-remove after 10 seconds
        setTimeout(() => {
            errorDiv.remove();
        }, 10000);
    }

    function handleFormSubmit(form) {
        form.addEventListener('submit', async function (e) {
            e.preventDefault();
            e.stopImmediatePropagation(); // Stop Gravity Forms handlers

            log('Form submitted');

            // Remove any existing error messages
            const existingError = form.querySelector('.form-error-message');
            if (existingError) {
                existingError.remove();
            }

            // Get customer ID (check form data attribute first, then global)
            let customerId = form.getAttribute('data-customer-id') || getCustomerId();

            if (!customerId) {
                showErrorMessage(form, 'Configuration error: Customer ID not specified. Please contact support.');
                log('ERROR: No customer ID found');
                return;
            }

            // Find submit button (support Gravity Forms button IDs)
            const submitBtn = form.querySelector('[type="submit"]') ||
                form.querySelector('button[type="submit"]') ||
                form.querySelector('[id*="gform_submit_button"]');
            const originalBtnText = submitBtn ? (submitBtn.textContent || submitBtn.value) : null;

            // Disable submit button
            if (submitBtn) {
                submitBtn.disabled = true;
                if (submitBtn.tagName === 'INPUT') {
                    submitBtn.value = 'SENDING...';
                } else {
                    submitBtn.textContent = 'SENDING...';
                }
            }

            try {
                // Extract form data
                const formData = extractFormFields(form);
                log('Extracted form data:', formData);

                // Validate that we have at least one field
                if (Object.keys(formData).length === 0) {
                    throw new Error('No form data could be extracted. Please check field mappings.');
                }

                // Submit to API
                const result = await submitToAPI(customerId, formData);

                // Show success message
                showSuccessMessage(form, result);

            } catch (error) {
                log('Submission error:', error);

                showErrorMessage(form, 'Unable to submit form. Please try again or contact support.');

                // Re-enable submit button
                if (submitBtn) {
                    submitBtn.disabled = false;
                    if (originalBtnText) {
                        if (submitBtn.tagName === 'INPUT') {
                            submitBtn.value = originalBtnText;
                        } else {
                            submitBtn.textContent = originalBtnText;
                        }
                    }
                }
            }
        });
    }

    function initializeForms() {
        log('Initializing form handler...');
        log('API Endpoint:', CONFIG.API_ENDPOINT);

        // Find all forms on the page
        const forms = document.querySelectorAll('form');
        log('Found', forms.length, 'form(s)');

        forms.forEach((form, index) => {
            // Skip forms with data-no-handler attribute
            if (form.hasAttribute('data-no-handler')) {
                log('Skipping form', index, '(has data-no-handler attribute)');
                return;
            }

            log('Attaching handler to form', index, '(ID:', form.id || 'none', ')');

            // For Gravity Forms, we need to intercept the button click
            if (isGravityForm(form)) {
                const submitBtn = form.querySelector('[type="submit"]');
                if (submitBtn) {
                    // Remove Gravity Forms onclick handler
                    submitBtn.removeAttribute('onclick');
                    log('Removed Gravity Forms onclick handler');
                }
            }

            handleFormSubmit(form);
        });

        if (forms.length === 0) {
            log('WARNING: No forms found on page');
        }
    }

    // ========================================
    // INITIALIZATION
    // ========================================
    if (document.readyState === 'loading') {
        document.addEventListener('DOMContentLoaded', initializeForms);
    } else {
        initializeForms();
    }

    log('Generic Form Handler loaded (supports Gravity Forms, Contact Form 7, and custom HTML forms)');

})();
