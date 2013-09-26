/*
 * WPUtils.cpp
 *
 *      Author: Daniele (b0unc3) Maio
 */

#include "WPUtils.h"


const QString WPUtils::dbName = "wpbb10.db";

WPUtils::WPUtils(QObject *parent)
{
	QDir home = QDir::home();
	QFile file(home.absoluteFilePath(dbName));
	if (!file.exists() && file.open(QIODevice::ReadWrite) )
	{
		SqlDataAccess sda(home.absoluteFilePath(dbName));
		sda.execute("CREATE TABLE userinfo(blogid TEXT, id INTEGER PRIMARY KEY, username TEXT, password BLOB, xmlrpc BLOB);");
	}
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
WPUtils::~WPUtils() {
	// TODO Auto-generated destructor stub
	_db.close();
}

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
	//for sure there is only - 1 - record
	q.next();
	_username = q.value(2).toString();
	_password = q.value(3).toString();
	QString bi = q.value(0).toString();
	QString xr = q.value(4).toString();

	QStringList bis = bi.split(",");
	QStringList xrs = xr.split(",");
	_blogid = bis.at(0);
	_endpoint = xrs.at(0);

	int i=0;
	for ( i=0; i<bis.size(); i++)
		_blogs.insertMulti(bis.at(i), xrs.at(i));

}

bool WPUtils::info_registered()
{
	QDir home = QDir::home();
	QFile file(home.absoluteFilePath(dbName));
	SqlDataAccess sda(home.absoluteFilePath(dbName));//QDir::currentPath() + "/data/wpbb10.db");
	QVariant list = sda.execute("SELECT * FROM userinfo");
	return (list.toList().size() > 0);
}

int WPUtils::getPosition()
{
	return _position;
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

void WPUtils::setBlogsInfo(QString bid, QString burl)
{

	_blogs.insertMulti(bid, burl);

	QString totbid = _blogid + " , " + bid;
	QString totburl= _endpoint + " , " + burl;

	_blogid = bid; //_blogs.values("blogid")[_position];
	_endpoint = burl;//_blogs.values("burl")[_position];

	/* register infos */
	QSqlQuery query(_db);

	if ( !info_registered() )
	{
		query.prepare("INSERT INTO userinfo (blogid,username,password,xmlrpc) VALUES (:blogid, :username, :password, :xmlrpc)");
		query.bindValue(":blogid", _blogid);
		query.bindValue(":username", _username);
		query.bindValue(":password", _password);
		query.bindValue(":xmlrpc", _endpoint);
		query.exec();
	} else {
		query.prepare("UPDATE table userinfo set blogid=:blogid and xmlrpc=:xmlrpc");
		query.bindValue(":blogid", totbid);
		query.bindValue(":xmlrpc", totburl);
		query.exec();
	}
}



// << -- XML/RPC stuff -- >>


void WPUtils::uploadFile(QString furl)
{

	QString workingDir = QDir::currentPath();

	QString fn = furl;
	QStringList l = fn.split('/');
	QString nome = l[l.count()-1];

	QString f = workingDir + "/shared/camera/" + nome;

	QFile* file = new QFile(f);

	if ( file->exists() )
		qDebug() << "file founded.";
	else qDebug() << "file not found.";

	if ( file->isReadable() )
		qDebug() << "readable";
	else qDebug() << "unreadable";

	file->open(QIODevice::ReadOnly);

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
	QImageReader reader(f);

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

void WPUtils::getComment(QString comment_id)
{
	_xml.clear();
	QXmlStreamWriter sw(&_xml);

	sw.setAutoFormatting(true);
	sw.writeStartDocument();

	sw.writeStartElement("methodCall");
	sw.writeTextElement("methodName", "wp.getComment");
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
	sw.writeStartElement("param");
	sw.writeCharacters("comment_id");
	sw.writeTextElement("value", comment_id);
	sw.writeEndElement();
	sw.writeEndElement();
	sw.writeEndDocument();

	QNetworkAccessManager *manager = new QNetworkAccessManager();

	manager->setObjectName("getComment");

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

void WPUtils::newComment(QString post_id, QString content, QString comment_parent)
{
	_xml.clear();
	QXmlStreamWriter sw(&_xml);

	sw.setAutoFormatting(true);
	sw.writeStartDocument();

	sw.writeStartElement("methodCall");
	sw.writeTextElement("methodName", "wp.newComment");
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
	sw.writeStartElement("param");
	sw.writeCharacters("post_id");
	sw.writeTextElement("value", post_id);
	sw.writeEndElement();
	sw.writeStartElement("struct");
	sw.writeStartElement("member");
	sw.writeTextElement("name", "content");
	sw.writeTextElement("value", content);
	sw.writeEndElement();
	if ( !comment_parent.isEmpty())
	{
		sw.writeStartElement("member");
		sw.writeTextElement("name", "comment_parent");
		sw.writeTextElement("value", comment_parent);
		sw.writeEndElement();
	}



	sw.writeEndElement();
	sw.writeEndElement();
	sw.writeEndDocument();

	QNetworkAccessManager *manager = new QNetworkAccessManager();

	manager->setObjectName("newComment");

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


void WPUtils::editComment(QString comment_id, QString status, QString content, QString author, QString authormail, QString authorurl)
{
	_xml.clear();
	QXmlStreamWriter sw(&_xml);

	sw.setAutoFormatting(true);
	sw.writeStartDocument();

	sw.writeStartElement("methodCall");
	sw.writeTextElement("methodName", "wp.editComment");
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
	sw.writeStartElement("param");
	sw.writeCharacters("comment_id");
	sw.writeTextElement("value", comment_id);
	sw.writeEndElement();
	sw.writeStartElement("struct");
	sw.writeStartElement("member");
	sw.writeTextElement("name", "status");
	sw.writeTextElement("value", status);
	sw.writeEndElement();
	if ( !content.isEmpty())
	{
		sw.writeStartElement("member");
		sw.writeTextElement("name", "content");
		sw.writeTextElement("value", content);
		sw.writeEndElement();
	}
	if ( !author.isEmpty())
	{
		sw.writeStartElement("member");
		sw.writeTextElement("name", "author");
		sw.writeTextElement("value", author);
		sw.writeEndElement();
	}
	if ( !authormail.isEmpty())
	{
		sw.writeStartElement("member");
		sw.writeTextElement("name", "author_email");
		sw.writeTextElement("value", authormail);
		sw.writeEndElement();
	}
	if ( !authorurl.isEmpty())
	{
		sw.writeStartElement("member");
		sw.writeTextElement("name", "author_url");
		sw.writeTextElement("value", authorurl);
		sw.writeEndElement();
	}

	sw.writeEndElement();
	sw.writeEndElement();
	sw.writeEndDocument();

	QNetworkAccessManager *manager = new QNetworkAccessManager();

	manager->setObjectName("editComment");

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

void WPUtils::editPost(bool pages, QString pid, QString title, QString content, QString status, QString format)
{
	_xml.clear();
	QXmlStreamWriter sw(&_xml);

	sw.setAutoFormatting(true);
	sw.writeStartDocument();

	sw.writeStartElement("methodCall");
	sw.writeTextElement("methodName", "wp.editPost");
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
	sw.writeStartElement("param");
	sw.writeCharacters("post_id");
	sw.writeTextElement("value", pid);
	sw.writeEndElement();
	sw.writeStartElement("struct");
	if ( !content.isEmpty())
	{
		sw.writeStartElement("member");
		sw.writeTextElement("name", "post_content");
		sw.writeTextElement("value", content);
		sw.writeEndElement();
	}
	if ( !title.isEmpty())
	{
		sw.writeStartElement("member");
		sw.writeTextElement("name", "post_title");
		sw.writeTextElement("value", title);
		sw.writeEndElement();
	}
	if ( !status.isEmpty())
	{
		sw.writeStartElement("member");
		sw.writeTextElement("name", "post_status");
		sw.writeTextElement("value", status);
		sw.writeEndElement();
	}
	if ( !format.isEmpty())
	{
		sw.writeStartElement("member");
		sw.writeTextElement("name", "post_format");
		sw.writeTextElement("value", format);
		sw.writeEndElement();
	}

	sw.writeEndElement();
	sw.writeEndElement();
	sw.writeEndDocument();

	QNetworkAccessManager *manager = new QNetworkAccessManager();

	if ( pages )
		manager->setObjectName("editPage");
	else manager->setObjectName("editPost");

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

void WPUtils::deletePost(bool pages, QString post_id)
{
	_xml.clear();
	QXmlStreamWriter sw(&_xml);

	sw.setAutoFormatting(true);
	sw.writeStartDocument();

	sw.writeStartElement("methodCall");
	sw.writeTextElement("methodName", "wp.deletePost");
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
	sw.writeStartElement("param");
	sw.writeCharacters("post_id");
	sw.writeTextElement("value", post_id);
	sw.writeEndElement();
	sw.writeEndElement();
	sw.writeEndDocument();

	QNetworkAccessManager *manager = new QNetworkAccessManager();

	if ( pages )
		manager->setObjectName("delPage");
	else manager->setObjectName("delPost");

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

void WPUtils::deleteComment(QString comment_id)
{
	_xml.clear();
	QXmlStreamWriter sw(&_xml);

	sw.setAutoFormatting(true);
	sw.writeStartDocument();

	sw.writeStartElement("methodCall");
	sw.writeTextElement("methodName", "wp.deleteComment");
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
	sw.writeStartElement("param");
	sw.writeCharacters("comment_id");
	sw.writeTextElement("value", comment_id);
	sw.writeEndElement();
	sw.writeEndElement();
	sw.writeEndDocument();

	QNetworkAccessManager *manager = new QNetworkAccessManager();

	manager->setObjectName("delComment");

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

void WPUtils::makePost(bool pages, QString title, QVariant cnt, QVariant type, QVariant status)
{
	_xml.clear();
	QString pd = cnt.toString();
	//pd.replace("&","&amp;");//&#38;");
	/*
	pd.replace("<","&lt;");//&#60;");
	pd.replace(">","&gt;");//#62;");
	pd.replace("\"","&quot;");//#34;");
	 */
	QXmlStreamWriter sw(&_xml);
	sw.setAutoFormatting(true);
	sw.writeStartDocument();

	sw.writeStartElement("methodCall");
	sw.writeTextElement("methodName", "wp.newPost");
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
	sw.writeTextElement("name", "post_type");
	sw.writeTextElement("value", (pages) ? "page" : type.toString());
	sw.writeEndElement();
	sw.writeStartElement("member");
	sw.writeTextElement("name", "post_status");
	sw.writeTextElement("value", status.toString());
	sw.writeEndElement();
	sw.writeStartElement("member");
	sw.writeTextElement("name", "post_title");
	sw.writeTextElement("value", title);
	sw.writeEndElement();

	sw.writeStartElement("member");
	sw.writeTextElement("name", "post_content");
	sw.writeTextElement("value", pd.toAscii());//.toUtf8());
	sw.writeEndElement();
	sw.writeEndElement();
	sw.writeEndDocument();

	QNetworkAccessManager *manager = new QNetworkAccessManager();

	if ( pages )
		manager->setObjectName("newPage");
	else manager->setObjectName("newPost");

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
	/* alternative ? */
	QDomDocument doc;
	QDomProcessingInstruction init = doc.createProcessingInstruction("xml version=\"1.0\"", "encoding=\"UTF-8\"");
	QDomElement mc = doc.createElement("methodCall");
	QDomElement mn = doc.createElement("methodName");
	QDomText mnt = doc.createTextNode("wp.getUsersBlogs");
	QDomElement ps = doc.createElement("params");
	QDomElement p1 = doc.createElement("param");
	QDomText p1t = doc.createTextNode("username");
	QDomElement v1 = doc.createElement("value");
	QDomText v1t = doc.createTextNode(u);
	QDomElement p2 = doc.createElement("param");
	QDomText p2t = doc.createTextNode("password");
	QDomElement v2 = doc.createElement("value");
	QDomText v2t = doc.createTextNode(p);

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

	QString xml = doc.toString();

	QNetworkAccessManager *manager = new QNetworkAccessManager();

	manager->setObjectName("getUsersBlogs");

	QObject::connect(manager, SIGNAL(finished(QNetworkReply*)), this, SLOT(replyFinished(QNetworkReply*)));

	QUrl url;

	_xml = xml.toUtf8();

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
	request.setAttribute(QNetworkRequest::Attribute(QNetworkRequest::User + 1), QVariant((int) cmd)); /* not sure */
	request.setRawHeader("User-Agent", "wp-bb10/0.0.1");
	request.setHeader(QNetworkRequest::ContentTypeHeader, "text/xml");

	manager->post(request,_xml);
}

void WPUtils::getPost(bool pages, QString pid)
{

	_xml.clear();
	/* alternative ? */
	QDomDocument doc;
	QDomProcessingInstruction init = doc.createProcessingInstruction("xml version=\"1.0\"", "encoding=\"UTF-8\"");
	QDomElement mc = doc.createElement("methodCall");
	QDomElement mn = doc.createElement("methodName");
	QDomText mnt = doc.createTextNode("wp.getPost");
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
	QDomText p4t = doc.createTextNode("post_id");
	QDomElement v4 = doc.createElement("value");
	QDomText v4t = doc.createTextNode(pid);

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

	if ( pages )
		manager->setObjectName("getPage");
	else manager->setObjectName("getPost");

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

void WPUtils::getPages()
{
	//useless
}

void WPUtils::getComments()
{
	_xml.clear();
	QXmlStreamWriter sw(&_xml);

	sw.setAutoFormatting(true);
	sw.writeStartDocument();

	sw.writeStartElement("methodCall");
	sw.writeTextElement("methodName", "wp.getComments");
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
	sw.writeEndElement();
	sw.writeEndDocument();

	QNetworkAccessManager *manager = new QNetworkAccessManager();

	manager->setObjectName("getComments");

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

void WPUtils::getPosts(bool pages)
{
	_xml.clear();
	QXmlStreamWriter sw(&_xml);

	sw.setAutoFormatting(true);
	sw.writeStartDocument();

	sw.writeStartElement("methodCall");
	sw.writeTextElement("methodName", "wp.getPosts");
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
	if ( pages )
	{
		sw.writeStartElement("struct");
		sw.writeStartElement("member");
		sw.writeTextElement("name", "post_type");
		sw.writeTextElement("value", "page");
		sw.writeEndElement();
		sw.writeEndElement();
	}
	sw.writeEndElement();
	sw.writeEndDocument();

	QNetworkAccessManager *manager = new QNetworkAccessManager();

	if ( pages )
		manager->setObjectName("getPages");
	else manager->setObjectName("getPosts");

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
						/* is this insane?! */
						QString theDate = xml.text().toString(); //"20130503T14:48:55";
						QDateTime date = QDateTime::fromString(theDate, "yyyyMMddTHH:mm:ss");
						res["sortDate"] = date;
						res["date"] = date.toString(Qt::SystemLocaleShortDate);
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

	if(QObject* pObject = sender()) {
		QString name = pObject->objectName();
		//datagetPosts
		//getPosts
		if ( !name.isEmpty() )
		{
			QString methodName = "dataReady_" + name;
			const char *x = methodName.toStdString().c_str();
			QMetaObject::invokeMethod(this, x, Qt::DirectConnection);//, Qt::DirectConnection);
		} else emit dataReady(ret);

	} else emit dataReady(ret);
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
						try to search on the HTML. href of pingback link
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
