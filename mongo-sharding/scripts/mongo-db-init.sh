#!/bin/bash

docker compose exec -it configSrv mongosh --port 27019 <<EOF
rs.initiate(
  {
    _id : "config_server",
       configsvr: true,
    members: [
      { _id : 0, host : "configSrv:27019" }
    ]
  }
)
EOF

docker compose exec -it shard1 mongosh --port 27021 <<EOF
rs.initiate( { _id : "shard1", members: [ { _id : 0, host : "shard1:27021" } ] })
exit()
EOF

docker compose exec -it shard2 mongosh --port 27022 <<EOF
rs.initiate( { _id : "shard2", members: [ { _id : 1, host : "shard2:27022" } ] })
exit()
EOF


docker compose exec -it mongodb1 mongosh --port 27017 <<EOF
sh.addShard("shard1/shard1:27021");
sh.addShard("shard2/shard2:27022");

sh.enableSharding("somedb");
sh.shardCollection("somedb.helloDoc", { "name" : "hashed" } )
EOF

docker compose exec -it mongodb1 mongosh --port 27017 <<EOF
use somedb
for(var i = 0; i < 1000; i++) db.helloDoc.insert({age:i, name:"ly"+i});
db.helloDoc.countDocuments();
exit()
EOF


