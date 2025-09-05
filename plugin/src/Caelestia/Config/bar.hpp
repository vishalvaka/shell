#pragma once

#include "jsonaccessor.hpp"
#include <QObject>

namespace caelestia::config::bar {

class Workspaces : public JsonAccessor {
    Q_OBJECT

    JSON_PROPERTY_INT(shown, 5)
    JSON_PROPERTY_BOOL(activeIndicator, true)
    JSON_PROPERTY_BOOL(occupiedBg, false)
    JSON_PROPERTY_BOOL(showWindows, true)
    JSON_PROPERTY_BOOL(showWindowsOnSpecialWorkspaces, showWindows())
    JSON_PROPERTY_BOOL(activeTrail, false)
    JSON_PROPERTY_BOOL(perMonitorWorkspaces, true)
    JSON_PROPERTY_STRING(label, "  ")
    JSON_PROPERTY_STRING(occupiedLabel, "󰮯")
    JSON_PROPERTY_STRING(activeLabel, "󰮯")
    JSON_PROPERTY_STRING(capitalisation, "preserve")

public:
    explicit Workspaces(QObject* parent = nullptr)
        : JsonAccessor(false, parent) {}
};

class Tray : public JsonAccessor {
    Q_OBJECT

    JSON_PROPERTY_BOOL(background, false)
    JSON_PROPERTY_BOOL(recolour, false)

public:
    explicit Tray(QObject* parent = nullptr)
        : JsonAccessor(false, parent) {}
};

class Bar : public JsonAccessor {
    Q_OBJECT

    JSON_PROPERTY_BOOL(persistent, true)
    JSON_PROPERTY_BOOL(showOnHover, true)
    JSON_PROPERTY_INT(dragThreshold, 20)

    JSON_SUBOBJECT(Workspaces, workspaces)
    JSON_SUBOBJECT(Tray, tray)

public:
    explicit Bar(QObject* parent = nullptr)
        : JsonAccessor(false, parent)
        , m_workspaces(new Workspaces(this))
        , m_tray(new Tray(this)) {}
};

} // namespace caelestia::config::bar
