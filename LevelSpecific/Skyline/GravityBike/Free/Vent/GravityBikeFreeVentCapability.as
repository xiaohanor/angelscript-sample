asset GravityBikeFreeVentCameraSettings of UHazeCameraSpringArmSettingsDataAsset
{
	SpringArmSettings.PivotLagMax = FVector::ZeroVector;
}

class UGravityBikeFreeVentCapability : UHazeCapability
{
	default CapabilityTags.Add(CapabilityTags::Movement);
	default CapabilityTags.Add(GravityBikeFree::Tags::GravityBikeFree);

    default TickGroup = EHazeTickGroup::Input;
	default TickGroupOrder = 110;	// After UGravityBikeFreeInputCapability

	AGravityBikeFree GravityBike;
	UGravityBikeFreeVentComponent VentComp;
	USplineLockComponent SplineLockComp;
	UGravityBikeFreeMovementComponent MoveComp;

	ASplineActor CurrentSpline;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		GravityBike = Cast<AGravityBikeFree>(Owner);
		VentComp = UGravityBikeFreeVentComponent::Get(GravityBike);
		SplineLockComp = USplineLockComponent::Get(GravityBike);
        MoveComp = UGravityBikeFreeMovementComponent::Get(GravityBike);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if(!VentComp.HasSpline())
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(!VentComp.HasSpline())
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		VentComp.bIsActive = true;
		LockToSpline(VentComp.InstigatedSpline.Get());

		GravityBike.BlockCapabilities(GravityBikeFree::Tags::GravityBikeFreeDrift, this);
		GravityBike.BlockCapabilities(GravityBikeFree::Jump::GravityBikeFreeJump, this);
		GravityBike.BlockCapabilities(n"GravityBikeFreeWeaponFire", this);

		GravityBike.GetDriver().ApplyCameraSettings(GravityBikeFreeVentCameraSettings, 0.5, this, EHazeCameraPriority::VeryHigh);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		VentComp.bIsActive = false;

		GravityBike.UnblockCapabilities(GravityBikeFree::Tags::GravityBikeFreeDrift, this);
		GravityBike.UnblockCapabilities(GravityBikeFree::Jump::GravityBikeFreeJump, this);
		GravityBike.UnblockCapabilities(n"GravityBikeFreeWeaponFire", this);

		GravityBike.UnlockMovementFromSpline(this);

		GravityBike.GetDriver().ClearCameraSettingsByInstigator(this);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if(CurrentSpline != VentComp.InstigatedSpline.Get())
		{
			// Change spline if we have a new one
			LockToSpline(VentComp.InstigatedSpline.Get());
		}

		AutoSteer();
		HandleSplineLockConstraint();
	}

	void LockToSpline(ASplineActor Spline)
	{
		if(CurrentSpline != nullptr)
			GravityBike.UnlockMovementFromSpline(this);

		FPlayerMovementSplineLockProperties LockProperties;
		LockProperties.AllowedHorizontalDeviation = 150;
		LockProperties.LockType = EPlayerSplineLockPlaneType::SplinePlaneAllowMovingWithinHorizontalDeviation;
		LockProperties.bRedirectMovementInput = false;
		GravityBike.LockMovementToSpline(Spline, this, LockProperties = LockProperties);

		CurrentSpline = Spline;
	}

	void AutoSteer()
	{
		const float AutoSteerInput = GetAutoSteerInput();
		const float PlayerSteerInput = GravityBike.Input.Steering;

		float Steering = 0;
		if(Math::Abs(PlayerSteerInput) > Math::Abs(AutoSteerInput))
		{
			Steering = PlayerSteerInput;
		}
		else if(Math::Sign(PlayerSteerInput) != Math::Sign(AutoSteerInput))
		{
			Steering = PlayerSteerInput;
		}
		else
		{
			Steering = AutoSteerInput;
		}

		Steering = Math::Clamp(Steering, -1, 1);

		GravityBike.Input.Steering = Steering;
	}

	void HandleSplineLockConstraint()
	{
		if(!SplineLockComp.AppliedSplineLockConstraintThisOrLastFrame())
			return;

		const FVector SplineRight = CurrentSpline.Spline.GetClosestSplineWorldRotationToWorldLocation(GravityBike.ActorLocation).RightVector;
		const FVector PreviousSideVelocity = MoveComp.PreviousVelocity.ProjectOnToNormal(SplineRight);
		const FVector CurrentSideVelocity = MoveComp.Velocity.ProjectOnToNormal(SplineRight);
		const FVector Impulse = CurrentSideVelocity - PreviousSideVelocity;

		const FQuat PreviousRotation = GravityBike.ActorQuat;
		FQuat NewRotation = FQuat::MakeFromZX(GravityBike.GetAcceleratedUp(), MoveComp.Velocity);

		if(Math::Sign(SplineLockComp.LastConstraintDeviation) > 0)
		{
			NewRotation = FQuat(GravityBike.GetAcceleratedUp(), -0.03) * NewRotation;
		}
		else
		{
			NewRotation = FQuat(GravityBike.GetAcceleratedUp(), 0.03) * NewRotation;
		}

		const FQuat Delta = FQuat::GetDelta(PreviousRotation, NewRotation);

		GravityBike.ApplyVentAlignWithSide(Impulse, Delta);

		GravityBike.SetActorRotation(NewRotation);
	}

	float GetAutoSteerInput() const
	{
		float SplineDistance = CurrentSpline.Spline.GetClosestSplineDistanceToWorldLocation(GravityBike.ActorLocation);
		SplineDistance += 2000;
		FVector ToAutoSteerTarget = CurrentSpline.Spline.GetWorldLocationAtSplineDistance(SplineDistance) - GravityBike.ActorLocation;
		ToAutoSteerTarget = ToAutoSteerTarget.VectorPlaneProject(GravityBike.MovementWorldUp).GetSafeNormal();

		ELeftRight Side = ToAutoSteerTarget.DotProduct(GravityBike.ActorRightVector) > 0 ? ELeftRight::Right : ELeftRight::Left;

		float AutoSteering = 0;
		if(Side == ELeftRight::Right)
			AutoSteering = 1.0;
		else
			AutoSteering = -1.0;

		float TurnAmount = Math::Saturate(ToAutoSteerTarget.GetAngleDegreesTo(GravityBike.ActorForwardVector.VectorPlaneProject(GravityBike.MovementWorldUp)) / 20);

		return AutoSteering * TurnAmount;
	}
}