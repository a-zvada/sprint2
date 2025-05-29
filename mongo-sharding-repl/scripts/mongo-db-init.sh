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
rs.initiate(
    { _id : "shard1",
    members: [
        { _id : 0, host : "shard1:27021" },
        { _id : 1, host : "shard1_r1:27022" },
        { _id : 2, host : "shard1_r2:27023" }
    ] });
exit()
EOF

docker compose exec -it shard2 mongosh --port 27031 <<EOF
rs.initiate(
    { _id : "shard2",
    members: [
        { _id : 0, host : "shard2:27031" },
        { _id : 1, host : "shard2_r1:27032" },
        { _id : 2, host : "shard2_r2:27033" }
    ]});
exit()
EOF


docker compose exec -it mongodb1 mongosh --port 27017 <<EOF
sh.addShard("shard1/shard1:27021,shard1_r1:27022,shard1_r2:27023");
sh.addShard("shard2/shard2:27031,shard2_r1:27032,shard2_r2:27033");

sh.enableSharding("somedb");
sh.shardCollection("somedb.helloDoc", { "name" : "hashed" } )
EOF

docker compose exec -it mongodb1 mongosh --port 27017 <<EOF
use somedb
for(var i = 0; i < 1000; i++) db.helloDoc.insert({age:i, name:"ly"+i});
db.helloDoc.getShardDistribution();
exit()
EOF


