#t_driver_face_compare_result增加evtId字段和索引
ALTER TABLE baseplatform.`t_driver_face_compare_result` ADD COLUMN evt_id varchar(100) DEFAULT NULL COMMENT '报警事件ID';
ALTER TABLE baseplatform.`t_driver_face_compare_result` ADD INDEX IDX_EVTID ( `evt_id` );

#t_alarm_config新增初始化配置
INSERT INTO freight.`t_alarm_config` VALUES (35, 2, 96, '人脸比对失败', 52, NULL, NULL, NULL, NULL, 0);

#t_multi_language新增初始化配置
INSERT INTO freight.`t_multi_language` VALUES ('3c0071631ab5486884e9cbe5dfbd4410', 'Web', 'pt_BR', '96', '', 'A comparação de rosto falhou', 0, '2021-08-30 08:40:41', '2021-08-30 08:40:41', NULL, 0);
INSERT INTO freight.`t_multi_language` VALUES ('63d34c5132044835a8a9439312f34d00', 'Web', 'es_ES', '96', '', 'La comparación de caras falló', 0, '2021-08-30 08:40:41', '2021-08-30 08:40:41', NULL, 0);
INSERT INTO freight.`t_multi_language` VALUES ('ef872612325a4749b6a912b9347ae4c0', 'Web', 'en_US', '96', '', 'Face comparison failed', 0, '2021-08-30 08:40:41', '2021-08-30 08:40:41', NULL, 0);
INSERT INTO freight.`t_multi_language` VALUES ('f72a3cc4a91d42049c275a69aacd5d00', 'Web', 'zh_CN', '96', '', '人脸比对失败', 0, '2021-08-30 08:40:41', '2021-08-30 08:40:41', NULL, 0);

#t_alarm_config新增初始化配置
INSERT INTO basealarm.`tb_alarm_config` VALUES (117, 1, 1, '96', 96, 'Face comparison failed', '人脸比对失败', '2021-08-30 10:48:44', 1, 'admin');

#tb_alarm_type_config新增初始化配置
INSERT INTO basealarm.`tb_alarm_type_config` VALUES (187, 1, 4, 96, '人脸比对失败', NULL, NULL);

#tb_alarm_type_name_dimension新增初始化配置
INSERT INTO basealarm.tb_alarm_type_name_dimension (app_id, link_id, link_type, alarm_type, type_name, level, category, create_time, update_time, creator_id, updater_id, creator, updater)
select 1, id, 2, 96, '人脸比对失败', 4, 1, now(), null, 141, null, 'streamax', null from baseplatform.t_company;

#basealarm合并2211补丁版本需要更新索引
alter table basealarm.tb_alarm_configure_value add index `vid_uid_cid` (`vehicle_id`,`user_id`,`config_id`);
alter table basealarm.tb_alarm_record add index idx_starttime_create_time (starttime,create_time);
create unique index vehicle_id on basealarm.tb_alarm_linkage_down_setting (vehicle_id, alarm_type);
drop index IF EXISTS appid_state_starttime on basealarm.tb_alarm_record;
drop index IF EXISTS starttime on basealarm.tb_alarm_record;
