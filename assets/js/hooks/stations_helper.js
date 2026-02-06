import L from "leaflet";
import { GeoSearchControl, OpenStreetMapProvider } from 'leaflet-geosearch';


delete L.Icon.Default.prototype._getIconUrl;

L.Icon.Default.mergeOptions({
    iconRetinaUrl: "/images/marker-icon-2x.png",
    iconUrl: "/images/marker-icon.png",
    shadowUrl: "/images/marker-shadow.png"
});

var greenLeafIcon = L.icon({
    iconUrl: 'https://leafletjs.com/examples/custom-icons/leaf-green.png',
    shadowUrl: 'https://leafletjs.com/examples/custom-icons/leaf-shadow.png',
    iconSize: [38, 95], // size of the icon
    shadowSize: [50, 64], // size of the shadow
    iconAnchor: [22, 94], // point of the icon which will correspond to marker's location
    shadowAnchor: [4, 62],  // the same for the shadow
    popupAnchor: [-3, -76] // point from which the popup should open relative to the iconAnchor
});

export const StationsMap = {
    mounted() {
        const map = L.map("map").setView([52.537300, 13.356085], 12);
        L.tileLayer(
            "https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png",
            {
                attribution: '&#169; <a href="//www.openstreetmap.org/">OpenStreetMap</a> contributors, CC BY-SA license. Data source <a href="https://citybik.es/">CityBikes</a>',
                maxZoom: 20,
            }).addTo(map);


        // Add geosearch control
        const provider = new OpenStreetMapProvider();

        const searchControl = new GeoSearchControl({
            provider: provider,
            searchLabel: 'Type address...',
        });

        map.addControl(searchControl);
        this.handleEvent("update-stations", (data_stations) => {
            // Remove existing markers
            map.eachLayer(layer => {
                if (layer instanceof L.Marker) {
                    map.removeLayer(layer);
                }
            });

            // Add new markers
            data_stations.stations.forEach(station => {
                var marker = null;
                var opacity = station.free_bikes > 0 ? 1.0 : 0.5;
                var text = `
                <b>Station name: ${station.name}</b><br/>
                Bikes Available: ${station.free_bikes}<br/>
                Empty Slots: ${station.empty_slots}
                `

                // Different icon if bikes are available
                if (station.free_bikes > 0) {
                    marker = L.marker([station.latitude, station.longitude], { icon: greenLeafIcon, opacity: opacity}).addTo(map)
                } else {
                    marker = L.marker([station.latitude, station.longitude], {opacity: opacity}).addTo(map)
                }

                marker.bindPopup(text);
            });
        });
    },
};
