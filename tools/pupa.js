const puppeteer = require('puppeteer');
const fs = require('fs');
const path = require('path');

async function runScraper(viewUrl, ip, port, userAgent) {
  const proxyAddress = `http://${ip}:${port}`;
  const browser = await puppeteer.launch({
    args: [
      `--proxy-server=${proxyAddress}`,
      '--no-sandbox',
      '--disable-setuid-sandbox',
      '--disable-dev-shm-usage',
      '--disable-accelerated-2d-canvas',
      '--no-first-run',
      '--no-zygote',
      '--single-process',
      '--disable-gpu',
      '--ignore-certificate-errors',
      '--ignore-certificate-errors-spki-list'
    ],
    headless: "new",
    ignoreHTTPSErrors: true
  });

  // Create folder for screenshots
  const now = new Date();
  const folderName = now.toISOString().replace(/[:T]/g, '_').slice(0, 13); // Format: YYYY_MM_DD_HH
  const screenshotDir = path.join('res', 'ss', folderName);
  fs.mkdirSync(screenshotDir, { recursive: true });

  try {
    const page = await browser.newPage();
    await page.setUserAgent(userAgent);

    // Enable JavaScript
    await page.setJavaScriptEnabled(true);
    await page.setExtraHTTPHeaders({
      'Accept-Language': 'en-US,en;q=0.9',
      'Sec-CH-UA': '"Google Chrome";v="91", "Chromium";v="91", ";Not A Brand";v="99"',
      'Sec-CH-UA-Mobile': '?0',
      'Sec-CH-UA-Platform': '"Windows"',
    });
    //await page.emulate(puppeteer.devices['Desktop 1920x1080']);
    // Set viewport size
    await page.setViewport({width: 1920, height: 1080});

    // Increase default timeout
    page.setDefaultNavigationTimeout(10000); // 10 seconds
    page.on('pageerror', (error) => {
      if (error.message.includes('Navigation timeout')) {
        console.log('Status: ERROR');
        console.log('Error: Navigation timeout exceeded');
        browser.close();
      }
    });

    // Check IP address
    console.log('Checking IP address...');
    try {
      const ipCheckPromise = page.goto('https://httpbin.org/ip', { waitUntil: 'networkidle2' });
      await Promise.race([
        ipCheckPromise,
        new Promise((_, reject) => setTimeout(() => reject(new Error('Timeout')), 5000))
      ]);
    } catch (error) {
      if (error.message === 'Timeout') {
        console.log('Status: ERROR');
        console.log('Error: IP check timeout exceeded');
      } else if (error.message.includes('net::ERR_PROXY_CONNECTION_FAILED')) {
        console.log('Status: ERROR');
        console.log('Error: Proxy connection failed');
      } else {
        console.log('Status: ERROR');
        console.log(`Error accessing httpbin.org/ip: ${error.message}`);
      }
      await browser.close();
      return; // Przerwij dalsze wykonanie skryptu
    }

    const ipContent = await page.evaluate(() => document.body.textContent);
    let ipJson;
    try {
      ipJson = JSON.parse(ipContent);
    } catch (error) {
      console.log('Status: ERROR');
      console.log(`Error parsing IP response: ${error.message}`);
      await browser.close();
      return; // Przerwij dalsze wykonanie skryptu
    }
    console.log('Current IP address:', ipJson.origin);
    console.log(`Navigating to ${viewUrl}`);
    try {
      await page.goto(viewUrl, { waitUntil: 'networkidle2' });
    } catch (error) {
      console.log('Status: ERROR');
      if (error.message.includes('net::ERR_CONNECTION_RESET')) {
        console.log('Error: Connection reset');
      } else if (error.message.includes('net::ERR_CONNECTION_CLOSED')) {
        console.log('Error: Connection closed');
      } else if (error.message.includes('net::ERR_PROXY_CONNECTION_FAILED')) {
        console.log('Error: Proxy connection failed');
      } else if (error.message.includes('Navigation timeout')) {
        console.log('Error: Navigation timeout exceeded');
      } else {
        console.log(`Error: ${error.message}`);
      }
      await browser.close();
      return; // Przerwij dalsze wykonanie skryptu
    }

    // Wait for any lazy-loaded content
    await new Promise(resolve => setTimeout(resolve, 5000));

    // Znajdź interesujący element (na przykład, główny kontener treści)
    const element = await page.$('main'); // Zmień 'main' na selektor odpowiadający interesującemu Cię elementowi

    const date = new Date().toISOString().replace(/[:.]/g, '-');
    const baseUrl = new URL(viewUrl).hostname;

    if (element) {
      // Pobierz wymiary i pozycję elementu
      const boundingBox = await element.boundingBox();

      // Zrób zrzut ekranu tylko tego elementu
      const screenshotBuffer = await page.screenshot({
        clip: boundingBox,
        encoding: 'binary'
      });

      // Zapisz zrzut ekranu
      const screenshotName = `${date}_${baseUrl}_${ip}.png`;
      const screenshotPath = path.join(screenshotDir, screenshotName);
      fs.writeFileSync(screenshotPath, screenshotBuffer);
      console.log(`Screenshot saved as ${screenshotPath}`);
    } else {
      console.log('Element not found. Taking full page screenshot.');
      // Jeśli element nie został znaleziony, zrób zrzut całej strony
      const screenshotName = `${date}_${baseUrl}_${ip}_full.png`;
      const screenshotPath = path.join(screenshotDir, screenshotName);
      await page.screenshot({ path: screenshotPath, fullPage: true });
      console.log(`Full page screenshot saved as ${screenshotPath}`);
    }

    console.log('Status: SUCCESS');
  } catch (error) {
    console.error('An error occurred:', error);
    console.log('Status: ERROR');
  } finally {
    await browser.close();
  }
}

async function autoScroll(page) {
  await page.evaluate(async () => {
    await new Promise((resolve) => {
      var totalHeight = 0;
      var distance = 100;
      var timer = setInterval(() => {
        var scrollHeight = document.body.scrollHeight;
        window.scrollBy(0, distance);
        totalHeight += distance;

        if(totalHeight >= scrollHeight){
          clearInterval(timer);
          resolve();
        }
      }, 100);
    });
  });
}

// Parse command line arguments
const args = process.argv.slice(2).reduce((acc, arg) => {
  const [key, value] = arg.split('=');
  acc[key] = value;
  return acc;
}, {});

// Extract parameters from command line arguments
const viewUrl = args.VIEW_URL || 'http://example.com';
const ip = args.IP || '127.0.0.1';
const port = args.PORT || '80';
const userAgent = args.USER_AGENT || 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36';

// Run the scraper
runScraper(viewUrl, ip, port, userAgent);