class USummitCrystalSkullRecoverBehaviour : UBasicBehaviour
{
	default Requirements.Add(EBasicBehaviourRequirement::Movement);

	USummitCrystalSkullSettings FlyerSettings;
	USummitCrystalSkullComponent FlyerComp;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Super::Setup();
		FlyerSettings = USummitCrystalSkullSettings::GetSettings(Owner);
		FlyerComp = USummitCrystalSkullComponent::GetOrCreate(Owner);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (!Super::ShouldActivate())
			return false;
		if(!TargetComp.HasValidTarget())
			return false;
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (Super::ShouldDeactivate())
			return true;
		if (ActiveDuration > FlyerSettings.RecoverDuration)
			return true;
		if (!TargetComp.HasValidTarget())
			return true;
		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Super::OnActivated();
		FlyerComp.SetVulnerable();
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Super::OnDeactivated();
		FlyerComp.ClearVulnerable();
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		// Move to straight away from target
		FVector Destination = Owner.ActorLocation + (Owner.ActorLocation - TargetComp.Target.ActorLocation).GetSafeNormal() * FlyerSettings.RecoverMoveSpeed;
		Destination = FlyerComp.ProjectToArea(Destination);
		DestinationComp.MoveTowardsIgnorePathfinding(Destination, FlyerSettings.RecoverMoveSpeed);

		// Clear vulnerable a short while before done recovering, so player will have time to react
		if (ActiveDuration > FlyerSettings.RecoverDuration - 0.8)
			FlyerComp.ClearVulnerable();
	}
}

