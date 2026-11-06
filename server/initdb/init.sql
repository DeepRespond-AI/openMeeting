-- openmeeting 微服务拆分后的数据库初始化（幂等，仅空数据卷首次启动时执行）
-- openmeeting_user 由 POSTGRES_DB 创建；这里补齐另外两个业务库。
CREATE DATABASE openmeeting_meeting;
CREATE DATABASE openmeeting_stt;
