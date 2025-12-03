// Cooldown after performing an attack
class UIslandPunchotronCooldownBehaviour : UBasicBehaviour
{
	default Requirements.Add(EBasicBehaviourRequirement::Animation);
	default Requirements.Add(EBasicBehaviourRequirement::Weapon);
	default Requirements.Add(EBasicBehaviourRequirement::Movement); 
	default Requirements.Add(EBasicBehaviourRequirement::Focus); 

	UIslandForceFieldComponent ForceFieldComp;
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
	}


	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (!Super::ShouldActivate())
			return false;
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (Super::ShouldDeactivate())
			return true;
		if (ActiveDuration > Settings.CooldownDuration)
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
		Params.StartTime = 0.0;
		//Punchotron.PlaySlotAnimation(Punchotron.AnimationTaunt, Params);
		AnimComp.RequestFeature(FeatureTagIslandPunchotron::AttackCooldown, EBasicBehaviourPriority::High, this, Settings.CooldownDuration);
		UIslandPunchotronEffectHandler::Trigger_OnExhaustVentStart(Owner, FIslandPunchotronExhaustVentParams(Punchotron.ExhaustVentLocation));
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Super::OnDeactivated();
		AttackComp.bEnableTaunt = false;
		UIslandPunchotronEffectHandler::Trigger_OnExhaustVentStop(Owner);
	}

}
