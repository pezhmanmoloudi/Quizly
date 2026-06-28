import { Application } from "@hotwired/stimulus"

export async function nextTick() {
  await Promise.resolve()
  await Promise.resolve()
}

export async function startController(ControllerClass, html, identifier = "test") {
  document.body.innerHTML = html
  const app = Application.start()
  app.register(identifier, ControllerClass)
  await nextTick()
  const element = document.querySelector(`[data-controller="${identifier}"]`)
  return { app, element }
}
