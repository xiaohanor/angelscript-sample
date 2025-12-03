
class UIslandOverseerRollerSweepExitBehaviour : UBasicBehaviour
{
	default CompoundNetworkSupport = EHazeCompoundNetworkSupport::LocalOrCrumbNetwork;

	UIslandOverseerSettings Settings;
	UIslandOverseerRollerComponent RollerComp;
	UBasicAIRuntimeSplineComponent SplineComp;

	float Distance = 0;
	FHazeAcceleratedVector AccScale;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Super::Setup();
		Settings = UIslandOverseerSettings::GetSettings(Owner);
		RollerComp = UIslandOverseerRollerComponent::GetOrCreate(Owner);
		SplineComp = UBasicAIRuntimeSplineComponent::GetOrCreate(Owner);
		TListedActors<AIslandOverseerSweepAttackPoint> ListedAttackPoints;
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
		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Super::OnActivated();
		Distance = 0;

		FHazeRuntimeSpline Spline;
		Spline.AddPoint(Owner.ActorLocation);
		Spline.AddPoint(RollerComp.DeployComp.WorldLocation);
		Spline.SetCustomEnterTangentPoint(Owner.ActorLocation + RollerComp.OwningActor.ActorForwardVector * 100);
		Spline.SetCustomExitTangentPoint(RollerComp.DeployComp.WorldLocation - RollerComp.OwningActor.ActorForwardVector * 100);
		SplineComp.SetSpline(Spline);

		// AccScale.SnapTo(FVector::OneVector * Settings.RollerSweepScale);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Super::OnDeactivated();
		RollerComp.Attach();
		// Owner.SetActorScale3D(FVector::OneVector);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		Distance += DeltaTime * Settings.RollerSweepExitSpeed;
		Owner.ActorLocation = SplineComp.Spline.GetLocationAtDistance(Distance);

		// AccScale.AccelerateTo(FVector::OneVector, 1, DeltaTime);
		// Owner.SetActorScale3D(AccScale.Value);

		if(Distance >= SplineComp.Spline.Length)
			DeactivateBehaviour();
	}
}