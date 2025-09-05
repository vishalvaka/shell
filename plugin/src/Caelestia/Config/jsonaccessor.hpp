#pragma once

#include <QJsonObject>
#include <QMetaProperty>
#include <QObject>

#define JSON_SUBOBJECT(type, name)                                                                                     \
    Q_PROPERTY(type* name READ name CONSTANT)                                                                          \
                                                                                                                       \
public:                                                                                                                \
    [[nodiscard]] type* name() const {                                                                                 \
        return m_##name;                                                                                               \
    }                                                                                                                  \
                                                                                                                       \
private:                                                                                                               \
    type* const m_##name;

#define JSON_PROPERTY(type, name, toType, default)                                                                     \
    Q_PROPERTY(type name READ name WRITE set_##name NOTIFY name##Changed)                                              \
                                                                                                                       \
public:                                                                                                                \
    [[nodiscard]] type name() const {                                                                                  \
        return raw().value(#name).toType(default);                                                                     \
    }                                                                                                                  \
                                                                                                                       \
    void set_##name(const type& _##name) {                                                                             \
        if (name() == _##name) {                                                                                       \
            return;                                                                                                    \
        }                                                                                                              \
                                                                                                                       \
        raw().insert(#name, QJsonValue::fromVariant(_##name));                                                         \
        emit name##Changed();                                                                                          \
    }                                                                                                                  \
                                                                                                                       \
    Q_SIGNAL void name##Changed();

#define JSON_PROPERTY_STRING(name, default) JSON_PROPERTY(QString, name, toString, default)
#define JSON_PROPERTY_BOOL(name, default) JSON_PROPERTY(bool, name, toBool, default)
#define JSON_PROPERTY_INT(name, default) JSON_PROPERTY(int, name, toInt, default)

namespace caelestia::config {

class JsonAccessor : public QObject {
    Q_OBJECT

public:
    explicit JsonAccessor(bool hidden = false, QObject* parent = nullptr)
        : QObject(parent)
        , m_hidden(hidden) {}

    [[nodiscard]] QJsonObject raw() const { return m_raw; }

protected:
    void setRaw(const QJsonObject& raw);

private:
    QJsonObject m_raw;
    bool m_hidden;

    QList<QPair<QMetaProperty, QVariant>> getProps();
    void updateSubObjects();
    [[nodiscard]] QJsonObject serialize() const;
};

} // namespace caelestia::config
