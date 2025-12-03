class UStormDragonReleaseMagicSphereCapability : UHazeCapability
{
	default CapabilityTags.Add(n"StormDragonReleaseMagicSphereCapability");
	
	default TickGroup = EHazeTickGroup::Gameplay;
	default TickGroupOrder = 100;

	AStormDragonChase StormDragon;

	float FireRate = 0.35;
	float FireTime;

	float YRange = 8000.0;
	float ZRange = 2000.0;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		StormDragon = Cast<AStormDragonChase>(Owner);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (!StormDragon.bActivateMagicSpheres)
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (!StormDragon.bActivateMagicSpheres)
			return true;
		
		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{

	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if (Time::GameTimeSeconds > FireTime)
		{
			FireTime = Time::GameTimeSeconds + FireRate;
			float RY = Math::RandRange(-YRange, YRange);
			float RZ = Math::RandRange(-ZRange, ZRange);

			FVector Location = StormDragon.ActorLocation;
			Location += -StormDragon.ActorForwardVector * 5000.0; 
			Location += StormDragon.ActorRightVector * RY;
			Location += StormDragon.ActorUpVector * RZ;

			StormDragon.SpawnMagicSphere(Location);
		}
	}	
}