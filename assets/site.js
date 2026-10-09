const navLinks = document.getElementById("nav-links");
const navToggle = document.getElementById("nav-toggle");
const themeToggle = document.getElementById("theme-toggle");
const progress = document.getElementById("reading-progress");
const shareActions = document.querySelector(".share-actions");
const shareStatus = document.querySelector(".share-status");

const savedTheme = localStorage.getItem("bfg-theme");
if (savedTheme === "dark") {
  document.body.classList.add("dark-theme");
  themeToggle.innerHTML = '<i class="ri-sun-line" aria-hidden="true"></i>';
}

navToggle?.addEventListener("click", () => {
  navLinks?.classList.toggle("show");
});

document.querySelectorAll(".nav__links a").forEach((link) => {
  link.addEventListener("click", () => navLinks?.classList.remove("show"));
});

themeToggle?.addEventListener("click", () => {
  document.body.classList.toggle("dark-theme");
  const isDark = document.body.classList.contains("dark-theme");
  localStorage.setItem("bfg-theme", isDark ? "dark" : "light");
  themeToggle.innerHTML = isDark
    ? '<i class="ri-sun-line" aria-hidden="true"></i>'
    : '<i class="ri-moon-line" aria-hidden="true"></i>';
  updateGiscusTheme();
});

function updateProgress() {
  if (!progress) return;
  const scrollTop = window.scrollY;
  const height = document.documentElement.scrollHeight - window.innerHeight;
  const width = height > 0 ? (scrollTop / height) * 100 : 0;
  progress.style.width = `${Math.min(width, 100)}%`;
}

window.addEventListener("scroll", updateProgress, { passive: true });
updateProgress();

document.querySelectorAll("pre").forEach((pre) => {
  const code = pre.querySelector("code");
  if (!code || pre.classList.contains("mermaid") || code.className.includes("mermaid")) return;

  const button = document.createElement("button");
  button.className = "copy-code";
  button.type = "button";
  button.textContent = "Copy";
  button.addEventListener("click", async () => {
    await navigator.clipboard.writeText(code.innerText);
    button.textContent = "Copied";
    window.setTimeout(() => {
      button.textContent = "Copy";
    }, 1400);
  });
  pre.appendChild(button);
});

function prepareMermaid() {
  document.querySelectorAll("pre.mermaid > code, pre > code.language-mermaid").forEach((code) => {
    const wrapper = document.createElement("div");
    wrapper.className = "mermaid";
    wrapper.textContent = code.textContent;
    code.closest("pre").replaceWith(wrapper);
  });

  if (window.mermaid) {
    window.mermaid.initialize({
      startOnLoad: false,
      theme: document.body.classList.contains("dark-theme") ? "dark" : "default",
    });
    window.mermaid.run();
  }
}

window.addEventListener("mermaid-ready", prepareMermaid);
prepareMermaid();

function articleSourcePath() {
  const fileName = window.location.pathname.split("/").pop() || "";
  if (!fileName.startsWith("week-") || !fileName.endsWith(".html")) return null;
  return `content/posts/${fileName.replace(/\.html$/, ".md")}`;
}

function setShareStatus(message) {
  if (!shareStatus) return;
  shareStatus.textContent = message;
  window.setTimeout(() => {
    if (shareStatus.textContent === message) shareStatus.textContent = "";
  }, 2200);
}

async function copyText(value) {
  if (navigator.clipboard?.writeText) {
    try {
      await navigator.clipboard.writeText(value);
      return true;
    } catch {
      // Fall through to the textarea fallback for browsers that expose
      // clipboard access but reject it in the current context.
    }
  }

  const textarea = document.createElement("textarea");
  textarea.value = value;
  textarea.setAttribute("readonly", "");
  textarea.style.position = "fixed";
  textarea.style.left = "-9999px";
  document.body.appendChild(textarea);
  textarea.select();
  const copied = document.execCommand("copy");
  textarea.remove();
  return copied;
}

function setupSharing() {
  if (!shareActions) return;

  const title = (shareActions.dataset.shareTitle || document.title).replace(/\s+/g, " ").trim();
  const url = window.location.href.split("#")[0];
  const encodedUrl = encodeURIComponent(url);
  const encodedTitle = encodeURIComponent(title);
  const nativeButton = shareActions.querySelector("[data-share-native]");
  const copyButton = shareActions.querySelector("[data-copy-link]");
  const linkedIn = shareActions.querySelector("[data-share-linkedin]");
  const x = shareActions.querySelector("[data-share-x]");
  const edit = shareActions.querySelector("[data-edit-github]");
  const discussQuestion = document.querySelector("[data-discuss-question]");
  const discussGeneral = document.querySelector("[data-discuss-general]");
  const sourcePath = articleSourcePath();

  if (linkedIn) {
    linkedIn.href = `https://www.linkedin.com/sharing/share-offsite/?url=${encodedUrl}`;
  }
  if (x) {
    x.href = `https://twitter.com/intent/tweet?text=${encodedTitle}&url=${encodedUrl}`;
  }
  if (edit && sourcePath) {
    edit.href = `https://github.com/Caffeinated-Code/Bioinformatics_Field_Guide/edit/main/${sourcePath}`;
  } else if (edit) {
    edit.href = "https://github.com/Caffeinated-Code/Bioinformatics_Field_Guide";
  }
  if (discussQuestion) {
    discussQuestion.href = `https://github.com/Caffeinated-Code/Bioinformatics_Field_Guide/discussions/new?category=q-a&title=${encodedTitle}`;
  }
  if (discussGeneral) {
    discussGeneral.href = "https://github.com/Caffeinated-Code/Bioinformatics_Field_Guide/discussions";
  }

  nativeButton?.addEventListener("click", async () => {
    if (navigator.share) {
      try {
        await navigator.share({ title, url });
        setShareStatus("Shared");
      } catch {
        setShareStatus("");
      }
      return;
    }
    try {
      await copyText(url);
      setShareStatus("Link copied");
    } catch {
      setShareStatus("Copy the URL from your browser bar");
    }
  });

  copyButton?.addEventListener("click", async () => {
    try {
      await copyText(url);
      setShareStatus("Link copied");
    } catch {
      setShareStatus("Copy the URL from your browser bar");
    }
  });
}

function updateGiscusTheme() {
  const iframe = document.querySelector("iframe.giscus-frame");
  if (!iframe) return;
  iframe.contentWindow?.postMessage(
    {
      giscus: {
        setConfig: {
          theme: document.body.classList.contains("dark-theme") ? "dark" : "light",
        },
      },
    },
    "https://giscus.app"
  );
}

setupSharing();
