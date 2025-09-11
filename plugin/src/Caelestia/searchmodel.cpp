#include "searchmodel.hpp"

#include <qfuturewatcher.h>
#include <qpair.h>
#include <qpromise.h>
#include <qsortfilterproxymodel.h>
#include <qtconcurrentmap.h>
#include <qtconcurrentrun.h>
#include <rapidfuzz/fuzz.hpp>

namespace caelestia {

InternalSearchModel::InternalSearchModel(QObject* parent)
    : QAbstractListModel(parent) {}

int InternalSearchModel::rowCount(const QModelIndex& parent) const {
    if (parent != QModelIndex()) {
        return 0;
    }
    return static_cast<int>(m_values.size());
}

QVariant InternalSearchModel::data(const QModelIndex& index, int role) const {
    if (role != Qt::UserRole || !index.isValid() || index.row() >= m_values.size()) {
        return QVariant();
    }
    return QVariant::fromValue(m_values.at(index.row()));
}

QHash<int, QByteArray> InternalSearchModel::roleNames() const {
    return { { Qt::UserRole, "modelData" } };
}

QList<QObject*> InternalSearchModel::values() const {
    return m_values;
}

bool InternalSearchModel::setValues(const QList<QObject*>& values) {
    if (m_values == values) {
        return false;
    }

    m_values = values;
    return true;
}

SearchModel::SearchModel(QObject* parent)
    : QSortFilterProxyModel(parent)
    , m_concat(false)
    , m_cutoff(0.3)
    , m_caseSensitive(false)
    , m_model(new InternalSearchModel(this))
    , m_scorer("")
    , m_watcher(nullptr) {
    setDynamicSortFilter(true);
    setSourceModel(m_model);
    m_keys << "name";
    calculateScores();
}

QString SearchModel::query() const {
    return m_query;
}

void SearchModel::setQuery(const QString& query) {
    if (m_query == query) {
        return;
    }

    m_query = query;
    emit queryChanged();

    if (m_caseSensitive) {
        m_scorer = Scorer(query.toStdString());
    } else {
        m_scorer = Scorer(query.toLower().toStdString());
    }
    calculateScores();
}

QStringList SearchModel::keys() const {
    return m_keys;
}

void SearchModel::setKeys(const QStringList& keys) {
    if (m_keys == keys) {
        return;
    }

    m_keys = keys;
    emit keysChanged();

    calculateScores();
}

QList<qreal> SearchModel::weights() const {
    return m_weights;
}

void SearchModel::setWeights(const QList<qreal>& weights) {
    if (m_weights == weights) {
        return;
    }

    m_weights = weights;
    emit weightsChanged();

    calculateScores();
}

bool SearchModel::concat() const {
    return m_concat;
}

void SearchModel::setConcat(bool concat) {
    if (m_concat == concat) {
        return;
    }

    m_concat = concat;
    emit concatChanged();

    calculateScores();
}

qreal SearchModel::cutoff() const {
    return m_cutoff;
}

void SearchModel::setCutoff(qreal cutoff) {
    if (qFuzzyCompare(m_cutoff + 1.0, cutoff + 1.0)) {
        return;
    }

    m_cutoff = cutoff;
    emit cutoffChanged();

    calculateScores();
}

bool SearchModel::caseSensitive() const {
    return m_caseSensitive;
}

void SearchModel::setCaseSensitive(bool caseSensitive) {
    if (m_caseSensitive == caseSensitive) {
        return;
    }

    m_caseSensitive = caseSensitive;
    emit caseSensitiveChanged();

    if (m_caseSensitive) {
        m_scorer = Scorer(m_query.toStdString());
    } else {
        m_scorer = Scorer(m_query.toLower().toStdString());
    }
    calculateScores();
}

QList<QObject*> SearchModel::values() const {
    return m_model->values();
}

void SearchModel::setValues(const QList<QObject*>& values) {
    if (m_model->setValues(values)) {
        emit valuesChanged();
    }
}

bool SearchModel::lessThan(const QModelIndex& left, const QModelIndex& right) const {
    const auto a = left.data(Qt::UserRole).value<QObject*>();
    const auto b = right.data(Qt::UserRole).value<QObject*>();

    const auto aScore = m_scores.value(a, 0.0);
    const auto bScore = m_scores.value(b, 0.0);

    if (!qFuzzyCompare(aScore + 1.0, bScore + 1.0)) {
        return aScore < bScore;
    }

    for (const auto& key : m_keys) {
        const auto aStr = a->property(key.toUtf8()).toString();
        const auto bStr = b->property(key.toUtf8()).toString();
        const auto comp = aStr.localeAwareCompare(bStr);

        if (comp != 0) {
            return comp > 0;
        }
    }

    return left.row() < right.row();
}

bool SearchModel::filterAcceptsRow(int sourceRow, const QModelIndex& parent) const {
    if (m_query.isEmpty()) {
        return true;
    }

    const auto idx = sourceModel()->index(sourceRow, 0, parent);
    const auto obj = idx.data(Qt::UserRole).value<QObject*>();
    return m_scores.value(obj, 0.0) > m_cutoff;
}

void SearchModel::calculateScores() {
    if (m_watcher) {
        m_watcher->cancel();
        m_watcher->deleteLater();
        m_watcher = nullptr;
    }

    const auto keys = m_keys;
    const auto weights = m_weights;
    const auto concat = m_concat;
    const auto cutoff = m_cutoff * 100;
    const auto caseSensitive = m_caseSensitive;
    const auto scorer = m_scorer;

    const QFuture<ScoreMap> future = QtConcurrent::mappedReduced(
        m_model->values(),
        [=](QObject* value) {
            if (!keys.size()) {
                return qMakePair(value, 0.0);
            }

            if (concat) {
                QStringList valueList;

                for (const auto& key : keys) {
                    valueList << value->property(key.toUtf8()).toString();
                }

                auto concatted = valueList.join(" ");
                if (!caseSensitive) {
                    concatted = concatted.toLower();
                }
                const double score = scorer.similarity(concatted.toStdString(), cutoff) / 100;

                return qMakePair(value, score);
            } else {
                double score = 0.0;
                for (int i = 0; i < keys.size(); ++i) {
                    auto valueStr = value->property(keys[i].toUtf8()).toString();
                    if (!caseSensitive) {
                        valueStr = valueStr.toLower();
                    }

                    const double keyScore = scorer.similarity(valueStr.toStdString(), cutoff) / 100;
                    const auto weight = weights.value(i, 1.0);

                    score += keyScore * weight;
                }

                double totalWeight = 0.0;
                for (int i = 0; i < keys.size(); ++i) {
                    totalWeight += weights.value(i, 1.0);
                }

                score /= totalWeight;

                return qMakePair(value, score);
            }
        },
        [](ScoreMap& map, const QPair<QObject*, double>& pair) {
            if (pair.first != nullptr) {
                map.insert(pair.first, pair.second);
            }
            return map;
        });

    m_watcher = new QFutureWatcher<ScoreMap>(this);

    connect(m_watcher, &QFutureWatcher<ScoreMap>::finished, this, [this]() {
        if (m_watcher->future().isResultReadyAt(0)) {
            m_scores = m_watcher->result();
            sort(0, Qt::DescendingOrder);
            invalidate();
        }
        m_watcher->deleteLater();
        m_watcher = nullptr;
    });

    m_watcher->setFuture(future);
}

} // namespace caelestia
