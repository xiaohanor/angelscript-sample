class UHackableSniperTurretMovementCapability : UHazeCapability
{
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	default CapabilityTags.Add(PrisonTags::Prison);
	default CapabilityTags.Add(PrisonTags::Drones);
	default CapabilityTags.Add(SwarmDroneTags::SwarmDroneHijackCapability);
	
	default TickGroup = EHazeTickGroup::Gameplay;
	default TickGroupOrder = 110;

	AHackableSniperTurret SniperTurret;
	float AccInput = 0;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		SniperTurret = Cast<AHackableSniperTurret>(Owner);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (!SniperTurret.HijackTargetableComp.IsHijacked())
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (!SniperTurret.HijackTargetableComp.IsHijacked())
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
	}

	UFUNCTION(BlueprintOverride)
	void PreTick(float DeltaTime)
	{
		if(!IsActive() && HasControl())
		{
			AccInput = Math::FInterpConstantTo(AccInput, 0, DeltaTime, SniperTurret.MovementAccelerateSpeed);
			return;
		}

		if(HasControl())
		{
			const UHazeSplineComponent Spline = SniperTurret.SplineToFollow.Spline;
			const float NewDistanceAlongSpline = SniperTurret.SyncedDistanceAlongSpline.GetValue() + (AccInput * SniperTurret.MoveAlongSplineSpeed * 100.0 * DeltaTime);
			const float NewClampedDistanceAlongSpline = Math::Clamp(NewDistanceAlongSpline, 0.0, Spline.GetSplineLength());

			if(NewDistanceAlongSpline != NewClampedDistanceAlongSpline)
				AccInput = 0;

			SniperTurret.SyncedDistanceAlongSpline.SetValue(NewClampedDistanceAlongSpline);
			SniperTurret.MoveToSplineAtDistance(SniperTurret.SyncedDistanceAlongSpline.GetValue());
		}
		else
		{
			SniperTurret.MoveToSplineAtDistance(SniperTurret.SyncedDistanceAlongSpline.GetValue());
		}
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		SniperTurret.HackedDuration = ActiveDuration;

		if(HasControl() && SniperTurret.bCanMove)
		{
			float HorizontalInputRaw = GetAttributeFloat(AttributeNames::MoveRight);
			FVector MovementInput = GetMovementInput();

			const FQuat SplineRotation = SniperTurret.SplineToFollow.Spline.GetWorldRotationAtSplineDistance(SniperTurret.SyncedDistanceAlongSpline.Value);
			const float HorizontalInputWorld = MovementInput.DotProduct(SplineRotation.RightVector);

			// Combine both world space input and local input to allow for either simply pressing left/right, or pressing in the travel direction (which can be up or down, if the camera is rotated)
			const float HorizontalInput = Math::Clamp(HorizontalInputWorld + HorizontalInputRaw, -1, 1);

			AccInput = Math::FInterpConstantTo(AccInput, HorizontalInput, DeltaTime, SniperTurret.MovementAccelerateSpeed);
		}
	}

	FVector GetMovementInput() const
	{
		FVector2D MoveInput2D = GetAttributeVector2D(AttributeVectorNames::MovementRaw);
		FVector MoveInput = FVector(0, MoveInput2D.X, 0);
		return FRotator::MakeFromX(SniperTurret.HijackTargetableComp.GetHijackPlayer().ViewRotation.ForwardVector.VectorPlaneProject(FVector::UpVector)).RotateVector(MoveInput);
	}
};