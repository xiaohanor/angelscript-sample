class UPlayerJumpClimbMantleEnterCapability : UHazePlayerCapability
{
	default CapabilityTags.Add(CapabilityTags::Movement);
	default CapabilityTags.Add(PlayerMovementTags::CoreMovement);
	default CapabilityTags.Add(PlayerMovementTags::LedgeMantle);
	default CapabilityTags.Add(PlayerLedgeMantleTags::LedgeMantleMovement);
	default CapabilityTags.Add(PlayerLedgeMantleTags::LedgeMantleJumping);

	default CapabilityTags.Add(BlockedWhileIn::WallRun);
	default CapabilityTags.Add(BlockedWhileIn::LedgeGrab);
	default CapabilityTags.Add(BlockedWhileIn::Swing);
	default CapabilityTags.Add(BlockedWhileIn::Grapple);
	default CapabilityTags.Add(BlockedWhileIn::Swimming);

	default DebugCategory = n"Movement";
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	default TickGroup = EHazeTickGroup::ActionMovement;
	default TickGroupOrder = 21;
	default TickGroupSubPlacement = 10;

	UPlayerLedgeMantleComponent MantleComp;
	UPlayerMovementComponent MoveComp;
	USteppingMovementData Movement;

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
	bool ShouldActivate(FPLayerJumpClimbMantleActivationParams& ActivationParams) const
	{
		if (MoveComp.HasMovedThisFrame())
			return false;

		if (!MoveComp.IsInAir())
			return false;

		if (MantleComp.GetState() != EPlayerLedgeMantleState::Inactive)
			return false;

		if (MantleComp.Data.bEnterCompleted)
			return false;

		if (!MantleComp.Data.HasValidData())
			return false;

		if (MantleComp.TracedForState != EPlayerLedgeMantleState::JumpClimbEnter)
			return false;

		if (MantleComp.Data.VerticalDistance > MantleComp.Settings.JumpClimbMantleMaxTopDistance)
			return false;

		if (!ValidateEnterHeight(ActivationParams))
			return false;
		
		ActivationParams.MantleData = MantleComp.Data;
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (MoveComp.HasMovedThisFrame())
			return true;

		if (MoveComp.HasImpulse())
			return true;
		
		// if (MoveComp.HasWallContact())
		// 	return true;

		if (MoveAlpha >= 1)
			return true;

		if (MantleComp.Data.TopHitComponent == nullptr || MantleComp.Data.ExitFloorHit.Component == nullptr)
			return true;

		if (MantleComp.Data.TopHitComponent.Owner.IsActorDisabled() || MantleComp.Data.ExitFloorHit.Component.Owner.IsActorDisabled())
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FPLayerJumpClimbMantleActivationParams ActivationParams)
	{
		Player.BlockCapabilities(BlockedWhileIn::LedgeMantle, this);
		Player.BlockCapabilities(CapabilityTags::Collision, this);

		MantleComp.Data = ActivationParams.MantleData;

		if(HasControl())
		{
			ActiveTimer = 0;
			RelativeStartLocation = ActivationParams.RelativeStartLocation;
			RelativeEndLocation = ActivationParams.RelativeEndLocation;
		}

		if (Player.IsMovementCameraBehaviorEnabled())
		{

		}

		MantleComp.SetState(EPlayerLedgeMantleState::JumpClimbEnter);
		MoveComp.FollowComponentMovement(MantleComp.Data.TopHitComponent, this);

		UPlayerCoreMovementEffectHandler::Trigger_Mantle_Climb_EnterStarted(Player);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Player.UnblockCapabilities(BlockedWhileIn::LedgeMantle, this);
		Player.UnblockCapabilities(CapabilityTags::Collision, this);

		MantleComp.StateCompleted(EPlayerLedgeMantleState::JumpClimbEnter);
		MoveComp.UnFollowComponentMovement(this);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if (MoveComp.PrepareMove(Movement))
		{
			if(HasControl())
			{
				ActiveTimer += DeltaTime;

				FVector StartLocation = MantleComp.Data.TopHitComponent.WorldTransform.TransformPosition(RelativeStartLocation);
				FVector EndLocation = MantleComp.Data.TopHitComponent.WorldTransform.TransformPosition(RelativeEndLocation);

				MoveAlpha = Math::Clamp(ActiveTimer / MantleComp.Settings.JumpClimbMantleEnterDuration, 0, 1);

				FVector TargetLocation = Math::Lerp(StartLocation, EndLocation, MoveAlpha);
				FVector FrameDelta = TargetLocation - Player.ActorLocation;

				FRotator TargetRotation = (-MantleComp.Data.WallHit.Normal).Rotation();
				FRotator NewRotation = Math::RInterpConstantTo(Player.ActorRotation, TargetRotation, DeltaTime, 1080);

				if(MoveAlpha >= 1)
				{
					MantleComp.Data.bEnterCompleted = true;
					
					float DurationDelta = ActiveTimer - MantleComp.Settings.FallingLowMantleEnterDuration;
					if(DurationDelta > 0)
						MantleComp.Data.MantleDurationCarryOver = DurationDelta;
				}

				Movement.AddDelta(FrameDelta);
				Movement.SetRotation(NewRotation);
			}
			else
			{
				Movement.ApplyCrumbSyncedAirMovement();
			}

			MoveComp.ApplyMoveAndRequestLocomotion(Movement, n"LedgeMantle");
		}
	}

	bool ValidateEnterHeight(FPLayerJumpClimbMantleActivationParams& ActivationParams) const
	{
		FVector TestRelativeStartLocation = MantleComp.Data.TopHitComponent.WorldTransform.InverseTransformPosition(Player.ActorLocation);
		FVector PlayerEndLocation = MantleComp.Data.LedgePlayerLocation + (-MoveComp.WorldUp * (120)) + (MantleComp.Data.WallHit.Normal.ConstrainToPlane(MoveComp.WorldUp) * MantleComp.Settings.FallingLowMantleWallOffset);
		FVector TestRelativeEndLocation = MantleComp.Data.TopHitComponent.WorldTransform.InverseTransformPosition(PlayerEndLocation);

		FHazeTraceSettings FloorTrace = Trace::InitFromMovementComponent(MoveComp);
		FloorTrace.UseLine();

		FHitResult FloorHit = FloorTrace.QueryTraceSingle(PlayerEndLocation, PlayerEndLocation + (-MoveComp.WorldUp * 200));

		if(FloorHit.bStartPenetrating)
		{
			MantleComp.Data.Reset();
			return false;
		}

		//If we would be forced downwards to align then dont allow activation / wait for airborne roll or falling mantle
		FVector PlayerToEndLocationDelta = PlayerEndLocation - Player.ActorLocation;
		if(PlayerToEndLocationDelta.DotProduct(MoveComp.WorldUp) < 0)
		{
			MantleComp.Data.Reset();
			return false;
		}

		if(FloorHit.bBlockingHit)
		{
			float VerticalDelta = (PlayerEndLocation - FloorHit.ImpactPoint).ConstrainToPlane(Player.ActorForwardVector).Size();
			if(VerticalDelta < MantleComp.Settings.JumpClimbMantleMinimumHeight)
			{
				MantleComp.Data.Reset();
				return false;
			}
		}

		ActivationParams.RelativeStartLocation = TestRelativeStartLocation;
		ActivationParams.RelativeEndLocation = TestRelativeEndLocation;
		return true;
	}
};

struct FPLayerJumpClimbMantleActivationParams
{
	FPlayerLedgeMantleData MantleData;

	FVector RelativeStartLocation;
	FVector RelativeEndLocation;
}