# SQL_Investigating-a-Drop-in-User-Engagement_different-version

--Returns first 100 rows from tutorial.yammer_events--
--Below the query that how many the column event_type data engagement has been collected within that period by week--
select date_trunc('week', e.occurred_at) as week, count(distinct user_id) as weekly_active_user
from tutorial.yammer_events e
where occurred_at between '2014-04-28 00:00:00' and '2014-08-25 23:59:59'
and e.event_type = 'engagement'
group by week
order by week

;

--Below the query that how many the users sign up without pending status within sepecific period by day--
select date_trunc('day', created_at) as signup_date, count(user_id) as signup_users, count(case when activated_at is not null then user_id else null end) as activated_users
from tutorial.yammer_users
where created_at between '2014-06-01 00:00:00' and '2014-08-31 23:59:59'
group by signup_date

;

--Below the query that how many the email server call action data had been collected withtin sepecific period by users --
select date_trunc('week', occurred_at) as week
      , action
      , count(distinct user_id) as cnt_user
from tutorial.yammer_emails
where occurred_at between '2014-04-28 00:00:00' and '2014-08-25 23:59:59'
group by week, action
;
select date_trunc('week', occurred_at) as week, 
count(case when action = 'sent_weekly_digest' then user_id else null end) as weekly_emails, 
count(case when action = 'sent_reengagement_email' then user_id else null end) as reengagement_emails, 
count(case when action = 'email_open' then user_id else null end) AS email_opens, 
count(case when action = 'email_clickthrough' then user_id else null end) as email_clickthroughs
from tutorial.yammer_emails
where occurred_at between '2014-04-28 00:00:00' and '2014-08-25 23:59:59'
group by week, action

;

--Below the query that each cohort analysis--
SELECT DATE_TRUNC('week',z.occurred_at) AS "week",
       AVG(z.age_at_event) AS "Average age during week",
       COUNT(DISTINCT CASE WHEN z.user_age > 70 THEN z.user_id ELSE NULL END) AS "10+ weeks",
       COUNT(DISTINCT CASE WHEN z.user_age < 70 AND z.user_age >= 63 THEN z.user_id ELSE NULL END) AS "9 weeks",
       COUNT(DISTINCT CASE WHEN z.user_age < 63 AND z.user_age >= 56 THEN z.user_id ELSE NULL END) AS "8 weeks",
       COUNT(DISTINCT CASE WHEN z.user_age < 56 AND z.user_age >= 49 THEN z.user_id ELSE NULL END) AS "7 weeks",
       COUNT(DISTINCT CASE WHEN z.user_age < 49 AND z.user_age >= 42 THEN z.user_id ELSE NULL END) AS "6 weeks",
       COUNT(DISTINCT CASE WHEN z.user_age < 42 AND z.user_age >= 35 THEN z.user_id ELSE NULL END) AS "5 weeks",
       COUNT(DISTINCT CASE WHEN z.user_age < 35 AND z.user_age >= 28 THEN z.user_id ELSE NULL END) AS "4 weeks",
       COUNT(DISTINCT CASE WHEN z.user_age < 28 AND z.user_age >= 21 THEN z.user_id ELSE NULL END) AS "3 weeks",
       COUNT(DISTINCT CASE WHEN z.user_age < 21 AND z.user_age >= 14 THEN z.user_id ELSE NULL END) AS "2 weeks",
       COUNT(DISTINCT CASE WHEN z.user_age < 14 AND z.user_age >= 7 THEN z.user_id ELSE NULL END) AS "1 week",
       COUNT(DISTINCT CASE WHEN z.user_age < 7 THEN z.user_id ELSE NULL END) AS "Less than a week"
  FROM (
        SELECT e.occurred_at,
               u.user_id,
               DATE_TRUNC('week',u.activated_at) AS activation_week,
               EXTRACT('day' FROM e.occurred_at - u.activated_at) AS age_at_event,
               EXTRACT('day' FROM '2014-09-01'::TIMESTAMP - u.activated_at) AS user_age
          FROM tutorial.yammer_users u
          JOIN tutorial.yammer_events e
            ON e.user_id = u.user_id
           AND e.event_type = 'engagement'
           AND e.event_name = 'login'
           AND e.occurred_at >= '2014-05-01'
           AND e.occurred_at < '2014-09-01'
         WHERE u.activated_at IS NOT NULL
       ) z
 GROUP BY week, user
 ORDER BY week, user
LIMIT 100

;

--Below the query that for each list data of the email data are engaging into DB within specific period--
select date_trunc('week', e1.occurred_at) as week
, count(case when e1.action = 'sent_weekly_digest' then e1.user_id else null end) as weekly_digest_email
, count(case when e1.action = 'sent_weekly_digest' then e2.user_id else null end) as weekly_digest_email_open
, count(case when e1.action = 'sent_weekly_digest' then e3.user_id else null end) as weekly_digest_email_clickthrough
from tutorial.yammer_emails e1
left join tutorial.yammer_emails e2
on e2.occurred_at between e1.occurred_at and e1.occurred_at + interval '5 minute'
and e2.user_id = e1.user_id
and e2.action = 'email_open'
left join tutorial.yammer_emails e3
on e3.occurred_at between e1.occurred_at and e1.occurred_at + interval '5 minute'
and e3.user_id = e1.user_id
and e3.action = 'email_clickthrough'
where e1.occurred_at between '2014-06-01 00:00:00' and '2014-08-31 23:59:59'
and e1.action in ('sent_weekly_digest', 'sent_reengagement_email')
group by week
;
--The below one is same query above one-- ----> In term of below query does not useful lose loading time or understanding people who barely got that
SELECT week,
       weekly_opens/CASE WHEN weekly_emails = 0 THEN 1 ELSE weekly_emails END::FLOAT AS weekly_open_rate,
       weekly_ctr/CASE WHEN weekly_opens = 0 THEN 1 ELSE weekly_opens END::FLOAT AS weekly_ctr,
       retain_opens/CASE WHEN retain_emails = 0 THEN 1 ELSE retain_emails END::FLOAT AS retain_open_rate,
       retain_ctr/CASE WHEN retain_opens = 0 THEN 1 ELSE retain_opens END::FLOAT AS retain_ctr
  FROM (
SELECT DATE_TRUNC('week',e1.occurred_at) AS week,
       COUNT(CASE WHEN e1.action = 'sent_weekly_digest' THEN e1.user_id ELSE NULL END) AS weekly_emails,
       COUNT(CASE WHEN e1.action = 'sent_weekly_digest' THEN e2.user_id ELSE NULL END) AS weekly_opens,
       COUNT(CASE WHEN e1.action = 'sent_weekly_digest' THEN e3.user_id ELSE NULL END) AS weekly_ctr,
       COUNT(CASE WHEN e1.action = 'sent_reengagement_email' THEN e1.user_id ELSE NULL END) AS retain_emails,
       COUNT(CASE WHEN e1.action = 'sent_reengagement_email' THEN e2.user_id ELSE NULL END) AS retain_opens,
       COUNT(CASE WHEN e1.action = 'sent_reengagement_email' THEN e3.user_id ELSE NULL END) AS retain_ctr
  FROM tutorial.yammer_emails e1
  LEFT JOIN tutorial.yammer_emails e2
    ON e2.occurred_at >= e1.occurred_at
   AND e2.occurred_at < e1.occurred_at + INTERVAL '5 MINUTE'
   AND e2.user_id = e1.user_id
   AND e2.action = 'email_open'
  LEFT JOIN tutorial.yammer_emails e3
    ON e3.occurred_at >= e2.occurred_at
   AND e3.occurred_at < e2.occurred_at + INTERVAL '5 MINUTE'
   AND e3.user_id = e2.user_id
   AND e3.action = 'email_clickthrough'
 WHERE e1.occurred_at >= '2014-06-01'
   AND e1.occurred_at < '2014-09-01'
   AND e1.action IN ('sent_weekly_digest','sent_reengagement_email')
 GROUP BY 1
       ) a
 ORDER BY 1

 --Below the query that for each device list data are engaging into DB by week--
  SELECT DATE_TRUNC('week', occurred_at) AS week,
       COUNT(DISTINCT e.user_id) AS weekly_active_users,
       COUNT(DISTINCT CASE WHEN e.device IN ('macbook pro','lenovo thinkpad','macbook air','dell inspiron notebook',
          'asus chromebook','dell inspiron desktop','acer aspire notebook','hp pavilion desktop','acer aspire desktop','mac mini')
          THEN e.user_id ELSE NULL END) AS computer,
       COUNT(DISTINCT CASE WHEN e.device IN ('iphone 5','samsung galaxy s4','nexus 5','iphone 5s','iphone 4s','nokia lumia 635',
       'htc one','samsung galaxy note','amazon fire phone') THEN e.user_id ELSE NULL END) AS phone,
        COUNT(DISTINCT CASE WHEN e.device IN ('ipad air','nexus 7','ipad mini','nexus 10','kindle fire','windows surface',
        'samsumg galaxy tablet') THEN e.user_id ELSE NULL END) AS tablet
  FROM tutorial.yammer_events e
 WHERE e.event_type = 'engagement'
   AND e.event_name = 'login'
 GROUP BY week
 ORDER BY week
LIMIT 100
