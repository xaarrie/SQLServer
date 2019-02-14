--IT SHOWS HOW MANY EVENTS HAS THE RING BUFFER REGISTERED AND HOW MANY DEADLOCKS
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
SELECT
    ring_buffer_event_count, 
    event_deadlock
FROM
(    SELECT target_data.value('(RingBufferTarget/@eventCount)[1]', 'int') AS ring_buffer_event_count,
        target_data.value('count(RingBufferTarget/event[@name="xml_deadlock_report"])', 'int') as event_deadlock
    FROM
    (    SELECT CAST(target_data AS XML) AS target_data  
        FROM sys.dm_xe_sessions as s
        INNER JOIN sys.dm_xe_session_targets AS st 
            ON s.address = st.event_session_address
        WHERE s.name = N'system_health'
            AND st.target_name = N'ring_buffer'    ) AS n    ) AS t;