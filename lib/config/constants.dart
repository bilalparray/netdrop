const appDisplayName = 'NetDrop';
const androidPackageName = 'com.qayham.netdrop';
const playStoreListingUrl =
    'https://play.google.com/store/apps/details?id=$androidPackageName';
const protocolVersion = '2.1';
const defaultPort = 53317;
const discoveryPort = 53316;
const portFallbackAttempts = 8;
const defaultDiscoveryTimeoutMs = 500;
const defaultMulticastGroup = '224.0.0.167';
const apiBasePath = '/api/netdrop/v2';

/// Parallel HTTP uploads per send session (LAN Wi‑Fi handles 6 well).
const uploadConcurrency = 6;

/// Parallel file-picker → CrossFile conversions after multi-select.
const filePrepConcurrency = 6;

/// Per-file upload attempts before failing the whole session.
const uploadMaxRetries = 3;

/// Read/write chunk size for file streams (256 KB).
const transferStreamChunkSize = 256 * 1024;
