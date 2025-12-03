class USkylineGravityZoneExitCapability : UHazePlayerCapability
{
	default CapabilityTags.Add(n"GravityZone");
	default CapabilityTags.Add(n"GravityZoneExit");

	default TickGroup = EHazeTickGroup::BeforeMovement;
	default TickGroupOrder = 91;

	USkylineGravityZoneComponent ZoneComp;
	UCameraUserComponent CameraUser;
	UPlayerSwingComponent SwingComp;
	UPlayerMovementComponent MoveComp;
	USweepingMovementData Movement;

	float ActiveTickDuration;
	FVector StartLocation;
	FVector StartGravityDirection;
	FVector TargetLocation;
	FVector TargetGravityDirection;
	FVector RotationAxis;
	float RotationAngularDistance;
	FVector Velocity;
	FRotator CameraTargetRotation;
	FHazeAcceleratedRotator CameraRotation;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		ZoneComp = USkylineGravityZoneComponent::Get(Owner);
		CameraUser = UCameraUserComponent::Get(Owner);
		SwingComp = UPlayerSwingComponent::Get(Owner);
		MoveComp = UPlayerMovementComponent::Get(Owner);
		Movement = MoveComp.SetupSweepingMovementData();
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (SwingComp.HasActivateSwingPoint())
			return false;

		if (ZoneComp.ActiveZone == nullptr)
			return false;

		if (ZoneComp.RegisteredZones.Contains(ZoneComp.ActiveZone))
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (ActiveTickDuration >= ZoneComp.SwitchDuration)
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		StartGravityDirection = Player.GetGravityDirection();
		StartLocation = Player.ActorLocation;
		TargetGravityDirection = -FVector::UpVector;
		TargetLocation = (StartLocation - StartGravityDirection * ZoneComp.LiftDistance + TargetGravityDirection * ZoneComp.LiftDistance);
		TargetLocation -= (ZoneComp.ActiveZone.ActorCenterLocation - TargetLocation).ConstrainToPlane(TargetGravityDirection).GetSafeNormal() * Player.ScaledCapsuleRadius * 2.0;

		Velocity = MoveComp.Velocity;
		if (ZoneComp.bLimitRetainedVelocity)
			Velocity = Velocity.GetSafeNormal() * Math::Min(Velocity.Size(), ZoneComp.MaxRetainedVelocity);

		FVector CrossVector = TargetGravityDirection;
		if (Math::Abs(StartGravityDirection.DotProduct(CrossVector)) > 0.99)
			CrossVector = Player.ActorRightVector;

		RotationAxis = StartGravityDirection.CrossProduct(CrossVector).GetSafeNormal();
		RotationAngularDistance = Math::RadiansToDegrees(Math::Acos(StartGravityDirection.DotProduct(TargetGravityDirection)));
		
		FVector CameraForward = Player.ActorForwardVector.RotateAngleAxis(RotationAngularDistance, RotationAxis);
		CameraTargetRotation = FRotator::MakeFromXZ(CameraForward, -TargetGravityDirection);
		CameraRotation.SnapTo(Player.ViewRotation, Player.ViewAngularVelocity);

		Player.PlaySlotAnimation(Animation = ZoneComp.GravitySwitchAnimation, bLoop = true);
		Player.ApplyCameraSettings(ZoneComp.CameraSettings, 1.0, this, SubPriority = 60);

		// Align fucks with gravity if we happen to find a target below us during transition
		Player.BlockCapabilities(GravityBladeGrappleTags::GravityBladeGrappleGravityAlign, this);
		Player.BlockCapabilities(GravityBladeCombatTags::GravityBladeAttack, this);
		Player.BlockCapabilities(n"GravityZoneEnter", this);

		// Bit funky, but fixes an issue where the player teleports when entering grounded state
		//  while gravity is still being rotated -- blocking ground trace doesn't help here
		UMovementStandardSettings::SetWalkableSlopeAngle(Owner, 0.0, this);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		// Player must exit and re-enter zone to switch again
		if (ZoneComp.ActiveZone != nullptr)
		{
			ZoneComp.UnregisterZone(ZoneComp.ActiveZone);
			ZoneComp.ActiveZone = nullptr;
		}

		Player.OverrideGravityDirection(TargetGravityDirection, Skyline::GravityProxy);

		Player.StopSlotAnimationByAsset(ZoneComp.GravitySwitchAnimation);
		Player.ClearCameraSettingsByInstigator(this);

		Player.UnblockCapabilities(GravityBladeGrappleTags::GravityBladeGrappleGravityAlign, this);
		Player.UnblockCapabilities(GravityBladeCombatTags::GravityBladeAttack, this);
		Player.UnblockCapabilities(n"GravityZoneEnter", this);

		UMovementStandardSettings::ClearWalkableSlopeAngle(Owner, this);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		float Alpha = Math::Clamp(ActiveDuration / ZoneComp.SwitchDuration, 0.0, 1.0);
		Alpha = Math::EaseInOut(0.0, 1.0, Alpha, 1.6);

		if (MoveComp.PrepareMove(Movement))
		{
			const FVector InterpLocation = Math::Lerp(StartLocation, TargetLocation, Alpha);
			const FVector TargetDelta = (InterpLocation - Player.ActorLocation);
			
			StartLocation += (Velocity * DeltaTime);
			TargetLocation += (Velocity * DeltaTime);
			Velocity -= (Velocity * ZoneComp.Drag * DeltaTime);

			Movement.AddDelta(TargetDelta);
			Movement.BlockGroundTracingForThisFrame();
			MoveComp.ApplyMove(Movement);
		}

		const FVector GravityDirection = StartGravityDirection.RotateAngleAxis(RotationAngularDistance * Alpha, RotationAxis);
		Player.OverrideGravityDirection(GravityDirection, Skyline::GravityProxy);

		CameraRotation.AccelerateTo(CameraTargetRotation, ZoneComp.SwitchDuration, DeltaTime);
		CameraUser.SetDesiredRotation(CameraRotation.Value, this);
		
		ActiveTickDuration = ActiveDuration;
	}
}