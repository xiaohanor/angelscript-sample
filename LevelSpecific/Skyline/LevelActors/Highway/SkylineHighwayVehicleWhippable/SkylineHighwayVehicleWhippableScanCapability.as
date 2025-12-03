class USkylineHighwayVehicleWhippableScanCapability : UHazeCapability
{
	USkylineHighwayVehicleWhippableScanComponent ScanComp;
	AHazePlayerCharacter PlayerTarget;
	FHazeAcceleratedVector AccDirection;
	float OffsetTimer;
	float ScanSpeed = 1.5;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		ScanComp = USkylineHighwayVehicleWhippableScanComponent::GetOrCreate(Owner);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if(ScanComp.bEnabled)
			return true;
		return false;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(!ScanComp.bEnabled)
			return true;
		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		PlayerTarget = Game::Mio;
		if(ScanComp.Select == EHazeSelectPlayer::Zoe)
			PlayerTarget = Game::Zoe;
		AccDirection.SnapTo(PlayerTarget.ActorLocation - Owner.ActorLocation);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		FVector TargetDir = (PlayerTarget.ActorCenterLocation - Owner.ActorLocation);
		AccDirection.AccelerateTo(TargetDir, 3, DeltaTime);

		OffsetTimer += DeltaTime * ScanSpeed;
		ScanComp.WorldRotation = AccDirection.Value.RotateAngleAxis(5 * Math::Sin(OffsetTimer), ScanComp.RightVector).Rotation();

		if(PlayerTarget.ActorLocation.Distance(Owner.ActorLocation) < 500)
			ScanComp.DisableScan();
	}
}