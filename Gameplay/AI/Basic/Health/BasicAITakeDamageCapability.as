
class UBasicAITakeDamageCapability : UHazeCapability
{
	default CapabilityTags.Add(n"Death");
	default TickGroup = EHazeTickGroup::BeforeGameplay;
	default TickGroupOrder = 110; // After death capability

	UBasicAIHealthComponent HealthComp;
	UBasicAIHealthSettings Settings;
	float NewDamage = 0.0;
	EDamageType DamageType;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		HealthComp = UBasicAIHealthComponent::Get(Owner);	
		HealthComp.OnTakeDamage.AddUFunction(this, n"OnTakeDamage");
		Settings = UBasicAIHealthSettings::GetSettings(Owner);
	}

	UFUNCTION()
	private void OnTakeDamage(AHazeActor ActorTakingDamage, AHazeActor Attacker, float Damage, EDamageType TakeDamageType)
	{
		// Reset any old damage in case this damage kill us or cause us to be blocked
		NewDamage = 0.0;

		if (IsBlocked())
			return;

		if (HealthComp.IsDead())
			return;
			
		NewDamage = Damage;
		this.DamageType = TakeDamageType;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (NewDamage > Settings.DamageEffectThreshold)
			return true;
		return false;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		return true;	
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		UBasicAIDamageEffectHandler::Trigger_OnDamage(Owner);
		NewDamage = 0.0;
	}
}

