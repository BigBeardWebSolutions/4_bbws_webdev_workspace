# Worker 3-4: HTML Email Templates

**Worker ID**: worker-3-4-html-email-templates
**Stage**: Stage 3 - Infrastructure Code Development
**Status**: PENDING
**Estimated Effort**: High
**Dependencies**: Stage 2 Worker 2-3

---

## Objective

Create all 12 HTML email templates based on the S3 design specifications from Stage 2.

---

## Input Documents

1. **Stage 2 Outputs**:
   - `/Users/tebogotseka/Documents/agentic_work/2_bbws_docs/LLDs/project-plan-1/stage-2-lld-document-creation/worker-3-s3-design-section/output.md` (Section 5.2.3 - HTML Email Templates)

---

## Deliverables

Create `/Users/tebogotseka/Documents/agentic_work/2_bbws_docs/LLDs/project-plan-1/stage-3-infrastructure-code/worker-4-html-email-templates/output.md` containing:

### 12 HTML Email Templates

Create each template with:
- Responsive HTML structure
- Mustache-style variables ({{variableName}})
- BBWS branding (placeholder)
- Mobile-responsive design
- Plain text alternative (commented section)

**Templates to create**:
1. receipts/payment_received.html
2. receipts/payment_failed.html
3. receipts/refund_processed.html
4. notifications/order_confirmation.html
5. notifications/order_shipped.html
6. notifications/order_delivered.html
7. notifications/order_cancelled.html
8. invoices/invoice_created.html
9. invoices/invoice_updated.html
10. marketing/campaign_notification.html
11. marketing/welcome_email.html
12. marketing/newsletter_template.html

Each template should include:
- DOCTYPE and html5 structure
- Responsive meta tags
- CSS (inline or style block)
- All variables from LLD Section 5.2.3
- Unsubscribe link (for marketing emails)

---

## Quality Criteria

- [ ] All 12 templates created
- [ ] Valid HTML5 syntax
- [ ] All variables from LLD included
- [ ] Responsive design (mobile-friendly)
- [ ] Marketing emails have unsubscribe link
- [ ] Professional appearance
- [ ] Consistent branding

---

## Output Format

Write output to `output.md` containing all 12 HTML templates in code blocks with file path headers.

**Target Length**: 1,500-2,000 lines

---

## Special Instructions

1. **Use LLD Specs**: Extract variable lists from Stage 2 Worker 2-3 Section 5.2.3
2. **Responsive Design**: Use simple responsive HTML (table-based for email compatibility)
3. **Variables**: Use {{variableName}} format exactly as specified in LLD
4. **Branding**: Use placeholder BBWS branding (logo URL as {{logoUrl}})

---

**Worker Created**: 2025-12-25
**Execution Mode**: Parallel (with 5 other Stage 3 workers)
