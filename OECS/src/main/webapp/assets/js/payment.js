(function () {
    'use strict';

    var redirectCounter = document.getElementById('payment-redirect-countdown');
    var homeLink = document.getElementById('payment-home-link');
    if (redirectCounter && homeLink) {
        var redirectDeadline = Date.now() + 3000;
        var redirectTimer = window.setInterval(function () {
            var seconds = Math.max(0, Math.ceil((redirectDeadline - Date.now()) / 1000));
            redirectCounter.textContent = String(seconds);
            if (seconds === 0) {
                window.clearInterval(redirectTimer);
                window.location.replace(homeLink.href);
            }
        }, 100);
    }

    var expiry = document.getElementById('payment-expiry');
    if (!expiry) return;
    var remainingValue = expiry.dataset.remainingMs;
    var remainingMs = Number(remainingValue);
    // A missing server clock used to turn an epoch timestamp into millions of minutes.
    // Invalid data must not start a timer or incorrectly disable payment controls.
    if (typeof remainingValue !== 'string' || remainingValue.trim() === ''
            || !Number.isFinite(remainingMs) || remainingMs > 15 * 60 * 1000) {
        expiry.textContent = '--:--';
        return;
    }
    // Use the server's remaining duration so the customer's clock does not affect expiry.
    var expiryDeadline = performance.now() + remainingMs;
    function updateExpiry() {
        var seconds = Math.max(0, Math.ceil((expiryDeadline - performance.now()) / 1000));
        expiry.textContent = String(Math.floor(seconds / 60)).padStart(2, '0')
                + ':' + String(seconds % 60).padStart(2, '0');
        if (seconds === 0) {
            document.getElementById('payment-pay-button').disabled = true;
            document.getElementById('payment-cod-button').disabled = true;
            document.getElementById('payment-expired-message').hidden = false;
            return false;
        }
        return true;
    }
    if (updateExpiry()) {
        var expiryTimer = window.setInterval(function () {
            if (!updateExpiry()) window.clearInterval(expiryTimer);
        }, 250);
    }
})();
