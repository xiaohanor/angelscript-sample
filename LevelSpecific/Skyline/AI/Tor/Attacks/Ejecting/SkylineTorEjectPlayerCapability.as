class USkylineTorEjectPlayerCapability : UHazeCapability
{
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;
	default TickGroup = EHazeTickGroup::InfluenceMovement;
	default TickGroupOrder = 20;

	UPlayerMovementComponent MoveComp;
	UTeleportingMovementData Movement;
	USkylineTorEjectPlayerComponent EjectComp;
	AHazePlayerCharacter Player;
	FHazeAcceleratedVector AccLocation;
	float EjectTime;
	float Delay = 0.75;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		MoveComp = UPlayerMovementComponent::Get(Owner);
		Movement = MoveComp.SetupTeleportingMovementData();
		EjectComp = USkylineTorEjectPlayerComponent::GetOrCreate(Owner);
		Player = Cast<AHazePlayerCharacter>(Owner);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if(MoveComp.HasMovedThisFrame())
			return false;
		if(!EjectComp.bGrabbed)
			return false;
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(MoveComp.HasMovedThisFrame())
			return true;
		if(EjectTime > SMALL_NUMBER && Time::GetGameTimeSince(EjectTime) > Delay)
			return true;
		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Owner.BlockCapabilities(CapabilityTags::Movement, this);
		Owner.BlockCapabilities(CapabilityTags::MovementInput, this);
		Owner.BlockCapabilities(CapabilityTags::GameplayAction, this);
		Owner.BlockCapabilities(n"ContextualMovesWidgets", this);
		EjectTime = 0;

		FHazePointOfInterestFocusTargetInfo Poi;
		Poi.SetFocusToActor(EjectComp.CenterActor);
		Poi.LocalOffset = FVector(0, 0, 1000);

		FApplyClampPointOfInterestSettings Settings;
		Settings.Duration = -1;
		Settings.InputCounterForce = 4;
		Settings.InputTurnRateMultiplier = 0.3;

		FHazeCameraClampSettings PoiClamps;
		PoiClamps.ApplyClampsYaw(15, 15);
		PoiClamps.ApplyClampsPitch(10, 10);
		Player.ApplyClampedPointOfInterest(this, Poi, Settings, PoiClamps, 2, EHazeCameraPriority::High);

		AccLocation.SnapTo(Owner.ActorLocation);

		FHazePlaySlotAnimationParams Params;
		Params.Animation = EjectComp.PlayerGrabbedAnim;
		Params.bLoop = true;
		Player.PlaySlotAnimation(Params);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Player.ClearPointOfInterestByInstigator(this);
		if(EjectTime < SMALL_NUMBER)
			Owner.UnblockCapabilities(CapabilityTags::Movement, this);
		Owner.UnblockCapabilities(CapabilityTags::MovementInput, this);
		Owner.UnblockCapabilities(CapabilityTags::GameplayAction, this);
		Owner.UnblockCapabilities(n"ContextualMovesWidgets", this);
		EjectComp.Complete();
		Owner.ClearSettingsByInstigator(this);
		Player.HealPlayerHealth(1);
		Player.StopSlotAnimation();
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if(EjectTime > SMALL_NUMBER)
			return; // Allow other movement

		if(MoveComp.PrepareMove(Movement))
		{
			if(HasControl())
			{
				FVector TargetLocation = EjectComp.Grabber.ActorLocation + EjectComp.Grabber.ActorForwardVector * 250 + FVector::UpVector * 200;
				AccLocation.AccelerateTo(TargetLocation, 2, DeltaTime);

				Movement.AddDeltaFromMoveToPositionWithCustomVelocity(AccLocation.Value, FVector::ZeroVector);
				MoveComp.ApplyMove(Movement);

				if(!EjectComp.bGrabbed)
					CrumbRelease(EjectComp.bEjected);
			}
			else
			{
				Movement.ApplyCrumbSyncedAirMovement();
				MoveComp.ApplyMove(Movement);
			}
		}
	}

	UFUNCTION(CrumbFunction)
	void CrumbRelease(bool bEject)
	{
		Owner.UnblockCapabilities(CapabilityTags::Movement, this);

		if(bEject)
		{
			EjectTime = Time::GameTimeSeconds;
			// Tweak this set how fast the movement in the eject should be
			float EjectForce = 950;

			UPlayerAirMotionSettings::SetDragOfExtraHorizontalVelocity(Owner, 8 * EjectForce, this);
			FVector Dir = ((Owner.ActorLocation - EjectComp.CenterActor.ActorLocation).GetSafeNormal2D() + FVector::UpVector * 0.25).GetSafeNormal();
			Owner.SetActorRotation((-Dir).Rotation());
			Player.AddMovementImpulse(Dir * 6 * EjectForce);
			Player.StopSlotAnimation();
		}
		else
		{
			EjectTime = Time::GameTimeSeconds - Delay;
		}
	}
}