class USummitSplineFollowCapability : UHazeCapability
{
	default CapabilityTags.Add(CapabilityTags::GameplayAction);
	default CapabilityTags.Add(CapabilityTags::Movement);

	default TickGroup = EHazeTickGroup::Gameplay;

	USummitSplineFollowComponent SplineFollowComp;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		auto ActorComp = Owner.GetComponentByClass(USummitSplineFollowComponent);
		SplineFollowComp = Cast<USummitSplineFollowComponent>(ActorComp);
		if(SplineFollowComp == nullptr)
			devError(f"{this} is added on something that does not have a SummitSplineFollowComponent.");
		
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if(!SplineFollowComp.bShouldMove)
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(!SplineFollowComp.bShouldMove)
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
	void TickActive(float DeltaTime)
	{
		SplineFollowComp.MoveAlongSpline(500 * DeltaTime);
	}
};