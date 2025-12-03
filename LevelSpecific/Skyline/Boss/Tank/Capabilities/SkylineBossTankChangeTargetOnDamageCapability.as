struct FSkylineBossTankChangeTargetOnDamageActivateParams
{
	AHazeActor LatestDamageInstigator;
};

class USkylineBossTankChangeTargetOnDamageCapability : USkylineBossTankChildCapability
{
	default CapabilityTags.Add(SkylineBossTankTags::SkylineBossTankChangeTargetOnDamage);

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Super::Setup();
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate(FSkylineBossTankChangeTargetOnDamageActivateParams& Params) const
	{
		if (BossTank.LatestDamageInstigator == nullptr)
			return false;
		
		if (!ShouldChargeTarget())
			return false;

		Params.LatestDamageInstigator = BossTank.LatestDamageInstigator;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		return true;
/*
		if (ActiveDuration > 2.0)
			return true;
*/

//		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FSkylineBossTankChangeTargetOnDamageActivateParams Params)
	{
		BossTank.SetTargetChange(Params.LatestDamageInstigator, 0.0);
/*
		BossTank.SetTarget(BossTank.LatestDamageInstigator);

		BossTank.BlockCapabilities(SkylineBossTankTags::SkylineBossTankAttack, this);
		BossTank.BlockCapabilities(SkylineBossTankTags::SkylineBossTankChase, this);
		BossTank.BlockCapabilities(SkylineBossTankTags::SkylineBossTankChangeTarget, this);

		BossTank.InstigatedSpeed.Apply(500.0, this, EInstigatePriority::High);
*/
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
/*
		BossTank.UnblockCapabilities(SkylineBossTankTags::SkylineBossTankAttack, this);
		BossTank.UnblockCapabilities(SkylineBossTankTags::SkylineBossTankChase, this);
		BossTank.UnblockCapabilities(SkylineBossTankTags::SkylineBossTankChangeTarget, this);

		BossTank.InstigatedSpeed.Clear(this);
*/
		BossTank.LatestDamageInstigator = nullptr;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
	}

	bool ShouldChargeTarget() const
	{
		auto Player = Cast<AHazePlayerCharacter>(BossTank.LatestDamageInstigator);
		if (Player != nullptr && Player.IsPlayerDead())
			return false;

		auto WeaponComp = UGravityBikeWeaponUserComponent::Get(BossTank.LatestDamageInstigator);
		if (WeaponComp != nullptr)
			return !WeaponComp.HasChargeForEquippedWeapon();
	
		return false;
	}
}