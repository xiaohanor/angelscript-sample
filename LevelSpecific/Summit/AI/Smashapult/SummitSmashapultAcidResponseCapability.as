class USummitSmashapultAcidResponseCapability : UHazeCapability
{
	default TickGroup = EHazeTickGroup::BeforeGameplay;

	UBasicAIHealthComponent HealthComp;
	USummitMeltComponent MeltComp;
	USummitSmashapultSettings Settings;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		HealthComp = UBasicAIHealthComponent::Get(Owner);
		MeltComp = USummitMeltComponent::GetOrCreate(Owner);
		Settings = USummitSmashapultSettings::GetSettings(Owner);
		auto AcidResponseComp = UAcidResponseComponent::GetOrCreate(Owner);
		AcidResponseComp.OnAcidHit.AddUFunction(this, n"OnAcidHit");
		auto RespawnComp = UHazeActorRespawnableComponent::Get(Owner);
		RespawnComp.OnRespawn.AddUFunction(this, n"OnRespawn");
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		// Delegates only for now
		return false;
	}

	UFUNCTION()
	private void OnRespawn()
	{
		MeltComp.ImmediateRestore();
	}

	UFUNCTION()
	private void OnAcidHit(FAcidHit Hit)
	{
		HealthComp.TakeDamage(Hit.Damage * Settings.DamageFromAcidFactor, EDamageType::Acid, Hit.PlayerInstigator);
	}
}
