class UGravityBikeSplineEnforcerDeathCapability : UHazeCapability
{
	default CapabilityTags.Add(CapabilityTags::GameplayAction);

	default TickGroup = EHazeTickGroup::AfterGameplay;

	AGravityBikeSplineEnforcer Enforcer;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Enforcer = Cast<AGravityBikeSplineEnforcer>(Owner);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if(!Enforcer.HealthComp.IsDead())
			return false;

		if(Enforcer.GrabTargetComp.IsGrabbedOrThrown())
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(!Enforcer.HealthComp.IsDead())
			return true;

		if(Enforcer.GrabTargetComp.IsGrabbedOrThrown())
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		UGravityBikeSplineEnforcerEventHandler::Trigger_OnDeath(Enforcer);
		Enforcer.AddActorDisable(this);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Enforcer.RemoveActorDisable(this);
	}
};