class UIslandRedBlueTargetableComponent : UIslandRedBlueWeaponBaseTargetable
{
	default TargetableCategory = n"IslandRedBlueTargetable";

	// Can we target this without being in an active aim mode
	UPROPERTY(EditAnywhere, BlueprintReadOnly, Category = "Targetable")
	bool bAllowWhenHipFire = true;

	// Can we target this when we are in an active aim mode
	UPROPERTY(EditAnywhere, BlueprintReadOnly, Category = "Targetable")
	bool bAllowWhenAim = true;

	// If true grenades will aim towards this targetable, if false grenades will just aim towards the crosshair.
	UPROPERTY(EditAnywhere, BlueprintReadOnly, Category = "Targetable")
	bool bTargetWithGrenade = true;

	bool CheckTargetable(FTargetableQuery& Query) const override
	{
		auto WeaponComponent = UIslandRedBlueWeaponUserComponent::Get(Query.Player);
		const bool bIsAiming = WeaponComponent.IsAiming();
		
		// This is not allowed when we are aiming
		if(bIsAiming && !bAllowWhenAim)
			return false;
		
		// This is not allowed when performing hip fire
		if(!bIsAiming && !bAllowWhenHipFire)
			return false;

		return Super::CheckTargetable(Query);
	}
}