class UMeltdownGlitchBazookaEquipCapability : UHazePlayerCapability
{
	default CapabilityTags.Add(CapabilityTags::Movement);
	default TickGroup = EHazeTickGroup::Movement;

	UMeltdownGlitchBazookaUserComponent BazookaComp;
	UPlayerAimingComponent AimingComp;
	UMeltdownGlitchShootingUserComponent ShootingComp;
	
	bool bBazookaVisible = false;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		BazookaComp = UMeltdownGlitchBazookaUserComponent::Get(Player);
		AimingComp = UPlayerAimingComponent::Get(Player);
		ShootingComp = UMeltdownGlitchShootingUserComponent::Get(Player);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (!ShootingComp.bGlitchShootingActive)
			return false;
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (!ShootingComp.bGlitchShootingActive)
			return true;
		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		BazookaComp.Bazooka = SpawnActor(BazookaComp.SwordClass);
		BazookaComp.Bazooka.AttachToComponent(Player.Mesh, n"RightAttach");
		BazookaComp.Bazooka.SetActorRelativeLocation(FVector(-5,-1,15));
		BazookaComp.Bazooka.SetActorRelativeRotation(FRotator(0,0, 0));
	//	BazookaComp.Bazooka.RootComponent.SetAbsolute(false, false, true);

		FAimingSettings AimingSettings;
		AimingSettings.bShowCrosshair = true;
		AimingSettings.OverrideCrosshairWidget = BazookaComp.CrosshairClass;
		AimingSettings.bUseAutoAim = true;
		AimingSettings.bApplyAimingSensitivity = false;
		AimingComp.StartAiming(n"MeltdownGlitchBazooka", AimingSettings);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		BazookaComp.Bazooka.DestroyActor();
		BazookaComp.Bazooka = nullptr;
		AimingComp.StopAiming(n"MeltdownGlitchBazooka");
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if (ShootingComp.WeaponVisibility.Get() != bBazookaVisible)
		{
			if (ShootingComp.WeaponVisibility.Get())
			{
				bBazookaVisible = true;
				if (IsValid(BazookaComp.Bazooka))
					BazookaComp.Bazooka.Appear();
			}
			else
			{
				bBazookaVisible = false;
				if (IsValid(BazookaComp.Bazooka))
					BazookaComp.Bazooka.Disappear();
			}
		}
	}
};