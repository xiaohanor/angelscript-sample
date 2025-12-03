class UPlayerFallingLowMantleEnterCapability : UHazePlayerCapability
{
	default CapabilityTags.Add(CapabilityTags::Movement);
	default CapabilityTags.Add(PlayerMovementTags::CoreMovement);
	default CapabilityTags.Add(PlayerMovementTags::LedgeMantle);
	default CapabilityTags.Add(PlayerLedgeMantleTags::LedgeMantleFalling);
	default CapabilityTags.Add(PlayerLedgeMantleTags::LedgeMantleMovement);

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
	default TickGroupSubPlacement = 10;

	//This capability brings us from falling (if within the threshhold) to the correct capsule height below the ledge over the duration

	UPlayerMovementComponent MoveComp;
	UTeleportingMovementData Movement;
	UPlayerLedgeMantleComponent MantleComp;

	FVector RelativeStartLocation;
	FVector RelativeEndLocation;
	float ActiveTimer;
	float MoveAlpha;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		MoveComp = UPlayerMovementComponent::Get(Player);
		Movement = MoveComp.SetupTeleportingMovementData();

		MantleComp = UPlayerLedgeMantleComponent::Get(Player);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate(FPlayerFallingMantleActivationParams& ActivationParams) const
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

		if (MantleComp.TracedForState != EPlayerLedgeMantleState::FallingLowEnter)
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

		if (MoveComp.HasWallContact())
			return true;

		if (MoveAlpha >= 1)
			return true;

		if (MantleComp.Data.TopHitComponent == nullptr || MantleComp.Data.ExitFloorHit.Component == nullptr)
			return true;

		if (MantleComp.Data.TopHitComponent.Owner.IsActorDisabled() || MantleComp.Data.ExitFloorHit.Component.Owner.IsActorDisabled())
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FPlayerFallingMantleActivationParams ActivationParams)
	{
		Player.BlockCapabilities(BlockedWhileIn::LedgeMantle, this);
		MantleComp.Data = ActivationParams.MantleData;

		if(HasControl())
		{
			RelativeStartLocation = ActivationParams.RelativeStartLocation;
			RelativeEndLocation = ActivationParams.RelativeEndLocation;
			ActiveTimer = 0;

			if(MantleComp.FallingLowImpactFeedback != nullptr)
				Player.PlayForceFeedback(MantleComp.FallingLowImpactFeedback, false, false, this);
		}

		MantleComp.SetState(EPlayerLedgeMantleState::FallingLowEnter);
		MoveComp.FollowComponentMovement(MantleComp.Data.TopHitComponent, this);
		
		if(Player.IsMovementCameraBehaviorEnabled())
		{
			//[AL] We could scale the impulse and FF within a range based on vertical velocity
			FHazeCameraImpulse ImpactImpulse;
			ImpactImpulse.CameraSpaceImpulse = FVector(0, 0, -600);
			ImpactImpulse.ExpirationForce = 40;
			ImpactImpulse.Dampening = 0.8;
			Player.ApplyCameraImpulse(ImpactImpulse, this);
		}

		CalculateAnimData();
		UPlayerCoreMovementEffectHandler::Trigger_Mantle_Airborne_Low_EnterStarted(Player);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Player.UnblockCapabilities(BlockedWhileIn::LedgeMantle, this);

		MantleComp.StateCompleted(EPlayerLedgeMantleState::FallingLowEnter);
		MoveComp.UnFollowComponentMovement(this);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if (MoveComp.PrepareMove(Movement))
		{
			if (HasControl())
			{
				ActiveTimer += DeltaTime;

				FVector StartLocation = MantleComp.Data.TopHitComponent.WorldTransform.TransformPosition(RelativeStartLocation);
				FVector EndLocation = MantleComp.Data.TopHitComponent.WorldTransform.TransformPosition(RelativeEndLocation);

				MoveAlpha = Math::Clamp(ActiveTimer / MantleComp.Settings.FallingLowMantleEnterDuration, 0, 1);

				if(MoveAlpha >= 1)
					MantleComp.Data.bEnterCompleted = true;
				
				float DurationDelta = ActiveTimer - MantleComp.Settings.FallingLowMantleEnterDuration;
				if(DurationDelta > 0)
					MantleComp.Data.MantleDurationCarryOver = DurationDelta;

				FVector TargetLocation = Math::Lerp(StartLocation, EndLocation, MoveAlpha);
				FVector FrameDelta = TargetLocation - Player.ActorLocation;

				FRotator TargetRotation = (-MantleComp.Data.WallHit.Normal).Rotation();
				FRotator NewRotation = Math::RInterpConstantTo(Player.ActorRotation, TargetRotation, DeltaTime, 1080);

				Movement.AddDelta(FrameDelta);
				Movement.SetRotation(NewRotation);
			}
			// Remote update
			else
			{
				Movement.ApplyCrumbSyncedGroundMovement();
			}
			
			MoveComp.ApplyMoveAndRequestLocomotion(Movement, n"LedgeMantle");
		}
	}

	bool ValidateEnterHeight(FPlayerFallingMantleActivationParams& ActivationParams) const
	{
		FVector TestRelativeStartLocation = MantleComp.Data.TopHitComponent.WorldTransform.InverseTransformPosition(Player.ActorLocation);
		FVector PlayerEndLocation = MantleComp.Data.LedgePlayerLocation + (-MoveComp.WorldUp * (120)) + (MantleComp.Data.WallHit.Normal.ConstrainToPlane(MoveComp.WorldUp) * MantleComp.Settings.FallingLowMantleWallOffset);
		FVector TestRelativeEndLocation = MantleComp.Data.TopHitComponent.WorldTransform.InverseTransformPosition(PlayerEndLocation);

		//Test to make sure we arent being pulled to far upwards (creating a weird enter trajectory)
		FVector PlayerToEndLocationDelta = PlayerEndLocation - Player.ActorLocation;
		PlayerToEndLocationDelta = PlayerToEndLocationDelta.ConstrainToPlane(Player.ActorForwardVector);
		if(PlayerToEndLocationDelta.DotProduct(MoveComp.WorldUp) > 20)
		{
			MantleComp.Data.Reset();
			return false;
		}

		if (!MantleComp.Settings.bIgnoreCollisionCheckForEnter)
		{
			//Test EndLocation Collision
			FHazeTraceSettings EnterLocationTest = Trace::InitFromMovementComponent(MoveComp);
			FOverlapResultArray OverlapTest = EnterLocationTest.QueryOverlaps(PlayerEndLocation);

			if(OverlapTest.HasBlockHit())
			{
				MantleComp.Data.Reset();
				return false;
			}
		}

		//Test to make sure we have some leeway underneath our end location
		FHazeTraceSettings FloorTrace = Trace::InitFromMovementComponent(MoveComp);
		FloorTrace.UseLine();

		FHitResult FloorHit = FloorTrace.QueryTraceSingle(PlayerEndLocation, PlayerEndLocation + (-MoveComp.WorldUp * 200));

		if(FloorHit.bStartPenetrating)
		{
			MantleComp.Data.Reset();
			return false;
		}

		if(FloorHit.bBlockingHit)
		{
			float VerticalDelta = (PlayerEndLocation - FloorHit.ImpactPoint).ConstrainToPlane(Player.ActorForwardVector).Size();
			if(VerticalDelta < MantleComp.Settings.FallingLowMinimumHeight)
			{
				MantleComp.Data.Reset();
				return false;
			}
		}

		ActivationParams.RelativeStartLocation = TestRelativeStartLocation;
		ActivationParams.RelativeEndLocation = TestRelativeEndLocation;
		return true;
	}

	void CalculateAnimData()
	{
		FVector ConstrainedEnterDirection = (MantleComp.Data.WallHit.ImpactPoint - Player.ActorLocation).ConstrainToPlane(MoveComp.WorldUp).GetSafeNormal();
		FVector ConstrainedLeft = ConstrainedEnterDirection.CrossProduct(MoveComp.WorldUp);
		float EnterToPlayerLeftDot = ConstrainedLeft.DotProduct(-MantleComp.Data.WallHit.Normal);
		MantleComp.AnimData.bEnterFromRight = EnterToPlayerLeftDot <= 0;
	}
};

struct FPlayerFallingMantleActivationParams
{
	FPlayerLedgeMantleData MantleData;

	FVector RelativeStartLocation;
	FVector RelativeEndLocation;
}