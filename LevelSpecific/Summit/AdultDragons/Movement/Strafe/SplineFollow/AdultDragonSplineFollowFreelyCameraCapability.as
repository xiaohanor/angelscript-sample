class UAdultDragonSplineFollowFreelyCameraCapability : UHazePlayerCapability
{
	default CapabilityTags.Add(n"AdultDragon");
	default CapabilityTags.Add(CameraTags::Camera);
	default CapabilityTags.Add(CameraTags::CameraControl);

	default DebugCategory = n"AdultDragon";
	default TickGroup = EHazeTickGroup::BeforeMovement;
	default TickGroupOrder = 1;

	UPlayerAdultDragonComponent DragonComp;
	UAdultDragonSplineFollowManagerComponent SplineFollowManagerComp;
	UAdultDragonStrafeComponent StrafeComp;
	UCameraUserComponent CameraUser;
	UPlayerMovementComponent MoveComp;

	FHazeAcceleratedRotator AccInputRotation;
	FHazeAcceleratedRotator AccRotation;

	UAdultDragonStrafeSettings StrafeSettings;

	FHazeAcceleratedFloat AcceleratedSideFlyMultiplier;

	FAdultDragonSplineFollowData CurrentSplineFollowData;
	bool bSplineFollowDataIsValid = false;


	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		DragonComp = UPlayerAdultDragonComponent::Get(Player);
		SplineFollowManagerComp = UAdultDragonSplineFollowManagerComponent::Get(Player);
		StrafeComp = UAdultDragonStrafeComponent::Get(Player);
		CameraUser = UCameraUserComponent::Get(Player);
		MoveComp = UPlayerMovementComponent::Get(Player);
		StrafeSettings = UAdultDragonStrafeSettings::GetSettings(Player);
	}

	UFUNCTION(NotBlueprintCallable)
	private void ToggleFreeFlyCamera()
	{
		SplineFollowManagerComp.bForceLockedStrafe = !SplineFollowManagerComp.bForceLockedStrafe;
	}

	UFUNCTION(BlueprintOverride)
	void PreTick(float DeltaTime)
	{
		bSplineFollowDataIsValid = SplineFollowManagerComp.CurrentSplineFollowData.IsSet();
		if (bSplineFollowDataIsValid)
			CurrentSplineFollowData = SplineFollowManagerComp.CurrentSplineFollowData.Value;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if(SplineFollowManagerComp.bForceLockedStrafe)
			return false;

		if(!StrafeSettings.bUseFreeFlyStrafe)
			return false;

		if(!CameraUser.CanControlCamera())
			return false;

		if(!CameraUser.CanApplyUserInput())
			return false;

		if(!bSplineFollowDataIsValid)
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(SplineFollowManagerComp.bForceLockedStrafe)
			return true;

		if(!StrafeSettings.bUseFreeFlyStrafe)
			return true;

		if(!CameraUser.CanControlCamera())
			return true;

		if(!CameraUser.CanApplyUserInput())
			return true;

		if(!bSplineFollowDataIsValid)
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		AccRotation.SnapTo(CurrentSplineFollowData.WorldRotation.Rotator());
		StrafeComp.AccMovementRotation.SnapTo(CurrentSplineFollowData.WorldRotation);
		StrafeComp.InputRotation = FRotator::ZeroRotator;
		AccInputRotation.SnapTo(FRotator::ZeroRotator);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		// PrintToScreen(f"{Player} FREE CAMERA");

		float CameraDeltaSeconds = Time::CameraDeltaSeconds;
		
		//Always goes 60% of the dragon roll amount 
		if (DragonComp.bGapFlying && DragonComp.GapFlyingData.Value.bAllowSideFlying)
			AcceleratedSideFlyMultiplier.AccelerateTo(0.6, 4.5, DeltaTime);
		else
			AcceleratedSideFlyMultiplier.AccelerateTo(0.0, 3.0, DeltaTime);

		FSplinePosition SplinePos = CurrentSplineFollowData.GetMostActiveSplinePosition();
		SplinePos.Move(StrafeSettings.ClosestSplinePositionForwardOffset);


		FVector ClosestSplineLocation = SplinePos.WorldLocation;
		
		FVector2D DistanceToSpline;
		DistanceToSpline.X = (ClosestSplineLocation - Player.ActorLocation).VectorPlaneProject(FVector::UpVector).Size();
		DistanceToSpline.Y = (ClosestSplineLocation - Player.ActorLocation).ProjectOnToNormal(FVector::UpVector).Size();
		
		FVector2D MaxDist = CurrentSplineFollowData.SplineFollowComp.GetBoundariesAtSplinePoint(SplinePos) * 2;
	
		FVector2D SplineDistanceAlpha;
		SplineDistanceAlpha.X = Math::Min(DistanceToSpline.X / MaxDist.X, 1);
		SplineDistanceAlpha.Y = Math::Min(DistanceToSpline.Y / MaxDist.Y, 1);
	
		FVector2D MovementInput = FVector2D(MoveComp.MovementInput.X, MoveComp.MovementInput.Y);
		FRotator InputRotation = AccInputRotation.Value;
		if(MovementInput.Size() > KINDA_SMALL_NUMBER * 4)
		{
			InputRotation = FRotator(MovementInput.X * StrafeSettings.MaxTurningOffset.Pitch, MovementInput.Y * StrafeSettings.MaxTurningOffset.Yaw, 0);
			AccInputRotation.AccelerateTo(InputRotation, StrafeSettings.StrafeTurningDuration, CameraDeltaSeconds);
		}

		// StrafeComp.InputRotation = InputRotation;

		FVector2D InputLockedAlpha = SplineDistanceAlpha;
		InputLockedAlpha.X = StrafeSettings.IgnoreMovementDependingOnSplineDistance.GetFloatValue(SplineDistanceAlpha.X, 0);
		InputLockedAlpha.Y = StrafeSettings.IgnoreMovementDependingOnSplineDistance.GetFloatValue(SplineDistanceAlpha.Y, 0);

		FRotator LocalToSplineRotation = SplinePos.WorldRotation.UnrotateVector(ClosestSplineLocation - Player.ActorLocation).Rotation();
		InputRotation.Yaw = Math::Lerp(InputRotation.Yaw, LocalToSplineRotation.Yaw, InputLockedAlpha.X);
		InputRotation.Pitch = Math::Lerp(InputRotation.Pitch, LocalToSplineRotation.Pitch, InputLockedAlpha.Y);
		
		FRotator WantedMovementRotation = SplinePos.GetWorldTransform().TransformRotation(InputRotation);
		StrafeComp.AccMovementRotation.AccelerateTo(WantedMovementRotation.Quaternion(), StrafeSettings.StrafeTurningDuration, DeltaTime);

		FRotator SplineRotation = AccRotation.Value;
		FRotator RotationToSpline = (ClosestSplineLocation - Player.ActorLocation).Rotation();
		FRotator CameraTargetRotation = WantedMovementRotation;

		float LookAtSplineAlpha = StrafeSettings.LookAtSplineDependingOnSplineDistance.GetFloatValue(SplineDistanceAlpha.Size());
		CameraTargetRotation = Math::LerpShortestPath(CameraTargetRotation, RotationToSpline, LookAtSplineAlpha);
		CameraTargetRotation = AccRotation.AccelerateTo(CameraTargetRotation, StrafeSettings.CameraPlayerRotationAccelerationDuration, DeltaTime);
		//CameraTargetRotation = SplineRotation;
		//Debug::DrawDebugDirectionArrow(Player.ActorLocation, CameraTargetRotation.ForwardVector, 10000, 50, FLinearColor::Green, Thickness = 10);

		
		TEMPORAL_LOG(StrafeComp)
			.Value("SplineDistanceAlpha", SplineDistanceAlpha)
			.Value("LookAtSplineAlpha", LookAtSplineAlpha)
			.Value("InputLockedAlpha", InputLockedAlpha)
			.Value("InputRotation", InputRotation)
			.Value("InputSplineRotation", StrafeComp.AccMovementRotation.Value.Rotator())
			.DirectionalArrow("Wanted Rotation", Player.ActorLocation, InputRotation.ForwardVector * 5000, 10, 40, FLinearColor::Red)
			.DirectionalArrow("Actor Forward", Player.ActorLocation, Player.ActorForwardVector * 5000, 10, 40, FLinearColor::Red)
			.DirectionalArrow("Actor Up", Player.ActorLocation, Player.ActorUpVector * 5000, 10, 40, FLinearColor::Blue)
			.DirectionalArrow("Actor Right", Player.ActorLocation, Player.ActorRightVector * 5000, 10, 40, FLinearColor::Green)
		;


		CameraUser.SetYawAxis(SplineRotation.UpVector, this);
		CameraUser.SetInputRotation(CameraTargetRotation, this);
	}
};