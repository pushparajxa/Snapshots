CREATE PROCEDURE ls (SnapShotId IN CHAR, Arg IN BIGINT(20))  IS
 
DECLARE
stime INT;

DECLARE CURSOR CL IS
 
SELECT t1.* , t2.original_row AS mdr, t2.time mdt
FROM
 
(SELECT  inodes.* FROM inodes WHERE parent_id=Arg
MINUS
SELECT Created_Inode_id FROM c-list WHERE Inode_id=Arg AND time>stime    
MINUS  
SELECT deleted_inode_id FROM d-list WHERE Inode_id=Arg AND time<stime
MINUS
SELECT DISTINCT moved_in_inode_id FROM mv_in-list WHERE Inode_id = Arg AND time>stime ) AS t1
 
LEFT JOIN  
 
(SELECT m1.Original_row AS original_row , m1.Modified_inode_id,m1.time AS time As modified_inode_id FROM m-list AS m1 INNER JOIN m-list AS m2 ON m1.Inode_Id = m2.Inode_Id  
    AND m1.Modified_Inode_Id= m2.Modified_Inode_Id AND m1.time<m2.time AND m1.Inode_Id=Arg  
    AND m2.Inode_Id=Arg AND m1.time>stime AND m2.time>stime) AS t2  
 
ON t1.inode_id = t2.modified_inode_id


CREATE CURSOR R1 IS
 
SELECT m5.moved_inode_id AS id ,m5.original_row AS mvd ,m5.time AS mvt,m6.time AS mdt ,m6.original_row AS md
 
(SELECT m3.a AS moved_inode_id , m3.b AS original_row , m3.c AS time, m3.d AS Inode_Id
 
FROM
    (SELECT m1.moved_inode_id AS a,m1.original_row AS b, m1.time AS c ,m1.Inode_id AS d FROM mv_list AS m1 INNER JOIN mov_list AS m2 ON m1.Inode_Id = m2.Inode_Id  
    AND m1.moved_inode_id= m2.moved_inode_id AND m1.time<m2.time AND m1.Inode_Id=Arg  
    AND m2.Inode_Id=Arg AND m1.time>stime AND m2.time>stime ) AS m3  

    LEFT  JOIN ON  
 
    (SELECT m1.moved_in_inode_id AS a , m1.time AS c FROM mov_in_list AS m1 INNER JOIN mov_in_list AS m2 ON m1.Inode_Id = m2.Inode_Id  
    AND m1.moved_in_inode_id= m2.moved_in_inode_id AND m1.time<m2.time AND m1.Inode_Id=Arg  
    AND m2.Inode_Id=Arg AND m1.time>stime AND m2.time>stime
    ) AS m4  
 
    ON m3.a=m4.a AND m3.c<m4.c
) AS m5  
 
LEFT JOIN  
 
    (SELECT m1.Inode_id AS Inode_Id , m1.Original_row AS original_row , m1.Modified_inode_id,m1.time AS time As modified_inode_id FROM m-list AS m1 INNER JOIN m-list AS m2 ON m1.Inode_Id = m2.Inode_Id  
    AND m1.Modified_Inode_Id= m2.Modified_Inode_Id AND m1.time<m2.time AND m1.Inode_Id=Arg  
    AND m2.Inode_Id=Arg AND m1.time>stime AND m2.time>stime ) AS m6
 
 ON m5.moved_inode_id = m6.modified_inode_id  AND m5.Inode_id = m6.Inode_Id


 
BEGIN 

#Now check whether the inode was modified

FOR rec in CL LOOP
 
 IF t2.time!=NULL THEN
  IF t2.original_row.isDir==false THEN
    #display t2.orginal_row  
  ELSE
    #display t2.orinal_row
    ls(SnapshotId,t1.id)   
 ELSE #It means this inode was not modified.
    IF t1.original_row.isDir==false THEN
    #display t1.*  
    ELSE
    #display t1.orinal_row
    ls(SnapshotId,t1.id)
 
 END ID
 
END LOOP


FOR rec in R1 LOOP
# If moved time is greater than modified time means, the child was modified first and then moved.
IF rec.mvt > rec.mdt THEN
  IF rec.md.isDir == false THEN
      #Print the file
  ELSE
     #Print the directory name, permission etc..from rec.md
     ls(SnapShotID,rec.id)
  END IF
ELSE
  IF rec.mvd.isDir == false THEN
      #Print the file
  ELSE
     #Print the directory name, permission etc..from rec.mvd
     ls(SnapShotID,rec.id)
  END IF
 
 
END LOOP;

END


