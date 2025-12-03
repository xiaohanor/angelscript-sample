class UMedallionMedallionStateCapability : UHazeCapability
{
	AMedallionMedallionActor Medallion;
	UMedallionPlayerMergeHighfiveJumpComponent HighfiveComp;
	UMedallionPlayerComponent MedallionComp;
	UMedallionPlayerReferencesComponent RefsComp;
	AHazePlayerCharacter Player;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Medallion = Cast<AMedallionMedallionActor>(Owner);
		Player = Game::GetPlayer(Medallion.TargetPlayer);
		HighfiveComp = UMedallionPlayerMergeHighfiveJumpComponent::GetOrCreate(Player);
		RefsComp = UMedallionPlayerReferencesComponent::GetOrCreate(Player);
		MedallionComp = UMedallionPlayerComponent::GetOrCreate(Player);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		return false;
	}

	bool ShouldHover() const
	{
		if (RefsComp.Refs == nullptr)
			return false;
		if (RefsComp.Refs.SideScrollerSplineLocker == nullptr)
			return false;
		if (MedallionComp.InsideZoeFakeMedallion != nullptr)
			return false;
		if (Player.bIsControlledByCutscene && !MedallionComp.bAllowCutsceneHover)
			return false;
		if (!IsInSidescrollerOrMerge())
			return false;
		return true;
	}

	bool ShouldHighfiveAttach() const
	{
		if (RefsComp.Refs == nullptr)
			return false;
		if (RefsComp.Refs.SideScrollerSplineLocker == nullptr)
			return false;
		if (MedallionComp.InsideZoeFakeMedallion != nullptr)
			return false;
		if (Player.bIsControlledByCutscene && !MedallionComp.bAllowCutsceneHover)
			return false;
		if (!IsInSidescrollerOrMerge())
			return false;
		if (!HighfiveComp.IsHighfiveJumping())
			return false;
		return true;
	}

	bool IsInSidescrollerOrMerge() const
	{
		if (RefsComp.Refs == nullptr)
			return false;
		switch (RefsComp.Refs.HydraAttackManager.Phase)
		{
			case EMedallionPhase::None:
			case EMedallionPhase::Sidescroller1:
			case EMedallionPhase::Merge1:
			case EMedallionPhase::Sidescroller2:
			case EMedallionPhase::Merge2:
			case EMedallionPhase::Sidescroller3:
			case EMedallionPhase::Merge3:
				return true;
			default:
				return false;
		}
	}

	bool ShouldInsideHover() const
	{
		if (!MedallionComp.bShowMioInsideMedallion)
			return false;
		if (MedallionComp.InsideZoeFakeMedallion == nullptr)
			return false;
		if (MedallionComp.bMioMedallionChill)
			return false;
		if (Player.IsZoe())
			return false;
		return true;
	}

	bool ShouldBeOnSocket() const
	{
		if (MedallionComp.bMioMedallionChill)
			return true;
		if (RefsComp.Refs == nullptr)
			return false;
		if (Player.IsZoe() && RefsComp.Refs.HydraAttackManager.Phase >= EMedallionPhase::Strangle3Sequence)
			return false;
		return true;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		Medallion.MedallionState = GetDesiredState();
		TEMPORAL_LOG(Medallion, "State").Value("State", Medallion.MedallionState);
	}

	EMedallionMedallionState GetDesiredState()
	{
		if (MedallionComp.bForceHidden)
			return EMedallionMedallionState::Hidden;
		if (Medallion.bIsControlledByCutscene)
			return EMedallionMedallionState::CutsceneControlled;
		if (ShouldInsideHover())
			return EMedallionMedallionState::HoverTowardsInsideDummy;
		if (ShouldHighfiveAttach())
			return EMedallionMedallionState::OnSocketHighfive;
		if (ShouldHover())
			return EMedallionMedallionState::HoverTowardsOther;
		if (ShouldBeOnSocket())
			return EMedallionMedallionState::OnSocketChest;
		return EMedallionMedallionState::Hidden;
	}
};