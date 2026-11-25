// Replace the production URL below with the deployed service's HTTPS /loader URL.
// Keep it empty until the service is running; never use a public EXE asset URL.
window.scoobyLoaderDownloadUrl = ['localhost', '127.0.0.1', '[::1]'].includes(location.hostname)
    ? location.origin + '/api/loader/download'
    : '';
