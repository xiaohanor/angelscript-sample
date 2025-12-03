class UMeltdownGlitchShootingWeaponCapability : UHazePlayerCapability
{
	default CapabilityTags.Add(n"GlitchShooting");

	default TickGroup = EHazeTickGroup::Movement;

	UMeltdownGlitchShootingUserComponent UserComp;
	UMeltdownGlitchShootingSettings Settings;
	UPlayerAimingComponent AimingComp;

	AMeltdownGlitchShootingWeapon Weapon;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		UserComp = UMeltdownGlitchShootingUserComponent::Get(Player);
		Settings = UMeltdownGlitchShootingSettings::GetSettings(Player);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (!UserComp.bGlitchShootingActive)
			return false;
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (!UserComp.bGlitchShootingActive)
			return true;
		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		if (!IsValid(Weapon))
		{
			Weapon = SpawnActor(UserComp.WeaponClass);
			Weapon.AttachToComponent(Player.Mesh, n"RightAttach");
			Weapon.SetActorRelativeLocation(FVector(-5,-1,15));
			Weapon.SetActorRelativeRotation(FRotator(0,0, 0));
			Weapon.SetActorHiddenInGame(true);
			UserComp.Weapon = Weapon;
		}
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Weapon.DestroyActor();
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if (UserComp.WeaponVisibility.Get())
			Weapon.SetActorHiddenInGame(false);
		else
			Weapon.SetActorHiddenInGame(true);
	}
};