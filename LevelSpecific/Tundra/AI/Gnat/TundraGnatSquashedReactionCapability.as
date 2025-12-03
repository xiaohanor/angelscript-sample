class UTundraGnatSquashedReactionCapability : UHazeCapability
{	
	default CapabilityTags.Add(n"Damage");
	default TickGroup = EHazeTickGroup::AfterGameplay;
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	UTundraGnatSettings Settings;
	UBasicAIHealthComponent HealthComp;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		auto SquashComp = UTundraPlayerSnowMonkeyGroundSlamResponseComponent::Get(Owner);
		SquashComp.OnGroundSlam.AddUFunction(this, n"OnSquash"); 
		Settings = UTundraGnatSettings::GetSettings(Owner);
		HealthComp = UBasicAIHealthComponent::Get(Owner);
	}

	UFUNCTION()
	private void OnSquash(ETundraPlayerSnowMonkeyGroundSlamType GroundSlamType, FVector PlayerLocation)
	{
		// Splat!
		HealthComp.TakeDamage(HealthComp.MaxHealth, EDamageType::MeleeBlunt, Game::Mio);
		UTundraGnatEffectEventHandler::Trigger_OnSquashed(Owner);
	}
}
