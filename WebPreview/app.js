const moods = [
  { id: "downCloud", title: "Down", shape: "cloud", face: "down", color: "#b9bbb8" },
  { id: "happyEgg", title: "Bright", shape: "egg", face: "closed", color: "#fadd59" },
  { id: "calmCloud", title: "Calm", shape: "cloud", face: "calm", color: "#93d0ac" },
  { id: "smilingHeart", title: "Loved", shape: "heart", face: "smile", color: "#ffa9a9" },
  { id: "bearSoft", title: "Soft", shape: "bear", face: "smile", color: "#d9b894" },
  { id: "dogTired", title: "Tired", shape: "dog", face: "sleepy", color: "#f0cba8" },
  { id: "appleFresh", title: "Fresh", shape: "apple", face: "smile", color: "#ff9c8c" },
  { id: "starProud", title: "Proud", shape: "star", face: "closed", color: "#fadd59" },
  { id: "flowerGood", title: "Good", shape: "flower", face: "smile", color: "#d8b7ee" },
  { id: "quietEgg", title: "Quiet", shape: "egg", face: "calm", color: "#9dc2ee" }
];

const STORAGE_KEY = "diary-focus-preview-state";

const state = {
  route: "home",
  selectedDate: new Date(),
  activeMomentTime: null,
  moodsByDate: {},
  entries: {},
  reviews: {
    books: []
  },
  selectedReview: {
    book: null
  },
  selectedPet: "dog",
  selectedRoom: "1",
  customFocusRoomBackground: "",
  focusInterval: null,
  focusRemaining: 25 * 60,
  focusSessionSeconds: 25 * 60,
  focusRunning: false
};

const calendarGrid = document.querySelector("#calendar-grid");
const yearLabel = document.querySelector("#year-label");
const monthLabel = document.querySelector("#month-label");
const menuButton = document.querySelector("#menu-button");
const menu = document.querySelector("#menu");
const diaryDialog = document.querySelector("#diary-dialog");
const settingsDialog = document.querySelector("#settings-dialog");
const diaryDate = document.querySelector("#diary-date");
const moodOptions = document.querySelector("#mood-options");
const diaryEditor = document.querySelector("#diary-editor");
const photoInput = document.querySelector("#diary-photo-input");
const photoUploadButton = document.querySelector("#photo-upload-button");
const photoFrame = document.querySelector("#photo-frame");
const photoUploadLabel = document.querySelector("#photo-upload-label");
const focusMinutes = document.querySelector("#focus-minutes");
const focusMinutesLabel = document.querySelector("#focus-minutes-label");
const focusTime = document.querySelector("#focus-time");
const startFocus = document.querySelector("#start-focus");
const landscapeFocus = document.querySelector("#landscape-focus");
const focusBgInput = document.querySelector("#focus-bg-input");
const focusBg = document.querySelector("#focus-bg");
const focusPet = document.querySelector("#focus-pet");
const focusRoom = document.querySelector(".focus-room");
const roomPicker = document.querySelector(".room-picker");
const petPicker = document.querySelector(".pet-picker");
const focusSummary = document.querySelector("#focus-summary");
const todoInputRow = document.querySelector("#todo-input-row");
const todoText = document.querySelector("#todo-text");
const todoList = document.querySelector("#todo-list");
const bookResults = document.querySelector("#book-results");
const movieResults = document.querySelector("#movie-results");
const bookSelected = document.querySelector("#book-selected");
const movieSelected = document.querySelector("#movie-selected");
const bookReviewText = document.querySelector("#book-review-text");
const bookReviewEditor = document.querySelector("#book-review-editor");
const bookLibrary = document.querySelector("#book-library");

loadState();
state.reviews ||= { books: [] };
state.reviews.books ||= [];
state.selectedReview ||= { book: null };
seedMoods();
renderCalendar();
renderMoodOptions();
renderPet();
renderRoom();
renderBookLibrary();
bindEvents();

function bindEvents() {
  menuButton.addEventListener("click", () => {
    const open = menu.classList.toggle("open");
    menuButton.setAttribute("aria-expanded", String(open));
  });

  menu.addEventListener("click", (event) => {
    const button = event.target.closest("button[data-route]");
    if (!button) return;
    setRoute(button.dataset.route);
    menu.classList.remove("open");
    menuButton.setAttribute("aria-expanded", "false");
  });

  document.querySelector("#settings-button").addEventListener("click", () => settingsDialog.showModal());
  document.querySelector("#add-entry").addEventListener("click", () => openDiary(new Date()));
  document.querySelector("#mark-time").addEventListener("click", insertTimestampLine);

  diaryDialog.addEventListener("close", saveDiaryHtml);
  diaryEditor.addEventListener("input", saveDiaryHtml);
  diaryEditor.addEventListener("keydown", handleDiaryKeydown);

  photoUploadButton.addEventListener("click", () => photoInput.click());
  photoInput.addEventListener("change", saveDiaryPhotos);

  document.querySelector("#add-todo-button").addEventListener("click", () => {
    todoInputRow.classList.toggle("open");
    if (todoInputRow.classList.contains("open")) todoText.focus();
  });
  document.querySelector("#save-todo").addEventListener("click", saveTodo);
  todoText.addEventListener("keydown", (event) => {
    if (event.key === "Enter") {
      event.preventDefault();
      saveTodo();
    }
  });

  focusMinutes.addEventListener("input", () => {
    const minutes = Number(focusMinutes.value);
    focusMinutesLabel.textContent = `${minutes}m`;
    if (!state.focusRunning) {
      state.focusRemaining = minutes * 60;
      renderFocusTime();
    }
  });

  startFocus.addEventListener("click", toggleFocus);
  landscapeFocus.addEventListener("click", toggleLandscapeFocus);
  document.querySelector("#focus-bg-button").addEventListener("click", () => focusBgInput.click());
  focusBgInput.addEventListener("change", setFocusBackground);
  document.querySelector("#save-book-review").addEventListener("click", saveBookReview);
  roomPicker.addEventListener("click", (event) => {
    const button = event.target.closest(".room-choice");
    if (!button) return;
    state.selectedRoom = button.dataset.room;
    saveState();
    renderRoom();
  });
  document.querySelectorAll(".search-row").forEach((form) => {
    form.addEventListener("submit", handleReviewSearch);
  });
  petPicker.addEventListener("click", (event) => {
    const button = event.target.closest(".pet-choice");
    if (!button) return;
    state.selectedPet = button.dataset.pet;
    saveState();
    renderPet();
  });
}

function setRoute(route) {
  state.route = route;
  document.querySelectorAll(".view").forEach((view) => {
    view.classList.toggle("active", view.dataset.view === route);
  });
}

function seedMoods() {
  if (Object.keys(state.moodsByDate).length > 0) return;

  const today = new Date();
  [-3, -2, -1, 0].forEach((offset, index) => {
    const date = new Date(today);
    date.setDate(today.getDate() + offset);
    state.moodsByDate[dayKey(date)] = moods[index].id;
  });
  saveState();
}

function renderCalendar() {
  const today = new Date();
  const year = today.getFullYear();
  const month = today.getMonth();
  const first = new Date(year, month, 1);
  const daysInMonth = new Date(year, month + 1, 0).getDate();

  yearLabel.textContent = String(year);
  monthLabel.textContent = today.toLocaleString("en", { month: "long" }).toUpperCase();
  calendarGrid.innerHTML = "";

  for (let i = 0; i < first.getDay(); i += 1) {
    calendarGrid.append(document.createElement("span"));
  }

  for (let day = 1; day <= daysInMonth; day += 1) {
    const date = new Date(year, month, day);
    const key = dayKey(date);
    const button = document.createElement("button");
    button.className = "day";
    if (date.getDay() === 0) button.classList.add("sunday");
    if (date.getDay() === 6) button.classList.add("saturday");
    if (stripTime(date) > stripTime(today)) button.classList.add("future");

    const mood = moods.find((item) => item.id === state.moodsByDate[key]);
    if (mood && stripTime(date) <= stripTime(today)) {
      button.append(renderMood(mood));
    } else {
      button.textContent = String(day);
    }

    button.addEventListener("click", () => openDiary(date));
    calendarGrid.append(button);
  }
}

function renderMoodOptions() {
  moodOptions.innerHTML = "";
  moods.forEach((mood) => {
    const button = document.createElement("button");
    button.className = "mood-choice";
    button.type = "button";
    button.dataset.mood = mood.id;
    button.classList.toggle("selected", mood.id === state.moodsByDate[dayKey(state.selectedDate)]);
    button.append(renderMood(mood));
    const title = document.createElement("span");
    title.textContent = mood.title;
    button.append(title);
    button.addEventListener("click", () => {
      state.moodsByDate[dayKey(state.selectedDate)] = mood.id;
      renderMoodOptions();
      renderCalendar();
      saveState();
    });
    moodOptions.append(button);
  });
}

function renderMood(mood) {
  const wrapper = document.createElement("span");
  wrapper.className = `mood ${mood.shape}`;
  wrapper.style.setProperty("--mood-color", mood.color);

  const face = document.createElement("span");
  face.className = `face ${mood.face}`;
  const mouth = document.createElement("span");
  face.append(mouth);
  wrapper.append(face);
  return wrapper;
}

function openDiary(date) {
  state.selectedDate = date;
  const key = dayKey(date);
  const entry = getEntry(key);

  diaryDate.textContent = date.toLocaleDateString("en", { month: "short", day: "numeric" });
  diaryEditor.innerHTML = entry.html || legacyDiaryHtml(entry);
  normalizeTimestampSpans();
  state.activeMomentTime = null;
  photoInput.value = "";
  todoText.value = "";
  todoInputRow.classList.remove("open");

  [...moodOptions.children].forEach((button) => {
    button.classList.toggle("selected", button.dataset.mood === state.moodsByDate[key]);
  });
  renderDiaryPhotos();
  renderFocusSummary();
  renderTodos();
  diaryDialog.showModal();
}

function saveDiaryHtml() {
  const key = dayKey(state.selectedDate);
  const entry = getEntry(key);
  normalizeTimestampSpans();
  const cleanEditor = cleanedDiaryClone();
  entry.html = cleanEditor.innerHTML;
  entry.text = cleanEditor.innerText;
  state.entries[key] = entry;
  saveState();
}

function cleanedDiaryClone() {
  const clone = diaryEditor.cloneNode(true);
  clone.querySelectorAll("[data-timestamp-text='true']").forEach((span) => {
    if (span.textContent.length > 1) {
      span.textContent = span.textContent.replaceAll("\u200b", "");
    }
  });
  return clone;
}

function normalizeTimestampSpans() {
  diaryEditor.querySelectorAll(".timestamp-line span").forEach((span) => {
    span.removeAttribute("contenteditable");
    span.dataset.timestampText = "true";
  });
}

function renderDiaryPhotos() {
  const key = dayKey(state.selectedDate);
  const entry = getEntry(key);
  dedupeEntryPhotos(entry);
  photoFrame.innerHTML = "";
  photoFrame.classList.toggle("has-photos", entry.photos.length > 0);
  photoUploadLabel.textContent = entry.photos.length > 0 ? `Add pictures (${entry.photos.length})` : "Add pictures";
  entry.photos.forEach((photo, index) => {
    const image = document.createElement("img");
    image.src = photo.dataUrl;
    image.alt = photo.name || `Diary picture ${index + 1}`;
    photoFrame.append(image);
  });
  photoFrame.scrollLeft = 0;
}

async function saveDiaryPhotos() {
  const files = [...photoInput.files];
  if (files.length === 0) return;

  photoUploadLabel.textContent = "Adding...";
  try {
    const key = dayKey(state.selectedDate);
    const entry = getEntry(key);
    await compactEntryPhotos(entry);
    const photos = await Promise.all(files.map(fileToStoredPhoto));
    entry.photos.push(...photos);
    dedupeEntryPhotos(entry);
    state.entries[key] = entry;
    await compactAllEntryPhotos();
    saveState();
    renderDiaryPhotos();
  } catch {
    photoUploadLabel.textContent = "Storage full";
  } finally {
    photoInput.value = "";
  }
}

function dedupeEntryPhotos(entry) {
  const seen = new Set();
  entry.photos = entry.photos.filter((photo) => {
    const fingerprint = photoFingerprint(photo);
    if (seen.has(fingerprint)) return false;
    seen.add(fingerprint);
    return true;
  });
}

function insertTimestampLine() {
  const timestamp = formatTime(new Date());
  const line = document.createElement("div");
  line.className = "timestamp-line";

  const time = document.createElement("time");
  time.textContent = timestamp;

  const text = document.createElement("span");
  text.dataset.timestampText = "true";
  text.append(document.createTextNode("\u200b"));

  line.append(time, text);
  appendNodeInDiary(line);
  saveDiaryHtml();
  placeCaretAtEnd(text);
}

function handleDiaryKeydown(event) {
  if (event.key === "Enter") {
    const timestampText = getActiveTimestampText();
    if (!timestampText) return;

    event.preventDefault();
    insertNormalLineAfter(timestampText.closest(".timestamp-line"));
    saveDiaryHtml();
    return;
  }

  if (event.key === "Backspace") normalizeTimestampSpans();
}

function getActiveTimestampText() {
  const selection = window.getSelection();
  if (!selection || selection.rangeCount === 0) return null;

  let node = selection.anchorNode;
  if (!node) return null;
  if (node.nodeType === Node.TEXT_NODE) node = node.parentElement;
  if (!(node instanceof Element)) return null;

  const timestampText = node.closest("[data-timestamp-text='true']");
  if (!timestampText || !diaryEditor.contains(timestampText)) return null;
  return timestampText;
}

function insertNormalLineAfter(node) {
  const paragraph = document.createElement("p");
  paragraph.className = "normal-line";
  paragraph.append(document.createElement("br"));
  node.after(paragraph);
  placeCaretAtEnd(paragraph);
}

function insertNormalLineBefore(node) {
  const paragraph = document.createElement("p");
  paragraph.className = "normal-line";
  paragraph.append(document.createElement("br"));
  node.before(paragraph);
  placeCaretAtEnd(paragraph);
}

function saveTodo() {
  const text = todoText.value.trim();
  if (!text) return;

  const key = dayKey(state.selectedDate);
  const entry = getEntry(key);
  entry.todos.push({ id: `todo-${Date.now()}-${Math.random().toString(16).slice(2)}`, text, done: false });
  state.entries[key] = entry;
  todoText.value = "";
  todoInputRow.classList.remove("open");
  saveState();
  renderTodos();
}

function renderFocusSummary() {
  const key = dayKey(state.selectedDate);
  const seconds = getEntry(key).focusSeconds || 0;
  focusSummary.classList.toggle("visible", seconds > 0);
  focusSummary.innerHTML = seconds > 0
    ? `<strong>Focus completed</strong><span>${formatDuration(seconds)}</span>`
    : "";
}

function renderTodos() {
  const key = dayKey(state.selectedDate);
  const todos = getEntry(key).todos;
  todoList.innerHTML = "";

  todos.forEach((todo) => {
    const row = document.createElement("label");
    row.className = "todo-item";
    row.classList.toggle("done", todo.done);

    const checkbox = document.createElement("input");
    checkbox.type = "checkbox";
    checkbox.checked = todo.done;
    checkbox.addEventListener("change", () => {
      todo.done = checkbox.checked;
      saveState();
      renderTodos();
    });

    const text = document.createElement("span");
    text.textContent = todo.text;
    row.append(checkbox, text);
    todoList.append(row);
  });
}

async function handleReviewSearch(event) {
  event.preventDefault();
  const kind = event.currentTarget.dataset.search;
  const input = document.querySelector(`#${kind}-search`);
  const results = kind === "book" ? bookResults : movieResults;
  const query = input.value.trim();
  if (!query) return;

  results.innerHTML = `<span class="search-status">Searching...</span>`;

  try {
    const items = kind === "book" ? await searchBooks(query) : await searchMovies(query);
    renderReviewResults(kind, items);
  } catch {
    results.innerHTML = `<span class="search-status">Search failed. Check your internet connection.</span>`;
  }
}

async function searchBooks(query) {
  const response = await fetch(`https://openlibrary.org/search.json?title=${encodeURIComponent(query)}&limit=8`);
  const data = await response.json();
  return (data.docs || []).map((book) => ({
    title: book.title,
    subtitle: [book.author_name?.[0], book.first_publish_year].filter(Boolean).join(" - "),
    image: book.cover_i ? `https://covers.openlibrary.org/b/id/${book.cover_i}-M.jpg` : "",
    fallback: "Book"
  }));
}

async function searchMovies(query) {
  const response = await fetch(`https://itunes.apple.com/search?media=movie&limit=8&term=${encodeURIComponent(query)}`);
  const data = await response.json();
  return (data.results || []).map((movie) => ({
    title: movie.trackName,
    subtitle: [movie.primaryGenreName, movie.releaseDate?.slice(0, 4)].filter(Boolean).join(" - "),
    image: movie.artworkUrl100?.replace("100x100bb", "600x900bb") || "",
    fallback: "Movie"
  }));
}

function renderReviewResults(kind, items) {
  const results = kind === "book" ? bookResults : movieResults;
  const selected = kind === "book" ? bookSelected : movieSelected;
  results.innerHTML = "";

  if (items.length === 0) {
    results.innerHTML = `<span class="search-status">No results found.</span>`;
    return;
  }

  items.forEach((item) => {
    const card = document.createElement("button");
    card.className = "result-card";
    card.type = "button";

    const image = document.createElement("img");
    image.alt = item.title;
    if (item.image) image.src = item.image;

    const title = document.createElement("strong");
    title.textContent = item.title || item.fallback;

    const subtitle = document.createElement("span");
    subtitle.textContent = item.subtitle || item.fallback;

    card.append(image, title, subtitle);
    card.addEventListener("click", () => selectReviewItem(kind, selected, item));
    results.append(card);
  });
}

function selectReviewItem(kind, container, item) {
  state.selectedReview[kind] = item;
  container.innerHTML = "";
  container.classList.add("visible");
  if (kind === "book") {
    bookReviewEditor.classList.add("visible");
  }

  const image = document.createElement("img");
  image.alt = item.title;
  if (item.image) image.src = item.image;

  const copy = document.createElement("div");
  const title = document.createElement("strong");
  title.textContent = item.title || item.fallback;
  const subtitle = document.createElement("span");
  subtitle.textContent = item.subtitle || item.fallback;
  copy.append(title, subtitle);
  container.append(image, copy);
}

function saveBookReview() {
  const reviewText = bookReviewText.value.trim();
  const selected = state.selectedReview.book;
  if (!selected && !reviewText) return;

  const review = {
    id: `book-review-${Date.now()}-${Math.random().toString(16).slice(2)}`,
    title: selected?.title || "Untitled book",
    subtitle: selected?.subtitle || "",
    image: selected?.image || "",
    text: reviewText,
    savedAt: new Date().toISOString()
  };

  state.reviews.books.unshift(review);
  state.selectedReview.book = null;
  bookReviewText.value = "";
  document.querySelector("#book-search").value = "";
  bookResults.innerHTML = "";
  bookSelected.innerHTML = "";
  bookSelected.classList.remove("visible");
  bookReviewEditor.classList.remove("visible");
  saveState();
  renderBookLibrary();
}

function renderBookLibrary() {
  bookLibrary.innerHTML = "";
  state.reviews.books.forEach((review) => {
    const card = document.createElement("article");
    card.className = "library-card";

    const image = document.createElement("img");
    image.alt = review.title;
    if (review.image) image.src = review.image;

    const copy = document.createElement("div");
    const title = document.createElement("strong");
    title.textContent = review.title;
    const subtitle = document.createElement("span");
    subtitle.textContent = review.subtitle || "Saved review";
    const excerpt = document.createElement("span");
    excerpt.textContent = review.text ? review.text.slice(0, 84) : "No notes yet";
    copy.append(title, subtitle, excerpt);
    card.append(image, copy);
    bookLibrary.append(card);
  });
}

function toggleFocus() {
  if (state.focusRunning) {
    stopFocus();
    return;
  }

  state.focusRunning = true;
  state.focusSessionSeconds = Number(focusMinutes.value) * 60;
  state.focusRemaining = state.focusSessionSeconds;
  startFocus.textContent = "Pause";
  landscapeFocus.hidden = false;
  state.focusInterval = window.setInterval(() => {
    state.focusRemaining -= 1;
    renderFocusTime();
    if (state.focusRemaining <= 0) completeFocusSession();
  }, 1000);
}

function stopFocus() {
  state.focusRunning = false;
  window.clearInterval(state.focusInterval);
  state.focusInterval = null;
  startFocus.textContent = "Start";
  landscapeFocus.hidden = true;
  document.querySelector("[data-view='focus']").classList.remove("landscape-mode");
}

function toggleLandscapeFocus() {
  document.querySelector("[data-view='focus']").classList.toggle("landscape-mode");
}

function completeFocusSession() {
  const completedSeconds = state.focusSessionSeconds;
  stopFocus();

  const key = dayKey(new Date());
  const entry = getEntry(key);
  entry.focusSeconds = (entry.focusSeconds || 0) + completedSeconds;
  state.entries[key] = entry;
  saveState();
}

function renderFocusTime() {
  const minutes = Math.max(0, Math.floor(state.focusRemaining / 60));
  const seconds = Math.max(0, state.focusRemaining % 60);
  focusTime.textContent = `${String(minutes).padStart(2, "0")}:${String(seconds).padStart(2, "0")}`;
}

function setFocusBackground() {
  const file = focusBgInput.files[0];
  if (!file) return;
  const reader = new FileReader();
  reader.addEventListener("load", async () => {
    state.customFocusRoomBackground = await compressImageDataUrl(reader.result);
    state.selectedRoom = "custom";
    saveState();
    renderRoom();
    focusBgInput.value = "";
  });
  reader.readAsDataURL(file);
}

function renderPet() {
  focusPet.className = `companion ${state.selectedPet}-companion`;
  focusPet.innerHTML = petSvg(state.selectedPet);

  document.querySelectorAll(".pet-choice").forEach((button) => {
    button.classList.toggle("selected", button.dataset.pet === state.selectedPet);
  });
}

function renderRoom() {
  if (state.selectedRoom === "custom" && state.customFocusRoomBackground) {
    focusRoom.dataset.room = "custom";
    focusRoom.style.backgroundImage = `url("${state.customFocusRoomBackground}")`;
    document.querySelectorAll(".room-choice").forEach((button) => {
      button.classList.remove("selected");
    });
    return;
  }

  const room = ["1", "2", "3", "4"].includes(state.selectedRoom) ? state.selectedRoom : "1";
  state.selectedRoom = room;
  focusRoom.dataset.room = room;
  focusRoom.style.backgroundImage = `url("assets/backgrounds/focus-bg-${room}.jpg")`;
  document.querySelectorAll(".room-choice").forEach((button) => {
    button.classList.toggle("selected", button.dataset.room === room);
  });
}

function petSvg(kind) {
  const pet = focusPetCharacter(kind);
  return `
    <svg class="pet-svg" viewBox="0 0 150 128" aria-hidden="true">
      ${pet.back || ""}
      <ellipse class="pet-shadow" cx="76" cy="112" rx="42" ry="8"/>
      ${pet.body}
      <g class="pet-legs">${pet.legs || ""}</g>
      ${pet.head}
      ${pet.features || ""}
      <circle class="pet-eye" cx="${pet.eyeLeft?.[0] || 61}" cy="${pet.eyeLeft?.[1] || 64}" r="3.4"/>
      <circle class="pet-eye" cx="${pet.eyeRight?.[0] || 89}" cy="${pet.eyeRight?.[1] || 64}" r="3.4"/>
      <path class="pet-face-line" d="${pet.mouth || "M70 74 Q75 78 80 74"}"/>
      <circle class="pet-cheek" cx="${pet.cheekLeft?.[0] || 52}" cy="${pet.cheekLeft?.[1] || 75}" r="5"/>
      <circle class="pet-cheek" cx="${pet.cheekRight?.[0] || 98}" cy="${pet.cheekRight?.[1] || 75}" r="5"/>
      ${pet.extra || ""}
    </svg>`;
}

function focusPetCharacter(kind) {
  const pets = {
    cat: {
      body: `<path class="pet-line" fill="#ffd0a6" d="M47 78 C47 58 60 49 75 50 C91 49 104 58 104 78 C104 102 91 112 75 112 C59 112 47 102 47 78 Z"/>`,
      head: `<path class="pet-line" fill="#ffd0a6" d="M45 48 L54 25 L68 42 C73 40 79 40 84 42 L98 25 L106 48 C111 62 102 79 75 79 C48 79 39 62 45 48 Z"/>`,
      back: `<path class="pet-line pet-tail" d="M106 86 C128 83 127 57 113 60"/>`,
      legs: `<path class="pet-line pet-leg left-leg" d="M63 101 V114"/><path class="pet-line pet-leg right-leg" d="M88 101 V114"/>`,
      features: `<path class="pet-face-line" d="M75 64 L72 67 L78 67 M51 67 H36 M52 73 H38 M98 67 H114 M97 73 H112 M62 101 V113 M88 101 V113"/>`,
      eyeLeft: [61, 58],
      eyeRight: [89, 58],
      cheekLeft: [53, 68],
      cheekRight: [97, 68],
      mouth: "M70 68 Q75 72 80 68"
    },
    sheep: {
      body: `<path class="pet-line" fill="#fffefa" d="M47 82 C47 59 60 49 76 51 C93 49 106 59 106 82 C106 105 92 114 76 112 C60 114 47 105 47 82 Z"/>`,
      head: `<path class="pet-line" fill="#fffefa" d="M48 51 C42 37 58 32 64 42 C70 25 91 27 94 43 C108 38 114 54 102 64 C100 78 51 79 48 51 Z"/>`,
      legs: `<path class="pet-line pet-leg left-leg" d="M63 101 V114"/><path class="pet-line pet-leg right-leg" d="M89 101 V114"/>`,
      features: `<path class="pet-line" d="M45 53 C30 55 31 76 48 75 M105 53 C120 55 119 76 102 75 M58 42 C52 29 66 26 69 39 M91 39 C94 26 108 29 102 42"/>`,
      eyeLeft: [62, 61],
      eyeRight: [88, 61],
      cheekLeft: [55, 71],
      cheekRight: [95, 71],
      mouth: "M70 70 Q75 73 80 70"
    },
    dog: {
      body: `<path class="pet-line" fill="#e3c49d" d="M46 79 C46 58 59 49 75 50 C91 49 104 58 104 79 C104 103 91 113 75 112 C59 113 46 103 46 79 Z"/>`,
      head: `<path class="pet-line" fill="#e3c49d" d="M45 48 C45 33 58 27 75 29 C92 27 105 33 105 48 C110 66 99 82 75 82 C51 82 40 66 45 48 Z"/>`,
      legs: `<path class="pet-line pet-leg left-leg" d="M62 101 V114"/><path class="pet-line pet-leg right-leg" d="M88 101 V114"/>`,
      features: `<path class="pet-line" fill="#c99a75" d="M48 43 C30 45 29 70 45 73 C58 66 58 49 48 43 Z M102 43 C120 45 121 70 105 73 C92 66 92 49 102 43 Z"/><path class="pet-line pet-tail" d="M106 88 C126 85 119 67 108 72"/><path class="pet-face-line" d="M75 66 L71 70 L79 70"/>`,
      eyeLeft: [61, 60],
      eyeRight: [89, 60],
      cheekLeft: [53, 72],
      cheekRight: [97, 72],
      mouth: "M70 72 Q75 76 80 72"
    },
    pig: {
      body: `<path class="pet-line" fill="#f6b3bd" d="M45 80 C45 58 58 48 75 49 C92 48 105 58 105 80 C105 104 91 114 75 112 C59 114 45 104 45 80 Z"/>`,
      head: `<path class="pet-line" fill="#f6b3bd" d="M44 51 C44 35 58 28 75 30 C92 28 106 35 106 51 C111 69 99 84 75 84 C51 84 39 69 44 51 Z"/>`,
      legs: `<path class="pet-line pet-leg left-leg" d="M62 101 V114"/><path class="pet-line pet-leg right-leg" d="M88 101 V114"/>`,
      features: `<path class="pet-line" d="M51 46 L40 34 M99 46 L110 34"/><ellipse class="pet-line" fill="#ffd0d8" cx="75" cy="69" rx="14" ry="9"/><path class="pet-face-line" d="M71 69 H71.1 M79 69 H79.1"/>`,
      eyeLeft: [61, 59],
      eyeRight: [89, 59],
      cheekLeft: [52, 73],
      cheekRight: [98, 73],
      mouth: "M70 78 Q75 81 80 78"
    }
  };

  return pets[kind] || pets.dog;
}

function getEntry(key) {
  if (!state.entries[key]) {
    state.entries[key] = { text: "", html: "", moments: [], photos: [], todos: [] };
  }

  const entry = state.entries[key];
  entry.html ||= "";
  entry.text ||= "";
  entry.moments ||= [];
  entry.photos ||= [];
  entry.todos ||= [];
  entry.focusSeconds ||= 0;
  return entry;
}

function appendNodeInDiary(node) {
  diaryEditor.focus();
  diaryEditor.append(node);
}

function placeCaretAtEnd(element) {
  const range = document.createRange();
  range.selectNodeContents(element);
  range.collapse(false);

  const selection = window.getSelection();
  selection.removeAllRanges();
  selection.addRange(range);
}

function textToHtml(text) {
  if (!text) return "";
  return text
    .split("\n")
    .map((line) => `<p>${escapeHtml(line)}</p>`)
    .join("");
}

function legacyDiaryHtml(entry) {
  const parts = [textToHtml(entry.text)];
  if (entry.moments?.length) {
    entry.moments.forEach((moment) => {
      parts.push(
        `<div class="timestamp-line"><time>${formatTime(new Date(moment.time))}</time><span data-timestamp-text="true">${escapeHtml(moment.text)}</span></div>`
      );
    });
  }
  return parts.join("");
}

function escapeHtml(value) {
  return value
    .replaceAll("&", "&amp;")
    .replaceAll("<", "&lt;")
    .replaceAll(">", "&gt;")
    .replaceAll('"', "&quot;")
    .replaceAll("'", "&#039;");
}

function fileToStoredPhoto(file) {
  return new Promise((resolve, reject) => {
    const reader = new FileReader();
    reader.addEventListener("load", () => {
      compressImageDataUrl(reader.result)
        .then((dataUrl) => {
          resolve({
            name: file.name,
            size: file.size,
            type: file.type,
            lastModified: file.lastModified,
            dataUrl
          });
        })
        .catch(reject);
    });
    reader.addEventListener("error", reject);
    reader.readAsDataURL(file);
  });
}

function compressImageDataUrl(dataUrl) {
  return new Promise((resolve, reject) => {
    const image = new Image();
    image.addEventListener("load", () => {
      const maxSide = 1100;
      const scale = Math.min(1, maxSide / Math.max(image.width, image.height));
      const width = Math.max(1, Math.round(image.width * scale));
      const height = Math.max(1, Math.round(image.height * scale));
      const canvas = document.createElement("canvas");
      canvas.width = width;
      canvas.height = height;
      const context = canvas.getContext("2d");
      context.drawImage(image, 0, 0, width, height);
      resolve(canvas.toDataURL("image/jpeg", 0.78));
    });
    image.addEventListener("error", reject);
    image.src = dataUrl;
  });
}

async function compactEntryPhotos(entry) {
  entry.photos = await Promise.all(
    entry.photos.map(async (photo) => {
      if (!photo.dataUrl || photo.dataUrl.length < 450000) return photo;
      return {
        ...photo,
        dataUrl: await compressImageDataUrl(photo.dataUrl)
      };
    })
  );
}

async function compactAllEntryPhotos() {
  for (const entry of Object.values(state.entries)) {
    if (entry?.photos?.length) {
      await compactEntryPhotos(entry);
      dedupeEntryPhotos(entry);
    }
  }
}

function photoFingerprint(photo) {
  if (photo.name && photo.size) return `${photo.name}:${photo.size}`;
  return photo.dataUrl;
}

function saveState() {
  const saved = {
    moodsByDate: state.moodsByDate,
    entries: state.entries,
    reviews: state.reviews,
    selectedPet: state.selectedPet,
    selectedRoom: state.selectedRoom,
    customFocusRoomBackground: state.customFocusRoomBackground
  };
  try {
    localStorage.setItem(STORAGE_KEY, JSON.stringify(saved));
  } catch {
    throw new Error("Preview storage is full. Try deleting some diary pictures.");
  }
}

function loadState() {
  const raw = localStorage.getItem(STORAGE_KEY);
  if (!raw) return;

  try {
    const saved = JSON.parse(raw);
    state.moodsByDate = saved.moodsByDate || {};
    state.entries = saved.entries || {};
    state.reviews = saved.reviews || { books: [] };
    state.reviews.books ||= [];
    state.selectedPet = normalizePet(saved.selectedPet);
    state.selectedRoom = saved.selectedRoom || "1";
    state.customFocusRoomBackground = saved.customFocusRoomBackground || "";
  } catch {
    state.moodsByDate = {};
    state.entries = {};
    state.reviews = { books: [] };
    state.selectedRoom = "1";
    state.customFocusRoomBackground = "";
  }
}

function normalizePet(pet) {
  const allowed = ["dog", "cat", "sheep", "pig"];
  const migrated = {
    frog: "dog",
    rat: "dog",
    ox: "dog",
    tiger: "cat",
    rabbit: "cat",
    dragon: "dog",
    snake: "cat",
    horse: "dog",
    goat: "sheep",
    monkey: "cat",
    rooster: "sheep"
  };
  return allowed.includes(pet) ? pet : migrated[pet] || "dog";
}

function dayKey(date) {
  const year = date.getFullYear();
  const month = String(date.getMonth() + 1).padStart(2, "0");
  const day = String(date.getDate()).padStart(2, "0");
  return `${year}-${month}-${day}`;
}

function stripTime(date) {
  return new Date(date.getFullYear(), date.getMonth(), date.getDate()).getTime();
}

function formatTime(date) {
  return date.toLocaleTimeString("en", { hour: "numeric", minute: "2-digit" }).toLowerCase();
}

function formatDuration(totalSeconds) {
  const hours = Math.floor(totalSeconds / 3600);
  const minutes = Math.round((totalSeconds % 3600) / 60);
  if (hours > 0 && minutes > 0) return `${hours} hr ${minutes} min`;
  if (hours > 0) return `${hours} hr`;
  return `${minutes} min`;
}
