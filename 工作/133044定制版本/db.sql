#统计哪些车辆的哪些告警信息有重复
select vehicle_id,alarm_type,count(*) as count from tb_alarm_linkage_down_setting group by vehicle_id,alarm_type having count(*) > 1 order by count;

#删除重复的数据，只保留ID最大的记录
delete from tb_alarm_linkage_down_setting where id in (select a.id from tb_alarm_linkage_down_setting a join (select vehicle_id,alarm_type, max(id) as retain_id from tb_alarm_linkage_down_setting group by vehicle_id,alarm_type having count(*) > 1) b on a.vehicle_id = b.vehicle_id and a.alarm_type = b.alarm_type and a.id <> b.retain_id)

#新增唯一索引
create unique index tb_alarm_linkage_down_setting_vehicle_id_alarm_type_uindex
    on tb_alarm_linkage_down_setting (vehicle_id, alarm_type);

#慢查询SQL优化
create index idx_company_id_source_type_state on t_download_task (company_id,state,source_type,start_time);
create index idx_company_id on t_evidence (vehicle_number,company_id,happen_time);
create index idx_online_time on t_vehicle_online_state (online_time);
create index idx_offline_time on t_vehicle_online_state (offline_time);