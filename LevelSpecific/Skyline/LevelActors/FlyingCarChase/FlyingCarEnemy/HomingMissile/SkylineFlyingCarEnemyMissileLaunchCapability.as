class USkylineFlyingCarEnemyMissileLaunchCapability : UHazeCapability
{
	default CapabilityTags.Add(CapabilityTags::GameplayAction);

	default TickGroup = EHazeTickGroup::Gameplay;

	ASkylineFlyingCarEnemyMissile Missile;

	float VelocityAlpha = 0;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Missile = Cast<ASkylineFlyingCarEnemyMissile>(Owner);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if(!Missile.bIsHoming)
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(!Missile.bIsHoming)
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Missile.Velocity = Missile.ActorForwardVector * Missile.MaxVelocity;

	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		Missile.RotationPivot.AddLocalOffset(FVector(0, 0, 2000 * DeltaTime));
		Missile.MeshRoot.AddLocalOffset(FVector(0, 0, 1600 * DeltaTime));


		if(ActiveDuration>= Missile.HomingDelay)
			Missile.bIsHoming = true;
		
	}
};