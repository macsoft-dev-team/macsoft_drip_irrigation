-- CreateTable
CREATE TABLE `users` (
    `id` BIGINT NOT NULL AUTO_INCREMENT,
    `name` VARCHAR(150) NOT NULL,
    `phone` VARCHAR(20) NOT NULL,
    `email` VARCHAR(150) NULL,
    `passwordHash` VARCHAR(255) NOT NULL,
    `role` ENUM('farmer', 'admin', 'distributor', 'technician') NOT NULL,
    `status` ENUM('active', 'blocked', 'deleted') NOT NULL DEFAULT 'active',
    `createdAt` DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
    `updatedAt` DATETIME(3) NOT NULL,

    UNIQUE INDEX `users_phone_key`(`phone`),
    UNIQUE INDEX `users_email_key`(`email`),
    PRIMARY KEY (`id`)
) DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

-- CreateTable
CREATE TABLE `farmers` (
    `id` BIGINT NOT NULL AUTO_INCREMENT,
    `userId` BIGINT NOT NULL,
    `distributorId` BIGINT NULL,
    `address` TEXT NULL,
    `village` VARCHAR(150) NULL,
    `district` VARCHAR(150) NULL,
    `state` VARCHAR(150) NULL,
    `pincode` VARCHAR(20) NULL,
    `createdAt` DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
    `updatedAt` DATETIME(3) NOT NULL,

    UNIQUE INDEX `farmers_userId_key`(`userId`),
    INDEX `farmers_distributorId_idx`(`distributorId`),
    PRIMARY KEY (`id`)
) DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

-- CreateTable
CREATE TABLE `distributors` (
    `id` BIGINT NOT NULL AUTO_INCREMENT,
    `userId` BIGINT NOT NULL,
    `businessName` VARCHAR(200) NOT NULL,
    `gstNumber` VARCHAR(50) NULL,
    `address` TEXT NULL,
    `status` ENUM('active', 'blocked', 'deleted') NOT NULL DEFAULT 'active',
    `createdAt` DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
    `updatedAt` DATETIME(3) NOT NULL,

    UNIQUE INDEX `distributors_userId_key`(`userId`),
    PRIMARY KEY (`id`)
) DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

-- CreateTable
CREATE TABLE `fields` (
    `id` BIGINT NOT NULL AUTO_INCREMENT,
    `farmerId` BIGINT NOT NULL,
    `name` VARCHAR(150) NOT NULL,
    `locationName` VARCHAR(255) NULL,
    `latitude` DECIMAL(10, 7) NULL,
    `longitude` DECIMAL(10, 7) NULL,
    `areaAcres` DECIMAL(10, 2) NULL,
    `status` ENUM('active', 'inactive') NOT NULL DEFAULT 'active',
    `createdAt` DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
    `updatedAt` DATETIME(3) NOT NULL,

    INDEX `fields_farmerId_idx`(`farmerId`),
    PRIMARY KEY (`id`)
) DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

-- CreateTable
CREATE TABLE `masterControllers` (
    `id` BIGINT NOT NULL AUTO_INCREMENT,
    `fieldId` BIGINT NOT NULL,
    `deviceUid` VARCHAR(100) NOT NULL,
    `imei` VARCHAR(50) NULL,
    `simNumber` VARCHAR(30) NULL,
    `firmwareVersion` VARCHAR(50) NULL,
    `connectionType` ENUM('gsm4g','gsm5g', 'wifi', 'loraGateway') NOT NULL DEFAULT 'gsm4g',
    `status` ENUM('online', 'offline', 'error', 'disabled') NOT NULL DEFAULT 'offline',
    `lastHeartbeatAt` DATETIME(3) NULL,
    `lastIp` VARCHAR(100) NULL,
    `installedAt` DATETIME(3) NULL,
    `createdAt` DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
    `updatedAt` DATETIME(3) NOT NULL,

    UNIQUE INDEX `masterControllers_fieldId_key`(`fieldId`),
    UNIQUE INDEX `masterControllers_deviceUid_key`(`deviceUid`),
    INDEX `masterControllers_status_idx`(`status`),
    INDEX `masterControllers_lastHeartbeatAt_idx`(`lastHeartbeatAt`),
    PRIMARY KEY (`id`)
) DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

-- CreateTable
CREATE TABLE `zones` (
    `id` BIGINT NOT NULL AUTO_INCREMENT,
    `fieldId` BIGINT NOT NULL,
    `name` VARCHAR(150) NOT NULL,
    `description` TEXT NULL,
    `status` ENUM('active', 'inactive') NOT NULL DEFAULT 'active',
    `createdAt` DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
    `updatedAt` DATETIME(3) NOT NULL,

    INDEX `zones_fieldId_idx`(`fieldId`),
    PRIMARY KEY (`id`)
) DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

-- CreateTable
CREATE TABLE `valves` (
    `id` BIGINT NOT NULL AUTO_INCREMENT,
    `zoneId` BIGINT NOT NULL,
    `deviceUid` VARCHAR(100) NOT NULL,
    `name` VARCHAR(150) NOT NULL,
    `valveNumber` INTEGER NOT NULL,
    `status` ENUM('open', 'closed', 'unknown', 'error', 'disabled') NOT NULL DEFAULT 'unknown',
    `lastStatusAt` DATETIME(3) NULL,
    `installedAt` DATETIME(3) NULL,
    `createdAt` DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
    `updatedAt` DATETIME(3) NOT NULL,

    UNIQUE INDEX `valves_deviceUid_key`(`deviceUid`),
    INDEX `valves_zoneId_idx`(`zoneId`),
    UNIQUE INDEX `valves_zoneId_valveNumber_key`(`zoneId`, `valveNumber`),
    PRIMARY KEY (`id`)
) DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

-- CreateTable
CREATE TABLE `commands` (
    `id` BIGINT NOT NULL AUTO_INCREMENT,
    `commandUid` VARCHAR(100) NOT NULL,
    `farmerId` BIGINT NOT NULL,
    `fieldId` BIGINT NOT NULL,
    `masterControllerId` BIGINT NOT NULL,
    `requestedByUserId` BIGINT NOT NULL,
    `targetType` ENUM('valve', 'zone', 'field') NOT NULL,
    `targetId` BIGINT NOT NULL,
    `action` ENUM('open', 'close') NOT NULL,
    `status` ENUM('created', 'queued', 'sent', 'partialSuccess', 'acknowledged', 'failed', 'timeout', 'expired') NOT NULL DEFAULT 'created',
    `source` ENUM('app', 'adminPanel', 'schedule', 'support', 'deviceHttp') NOT NULL DEFAULT 'app',
    `retryCount` INTEGER NOT NULL DEFAULT 0,
    `maxRetries` INTEGER NOT NULL DEFAULT 3,
    `expiresAt` DATETIME(3) NULL,
    `sentAt` DATETIME(3) NULL,
    `acknowledgedAt` DATETIME(3) NULL,
    `failedReason` TEXT NULL,
    `createdAt` DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
    `updatedAt` DATETIME(3) NOT NULL,

    UNIQUE INDEX `commands_commandUid_key`(`commandUid`),
    INDEX `commands_farmerId_createdAt_idx`(`farmerId`, `createdAt`),
    INDEX `commands_masterControllerId_status_idx`(`masterControllerId`, `status`),
    INDEX `commands_status_expiresAt_idx`(`status`, `expiresAt`),
    PRIMARY KEY (`id`)
) DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

-- CreateTable
CREATE TABLE `commandItems` (
    `id` BIGINT NOT NULL AUTO_INCREMENT,
    `commandId` BIGINT NOT NULL,
    `valveId` BIGINT NOT NULL,
    `sequenceNumber` INTEGER NOT NULL,
    `action` ENUM('open', 'close') NOT NULL,
    `status` ENUM('pending', 'sent', 'acknowledged', 'failed', 'timeout', 'skipped') NOT NULL DEFAULT 'pending',
    `sentAt` DATETIME(3) NULL,
    `acknowledgedAt` DATETIME(3) NULL,
    `failedReason` TEXT NULL,
    `createdAt` DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
    `updatedAt` DATETIME(3) NOT NULL,

    INDEX `commandItems_commandId_idx`(`commandId`),
    INDEX `commandItems_valveId_idx`(`valveId`),
    UNIQUE INDEX `commandItems_commandId_valveId_key`(`commandId`, `valveId`),
    PRIMARY KEY (`id`)
) DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

-- CreateTable
CREATE TABLE `masterHeartbeats` (
    `id` BIGINT NOT NULL AUTO_INCREMENT,
    `masterControllerId` BIGINT NOT NULL,
    `signalStrength` INTEGER NULL,
    `batteryVoltage` DECIMAL(6, 2) NULL,
    `powerSource` ENUM('mainPower', 'battery', 'solar') NULL,
    `firmwareVersion` VARCHAR(50) NULL,
    `rawPayload` JSON NULL,
    `createdAt` DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),

    INDEX `masterHeartbeats_masterControllerId_createdAt_idx`(`masterControllerId`, `createdAt`),
    PRIMARY KEY (`id`)
) DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

-- CreateTable
CREATE TABLE `valveStatusLogs` (
    `id` BIGINT NOT NULL AUTO_INCREMENT,
    `valveId` BIGINT NOT NULL,
    `commandId` BIGINT NULL,
    `oldStatus` ENUM('open', 'closed', 'unknown', 'error', 'disabled') NULL,
    `newStatus` ENUM('open', 'closed', 'unknown', 'error', 'disabled') NOT NULL,
    `source` ENUM('masterController', 'appCommand', 'adminCommand', 'schedule', 'support') NOT NULL,
    `rawPayload` JSON NULL,
    `createdAt` DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),

    INDEX `valveStatusLogs_valveId_createdAt_idx`(`valveId`, `createdAt`),
    INDEX `valveStatusLogs_commandId_idx`(`commandId`),
    PRIMARY KEY (`id`)
) DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

-- CreateTable
CREATE TABLE `irrigationSchedules` (
    `id` BIGINT NOT NULL AUTO_INCREMENT,
    `farmerId` BIGINT NOT NULL,
    `fieldId` BIGINT NOT NULL,
    `name` VARCHAR(150) NOT NULL,
    `targetType` ENUM('valve', 'zone', 'field') NOT NULL,
    `targetId` BIGINT NOT NULL,
    `action` ENUM('openThenClose') NOT NULL DEFAULT 'openThenClose',
    `startTime` VARCHAR(5) NOT NULL,
    `durationMinutes` INTEGER NOT NULL,
    `repeatType` ENUM('once', 'daily', 'weekly', 'customDays') NOT NULL DEFAULT 'daily',
    `repeatDays` JSON NULL,
    `status` ENUM('active', 'paused', 'deleted') NOT NULL DEFAULT 'active',
    `timezone` VARCHAR(80) NOT NULL DEFAULT 'Asia/Kolkata',
    `createdAt` DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
    `updatedAt` DATETIME(3) NOT NULL,

    INDEX `irrigationSchedules_farmerId_status_idx`(`farmerId`, `status`),
    INDEX `irrigationSchedules_fieldId_idx`(`fieldId`),
    PRIMARY KEY (`id`)
) DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

-- CreateTable
CREATE TABLE `scheduleRuns` (
    `id` BIGINT NOT NULL AUTO_INCREMENT,
    `scheduleId` BIGINT NOT NULL,
    `openCommandId` BIGINT NULL,
    `closeCommandId` BIGINT NULL,
    `status` ENUM('pending', 'running', 'completed', 'failed', 'skipped') NOT NULL DEFAULT 'pending',
    `scheduledFor` DATETIME(3) NOT NULL,
    `startedAt` DATETIME(3) NULL,
    `completedAt` DATETIME(3) NULL,
    `failedReason` TEXT NULL,
    `createdAt` DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),

    INDEX `scheduleRuns_scheduleId_scheduledFor_idx`(`scheduleId`, `scheduledFor`),
    PRIMARY KEY (`id`)
) DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

-- CreateTable
CREATE TABLE `products` (
    `id` BIGINT NOT NULL AUTO_INCREMENT,
    `name` VARCHAR(200) NOT NULL,
    `sku` VARCHAR(100) NOT NULL,
    `type` ENUM('masterController', 'valve', 'accessory', 'serviceFee') NOT NULL,
    `description` TEXT NULL,
    `price` DECIMAL(10, 2) NOT NULL,
    `status` ENUM('active', 'inactive') NOT NULL DEFAULT 'active',
    `createdAt` DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
    `updatedAt` DATETIME(3) NOT NULL,

    UNIQUE INDEX `products_sku_key`(`sku`),
    PRIMARY KEY (`id`)
) DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

-- CreateTable
CREATE TABLE `orders` (
    `id` BIGINT NOT NULL AUTO_INCREMENT,
    `farmerId` BIGINT NOT NULL,
    `distributorId` BIGINT NULL,
    `orderNumber` VARCHAR(100) NOT NULL,
    `subtotal` DECIMAL(10, 2) NOT NULL DEFAULT 0,
    `platformFee` DECIMAL(10, 2) NOT NULL DEFAULT 0,
    `taxAmount` DECIMAL(10, 2) NOT NULL DEFAULT 0,
    `totalAmount` DECIMAL(10, 2) NOT NULL DEFAULT 0,
    `paymentStatus` ENUM('pending', 'paid', 'failed', 'refunded') NOT NULL DEFAULT 'pending',
    `orderStatus` ENUM('created', 'confirmed', 'dispatched', 'delivered', 'cancelled') NOT NULL DEFAULT 'created',
    `createdAt` DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
    `updatedAt` DATETIME(3) NOT NULL,

    UNIQUE INDEX `orders_orderNumber_key`(`orderNumber`),
    INDEX `orders_farmerId_idx`(`farmerId`),
    INDEX `orders_distributorId_idx`(`distributorId`),
    PRIMARY KEY (`id`)
) DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

-- CreateTable
CREATE TABLE `orderItems` (
    `id` BIGINT NOT NULL AUTO_INCREMENT,
    `orderId` BIGINT NOT NULL,
    `productId` BIGINT NOT NULL,
    `quantity` INTEGER NOT NULL,
    `unitPrice` DECIMAL(10, 2) NOT NULL,
    `totalPrice` DECIMAL(10, 2) NOT NULL,
    `createdAt` DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),

    INDEX `orderItems_orderId_idx`(`orderId`),
    INDEX `orderItems_productId_idx`(`productId`),
    PRIMARY KEY (`id`)
) DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

-- CreateTable
CREATE TABLE `farmerServicePlans` (
    `id` BIGINT NOT NULL AUTO_INCREMENT,
    `farmerId` BIGINT NOT NULL,
    `planName` VARCHAR(150) NOT NULL,
    `billingType` ENUM('oneTime', 'monthly', 'yearly', 'bundled') NOT NULL DEFAULT 'bundled',
    `feeAmount` DECIMAL(10, 2) NOT NULL DEFAULT 0,
    `remoteSupportEnabled` BOOLEAN NOT NULL DEFAULT true,
    `monitoringEnabled` BOOLEAN NOT NULL DEFAULT true,
    `status` ENUM('active', 'expired', 'cancelled') NOT NULL DEFAULT 'active',
    `startsAt` DATETIME(3) NOT NULL,
    `endsAt` DATETIME(3) NULL,
    `createdAt` DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
    `updatedAt` DATETIME(3) NOT NULL,

    INDEX `farmerServicePlans_farmerId_status_idx`(`farmerId`, `status`),
    PRIMARY KEY (`id`)
) DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

-- CreateTable
CREATE TABLE `supportTickets` (
    `id` BIGINT NOT NULL AUTO_INCREMENT,
    `farmerId` BIGINT NOT NULL,
    `fieldId` BIGINT NULL,
    `masterControllerId` BIGINT NULL,
    `valveId` BIGINT NULL,
    `assignedToUserId` BIGINT NULL,
    `title` VARCHAR(200) NOT NULL,
    `description` TEXT NULL,
    `priority` ENUM('low', 'medium', 'high', 'critical') NOT NULL DEFAULT 'medium',
    `status` ENUM('open', 'inProgress', 'resolved', 'closed') NOT NULL DEFAULT 'open',
    `createdAt` DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
    `updatedAt` DATETIME(3) NOT NULL,

    INDEX `supportTickets_farmerId_status_idx`(`farmerId`, `status`),
    INDEX `supportTickets_assignedToUserId_idx`(`assignedToUserId`),
    PRIMARY KEY (`id`)
) DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

-- AddForeignKey
ALTER TABLE `farmers` ADD CONSTRAINT `farmers_userId_fkey` FOREIGN KEY (`userId`) REFERENCES `users`(`id`) ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE `farmers` ADD CONSTRAINT `farmers_distributorId_fkey` FOREIGN KEY (`distributorId`) REFERENCES `distributors`(`id`) ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE `distributors` ADD CONSTRAINT `distributors_userId_fkey` FOREIGN KEY (`userId`) REFERENCES `users`(`id`) ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE `fields` ADD CONSTRAINT `fields_farmerId_fkey` FOREIGN KEY (`farmerId`) REFERENCES `farmers`(`id`) ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE `masterControllers` ADD CONSTRAINT `masterControllers_fieldId_fkey` FOREIGN KEY (`fieldId`) REFERENCES `fields`(`id`) ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE `zones` ADD CONSTRAINT `zones_fieldId_fkey` FOREIGN KEY (`fieldId`) REFERENCES `fields`(`id`) ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE `valves` ADD CONSTRAINT `valves_zoneId_fkey` FOREIGN KEY (`zoneId`) REFERENCES `zones`(`id`) ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE `commands` ADD CONSTRAINT `commands_farmerId_fkey` FOREIGN KEY (`farmerId`) REFERENCES `farmers`(`id`) ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE `commands` ADD CONSTRAINT `commands_fieldId_fkey` FOREIGN KEY (`fieldId`) REFERENCES `fields`(`id`) ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE `commands` ADD CONSTRAINT `commands_masterControllerId_fkey` FOREIGN KEY (`masterControllerId`) REFERENCES `masterControllers`(`id`) ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE `commands` ADD CONSTRAINT `commands_requestedByUserId_fkey` FOREIGN KEY (`requestedByUserId`) REFERENCES `users`(`id`) ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE `commandItems` ADD CONSTRAINT `commandItems_commandId_fkey` FOREIGN KEY (`commandId`) REFERENCES `commands`(`id`) ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE `commandItems` ADD CONSTRAINT `commandItems_valveId_fkey` FOREIGN KEY (`valveId`) REFERENCES `valves`(`id`) ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE `masterHeartbeats` ADD CONSTRAINT `masterHeartbeats_masterControllerId_fkey` FOREIGN KEY (`masterControllerId`) REFERENCES `masterControllers`(`id`) ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE `valveStatusLogs` ADD CONSTRAINT `valveStatusLogs_valveId_fkey` FOREIGN KEY (`valveId`) REFERENCES `valves`(`id`) ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE `valveStatusLogs` ADD CONSTRAINT `valveStatusLogs_commandId_fkey` FOREIGN KEY (`commandId`) REFERENCES `commands`(`id`) ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE `irrigationSchedules` ADD CONSTRAINT `irrigationSchedules_farmerId_fkey` FOREIGN KEY (`farmerId`) REFERENCES `farmers`(`id`) ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE `irrigationSchedules` ADD CONSTRAINT `irrigationSchedules_fieldId_fkey` FOREIGN KEY (`fieldId`) REFERENCES `fields`(`id`) ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE `scheduleRuns` ADD CONSTRAINT `scheduleRuns_scheduleId_fkey` FOREIGN KEY (`scheduleId`) REFERENCES `irrigationSchedules`(`id`) ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE `scheduleRuns` ADD CONSTRAINT `scheduleRuns_openCommandId_fkey` FOREIGN KEY (`openCommandId`) REFERENCES `commands`(`id`) ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE `scheduleRuns` ADD CONSTRAINT `scheduleRuns_closeCommandId_fkey` FOREIGN KEY (`closeCommandId`) REFERENCES `commands`(`id`) ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE `orders` ADD CONSTRAINT `orders_farmerId_fkey` FOREIGN KEY (`farmerId`) REFERENCES `farmers`(`id`) ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE `orders` ADD CONSTRAINT `orders_distributorId_fkey` FOREIGN KEY (`distributorId`) REFERENCES `distributors`(`id`) ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE `orderItems` ADD CONSTRAINT `orderItems_orderId_fkey` FOREIGN KEY (`orderId`) REFERENCES `orders`(`id`) ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE `orderItems` ADD CONSTRAINT `orderItems_productId_fkey` FOREIGN KEY (`productId`) REFERENCES `products`(`id`) ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE `farmerServicePlans` ADD CONSTRAINT `farmerServicePlans_farmerId_fkey` FOREIGN KEY (`farmerId`) REFERENCES `farmers`(`id`) ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE `supportTickets` ADD CONSTRAINT `supportTickets_farmerId_fkey` FOREIGN KEY (`farmerId`) REFERENCES `farmers`(`id`) ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE `supportTickets` ADD CONSTRAINT `supportTickets_fieldId_fkey` FOREIGN KEY (`fieldId`) REFERENCES `fields`(`id`) ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE `supportTickets` ADD CONSTRAINT `supportTickets_masterControllerId_fkey` FOREIGN KEY (`masterControllerId`) REFERENCES `masterControllers`(`id`) ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE `supportTickets` ADD CONSTRAINT `supportTickets_valveId_fkey` FOREIGN KEY (`valveId`) REFERENCES `valves`(`id`) ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE `supportTickets` ADD CONSTRAINT `supportTickets_assignedToUserId_fkey` FOREIGN KEY (`assignedToUserId`) REFERENCES `users`(`id`) ON DELETE SET NULL ON UPDATE CASCADE;
