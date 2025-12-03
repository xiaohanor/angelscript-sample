class UBallistaHydraSplinePlayerInheritMoveCapability : UHazeCapability
{
	UBallistaHydraActorReferencesComponent BallistaRefsComp;
	UMedallionPlayerReferencesComponent MedallionRefsComp;
	UPlayerMovementComponent MioMoveComp;
	UPlayerMovementComponent ZoeMoveComp;

	ABallistaHydraSpline Spline;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Spline = Cast<ABallistaHydraSpline>(Owner);
		BallistaRefsComp = UBallistaHydraActorReferencesComponent::GetOrCreate(Game::Mio);
		MedallionRefsComp = UMedallionPlayerReferencesComponent::GetOrCreate(Game::Mio);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (BallistaRefsComp.Refs == nullptr)
			return false;
		if (MedallionRefsComp.Refs == nullptr)
			return false;
		if (MedallionRefsComp.Refs.HydraAttackManager.Phase < EMedallionPhase::Ballista1)
			return false;
		if (MedallionRefsComp.Refs.HydraAttackManager.Phase > EMedallionPhase::BallistaArrowShot3)
			return false;
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (MedallionRefsComp.Refs.HydraAttackManager.Phase > EMedallionPhase::BallistaArrowShot3)
			return true;
		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		if (MioMoveComp == nullptr)
			MioMoveComp = UPlayerMovementComponent::Get(Game::Mio);
		if (ZoeMoveComp == nullptr)
			ZoeMoveComp = UPlayerMovementComponent::Get(Game::Zoe);

		Spline.PlayerInheritMovementComponent.EnableTrigger(Spline);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
	}

};