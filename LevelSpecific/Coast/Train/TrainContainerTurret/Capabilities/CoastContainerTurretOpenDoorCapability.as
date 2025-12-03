class UCoastContainerTurretOpenDoorCapability : UHazeCapability
{
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;
	
	UCoastContainerTurretDoorComponent TurretDoorComp;

	FRotator OpenRotation;
	FHazeAcceleratedRotator RotationAcc;
	float Duration = 1;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		OpenRotation = FRotator(0, 0, 90);
		TurretDoorComp = UCoastContainerTurretDoorComponent::GetOrCreate(Owner);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if(!TurretDoorComp.DoOpen)
			return false;
		if(TurretDoorComp.IsOpen)
			return false;
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(ActiveDuration > Duration)
			return true;
		if(TurretDoorComp.IsOpen)
			return true;
		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		RotationAcc.Value = TurretDoorComp.RelativeRotation;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		TurretDoorComp.RelativeRotation = OpenRotation;
		TurretDoorComp.IsOpen = true;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		RotationAcc.AccelerateTo(OpenRotation, Duration, DeltaTime);
		TurretDoorComp.RelativeRotation = RotationAcc.Value;
	}
}