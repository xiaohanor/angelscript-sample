class UBasicSplineEntranceBehaviour : UBasicBehaviour
{
	// Movement only (which is replicated separately)
	default CompoundNetworkSupport = EHazeCompoundNetworkSupport::ActivatesOnControlOrLocalOnly;

	default Requirements.Add(EBasicBehaviourRequirement::Movement);

	UHazeActorRespawnableComponent RespawnComp;
	UHazeSplineComponent EntrySpline;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Super::Setup();
		RespawnComp = UHazeActorRespawnableComponent::Get(Owner);
		RespawnComp.OnRespawn.AddUFunction(this, n"OnRespawn");
	}

	UFUNCTION()
	private void OnRespawn()
	{
		EntrySpline = RespawnComp.SpawnParameters.Spline;
		if (EntrySpline != nullptr)
			Owner.TeleportActor(EntrySpline.GetWorldLocationAtSplineDistance(0.0), EntrySpline.GetWorldRotationAtSplineDistance(0.0).Rotator(), this);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (!Super::ShouldActivate())
			return false;
		if (EntrySpline == nullptr)
			return false;
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (Super::ShouldDeactivate())
			return true;
		if (EntrySpline == nullptr)
			return true;
		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Super::OnDeactivated();
		EntrySpline = nullptr;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		DestinationComp.MoveAlongSpline(EntrySpline, BasicSettings.SplineEntranceMoveSpeed);
		if (DestinationComp.IsAtSplineEnd(EntrySpline, BasicSettings.SplineEntranceCompletionRange))
		{
			DeactivateBehaviour();				
		}
	}
}
