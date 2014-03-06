-- --------------------------------------------------------------------------------
-- Routine DDL
-- Note: comments before and after the routine body will not be stored by the server
-- --------------------------------------------------------------------------------
DELIMITER $$

CREATE DEFINER=`hop`@`%` PROCEDURE `list_files`(IN stime  INT, IN Arg INT)
BEGIN
DECLARE done1 INT DEFAULT FALSE;
DECLARE done2 INT DEFAULT FALSE;
DECLARE _i1,_i2,_i3,_i4,_i5,_i6 INT;

DECLARE _id,_parent,_isdir,_isdel INT;
DECLARE  _name ,_c1,_c2 VARCHAR(50);


#DECLARE Arg INT default 4;
#DECLARE stime INT default 5;


DECLARE CL  CURSOR FOR 
SELECT ndes.*,t2.original_row AS mdr, t2.time AS mdt 
FROM(
SELECT nodes.* FROM 

(SELECT inodes.* FROM inodes WHERE parent_id=Arg) AS nodes LEFT JOIN
( 
(SELECT Created_Inode_id AS inode_id  FROM clist WHERE Inode_id=Arg AND time>stime ) 
	UNION
	(SELECT deleted_inode_id AS inode_id FROM dlist WHERE Inode_id=Arg AND time<stime) 
	UNION
	(SELECT DISTINCT moved_in_inode_id AS inode_id  FROM mvinlist WHERE Inode_id = Arg AND time>stime)
 ) AS set1
ON nodes.id=set1.inode_id
WHERE set1.inode_id IS NULL
) AS ndes

LEFT JOIN

(select m1.*
from mlist AS m1 INNER JOIN
(
Select modified_inode_id,Min(time) As time
FROM mlist
WHERE Inode_Id=Arg AND time>stime
GROUP BY Modified_Inode_Id
) AS m2
ON m1.Modified_Inode_Id=m2.modified_inode_id AND m1.time = m2.time
WHERE m1.Inode_Id=Arg) AS t2  
 
ON ndes.id = t2.modified_inode_id;



DECLARE CL2 CURSOR FOR
SELECT ndes.moved_inode_id,ndes.time,ndes.original_row,t2.original_row, t2.time
FROM
(

SELECT mvd.*
FROM(

select m1.*
from mvlist AS m1 INNER JOIN
(
Select moved_inode_id,Min(time) As time
FROM mvlist
WHERE Inode_Id=Arg AND time>stime
GROUP BY moved_inode_id
) AS m2
ON m1.moved_inode_id=m2.moved_inode_id AND m1.time = m2.time
WHERE m1.Inode_Id=Arg

) AS mvd

LEFT JOIN

(

select m1.*
from mvinlist AS m1 INNER JOIN
(
Select moved_in_inode_id,Min(time) As time
FROM mvinlist
WHERE Inode_Id=Arg AND time>stime
GROUP BY moved_in_inode_id
) AS m2
ON m1.moved_in_inode_id=m2.moved_in_inode_id AND m1.time = m2.time
WHERE m1.Inode_Id=Arg

) AS mvdin

ON mvd.moved_inode_id = mvdin.moved_in_inode_id AND mvd.time < mvdin.time

) AS ndes

LEFT JOIN 

(

select m1.*
from mlist AS m1 INNER JOIN
(
Select modified_inode_id,Min(time) As time
FROM mlist
WHERE Inode_Id=Arg AND time>stime
GROUP BY Modified_Inode_Id
) AS m2
ON m1.Modified_Inode_Id=m2.modified_inode_id AND m1.time = m2.time
WHERE m1.Inode_Id=Arg

) AS t2  
 
ON ndes.moved_inode_id = t2.modified_inode_id;



DECLARE CONTINUE HANDLER FOR NOT FOUND SET done1 = TRUE;
#DECLARE CONTINUE HANDLER FOR NOT FOUND SET done2 = TRUE;

OPEN CL;

	label1: LOOP
		FETCH CL INTO _id,_name,_parent,_isdir,_isdel,_c1,_i1;
		IF done1 THEN
			LEAVE label1;
		END IF;

		IF _i1 IS NULL THEN
			IF _isdir =1 THEN
			  select _id,_name,_parent_isdir,_is_del;
			  call list_files(stime,_id);
			ELSE
			    select _id,_name,_parent_isdir,_is_del;
			END IF;
		
		ELSE
			select _c1;
		END IF;			  					
	
	END LOOP;

CLOSE CL;

SET done1=FALSE;

OPEN CL2;
#ndes.moved_inode_id,ndes.time,ndes.original_row,t2.original_row, t2.time
	label2: LOOP
		FETCH CL2 INTO _i1,_i2,_c1,_c2,_i3;
		IF done1 THEN
			LEAVE label2;
		END IF;
# If moved time is greater than modified time means, the child was modified first and then moved.
		IF _i3 IS NULL THEN
            SELECT _c1;
		ELSEIF _i2>_i3 THEN
			SELECT _c1;
		ELSE
			SELECT _c2;
		END IF;

	END LOOP;


CLOSE CL2;

END
