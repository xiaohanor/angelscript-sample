class UTundraPlayerSnowMonkeyIceKingBossPunchBackFlipCapability : UHazePlayerCapability
{
	default TickGroup = EHazeTickGroup::ActionMovement;
	default TickGroupOrder = 25;
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	default CapabilityTags.Add(TundraShapeshiftingTags::SnowMonkeyBossPunch);

	UTundraPlayerSnowMonkeyIceKingBossPunchComponent BossPunchComp;
	UTundraPlayerSnowMonkeyComponent SnowMonkeyComp;
	UPlayerMovementComponent MoveComp;
	UTeleportingMovementData Movement;
	UTundraPlayerSnowMonkeyIceKingBossPunchSettings Settings;
	ULocomotionFeatureSnowMonkeyBossPunch Feature;

	FHazeLocomotionTransform RootMotion;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		BossPunchComp = UTundraPlayerSnowMonkeyIceKingBossPunchComponent::GetOrCreate(Player);
		SnowMonkeyComp = UTundraPlayerSnowMonkeyComponent::Get(Player);
		MoveComp = UPlayerMovementComponent::Get(Player);
		Movement = MoveComp.SetupTeleportingMovementData();
		Settings = UTundraPlayerSnowMonkeyIceKingBossPunchSettings::GetSettings(Player);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if(BossPunchComp.CurrentBossPunchTargetable == nullptr)
			return false;

		if(!BossPunchComp.TypeSettings.bDoBackFlip)
			return false;

		if(MoveComp.HasMovedThisFrame())
			return false;

		if(BossPunchComp.AmountOfPunchesPerformed != BossPunchComp.TypeSettings.BossPunchesAmount)
			return false;

		if(Time::GetGameTimeSince(BossPunchComp.TimeOfLastPunch) < BossPunchComp.TypeSettings.TimeToBackFlipAfterLastPunch)
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(MoveComp.HasMovedThisFrame())
			return true;

		if(ActiveDuration > Feature.AnimData.Punch6.Sequence.PlayLength)
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		if (BossPunchComp.Type == ETundraPlayerSnowMonkeyIceKingBossPunchType::SecondPunch)
		{
			Player.CameraOffsetComponent.LerpToLocation(this,
				Player.CameraOffsetComponent.WorldLocation + FVector(0, -600, 700),
				2.0);
		}

		Player.BlockCapabilities(TundraShapeshiftingTags::SnowMonkeyBossPunch, this);
		Player.BlockCapabilities(TundraShapeshiftingTags::ShapeshiftingInput, this);
		RootMotion = FHazeLocomotionTransform();
		BossPunchComp.AnimData.bDoBackFlip = true;
		UHazeLocomotionFeatureBase GenericFeature = SnowMonkeyComp.GetShapeActor().Mesh.GetFeatureByTag(BossPunchComp.AnimationFeatureTag);
		Feature = Cast<ULocomotionFeatureSnowMonkeyBossPunch>(GenericFeature);
		BossPunchComp.OnBackFlipStarted.Broadcast(BossPunchComp.Type);

		SnowMonkeyComp.GetShapeActor().Mesh.OnPostAnimEvalComplete.AddUFunction(this, n"OnPostAnimEvalComplete");
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Player.CameraOffsetComponent.ResetOffsetWithLerp(this, 2.0);

		Player.UnblockCapabilities(TundraShapeshiftingTags::SnowMonkeyBossPunch, this);
		Player.UnblockCapabilities(TundraShapeshiftingTags::ShapeshiftingInput, this);
		BossPunchComp.ExitBossPunch();
		BossPunchComp.AnimData.bDoBackFlip = false;

		SnowMonkeyComp.GetShapeActor().Mesh.OnPostAnimEvalComplete.Unbind(this, n"OnPostAnimEvalComplete");
	}

	UFUNCTION()
	private void OnPostAnimEvalComplete(UHazeSkeletalMeshComponentBase SkeletalMesh)
	{
		SkeletalMesh.ConsumeLastExtractedRootMotion(RootMotion);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if(MoveComp.PrepareMove(Movement))
		{
			FVector CurrentDelta = RootMotion.DeltaTranslation;
			Movement.AddDeltaWithCustomVelocity(CurrentDelta, FVector::ZeroVector);
			MoveComp.ApplyMoveAndRequestLocomotion(Movement, BossPunchComp.AnimationFeatureTag);
		}
	}
}