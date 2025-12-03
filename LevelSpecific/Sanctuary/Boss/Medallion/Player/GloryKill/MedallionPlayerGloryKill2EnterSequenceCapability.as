struct FMedallionPlayerGloryKill2EnterSequenceData
{
	bool bPlayersOnCorrectSide = true;
}
class UMedallionPlayerGloryKill2EnterSequenceCapability : UHazePlayerCapability
{
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	default CapabilityTags.Add(MedallionTags::MedallionTag);
	default CapabilityTags.Add(MedallionTags::MedallionGloryKill);
	default TickGroup = EHazeTickGroup::Movement;
	default TickGroupOrder = 61;

	UMedallionPlayerGloryKillComponent GloryKillComp;
	UMedallionPlayerReferencesComponent RefsComp;

	UMedallionPlayerFlyingMovementComponent MioMoveDataComp;
	UMedallionPlayerFlyingMovementComponent ZoeMoveDataComp;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		GloryKillComp = UMedallionPlayerGloryKillComponent::GetOrCreate(Player);
		RefsComp = UMedallionPlayerReferencesComponent::GetOrCreate(Player);
		MioMoveDataComp = UMedallionPlayerFlyingMovementComponent::GetOrCreate(Game::Mio);
		ZoeMoveDataComp = UMedallionPlayerFlyingMovementComponent::GetOrCreate(Game::Zoe);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate(FMedallionPlayerGloryKill2EnterSequenceData & Params) const
	{
		if (RefsComp.Refs == nullptr)
			return false;
		if (GloryKillComp.GloryKillState != EMedallionGloryKillState::EnterSequence)
			return false;
		
		bool bMioIsOnLeftSide = MioMoveDataComp.SyncedSideways.Value < ZoeMoveDataComp.SyncedSideways.Value;
		Params.bPlayersOnCorrectSide = bMioIsOnLeftSide;
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (Player.bIsControlledByCutscene)
			return false;
		return true;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FMedallionPlayerGloryKill2EnterSequenceData Params)
	{
		GloryKillComp.SyncedStrangle.SetValue(0.0);
		
		if (!Player.bIsControlledByCutscene)
		{
			GloryKillComp.GetCutsceneHydra().HeadPivotBlockers.AddUnique(MedallionConstants::Tags::StrangleBlockHeadPivot);
			if (Params.bPlayersOnCorrectSide)
				RefsComp.Refs.StartGloryKillEvent.Broadcast();
			else
				RefsComp.Refs.StartGloryKillEventWithPlayersSwapped.Broadcast();
		}
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		// if (Player.IsMio())
		// {
		// 	auto Transform = RefsComp.Refs.GloryKillSplineMio.Spline.GetWorldTransformAtSplineDistance(RefsComp.Refs.GloryKillSplineMio.Spline.SplineLength);
		// 	Player.TeleportActor(Transform.Location, Transform.Rotator(), this, false);
		// }
		// if (Player.IsZoe())
		// {
		// 	auto Transform = RefsComp.Refs.GloryKillSplineZoe.Spline.GetWorldTransformAtSplineDistance(RefsComp.Refs.GloryKillSplineZoe.Spline.SplineLength);
		// 	Player.TeleportActor(Transform.Location, Transform.Rotator(), this, false);
		// }
		GloryKillComp.SetGloryKillState(EMedallionGloryKillState::Strangle, this);
	}

	// UFUNCTION(BlueprintOverride)
	// void TickActive(float DeltaTime)
	// {
	// 	{
	// 		ASanctuaryBossMedallionHydra Hydra = GloryKillComp.GetCutsceneHydra();
	// 		if (Hydra == nullptr)
	// 			return;
	// 		FTransform HipsTransform = Player.Mesh.GetSocketTransform(n"Hips");
	// 		TEMPORAL_LOG(Player, "Strangle Sequence").Value("Hips Loc", HipsTransform.Location);
	// 		TEMPORAL_LOG(Player, "Strangle Sequence").Value("Hips Rot", HipsTransform.Rotation);
	// 		FVector HipsRelativeLocation = Hydra.ActorTransform.InverseTransformPosition(HipsTransform.Location);
	// 		FQuat HipsRelativeRotation = Hydra.ActorTransform.InverseTransformRotation(HipsTransform.Rotation);
	// 		TEMPORAL_LOG(Player, "Strangle Sequence").Value("Hips Relative Loc", HipsRelativeLocation);
	// 		TEMPORAL_LOG(Player, "Strangle Sequence").Value("Hips Relative Rot", HipsRelativeRotation);
	// 	}
	// }
};