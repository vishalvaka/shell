#pragma once

#include "bar.hpp"
#include "jsonaccessor.hpp"
#include <QFileSystemWatcher>
#include <QJSEngine>
#include <QObject>
#include <QQmlEngine>
#include <qqmlintegration.h>

namespace caelestia::config {

class Config : public JsonAccessor {
    Q_OBJECT
    QML_ELEMENT
    QML_SINGLETON

    JSON_SUBOBJECT(bar::Bar, bar)

public:
    static Config* instance();
    static Config* create(QQmlEngine*, QJSEngine*);

signals:
    void reloaded();

private slots:
    void handleDirChanged(const QString& path);
    void handleFileChanged(const QString& path);

private:
    explicit Config(QObject* parent = nullptr);

    const QString m_path;
    QFileSystemWatcher m_watcher;

    void tryWatchFile();
    void updateJson();
};

} // namespace caelestia::config