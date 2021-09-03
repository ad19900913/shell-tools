#t_driver_face_compare_result增加evtId字段和索引
alter table baseplatform.`t_driver_face_compare_result` drop column IF EXISTS evt_id;
drop index IF EXISTS IDX_EVTID on baseplatform.t_driver_face_compare_result;

#t_alarm_config新增初始化配置
delete from freight.`t_alarm_config` where id = 35;

#t_multi_language新增初始化配置
delete from freight.`t_multi_language` where id = '3c0071631ab5486884e9cbe5dfbd4410';
delete from freight.`t_multi_language` where id = '63d34c5132044835a8a9439312f34d00';
delete from freight.`t_multi_language` where id = 'ef872612325a4749b6a912b9347ae4c0';
delete from freight.`t_multi_language` where id = 'f72a3cc4a91d42049c275a69aacd5d00';

#t_alarm_config新增初始化配置
delete from basealarm.`tb_alarm_config` where id = 117;

#tb_alarm_type_config新增初始化配置
delete from basealarm.`tb_alarm_type_config` where id = 187;

#tb_alarm_type_name_dimension新增初始化配置
delete from basealarm.tb_alarm_type_name_dimension where alarm_type = 96;

#basealarm合并2211补丁版本需要更新索引
drop index IF EXISTS `vid_uid_cid` on basealarm.tb_alarm_configure_value;
drop index IF EXISTS idx_starttime_create_time on basealarm.tb_alarm_record;
drop index IF EXISTS vehicle_id on basealarm.tb_alarm_linkage_down_setting;
