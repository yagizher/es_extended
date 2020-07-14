CREATE TABLE `vehicles` (
	`id`INT(11) NOT NULL,
	`owner` VARCHAR(40) NOT NULL,
	`plate` VARCHAR(12) NOT NULL,
	`vehicle` LONGTEXT,
	`type` VARCHAR(20) NOT NULL DEFAULT 'car',
	`stored` TINYINT NOT NULL DEFAULT '0',

	PRIMARY KEY (`plate`)
);