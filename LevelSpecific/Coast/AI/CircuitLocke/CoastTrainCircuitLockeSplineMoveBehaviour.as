class UCoastTrainCircuitLockeSplineMoveBehaviour : UBasicBehaviour
{
	// Movement only (which is replicated separately)
	default CompoundNetworkSupport = EHazeCompoundNetworkSupport::ActivatesOnControlOnly;

	default Requirements.Add(EBasicBehaviourRequirement::Movement);

	UCoastTrainCircuitLockeSettings Settings;
	UCoastTrainCircuitLockeSplineMoveComponent SplineComp;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Super::Setup();
		Settings = UCoastTrainCircuitLockeSettings::GetSettings(Owner);
		SplineComp = UCoastTrainCircuitLockeSplineMoveComponent::GetOrCreate(Owner);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (!Super::ShouldActivate())
			return false;
		if (SplineComp.CurrentSpline == nullptr)
			return false;
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (Super::ShouldDeactivate())
			return true;
		if (SplineComp.CurrentSpline == nullptr)
			return true;
		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Super::OnActivated();
		SplineComp.OnStart.Broadcast();
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Super::OnDeactivated();
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		DestinationComp.MoveAlongSpline(SplineComp.CurrentSpline.Spline, Settings.MoveSpeed);
		if (DestinationComp.IsAtSplineEnd(SplineComp.CurrentSpline.Spline, Settings.MoveSpeed))
		{
			SplineComp.OnFinished.Broadcast();
			SplineComp.FinishSpline();
			DeactivateBehaviour();				
		}
	}
}