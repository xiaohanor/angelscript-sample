class UGravityBikeMachineGunFireCapability : UHazePlayerCapability
{
	UGravityBikeWeaponUserComponent WeaponComp;
	UGravityBikeMachineGunComponent MachineGunComp;
	AGravityBikeMachineGun MachineGun;

	bool bUseLeftMuzzle = false;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		WeaponComp = UGravityBikeWeaponUserComponent::Get(Owner);
		MachineGunComp = UGravityBikeMachineGunComponent::Get(Owner);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (!IsActioning(GravityBikeWeapon::FireAction))
			return false;

		if (!MachineGunComp.IsEquipped())
			return false;

		if (!WeaponComp.HasChargeFor(MachineGunComp.MachineGun.GetChargePerShot()))
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (!IsActioning(GravityBikeWeapon::FireAction))
			return true;

		if (!MachineGunComp.IsEquipped())
			return true;

		if (!WeaponComp.HasChargeFor(MachineGunComp.MachineGun.GetChargePerShot()))
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		MachineGun = MachineGunComp.MachineGun;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		WeaponComp.UpdateIsFired();

		if (Time::GameTimeSeconds < MachineGunComp.TimeLastFired + MachineGun.FireInterval)
			return;

		FireWeapon();
	}

	void FireWeapon()
	{
		auto GravityBike = UGravityBikeFreeDriverComponent::Get(Player).GetGravityBike();

		bUseLeftMuzzle = !bUseLeftMuzzle;
		auto MuzzleComp = GetCurrentMuzzle();
		
		FVector Direction = MuzzleComp.WorldTransform.Rotation.ForwardVector;

		auto Projectile = SpawnActor(MachineGun.BulletClass, bDeferredSpawn = true);

		FTransform SpawnTransform = MuzzleComp.WorldTransform;
		SpawnTransform.Scale3D = FVector::OneVector;

		FinishSpawningActor(Projectile, SpawnTransform);
	
		Niagara::SpawnOneShotNiagaraSystemAttached(MachineGun.MuzzleFlash, MuzzleComp);
		UGravityBikeFreeEventHandler::Trigger_OnWeaponFire(GravityBike);
	
		WeaponComp.DecreaseCharge(1.0 / MachineGun.ShotsPerMaxCharge);
	
		MachineGunComp.TimeLastFired = Time::GameTimeSeconds;

		FHazeFrameForceFeedback ForceFeedback;
		ForceFeedback.LeftMotor = 0.1;
		ForceFeedback.RightMotor = 0.1;
		ForceFeedback.LeftTrigger = 0.1;
		ForceFeedback.RightTrigger = 0.1;
		Player.SetFrameForceFeedback(ForceFeedback, 0.09);

		MachineGun.BP_OnWeaponFire(Player);
	}

	UArrowComponent GetCurrentMuzzle() const
	{
		return bUseLeftMuzzle ? MachineGun.LeftMuzzle : MachineGun.RightMuzzle;
	}
}