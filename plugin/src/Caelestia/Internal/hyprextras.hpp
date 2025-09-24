#pragma once

#include "hyprdevices.hpp"
#include <qlocalsocket.h>
#include <qobject.h>
#include <qqmlintegration.h>

namespace caelestia::internal::hypr {

class HyprExtras : public QObject {
    Q_OBJECT
    QML_ELEMENT

    Q_PROPERTY(QVariantHash options READ options NOTIFY optionsChanged)
    Q_PROPERTY(HyprDevices* devices READ devices CONSTANT)

public:
    explicit HyprExtras(QObject* parent = nullptr);

    [[nodiscard]] QVariantHash options() const;
    [[nodiscard]] HyprDevices* devices() const;

    Q_INVOKABLE void refreshOptions();
    Q_INVOKABLE void refreshDevices();

signals:
    void optionsChanged();

private:
    QString m_requestSocket;
    QString m_eventSocket;
    QLocalSocket* m_socket;

    QVariantHash m_options;
    HyprDevices* const m_devices;

    bool refreshingOptions;
    bool refreshingDevices;

    void readEvent();
    void handleEvent(const QString& event);

    void makeRequestJson(const QString& request, const std::function<void(QJsonDocument)> callback);
    void makeRequest(const QString& request, const std::function<void(QByteArray)> callback);
};

} // namespace caelestia::internal::hypr
