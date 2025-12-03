class UCoastShoulderTurretAttachCapability : UHazePlayerCapability
{
	default TickGroup = EHazeTickGroup::AfterGameplay;
	default CapabilityTags.Add(n"ShoulderTurret");

	ACoastShoulderTurret Turret;

	UCoastShoulderTurretComponent TurretComp;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		TurretComp = UCoastShoulderTurretComponent::Get(Player);

		Turret = SpawnActor(TurretComp.TurretClass, bDeferredSpawn = true);
		Turret.MakeNetworked(this);
		TurretComp.Turret = Turret;
		Turret.Player = Player;
		FinishSpawningActor(Turret);
		Turret.AddActorDisable(this);
		Turret.AttachToActor(Player, TurretComp.AttachmentSocketName
			, EAttachmentRule::SnapToTarget, EAttachmentRule::SnapToTarget, EAttachmentRule::SnapToTarget, false);
	}


	UFUNCTION(BlueprintOverride)
	void OnRemoved()
	{
		Turret.DestroyActor();
		Turret = nullptr;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Turret.ActiveInstigators.Apply(true, this, EInstigatePriority::Low);
		Turret.RemoveActorDisable(this);

		Player.ApplyCameraSettings(TurretComp.TurretCameraSettings, 0.0, this, SubPriority = 100);

		Outline::AddToPlayerOutlineActor(Turret, Player, this, EInstigatePriority::Normal);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Turret.ActiveInstigators.Clear(this);
		Turret.AddActorDisable(this);

		Player.ClearCameraSettingsByInstigator(this);

		Outline::ClearOutlineOnActor(Turret, Player, this);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
	}
};