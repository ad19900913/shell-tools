#!/bin/bash
scp upgrade.sh root@10.30.25.78:/iotp && ssh root@10.30.25.78 "chmod a+x /iotp/upgrade.sh"
scp upgrade.sql root@10.30.25.78:/iotp
scp rollback.sql root@10.30.25.78:/iotp
