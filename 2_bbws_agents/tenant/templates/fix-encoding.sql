-- Fix UTF-8 encoding issues in WordPress database

-- Fix non-breaking space (Â )
UPDATE wp_posts SET post_content = REPLACE(post_content, 'Â ', ' ');
UPDATE wp_posts SET post_content = REPLACE(post_content, 'Â', '');
UPDATE wp_postmeta SET meta_value = REPLACE(meta_value, 'Â ', ' ');
UPDATE wp_postmeta SET meta_value = REPLACE(meta_value, 'Â', '');

-- Fix curly quotes
UPDATE wp_posts SET post_content = REPLACE(post_content, 'â€™', '\'');
UPDATE wp_posts SET post_content = REPLACE(post_content, 'â€œ', '"');
UPDATE wp_posts SET post_content = REPLACE(post_content, 'â€', '"');
UPDATE wp_postmeta SET meta_value = REPLACE(meta_value, 'â€™', '\'');
UPDATE wp_postmeta SET meta_value = REPLACE(meta_value, 'â€œ', '"');
UPDATE wp_postmeta SET meta_value = REPLACE(meta_value, 'â€', '"');

-- Fix em-dashes
UPDATE wp_posts SET post_content = REPLACE(post_content, 'â€"', '–');
UPDATE wp_posts SET post_content = REPLACE(post_content, 'â€"', '—');
UPDATE wp_postmeta SET meta_value = REPLACE(meta_value, 'â€"', '–');
UPDATE wp_postmeta SET meta_value = REPLACE(meta_value, 'â€"', '—');

SELECT 'Encoding fixes complete!' as status;
