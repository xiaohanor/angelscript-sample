class USanctuaryBossMedallionHydraHideBehindCameraCapability : UHazeCapability
{
	ASanctuaryBossMedallionHydra Hydra;
	UMedallionPlayerReferencesComponent RefsComp;

	default TickGroup = EHazeTickGroup::AfterGameplay;
	EMedallionPhase EnterPhase;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Hydra = Cast<ASanctuaryBossMedallionHydra>(Owner);
		RefsComp = UMedallionPlayerReferencesComponent::GetOrCreate(Game::Mio);
		UDebugActorBlockersComponent::GetOrCreate(Owner);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (RefsComp.Refs == nullptr)
			return false;
		if (IsCheerleading())
			return false;
		if (Hydra.bIsStrangleAttacked)
			return false;
		if (Hydra.bDead)
			return false;
		if (Hydra.bMedallionKilled)
			return false;
		if (!IsInStranglePhase())
			return false;
		if (!IsOutOfView())
			return false;
		return true;
	}

	bool IsInStranglePhase() const
	{
		if (RefsComp.Refs.HydraAttackManager.Phase == EMedallionPhase::Strangle1)
			return true;
		if (RefsComp.Refs.HydraAttackManager.Phase == EMedallionPhase::Strangle1Sequence)
			return true;
		if (RefsComp.Refs.HydraAttackManager.Phase == EMedallionPhase::Strangle2)
			return true;
		if (RefsComp.Refs.HydraAttackManager.Phase == EMedallionPhase::Strangle2Sequence)
			return true;
		if (RefsComp.Refs.HydraAttackManager.Phase == EMedallionPhase::Strangle3)
			return true;
		if (RefsComp.Refs.HydraAttackManager.Phase == EMedallionPhase::Strangle3Sequence)
			return true;
		return false;
	}

	bool IsCheerleading() const
	{
		return Hydra.HydraType == EMedallionHydra::MioLeft || Hydra.HydraType == EMedallionHydra::ZoeRight;
	}

	bool IsOutOfView() const
	{
		FTransform ViewTransform = Game::Mio.GetViewTransform();
		FVector RelativeLocation = Hydra.ActorLocation - ViewTransform.Location;
		if (ViewTransform.Rotation.ForwardVector.DotProduct(RelativeLocation) < KINDA_SMALL_NUMBER)
			return true;
		return false;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (!IsInStranglePhase())
			return true;
		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Hydra.AddActorVisualsBlock(this);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Hydra.RemoveActorVisualsBlock(this);
	}

	// UFUNCTION(BlueprintOverride)
	// void TickActive(float DeltaTime)
	// {
	// 	Debug::DrawDebugArrow(Owner.ActorLocation, Owner.ActorLocation + FVector::UpVector * 100000, 100, Hydra.DebugColor, 10, 0.0, true);
	// }
};