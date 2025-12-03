class USanctuaryBossStopSplineRunCapability : UHazeCapability
{
	default TickGroup = EHazeTickGroup::Gameplay;
	USanctuaryBossStopSplineRunComponent StopperComp;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		StopperComp = USanctuaryBossStopSplineRunComponent::GetOrCreate(Owner);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (StopperComp.SplineRunParent == nullptr)
			return false;
		if (!StopperComp.bShouldStop)
			return false;
		if (!HasReachedSplineDistance())
			return false;
		return true;
	}

	bool HasReachedSplineDistance() const
	{
		return StopperComp.SplineRunParent.MovingActors[StopperComp.SplineRunChildActor].SplinePosition.CurrentSplineDistance >= StopperComp.StopAtDistance;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (!StopperComp.bShouldStop)
			return true;
		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		StopperComp.SplineRunParent.StopInstigators.AddUnique(this);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		StopperComp.SplineRunParent.StopInstigators.Remove(this);
	}
};