class UIslandBuzzerDamageComponent : UActorComponent
{
	UBasicAIHealthComponent HealthComp;
	UIslandBuzzerSettings Settings;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Settings = UIslandBuzzerSettings::GetSettings(Cast<AHazeActor>(Owner));
		HealthComp = UBasicAIHealthComponent::Get(Owner);
		UIslandRedBlueImpactResponseComponent ResponseComp = UIslandRedBlueImpactResponseComponent::GetOrCreate(Owner);		
		ResponseComp.OnImpactEvent.AddUFunction(this, n"OnImpact");
	}

	UFUNCTION()
	private void OnImpact(FIslandRedBlueImpactResponseParams Data)
	{
		HealthComp.TakeDamage(Settings.RedBlueDamage * Data.ImpactDamageMultiplier, EDamageType::Default, Data.Player);
	}
}