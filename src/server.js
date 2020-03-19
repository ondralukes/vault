const mongodb = require('mongodb');
const express = require('express');
const crypto = require('crypto');
const session = require('express-session');
const RSA = require('node-rsa');

const mongo = mongodb.MongoClient;
const url = 'mongodb://localhost:27017/vault';

var app = express();

app.use(session({
  secret: '9bb268948e97a37e045c37ac6208e7c43b6',
  resave: false,
  saveUninitialized: false,
  cookie: { secure: false }
}));

app.use(express.json());

app.use(express.static('public'));

app.post('/user/create', async (req, res) => {
  function validateRegister(){
    return new Promise((resolve, reject) => {
      if(Object.keys(req.body).length > 2){
        res.statusCode = 400;
        res.setHeader('Content-Type', 'text/plain');
        res.write('Too many arguments provided.');
        res.end();
        reject();
      }
      if(typeof req.body.name === 'undefined'){
        res.statusCode = 400;
        res.setHeader('Content-Type', 'text/plain');
        res.write('No name provided.');
        res.end();
        reject();
      }
      if(typeof req.body.rsa === 'undefined'){
        res.statusCode = 400;
        res.setHeader('Content-Type', 'text/plain');
        res.write('No RSA keypair provided.');
        res.end();
        reject();
      }
      if(typeof req.body.rsa.public === 'undefined' ||
        typeof req.body.rsa.private === 'undefined'){
        res.statusCode = 400;
        res.setHeader('Content-Type', 'text/plain');
        res.write('RSA keypair incomplete.');
        res.end();
        reject();
      }
      if(!req.body.rsa.public.length > 750){
        res.statusCode = 400;
        res.setHeader('Content-Type', 'text/plain');
        res.write('RSA public key too long.');
        res.end();
        reject();
      }
      if(!req.body.rsa.private.length > 3000){
        res.statusCode = 400;
        res.setHeader('Content-Type', 'text/plain');
        res.write('RSA private key too long.');
        res.end();
        reject();
      }
      resolve();
    });
  }

  function connectToDB(){
    return new Promise((resolve, reject) => {
      mongo.connect(url,
        {
          useNewUrlParser: true,
          useUnifiedTopology: true
        },
        (err, conn) => {
          if(err){
            res.statusCode = 500;
            res.setHeader('Content-Type', 'text/plain');
            res.write('DB connecting error.');
            res.end();
            reject();
          }
          resolve(conn);
        });
      });
    }

    function validateInDB(db, user){
      return new Promise((resolve, reject) => {
        var query = { name: user.name };
        db.collection('users').find(query).toArray((err, dbres) => {
          if(err){
            res.statusCode = 500;
            res.setHeader('Content-Type', 'text/plain');
            res.write('DB validating error.');
            res.end();
            reject();
          }
          if(dbres.length == 0){
            resolve();
          } else {
            res.statusCode = 400;
            res.setHeader('Content-Type', 'text/plain');
            res.write('This name is already used.');
            res.end();
            reject();
          }
        });
      });
    }

    function insert(db, user){
      return new Promise((resolve, reject) => {
        var query = { name: user.name };
        db.collection('users').insertOne(user,(err, dbres) => {
          if(err){
            res.statusCode = 500;
            res.setHeader('Content-Type', 'text/plain');
            res.write('DB inserting error.');
            res.end();
            reject();
          }
          res.statusCode = 200;
          res.end();
          resolve();
        });
      });
    }

    var user = req.body;

    try {
      await validateRegister();
      var conn = await connectToDB();
      var db = conn.db('vault');
      await validateInDB(db, user);
      await insert(db, user);
      conn.close();
    } catch (err){
      if(conn) conn.close();
      return;
    }

  });

app.post('/token', async (req, res) => {
  if(!req.body.name){
    res.statusCode = 400;
    res.setHeader('Content-Type', 'text/plain');
    res.write('No name provided.');
    res.end();
    return;
  }
  try {
    var conn = await connectToDB();
    var db = conn.db('vault');
    var user = await getUser(db, req.body.name);
    var token = await generateToken();
  } catch (err){
    if(conn) conn.close();
    return;
  }
  req.session.token = token;
  req.session.user = user;

  var response = {
    token: token,
    user: user
  };
  res.statusCode = 200;
  res.setHeader('Content-Type', 'text/json');
  res.write(JSON.stringify(response));
  res.end();

  function connectToDB(){
    return new Promise((resolve, reject) => {
      mongo.connect(url,
        {
          useNewUrlParser: true,
          useUnifiedTopology: true
        },
        (err, conn) => {
          if(err){
            res.statusCode = 500;
            res.setHeader('Content-Type', 'text/plain');
            res.write('DB connecting error.');
            res.end();
            reject();
          }
          resolve(conn);
        });
      });
    }

    function getUser(db, name){
      return new Promise((resolve, reject) => {
        var user = { name: name };
        var query = { name: user.name };
        db.collection('users').find(query).toArray((err, dbres) => {
          if(err){
            res.statusCode = 500;
            res.setHeader('Content-Type', 'text/plain');
            res.write('DB lookup error.');
            res.end();
            reject();
          }
          if(dbres.length != 1){
            res.statusCode = 400;
            res.setHeader('Content-Type', 'text/plain');
            res.write('User does not exist.');
            res.end();
            reject();
          } else {
            user.rsa = dbres[0].rsa;
            resolve(user);
          }
        });
      });
    }

    function generateToken(){
      return new Promise((resolve, reject) => {
        crypto.randomBytes(256, (err, buf) => {
          if(err){
            res.statusCode = 500;
            res.setHeader('Content-Type', 'text/plain');
            res.write('Failed to generate random token');
            res.end();
            reject();
          }
          resolve(buf.toString('hex'));
        });
      });
    }
  });

app.post('/verifyToken', async (req, res) => {
  var verified = await auth(req,res);
  if(!verified){
    return;
  }
  res.statusCode = 200;
  res.setHeader('Content-Type', 'text/plain');
  res.end();
});

app.post('/vault/create', async (req, res) => {
  var verified = await auth(req,res);
  if(!verified){
    return;
  }
  delete req.body.encryptedToken;

  function validate(){
    return new Promise((resolve, reject) => {
      if(Object.keys(req.body).length > 3){
        res.statusCode = 400;
        res.setHeader('Content-Type', 'text/plain');
        res.write('Too many arguments provided.');
        res.end();
        reject();
      }
      if(typeof req.body.codename === 'undefined'){
        res.statusCode = 400;
        res.setHeader('Content-Type', 'text/plain');
        res.write('No codename provided.');
        res.end();
        reject();
      }
      if(typeof req.body.name === 'undefined'){
        res.statusCode = 400;
        res.setHeader('Content-Type', 'text/plain');
        res.write('No name provided.');
        res.end();
        reject();
      }
      if(typeof req.body.keys === 'undefined'){
        res.statusCode = 400;
        res.setHeader('Content-Type', 'text/plain');
        res.write('No keys provided.');
        res.end();
        reject();
      }
        req.body.keys.forEach((key) => {
          if(!Object.keys(key).length > 2){
            res.statusCode = 400;
            res.setHeader('Content-Type', 'text/plain');
            res.write('Too many arguments provided for one or more keys.');
            res.end();
            reject();
          }
          if(typeof key.user === 'undefined'){
            res.statusCode = 400;
            res.setHeader('Content-Type', 'text/plain');
            res.write('No user provided for one or more keys.');
            res.end();
            reject();
          }
          if(typeof key.key === 'undefined'){
            res.statusCode = 400;
            res.setHeader('Content-Type', 'text/plain');
            res.write('No key provided for one or more keys.');
            res.end();
            reject();
          }
        });
      resolve();
    });
  }

  function connectToDB(){
    return new Promise((resolve, reject) => {
      mongo.connect(url,
        {
          useNewUrlParser: true,
          useUnifiedTopology: true
        },
        (err, conn) => {
          if(err){
            res.statusCode = 500;
            res.setHeader('Content-Type', 'text/plain');
            res.write('DB connecting error.');
            res.end();
            reject();
          }
          resolve(conn);
        });
      });
    }

  function validateInDB(db, vault){
    return new Promise((resolve, reject) => {
      var query = { codename: vault.codename };
      db.collection('vaults').find(query).toArray((err, dbres) => {
        if(err){
          res.statusCode = 500;
          res.setHeader('Content-Type', 'text/plain');
          res.write('DB validating error.');
          res.end();
          reject();
        }
        if(dbres.length == 0){
          resolve();
        } else {
          res.statusCode = 400;
          res.setHeader('Content-Type', 'text/plain');
          res.write('This codename is already used.');
          res.end();
          reject();
        }
      });
    });
  }

  function generateAccessToken(){
    return new Promise((resolve, reject) => {
      crypto.randomBytes(32, (err, buf) => {
        if(err){
          res.statusCode = 500;
          res.setHeader('Content-Type', 'text/plain');
          res.write('Failed to generate token.');
          res.end();
          reject();
        }
        resolve(buf.toString('hex'));
      });
    });
  }

  function insert(db, vault){
    return new Promise((resolve, reject) => {
      db.collection('vaults').insertOne(vault,(err, dbres) => {
        if(err){
          res.statusCode = 500;
          res.setHeader('Content-Type', 'text/plain');
          res.write('DB inserting error.');
          res.end();
          reject();
        }
        res.statusCode = 200;
        res.end();
        resolve();
      });
    });
  }

  var vault = req.body;
  try {
    await validate();
    var conn = await connectToDB();
    var db = conn.db('vault');
    await validateInDB(db, vault);
    vault.accessToken = await generateAccessToken();
    vault.messages = [];
    await insert(db, vault);
    conn.close();
  } catch (err){
    if(conn) conn.close();
    return;
  }
});

app.post('/vault/get', async (req, res) => {
  //Do not require auth, request is secured by access token.
  delete req.body.encryptedToken;

  function validate(){
    return new Promise((resolve, reject) => {
      if(Object.keys(req.body).length > 2){
        res.statusCode = 400;
        res.setHeader('Content-Type', 'text/plain');
        res.write('Too many arguments provided.');
        res.end();
        reject();
      }
      if(typeof req.body.codename === 'undefined'){
        res.statusCode = 400;
        res.setHeader('Content-Type', 'text/plain');
        res.write('No codename provided.');
        res.end();
        reject();
      }
      if(typeof req.body.accessToken === 'undefined'){
        res.statusCode = 400;
        res.setHeader('Content-Type', 'text/plain');
        res.write('No access token provided.');
        res.end();
        reject();
      }
      resolve();
    });
  }

  function connectToDB(){
    return new Promise((resolve, reject) => {
      mongo.connect(url,
        {
          useNewUrlParser: true,
          useUnifiedTopology: true
        },
        (err, conn) => {
          if(err){
            res.statusCode = 500;
            res.setHeader('Content-Type', 'text/plain');
            res.write('DB connecting error.');
            res.end();
            reject();
          }
          resolve(conn);
        });
      });
    }

    function getVault(db, params){
      return new Promise((resolve, reject) => {
        var pipeline = [
          {'$match': {codename: params.codename, accessToken: params.accessToken}},
          {'$project': {codename: 1, name: 1, keys: 1, messagesCount: {$size: '$messages'}}},
          {'$project': {_id: 0, messages:0}}
        ];
        db.collection('vaults').aggregate(pipeline, (err, dbres) =>{
          dbres.forEach((v) => {
          if(err){
            res.statusCode = 500;
            res.setHeader('Content-Type', 'text/plain');
            res.write('DB lookup error.');
            res.end();
            reject();
          }
          if(!v){
            res.statusCode = 400;
            res.setHeader('Content-Type', 'text/plain');
            res.write('Vault does not exist.');
            res.end();
            reject();
          } else {
            //Do not send access token to user
            delete v.accessToken;
            resolve(v);
          }
        });
        });
      });
    }

    var vault;
    try {
      await validate();
      var conn = await connectToDB();
      var db = conn.db('vault');
      vault = await getVault(db, req.body);
      conn.close();
    } catch (err){
      if(conn) conn.close();
      return;
    }

    res.statusCode = 200;
    res.setHeader('Content-Type', 'application/json');
    res.write(JSON.stringify(vault));
    res.end();
});

app.post('/vault/member/add', async (req, res) => {
  //Save user before the session is destroyed in auth()
  var username = req.session.user.name;

  var verified = await auth(req,res);
  if(!verified){
    return;
  }
  delete req.body.encryptedToken;

  function validate(){
    return new Promise((resolve, reject) => {
      if(Object.keys(req.body).length > 2){
        res.statusCode = 400;
        res.setHeader('Content-Type', 'text/plain');
        res.write('Too many arguments provided.');
        res.end();
        reject();
      }
      if(typeof req.body.codename === 'undefined'){
        res.statusCode = 400;
        res.setHeader('Content-Type', 'text/plain');
        res.write('No codename provided.');
        res.end();
        reject();
      }
      if(typeof req.body.key === 'undefined'){
        res.statusCode = 400;
        res.setHeader('Content-Type', 'text/plain');
        res.write('No key provided.');
        res.end();
        reject();
      }
      if(typeof req.body.key.user === 'undefined'){
        res.statusCode = 400;
        res.setHeader('Content-Type', 'text/plain');
        res.write('No key user provided.');
        res.end();
        reject();
      }
      if(typeof req.body.key.key === 'undefined'){
        res.statusCode = 400;
        res.setHeader('Content-Type', 'text/plain');
        res.write('No key key provided.');
        res.end();
        reject();
      }
      resolve();
    });
  }

  function connectToDB(){
    return new Promise((resolve, reject) => {
      mongo.connect(url,
        {
          useNewUrlParser: true,
          useUnifiedTopology: true
        },
        (err, conn) => {
          if(err){
            res.statusCode = 500;
            res.setHeader('Content-Type', 'text/plain');
            res.write('DB connecting error.');
            res.end();
            reject();
          }
          resolve(conn);
        });
      });
    }

    function pushToDB(db, params){
      return new Promise((resolve, reject) => {
        var query = {
          codename: params.codename,
          keys:
          {
            $elemMatch:
            {
              user: params.user
            },
            $not: {
              $elemMatch:
              {
                user: params.key.user
              }
            }
          }
        };
        var update = {
          $push:
          {
            keys: params.key
          }
        };
        db.collection('vaults').updateOne(query, update, (err, dbres) => {
          if(err){
            res.statusCode = 500;
            res.setHeader('Content-Type', 'text/plain');
            res.write('Failed to push to DB.');
            res.end();
            reject();
          }
          if(dbres.result.n != 1){
            res.statusCode = 500;
            res.setHeader('Content-Type', 'text/plain');
            res.write('Query did not return one vault.');
            res.end();
            reject();
          }
          resolve();
        });
      });
    }

    try {
      await validate();
      var conn = await connectToDB();
      var db = conn.db('vault');
      req.body.user = username;
      await pushToDB(db, req.body);
      conn.close();
    } catch (err){
      if(conn) conn.close();
      return;
    }

    res.statusCode = 200;
    res.setHeader('Content-Type', 'text/plain');
    res.end();
});

app.post('/message/send', async (req, res) => {
  //Do not require auth, request is secured by access token.
  delete req.body.encryptedToken;

  function validate(){
    return new Promise((resolve, reject) => {
      if(Object.keys(req.body).length > 3){
        res.statusCode = 400;
        res.setHeader('Content-Type', 'text/plain');
        res.write('Too many arguments provided.');
        res.end();
        reject();
      }
      if(typeof req.body.codename === 'undefined'){
        res.statusCode = 400;
        res.setHeader('Content-Type', 'text/plain');
        res.write('No codename provided.');
        res.end();
        reject();
      }
      if(typeof req.body.accessToken === 'undefined'){
        res.statusCode = 400;
        res.setHeader('Content-Type', 'text/plain');
        res.write('No access token provided.');
        res.end();
        reject();
      }
      if(typeof req.body.message === 'undefined'){
        res.statusCode = 400;
        res.setHeader('Content-Type', 'text/plain');
        res.write('No message provided.');
        res.end();
        reject();
      }
      resolve();
    });
  }

  function connectToDB(){
    return new Promise((resolve, reject) => {
      mongo.connect(url,
        {
          useNewUrlParser: true,
          useUnifiedTopology: true
        },
        (err, conn) => {
          if(err){
            res.statusCode = 500;
            res.setHeader('Content-Type', 'text/plain');
            res.write('DB connecting error.');
            res.end();
            reject();
          }
          resolve(conn);
        });
      });
    }

    function pushToDB(db, params){
      return new Promise((resolve, reject) => {
        var query = { codename: params.codename, accessToken: params.accessToken };
        var update = {
          $push:
          {
            messages: params.message
          }
        };
        db.collection('vaults').updateOne(query, update, (err, dbres) => {
          if(err){
            res.statusCode = 500;
            res.setHeader('Content-Type', 'text/plain');
            res.write('Failed to push to DB.');
            res.end();
            reject();
          }
          resolve();
        });
      });
    }

    try {
      await validate();
      var conn = await connectToDB();
      var db = conn.db('vault');
      await pushToDB(db, req.body);
      conn.close();
    } catch (err){
      if(conn) conn.close();
      return;
    }

    res.statusCode = 200;
    res.setHeader('Content-Type', 'text/plain');
    res.end();
});

app.post('/message/get', async (req, res) => {
  function validate(){
    return new Promise((resolve, reject) => {
      if(Object.keys(req.body).length > 4){
        res.statusCode = 400;
        res.setHeader('Content-Type', 'text/plain');
        res.write('Too many arguments provided.');
        res.end();
        reject();
      }
      if(typeof req.body.codename === 'undefined'){
        res.statusCode = 400;
        res.setHeader('Content-Type', 'text/plain');
        res.write('No codename provided.');
        res.end();
        reject();
      }
      if(typeof req.body.accessToken === 'undefined'){
        res.statusCode = 400;
        res.setHeader('Content-Type', 'text/plain');
        res.write('No access token provided.');
        res.end();
        reject();
      }
      if(typeof req.body.offset === 'undefined'){
        res.statusCode = 400;
        res.setHeader('Content-Type', 'text/plain');
        res.write('No offset provided.');
        res.end();
        reject();
      }
      if(typeof req.body.count === 'undefined'){
        res.statusCode = 400;
        res.setHeader('Content-Type', 'text/plain');
        res.write('No count provided.');
        res.end();
        reject();
      }
      resolve();
    });
  }

  function connectToDB(){
    return new Promise((resolve, reject) => {
      mongo.connect(url,
        {
          useNewUrlParser: true,
          useUnifiedTopology: true
        },
        (err, conn) => {
          if(err){
            res.statusCode = 500;
            res.setHeader('Content-Type', 'text/plain');
            res.write('DB connecting error.');
            res.end();
            reject();
          }
          resolve(conn);
        });
      });
    }

    function getMessages(db, params){
      return new Promise((resolve, reject) => {
        var query = {
          codename: params.codename,
          accessToken: params.accessToken
          };
        var projection = {_id: 0, messages: {$slice: [params.offset, params.count]}};
        db.collection('vaults').find(query, {projection: projection}).toArray((err, dbres) => {
          if(err){
            res.statusCode = 500;
            res.setHeader('Content-Type', 'text/plain');
            res.write('DB lookup error.');
            res.end();
            reject();
          }
          if(typeof dbres === 'undefined'){
            resolve({});
          } else if(dbres.length != 1){
            resolve({});
          } else {
            resolve(dbres[0].messages);
          }
        });
      });
    }

    var messages;
    try {
      await validate();
      var conn = await connectToDB();
      var db = conn.db('vault');
      messages = await getMessages(db, req.body);
      conn.close();
    } catch (err){
      if(conn) conn.close();
      return;
    }

    res.statusCode = 200;
    res.setHeader('Content-Type', 'application/json');
    res.write(JSON.stringify(messages));
    res.end();
});

app.post('/user/get/private', async (req, res) => {

  //Save user before the session is destroyed in auth()
  var username = req.session.user.name;

  var verified = await auth(req,res);
  if(!verified){
    return;
  }
  delete req.body.encryptedToken;
  var user;

  try {
    var conn = await connectToDB();
    var db = conn.db('vault');
    user = await getUser(db, username);
    user.vaults = await getUserVaults(db, username);
  } catch (err){
    if(conn) conn.close();
    return;
  }

  res.statusCode = 200;
  res.setHeader('Content-Type', 'text/json');
  res.write(JSON.stringify(user));
  res.end();

  function connectToDB(){
    return new Promise((resolve, reject) => {
      mongo.connect(url,
        {
          useNewUrlParser: true,
          useUnifiedTopology: true
        },
        (err, conn) => {
          if(err){
            res.statusCode = 500;
            res.setHeader('Content-Type', 'text/plain');
            res.write('DB connecting error.');
            res.end();
            reject();
          }
          resolve(conn);
        });
      });
    }

    function getUser(db, name){
      return new Promise((resolve, reject) => {
        var user = { name: name };
        var query = { name: user.name };
        db.collection('users').find(query).toArray((err, dbres) => {
          if(err){
            res.statusCode = 500;
            res.setHeader('Content-Type', 'text/plain');
            res.write('DB lookup error.');
            res.end();
            reject();
          }
          if(dbres.length != 1){
            res.statusCode = 400;
            res.setHeader('Content-Type', 'text/plain');
            res.write('User does not exist.');
            res.end();
            reject();
          } else {
            user = dbres[0];
            resolve(user);
          }
        });
      });
    }

    function getUserVaults(db, name){
      return new Promise((resolve, reject) => {
        var user = { name: name };
        var query = { keys: {$elemMatch: {user: user.name}}};
        var projection = {_id: 0, accessToken: 1, codename: 1};
        db.collection('vaults').find(query, {projection: projection}).toArray((err, dbres) => {
          if(err){
            res.statusCode = 500;
            res.setHeader('Content-Type', 'text/plain');
            res.write('DB lookup error.');
            res.end();
            reject();
          }
          resolve(dbres);
        });
      });
    }
});

app.post('/user/get/public', async (req, res) => {

  try {
    await validate();
    var conn = await connectToDB();
    var db = conn.db('vault');
    user = await getUser(db, req.body.name);
  } catch (err){
    if(conn) conn.close();
    return;
  }

  res.statusCode = 200;
  res.setHeader('Content-Type', 'text/json');
  res.write(JSON.stringify(user));
  res.end();

  function validate(){
    return new Promise((resolve, reject) => {
      if(Object.keys(req.body).length > 1){
        res.statusCode = 400;
        res.setHeader('Content-Type', 'text/plain');
        res.write('Too many arguments provided.');
        res.end();
        reject();
      }
      if(typeof req.body.name === 'undefined'){
        res.statusCode = 400;
        res.setHeader('Content-Type', 'text/plain');
        res.write('No name provided.');
        res.end();
        reject();
      }
      resolve();
    });
  }

  function connectToDB(){
    return new Promise((resolve, reject) => {
      mongo.connect(url,
        {
          useNewUrlParser: true,
          useUnifiedTopology: true
        },
        (err, conn) => {
          if(err){
            res.statusCode = 500;
            res.setHeader('Content-Type', 'text/plain');
            res.write('DB connecting error.');
            res.end();
            reject();
          }
          resolve(conn);
        });
      });
    }

    function getUser(db, name){
      return new Promise((resolve, reject) => {
        var user = { name: name };
        var query = { name: user.name };
        db.collection('users').find(query).toArray((err, dbres) => {
          if(err){
            res.statusCode = 500;
            res.setHeader('Content-Type', 'text/plain');
            res.write('DB lookup error.');
            res.end();
            reject();
          }
          if(dbres.length != 1){
            res.statusCode = 400;
            res.setHeader('Content-Type', 'text/plain');
            res.write('User does not exist.');
            res.end();
            reject();
          } else {
            var user = {
              name: dbres[0].name,
              rsa : {
                public: dbres[0].rsa.public
              }
            };
            resolve(user);
          }
        });
      });
    }

    function getUserVaults(db, name){
      return new Promise((resolve, reject) => {
        var user = { name: name };
        var query = { keys: {$elemMatch: {user: user.name}}};
        var projection = {_id: 0, accessToken: 1, codename: 1};
        db.collection('vaults').find(query, {projection: projection}).toArray((err, dbres) => {
          if(err){
            res.statusCode = 500;
            res.setHeader('Content-Type', 'text/plain');
            res.write('DB lookup error.');
            res.end();
            reject();
          }
          resolve(dbres);
        });
      });
    }
});

async function auth(req, res){
  if(!req.session.token || !req.session.user || !req.session.user.rsa){
    res.statusCode = 400;
    res.setHeader('Content-Type', 'text/plain');
    res.write('No token initialized.');
    res.end();
    return false;
  }
  if(!req.body.encryptedToken){
    res.statusCode = 400;
    res.setHeader('Content-Type', 'text/plain');
    res.write('No encrypted token provided.');
    res.end();
    return false;
  }
  var rsaKey = new RSA(req.session.user.rsa.public);
  var encryptedToken = Buffer.from(req.body.encryptedToken, 'hex');
  var decryptedToken = rsaKey.decryptPublic(encryptedToken);

  var verified = false;
  if(req.session.token == decryptedToken.toString('hex')){
    verified = true;
  }
  try {
    await new Promise((resolve, reject) => {
      req.session.destroy((err) => {
        if(err){
          res.statusCode = 500;
          res.setHeader('Content-Type', 'text/plain');
          res.write('Failed to destroy session.');
          res.end();
          reject();
        }
        resolve();
      });
    });
    if(verified){
      return true;
    } else {
      res.statusCode = 401;
      res.setHeader('Content-Type', 'text/plain');
      res.write('Authentication failed.');
      res.end();
    }
  } catch (err){

  }
}

var server = app.listen(8080);
