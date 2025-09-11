#pragma once

#include <qfuturewatcher.h>
#include <qobject.h>
#include <qqmlintegration.h>
#include <qsortfilterproxymodel.h>
#include <rapidfuzz/fuzz.hpp>

namespace caelestia {

class InternalSearchModel : public QAbstractListModel {
    Q_OBJECT

public:
    explicit InternalSearchModel(QObject* parent = nullptr);

    int rowCount(const QModelIndex& parent = QModelIndex()) const override;
    QVariant data(const QModelIndex& index, int role = Qt::DisplayRole) const override;
    QHash<int, QByteArray> roleNames() const override;

    [[nodiscard]] QList<QObject*> values() const;
    [[nodiscard]] bool setValues(const QList<QObject*>& values);

private:
    QList<QObject*> m_values;
};

class SearchModel : public QSortFilterProxyModel {
    Q_OBJECT
    QML_ELEMENT

    Q_PROPERTY(QString query READ query WRITE setQuery NOTIFY queryChanged)
    Q_PROPERTY(QStringList keys READ keys WRITE setKeys NOTIFY keysChanged)
    Q_PROPERTY(QList<qreal> weights READ weights WRITE setWeights NOTIFY weightsChanged)
    Q_PROPERTY(bool concat READ concat WRITE setConcat NOTIFY concatChanged)
    Q_PROPERTY(qreal cutoff READ cutoff WRITE setCutoff NOTIFY cutoffChanged)
    Q_PROPERTY(bool caseSensitive READ caseSensitive WRITE setCaseSensitive NOTIFY caseSensitiveChanged)
    Q_PROPERTY(QList<QObject*> values READ values WRITE setValues NOTIFY valuesChanged)

public:
    explicit SearchModel(QObject* parent = nullptr);

    [[nodiscard]] QString query() const;
    void setQuery(const QString& query);

    [[nodiscard]] QStringList keys() const;
    void setKeys(const QStringList& keys);

    [[nodiscard]] QList<qreal> weights() const;
    void setWeights(const QList<qreal>& weights);

    [[nodiscard]] bool concat() const;
    void setConcat(bool concat);

    [[nodiscard]] qreal cutoff() const;
    void setCutoff(qreal cutoff);

    [[nodiscard]] bool caseSensitive() const;
    void setCaseSensitive(bool caseSensitive);

    [[nodiscard]] QList<QObject*> values() const;
    void setValues(const QList<QObject*>& values);

signals:
    void queryChanged();
    void keysChanged();
    void weightsChanged();
    void concatChanged();
    void valuesChanged();
    void cutoffChanged();
    void caseSensitiveChanged();

protected:
    bool filterAcceptsRow(int source_row, const QModelIndex& source_parent) const override;
    bool lessThan(const QModelIndex& left, const QModelIndex& right) const override;

private:
    using ScoreMap = QHash<QObject*, double>;
    using Scorer = rapidfuzz::fuzz::CachedTokenSortRatio<std::string::value_type>;

    QString m_query;
    QStringList m_keys;
    QList<qreal> m_weights;
    bool m_concat;
    qreal m_cutoff;
    bool m_caseSensitive;

    InternalSearchModel* m_model;
    Scorer m_scorer;
    QFutureWatcher<ScoreMap>* m_watcher;
    ScoreMap m_scores;

    void calculateScores();
};

} // namespace caelestia
