-- --------------------------------------------------------------------------------
-- Routine DDL
-- Note: comments before and after the routine body will not be stored by the server
-- --------------------------------------------------------------------------------
DELIMITER $$

 
CREATE DEFINER=`hop`@`%` PROCEDURE `list_files`(IN stime  INT, IN Arg INT)
BEGIN
DECLARE done INT DEFAULT FALSE;
DECLARE _i1,_i3,_i4,_i5 INT;
DECLARE _t1,_t2 INT;
DECLARE _id,_parent,_isDir,_isDel INT;
DECLARE  _name ,_c2 VARCHAR(50);


#DECLARE Arg INT default 4;
#DECLARE stime INT default 5;


DECLARE CL  CURSOR FOR 
SELECT ndes.*,t2.orig_Name,t2.orig_Parent_Id,t2.orig_isDir , t2.orig_isDeleted , t2.time
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
SELECT ndes.moved_inode_id,ndes.Orig_Name,ndes.orig_Parent_Id,ndes.Orig_isDir,ndes.Orig_isDeleted,
t2.Orig_Name,t2.orig_Parent_Id,t2.Orig_isDir,t2.Orig_isDeleted,ndes.time,t2.time
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



DECLARE CONTINUE HANDLER FOR NOT FOUND SET done = TRUE;

OPEN CL;

	label1: LOOP
		#SELECT ndes.*,t2.orig_Name,t2.orig_Parent_Id,t2.orig_isDir , t2.orig_isDelted , t2.time
		FETCH CL INTO _id,_name,_parent,_isDir,_isDel,_c2,_i3,_i4,_i5,_t1;
		
		IF done THEN
			LEAVE label1;
		END IF;

		IF _t1 IS NULL THEN
			IF _isDir =1 THEN
			  select _id,_name,_parent,_isDir,_isDel;
			  call list_files(stime,_id);
			ELSE
			    select _id,_name,_parent,_isDir,_isDel;
			END IF;
		
		ELSE #Take the modified fields
			IF _i4 =1 THEN #It is a directory.So call recursively.
			  select _id,_c2,_i3,_i4,_i5;
			  call list_files(stime,_id);
			ELSE
			   select _id,_c2,_i3,_i4,_i5;
			END IF;
		END IF;			  					
	
	END LOOP;

CLOSE CL;

SET done=FALSE;

OPEN CL2;
#SELECT ndes.moved_inode_id,ndes.Orig_Name,ndes.orig_Parent_Id,ndes.Orig_isDir,ndes.Orig_isDeleted,
#t2.Orig_Name,t2.orig_Parent_Id,t2.Orig_isDir,t2.Orig_isDeleted,ndes.time,t2.time
	label2: LOOP
		FETCH CL2 INTO _id,_name,_parent,_isDir,_isDel,_c2,_i3,_i4,_i5,_t1,_t2;
		IF done THEN
			LEAVE label2;
		END IF;
# If moved time is greater than modified time means, the child was modified first and then moved.
		IF _t2 IS NULL OR _t2>_t1 THEN 

			IF _isDir =1 THEN
			  SELECT _id,_name,_parent,_isDir,_isDel;
			  CALL list_files(stime,_id);
			ELSE
			    SELECT _id,_name,_parent,_isDir,_isDel;
			END IF;

		ELSE

			IF _i4 =1 THEN
				SELECT _id,_c2,_i3,_i4,_i5;
			    CALL list_files(stime,_id);
			ELSE
			    SELECT _id,_c2,_i3,_i4,_i5;
			END IF;

		END IF;

	END LOOP;


CLOSE CL2;

END
