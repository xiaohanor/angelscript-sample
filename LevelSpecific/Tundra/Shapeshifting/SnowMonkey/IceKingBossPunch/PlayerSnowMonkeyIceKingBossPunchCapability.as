class UTundraPlayerSnowMonkeyIceKingBossPunchCapability : UHazePlayerCapability
{
	default TickGroup = EHazeTickGroup::ActionMovement;
	default TickGroupOrder = 75;
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	default CapabilityTags.Add(TundraShapeshiftingTags::SnowMonkeyBossPunch);

	UTundraPlayerSnowMonkeyIceKingBossPunchComponent BossPunchComp;
	UTundraPlayerSnowMonkeyComponent SnowMonkeyComp;
	UPlayerMovementComponent MoveComp;
	USteppingMovementData Movement;
	UTeleportingMovementData RootMovement;
	UTundraPlayerSnowMonkeyIceKingBossPunchSettings Settings;

	FHazeLocomotionTransform RootMotion;
	EVisibilityBasedAnimTickOption PreviousTickOption;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		BossPunchComp = UTundraPlayerSnowMonkeyIceKingBossPunchComponent::GetOrCreate(Player);
		MoveComp = UPlayerMovementComponent::Get(Player);
		Movement = MoveComp.SetupSteppingMovementData();
		RootMovement = MoveComp.SetupTeleportingMovementData();
		Settings = UTundraPlayerSnowMonkeyIceKingBossPunchSettings::GetSettings(Player);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if(MoveComp.HasMovedThisFrame())
			return false;

		if(BossPunchComp.CurrentBossPunchTargetable == nullptr)
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(MoveComp.HasMovedThisFrame())
			return true;

		if(Player.IsPlayerDead())
			return true;

		if(BossPunchComp.CurrentBossPunchTargetable == nullptr)
			return true;

		if(!BossPunchComp.TypeSettings.bDoBackFlip && BossPunchComp.AmountOfPunchesPerformed == BossPunchComp.TypeSettings.BossPunchesAmount)
		{
			if(Time::GetGameTimeSince(BossPunchComp.TimeOfLastPunch) > BossPunchComp.TypeSettings.LastAnimationDuration + 2) // Ugly little thing here..
				return true;
		}

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		SnowMonkeyComp = UTundraPlayerSnowMonkeyComponent::Get(Player);
		SnowMonkeyComp.GetShapeMesh().OnPostAnimEvalComplete.AddUFunction(this, n"OnPostAnimEvalComplete");
		PreviousTickOption = SnowMonkeyComp.GetShapeMesh().VisibilityBasedAnimTickOption;
		SnowMonkeyComp.GetShapeMesh().VisibilityBasedAnimTickOption = EVisibilityBasedAnimTickOption::AlwaysTickPoseAndRefreshBones;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		SnowMonkeyComp.GetShapeMesh().OnPostAnimEvalComplete.Unbind(this, n"OnPostAnimEvalComplete");
		SnowMonkeyComp.GetShapeMesh().VisibilityBasedAnimTickOption = PreviousTickOption;
		BossPunchComp.ExitBossPunch();
	}

	UFUNCTION()
	private void OnPostAnimEvalComplete(UHazeSkeletalMeshComponentBase SkelMeshComp)
	{
		if(BossPunchComp.bWithinRootMotionState)
			SkelMeshComp.ConsumeLastExtractedRootMotion(RootMotion);
		else
			RootMotion = FHazeLocomotionTransform();
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if(BossPunchComp.bWithinRootMotionState && MoveComp.PrepareMove(RootMovement))
		{
			if(HasControl())
			{
				FVector CurrentDelta = RootMotion.DeltaTranslation;
				RootMovement.AddDeltaWithCustomVelocity(CurrentDelta, FVector::ZeroVector);
			}
			else
			{
				if(MoveComp.HasGroundContact())
					RootMovement.ApplyCrumbSyncedGroundMovement();
				else
					RootMovement.ApplyCrumbSyncedAirMovement();
			}

			MoveComp.ApplyMoveAndRequestLocomotion(RootMovement, BossPunchComp.AnimationFeatureTag);
			return;
		}

		if(MoveComp.PrepareMove(Movement))
		{
			if(HasControl())
			{
				if(BossPunchComp.Type != ETundraPlayerSnowMonkeyIceKingBossPunchType::FinalPunch)
				{
					Movement.AddGravityAcceleration();
					Movement.AddOwnerVerticalVelocity();
				}
			}
			else
			{
				Movement.ApplyCrumbSyncedAirMovement();
			}

			MoveComp.ApplyMoveAndRequestLocomotion(Movement, BossPunchComp.AnimationFeatureTag);
		}
	}
}