-- --------------------------------------------------------------------------------
-- Routine DDL
-- Note: comments before and after the routine body will not be stored by the server
-- --------------------------------------------------------------------------------
DELIMITER $$

CREATE DEFINER=`hop`@`%` PROCEDURE `ls`(IN stime INT,IN Arg INT)
BEGIN
DECLARE done INT DEFAULT FALSE;
DECLARE _i1,_i3,_i4,_i5 INT;
DECLARE _t1,_t2 INT;
DECLARE _id,_parent,_isDir,_isDel INT;
DECLARE  _name ,_c2 VARCHAR(50);



DECLARE CL  CURSOR FOR 
SELECT ns.id AS Id , ns.name AS Name, ns.parent_id AS Parent_ID, ns.isDir AS IsDir,ns.isDeleted AS IsDeleted,
t2.orig_Name,t2.orig_Parent_Id,t2.orig_isDir , t2.orig_isDeleted ,ns.time,t2.time
FROM(

	(SELECT nodes.* ,4294967295 AS time 
		FROM 
		
		(SELECT inodesN.* FROM inodesN WHERE parent_id=Arg) AS nodes 
		
		LEFT JOIN
		( 
			(SELECT Created_Inode_id AS inode_id  FROM clist WHERE Inode_id=Arg AND time>stime ) 
			UNION
			(SELECT deleted_inode_id AS inode_id FROM dlist WHERE Inode_id=Arg AND time<stime) 
			UNION
			(SELECT DISTINCT moved_in_inode_id AS inode_id  FROM mvinlist WHERE Inode_id = Arg AND time>stime)
		) AS set1
		
		ON nodes.id=set1.inode_id
		WHERE set1.inode_id IS NULL
	) 
	
	UNION 

	(SELECT mvd.moved_inode_id,mvd.Orig_Name,mvd.orig_Parent_Id,mvd.Orig_isDir,mvd.Orig_isDeleted,mvd.time
	FROM
		(SELECT m1.*
		FROM 
			(SELECT * FROM mvlist WHERE  Inode_Id=Arg AND time>stime ) AS m1 

			INNER JOIN

			(SELECT moved_inode_id,Min(time) AS time 
			FROM 
				mvlist
			WHERE Inode_Id=Arg AND time>stime
			GROUP BY moved_inode_id
			) AS m2

		ON m1.moved_inode_id=m2.moved_inode_id AND m1.time = m2.time
		
	   ) AS mvd

		LEFT JOIN

		
		(SELECT moved_in_inode_id,Min(time) As time
			FROM 
				mvinlist
			WHERE Inode_Id=Arg AND time>stime
			GROUP BY moved_in_inode_id
			
		) AS mvdin

		ON mvd.moved_inode_id = mvdin.moved_in_inode_id AND mvd.time < mvdin.time
	)

) AS ns

LEFT JOIN

(SELECT  m1.*
FROM
	(SELECT * FROM mlist WHERE Inode_Id=Arg AND time>stime ) AS m1
	
	INNER JOIN
	(
		Select modified_inode_id,Min(time) As time
		FROM mlist
		WHERE Inode_Id=Arg AND time>stime
		GROUP BY Modified_Inode_Id
	) AS m2

	ON m1.Modified_Inode_Id=m2.modified_inode_id AND m1.time = m2.time

) AS t2  
 
ON ns.id = t2.modified_inode_id;


DECLARE CONTINUE HANDLER FOR NOT FOUND SET done = TRUE;



SET done=FALSE;



OPEN CL;
#SELECT ns.id AS Id , ns.name AS Name, ns.parent_id AS Parent_ID, ns.isDir AS IsDir,ns.isDeleted AS IsDeleted,
#t2.orig_Name,t2.orig_Parent_Id,t2.orig_isDir , t2.orig_isDeleted ,ns.time,t2.time
	label2: LOOP
		FETCH CL INTO _id,_name,_parent,_isDir,_isDel,_c2,_i3,_i4,_i5,_t1,_t2;
		IF done THEN
			LEAVE label2;
		END IF;
# If moved time is greater than modified time means, the child was modified first and then moved.
		IF _t2 IS NULL OR _t1<_t2 THEN 

			IF _isDir =1 THEN
			  SELECT _id,_name,_parent,_isDir,_isDel;
			  CALL ls(stime,_id);
			ELSE
			    SELECT _id,_name,_parent,_isDir,_isDel;
			END IF;

		ELSE

			IF _i4 =1 THEN
				SELECT _id,_c2,_i3,_i4,_i5;
			    CALL ls(stime,_id);
			ELSE
			    SELECT _id,_c2,_i3,_i4,_i5;
			END IF;

		END IF;

	END LOOP;


CLOSE CL;



END
