/*
 * WPUtils.cpp
 *
 *      Author: Daniele (b0unc3) Maio
 */

#include "WPUtils.h"

#include <QSettings>

/* crypt/decrypt stuff */
#include <huaes.h>
#include <sbreturn.h>
#include <hurandom.h>
#include <string.h>

#include "AESParams.hpp"
#include "AESKey.hpp"
#include "DRBG.hpp"
#include "SBError.hpp"
/*********************/


const QString WPUtils::dbName = "wpbb10.db";

WPUtils::WPUtils(QObject *parent)
{
	init();
}

WPUtils::~WPUtils() {
	// TODO Auto-generated destructor stub
	_db.close();
}

void WPUtils::init()
{
	QDir home = QDir::home();
	QFile file(home.absoluteFilePath(dbName));
	if (!file.exists() && file.open(QIODevice::ReadWrite) )
	{
		SqlDataAccess sda(home.absoluteFilePath(dbName));
		sda.execute("CREATE TABLE userinfo(blogid TEXT, id INTEGER PRIMARY KEY, username TEXT, password BLOB, xmlrpc BLOB);");
	}
	/*
	 * load crypt/decrypt stuff
	 */
	QSettings settings;
	if (!settings.contains("key")) {
		settings.setValue("key",generate());
	}
	if (!settings.contains("iv")) {
		settings.setValue("iv",generate());
	}
	_key = settings.value("key").toString();
	_iv = settings.value("iv").toString();
	/*****/

	_position = 0; // <<== WTF?
	_info_registered = true;
	_db = QSqlDatabase::addDatabase("QSQLITE");
	_db.setDatabaseName(home.absoluteFilePath(dbName));
	if (!_db.open())
	{
		qDebug() << "db not opened!";
		_info_registered = false;
		/* FIXIT */
	}
	if (!info_registered())
		_info_registered = false;
	else {
		getRegisteredData();
	}
}
/*
 * crypt/decrypt stuff
 * from : https://github.com/blackberry/Cascades-Community-Samples/tree/master/AESCryptoDemo
 *
 */

QString WPUtils::generate() {
	DRBG drbg(globalContext);
	QByteArray buffer(16, 0);
	int rc = drbg.getBytes(buffer);
	if (rc != SB_SUCCESS) {
		qDebug() << QString("Could not generate random bytes %1").arg(SBError::getErrorText(rc));
		return "";
	}
	return toHex(buffer);
}

void WPUtils::pad(QByteArray & in) {
	int padLength = 16 - (in.length() % 16);
	for (int i = 0; i < padLength; ++i) {
		in.append((char) padLength);
	}
}

QString WPUtils::encrypt(QString s) {
	QByteArray in(s.toUtf8());// plainText().toUtf8());
	pad(in);
	QByteArray out(in.length(), 0);

	if (crypt(true, in, out)) {
		//setCipherText(toHex(out));
		//return true;
		return toHex(out);
	}
	return "";//false;
}

bool WPUtils::crypt(bool isEncrypt, const QByteArray & in,
		QByteArray & out) {
	QByteArray key, iv;
	QString fail;

	if (!fromHex(_key, key)) {
		fail += "Key is not valid hex. ";
	}
	if (!fromHex(_iv, iv)) {
		fail += "IV is not valid hex. ";
	}

	if (!fail.isEmpty()) {
		qDebug() << "fail = " << fail;
		//toast(fail);
		return false;
	}

	AESParams params(globalContext);
	if (!params.isValid()) {
		//toast(
		qDebug () << "fails = " << QString("Could not create params. %1").arg(SBError::getErrorText(params.lastError()));
		return false;
	}

	AESKey aesKey(params, key);
	if (!aesKey.isValid()) {
		qDebug() << "failes = " <<  QString("Could not create a key. %1").arg(SBError::getErrorText(aesKey.lastError()));
		return false;
	}

	int rc;
	if (isEncrypt) {
		rc = hu_AESEncryptMsg(params.aesParams(), aesKey.aesKey(), iv.length(),
				(const unsigned char*) iv.constData(), in.length(),
				(const unsigned char *) in.constData(),
				(unsigned char *) out.data(), globalContext.ctx());
	} else {
		rc = hu_AESDecryptMsg(params.aesParams(), aesKey.aesKey(), iv.length(),
				(const unsigned char*) iv.constData(), in.length(),
				(const unsigned char *) in.constData(),
				(unsigned char *) out.data(), globalContext.ctx());
	}
	if (rc == SB_SUCCESS) {
		return true;
	}

	//toast
	qDebug() << QString("Crypto operation failed. %1").arg(SBError::getErrorText(rc));
	return false;

}

QString WPUtils::decrypt(QString d) {
	QByteArray in;
	if (!fromHex(d, in)) {
		//toast
		qDebug() << "Cipher text is not valid hex";
		return false;
	}
	QByteArray out(in.length(), 0);

	if (crypt(false, in, out)) {
		if (removePadding(out)) {
			QString toUse(QString::fromUtf8(out.constData(), out.length()));
			return toUse;
			//return true;
		}
	}
	return "";//false;
}

char WPUtils::nibble(char c) {
	if (c >= '0' && c <= '9') {
		return c - '0';
	} else if (c >= 'a' && c <= 'f') {
		return c - 'a' + 10;
	} else if (c >= 'A' && c <= 'F') {
		return c - 'A' + 10;
	}
	return -1;
}

QString WPUtils::toHex(const QByteArray & in) {
	static char hexChars[] = "0123456789abcdef";

	const char * c = in.constData();
	QString toReturn;
	for (int i = 0; i < in.length(); ++i) {
		toReturn += hexChars[(c[i] >> 4) & 0xf];
		toReturn += hexChars[(c[i]) & 0xf];
	}

	return toReturn;
}

bool WPUtils::fromHex(const QString in, QByteArray & toReturn) {
	QString temp(in);
	temp.replace(" ","");
	temp.replace(":","");
	temp.replace(".","");
	QByteArray content(temp.toLocal8Bit());

	const char * c(content.constData());

	if (content.length() == 0 || ((content.length() % 2) != 0)) {
		return false;
	}

	for (int i = 0; i < content.length(); i += 2) {
		char a = c[i];
		char b = c[i + 1];
		a = nibble(a);
		b = nibble(b);
		if (a < 0 || b < 0) {
			toReturn.clear();
			return false;
		}
		toReturn.append((a << 4) | b);
	}
	return true;
}

bool WPUtils::removePadding(QByteArray & out) {
	char paddingLength = out[out.length() - 1];
	if (paddingLength < 1 || paddingLength > 16) {
		//toast
		qDebug() << "Invalid padding length. Were the keys good?";
		out.clear();
		return false;
	}
	if (paddingLength > out.length()) {
		//toast
		qDebug() << "Padding is claiming to be longer than the buffer!";
		out.clear();
		return false;
	}
	for (int i = 1; i < paddingLength; ++i) {
		char next = out[out.length() - 1 - i];
		if (next != paddingLength) {
			qDebug()  << "Not all padding bytes are correct!";
			out.clear();
			return false;
		}
	}
	out.remove(out.length() - paddingLength, paddingLength);
	return true;
}

/*************************************************************/

void WPUtils::getRegisteredData()
{
	QSqlQuery q(_db);
	q.exec("SELECT * FROM userinfo");
	/*
	 * table structure:
	 * id,username,password,blogid,xmlrp
	 *
	 * blogid - xmlrpc  <= multiple item separated by comma
	 * TODO = create another table and link with foreign key
	 */
	//*for sure* there is only - 1 - record
	q.next();
	_username = q.value(2).toString();
	_password = decrypt(q.value(3).toString()); //<--- decrypt
	QString bi = q.value(0).toString();
	QString xr = q.value(4).toString();

	QStringList bis = bi.split(",");
	QStringList xrs = xr.split(",");
	_blogid = bis.at(0);
	_endpoint = xrs.at(0);

	int i=0;
	for ( i=0; i<bis.size(); i++)
	{
		_blogs.insertMulti(bis.at(i).trimmed(), xrs.at(i).trimmed());

		_blogid = bis.at(i).trimmed(); //_blogs.values("blogid")[_position];
		_endpoint = xrs.at(i).trimmed();//_blogs.values("burl")[_position];
		qDebug() << "adding item in pos = " << QString::number(i);
		qDebug()  << "going to add  =  " << bis.at(i) << xrs.at(i);
		//void WPUtils::setBlogsInfo(QString bid, QString burl)
	}

	QSettings settings;

	if (!settings.value("blogid").isNull()) {
		_blogid = settings.value("blogid").toString();
		_endpoint = settings.value("endpoint").toString();
	}

}

bool WPUtils::info_registered()
{
	QDir home = QDir::home();
	QFile file(home.absoluteFilePath(dbName));
	SqlDataAccess sda(home.absoluteFilePath(dbName));//QDir::currentPath() + "/data/wpbb10.db");
	QVariant list = sda.execute("SELECT * FROM userinfo");
	return (list.toList().size() > 0);
}

bool WPUtils::deleteData()
{
	QDir home = QDir::home();
	bool ret = QFile::remove(home.absoluteFilePath(dbName));
	_db.close();
	init();

	return ret;


}

int WPUtils::getPosition()
{
	return _position;
}

void WPUtils::setCurrentBlog(QString b, QString u)
{
	if ( !b.isEmpty() && !u.isEmpty() )
	{
		_blogid = b.trimmed();
		_endpoint =u.trimmed();
		QSettings settings;
		settings.setValue("blogid", _blogid);
		settings.setValue("endpoint", _endpoint);
	}
}

QString WPUtils::getCurrentBlog()
{
	return _blogid + "-" + _endpoint;
}

QMap<QString, QVariant> WPUtils::getBI()
{
	return _blogs;
}

void WPUtils::getBlogsInfo()
{

	// uhm

}

bool WPUtils::blogsInfo()
{
	return _blogs.isEmpty();
}

bool WPUtils::deleteBlog(QString bid, QString burl)
{
	//get current blog(s) from db
	QSqlQuery q(_db);
	q.exec("SELECT * FROM userinfo");
	q.next();
	QString bi = q.value(0).toString().replace(bid, "");
	QString xr = q.value(4).toString().replace(burl, "");

	QSqlQuery qu(_db);
	qu.prepare("UPDATE userinfo SET blogid=:bi and url=:u");
	qu.bindValue(":bi", bi);
	qu.bindValue(":u", xr);
	bool r = qu.exec();

	q.clear();
	qu.clear();

	return r;
}

void WPUtils::setBlogsInfo(QString bid, QString burl)
{

	qDebug() << "saving " << bid << burl;

	_blogs.insertMulti(bid, burl);

	_totbid += (( !_totbid.isEmpty() ) ? " , "  : "" ) + bid; // + _blogid + " , " + bid;
	_totburl+= (( !_totburl.isEmpty() ) ? " , "  : "" ) + burl; // _endpoint + " , " + burl;

	_blogid = bid; //_blogs.values("blogid")[_position];
	_endpoint = burl;//_blogs.values("burl")[_position];

	/* register infos */
	QSqlQuery query(_db);

	if ( !info_registered() )
	{
		qDebug() << "inserting" << _blogid << _endpoint;
		query.prepare("INSERT INTO userinfo (blogid,username,password,xmlrpc) VALUES (:blogid, :username, :password, :xmlrpc)");
		query.bindValue(":blogid", _blogid);
		query.bindValue(":username", _username); // <-- crypt
		query.bindValue(":password", encrypt(_password));
		query.bindValue(":xmlrpc", _endpoint);
		query.exec();
	} else {
		qDebug() << "updating" << _totbid << _totburl;
		query.prepare("UPDATE userinfo set blogid=:blogid , xmlrpc=:xmlrpc");
		query.bindValue(":blogid", _totbid);
		query.bindValue(":xmlrpc", _totburl);
		//QSqlError e = query.lastError();
		query.exec();
	}
}



// << -- XML/RPC stuff -- >>


void WPUtils::uploadFile(QString furl)
{
	QFile* file = new QFile(furl);



	if ( file->exists() )
		qDebug() << "file founded.";
	else qDebug() << "file not found.";

	if ( file->isReadable() )
		qDebug() << "readable";
	else qDebug() << "unreadable";

	file->open(QIODevice::ReadOnly);

	QFileInfo fileInfo(file->fileName());
	QString nome(fileInfo.fileName());

	_xml.clear();
	QXmlStreamWriter sw(&_xml);

	sw.setAutoFormatting(true);
	sw.writeStartDocument();

	sw.writeStartElement("methodCall");
	sw.writeTextElement("methodName", "wp.uploadFile");
	sw.writeStartElement("params");
	sw.writeStartElement("param");
	sw.writeCharacters("blog_id");
	sw.writeTextElement("value", _blogid);
	sw.writeEndElement();
	sw.writeStartElement("param");
	sw.writeCharacters("username");
	sw.writeTextElement("value", _username);
	sw.writeEndElement();
	sw.writeStartElement("param");
	sw.writeCharacters("password");
	sw.writeTextElement("value", _password);
	sw.writeEndElement();
	sw.writeStartElement("struct");
	sw.writeStartElement("member");
	sw.writeTextElement("name", "name");
	sw.writeTextElement("value", nome);
	sw.writeEndElement();
	sw.writeStartElement("member");
	sw.writeTextElement("name", "type");
	QImageReader reader(furl);

	sw.writeTextElement("value", "image/"+reader.format());
	sw.writeEndElement();
	sw.writeStartElement("member");
	sw.writeTextElement("name", "bits");
	sw.writeStartElement("value");
	sw.writeStartElement("base64");
	sw.writeCharacters(file->readAll().toBase64());
	sw.writeEndElement();
	sw.writeEndElement();
	sw.writeEndElement();
	sw.writeStartElement("member");
	sw.writeTextElement("name", "overwrite");
	sw.writeTextElement("value", "true");
	sw.writeEndElement();
	sw.writeEndElement();
	sw.writeEndElement();
	sw.writeEndDocument();

	QNetworkAccessManager *manager = new QNetworkAccessManager();

	QObject::connect(manager, SIGNAL(finished(QNetworkReply*)), this, SLOT(replyFinished(QNetworkReply*)));

	QUrl url;

	url.setUrl(_endpoint);
	QNetworkRequest request(url);
	int cmd = 0;
	request.setAttribute(QNetworkRequest::Attribute(QNetworkRequest::User + 1), QVariant((int) cmd)); /* not sure */
	request.setRawHeader("User-Agent", "wp-bb10/0.0.1");
	request.setHeader(QNetworkRequest::ContentTypeHeader, "text/xml");


	manager->post(request,_xml);
}


void WPUtils::buildWPXML(QString mName, bool standardParams,
		QStringList other_paramsNames, QStringList other_paramsValues,
		QStringList memberNames , QStringList memberValues)

{
	qDebug() << "bwpx : endpoint on = " << _endpoint;
	QByteArray _xml;
	QXmlStreamWriter sw(&_xml);

	sw.setAutoFormatting(true);
	sw.writeStartDocument();

	sw.writeStartElement("methodCall");
	sw.writeTextElement("methodName", mName);

	sw.writeStartElement("params");

	if ( standardParams )
	{
		sw.writeStartElement("param");
		sw.writeCharacters("blog_id");
		sw.writeTextElement("value", _blogid);
		sw.writeEndElement();

		sw.writeStartElement("param");
		sw.writeCharacters("username");
		sw.writeTextElement("value", _username);
		sw.writeEndElement();

		sw.writeStartElement("param");
		sw.writeCharacters("password");
		sw.writeTextElement("value", _password);
		sw.writeEndElement();
	}

	int i;

	for ( i=0; i<other_paramsNames.size(); i++ )
	{
		sw.writeStartElement("param");
		sw.writeCharacters(other_paramsNames.at(i).toLocal8Bit().constData());
		sw.writeTextElement("value", other_paramsValues.at(i).toLocal8Bit().constData());
		sw.writeEndElement();
	}
	sw.writeEndElement();
	if ( memberNames.size() > 0 )
	{
		sw.writeStartElement("struct");

		for ( i = 0; i < memberNames.size(); i++ )
		{
			sw.writeStartElement("member");
			sw.writeTextElement("name", memberNames.at(i).toLocal8Bit().constData());
			sw.writeTextElement("value", memberValues.at(i).toLocal8Bit().constData());
			sw.writeEndElement();

		}

		sw.writeEndElement();
	}


	sw.writeEndDocument();

	QNetworkAccessManager *manager = new QNetworkAccessManager();

	mName.replace("deletePost","delPost", Qt::CaseSensitive);
	mName.replace("deleteComment", "delComment", Qt::CaseSensitive);
	if ( memberValues.contains("page", Qt::CaseSensitive) )
		mName.replace("Post", "Page", Qt::CaseInsensitive);

	manager->setObjectName(mName.replace("wp.",""));

	QObject::connect(manager, SIGNAL(finished(QNetworkReply*)), this, SLOT(replyFinished(QNetworkReply*)));

	QUrl url;

	url.setUrl(_endpoint);
	QNetworkRequest request(url);
	int cmd = 0;
	request.setAttribute(QNetworkRequest::Attribute(QNetworkRequest::User + 1), QVariant((int) cmd)); /* not sure */
	request.setRawHeader("User-Agent", "wp-bb10/0.0.1");
	request.setHeader(QNetworkRequest::ContentTypeHeader, "text/xml");

	manager->post(request,_xml);
}

void WPUtils::getBlogs(QString u, QString p, QString blog_address)
{
	_xml.clear();
	QXmlStreamWriter sw(&_xml);

	sw.setAutoFormatting(true);
	sw.writeStartDocument();

	sw.writeStartElement("methodCall");
	sw.writeTextElement("methodName", "wp.getUsersBlogs");

	sw.writeStartElement("params");
	sw.writeStartElement("param");
	sw.writeCharacters("username");
	sw.writeTextElement("value", u);
	sw.writeEndElement();
	sw.writeStartElement("param");
	sw.writeCharacters("password");
	sw.writeTextElement("value", p);
	sw.writeEndElement();

	sw.writeEndDocument();

	QNetworkAccessManager *manager = new QNetworkAccessManager();

	manager->setObjectName("getUsersBlogs");

	QObject::connect(manager, SIGNAL(finished(QNetworkReply*)), this, SLOT(replyFinished(QNetworkReply*)));

	QUrl url;

	//_xml = xml.toUtf8();

	QString tmp_url = searchEndPoint(blog_address);
	if ( tmp_url.isEmpty() )
	{
		qDebug() << "unable to found endpoint";
		res.insert("ERROR","ERROR");
	} else {

		url.setUrl(tmp_url);
		QNetworkRequest request(url);
		int cmd = 0;
		request.setAttribute(QNetworkRequest::Attribute(QNetworkRequest::User + 1), QVariant((int) cmd)); /* not sure */
		request.setRawHeader("User-Agent", "wp-bb10/0.0.1");
		request.setHeader(QNetworkRequest::ContentTypeHeader, "text/xml");

		manager->post(request,_xml);
	}
}

/* not yet used
 *
 *
void WPUtils::getCategories()
{

	_xml.clear();
	QDomDocument doc;
	QDomProcessingInstruction init = doc.createProcessingInstruction("xml version=\"1.0\"", "encoding=\"UTF-8\"");
	QDomElement mc = doc.createElement("methodCall");
	QDomElement mn = doc.createElement("methodName");
	QDomText mnt = doc.createTextNode("wp.getTerms");
	QDomElement ps = doc.createElement("params");
	QDomElement p1 = doc.createElement("param");
	QDomText p1t = doc.createTextNode("blogid");
	QDomElement v1 = doc.createElement("value");
	QDomText v1t = doc.createTextNode(_blogid);
	QDomElement p2 = doc.createElement("param");
	QDomText p2t = doc.createTextNode("username");
	QDomElement v2 = doc.createElement("value");
	QDomText v2t = doc.createTextNode(_username);
	QDomElement p3 = doc.createElement("param");
	QDomText p3t = doc.createTextNode("password");
	QDomElement v3 = doc.createElement("value");
	QDomText v3t = doc.createTextNode(_password);
	QDomElement p4 = doc.createElement("param");
	QDomText p4t = doc.createTextNode("taxonomy");
	QDomElement v4 = doc.createElement("value");
	QDomText v4t = doc.createTextNode("category");

	doc.appendChild(init);
	doc.appendChild(mc);
	mc.appendChild(mn);
	mn.appendChild(mnt);
	mc.appendChild(ps);

	ps.appendChild(p1);
	p1.appendChild(p1t);
	p1.appendChild(v1);
	v1.appendChild(v1t);

	ps.appendChild(p2);
	p2.appendChild(p2t);
	p2.appendChild(v2);
	v2.appendChild(v2t);

	ps.appendChild(p3);
	p3.appendChild(p3t);
	p3.appendChild(v3);
	v3.appendChild(v3t);

	ps.appendChild(p4);
	p4.appendChild(p4t);
	p4.appendChild(v4);
	v4.appendChild(v4t);



	_xml = doc.toString().toUtf8();

	QNetworkAccessManager *manager = new QNetworkAccessManager();

	QObject::connect(manager, SIGNAL(finished(QNetworkReply*)), this, SLOT(replyFinished(QNetworkReply*)));

	QUrl url;

	url.setUrl(_endpoint);
	QNetworkRequest request(url);
	int cmd = 0;
	request.setAttribute(QNetworkRequest::Attribute(QNetworkRequest::User + 1), QVariant((int) cmd));
	request.setRawHeader("User-Agent", "wp-bb10/0.0.1");
	request.setHeader(QNetworkRequest::ContentTypeHeader, "text/xml");

	manager->post(request,_xml);
}
 */

void WPUtils::replyFinished(QNetworkReply *rep)
{
	QVariantMap _res_bck;
	model = new GroupDataModel(QStringList() << "sortDate" ); //"date" << "date_created_gmt" << "post_date");

	model->setSortedAscending(false);

	model->setGrouping(ItemGrouping::None);

	if ( model && !model->isEmpty() )
		model->clear();

	if ( !res.isEmpty() )
		res.clear();

	if (!_res_bck.isEmpty() )
		_res_bck.clear();


	QByteArray ret = rep->readAll();

	if ( !ret.isEmpty() )
		qDebug() << "reading " << ret; //rep->readAll();
	else qDebug() << "ret empty -> error handling /*TODO*/";

	QString _current_name = "";

	QXmlStreamReader xml(ret);

	QList<QVariantMap> Entries;
	int _struct_counter = 0;

	while(!xml.atEnd() && !xml.hasError()) {
		QXmlStreamReader::TokenType token = xml.readNext();
		if ( token == QXmlStreamReader::StartElement )
		{
			if ( xml.name().toString() == "fault")
			{
				res["ERROR"] = "fault";
			} else if ( xml.name().toString() == "struct" )
			{
				_struct_counter++;
			} else if ( xml.name().toString() == "name" )
			{
				token = xml.readNext();
				_current_name = xml.text().toString();
			} else if ( xml.name().toString() == "value" && !_current_name.isEmpty() )
			{
				token = xml.readNext();
				if ( xml.name().toString() == "string" || xml.name().toString() == "boolean" || xml.name().toString() == "dateTime.iso8601" )
				{
					token = xml.readNext();
					if ( _current_name == "post_date" || _current_name == "date_created_gmt" )
					{
						QLocale c = QLocale::c();
						QDateTime date = c.toDateTime(xml.text().toString(), QLatin1String("yyyyMMddTHH:mm:ss"));//ddd, dd MMM yyyy HH:mm:ss"));// '+0000"));
						QString outputFromat("dd MMM yyyy - HH:mm:ss");
						date.setTimeSpec(Qt::UTC);
						res["sortDate"] = date;
						res["date"] = date.toString(outputFromat);
						/* is this insane?! */
						/*
						QString theDate = xml.text().toString(); //"20130503T14:48:55";
						QDateTime date = QDateTime::fromString(theDate, "yyyyMMddTHH:mm:ss");
						res["sortDate"] = date;
						res["date"] = date.toString(Qt::SystemLocaleShortDate);
						 */
					}
					else res[_current_name] = xml.text().toString();

					_current_name = "";
				} else _current_name = "";
			} else if ( xml.name().toString() == "string" )
			{
				/* newpost workaround */
				token = xml.readNext();
				res["newpostid"] = xml.text().toString();
				model->insert(res);
				_res_bck.unite(res);
				res.clear();
			} else if ( xml.name().toString() == "boolean")
			{
				/* deletepost workaround */
				token = xml.readNext();
				res["delpost"] = xml.text().toString();
				model->insert(res);
				_res_bck.unite(res);
				res.clear();
			} else if ( xml.name().toString() == "int" )
			{
				/* newcomment workaround */
				token = xml.readNext();
				res["newcommentid"] = xml.text().toString();
				model->insert(res);
				_res_bck.unite(res);
				res.clear();
			}
			QVariantMap Entry;
						foreach(const QXmlStreamAttribute &attr, xml.attributes()) {
							qDebug() << "adding name = " << attr.name().toString() << " value = " << attr.value().toString();
							Entry[attr.name().toString()] = attr.value().toString();
						}
						qDebug() << "adding name = " << xml.name().toString() << " and = " << xml.text().toString();
						Entry[_current_name] = xml.text().toString();
								//xml.text().toString();
						Entries.append(Entry);

		} else if ( token == QXmlStreamReader::EndElement )
		{
			if ( xml.name().toString() == "struct" )
			{
				_struct_counter--;

				if ( _struct_counter == 0 )
				{
					if ( !res.isEmpty() )
					{
						model->insert(res);
						_res_bck.unite(res);
						res.clear();
					} else qDebug() << "*+*+*+*+*+*+*+* ouch! res is empty!! =====DO SMTG======";

				}
			}
		}
	}

	res = _res_bck;

	QList<QVariant> one_blog = res.values("blogid");

	if ( !one_blog.isEmpty() && one_blog.size() == 1 )
	{
		qDebug() << "one blog = " << one_blog;
		qDebug() << "size = " << QString::number(one_blog.size());
		/* skip the blog selection */
		qDebug() << "adding = " << one_blog[0].toString();
		QList<QVariant> bu = res.values("xmlrpc");
		setBlogsInfo(one_blog[0].toString(), bu[0].toString());
		res["oneblog"] = 1;
		//setBlogsInfo(one_blog[1], QString burl)
	}

	QVariantList QVList;

    for(QVariantMap::const_iterator iter = res.begin(); iter != res.end(); ++iter) {
    	qDebug() << "traversing map ";
    	qDebug() << iter.key() << iter.value();
    }

	qDebug() << "stuff coming : " << Entries;

	if(QObject* pObject = sender()) {
		QString name = pObject->objectName();
		if ( !name.isEmpty() )
		{
			QString methodName = "dataReady_" + name;
			const char *x = methodName.toStdString().c_str();
			QMetaObject::invokeMethod(this, x, Qt::DirectConnection);//, Qt::DirectConnection);
		} else emit dataReady(res);//QVList);

	} else emit dataReady(res);
}

/* no need to pass a qbytearray, model filled in the replyFinished */
bb::cascades::GroupDataModel * WPUtils::setModel(QByteArray a)
{
	/***FIXME***/
	return model;
}

QString WPUtils::sanitize(QString burl)
{
	/*
	 * check for the presence of http / https
	 * check for the trailing /
	 */
	if ( !burl.isEmpty() ) {
		if ( !burl.toLower().startsWith("http://") && !burl.toLower().startsWith("https://") )
		{
			burl = "http://" + burl;
		}
		if ( !burl.endsWith("/") )
			burl.append("/");


		return burl;
	}

	return burl;

}

QString WPUtils::searchEndPoint(QString url) // WP_FindEndPoint(QString url)
{
	_url = sanitize(url);
	/*
	 * not here , but somewhere esle TBD
	QUrl t(_url);
	if ( !t.isValid() )
	{
		return "";
	}*/

	if ( _url.isEmpty() )
	{
		_url = "https://wordpress.com/xmlrpc.php";
		if ( validate(_url) )
			return _endpoint;
		else return "";


	} else {
		if ( _url.indexOf("xmlrpc.php") != - 1 )
		{
			if ( validate(_url) )
				return _endpoint;
		}
		else if ( _url.indexOf("/wp-admin/") != -1 )
		{
			/*
					input contains /wp-admin/
					remove it, and adding xmlrpc.php (WRN : check if there is also xmlrpc.php FIXME )
					then validate
			 */
			_url.replace("/wp-admin/","/").append("xmlrpc.php");
			if ( validate(_url) )
				return _endpoint;
		}
		else if ( validate(_url.append("xmlrpc.php")) )
		{
			return _endpoint;
		} else {
			/*
						unable to locate xmlrpc.php
						try to search in the HTML. href or pingback link
			 */
			QNetworkAccessManager *a = new QNetworkAccessManager();
			QUrl url(_url);//.append("/"));
			QNetworkRequest request(_url);

			QNetworkReply *reply = a->get(request);
			//QEvent_loop _loop;
			QObject::connect(a, SIGNAL(finished(QNetworkReply*)), this, SLOT(checkForPingback(QNetworkReply*)) );

			_loop.exec();

			return _endpoint;
			/*if ( _endpoint.isEmpty() )
							return
			 */


		}
	}

	if ( _endpoint.isEmpty() )
	{
		_url = "https://wordpress.com/xmlrpc.php";
		if ( validate(_url) )
			return _endpoint;
		else return "";


	}

	return "";



}

bool WPUtils::validate(QString e)
{
	QUrl u(e);
	QNetworkAccessManager *a = new QNetworkAccessManager();

	QNetworkRequest request(u);
	int cmd = 0;
	request.setAttribute(QNetworkRequest::Attribute(QNetworkRequest::User + 1), QVariant((int) cmd));
	request.setRawHeader("User-Agent", "wp-bb10/0.0.1");
	request.setHeader(QNetworkRequest::ContentTypeHeader, "text/xml");

	QNetworkReply *reply;

	reply = a->post(request, _xml);


	QObject::connect(a, SIGNAL(finished(QNetworkReply*)), this, SLOT(repFinished(QNetworkReply*)) );
	_loop.exec();

	if ( _endpoint.isEmpty() )
		return false;
	else return true;
}

void WPUtils::repFinished(QNetworkReply *r)
{
	QByteArray t = r->readAll();
	QXmlStreamReader xr(t);//r->readAll());

	_endpoint = "";
	while(!xr.atEnd() && !xr.hasError())
	{

		QXmlStreamReader::TokenType token = xr.readNext();
		if(token == QXmlStreamReader::StartElement)
		{
			if ( xr.name() == "methodResponse") //all the correct call, contain a <methodResponse> ; right? */
			{
				_endpoint = _url;
			}


		}
	}
	xr.clear();
	_loop.quit();
}
void WPUtils::checkForPingback(QNetworkReply *r)
{
	QRegExp trx("link rel=\"pingback\" href=\"([^\"]*)\"");//(.*)<\/a>)
	QString str = r->readAll();//"Offsets: 12 14 99 231 7";

	int pos = trx.indexIn(str);
	if ( pos != -1 )
	{
		QStringList list = trx.capturedTexts();
		if ( validate(list[1]) )
			qDebug() << "got it " << _endpoint;// return _endpoint;
		else{
			/*
							check on pingback href failed
							check on EditURI href
			 */
			QRegExp erx("link rel=\"EditURI\" type=\"application/rsd\+[^*]*\" title=\"RSD\" href=\"([^\"]*)\"");//(.*)<\/a>)
			int pos = erx.indexIn(str);
			if ( pos != -1 )
			{
				QStringList list = erx.capturedTexts();
				if (list[1].indexOf('xmlrpc') != -1 ) //double check we got the right url
				{
					/*
									download the xml and parse it
										check for apiLink url
					 */
					/****TODO****/
				}
				if ( validate(list[1]) )
					qDebug() << "got on 2 = " <<  _endpoint;
				else {
					qDebug() << "nothing found";
				}
			}
		}
	}
}
