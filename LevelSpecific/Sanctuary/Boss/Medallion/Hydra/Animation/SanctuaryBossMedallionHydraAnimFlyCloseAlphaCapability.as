class USanctuaryBossMedallionHydraAnimFlyCloseAlphaCapability : UHazeCapability
{
	ASanctuaryBossMedallionHydra Hydra;
	UMedallionPlayerReferencesComponent RefsComp;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Hydra = Cast<ASanctuaryBossMedallionHydra>(Owner);
		RefsComp = UMedallionPlayerReferencesComponent::GetOrCreate(Game::Mio);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (RefsComp.Refs == nullptr)
			return false;
		if (!RefsComp.Refs.IsInFlyingPhase(false, false, false))
			return false;
		if (Hydra.bDead)
			return false;
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (!RefsComp.Refs.IsInFlyingPhase(false, false, false))
			return true;
		if (Hydra.bDead)
			return true;
		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Hydra.AnimPlayerFlyingCloserAlpha = 0.0;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Hydra.AnimPlayerFlyingCloserAlpha = 0.0;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		float Dist = Hydra.ActorLocation.Dist2D(RefsComp.Refs.MedallionBossPlane2D.ActorLocation, FVector::UpVector);
		const float AlphaMinDist = 1000.0;
		const float AlphaMaxDist = 8000.0;
		Hydra.AnimPlayerFlyingCloserAlpha = Math::GetMappedRangeValueClamped(FVector2D(AlphaMinDist, AlphaMaxDist), FVector2D(0.0, 1.0), Dist);
	}
};