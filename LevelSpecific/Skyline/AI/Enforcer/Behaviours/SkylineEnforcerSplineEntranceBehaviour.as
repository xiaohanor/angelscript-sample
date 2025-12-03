class USkylineEnforcerSplineEntranceBehaviour : UBasicBehaviour
{
	// Movement only (which is replicated separately)
	default CompoundNetworkSupport = EHazeCompoundNetworkSupport::ActivatesOnControlOnly;

	default Requirements.Add(EBasicBehaviourRequirement::Movement);

	default CapabilityTags.Add(n"SkylineEnforcerSplineEntrance");

	UHazeActorRespawnableComponent RespawnComp;
	UHazeSplineComponent EntrySpline;

	float Distance;
	float Speed = 750;

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
		Distance = 0;
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
		Distance += DeltaTime * Speed;
		Owner.ActorLocation = EntrySpline.GetWorldLocationAtSplineDistance(Distance);
		if(Distance > EntrySpline.SplineLength - 50)
		{
			DeactivateBehaviour();
		}
	}
}
