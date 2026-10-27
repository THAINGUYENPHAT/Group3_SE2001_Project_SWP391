const test = require('node:test');
const assert = require('node:assert/strict');
const fs = require('node:fs');
const path = require('node:path');
const vm = require('node:vm');

const source = fs.readFileSync(path.join(__dirname, '../../main/webapp/assets/js/payment.js'), 'utf8');

function run(remainingMs) {
    let now = 0;
    const timers = new Map();
    const expiry = { dataset: { remainingMs }, textContent: '--:--' };
    const pay = { disabled: false }, cod = { disabled: false }, warning = { hidden: true };
    const elements = { 'payment-expiry': expiry, 'payment-pay-button': pay,
        'payment-cod-button': cod, 'payment-expired-message': warning };
    vm.runInNewContext(source, {
        document: { getElementById: id => elements[id] || null },
        performance: { now: () => now },
        window: { setInterval: callback => { timers.set(1, callback); return 1; },
            clearInterval: id => timers.delete(id) }
    });
    return { expiry, pay, cod, warning, timers,
        advance(ms) { now += ms; [...timers.values()].forEach(callback => callback()); } };
}

test('shows actual remaining time and counts down across a minute', () => {
    const page = run('61000');
    assert.equal(page.expiry.textContent, '01:01');
    page.advance(1000);
    assert.equal(page.expiry.textContent, '01:00');
    page.advance(1000);
    assert.equal(page.expiry.textContent, '00:59');
    assert.equal(page.pay.disabled, false);
});

test('expires at zero and stops its timer even after a delayed tick', () => {
    const page = run('1500');
    page.advance(3000);
    assert.equal(page.expiry.textContent, '00:00');
    assert.equal(page.pay.disabled, true);
    assert.equal(page.cod.disabled, true);
    assert.equal(page.warning.hidden, false);
    assert.equal(page.timers.size, 0);
});

test('already expired orders show zero, never a negative countdown', () => {
    const page = run('-1000');
    assert.equal(page.expiry.textContent, '00:00');
    assert.equal(page.pay.disabled, true);
    assert.equal(page.timers.size, 0);
});

test('missing, invalid, or epoch-sized durations never display huge minutes', () => {
    for (const value of [undefined, '', ' ', 'NaN', 'Infinity', '1793064255000', '900001']) {
        const page = run(value);
        assert.equal(page.expiry.textContent, '--:--', String(value));
        assert.equal(page.timers.size, 0);
        assert.equal(page.pay.disabled, false);
        assert.equal(page.warning.hidden, true);
    }
});

test('a full valid reservation starts at 15 minutes', () => {
    assert.equal(run('900000').expiry.textContent, '15:00');
});
