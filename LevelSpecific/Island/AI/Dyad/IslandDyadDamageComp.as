class UIslandDyadDamageComponent : UActorComponent
{
	UBasicAIHealthComponent HealthComp;
	UIslandForceFieldComponent ForceFieldComponent;
	UIslandDyadSettings Settings;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Settings = UIslandDyadSettings::GetSettings(Cast<AHazeActor>(Owner));
		HealthComp = UBasicAIHealthComponent::Get(Owner);
		ForceFieldComponent = UIslandForceFieldComponent::Get(Owner);
		UIslandRedBlueImpactResponseComponent ResponseComp = UIslandRedBlueImpactResponseComponent::GetOrCreate(Owner);		
		ResponseComp.OnImpactEvent.AddUFunction(this, n"OnImpact");
	}

	UFUNCTION()
	private void OnImpact(FIslandRedBlueImpactResponseParams Data)
	{
		if (!ForceFieldComponent.IsDepleted())
			return;

		HealthComp.TakeDamage(Settings.ForceFieldRedBlueDamage * Data.ImpactDamageMultiplier, EDamageType::Default, Data.Player);
	}
}