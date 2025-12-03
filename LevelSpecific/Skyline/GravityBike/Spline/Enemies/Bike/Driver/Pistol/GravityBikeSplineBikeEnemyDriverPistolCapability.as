class UGravityBikeSplineBikeEnemyDriverPistolCapability : UHazeCapability
{
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	default CapabilityTags.Add(CapabilityTags::GameplayAction);
	default CapabilityTags.Add(GravityBikeSpline::Enemy::EnemyFireTag);
	default CapabilityTags.Add(GravityBikeSpline::BikeEnemyDriver::Pistol::BikeEnemyDriverPistolTag);

	default TickGroup = EHazeTickGroup::Gameplay;

	AGravityBikeSplineBikeEnemyDriver Driver;
	UGravityBikeSplineBikeEnemyDriverPistolComponent PistolComp;

	UGravityBikeSplineEnemyHealthComponent BikeHealthComp;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Driver = Cast<AGravityBikeSplineBikeEnemyDriver>(Owner);
		PistolComp = UGravityBikeSplineBikeEnemyDriverPistolComponent::Get(Owner);

		BikeHealthComp = UGravityBikeSplineEnemyHealthComponent::Get(Driver.Bike);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if(BikeHealthComp.IsDead())
			return false;

		if(BikeHealthComp.IsRespawning())
			return false;

		if(!GravityBikeSpline::GetGravityBike().BlockEnemyRifleFire.IsEmpty())
			return false;

		if(Driver.GrabTargetComp.GrabState != EGravityBikeWhipGrabState::None)
			return false;

		// Player is moving too slow, fire even if we have no instigators and are far away
		if(PistolComp.IsPlayerTooSlow())
		{
			if(Driver.ActorCenterLocation.DistSquared(GravityBikeSpline::GetGravityBike().ActorLocation) < Math::Square(GravityBikeSpline::BikeEnemyDriver::Pistol::MaxSlowTargetDistance))
				return true;
		}

		if(PistolComp.FireInstigators.Num() == 0)
			return false;

		// Target too far away
		if(Driver.ActorCenterLocation.DistSquared(GravityBikeSpline::GetGravityBike().ActorLocation) > Math::Square(GravityBikeSpline::BikeEnemyDriver::Pistol::MaxTargetDistance))
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(!GravityBikeSpline::GetGravityBike().BlockEnemyRifleFire.IsEmpty())
			return true;

		if(Driver.GrabTargetComp.GrabState != EGravityBikeWhipGrabState::None)
			return true;

		// Player is moving too slow, fire even if we have no instigators and are far away
		if(PistolComp.IsPlayerTooSlow())
		{
			if(Driver.ActorCenterLocation.DistSquared(GravityBikeSpline::GetGravityBike().ActorLocation) < Math::Square(GravityBikeSpline::BikeEnemyDriver::Pistol::MaxSlowTargetDistance))
				return false;
		}

		if(PistolComp.FireInstigators.Num() == 0)
			return true;

		// Target too far away
		if(Driver.ActorCenterLocation.DistSquared(GravityBikeSpline::GetGravityBike().ActorLocation) > Math::Square(GravityBikeSpline::BikeEnemyDriver::Pistol::MaxTargetDistance))
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		PistolComp.bIsFiring = true;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		PistolComp.bIsFiring = false;
	}

	UFUNCTION(BlueprintOverride)
	void PreTick(float DeltaTime)
	{
		PistolComp.AccAimAheadAmount.AccelerateTo(GravityBikeSpline::GetGravityBike().ActorVelocity * PistolComp.PistolAimAheadTime, GravityBikeSpline::BikeEnemyDriver::Pistol::AimAheadDuration, DeltaTime);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		PistolComp.TryFire();
	}
};