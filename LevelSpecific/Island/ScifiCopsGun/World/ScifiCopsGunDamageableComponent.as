class UScifiCopsGunDamageableComponent : UScifiCopsGunImpactResponseComponent
{
	UPROPERTY()
	UScifiCopsGunDamageSettings DamageSettings;

	UPROPERTY()
	bool bCanApplyBulletDamage = true;

	UPROPERTY()
	bool bCanApplyThrowDamage = false;

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
			devError("" + Owner.GetName() + " has a ScifiCopsGunDamageableComponent but is missing a BasicAIHealthComponent!");

		if(DamageSettings != nullptr)
			HazeOwner.ApplyDefaultSettings(DamageSettings);
	}
	
	protected void ApplyBulletImpact(AHazePlayerCharacter FromPlayer, FCopsGunBulletImpactParams ImpactParams) override
	{
		Super::ApplyBulletImpact(FromPlayer, ImpactParams);
		
		// Damage from the players control side to make it snappier
		if(!FromPlayer.HasControl())
			return;
		
		if(HazeOwner.IsCapabilityTagBlocked(n"TakeDamage"))
			return;
		
		FVector Impulse = FVector::ZeroVector;
		if(ImpactImpulseAmount > 0)
		{
			FVector Direction = (Owner.ActorLocation - FromPlayer.ActorLocation).GetSafeNormal();
			Impulse = Direction * ImpactImpulseAmount;	
		}

		auto ActiveSettings = UScifiCopsGunDamageSettings::GetSettings(HazeOwner);
		float FinalDamageAmount = ActiveSettings.GetDamage(EScifiCopsGunDamageType::Bullet, AiHealthComponent.MaxHealth);

		HazeOwner.AddMovementImpulse(Impulse);
		AiHealthComponent.TakeDamage(FinalDamageAmount,  EDamageType::Projectile, FromPlayer);
	}

	protected void ApplyWeaponImpact(AHazePlayerCharacter FromPlayer) override
	{
		Super::ApplyWeaponImpact(FromPlayer);

		// Damage from the players control side to make it snappier
		if(!FromPlayer.HasControl())
			return;
		
		if(HazeOwner.IsCapabilityTagBlocked(n"TakeDamage"))
			return;
		
		FVector Impulse = FVector::ZeroVector;
		if(ImpactImpulseAmount > 0)
		{
			FVector Direction = (Owner.ActorLocation - FromPlayer.ActorLocation).GetSafeNormal();
			Impulse = Direction * ImpactImpulseAmount;	
		}

		auto ActiveSettings = UScifiCopsGunDamageSettings::GetSettings(HazeOwner);
		float FinalDamageAmount = ActiveSettings.GetDamage(EScifiCopsGunDamageType::Throw, AiHealthComponent.MaxHealth);

		HazeOwner.AddMovementImpulse(Impulse);
		AiHealthComponent.TakeDamage(FinalDamageAmount,  EDamageType::Impact, FromPlayer);
	}

}