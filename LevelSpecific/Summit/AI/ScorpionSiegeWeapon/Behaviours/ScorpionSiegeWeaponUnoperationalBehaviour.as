class UScorpionSiegeWeaponUnoperationalBehaviour : UBasicBehaviour
{
	default Requirements.Add(EBasicBehaviourRequirement::Weapon);
	default Requirements.Add(EBasicBehaviourRequirement::Focus);

	AScorpionSiegeWeapon Weapon;
	UScorpionSiegeWeaponSettings ScorpionSettings;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Super::Setup();
		Weapon = Cast<AScorpionSiegeWeapon>(Owner);
		ScorpionSettings = UScorpionSiegeWeaponSettings::GetSettings(Owner);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if(!Super::ShouldActivate())
			return false;
		if(Weapon.bOperational || !Weapon.HealthComp.IsAlive())
			return false;
		
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(Super::ShouldDeactivate())
			return true;
		if(Weapon.bOperational || !Weapon.HealthComp.IsAlive())
			return true;
		
		return false;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		
	}
}