import { Controller } from "@hotwired/stimulus"

// Generating an itinerary is a single synchronous request that regularly runs
// for a minute or two. Without feedback the page just sits there, so this
// controller puts a progress overlay in front of the user for the whole wait.
//
// There is no real progress to report from the server, so the bar eases towards
// a ceiling on a curve that never quite arrives, and only snaps to 100% when
// the response actually lands. The stage messages carry the honest information
// about what is happening.

// Ceiling the simulated progress creeps towards, and how fast it gets there.
// TIME_CONSTANT is in seconds: progress passes ~65% at one minute and ~87% at
// two, which tracks how long generation really takes.
const CEILING = 96
const TIME_CONSTANT = 52

// Seconds elapsed at which each message takes over.
const STAGES = [
  { at: 0, label: "Reading your trip details…" },
  { at: 5, label: "Researching %{destination}…" },
  { at: 16, label: "Shortlisting real places worth your time…" },
  { at: 32, label: "Building your day-by-day plan…" },
  { at: 52, label: "Balancing the days against your budget…" },
  { at: 74, label: "Checking travel times between stops…" },
  { at: 96, label: "Pinning every location on the map…" },
  { at: 120, label: "Almost there — adding the finishing touches…" }
]

export default class extends Controller {
  static targets = ["overlay", "bar", "percent", "elapsed", "status", "heading", "icon"]
  static values = { destination: String }

  connect() {
    this.startedAt = null
    this.frame = null
    this.stageIndex = -1

    // Turbo caches the page snapshot on navigation. Without this the overlay
    // would still be on screen when the user hits back.
    this.resetOnCache = () => this.reset()
    document.addEventListener("turbo:before-cache", this.resetOnCache)
  }

  disconnect() {
    document.removeEventListener("turbo:before-cache", this.resetOnCache)
    this.stopTicking()
  }

  // turbo:submit-start on either the generate or the regenerate form.
  start() {
    if (this.startedAt) return

    this.startedAt = performance.now()
    this.stageIndex = -1

    this.overlayTarget.classList.remove("is-closing", "is-done")
    this.overlayTarget.hidden = false

    this.setProgress(0)
    this.tick()
  }

  // turbo:submit-end — the response is in and Turbo is about to render it.
  // Finish the bar so the wait resolves instead of being cut off mid-creep.
  finish() {
    if (!this.startedAt) return

    this.stopTicking()

    this.overlayTarget.classList.add("is-done")
    this.iconTarget.textContent = "✓"
    this.headingTarget.textContent = "Your itinerary is ready"
    this.setStatus("Opening your travel plan…")
    this.setProgress(100)

    this.closeTimeout = setTimeout(() => {
      this.overlayTarget.classList.add("is-closing")
    }, 550)
  }

  reset() {
    this.stopTicking()
    clearTimeout(this.closeTimeout)

    this.startedAt = null
    this.overlayTarget.hidden = true
    this.overlayTarget.classList.remove("is-closing", "is-done")
    this.iconTarget.textContent = "🧭"
    this.headingTarget.textContent = "Building your itinerary"
    this.setProgress(0)
  }

  tick() {
    const seconds = (performance.now() - this.startedAt) / 1000

    this.setProgress(CEILING * (1 - Math.exp(-seconds / TIME_CONSTANT)))
    this.elapsedTarget.textContent = this.formatElapsed(seconds)
    this.updateStage(seconds)

    this.frame = requestAnimationFrame(() => this.tick())
  }

  stopTicking() {
    if (this.frame) cancelAnimationFrame(this.frame)
    this.frame = null
  }

  updateStage(seconds) {
    let index = 0
    STAGES.forEach((stage, i) => {
      if (seconds >= stage.at) index = i
    })

    if (index === this.stageIndex) return
    this.stageIndex = index

    const destination = this.destinationValue || "your destination"
    this.setStatus(STAGES[index].label.replace("%{destination}", destination))
  }

  // Crossfade rather than swapping the text outright, so the panel does not
  // flicker every time a stage rolls over.
  setStatus(text) {
    this.statusTarget.classList.add("is-fading")

    clearTimeout(this.statusTimeout)
    this.statusTimeout = setTimeout(() => {
      this.statusTarget.textContent = text
      this.statusTarget.classList.remove("is-fading")
    }, 220)
  }

  setProgress(value) {
    const rounded = Math.min(100, Math.round(value))

    this.barTarget.style.width = `${rounded}%`
    this.percentTarget.textContent = `${rounded}%`
    this.barTarget.parentElement.setAttribute("aria-valuenow", rounded)
  }

  formatElapsed(seconds) {
    const total = Math.floor(seconds)
    const minutes = Math.floor(total / 60)

    return `${minutes}:${String(total % 60).padStart(2, "0")} elapsed`
  }
}
