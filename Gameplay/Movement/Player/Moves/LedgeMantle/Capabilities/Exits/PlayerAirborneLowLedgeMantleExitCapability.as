class UPlayerAirborneLowLedgeMantleExitCapability : UHazePlayerCapability
{
	default CapabilityTags.Add(CapabilityTags::Movement);
	default CapabilityTags.Add(PlayerMovementTags::CoreMovement);
	default CapabilityTags.Add(PlayerMovementTags::LedgeMantle);
	default CapabilityTags.Add(PlayerLedgeMantleTags::LedgeMantleMovement);
	default CapabilityTags.Add(PlayerLedgeMantleTags::LedgeMantleAirborneLow);

	default CapabilityTags.Add(BlockedWhileIn::WallScramble);
	default CapabilityTags.Add(BlockedWhileIn::WallRun);
	default CapabilityTags.Add(BlockedWhileIn::LedgeGrab);
	default CapabilityTags.Add(BlockedWhileIn::Swing);
	default CapabilityTags.Add(BlockedWhileIn::Grapple);
	default CapabilityTags.Add(BlockedWhileIn::Swimming);

	default DebugCategory = n"Movement";
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	default TickGroup = EHazeTickGroup::ActionMovement;
	default TickGroupOrder = 21;
	default TickGroupSubPlacement = 5;

	UPlayerMovementComponent MoveComp;
	USteppingMovementData Movement;
	UPlayerLedgeMantleComponent MantleComp;

	bool bMoveCompleted = false;

	float ActiveTimer = 0;
	float MoveAlpha = 0;

	FVector RelativeStartLocation;
	FVector RelativeEndLocation;

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

		if (!MantleComp.Data.HasValidData())
			return false;

		if (MantleComp.GetState() != EPlayerLedgeMantleState::AirborneLowEnter)
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

		if (MoveAlpha >= 1)
			return true;

		if (MantleComp.Data.ExitFloorHit.Component == nullptr || MantleComp.Data.TopHitComponent == nullptr)
			return true;

		if (MantleComp.Data.TopHitComponent.Owner.IsActorDisabled() || MantleComp.Data.ExitFloorHit.Component.Owner.IsActorDisabled())
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Player.BlockCapabilities(BlockedWhileIn::LedgeMantle, this);
		Player.BlockCapabilities(CapabilityTags::Collision, this);

		if(HasControl())
		{
			bMoveCompleted = false;
			ActiveTimer = 0 + MantleComp.Data.MantleDurationCarryOver;
			RelativeStartLocation = MantleComp.Data.ExitFloorHit.Component.WorldTransform.InverseTransformPosition(Player.ActorLocation);
			RelativeEndLocation = MantleComp.Data.FloorRelativeExitLocation;
		}
	
		MoveComp.FollowComponentMovement(MantleComp.Data.TopHitComponent, this);
		MantleComp.SetState(EPlayerLedgeMantleState::AirborneLowExit);

		Player.PlayForceFeedback(MantleComp.FF_AirborneLow, this);

		UPlayerCoreMovementEffectHandler::Trigger_Mantle_Airborne_Low_ExitStarted(Player);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Player.UnblockCapabilities(BlockedWhileIn::LedgeMantle, this);
		Player.UnblockCapabilities(CapabilityTags::Collision, this);
		MoveComp.Reset();

		float ExitSpeed = Math::Lerp(200, 300, Math::Clamp(MoveComp.MovementInput.DotProduct(Player.ActorForwardVector), 0, 1));
		Player.SetActorVelocity(Player.ActorForwardVector * ExitSpeed);

		MoveComp.UnFollowComponentMovement(this);
		MantleComp.StateCompleted(EPlayerLedgeMantleState::AirborneLowExit);

		UPlayerCoreMovementEffectHandler::Trigger_Mantle_Airborne_Low_ExitFinished(Player);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if (MoveComp.PrepareMove(Movement))
		{
			if(HasControl())
			{
				ActiveTimer += DeltaTime;

				FVector StartLocation = MantleComp.Data.ExitFloorHit.Component.WorldTransform.TransformPosition(RelativeStartLocation);
				FVector EndLocation = MantleComp.Data.ExitFloorHit.Component.WorldTransform.TransformPosition(RelativeEndLocation);

				MoveAlpha = Math::Clamp(ActiveTimer / MantleComp.Settings.AirborneLowMantleExitDuration, 0, 1);

				//If our next frame of movement would be excessively small, just append it to this frames movement
				if(MoveAlpha > 0.99)
					MoveAlpha = 1;

				FVector TargetLocation = Math::Lerp(StartLocation, EndLocation, MoveAlpha);
				FVector FrameDelta =  TargetLocation - Player.ActorLocation;

				Movement.AddDeltaWithCustomVelocity(FrameDelta, MantleComp.Data.ExitFacingDirection * 150);
			}
			else
			{
				Movement.ApplyCrumbSyncedGroundMovement();
			}
			
			MoveComp.ApplyMoveAndRequestLocomotion(Movement, n"LedgeMantle");
		}
	}
};