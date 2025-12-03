class USkylineHighwayBossVehicleGunAimCapability : UHazeCapability
{
	ASkylineHighwayBossVehicle Vehicle;
	FHazeAcceleratedRotator AccRotation;
	USkylineHighwayBossVehicleGunComponent GunComp;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Vehicle = Cast<ASkylineHighwayBossVehicle>(Owner);
		GunComp = USkylineHighwayBossVehicleGunComponent::GetOrCreate(Owner);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		return true;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if(Vehicle.TargetPlayer != nullptr && !GunComp.bHasAim.Get())
		{
			FRotator Rotation = (Vehicle.TargetPlayer.ActorLocation - Owner.ActorLocation).Rotation();
			FRotator LocalRotation = Owner.ActorTransform.InverseTransformRotation(Rotation);
			AccRotation.AccelerateTo(LocalRotation, 1, DeltaTime);
		}
		else if(GunComp.bHasAim.Get())
		{
			FRotator LocalRotation = Owner.ActorTransform.InverseTransformRotation(GunComp.AimRotation);
			AccRotation.AccelerateTo(LocalRotation, GunComp.Duration, DeltaTime);
		}

		Vehicle.GunBaseMesh.RelativeRotation = FRotator(0, AccRotation.Value.Yaw, 0);
		Vehicle.GunCaseMesh.RelativeRotation = FRotator(AccRotation.Value.Pitch, 0, 0);
	}
}