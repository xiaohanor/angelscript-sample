class USkylineFlyingCarEnemyReloadCapability : UHazeCapability
{
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	default CapabilityTags.Add(CapabilityTags::GameplayAction);
	default CapabilityTags.Add(SkylineFlyingCarEnemy::Turret::SkylineCarEnemyTurretFireTag);
	default CapabilityTags.Add(SkylineFlyingCarEnemy::Turret::SkylineCarEnemyTurretTag);

	default TickGroup = EHazeTickGroup::BeforeGameplay;

	ASkylineFlyingCarEnemy CarEnemy;
	USkylineFlyingCarEnemyTurretComponent TurretComp;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		CarEnemy = Cast<ASkylineFlyingCarEnemy>(Owner);
		TurretComp = USkylineFlyingCarEnemyTurretComponent::Get(Owner);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if(!TurretComp.IsMagazineEmpty())
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(TurretComp.HasFinishedReloading())
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		float AdditionalCooldown = Math::RandRange(0,0.5);
		TurretComp.StartReload(AdditionalCooldown);

		Owner.BlockCapabilities(SkylineFlyingCarEnemy::Turret::SkylineCarEnemyTurretFireTag, this);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		TurretComp.FinishReload();

		Owner.UnblockCapabilities(SkylineFlyingCarEnemy::Turret::SkylineCarEnemyTurretFireTag, this);
	}
};