#!/bin/bash
#Author: ming
#Create Date: 2024/01/25
#Last Modify Date: 2024/01/25
#Usage: ES 命令快捷脚本

case $1 in
	1)
		curl -XGET 'http://localhost:9300/_cluster/allocation/explain' -H "Content-Type: application/json" -d '
		{ 
			"index": "lp_base_info", 
			"shard": 0, 
			"primary": true 
		}' -u elastic | python -m json.tool
		;;
	2)
		curl -XGET  http://localhost:9300/_cat/shards?v -u elastic
		;;
	3)
		curl -XPUT "http://localhost:9300/_settings" -H "Content-Type: application/json" -d ' 
		{ 
			"index": {  
				"number_of_replicas": 0 
			} 
		}' -u elastic | python -m json.tool
		;;
	4)
		curl -XPOST "http://localhost:9300/_cluster/reroute" -H "Content-Type: application/json" -d ' 
		{ "commands" : [
			 {"allocate_stale_primary" :
				 {"index": "sharedb_cert_info_time_test","shard":1,"node": "node-1"}
			}
				]
		}' -u elastic | python -m json.tool
		;;
	5)
		curl -XGET "http://localhost:9300/_cluster/allocation/explain?pretty" | python -m json.tool
		;;
	6)
		curl -XPOST 'localhost:9300/_cluster/reroute' -H "Content-Type: application/json" -d '{
			    "commands": [{
				"allocate": {
				    "index": "$2",
				    "shard": 1,
				    "node": "node-1",
				    "allow_primary": 1
				}
			    }]
			}' -u elastic | python -m json.tool
		;;
	7)
		curl -XGET "http://localhost:9300/_cluster/settings" -u elastic | python -m json.tool
		;;
	8)
		curl -XPUT "http://localhost:9300/_cluster/settings" -H "Content-Type: application/json" -d '
		{
			"transient" : {
				"cluster.routing.allocation.enable" : "all"
			}
		}' -u elastic | python -m json.tool
		;;
	9)
		curl -XGET "http://localhost:9300/_cat/shards?v" -u elastic
		;;
	10)
		curl -XGET "http://localhost:9300/_cluster/health" -u elastic | python -m json.tool
		;;
	11)
		curl -XGET "http://localhost:9300/_snapshot/_all" -u elastic | python -m json.tool
		;;
	12)
		curl -XGET "http://localhost:9300/_snapshot/ming-restore/_all" -u elastic | python -m json.tool
		;;
	13)
		curl -XPOST "http://localhost:9300/_snapshot/ming-restore/$2/_restore" -u elastic | python -m json.tool\
		;;
	14)
		curl -XDELETE "http://localhost:9300/$2" -u elastic | python -m json.tool
		;;
	15)
		curl -XGET "http://localhost:9300/_cat/shards?v&h=index,shard,prirep,state,unassigned.reason" -u elastic
		;;
	16)
		curl -XPOST "http://localhost:9300/_snapshot/ming/$2/_restore" -u elastic | python -m json.tool
		;;
	17)
		curl -XGET "http://localhost:9300/_cat/indices?v" -u elastic
		;;
	18)
		curl -XGET "http://localhost:9300/_snapshot/ming/_all" -u elastic | python -m json.tool
		;;
	19)
		curl -XGET "http://localhost:9300/_snapshot/ming-restore/_all" -u elastic | python -m json.tool
		;;
	20)
		curl -XGET "http://localhost:9300/_snapshot/ming/$2" -u elastic | python -m json.tool
		;;
	21)
		curl -XPOST "http://localhost:9300/_snapshot/ming/snapshot-2024-01-24/_restore?wait_for_completion=true" -H "Content-Type: application/json" -d '
		{
			"indices":"'$2'"
		}' -u elastic | python -m json.tool
		
		;;
	22)
		curl -XPOST "http://localhost:9300/_snapshot/ming" -H "Content-Type: application/json" -d '
		{
			"type": "fs",
			"settings": {
				"location": "/home/dsp/help/snapshot"
			}
		}' -u elastic | python -m json.tool
		;;
	23)
		curl -XGET "http://localhost:9300/cert_join_lerep_test/_search" -u elastic
		;;
	?) 
		echo "Unkonwn"
		;;
esac
