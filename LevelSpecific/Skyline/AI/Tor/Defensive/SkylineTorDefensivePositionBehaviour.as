class USkylineTorDefensivePositionBehaviour : UBasicBehaviour
{	
	default Requirements.Add(EBasicBehaviourRequirement::Movement);

	UBasicAIHealthComponent HealthComp;
	USkylineTorHoldHammerComponent HoldHammerComp;
	USkylineTorTargetingComponent TorTargetingComp;
	USkylineTorSettings Settings;
	private ASkylineTorDefensivePoint DefensivePoint;

	UFUNCTION(BlueprintOverride)
	void Setup() 
	{
		Super::Setup();
		HealthComp = UBasicAIHealthComponent::Get(Owner);
		HoldHammerComp = USkylineTorHoldHammerComponent::GetOrCreate(Owner);
		TorTargetingComp = USkylineTorTargetingComponent::GetOrCreate(Owner);
		Settings = USkylineTorSettings::GetSettings(Owner);
		DefensivePoint = TListedActors<ASkylineTorDefensivePoint>().Single;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (Super::ShouldActivate() == false)
			return false;
		if (Owner.ActorLocation.Dist2D(DefensivePoint.ActorLocation) < 250)
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
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Super::OnDeactivated();
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if(Owner.ActorLocation.Dist2D(DefensivePoint.ActorLocation) >= 250)
		{
			DestinationComp.MoveTowards(DefensivePoint.ActorLocation, 1000);
		}
		else
		{
			DeactivateBehaviour();
		}
	}
}