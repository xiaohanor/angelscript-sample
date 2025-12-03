class UPlayerScrambleToMantleExitCapability : UHazePlayerCapability
{
	default CapabilityTags.Add(CapabilityTags::Movement);
	default CapabilityTags.Add(PlayerMovementTags::CoreMovement);
	default CapabilityTags.Add(PlayerMovementTags::LedgeMantle);
	default CapabilityTags.Add(PlayerLedgeMantleTags::LedgeMantleMovement);
	default CapabilityTags.Add(PlayerLedgeMantleTags::LedgeMantleScramble);

	default CapabilityTags.Add(BlockedWhileIn::WallScramble);
	default CapabilityTags.Add(BlockedWhileIn::WallRun);
	default CapabilityTags.Add(BlockedWhileIn::LedgeGrab);

	default DebugCategory = n"Movement";
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	default TickGroup = EHazeTickGroup::ActionMovement;
	default TickGroupOrder = 21;
	default TickGroupSubPlacement = 5;

	UPlayerMovementComponent MoveComp;
	USteppingMovementData Movement;
	UPlayerLedgeMantleComponent MantleComp;

	bool bMoveCompleted = false;
	float MoveSpeed;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		MoveComp = UPlayerMovementComponent::Get(Player);
		Movement = MoveComp.SetupSteppingMovementData();

		MantleComp = UPlayerLedgeMantleComponent::Get(Player);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (MoveComp.HasMovedThisFrame())
			return false;

		if (MantleComp.GetState() != EPlayerLedgeMantleState::ScrambleEnter)
			return false;

		if (!MantleComp.Data.HasValidData())
			return false;

		if (!MantleComp.Data.bEnterCompleted)
			return false;
		
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (MoveComp.HasMovedThisFrame())
			return true;

		if (MoveComp.HasWallContact())
			return true;

		if (bMoveCompleted)
			return true;

		if (MantleComp.Data.TopHitComponent == nullptr || MantleComp.Data.ExitFloorHit.Component == nullptr)
			return true;

		if (MantleComp.Data.TopHitComponent.Owner.IsActorDisabled() || MantleComp.Data.ExitFloorHit.Component.Owner.IsActorDisabled())
			return true;

		if (ActiveDuration >= MantleComp.Settings.ScrambleExitDuration)
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Player.BlockCapabilities(BlockedWhileIn::LedgeMantle, this);
		MoveComp.FollowComponentMovement(MantleComp.Data.ExitFloorHit.Component, this);

		// if(Player.IsMovementCameraBehaviorEnabled())
		// {

		// }
		
		if(HasControl())
		{
			bMoveCompleted = false;
			FVector EndLocation = MantleComp.Data.ExitFloorHit.Component.WorldTransform.TransformPosition(MantleComp.Data.FloorRelativeExitLocation);
			FVector ToTarget = EndLocation - Player.ActorLocation;
			FVector ToTargetFlattened = ToTarget.ConstrainToPlane(MantleComp.Data.ExitFloorHit.Normal);
			MoveSpeed = ToTargetFlattened.Size() / (MantleComp.Settings.ScrambleExitDuration - MantleComp.Data.MantleDurationCarryOver);

#if !RELEASE
			if(IsDebugActive() || PlayerLedgeMantle::CVar_DebugLedgeMantle.GetInt() == 1)
				Debug::DrawDebugSphere(EndLocation, 25, Duration = 5);
#endif	
		}

		MantleComp.SetState(EPlayerLedgeMantleState::ScrambleExit);
		UPlayerCoreMovementEffectHandler::Trigger_Mantle_Scramble_ExitStarted(Player);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Player.UnblockCapabilities(BlockedWhileIn::LedgeMantle, this);
		MoveComp.UnFollowComponentMovement(this);

		MantleComp.StateCompleted(EPlayerLedgeMantleState::ScrambleExit);
		UPlayerCoreMovementEffectHandler::Trigger_Mantle_Scramble_ExitFinished(Player);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if (!MoveComp.PrepareMove(Movement))
			return;

		if (HasControl())
		{
			FVector ToTarget = MantleComp.Data.ExitFloorHit.Component.WorldTransform.TransformPosition(MantleComp.Data.FloorRelativeExitLocation) - Player.ActorLocation;
			ToTarget = ToTarget.ConstrainToPlane(MantleComp.Data.ExitFloorHit.Normal);
			FVector DeltaMove = ToTarget.GetSafeNormal() * (MoveSpeed * DeltaTime);

			if(ToTarget.Size() < DeltaMove.Size() || ((ToTarget.Size() - DeltaMove.Size()) < (DeltaMove.Size() * 0.5)))
			{
				DeltaMove = ToTarget;
				bMoveCompleted = true;
				Movement.OverrideFinalGroundResult(MantleComp.Data.ExitFloorHit);
			}

			Movement.AddDeltaWithCustomVelocity(DeltaMove, MantleComp.Data.Direction * MoveSpeed);
			Movement.SetRotation(ToTarget.Rotation());
		}
		// Remote update
		else
		{
			Movement.ApplyCrumbSyncedGroundMovement();
		}

		MoveComp.ApplyMoveAndRequestLocomotion(Movement, n"LedgeMantle");
	}
};