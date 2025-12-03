class UTeenDragonEatingCapability : UHazePlayerCapability
{
	default CapabilityTags.Add(TeenDragonCapabilityTags::TeenDragon);

	default TickGroup = EHazeTickGroup::Movement;
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	UTeenDragonEatingComponent UserComp;
	UHazeMovementComponent MoveComp;
	UPlayerTeenDragonComponent DragonComp;
	USteppingMovementData Movement;

	float TotalDuration = 0.9;
	float AttachDuration = 0.28;
	float EatDuration = 0.95;

	bool bHasAttached;
	bool bHaveEaten;
	bool bCompletedMove;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		UserComp = UTeenDragonEatingComponent::Get(Player);
		MoveComp = UHazeMovementComponent::Get(Player);
		DragonComp = UPlayerTeenDragonComponent::Get(Player);
		Movement = MoveComp.SetupSteppingMovementData();
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (!UserComp.ConsumeEatingCheck())
			return false;

		if (MoveComp.HasMovedThisFrame())
			return false;

		if (!MoveComp.HasGroundContact())
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (ActiveDuration > TotalDuration)
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Player.BlockCapabilities(CapabilityTags::MovementInput, this);
		Player.BlockCapabilities(CapabilityTags::Input, this);
		Player.BlockCapabilities(CapabilityTags::GameplayAction, this);
		bHaveEaten = false;
		bHasAttached = false;
		Player.ApplyCameraSettings(UserComp.CameraSettings, 2.0, this, EHazeCameraPriority::High);

		FHazePlaySlotAnimationParams Animation = Player.IsMio() ? UserComp.AnimAcid : UserComp.AnimTail;
		DragonComp.GetTeenDragon().Mesh.PlaySlotAnimation(Animation);

		// FHazePointOfInterestFocusTargetInfo FocusTargetInfo;
		// FocusTargetInfo.SetFocusToActor(UserComp.ObjectData.Object);
		// FocusTargetInfo.SetLocalOffset(FVector(200.0, 400.0, -50));
		// FApplyPointOfInterestSettings PoiSettings;
		// PoiSettings.Duration = TotalDuration;
		// Player.ApplyPointOfInterest(this, FocusTargetInfo, PoiSettings, 2.5);

		UTeenDragonEatingEventHandler::Trigger_OnStartEating(Player);

		TotalDuration = Animation.GetPlayLength() - HazeAnimation::ANIMATION_MIN_TIME;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Player.UnblockCapabilities(CapabilityTags::MovementInput, this);
		Player.UnblockCapabilities(CapabilityTags::Input, this);
		Player.UnblockCapabilities(CapabilityTags::GameplayAction, this);
		Player.ClearCameraSettingsByInstigator(this);
		Player.ClearPointOfInterestByInstigator(this);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		ATeenDragon TeenDragon = DragonComp.GetTeenDragon();

		if (!MoveComp.PrepareMove(Movement))
			return;

		FQuat TargetQuat = (UserComp.ObjectData.Object.ActorLocation - Player.ActorLocation).ConstrainToPlane(FVector::UpVector).GetSafeNormal().ToOrientationQuat();
		FVector TargetLocation = UserComp.ObjectData.Object.ActorLocation + (-TargetQuat.ForwardVector * UserComp.ObjectData.ObjectLocationOffset);
		FHazeTraceSettings TraceSettings = Trace::InitChannel(ECollisionChannel::ECC_Visibility);
		TraceSettings.UseLine();

		FHitResult Hit = TraceSettings.QueryTraceSingle(TargetLocation, -FVector::UpVector * 5000.0);
		if (Hit.bBlockingHit)
		{
			TargetLocation = Hit.ImpactPoint;
		}

		Movement.InterpRotationTo(TargetQuat, 9.0, false);
		FVector HorizontalMove = (TargetLocation - Player.ActorLocation);
		if (HorizontalMove.Size() > 50.0 && !bCompletedMove)
		{
			bCompletedMove = true;
			Movement.AddHorizontalVelocity(HorizontalMove);
		}

		if (!bHaveEaten && ActiveDuration > EatDuration)
		{
			UserComp.ObjectData.Object.EatObject();
			UTeenDragonEatingEventHandler::Trigger_OnObjectEaten(Player);
			bHaveEaten = true;
		}

		if (!bHasAttached && ActiveDuration > AttachDuration)
		{
			bHasAttached = true;

			UserComp.ObjectData.Object.MeshComp.AttachToComponent(TeenDragon.Mesh, n"Align");
			UserComp.ObjectData.Object.MeshComp.AddRelativeRotation(FRotator(0, -90, 90));
		}

		MoveComp.ApplyMove(Movement);
		if (TeenDragon.Mesh.CanRequestLocomotion())
			TeenDragon.RequestLocomotion(n"Movement", this);
	}
};