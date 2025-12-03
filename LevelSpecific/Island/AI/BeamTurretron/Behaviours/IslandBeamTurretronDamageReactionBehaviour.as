
class UIslandBeamTurretronDamageReactionBehaviour : UBasicBehaviour
{
	UIslandRedBlueImpactResponseComponent ResponseComp;	
	UBasicAIHealthComponent HealthComp;
	UIslandForceFieldComponent ForceField;
	UIslandForceFieldBubbleComponent ForceFieldBubbleComp;
	UIslandBeamTurretronSettings Settings;
		
	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Super::Setup();
		Settings = UIslandBeamTurretronSettings::GetSettings(Owner);
		HealthComp = UBasicAIHealthComponent::Get(Owner);
		ResponseComp = UIslandRedBlueImpactResponseComponent::Get(Owner);
		ForceField = UIslandForceFieldComponent::Get(Owner);
		ForceFieldBubbleComp = UIslandForceFieldBubbleComponent::Get(Owner);
		ResponseComp.OnImpactEvent.AddUFunction(this, n"OnImpact");		
		HealthComp.OnDie.AddUFunction(this, n"OnDie");
	}

	UFUNCTION()
	private void OnDie(AHazeActor ActorBeingKilled)
	{
		AHazePlayerCharacter Player = Cast<AHazePlayerCharacter>(HealthComp.LastAttacker);
		UIslandBeamTurretronEffectHandler::Trigger_OnDeath(Owner, FIslandBeamTurretronOnDeathParams(Player));
	}

	UFUNCTION()
	private void OnImpact(FIslandRedBlueImpactResponseParams Params)
	{
		if (ForceFieldBubbleComp != nullptr && Owner.IsAnyCapabilityActive(n"IslandForceFieldBubble"))
			return;

		if (ForceField != nullptr && !ForceField.IsDepleted())
			return;
				
		UIslandBeamTurretronEffectHandler::Trigger_OnDamage(Owner, FIslandBeamTurretronProjectileImpactParams(Params.ImpactLocation));
		HealthComp.TakeDamage(Settings.DefaultDamage * Params.ImpactDamageMultiplier, EDamageType::Projectile, Params.Player);
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

