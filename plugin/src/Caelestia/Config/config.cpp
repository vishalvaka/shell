#include "config.hpp"

#include "bar.hpp"
#include "jsonaccessor.hpp"
#include <QDebug>
#include <QDir>
#include <QFile>
#include <QFileInfo>
#include <QFileSystemWatcher>
#include <QJSEngine>
#include <QJsonDocument>
#include <QJsonObject>
#include <QObject>
#include <QQmlEngine>

namespace caelestia::config {

Config* Config::instance() {
    static Config* instance = new Config();
    return instance;
}

Config* Config::create(QQmlEngine*, QJSEngine*) {
    return instance();
}

Config::Config(QObject* parent)
    : JsonAccessor(false, parent)
    , m_bar(new bar::Bar(this))
    , m_path(qEnvironmentVariable("XDG_CONFIG_HOME", QDir::homePath() + "/.config") + "/caelestia/shell.json") {
    connect(&m_watcher, &QFileSystemWatcher::directoryChanged, this, &Config::handleDirChanged);
    connect(&m_watcher, &QFileSystemWatcher::fileChanged, this, &Config::handleFileChanged);
    tryWatchFile();
}

void Config::handleDirChanged(const QString& path) {
    QDir dir(path);

    if (dir.exists()) {
        tryWatchFile();
    } else {
        dir.cdUp();
        m_watcher.addPath(dir.absolutePath());
    }
}

void Config::handleFileChanged(const QString& path) {
    if (path != m_path) {
        return;
    }

    QFileInfo fileInfo(path);
    if (fileInfo.exists()) {
        updateJson();
    } else {
        tryWatchFile();
    }
}

void Config::tryWatchFile() {
    QFileInfo fileInfo(m_path);

    if (fileInfo.exists()) {
        if (m_watcher.addPath(m_path)) {
            updateJson();
        }
    } else {
        setRaw(QJsonObject()); // Reset to default config
        emit reloaded();

        QDir dir(QFileInfo(m_path).absolutePath());
        while (!dir.exists()) {
            dir.cdUp();
        }
        m_watcher.addPath(dir.absolutePath());
    }
}

void Config::updateJson() {
    QFile file(m_path);
    if (!file.open(QIODevice::ReadOnly)) {
        qWarning() << "Config::updateJson: failed to open" << m_path << "| using default config";

        setRaw(QJsonObject());
        emit reloaded();

        return;
    }

    const QByteArray data = file.readAll();
    file.close();

    QJsonParseError error;
    const auto doc = QJsonDocument::fromJson(data, &error);

    if (error.error != QJsonParseError::NoError) {
        qWarning() << "Config::updateJson: failed to parse" << m_path << "| error:" << error.errorString();
        return;
    }

    setRaw(doc.object());
    emit reloaded();
}

} // namespace caelestia::config