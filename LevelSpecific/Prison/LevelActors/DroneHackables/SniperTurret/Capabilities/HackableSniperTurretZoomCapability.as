class UHackableSniperTurretZoomCapability : UHazeCapability
{
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	default TickGroup = EHazeTickGroup::Gameplay;
	default TickGroupOrder = 140;

	AHackableSniperTurret SniperTurret;
	AHazePlayerCharacter Player;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		SniperTurret = Cast<AHackableSniperTurret>(Owner);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (!SniperTurret.HijackTargetableComp.IsHijacked())
			return false;

		if(SniperTurret.ZoomAlpha.Value < KINDA_SMALL_NUMBER)
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (!SniperTurret.HijackTargetableComp.IsHijacked())
			return true;

		if(SniperTurret.ZoomAlpha.Value < KINDA_SMALL_NUMBER)
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Player = SniperTurret.HijackTargetableComp.GetHijackPlayer();

		SniperTurret.bIsZooming = true;
		SniperTurret.OnSniperTurretStartZoom.Broadcast();
		SniperTurret.bHasZoomed = true;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		SniperTurret.bIsZooming = false;
		SniperTurret.OnSniperTurretEndZoom.Broadcast();

		UCameraSettings::GetSettings(Player).FOV.Clear(this);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		const float FOV = Math::Lerp(SniperTurret.AimFOV, SniperTurret.ZoomedFOV, SniperTurret.ZoomAlpha.Value);
		UCameraSettings::GetSettings(Player).FOV.Apply(FOV, this, Priority = EHazeCameraPriority::Medium);
	}
}