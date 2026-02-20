#!/usr/bin/env php
<?php
/**
 * Extract All-in-One WP Migration .wpress file
 *
 * Usage: php extract_wpress.php <wpress_file> <output_directory>
 */

if ($argc < 3) {
    echo "Usage: php extract_wpress.php <wpress_file> <output_directory>\n";
    exit(1);
}

$wpressFile = $argv[1];
$outputDir = $argv[2];

if (!file_exists($wpressFile)) {
    echo "Error: File not found: $wpressFile\n";
    exit(1);
}

// Create output directory
if (!is_dir($outputDir)) {
    mkdir($outputDir, 0755, true);
}

echo "Extracting $wpressFile to $outputDir\n\n";

// Open the .wpress file
$handle = fopen($wpressFile, 'rb');
if (!$handle) {
    echo "Error: Cannot open file\n";
    exit(1);
}

$fileCount = 0;
$totalSize = 0;

while (!feof($handle)) {
    // Read file header
    $header = fread($handle, 4377);
    if (strlen($header) < 4377) {
        break; // End of archive
    }

    // Parse header
    // First 255 bytes: filename
    // Next 14 bytes: file size (as string)
    // Next 14 bytes: mtime
    // Rest: padding

    $filename = rtrim(substr($header, 0, 255), "\0");
    $filesize = intval(trim(substr($header, 255, 14)));
    $mtime = intval(trim(substr($header, 269, 14)));

    if (empty($filename)) {
        break;
    }

    echo "Extracting: $filename ($filesize bytes)\n";

    // Create directory structure
    $filepath = $outputDir . '/' . $filename;
    $filedir = dirname($filepath);
    if (!is_dir($filedir)) {
        mkdir($filedir, 0755, true);
    }

    // Read and write file content
    $outHandle = fopen($filepath, 'wb');
    $remaining = $filesize;
    $chunkSize = 1024 * 1024; // 1MB chunks

    while ($remaining > 0) {
        $toRead = min($chunkSize, $remaining);
        $data = fread($handle, $toRead);
        fwrite($outHandle, $data);
        $remaining -= strlen($data);
    }

    fclose($outHandle);
    touch($filepath, $mtime);

    $fileCount++;
    $totalSize += $filesize;
}

fclose($handle);

echo "\n";
echo "========================================\n";
echo "Extraction Complete!\n";
echo "========================================\n";
echo "Files extracted: $fileCount\n";
echo "Total size: " . round($totalSize / 1024 / 1024, 2) . " MB\n";
echo "Output directory: $outputDir\n";
echo "\n";
echo "Look for:\n";
echo "- database.sql (WordPress database)\n";
echo "- package.json (metadata)\n";
echo "- WordPress files in original structure\n";
?>
