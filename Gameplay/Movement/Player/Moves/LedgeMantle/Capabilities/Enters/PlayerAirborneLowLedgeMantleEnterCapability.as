class UPlayerAirborneLowLedgeMantleEnterCapability : UHazePlayerCapability
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
	default TickGroupSubPlacement = 10;

	UTeleportingMovementData Movement;
	UPlayerMovementComponent MoveComp;
	UPlayerLedgeMantleComponent MantleComp;

	FVector RelativeStartLocation;
	FVector RelativeEndLocation;
	float ActiveTimer;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		MoveComp = UPlayerMovementComponent::Get(Player);
		Movement = MoveComp.SetupTeleportingMovementData();

		MantleComp = UPlayerLedgeMantleComponent::Get(Player);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate(FAirborneLowMantleEnterParams& ActivationParams) const
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

		if (MantleComp.TracedForState != EPlayerLedgeMantleState::AirborneLowEnter)
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

		if (MantleComp.Data.bEnterCompleted)
			return true;

		if (MoveComp.HasWallContact())
			return true;

		if (MantleComp.Data.TopHitComponent == nullptr || MantleComp.Data.ExitFloorHit.Component == nullptr)
			return true;
		
		if (MantleComp.Data.TopHitComponent.Owner.IsActorDisabled() || MantleComp.Data.ExitFloorHit.Component.Owner.IsActorDisabled())
			return true;
		
		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FAirborneLowMantleEnterParams ActivationParams)
	{
		Player.BlockCapabilities(CapabilityTags::Collision, this);
		Player.BlockCapabilities(BlockedWhileIn::LedgeMantle, this);

		//Make sure our data is the same on both Control/Remote
		MantleComp.Data = ActivationParams.MantleData;

		if(HasControl())
		{
			RelativeStartLocation = ActivationParams.RelativeStartLocation;
			RelativeEndLocation = ActivationParams.RelativeEndLocation;
			ActiveTimer = 0;
		}

		if(Player.IsMovementCameraBehaviorEnabled())
		{
			//Camera Impulse/etc
		}

		MantleComp.SetState(EPlayerLedgeMantleState::AirborneLowEnter);
		MoveComp.FollowComponentMovement(MantleComp.Data.TopHitComponent, this);

		UPlayerCoreMovementEffectHandler::Trigger_Mantle_Airborne_Low_EnterStarted(Player);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Player.UnblockCapabilities(CapabilityTags::Collision, this);
		Player.UnblockCapabilities(BlockedWhileIn::LedgeMantle, this);

		if(!MantleComp.Data.bEnterCompleted)
		{

		}

		MoveComp.UnFollowComponentMovement(this);
		MantleComp.StateCompleted(EPlayerLedgeMantleState::AirborneLowEnter);
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
				FVector Endlocation = MantleComp.Data.TopHitComponent.WorldTransform.TransformPosition(RelativeEndLocation);

				float MoveAlpha = Math::Clamp(ActiveTimer / MantleComp.Settings.AirborneLowMantleEnterDuration, 0, 1);

				//If our next frame of movement would be excessively small, just append it to this frames movement
				if(MoveAlpha > 0.99)
					MoveAlpha = 1;

				if (MoveAlpha >= 1)
				{
					float DurationDelta = ActiveTimer - MantleComp.Settings.AirborneLowMantleEnterDuration;
					if(DurationDelta > 0)
						MantleComp.Data.MantleDurationCarryOver = DurationDelta;

					MantleComp.Data.bEnterCompleted = true;
				}

				FVector TargetLocation = Math::Lerp(StartLocation, Endlocation, MoveAlpha);
				FVector FrameDelta = TargetLocation - Player.ActorLocation;

				FRotator TargetRotation = (-MantleComp.Data.WallHit.Normal).Rotation();
				FRotator NewRotation = Math::RInterpConstantTo(Player.ActorRotation, TargetRotation, DeltaTime, 1080);

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

	bool ValidateEnterHeight(FAirborneLowMantleEnterParams& ActivationParams) const
	{
		FVector TestRelativeStartLocation = MantleComp.Data.TopHitComponent.WorldTransform.InverseTransformPosition(Player.ActorLocation);
		FVector PlayerEndLocation = MantleComp.Data.LedgePlayerLocation + (-MoveComp.WorldUp * (80)) + (MantleComp.Data.WallHit.Normal.ConstrainToPlane(MoveComp.WorldUp) * MantleComp.Settings.FallingLowMantleWallOffset);
		FVector TestRelativeEndLocation = MantleComp.Data.TopHitComponent.WorldTransform.InverseTransformPosition(PlayerEndLocation);

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
			if(VerticalDelta < MantleComp.Settings.AirborneLowMinimumHeight)
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

struct FAirborneLowMantleEnterParams
{
	FPlayerLedgeMantleData MantleData;

	FVector RelativeStartLocation;
	FVector RelativeEndLocation;
}