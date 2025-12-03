class USummitTeenDragonRollingLiftRollingCapability : UHazePlayerCapability
{
	default DebugCategory = SummitDebugCapabilityTags::TeenDragon;

	default TickGroup = EHazeTickGroup::ActionMovement;
	default TickGroupOrder = 100;

	UPlayerTeenDragonComponent DragonComp;
	USummitTeenDragonRollingLiftComponent LiftComp;

	UPlayerMovementComponent MoveComp;
	USteppingMovementData Movement;
	UMovementSteppingSettings StepSettings;
	ASummitRollingLift CurrentRollingLift;

	const float RotationSpeedTowardsInput = 3.0;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		LiftComp = USummitTeenDragonRollingLiftComponent::Get(Player);

		MoveComp = UPlayerMovementComponent::Get(Player);
		Movement = MoveComp.SetupSteppingMovementData();
		StepSettings = UMovementSteppingSettings::GetSettings(Player);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (MoveComp.HasMovedThisFrame())
			return false;

		if(LiftComp.CurrentRollingLift == nullptr)
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (MoveComp.HasMovedThisFrame())
			return true;

		if(LiftComp.CurrentRollingLift == nullptr)
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		DragonComp = UPlayerTeenDragonComponent::Get(Player);
		CurrentRollingLift = LiftComp.CurrentRollingLift;
		Player.ApplySettings(SummitRollingLiftGravitySettings, this, EHazeSettingsPriority::Gameplay);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Player.ClearSettingsByInstigator(this);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if (MoveComp.PrepareMove(Movement))
		{
			FVector MovementInput = MoveComp.MovementInput;
			bool bHasInput = !MovementInput.IsNearlyZero();
			if (HasControl())
			{
				FVector CurrentVelocity = GetCurrentVelocity(DeltaTime, MovementInput);
				if(bHasInput)
				{
					FQuat Rotation = Math::QInterpTo(
						Player.ActorQuat
						, FQuat::MakeFromX(MovementInput)
						, DeltaTime
						, RotationSpeedTowardsInput);
					Movement.SetRotation(Rotation);
				}

				Movement.AddGravityAcceleration();
				Movement.AddOwnerVerticalVelocity();
				//Movement.AddPendingImpulses();

				// FVector Impulse = FVector::ZeroVector;
				// ApplyImpulses(DeltaTime, Impulse);

				Movement.AddPendingImpulses();
				Movement.AddHorizontalVelocity(CurrentVelocity);

				// Make the velocity follow the spline
				// {
				// 	const FVector PendingDelta = (Impulse + CurrentVelocity) * DeltaTime;
				// 	const FVector PendingLocation = Player.ActorLocation + PendingDelta;
				// 	const FSplinePosition SplinePosition = CurrentRollingLift.UpdateBestGuideSpline(PendingLocation, Player);
				// 	//const FVector DeltaToSpline = CurrentRollingLift.GetLockedDeltaToSpline(SplinePosition, PendingLocation);
				// 	//Movement.AddDeltaWithCustomVelocity(DeltaToSpline, FVector::ZeroVector);

				// 	TEMPORAL_LOG(Player)
				// 		.Value("Rolling Lift:", SplinePosition.CurrentSpline.Owner)
				// 		.Arrow("Rolling Lift: CurrentVelocity", Player.ActorCenterLocation, Player.ActorCenterLocation + CurrentVelocity, false, 20, 40, FLinearColor::White)
				// 		//.Arrow("Rolling Lift: DeltaToSpline", Player.ActorCenterLocation, Player.ActorCenterLocation + (DeltaToSpline * 3000), false, 20, 40, FLinearColor::Teal)
				// 		.Sphere("Rolling Lift: Guide Spline Position", SplinePosition.WorldLocation, 200, FLinearColor::Blue, 20)
				// 		.Value("Rolling Lift: Guide Spline Distance", SplinePosition.CurrentSplineDistance)
				// 	;

				// 	//CurrentRollingLift.LastSplineForward = SplinePosition.WorldForwardVector;
				// }
			}
			// Remote update
			else
			{
				Movement.ApplyCrumbSyncedGroundMovement();
			}
			MoveComp.ApplyMove(Movement);
			FName LocomotionTag = TeenDragonLocomotionTags::RollMovement;
			// if(!bHasInput)
			// 	LocomotionTag = TeenDragonLocomotionTags::Movement;
			DragonComp.RequestLocomotionDragonAndPlayer(LocomotionTag);
		}
	}

	FVector GetCurrentVelocity(float DeltaTime, FVector MovementInput) const
	{
		FVector CurrentVelocity = MoveComp.HorizontalVelocity;
		CurrentVelocity -= CurrentRollingLift.GetDeceleration(CurrentVelocity, DeltaTime);
		CurrentVelocity += CurrentRollingLift.GetAccelerationFromInput(MovementInput, DeltaTime);
		if(MoveComp.IsOnAnyGround())
			CurrentVelocity += CurrentRollingLift.GetSlopeAcceleration(DeltaTime);
		CurrentVelocity = CurrentRollingLift.ClampVelocityToMaxSpeed(CurrentVelocity);
		return CurrentVelocity;
	}

	// void ApplyImpulses(float DeltaTime, FVector& Impulse)
	// {
	// 	Impulse += MoveComp.GetPendingImpulse();	

	// 	// Velocity from custom impulses will ignore any movement component velocity
	// 	// It's weird that regular impulses do not work, since these should do about the same thing...
	// 	if (LiftComp.CustomImpulses.Num() == 0)
	// 		return;

	// 	//FVector CustomVelocity = FVector::ZeroVector;
	// 	for (int i = LiftComp.CustomImpulses.Num() - 1; i >= 0; i--)
	// 	{
	// 		Impulse += LiftComp.CustomImpulses[i];
	// 	}
	// 	LiftComp.CustomImpulses.Empty();

	// 	//Movement.AddVelocity(CustomVelocity);
	// }

};