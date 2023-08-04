import os
import time
import json
import redis
import ssl
import paho.mqtt.client as mqtt

mqtt_broker_address = os.getenv('MQTT_BROKER')
mqtt_broker_port = 8883
mqtt_topic = "firewalla-alarms"
mqtt_username = os.getenv('MQTT_USERNAME')
mqtt_password = os.getenv('MQTT_PASSWORD')
redis_host = 'localhost'
redis_port = 6379
ca_certs = "/etc/ssl/certs/ca-certificates.crt"

r = redis.Redis(host=redis_host, port=redis_port, decode_responses=True)

client = mqtt.Client("RedisAlarmMonitor")
client.username_pw_set(username=mqtt_username, password=mqtt_password)
client.tls_set(ca_certs=ca_certs, tls_version=ssl.PROTOCOL_TLS)
client.connect(mqtt_broker_address, port=mqtt_broker_port)

def publish_alarm(data):
    json_data = json.dumps(data)
    client.publish(mqtt_topic, json_data)

def check_alarms():
    keys = r.keys("_alarm*")
    
    for key in keys:
        # Retrieve all fields and values for the key
        alarm_data = r.hgetall(key)
        alarm_id = alarm_data['aid']

        # Check if alarm has already been sent over MQTT
        if not r.exists(f"mqtt_alarm_sent_{alarm_id}"):
            print(f"Publishing new alert {alarm_id}")
            # print(alarm_data)
            publish_alarm(alarm_data)
            r.set(f"mqtt_alarm_sent_{alarm_id}", "")

while True:
    check_alarms()
    time.sleep(1)

