class UBallistaHydraPlayerDeathCameraCapability : UHazePlayerCapability
{
	UMedallionPlayerReferencesComponent RefsComp;
	UBallistaHydraActorReferencesComponent BallistaRefsComp;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		RefsComp = UMedallionPlayerReferencesComponent::GetOrCreate(Player);
		BallistaRefsComp = UBallistaHydraActorReferencesComponent::GetOrCreate(Player);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (RefsComp.Refs == nullptr)
			return false;
		if (RefsComp.Refs.HydraAttackManager.Phase < EMedallionPhase::Ballista1)
			return false;
		if (RefsComp.Refs.HydraAttackManager.Phase > EMedallionPhase::BallistaPlayersAiming3)
			return false;
		if (BallistaRefsComp.Refs == nullptr)
			return false;
		if (BallistaRefsComp.Refs.MioDeathCamera == nullptr)
			return false;
		if (BallistaRefsComp.Refs.ZoeDeathCamera == nullptr)
			return false;
		if (!Player.IsPlayerDead())
			return false;
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (!Player.IsPlayerDead())
			return true;
		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		if (Player.IsMio())
			Player.ActivateCamera(BallistaRefsComp.Refs.MioDeathCamera, BallistaRefsComp.Refs.DeathCameraBlendInTime, this, EHazeCameraPriority::VeryHigh);
		else
			Player.ActivateCamera(BallistaRefsComp.Refs.ZoeDeathCamera, BallistaRefsComp.Refs.DeathCameraBlendInTime, this, EHazeCameraPriority::VeryHigh);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Player.DeactivateCameraByInstigator(this, 0.0);
	}
};