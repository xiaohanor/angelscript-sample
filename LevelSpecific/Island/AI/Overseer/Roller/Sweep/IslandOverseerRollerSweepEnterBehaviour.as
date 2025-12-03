
class UIslandOverseerRollerSweepEnterBehaviour : UBasicBehaviour
{
	default CompoundNetworkSupport = EHazeCompoundNetworkSupport::LocalOrCrumbNetwork;

	UIslandOverseerSettings Settings;
	UIslandOverseerRollerComponent RollerComp;
	// UBasicAIRuntimeSplineComponent SplineComp;
	UIslandOverseerRollerSweepComponent SweepComp;

	float Distance = 0;
	FHazeAcceleratedVector AccLocation;
	FHazeAcceleratedVector AccScale;
	FHazeAcceleratedRotator AccRotation;
	FVector TargetLocation;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Super::Setup();
		Settings = UIslandOverseerSettings::GetSettings(Owner);
		RollerComp = UIslandOverseerRollerComponent::GetOrCreate(Owner);
		// SplineComp = UBasicAIRuntimeSplineComponent::GetOrCreate(Owner);
		SweepComp = UIslandOverseerRollerSweepComponent::GetOrCreate(Owner);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if(!Super::ShouldActivate())
			return false;
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(Super::ShouldDeactivate())
			return true;
		if(ActiveDuration > 2)
			return true;
		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Super::OnActivated();
		Distance = 0;

		TargetLocation = SweepComp.StartLocation + FVector::UpVector * 750;

		// FHazeRuntimeSpline Spline;
		// Spline.AddPoint(Owner.ActorLocation);
		// Spline.AddPoint(TargetLocation);
		// Spline.SetCustomEnterTangentPoint(Owner.ActorLocation - RollerComp.OwningActor.ActorForwardVector * 100);
		// Spline.SetCustomExitTangentPoint(Location + RollerComp.OwningActor.ActorForwardVector * 100);
		// SplineComp.SetSpline(Spline);

		AccLocation.SnapTo(Owner.ActorLocation);
		AccScale.SnapTo(FVector::OneVector);
		AccRotation.SnapTo(Owner.ActorRotation);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Super::OnDeactivated();
		Owner.SetActorLocation(TargetLocation);
		if(RollerComp.OwningActor != nullptr)
			Owner.SetActorRotation(RollerComp.OwningActor.ActorForwardVector.Rotation());
		UIslandOverseerRollerEventHandler::Trigger_OnSweepTelegraphEnd(Owner);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		// Distance += DeltaTime * Settings.RollerSweepEnterSpeed;
		// Owner.ActorLocation = SplineComp.Spline.GetLocationAtDistance(Distance);

		// AccScale.AccelerateTo(FVector::OneVector * Settings.RollerSweepScale, 1, DeltaTime);
		// Owner.SetActorScale3D(AccScale.Value);

		if(RollerComp.OwningActor != nullptr)
			AccRotation.AccelerateTo(RollerComp.OwningActor.ActorForwardVector.Rotation(), 1, DeltaTime);
		Owner.SetActorRotation(AccRotation.Value);

		AccLocation.SpringTo(TargetLocation, 100, 0.2, DeltaTime);
		Owner.SetActorLocation(AccLocation.Value);

		// if(Distance >= SplineComp.Spline.Length)
		// 	DeactivateBehaviour();
	}
}