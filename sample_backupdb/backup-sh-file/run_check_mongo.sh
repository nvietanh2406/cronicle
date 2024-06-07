// Kết nối đến MongoDB
var conn = new MongoClient('mongodb://mongo-root:w2tWZe3HKJHcgxLLQoudnp4d@192.168.12.21:27017,192.168.12.11:27017,192.168.12.41:27017/admin?replicaSet=rsdev01&readPreference=primary');
conn.connect();
var db = conn.db('admin');

// Lấy danh sách tất cả các database
var dbs = db.adminCommand('listDatabases');
print('------- Danh sách database -------');
printjson(dbs.databases);

// Lấy thông tin về một database ngẫu nhiên
randomDbName = dbs.databases[Math.floor(Math.random() * dbs.databases.length)].name;
randomDb = db.getSiblingDB(randomDbName);
print('\n------- Database ngẫu nhiên: ' + randomDbName + ' -------');

// Lấy danh sách các collection trong database đó
collections = randomDb.getCollectionNames();
print('Số collection: ' + collections.length);
print('Danh sách collection:');
printjson(collections);

// Lấy 10 document ngẫu nhiên từ một collection ngẫu nhiên
if (collections.length > 0) {
    randomCollection = collections[Math.floor(Math.random() * collections.length)];
    print('\nCollection ngẫu nhiên: ' + randomCollection);
    docs = randomDb.getCollection(randomCollection).find().limit(10).toArray();
    print('10 document ngẫu nhiên:');
    printjson(docs);
} else {
    print('Database không có collection');
}

// Đóng kết nối
conn.close();