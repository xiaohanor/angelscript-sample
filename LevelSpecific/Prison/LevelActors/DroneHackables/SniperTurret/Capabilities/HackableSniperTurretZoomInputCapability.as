class UHackableSniperTurretZoomInputCapability : UHazeCapability
{
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;
	
	default TickGroup = EHazeTickGroup::Input;
	default TickGroupOrder = 100;

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

		if(!IsActioning(ActionNames::SecondaryLevelAbility))
			return false;

		// Wait until the FOV blendtime has finished in OnActivated
		if(SniperTurret.HackedDuration < SniperTurret.FOV_BLENDTIME)
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
        if (!SniperTurret.HijackTargetableComp.IsHijacked())
            return true;

        if(!IsActioning(ActionNames::SecondaryLevelAbility))
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Player = SniperTurret.HijackTargetableComp.GetHijackPlayer();
		UHackableSniperTurretEventHandler::Trigger_OnZoomActivated(SniperTurret);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		UHackableSniperTurretEventHandler::Trigger_OnZoomDeactivated(SniperTurret);
	}

	UFUNCTION(BlueprintOverride)
	void PreTick(float DeltaTime)
	{
		// Get if we should zoom or not
		float ZoomTargetAlpha = IsActive() ? 1 : 0;

		// Smoothly accelerate zoom alpha towards the target
		SniperTurret.ZoomAlpha.AccelerateTo(ZoomTargetAlpha, 1.0, DeltaTime);
	}
}