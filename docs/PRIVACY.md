# Privacy Notes

Diary Focus should be designed as a privacy-first personal diary app.

## Prototype

The current web preview stores data in browser local storage:

- Diary text.
- Mood selections.
- Todos.
- Focus session totals.
- Uploaded preview images.
- Selected pet and background.

No server upload is implemented in the prototype.

## Native iOS Direction

For the MVP, data should remain local to the device unless backup/sync is explicitly added.

Potential permission prompts:

- Photo Library: for selecting diary images and focus backgrounds.
- Notifications: for focus reminders or diary reminders.
- Face ID / passcode: for app lock if implemented.

## App Store Privacy

Before App Store submission, document:

- What data is collected.
- Whether data is linked to the user.
- Whether data is used for tracking.
- Whether third-party SDKs collect data.

If the app stays fully local and uses no analytics, the privacy label can be much simpler.
