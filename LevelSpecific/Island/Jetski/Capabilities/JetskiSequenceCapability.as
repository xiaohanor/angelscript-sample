class UJetskiSequenceCapability : UHazeCapability
{
	default TickGroup = EHazeTickGroup::BeforeMovement;

	AJetski Jetski;
	FHazeAcceleratedFloat AccVerticalLocation;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Jetski = Cast<AJetski>(Owner);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if(!Jetski.bIsControlledByCutscene)
			return false;

		auto SequenceSettingsActor = AJetskiSequenceSettingsActor::Get();
		if(SequenceSettingsActor == nullptr)
			return false;

		if(Jetski.Driver.IsMio())
		{
			if(!SequenceSettingsActor.bPlaceMioJetskiOnWater)
				return false;
		}
		else
		{
			if(!SequenceSettingsActor.bPlaceZoeJetskiOnWater)
				return false;
		}

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(!Jetski.bIsControlledByCutscene)
			return true;

		auto SequenceSettingsActor = AJetskiSequenceSettingsActor::Get();
		if(SequenceSettingsActor == nullptr)
			return true;

		if(Jetski.Driver.IsMio())
		{
			if(!SequenceSettingsActor.bPlaceMioJetskiOnWater)
				return false;
		}
		else
		{
			if(!SequenceSettingsActor.bPlaceZoeJetskiOnWater)
				return false;
		}

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		AccVerticalLocation.SnapTo(Jetski.ActorLocation.Z, Jetski.ActorVelocity.Z);
		//OffsetFromWaveLocation =  Jetski.GetWaveLocation() - Jetski.ActorLocation;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Jetski.SetActorLocation(Jetski.RootOffsetComponent.WorldLocation);
		Jetski.RootOffsetComponent.ClearOffset(this);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		float TargetHeight = Jetski.GetWaveHeight();
		TargetHeight -= Jetski.GetSphereRadius() * 0.7;

		AccVerticalLocation.SpringTo(TargetHeight, 100, 0.2, DeltaTime);
		const FVector Location = FVector(Jetski.ActorLocation.X, Jetski.ActorLocation.Y, AccVerticalLocation.Value);
		Jetski.RootOffsetComponent.SnapToLocation(this, Location);
	}
};