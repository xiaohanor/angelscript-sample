class UScorpionSiegeWeaponDestroyedBehaviour : UBasicBehaviour
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
		if(Weapon.HealthComp.IsAlive())
			return false;
		
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(Super::ShouldDeactivate())
			return true;
		if(Weapon.HealthComp.IsAlive())
			return true;
		
		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Super::OnActivated();

		for(AScorpionSiegeOperator Operator: Weapon.Manager.Operators)
		{
			Operator.HealthComp.Die();
		}
		Weapon.Manager.Reset();
		Weapon.Mesh.SetVisibility(false);
		Weapon.BrokenMesh.SetVisibility(true);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if(Weapon.RepairComp.RepairTime >= ScorpionSettings.RepairDuration)
		{
			Weapon.Revive();
		}
	}
}