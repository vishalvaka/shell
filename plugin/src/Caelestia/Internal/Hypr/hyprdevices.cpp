#include "hyprdevices.hpp"

namespace caelestia::internal::hypr {

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

} // namespace caelestia::internal::hypr
