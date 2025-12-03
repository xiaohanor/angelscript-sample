class UIslandPunchotronTauntBehaviour : UBasicBehaviour
{
	default Requirements.Add(EBasicBehaviourRequirement::Animation);
	default Requirements.Add(EBasicBehaviourRequirement::Weapon);
	default Requirements.Add(EBasicBehaviourRequirement::Movement); 
	default Requirements.Add(EBasicBehaviourRequirement::Focus); 

	UIslandForceFieldComponent ForceFieldComp;
	UIslandRedBlueImpactResponseComponent ResponseComp;
	UBasicAIHealthComponent HealthComp;
	UIslandPunchotronAttackComponent AttackComp;
	AAIIslandPunchotron Punchotron;
	UIslandPunchotronSettings Settings;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Super::Setup();
		Settings = UIslandPunchotronSettings::GetSettings(Owner);
		ForceFieldComp = UIslandForceFieldComponent::Get(Owner);
		HealthComp = UBasicAIHealthComponent ::Get(Owner);
		AttackComp = UIslandPunchotronAttackComponent::GetOrCreate(Owner);
		Punchotron = Cast<AAIIslandPunchotron>(Owner);
		ResponseComp = UIslandRedBlueImpactResponseComponent::GetOrCreate(Owner);
		ResponseComp.OnImpactEvent.AddUFunction(this, n"OnImpact");		
	}

	UFUNCTION()
	private void OnImpact(FIslandRedBlueImpactResponseParams Data)
	{
		if (!IsActive())
			return;

		if (!ForceFieldComp.IsDepleted())
			return;
		
		Punchotron.StopSlotAnimation();
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (!Super::ShouldActivate())
			return false;
		if (!AttackComp.bEnableTaunt)
			return false;
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (Super::ShouldDeactivate())
			return true;
		if (ActiveDuration > Settings.TauntDuration)
			return true;
		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Super::OnActivated();
		FHazeSlotAnimSettings Params;
		Params.BlendTime = 0.2;
		Params.BlendOutTime = 0.2;
		Params.bLoop = false;
		Params.StartTime = 3.2;
		Punchotron.PlaySlotAnimation(Punchotron.AnimationTaunt, Params);
		//TODO: AnimComp.RequestFeature(FeatureTagIslandPunchotron::Taunt, EBasicBehaviourPriority::High, this, Settings.StunnedDuration);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Super::OnDeactivated();
		AttackComp.bEnableTaunt = false;		
	}

}
