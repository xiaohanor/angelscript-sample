class UScorpionSiegeWeaponAimingBehaviour : UBasicBehaviour
{
	AScorpionSiegeWeapon Weapon;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Super::Setup();
		Weapon = Cast<AScorpionSiegeWeapon>(Owner);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if(!Super::ShouldActivate())
			return false;
		if(!TargetComp.HasValidTarget())
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(Super::ShouldDeactivate())
			return true;
		if(!TargetComp.HasValidTarget())
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		float Pitch = (TargetComp.Target.FocusLocation - Owner.FocusLocation).Rotation().Pitch;
		Weapon.Mesh.SetRelativeRotation(FRotator(Pitch, 0 , 0));
	}
}