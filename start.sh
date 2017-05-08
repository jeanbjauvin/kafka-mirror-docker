#!/bin/bash -x

# This file is part of kafka-mirror-docker.
#
# kafka-mirror-docker is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# kafka-mirror-docker is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with kafka-mirror-docker.  If not, see <http://www.gnu.org/licenses/>.

# Checks if blacklist or whitelist should be used
# Either WHITELIST or BLACKLIST must be set in env
[ -z "$WHITELIST" ] && [ -z "$BLACKLIST" ] && { echo "Either whitelist or blakclist must be set"; exit -1; }

[ -n "$WHITELIST" ] && [ -n "$BLACKLIST" ] && { echo "Whitelist and Blacklist are mutually exclusive"; exit -1; }

# From that point on, it is known that either WHITELIST or BLACK LIST is set
[ -n "$WHITELIST" ] && LIST="--whitelist ${WHITELIST}"
[ -n "$BLACKLIST" ] && LIST="--blacklist ${BLACKLIST}"

# If a Kafka producer container is linked with the alias `kafka-producer`, use it.
# Otherwise, KAFKA_PRODUCER_IP must be set in env.
# Optionally, a KAFKA_PRODUCER_PORT can be set in env.
[ -n "$KAFKA-PRODUCER_PORT_9092_TCP_ADDR" ] && KAFKA_PRODUCER_IP=$KAFKA-PRODUCER_PORT_9092_TCP_ADDR
[ -n "$KAFKA-PRODUCER_PORT_9092_TCP_PORT" ] && KAFKA_PRODUCER_PORT=$KAFKA-PRODUCER_PORT_9092_TCP_PORT

# Concatenate ti IP and PORT for Kafka producer to allow setting a full connection
# string with multiple Kafka producer hosts
[ -z "$KAFKA_PRODUCER_CONNECTION_STRING" ] && KAFKA_PRODUCER_CONNECTION_STRING="${KAFKA_PRODUCER_IP}:${KAFKA_PRODUCER_PORT:-9092}"

# If a Kafka consumer container is linked with the alias `kafka-consumer`, use it.
# Otherwise, KAFKA_CONSUMER_IP must be set in env.
# Optionally, a KAFKA_CONSUMER_PORT can be set in env.
[ -n "$KAFKA-CONSUMER_PORT_9092_TCP_ADDR" ] && KAFKA_CONSUMER_IP=$KAFKA-CONSUMER_PORT_9092_TCP_ADDR
[ -n "$KAFKA-CONSUMER_PORT_9092_TCP_PORT" ] && KAFKA_CONSUMER_PORT=$KAFKA-CONSUMER_PORT_9092_TCP_PORT

IP=$(grep "\${HOSTNAME}" /etc/hosts | head -n 1 | awk '{print $1}')

# Concatenate ti IP and PORT for Kafka consumer to allow setting a full connection
# string with multiple Kafka consumer hosts
[ -z "$KAFKA_CONSUMER_CONNECTION_STRING" ] && KAFKA_CONSUMER_CONNECTION_STRING="${KAFKA_CONSUMER_IP}:${KAFKA_CONSUMER_PORT:-9092}"

cat /kafka/conf/consumer.properties.template | sed \
-e "s|{{KAFKA_CONSUMER_CONNECTION_STRING}}|${KAFKA_CONSUMER_CONNECTION_STRING}" \
-e "s|{{KAFKA_MIRROR_GROUP}}|${KAFKA_MIRROR_GROUP:-group1}"
> /kafka/conf/consumer.properties

cat /kafka/conf/producer.properties.template | sed \
-e "s|{{KAFKA_CONSUMER_CONNECTION_STRING}}|${KAFKA_CONSUMER_CONNECTION_STRING}"
> /kafka/conf/producer.properties

echo "Starting kafka"
exec /kafka/bin/kafka-mirror-maker.sh \
--consumer.config /conf/consumer.properties \
--producer.config /conf/producer.properties \
${LIST}
