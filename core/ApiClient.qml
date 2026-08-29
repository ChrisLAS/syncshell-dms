import QtQuick
import "../models/SyncthingApi.js" as Api

QtObject {
    id: root
    property string baseUrl: "http://127.0.0.1:8384"
    property string apiKey: ""

    function request(name, options, onSuccess, onError) {
        return Api.request(baseUrl, apiKey, name, options || {}, onSuccess, onError)
    }
}
