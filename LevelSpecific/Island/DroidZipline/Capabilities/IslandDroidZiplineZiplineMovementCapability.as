class UIslandDroidZiplineZiplineMovementCapability : UIslandDroidZiplineBaseCapability
{
	default CapabilityTags.Add(CapabilityTags::Movement);
	default TickGroup = EHazeTickGroup::Movement;
	//default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	UIslandDroidZiplineSettings Settings;

	UIslandDroidZiplineZiplineDestroyComponent DestroyComp;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Super::Setup();
		
		Settings = UIslandDroidZiplineSettings::GetSettings(Droid);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if(Droid.CurrentDroidState != EIslandDroidZiplineState::Ziplining)
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(Droid.CurrentDroidState != EIslandDroidZiplineState::Ziplining)
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Droid.CurrentSplineDistance = Droid.ZiplineSpline.Spline.GetClosestSplineDistanceToWorldLocation(Droid.ActorLocation);
		DestroyComp = UIslandDroidZiplineZiplineDestroyComponent::Get(Droid.ZiplineSpline);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		FVector Delta;
		GetSplineDelta(Delta, DeltaTime);
		GetSidewaysDelta(Delta, DeltaTime);

		Droid.ActorLocation += Delta;
		Droid.SetActorVelocity(Delta / DeltaTime);

		if(Droid.CurrentTiltValue.HasControl() && (Droid.MoveWillResultInFatalImpact(Delta) || HasPassedDestroyComp()))
		{
			Droid.KillDroid();
		}
	}

	void GetSplineDelta(FVector& Delta, float DeltaTime)
	{
		Droid.CurrentSplineSpeed += Settings.PatrolToZiplineAcceleration * DeltaTime;
		Droid.CurrentSplineSpeed = Math::Min(Droid.CurrentSplineSpeed, Settings.ZiplineSpeed);

		Droid.CurrentSplineDistance += Droid.CurrentSplineSpeed * DeltaTime;
		FTransform TargetTransform = Droid.ZiplineSpline.Spline.GetWorldTransformAtSplineDistance(Droid.CurrentSplineDistance);
		FVector TargetLocation = TargetTransform.Location;

		if(Droid.CurrentSplineDistance > Droid.ZiplineSpline.Spline.SplineLength)
		{
			float RemainingDistance = Droid.CurrentSplineDistance - Droid.ZiplineSpline.Spline.SplineLength;
			TargetLocation += TargetTransform.Rotation.ForwardVector * RemainingDistance;
		}

		FVector DroidLocationMinusSidewaysMovement = Droid.ActorLocation - Droid.PreviousSidewaysWorldOffset;
		
		FVector NextLocation = Math::VInterpConstantTo(DroidLocationMinusSidewaysMovement, TargetLocation, DeltaTime, Droid.CurrentSplineSpeed);

		if(Droid.CurrentTiltValue.HasControl())
		{
			Droid.CurrentTiltValue.Value = Math::FInterpTo(Droid.CurrentTiltValue.Value, 0.0, DeltaTime, 5.0);
		}

		Delta = (NextLocation - DroidLocationMinusSidewaysMovement);
		FVector TargetForward = Delta.GetSafeNormal();
		FQuat CurrentTargetRotation = FQuat::MakeFromZX(FVector::UpVector.RotateAngleAxis(Settings.ZiplineSidewaysRollDegrees * -Droid.CurrentTiltValue.Value, TargetForward), TargetForward);

		Droid.ActorRotation = Math::RInterpShortestPathTo(Droid.ActorRotation, CurrentTargetRotation.Rotator(), DeltaTime, Settings.SplineRotationInterpSpeed);
	}

	void GetSidewaysDelta(FVector& Delta, float DeltaTime)
	{
		// Reset previous sideways world offset, easier this way to make everything correct for instance when spline turns etc.
		Delta -= Droid.PreviousSidewaysWorldOffset;
		
		FVector RightNoHeight = Droid.ActorRightVector.GetSafeNormal2D();
		FVector SidewaysWorldOffset = RightNoHeight * Droid.SidewaysDistance.Value;

		Delta += SidewaysWorldOffset;
		Droid.PreviousSidewaysWorldOffset = SidewaysWorldOffset;
	}

	float GetDistanceToDestroyComp() const property
	{
		if(DestroyComp == nullptr)
			return -1.0;

		float Dist = Droid.ZiplineSpline.Spline.GetClosestSplineDistanceToWorldLocation(Droid.ActorLocation);
		return DestroyComp.DistanceOnSpline - Dist;
	}

	bool HasPassedDestroyComp()
	{
		if(DestroyComp == nullptr)
			return false;

		float Dist = Droid.ZiplineSpline.Spline.GetClosestSplineDistanceToWorldLocation(Droid.ActorLocation);
		if(Dist < DestroyComp.DistanceOnSpline)
			return false;

		return true;
	}
}