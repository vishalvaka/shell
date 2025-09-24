#include "hyprextras.hpp"

#include <qdir.h>
#include <qjsonarray.h>
#include <qlocalsocket.h>

namespace caelestia::internal {

HyprKeyboard::HyprKeyboard(QJsonObject ipcObject, QObject* parent)
    : QObject(parent)
    , m_lastIpcObject(ipcObject) {}

QVariantMap HyprKeyboard::lastIpcObject() const {
    return m_lastIpcObject.toVariantMap();
}

QString HyprKeyboard::address() const {
    return m_lastIpcObject.value("address").toString();
}

QString HyprKeyboard::name() const {
    return m_lastIpcObject.value("name").toString();
}

QString HyprKeyboard::layout() const {
    return m_lastIpcObject.value("layout").toString();
}

QString HyprKeyboard::activeKeymap() const {
    return m_lastIpcObject.value("active_keymap").toString();
}

bool HyprKeyboard::capsLock() const {
    return m_lastIpcObject.value("capsLock").toBool();
}

bool HyprKeyboard::numLock() const {
    return m_lastIpcObject.value("numLock").toBool();
}

bool HyprKeyboard::main() const {
    return m_lastIpcObject.value("main").toBool();
}

bool HyprKeyboard::updateLastIpcObject(const QJsonObject& object) {
    if (m_lastIpcObject == object) {
        return false;
    }

    const auto last = m_lastIpcObject;

    m_lastIpcObject = object;
    emit lastIpcObjectChanged();

    bool dirty = false;
    if (last.value("address") != object.value("address")) {
        dirty = true;
        emit addressChanged();
    }
    if (last.value("name") != object.value("name")) {
        dirty = true;
        emit nameChanged();
    }
    if (last.value("layout") != object.value("layout")) {
        dirty = true;
        emit layoutChanged();
    }
    if (last.value("active_keymap") != object.value("active_keymap")) {
        dirty = true;
        emit activeKeymapChanged();
    }
    if (last.value("capsLock") != object.value("capsLock")) {
        dirty = true;
        emit capsLockChanged();
    }
    if (last.value("numLock") != object.value("numLock")) {
        dirty = true;
        emit numLockChanged();
    }
    if (last.value("main") != object.value("main")) {
        dirty = true;
        emit mainChanged();
    }
    return dirty;
}

HyprExtras::HyprExtras(QObject* parent)
    : QObject(parent)
    , m_requestSocket("")
    , m_borderSize(0)
    , m_windowRounding(0)
    , m_animsEnabled(true) {
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
}

int HyprExtras::borderSize() {
    makeRequestJson("getoption general:border_size", [this](const QJsonObject& response) {
        const auto val = response.value("int").toInt();
        if (m_borderSize != val) {
            m_borderSize = val;
            emit borderSizeChanged();
        }
    });

    return m_borderSize;
}

int HyprExtras::windowRounding() {
    makeRequestJson("getoption decoration:rounding", [this](const QJsonObject& response) {
        const auto val = response.value("int").toInt();
        if (m_windowRounding != val) {
            m_windowRounding = val;
            emit windowRoundingChanged();
        }
    });

    return m_windowRounding;
}

bool HyprExtras::animsEnabled() {
    makeRequestJson("getoption animations:enabled", [this](const QJsonObject& response) {
        const auto val = response.value("int").toBool();
        if (m_animsEnabled != val) {
            m_animsEnabled = val;
            emit animsEnabledChanged();
        }
    });

    return m_animsEnabled;
}

QList<HyprKeyboard*> HyprExtras::keyboards() {
    reloadKeyboards();
    return m_keyboards;
}

void HyprExtras::reloadKeyboards() {
    makeRequestJson("devices", [this](const QJsonObject& response) {
        const auto val = response.value("keyboards").toArray();
        bool dirty = false;

        for (const auto& keyboard : std::as_const(m_keyboards)) {
            if (std::find_if(val.begin(), val.end(), [keyboard](const QJsonValue& object) {
                    return object.toObject().value("address").toString() == keyboard->address();
                }) == val.end()) {
                dirty = true;
                m_keyboards.removeAll(keyboard);
                keyboard->deleteLater();
            }
        }

        for (const auto& object : val) {
            const auto obj = object.toObject();
            const auto addr = obj.value("address").toString();

            auto it = std::find_if(m_keyboards.begin(), m_keyboards.end(), [addr](const HyprKeyboard* keyboard) {
                return keyboard->address() == addr;
            });

            if (it != m_keyboards.end()) {
                dirty |= (*it)->updateLastIpcObject(obj);
            } else {
                dirty = true;
                m_keyboards << new HyprKeyboard(obj, this);
            }
        }

        if (dirty) {
            emit keyboardsChanged();
        }
    });
}

void HyprExtras::makeRequestJson(const QString& request, const std::function<void(QJsonObject)> callback) {
    makeRequest("j/" + request, [callback](const QByteArray& response) {
        callback(QJsonDocument::fromJson(response).object());
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

} // namespace caelestia::internal
