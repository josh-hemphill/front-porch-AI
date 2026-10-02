# Rawhide — What's New (Nightlies)

These notes feed the in-app "Update Available" dialog for Rawhide / cutting-edge builds.
**Only list what landed after the last shipped nightly.** Clear this section when a new nightly goes out — delete the old bullets; do not accumulate them.

Last shipped nightly: `rawhide.20261001.06827b2`. Everything below is unreleased.

## Recent improvements (unreleased — ships in the next build)

- ✏️ **Editing a message works on the phone again** — Save, Cancel and the text box answer taps, and on a notched iPhone the buttons sit below the clock. If a save fails, the editor stays open with your text and says why.
- 📱 **Phone taps that fail now say so** — regenerate, continue, swipe, fork, delete, switching chats, group settings and the rest show a plain reason instead of doing nothing.
- 📱 **A screen that breaks on the phone shows a way out** — Reload or Back to library, instead of a blank page.
- 📖 **Reading a story on the phone no longer overwrites it** — turning a page saves only your place, not an older copy of the story.
- 📱 **Leaving a chat mid-reply keeps that reply out of the next chat.**
- 📱 **With a chat theme picture, the Regenerate and version-picker windows cover the message box** like they do without one.
- ⚡ **Long chats on the phone stay smooth while a reply streams in.**
- ⌨️ **Japanese, Chinese and Korean keyboards no longer send mid-word** when Enter picks a character.
- 🖼️ **A photo the phone can't read is no longer dropped quietly** — your text and photo stay put with a note.

- 🤖 **xAI is a chat backend** — pick xAI in Settings → Backend (or Model Settings) and sign in with SuperGrok to use your subscription allowance instead of paid API credits. The sign-in is unofficial and at your own risk; an xAI API key also works. The sign-in borrows xAI's own Grok CLI login, so xAI may block it at any time. If your allowance runs out, chat says so in plain words. Same on the phone.

- 🧑 **A brand-new chat starts as your default persona** — left-clicking a character you've never opened now begins the chat with your default "Speak as", instead of carrying over the persona from the chat you were just in. Chats you've already opened keep their own persona. Same on the phone.
- 🖼️ **Saved ComfyUI edit workflows get the real prompt** — a chained or multi-step prompt now flows into your saved Edit workflow instead of being dropped, and Qwen image-edit keeps the denoise strength you set instead of snapping back to a default. Same on the phone.
- 🖼️ **Image before/after comparisons wait until both sides are done** — Image Studio no longer posts a half-finished ComfyUI comparison; an incomplete compare is skipped instead of shown broken.
