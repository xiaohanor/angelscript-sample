class USkylineExploderProximityExplosionBehaviour : UBasicBehaviour
{
	default Requirements.Add(EBasicBehaviourRequirement::Movement);
	default Requirements.Add(EBasicBehaviourRequirement::Animation);
	default Requirements.Add(EBasicBehaviourRequirement::Weapon);

	USkylineExploderSettings ExploderSettings;
	UBasicAIHealthComponent HealthComp;
	USkylineExploderExplosionComp ExplosionComp;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Super::Setup();
		ExploderSettings = USkylineExploderSettings::GetSettings(Owner);
		HealthComp = UBasicAIHealthComponent::Get(Owner);
		ExplosionComp = USkylineExploderExplosionComp::Get(Owner);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if(!Super::ShouldActivate())
			return false;
		if(!TargetComp.HasValidTarget())
			return false;
		if(HealthComp.IsDead())
			return false;
		if(TargetComp.Target.ActorLocation.Distance(Owner.ActorLocation) > ExploderSettings.ProximityExplosionDistance)
			return false;
		
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (Super::ShouldDeactivate())
			return true;
		return true;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Super::OnActivated();
		HealthComp.Die();	
	}
}