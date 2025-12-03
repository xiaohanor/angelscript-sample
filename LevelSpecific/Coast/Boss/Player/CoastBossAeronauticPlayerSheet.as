namespace CoastBossTags
{
	const FName CoastBossTag = n"CoastBoss";
	const FName CoastBossPlayerShootTag = n"CoastBossPlayerShoot";
	const FName CoastBossPowerUp = n"CoastBossPowerUp";
}

asset CoastBossAeronauticPlayerSheet of UHazeCapabilitySheet
{
	Capabilities.Add(UCoastBossAeronauticMoveTo2DPlanePlayerCapability);
	Capabilities.Add(UCoastBossAeronauticCameraPlayerCapability);
	Capabilities.Add(UCoastBossAeronauticMovementPlayerCapability);
	Capabilities.Add(UCoastBossAeronauticMoveToPortalPlayerCapability);
	Capabilities.Add(UCoastBossAeronauticDashCapability);

	Capabilities.Add(UCoastBossAeronauticAttachedToDroneCapability);
	Capabilities.Add(UCoastBossAeronauticInvulnerableCapability);
	Capabilities.Add(UCoastBossAeronauticDamageFeedbackCapability);
	Capabilities.Add(UCoastBossAeronauticShieldCapability);
	Capabilities.Add(UCoastBossAeronauticRegenerateShieldCapability);

	Capabilities.Add(UCoastBossAeronauticShootPlayerCapability);
	Capabilities.Add(UCoastBossAeronauticPlayerLaserPowerUpCapability);
	Capabilities.Add(UCoastBossAeronauticShootHomingPlayerCapability);
	Capabilities.Add(UCoastBossAeronauticHomingPowerUpCapability);
	Capabilities.Add(UCoastBossAeronauticPlayerMoveBulletsCapability);
	Capabilities.Add(UCoastBossAeronauticPlayerResolveDamageCapability);
	Capabilities.Add(UCoastBossAeronauticScaleDamagePlayerCapability);
	
}
