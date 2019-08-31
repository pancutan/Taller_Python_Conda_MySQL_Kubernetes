-- --------------------------------------------------------
-- Host:                         127.0.0.1
-- Versión del servidor:         10.4.6-MariaDB - Source distribution
-- SO del servidor:              Linux
-- HeidiSQL Versión:             9.5.0.5196
-- --------------------------------------------------------

/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET NAMES utf8 */;
/*!50503 SET NAMES utf8mb4 */;
/*!40014 SET @OLD_FOREIGN_KEY_CHECKS=@@FOREIGN_KEY_CHECKS, FOREIGN_KEY_CHECKS=0 */;
/*!40101 SET @OLD_SQL_MODE=@@SQL_MODE, SQL_MODE='NO_AUTO_VALUE_ON_ZERO' */;


-- Volcando estructura de base de datos para inventario
DROP DATABASE IF EXISTS `inventario`;
CREATE DATABASE IF NOT EXISTS `inventario` /*!40100 DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci */;
USE `inventario`;

-- Volcando estructura para tabla inventario.amigos
DROP TABLE IF EXISTS `amigos`;
CREATE TABLE IF NOT EXISTS `amigos` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `nombre` char(50) COLLATE utf8mb4_unicode_ci DEFAULT '0',
  `apellido` char(50) COLLATE utf8mb4_unicode_ci DEFAULT '0',
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=3 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Volcando datos para la tabla inventario.amigos: ~2 rows (aproximadamente)
/*!40000 ALTER TABLE `amigos` DISABLE KEYS */;
INSERT INTO `amigos` (`id`, `nombre`, `apellido`) VALUES
	(1, 'Juan', 'Perez'),
	(2, 'Pedro', 'Gimenez');
/*!40000 ALTER TABLE `amigos` ENABLE KEYS */;

-- Volcando estructura para tabla inventario.objetos
DROP TABLE IF EXISTS `objetos`;
CREATE TABLE IF NOT EXISTS `objetos` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `nombre` varchar(250) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=4 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Volcando datos para la tabla inventario.objetos: ~3 rows (aproximadamente)
/*!40000 ALTER TABLE `objetos` DISABLE KEYS */;
INSERT INTO `objetos` (`id`, `nombre`) VALUES
	(1, 'Libro Los Viajes de Tuf'),
	(2, 'DVD EL Señor de los Ladrillos'),
	(3, 'Revista n4 Electrónica');
/*!40000 ALTER TABLE `objetos` ENABLE KEYS */;

-- Volcando estructura para tabla inventario.prestamos
DROP TABLE IF EXISTS `prestamos`;
CREATE TABLE IF NOT EXISTS `prestamos` (
  `amigo_id` int(11) DEFAULT NULL,
  `objeto_id` int(11) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Volcando datos para la tabla inventario.prestamos: ~3 rows (aproximadamente)
/*!40000 ALTER TABLE `prestamos` DISABLE KEYS */;
INSERT INTO `prestamos` (`amigo_id`, `objeto_id`) VALUES
	(1, 1),
	(1, 2),
	(2, 3);
/*!40000 ALTER TABLE `prestamos` ENABLE KEYS */;

/*!40101 SET SQL_MODE=IFNULL(@OLD_SQL_MODE, '') */;
/*!40014 SET FOREIGN_KEY_CHECKS=IF(@OLD_FOREIGN_KEY_CHECKS IS NULL, 1, @OLD_FOREIGN_KEY_CHECKS) */;
/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
