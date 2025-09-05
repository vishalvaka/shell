#include "jsonaccessor.hpp"

#include <QJsonObject>
#include <QJsonValue>
#include <QMetaProperty>
#include <QObject>
#include <QVariant>

namespace caelestia::config {

void JsonAccessor::setRaw(const QJsonObject& raw) {
    if (m_raw == raw) {
        return;
    }

    const auto oldProps = getProps();
    m_raw = raw;

    for (const auto& propPair : oldProps) {
        const auto prop = propPair.first;
        const auto oldValue = propPair.second;

        if (prop.read(this) != oldValue) {
            prop.notifySignal().invoke(this, Qt::DirectConnection);
        }
    }

    updateSubObjects();
}

QList<QPair<QMetaProperty, QVariant>> JsonAccessor::getProps() {
    QList<QPair<QMetaProperty, QVariant>> props;
    const QMetaObject* meta = metaObject();
    const QMetaObject* base = &JsonAccessor::staticMetaObject;

    for (int i = base->propertyOffset(); i < meta->propertyCount(); ++i) {
        const QMetaProperty prop = meta->property(i);

        if (prop.isReadable() && prop.hasNotifySignal()) {
            props << qMakePair(prop, prop.read(this));
        }
    }

    return props;
}

void JsonAccessor::updateSubObjects() {
    const QMetaObject* meta = metaObject();
    const QMetaObject* base = &JsonAccessor::staticMetaObject;

    for (int i = base->propertyOffset(); i < meta->propertyCount(); ++i) {
        const QMetaProperty prop = meta->property(i);

        if (prop.isReadable() && m_raw.contains(prop.name()) && m_raw.value(prop.name()).isObject()) {
            QVariant value = prop.read(this);

            if (value.canView<JsonAccessor*>()) {
                auto* accessor = value.view<JsonAccessor*>();
                accessor->setRaw(m_raw.value(prop.name()).toObject());
            }
        }
    }
};

QJsonObject JsonAccessor::serialize() const {
    QJsonObject result;
    const QMetaObject* meta = metaObject();
    const QMetaObject* base = &JsonAccessor::staticMetaObject;

    for (int i = base->propertyOffset(); i < meta->propertyCount(); ++i) {
        const QMetaProperty prop = meta->property(i);

        if (prop.isReadable()) {
            QVariant value = prop.read(this);

            if (value.canView<JsonAccessor*>()) {
                auto* accessor = value.view<JsonAccessor*>();
                if (!accessor->m_hidden) {
                    result.insert(prop.name(), accessor->serialize());
                }
            } else {
                result.insert(prop.name(), QJsonValue::fromVariant(value));
            }
        }
    }

    return result;
};

} // namespace caelestia::config
