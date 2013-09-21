/*
 * WPUtils.h
 *
 *      Author: Daniele (b0unc3) Maio
 */

#ifndef WPUTILS_H_
#define WPUTILS_H_

#include <QObject>
#include <QMetaType>
#include <QMap>

#include <qnetworkaccessmanager.h>
#include <qnetworkreply.h>
#include <qnetworkrequest.h>

#include <QUrl>
/* TO BE ROMEVED, USE QXml* */
#include <QDomDocument>
#include <QDomElement>
#include <QDomText>

#include <QtXml/QXmlStreamReader>
#include <QXmlStreamWriter>

#include <QByteArray>
#include <QVariant>

#include <QStringList>

#include <QRegExp>

#include <QXmlStreamReader>

#include <Qt/qimagereader.h>

#include <QDebug>

#include <QMetaType>
#include <QtScript>

#include <QtSql/QtSql>

#include <bb/cascades/GroupDataModel>
#include <bb/data/SqlDataAccess.hpp>

using namespace bb::data;
using namespace bb::cascades;			//?


class WPUtils: public QObject {
	Q_OBJECT

public:
	QVariantMap res;
	bb::cascades::GroupDataModel *model;


	WPUtils(QObject *parent = 0);
	virtual ~WPUtils();

	Q_INVOKABLE void getBlogs(QString, QString, QString);
	Q_INVOKABLE void getPosts(bool);
	Q_INVOKABLE void setBlogsInfo(QString,QString);
	Q_INVOKABLE void getComments();
	Q_INVOKABLE void getPages();
	Q_INVOKABLE void getPost(QString);
	Q_INVOKABLE void getCategories();
	Q_INVOKABLE void makePost(bool, QString, QVariant, QVariant, QVariant);
	Q_INVOKABLE void deletePost(QString);
	Q_INVOKABLE void uploadFile(QString);
	Q_INVOKABLE void editComment(QString, QString, QString, QString, QString, QString);
	Q_INVOKABLE void deleteComment(QString);
	Q_INVOKABLE void newComment(QString, QString, QString);
	Q_INVOKABLE void getComment(QString);
	Q_INVOKABLE void editPost(QString, QString, QString, QString, QString);

	Q_INVOKABLE bb::cascades::GroupDataModel *setModel(QByteArray); /* should be getModel, since the model is setted in another func */
	QString searchEndPoint(QString);

	/* maybe temporary */
	Q_INVOKABLE QMap<QString, QVariant> getRes() { return res; }
	Q_INVOKABLE void resetRes() { res.clear(); }
	Q_INVOKABLE void setUsername(QString u) { qDebug() << "&&&&&& ==== USERNAME SETTED TO => " << u; _username = u; }
	Q_INVOKABLE void setPassword(QString p) { _password = p; }

	Q_INVOKABLE void setPosition(int p) { _position = p; }
	Q_INVOKABLE bool blogsInfo();
	Q_INVOKABLE void getBlogsInfo();
	Q_INVOKABLE bool info_registered();
	Q_INVOKABLE QMap<QString, QVariant> getBI();

private:
	int _position;
	bool _info_registered;
	static const QString dbName;
	QMap<QString, QVariant> _blogs;
	//QHash<QString, QString> _blogs;
	QString _endpoint;
	QString _url;
	QEventLoop _loop;
	QByteArray _xml;
	QString _username;
	QString _password;
	QString _blogid;
	QString _emit;
	QSqlDatabase _db;


	int getPosition();
	QString sanitize(QString);
	bool validate(QString);
	void getRegisteredData();

	signals:
	void dataReady(QByteArray); //QVariant);//QString);

	void dataReady_getUsersBlogs();
	void dataReady_getBlogs(QByteArray);

	void dataReady_getPosts();
	void dataReady_getPost();
	void dataReady_viewPost();
	void dataReady_editPost();
	void dataReady_delPost();
	void dataReady_newPost();

	void dataReady_getComments();
	void dataReady_getComment();
	void dataReady_newComment();
	void dataReady_viewComment();
	void dataReady_editComment();
	void dataReady_delComment();

	void dataReady_getPages();
	void dataReady_viewPage();
	void dataReady_editPage();
	void dataReady_delPage();
	void dataReady_newPage();

	void blogsReady(QHash<QString, QString>);

private slots:
void replyFinished(QNetworkReply*);
void repFinished(QNetworkReply*);
void checkForPingback(QNetworkReply*);

};

#endif /* WPUTILS_H_ */
