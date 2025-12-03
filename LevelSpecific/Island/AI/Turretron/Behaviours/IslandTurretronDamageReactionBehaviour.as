
class UIslandTurretronDamageReactionBehaviour : UBasicBehaviour
{
	UIslandRedBlueImpactResponseComponent ResponseComp;	
	UBasicAIHealthComponent HealthComp;
	UIslandForceFieldComponent ForceField;
	UIslandForceFieldBubbleComponent ForceFieldBubbleComp;
	UIslandTurretronSettings Settings;
		
	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Super::Setup();
		Settings = UIslandTurretronSettings::GetSettings(Owner);
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
		UIslandTurretronEffectHandler::Trigger_OnDeath(Owner, FIslandTurretronOnDeathParams(Player));
		UIslandTurretronPlayerEffectHandler::Trigger_OnDeath(Game::Mio, FIslandTurretronOnDeathPlayerEventParams(Owner, Player));
		UIslandTurretronPlayerEffectHandler::Trigger_OnDeath(Game::Zoe, FIslandTurretronOnDeathPlayerEventParams(Owner, Player));
	}

	UFUNCTION()
	private void OnImpact(FIslandRedBlueImpactResponseParams Params)
	{
		if (ForceFieldBubbleComp != nullptr && Owner.IsAnyCapabilityActive(n"IslandForceFieldBubble"))
			return;

		if (ForceField != nullptr && !ForceField.IsDepleted())
			return;
				
		UIslandTurretronEffectHandler::Trigger_OnDamage(Owner, FIslandTurretronProjectileImpactParams(Params.ImpactLocation));
		UIslandTurretronPlayerEffectHandler::Trigger_OnDamage(Game::Mio, FIslandTurretronProjectileImpactPlayerEventParams(Params.ImpactLocation, Owner, Params.Player));
		UIslandTurretronPlayerEffectHandler::Trigger_OnDamage(Game::Zoe, FIslandTurretronProjectileImpactPlayerEventParams(Params.ImpactLocation, Owner, Params.Player));

		HealthComp.TakeDamage(Settings.DefaultDamage * Params.ImpactDamageMultiplier, EDamageType::Projectile, Params.Player);
	}

}

