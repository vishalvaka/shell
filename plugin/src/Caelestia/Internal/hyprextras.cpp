#include "hyprextras.hpp"

#include <qdir.h>
#include <qjsonarray.h>
#include <qlocalsocket.h>
#include <qvariant.h>

namespace caelestia::internal::hypr {

HyprExtras::HyprExtras(QObject* parent)
    : QObject(parent)
    , m_requestSocket("")
    , m_eventSocket("")
    , m_socket(nullptr)
    , m_devices(new HyprDevices(this)) {
    const auto his = qEnvironmentVariable("HYPRLAND_INSTANCE_SIGNATURE");
    if (his.isEmpty()) {
        qWarning()
            << "HyprExtras::HyprExtras: $HYPRLAND_INSTANCE_SIGNATURE is unset. Unable to connect to Hyprland socket.";
        return;
    }

    auto hyprDir = QString("%1/hypr/%2").arg(qEnvironmentVariable("XDG_RUNTIME_DIR"), his);
    if (!QDir(hyprDir).exists()) {
        hyprDir = "/tmp/hypr/" + his;

        if (!QDir(hyprDir).exists()) {
            qWarning() << "HyprExtras::HyprExtras: Hyprland socket directory does not exist. Unable to connect to "
                          "Hyprland socket.";
            return;
        }
    }

    m_requestSocket = hyprDir + "/.socket.sock";
    m_eventSocket = hyprDir + "/.event.sock";

    refreshOptions();
    refreshDevices();

    m_socket = new QLocalSocket(this);
    QObject::connect(m_socket, &QLocalSocket::readyRead, this, &HyprExtras::readEvent);
    m_socket->connectToServer(m_eventSocket);
}

QVariantHash HyprExtras::options() const {
    return m_options;
}

HyprDevices* HyprExtras::devices() const {
    return m_devices;
}

void HyprExtras::refreshOptions() {
    makeRequestJson("descriptions", [this](const QJsonDocument& response) {
        const auto options = response.array();
        bool dirty = false;

        for (const auto& o : std::as_const(options)) {
            const auto obj = o.toObject();
            const auto key = obj.value("value").toString();
            const auto value = obj.value("data").toObject().value("value").toVariant();
            if (m_options.value(key) != value) {
                dirty = true;
                m_options.insert(key, value);
            }
        }

        if (dirty) {
            emit optionsChanged();
        }
    });
}

void HyprExtras::refreshDevices() {
    makeRequestJson("devices", [this](const QJsonDocument& response) {
        m_devices->updateLastIpcObject(response.object());
    });
}

void HyprExtras::readEvent() {
    while (true) {
        auto rawEvent = m_socket->readLine();
        if (rawEvent.isEmpty()) {
            break;
        }
        rawEvent.truncate(rawEvent.length() - 1); // Remove trailing \n
        const auto event = QByteArrayView(rawEvent.data(), rawEvent.indexOf(">>"));
        handleEvent(QString::fromUtf8(event));
    }
}

void HyprExtras::handleEvent(const QString& event) {
    if (event == "configreloaded") {
        refreshOptions();
    } else if (event == "activelayout") {
        refreshDevices();
    }
}

void HyprExtras::makeRequestJson(const QString& request, const std::function<void(QJsonDocument)> callback) {
    makeRequest("j/" + request, [callback](const QByteArray& response) {
        callback(QJsonDocument::fromJson(response));
    });
}

void HyprExtras::makeRequest(const QString& request, const std::function<void(QByteArray)> callback) {
    if (m_requestSocket.isEmpty()) {
        return;
    }

    auto* socket = new QLocalSocket(this);

    QObject::connect(socket, &QLocalSocket::connected, this, [=, this]() {
        QObject::connect(socket, &QLocalSocket::readyRead, this, [socket, callback]() {
            const auto response = socket->readAll();
            callback(std::move(response));
            socket->deleteLater();
        });

        socket->write(request.toUtf8());
        socket->flush();
    });

    QObject::connect(socket, &QLocalSocket::errorOccurred, this, [socket, request](QLocalSocket::LocalSocketError err) {
        qWarning() << "HyprExtras::makeRequest: error making request: " << err << "request: " << request;
        socket->deleteLater();
    });

    socket->connectToServer(m_requestSocket);
}

} // namespace caelestia::internal::hypr
