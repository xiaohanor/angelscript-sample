
/** A Component made to apply damage on AIs */
class UIslandNunchuckDamageableComponent : UIslandNunchuckImpactResponseComponent
{
	UPROPERTY()
	UIslandNunchuckDamageSettings DamageSettings;

	// Apply an impulse on the owner when taking damage.
	UPROPERTY()
	float ImpactImpulseAmount = 0;

	private AHazeActor HazeOwner;
	private UBasicAIHealthComponent AiHealthComponent;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		HazeOwner = Cast<AHazeActor>(Owner);

		AiHealthComponent = UBasicAIHealthComponent::Get(Owner);
		if(AiHealthComponent == nullptr)
			devError("" + Owner.GetName() + " has a IslandNunchuckDamageableComponent but is missing a BasicAIHealthComponent!");

		if(DamageSettings != nullptr)
			HazeOwner.ApplyDefaultSettings(DamageSettings);
	}
	
	bool ApplyImpact(AHazePlayerCharacter ImpactInstigator, FIslandNunchuckDamage Damage) override
	{
		if(HazeOwner.IsCapabilityTagBlocked(n"TakeDamage"))
			return false;

		if(!Super::ApplyImpact(ImpactInstigator, Damage))
			return false;

		// We only apply damage from the players control side
		// But this still count as a valid apply imapct
		if(!ImpactInstigator.HasControl())
			return true;
		
		if(ImpactImpulseAmount > 0)
		{
			FVector Direction = (Owner.ActorLocation - ImpactInstigator.ActorLocation).GetSafeNormal();
			FVector Impulse = Direction * ImpactImpulseAmount;
			HazeOwner.AddMovementImpulse(Impulse);
		}

		auto ActiveSettings = UIslandNunchuckDamageSettings::GetSettings(HazeOwner);
		float FinalDamageAmount = ActiveSettings.GetDamage(Damage, AiHealthComponent.MaxHealth);
		AiHealthComponent.TakeDamage(FinalDamageAmount, EDamageType::Default, ImpactInstigator);
		return true;
	}
	
}