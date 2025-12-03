class UTundraPlayerSwingSnapPositionCapability : UHazePlayerCapability
{
	default CapabilityTags.Add(CapabilityTags::Movement);
	default NetworkMode = EHazeCapabilityNetworkMode::Local;
	default TickGroup = EHazeTickGroup::LastMovement;

	UTundraPlayerSwingComponent SwingComp;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		SwingComp = UTundraPlayerSwingComponent::GetOrCreate(Player);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if(!SwingComp.bIsActive)
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(!SwingComp.bIsActive)
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
		FVector FixedLocation = SwingComp.HorizontalLocation;
		FixedLocation.Z = Player.ActorLocation.Z;

		float InteractionZ = SwingComp.Swing.PlayerData[Player].InteractionComponent.WorldLocation.Z;
		if(FixedLocation.Z < InteractionZ)
			FixedLocation.Z = InteractionZ + 100;

		Player.SetActorLocation(FixedLocation);
		FQuat Rotation = FQuat::MakeFromZX(FVector::UpVector, SwingComp.Swing.PlayerData[Player].InteractionComponent.WorldRotation.ForwardVector);
		Player.SetActorRotation(Rotation);
	}
};