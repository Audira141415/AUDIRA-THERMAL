/**
 * AUDIRA RECEIPT — LANDING PAGE JAVASCRIPT
 * Interactive Simulator, Live Terbilang Engine, Template Filters, & Accordions
 */

document.addEventListener('DOMContentLoaded', () => {

  // =========================================================================
  // 1. TERBILANG ENGINE (BAHASA INDONESIA)
  // =========================================================================
  const satuan = ['', 'Satu', 'Dua', 'Tiga', 'Empat', 'Lima', 'Enam', 'Tujuh', 'Delapan', 'Sembilan', 'Sepuluh', 'Sebelas'];

  function convertTerbilang(num) {
    num = Math.floor(Math.abs(num));
    if (num === 0) return 'Nol Rupiah';

    function terbilangHelper(n) {
      if (n < 12) {
        return satuan[n];
      } else if (n < 20) {
        return terbilangHelper(n - 10) + ' Belas';
      } else if (n < 100) {
        return terbilangHelper(Math.floor(n / 10)) + ' Puluh ' + terbilangHelper(n % 10);
      } else if (n < 200) {
        return 'Seratus ' + terbilangHelper(n - 100);
      } else if (n < 1000) {
        return terbilangHelper(Math.floor(n / 100)) + ' Ratus ' + terbilangHelper(n % 100);
      } else if (n < 2000) {
        return 'Seribu ' + terbilangHelper(n - 1000);
      } else if (n < 1000000) {
        return terbilangHelper(Math.floor(n / 1000)) + ' Ribu ' + terbilangHelper(n % 1000);
      } else if (n < 1000000000) {
        return terbilangHelper(Math.floor(n / 1000000)) + ' Juta ' + terbilangHelper(n % 1000000);
      } else if (n < 1000000000000) {
        return terbilangHelper(Math.floor(n / 1000000000)) + ' Miliar ' + terbilangHelper(n % 1000000000);
      } else {
        return terbilangHelper(Math.floor(n / 1000000000000)) + ' Triliun ' + terbilangHelper(n % 1000000000000);
      }
    }

    const words = terbilangHelper(num).replace(/\s+/g, ' ').trim();
    return words ? words + ' Rupiah' : 'Nol Rupiah';
  }

  function formatRupiah(val) {
    return 'Rp ' + Math.round(val).toLocaleString('id-ID');
  }

  // =========================================================================
  // 2. LIVE THERMAL SIMULATOR ENGINE
  // =========================================================================
  const simStoreName = document.getElementById('simStoreName');
  const simTagline = document.getElementById('simTagline');
  const simAddress = document.getElementById('simAddress');
  const simPaperSize = document.getElementById('simPaperSize');
  const simTemplate = document.getElementById('simTemplate');
  const simDiscount = document.getElementById('simDiscount');
  const simTaxPct = document.getElementById('simTaxPct');
  const simPaymentMethod = document.getElementById('simPaymentMethod');
  const simCashGiven = document.getElementById('simCashGiven');

  const tpStoreName = document.getElementById('tpStoreName');
  const tpTagline = document.getElementById('tpTagline');
  const tpAddress = document.getElementById('tpAddress');
  const tpItemsContainer = document.getElementById('tpItemsContainer');
  const tpSubtotal = document.getElementById('tpSubtotal');
  const tpDiscountRow = document.getElementById('tpDiscountRow');
  const tpDiscount = document.getElementById('tpDiscount');
  const tpTaxRow = document.getElementById('tpTaxRow');
  const tpTax = document.getElementById('tpTax');
  const tpTotal = document.getElementById('tpTotal');
  const tpTerbilang = document.getElementById('tpTerbilang');
  const tpPayMethod = document.getElementById('tpPayMethod');
  const tpCashGiven = document.getElementById('tpCashGiven');
  const tpChange = document.getElementById('tpChange');
  const tpDivider1 = document.getElementById('tpDivider1');
  const tpDivider2 = document.getElementById('tpDivider2');
  const tpDivider3 = document.getElementById('tpDivider3');
  const tpDivider4 = document.getElementById('tpDivider4');
  const tpDivider5 = document.getElementById('tpDivider5');
  const paperContainer = document.getElementById('paperContainer');

  const simItemsList = document.getElementById('simItemsList');
  const btnSimAddItem = document.getElementById('btnSimAddItem');
  const btnSimCopy = document.getElementById('btnSimCopy');

  function updateSimulator() {
    // 1. Store Header Info
    tpStoreName.textContent = simStoreName.value.trim() || 'NAMA TOKO';
    tpTagline.textContent = simTagline.value.trim() || '';
    tpAddress.textContent = simAddress.value.trim() || '';

    // 2. Paper width
    const is80 = simPaperSize.value === '80mm';
    if (is80) {
      paperContainer.style.maxWidth = '460px';
      const divDouble = '================================================';
      const divSingle = '------------------------------------------------';
      tpDivider1.textContent = divDouble;
      tpDivider4.textContent = divDouble;
      tpDivider2.textContent = divSingle;
      tpDivider3.textContent = divSingle;
      tpDivider5.textContent = divSingle;
    } else {
      paperContainer.style.maxWidth = '360px';
      const divDouble = '================================';
      const divSingle = '--------------------------------';
      tpDivider1.textContent = divDouble;
      tpDivider4.textContent = divDouble;
      tpDivider2.textContent = divSingle;
      tpDivider3.textContent = divSingle;
      tpDivider5.textContent = divSingle;
    }

    // 3. Items calculation
    let subtotal = 0;
    tpItemsContainer.innerHTML = '';

    const itemRows = simItemsList.querySelectorAll('.sim-item-row');
    itemRows.forEach(row => {
      const name = row.querySelector('.sim-item-name').value.trim() || 'Item';
      const qty = parseFloat(row.querySelector('.sim-item-qty').value) || 1;
      const price = parseFloat(row.querySelector('.sim-item-price').value) || 0;
      const lineTotal = qty * price;
      subtotal += lineTotal;

      const itemDiv = document.createElement('div');
      itemDiv.className = 'tp-item-line-wrapper';
      itemDiv.innerHTML = `
        <div class="tp-item-line">
          <span>${name}</span>
          <span>${Math.round(lineTotal).toLocaleString('id-ID')}</span>
        </div>
        <div class="tp-item-sub">${qty} x ${Math.round(price).toLocaleString('id-ID')}</div>
      `;
      tpItemsContainer.appendChild(itemDiv);
    });

    tpSubtotal.textContent = formatRupiah(subtotal);

    // 4. Discount & Tax
    const discountVal = parseFloat(simDiscount.value) || 0;
    if (discountVal > 0) {
      tpDiscountRow.style.display = 'flex';
      tpDiscount.textContent = '- ' + formatRupiah(discountVal);
    } else {
      tpDiscountRow.style.display = 'none';
    }

    const taxPct = parseFloat(simTaxPct.value) || 0;
    const taxBase = Math.max(0, subtotal - discountVal);
    const taxVal = Math.round((taxBase * taxPct) / 100);

    if (taxVal > 0) {
      tpTaxRow.style.display = 'flex';
      tpTaxRow.querySelector('span:first-child').textContent = `PPN (${taxPct}%):`;
      tpTax.textContent = '+ ' + formatRupiah(taxVal);
    } else {
      tpTaxRow.style.display = 'none';
    }

    // 5. Total & Terbilang
    const total = Math.max(0, subtotal - discountVal + taxVal);
    tpTotal.textContent = formatRupiah(total);
    tpTerbilang.textContent = `"${convertTerbilang(total)}"`;

    // 6. Payment & Change
    const payMethod = simPaymentMethod.value;
    tpPayMethod.textContent = payMethod;
    const cashGiven = parseFloat(simCashGiven.value) || total;
    tpCashGiven.textContent = formatRupiah(cashGiven);

    const change = Math.max(0, cashGiven - total);
    tpChange.textContent = formatRupiah(change);
  }

  // Event Listeners for Simulator Inputs
  [simStoreName, simTagline, simAddress, simPaperSize, simTemplate, simDiscount, simTaxPct, simPaymentMethod, simCashGiven].forEach(el => {
    el.addEventListener('input', updateSimulator);
    el.addEventListener('change', updateSimulator);
  });

  simItemsList.addEventListener('input', updateSimulator);

  // Add Item to list
  btnSimAddItem.addEventListener('click', () => {
    const row = document.createElement('div');
    row.className = 'sim-item-row';
    row.innerHTML = `
      <input type="text" class="sim-item-name" value="Item Baru" placeholder="Nama Barang">
      <input type="number" class="sim-item-qty" value="1" min="1" max="99">
      <input type="number" class="sim-item-price" value="15000" step="500">
      <button type="button" class="btn-remove-item" title="Hapus">×</button>
    `;
    simItemsList.appendChild(row);
    updateSimulator();
  });

  // Remove Item from list
  simItemsList.addEventListener('click', (e) => {
    if (e.target.classList.contains('btn-remove-item')) {
      const rows = simItemsList.querySelectorAll('.sim-item-row');
      if (rows.length > 1) {
        e.target.closest('.sim-item-row').remove();
        updateSimulator();
      } else {
        alert('Minimal harus ada 1 item transaksi!');
      }
    }
  });

  // Copy Plain Text Receipt
  btnSimCopy.addEventListener('click', () => {
    const is80 = simPaperSize.value === '80mm';
    const width = is80 ? 48 : 32;
    const divider = '='.repeat(width);
    const sDivider = '-'.repeat(width);

    let text = `${simStoreName.value.toUpperCase()}\n`;
    if (simTagline.value) text += `${simTagline.value}\n`;
    if (simAddress.value) text += `${simAddress.value}\n`;
    text += `${divider}\n`;
    text += `No. Bukti : AUD-2026-0088\n`;
    text += `Tanggal   : 28/09/2026 15:42\n`;
    text += `Kasir     : Admin / Kasir 01\n`;
    text += `${sDivider}\n`;

    let subtotal = 0;
    const itemRows = simItemsList.querySelectorAll('.sim-item-row');
    itemRows.forEach(row => {
      const name = row.querySelector('.sim-item-name').value || 'Item';
      const qty = parseFloat(row.querySelector('.sim-item-qty').value) || 1;
      const price = parseFloat(row.querySelector('.sim-item-price').value) || 0;
      const lineTotal = qty * price;
      subtotal += lineTotal;
      text += `${name}\n`;
      text += `  ${qty} x ${price.toLocaleString('id-ID')} = ${lineTotal.toLocaleString('id-ID')}\n`;
    });

    const discountVal = parseFloat(simDiscount.value) || 0;
    const taxPct = parseFloat(simTaxPct.value) || 0;
    const taxVal = Math.round((Math.max(0, subtotal - discountVal) * taxPct) / 100);
    const total = Math.max(0, subtotal - discountVal + taxVal);

    text += `${sDivider}\n`;
    text += `Subtotal  : Rp ${subtotal.toLocaleString('id-ID')}\n`;
    if (discountVal > 0) text += `Diskon    : - Rp ${discountVal.toLocaleString('id-ID')}\n`;
    if (taxVal > 0) text += `PPN (${taxPct}%): + Rp ${taxVal.toLocaleString('id-ID')}\n`;
    text += `${divider}\n`;
    text += `TOTAL     : Rp ${total.toLocaleString('id-ID')}\n`;
    text += `Terbilang : ${convertTerbilang(total)}\n`;
    text += `${sDivider}\n`;
    text += `*** LUNAS ***\n`;
    text += `Terima kasih atas kunjungan Anda!\n`;

    navigator.clipboard.writeText(text).then(() => {
      const originalText = btnSimCopy.innerHTML;
      btnSimCopy.innerHTML = '<span>✓ Teks Struk Berhasil Disalin!</span>';
      setTimeout(() => {
        btnSimCopy.innerHTML = originalText;
      }, 2500);
    });
  });

  // Initial Simulator Run
  updateSimulator();


  // =========================================================================
  // 3. TEMPLATE FILTERING
  // =========================================================================
  const filterBtns = document.querySelectorAll('.filter-btn');
  const tplCards = document.querySelectorAll('.tpl-card');

  filterBtns.forEach(btn => {
    btn.addEventListener('click', () => {
      filterBtns.forEach(b => b.classList.remove('active'));
      btn.classList.add('active');

      const cat = btn.getAttribute('data-cat');
      tplCards.forEach(card => {
        if (cat === 'all' || card.getAttribute('data-cat') === cat) {
          card.style.display = 'flex';
        } else {
          card.style.display = 'none';
        }
      });
    });
  });


  // =========================================================================
  // 4. FAQ ACCORDION
  // =========================================================================
  const faqItems = document.querySelectorAll('.faq-item');
  faqItems.forEach(item => {
    const question = item.querySelector('.faq-question');
    question.addEventListener('click', () => {
      const wasActive = item.classList.contains('active');
      faqItems.forEach(i => i.classList.remove('active'));
      if (!wasActive) {
        item.classList.add('active');
      }
    });
  });


  // =========================================================================
  // 5. MOBILE MENU TOGGLE
  // =========================================================================
  const mobileToggle = document.getElementById('mobileMenuToggle');
  const navMenu = document.getElementById('navMenu');

  if (mobileToggle && navMenu) {
    mobileToggle.addEventListener('click', () => {
      const isVisible = navMenu.style.display === 'flex';
      if (isVisible) {
        navMenu.style.display = '';
      } else {
        navMenu.style.display = 'flex';
        navMenu.style.flexDirection = 'column';
        navMenu.style.position = 'absolute';
        navMenu.style.top = '72px';
        navMenu.style.left = '0';
        navMenu.style.width = '100%';
        navMenu.style.background = '#0B0F19';
        navMenu.style.padding = '1.5rem';
        navMenu.style.borderBottom = '1px solid rgba(255,255,255,0.1)';
      }
    });
  }

});
