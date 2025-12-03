class USkylineHighwayVehicleWhippableCrashCapability : UHazeCapability
{
	ASkylineHighwayVehicleWhippable Vehicle;
	bool bCrash;
	bool bCrashed;
	FHazeAcceleratedRotator AccRot;
	FRotator TargetRot;
	FHazeAcceleratedFloat AccSpeed;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Vehicle = Cast<ASkylineHighwayVehicleWhippable>(Owner);
		Vehicle.OnTurretDie.AddUFunction(this, n"TurretDie");
	}

	UFUNCTION()
	private void TurretDie(ASkylineHighwayVehicleWhippable CrashVehicle)
	{
		bCrash = true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if(!bCrash)
			return false;
		if(bCrashed)
			return false;
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(ActiveDuration > 5)
			return true;
		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		AccRot.SnapTo(Owner.ActorRotation);
		TargetRot = Owner.ActorRotation + FRotator(0, 0, 70);
		AccSpeed.Value = 0;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		bCrashed = true;
		Vehicle.Explode();
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		AccRot.AccelerateTo(TargetRot, 5, DeltaTime);
		Owner.ActorRotation = AccRot.Value;

		AccSpeed.AccelerateTo(400, 5, DeltaTime);
		Owner.ActorLocation += FVector::DownVector * AccSpeed.Value * DeltaTime;
	}
}