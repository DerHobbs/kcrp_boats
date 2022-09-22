CREATE TABLE IF NOT EXISTS `boates` (
  `identifier` varchar(40) NOT NULL,
  `charid` int(11) NOT NULL,
  `name` varchar(255) NOT NULL,
  `boat` varchar(255) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8;