#!/bin/bash
# Database backup script

pg_dump -U airea_user airea_db > backup_$(date +%Y%m%d_%H%M%S).sql

