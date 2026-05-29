const fs = require("fs");
const path = require("path");
const { chromium } = require("playwright");

function parseArgs(argv) {
  const out = {
    port: 9222,
    handle: "octopusycc",
    url: "https://x.com/octopusycc/",
    urlsFile: "",
    rounds: 80,
    delayMs: 1500,
    outputDir: process.cwd(),
    stopAfterNoNewRounds: 8,
  };

  for (let i = 2; i < argv.length; i += 1) {
    const arg = argv[i];
    const next = argv[i + 1];
    if (arg === "--port") { out.port = Number(next); i += 1; }
    else if (arg === "--handle") { out.handle = next; i += 1; }
    else if (arg === "--url") { out.url = next; i += 1; }
    else if (arg === "--urlsFile") { out.urlsFile = next; i += 1; }
    else if (arg === "--rounds") { out.rounds = Number(next); i += 1; }
    else if (arg === "--delayMs" || arg === "--delay") { out.delayMs = Number(next); i += 1; }
    else if (arg === "--out" || arg === "--outputDir") { out.outputDir = next; i += 1; }
    else if (arg === "--stopAfterNoNewRounds") { out.stopAfterNoNewRounds = Number(next); i += 1; }
    else if (arg === "--help" || arg === "-h") {
      console.log([
        "Usage:",
        "  node capture_x_edge_cdp.cjs --url https://x.com/octopusycc/ --rounds 80 --out C:\\Users\\xorry\\Downloads",
        "  node capture_x_edge_cdp.cjs --urlsFile .\\octopusycc_urls.txt --rounds 20 --out C:\\Users\\xorry\\Downloads",
      ].join("\n"));
      process.exit(0);
    }
  }
  return out;
}

function sleep(ms) {
  return new Promise((resolve) => setTimeout(resolve, ms));
}

function safeFilePart(value) {
  return String(value || "x").replace(/[^\w.-]+/g, "_").replace(/^_+|_+$/g, "") || "x";
}

async function capturePage(page, options) {
  const startedAt = new Date().toISOString();
  const seen = new Map();

  async function collect() {
    return page.evaluate(({ includeHtml }) => {
      function cleanText(text) {
        return (text || "")
          .replace(/\u00a0/g, " ")
          .replace(/[ \t]+\n/g, "\n")
          .replace(/\n{4,}/g, "\n\n\n")
          .trim();
      }

      function normalizeStatusUrl(raw) {
        if (!raw) return "";
        try {
          const url = new URL(raw, location.href);
          const match = url.pathname.match(/^\/([^/]+)\/status\/(\d+)/);
          if (!match) return url.href;
          return `https://x.com/${match[1]}/status/${match[2]}`;
        } catch {
          return raw;
        }
      }

      function getMetric(article, testId) {
        const el = article.querySelector(`[data-testid="${testId}"]`);
        return el?.getAttribute("aria-label") || el?.innerText || "";
      }

      function expandVisibleLongPosts() {
        const labels = new Set(["Show more", "显示更多", "查看更多", "顯示更多", "もっと見る"]);
        const candidates = [...document.querySelectorAll('article [role="button"], article a, article span')]
          .filter((el) => labels.has(cleanText(el.innerText)));
        for (const el of candidates) {
          try { el.click(); } catch {}
        }
      }

      function extractArticle(article, indexOnPage) {
        const links = [...article.querySelectorAll('a[href*="/status/"]')].map((a) => a.href);
        const statusUrl = normalizeStatusUrl(links.find(Boolean) || "");
        const time = article.querySelector("time")?.dateTime || "";

        const tweetTextNodes = [...article.querySelectorAll('[data-testid="tweetText"]')];
        const tweetText = cleanText(tweetTextNodes.map((e) => e.innerText).join("\n\n"));
        const fallbackText = cleanText(article.innerText);

        const media = [...article.querySelectorAll('img[src*="pbs.twimg.com/media"], video')]
          .map((el) => ({
            tag: el.tagName.toLowerCase(),
            src: el.currentSrc || el.src || el.getAttribute("poster") || "",
            alt: el.getAttribute("alt") || ""
          }))
          .filter((m) => m.src);

        const text = tweetText || fallbackText;
        if (!text || text.length < 15) return null;

        return {
          statusUrl,
          time,
          userName: cleanText(article.querySelector('[data-testid="User-Name"]')?.innerText || ""),
          text,
          media,
          metrics: {
            reply: getMetric(article, "reply"),
            retweet: getMetric(article, "retweet"),
            like: getMetric(article, "like"),
            bookmark: getMetric(article, "bookmark")
          },
          indexOnPage,
          capturedAt: new Date().toISOString(),
          html: includeHtml ? article.outerHTML : undefined
        };
      }

      expandVisibleLongPosts();
      return [...document.querySelectorAll("article")]
        .map((article, index) => extractArticle(article, index))
        .filter(Boolean);
    }, { includeHtml: false });
  }

  let added = 0;
  for (const item of await collect()) {
    const key = item.statusUrl || `${item.time}:${item.text.slice(0, 160)}`;
    if (!seen.has(key)) { seen.set(key, item); added += 1; }
  }

  let noNewRounds = 0;
  for (let i = 0; i < options.rounds; i += 1) {
    await page.evaluate(() => window.scrollBy(0, Math.floor(window.innerHeight * 0.9)));
    await sleep(options.delayMs);
    added = 0;
    for (const item of await collect()) {
      const key = item.statusUrl || `${item.time}:${item.text.slice(0, 160)}`;
      if (!seen.has(key)) { seen.set(key, item); added += 1; }
    }
    noNewRounds = added === 0 ? noNewRounds + 1 : 0;
    if (noNewRounds >= options.stopAfterNoNewRounds) break;
  }

  return {
    sourceUrl: page.url(),
    handle: options.handle,
    startedAt,
    finishedAt: new Date().toISOString(),
    count: seen.size,
    tweets: [...seen.values()],
  };
}

async function main() {
  const options = parseArgs(process.argv);
  fs.mkdirSync(options.outputDir, { recursive: true });

  const endpoint = `http://127.0.0.1:${options.port}`;
  const browser = await chromium.connectOverCDP(endpoint);
  const context = browser.contexts()[0] || await browser.newContext();
  let page = context.pages().find((p) => /https?:\/\/(x|twitter)\.com/i.test(p.url())) || context.pages()[0];
  if (!page) page = await context.newPage();

  const urls = options.urlsFile
    ? fs.readFileSync(options.urlsFile, "utf8").split(/\r?\n/).map((x) => x.trim()).filter(Boolean)
    : [options.url];

  const globalSeen = new Map();
  const perUrl = [];

  for (let i = 0; i < urls.length; i += 1) {
    const url = urls[i];
    console.log(`[${i + 1}/${urls.length}] ${url}`);
    try {
      await page.goto(url, { waitUntil: "domcontentloaded", timeout: 60000 });
    } catch (error) {
      console.warn(`Navigation warning: ${error.message}`);
      try {
        await page.evaluate((nextUrl) => {
          if (location.href !== nextUrl) location.href = nextUrl;
        }, url);
      } catch {}
    }
    await sleep(6000);
    const archive = await capturePage(page, options);
    perUrl.push({ url, count: archive.count });

    for (const tweet of archive.tweets) {
      const key = tweet.statusUrl || `${tweet.time}:${tweet.text.slice(0, 160)}`;
      if (!globalSeen.has(key)) globalSeen.set(key, tweet);
    }
  }

  const tweets = [...globalSeen.values()].sort((a, b) => String(b.time).localeCompare(String(a.time)));
  const archive = {
    sourceUrl: urls.length === 1 ? urls[0] : `urlsFile:${options.urlsFile}`,
    handle: options.handle,
    startedAt: new Date().toISOString(),
    finishedAt: new Date().toISOString(),
    count: tweets.length,
    perUrl,
    tweets,
  };

  const filename = `x_${safeFilePart(options.handle)}_${new Date().toISOString().replace(/[:.]/g, "-")}.json`;
  const outputPath = path.join(options.outputDir, filename);
  fs.writeFileSync(outputPath, JSON.stringify(archive, null, 2), "utf8");
  console.log(outputPath);
  await browser.close();
}

main().catch((error) => {
  console.error(error && error.stack ? error.stack : error);
  process.exit(1);
});
