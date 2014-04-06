-- --------------------------------------------------------------------------------
-- Routine DDL
-- Note: comments before and after the routine body will not be stored by the server
-- --------------------------------------------------------------------------------
DELIMITER $$

CREATE DEFINER=`hop`@`%` PROCEDURE `list_all_files`(IN Arg INT)
BEGIN

DECLARE done INT DEFAULT FALSE;
DECLARE _id,_parent,_isDir,_isDel INT;
DECLARE _name VARCHAR(45);

#Select children which are not deleted or isDeleted=1;
DECLARE AL CURSOR FOR 
SELECT * FROM inodesN WHERE parent_id=Arg;

DECLARE DR CURSOR FOR
SELECT id FROM inodesN WHERE parent_id=Arg AND isDir=1;

DECLARE CONTINUE HANDLER FOR NOT FOUND SET done=TRUE;

OPEN AL;
	
	label1:LOOP

		FETCH AL INTO _id,_name,_parent,_isDir,_isDel;	
			
		IF done THEN
			LEAVE label1;
		END IF;
		
		SELECT _id,_name,_parent,_isDir,_isDel;

	END LOOP;

CLOSE AL;

SET done=FALSE;

#Call directories recursively.
OPEN DR;

	label2:LOOP
		
		FETCH DR INTO _id;
		
		IF done THEN
			LEAVE label2;
		END IF;

		CALL list_all_files(_id);
	END LOOP;

CLOSE DR;


END
