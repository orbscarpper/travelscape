import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = {
    apiKey: String,
    markers: Array
  }

  connect() {
    mapboxgl.accessToken = this.apiKeyValue

    const markers = this.markersValue

    if (markers.length === 0) {
      return
    }

    const firstMarker = markers[0]

    const map = new mapboxgl.Map({
      container: this.element,
      style: "mapbox://styles/mapbox/streets-v12",
      center: [firstMarker.longitude, firstMarker.latitude],
      zoom: 12
    })

    markers.forEach((marker) => {
      new mapboxgl.Marker()
        .setLngLat([marker.longitude, marker.latitude])
        .setPopup(
          new mapboxgl.Popup().setHTML(
            `<strong>${marker.location}</strong>`
          )
        )
        .addTo(map)
    })
  }
}
