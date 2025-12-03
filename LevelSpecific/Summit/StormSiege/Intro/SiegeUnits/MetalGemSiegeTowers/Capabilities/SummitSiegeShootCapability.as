class USummitSiegeShootCapability : UHazeCapability
{
	default CapabilityTags.Add(CapabilityTags::GameplayAction);

	default TickGroup = EHazeTickGroup::Gameplay;

	USiegeActivationComponent ActivationComp;
	USiegeProjectileShootComponent ShootComp;
	USiegeHealthComponent HealthComp;

	float NextFireTime;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		ActivationComp = USiegeActivationComponent::Get(Owner);
		ShootComp = USiegeProjectileShootComponent::Get(Owner);
		HealthComp = USiegeHealthComponent::Get(Owner);
	}

	UFUNCTION(BlueprintOverride)
	void PreTick(float DeltaTime)
	{
		if (ShootComp.bDebug)
		{
			PrintToScreen("" + Owner + "HealthComp.bAlive: " + HealthComp.bAlive);
			PrintToScreen("" + Owner + "ActivationComp.bCanBeActive: " + ActivationComp.bCanBeActive);
			PrintToScreen("" + Owner + "CanFire(): " + CanFire());
		}
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (!HealthComp.bAlive)
			return false;

		if (!CanFire())
			return false;
		
		if (!ActivationComp.bCanBeActive)
			return false;

		if (Time::GameTimeSeconds < NextFireTime)
			return false;
		
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		return true;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		ShootComp.SpawnProjectile(GetClosestPlayer());
		NextFireTime = Time::GameTimeSeconds + ShootComp.SpawnRate;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
	}

	AHazePlayerCharacter GetClosestPlayer() const
	{
		return Game::Mio.GetDistanceTo(Owner) < Game::Zoe.GetDistanceTo(Owner) ? Game::Mio : Game::Zoe;
	}

	bool CanFire() const
	{
		if (GetClosestPlayer().GetDistanceTo(Owner) < ShootComp.MinRangeRequired)
		{
			float Distance = GetClosestPlayer().OtherPlayer.GetDistanceTo(Owner);
			if (Distance < ShootComp.MinRangeRequired)
				return false;
			else 
				return true;
		}

		return true;
	}
};