struct FSkylineGravityZoneEnterParams
{
	ASkylineGravityZone Zone;
}

class USkylineGravityZoneEnterCapability : UHazePlayerCapability
{
	default CapabilityTags.Add(n"GravityZone");
	default CapabilityTags.Add(n"GravityZoneEnter");

	default TickGroup = EHazeTickGroup::BeforeMovement;
	default TickGroupOrder = 90;

	USkylineGravityZoneComponent ZoneComp;
	UPlayerSwingComponent SwingComp;
	UCameraUserComponent CameraUser;
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
	bool ShouldActivate(FSkylineGravityZoneEnterParams& Params) const
	{
		if (SwingComp.HasActivateSwingPoint())
			return false;

		if (ZoneComp.PrimaryZone == nullptr)
			return false;

		FVector ZoneUpVector = ZoneComp.PrimaryZone.ActorUpVector;
		if (ZoneUpVector.DotProduct(Player.MovementWorldUp) > 0.98)
			return false;

		Params.Zone = ZoneComp.PrimaryZone;
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
	void OnActivated(const FSkylineGravityZoneEnterParams& Params)
	{
		// TODO: Lots of duplicate data between enter/exit, should probably move stuff into comp
		ZoneComp.ActiveZone = Params.Zone;
		StartGravityDirection = Player.GetGravityDirection();
		StartLocation = Player.ActorLocation;
		TargetGravityDirection = -ZoneComp.ActiveZone.ActorUpVector;
		TargetLocation = (StartLocation - StartGravityDirection * ZoneComp.LiftDistance + TargetGravityDirection * ZoneComp.LiftDistance);
		TargetLocation += (ZoneComp.ActiveZone.ActorCenterLocation - TargetLocation).ConstrainToPlane(TargetGravityDirection).GetSafeNormal() * Player.ScaledCapsuleRadius * 2.0;
		
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
		Player.ApplyCameraSettings(ZoneComp.CameraSettings, 1, this, EHazeCameraPriority::Low);

		// Align fucks with gravity if we happen to find a target below us during transition
		Player.BlockCapabilities(GravityBladeGrappleTags::GravityBladeGrappleGravityAlign, this);
		Player.BlockCapabilities(GravityBladeCombatTags::GravityBladeAttack, this);
		Player.BlockCapabilities(n"GravityZoneExit", this);

		// Bit funky, but fixes an issue where the player teleports when entering grounded state
		//  while gravity is still being rotated -- blocking ground trace doesn't help here
		UMovementStandardSettings::SetWalkableSlopeAngle(Owner, 0.0, this);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Player.OverrideGravityDirection(TargetGravityDirection, Skyline::GravityProxy);

		Player.StopSlotAnimationByAsset(ZoneComp.GravitySwitchAnimation);
		Player.ClearCameraSettingsByInstigator(this);

		Player.UnblockCapabilities(GravityBladeGrappleTags::GravityBladeGrappleGravityAlign, this);
		Player.UnblockCapabilities(GravityBladeCombatTags::GravityBladeAttack, this);
		Player.UnblockCapabilities(n"GravityZoneExit", this);

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