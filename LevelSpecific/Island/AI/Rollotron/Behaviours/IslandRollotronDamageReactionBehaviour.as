class UIslandRollotronDamageReactionBehaviour : UBasicBehaviour
{
	default Requirements.Add(EBasicBehaviourRequirement::Animation);

	//UIslandRedBlueImpactResponseComponent ResponseComp;
	UBasicAIHealthComponent HealthComp;
	UIslandRollotronSettings Settings;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Super::Setup();
		Settings = UIslandRollotronSettings::GetSettings(Owner);
		HealthComp = UBasicAIHealthComponent ::Get(Owner);
		//ResponseComp = UIslandRedBlueImpactResponseComponent::GetOrCreate(Owner);
		//ResponseComp.OnImpactEvent.AddUFunction(this, n"OnImpact");
		HealthComp.OnDie.AddUFunction(this, n"OnDie");
	}

	UFUNCTION()
	private void OnDie(AHazeActor ActorBeingKilled)
	{
		UIslandRollotronEffectHandler::Trigger_OnDetonated(Owner);

		auto AudioManager = TListedActors<AAIIslandRollotronAudioManagerActor>().GetSingle();
		UIslandRollotronEffectHandler::Trigger_OnRollotronDetonate(AudioManager, FRollotronEventParams(Cast<AAIIslandRollotron>(Owner)));
	}

	UFUNCTION()
	private void OnImpact(FIslandRedBlueImpactResponseParams Data)
	{
		HealthComp.TakeDamage(Settings.DefaultDamage * Data.ImpactDamageMultiplier, EDamageType::Projectile, Data.Player);		
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (!Super::ShouldActivate())
			return false;
		if (Time::GetGameTimeSince(HealthComp.LastDamageTime) > 0.5)
			return false;
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (Super::ShouldDeactivate())
			return true;
		if (ActiveDuration > Settings.HurtReactionDuration)
			return true;
		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Super::OnActivated();
		AnimComp.RequestFeature(LocomotionFeatureAITags::HurtReactions, SubTagAIHurtReactions::Default, EBasicBehaviourPriority::Medium, this, Settings.HurtReactionDuration);		
	}
}
