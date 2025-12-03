class UChainedSculptureReturnCapability : UHazeCapability 
{
	default CapabilityTags.Add(n"ChainedSculptureReturnCapability");
	
	default TickGroup = EHazeTickGroup::Gameplay;
	default TickGroupOrder = 100;

	AChainedSculptureDropWeight Sculpture;

	FHazeAcceleratedVector AccelVector;
	FHazeAcceleratedRotator AccelRotator;
	FVector StartingOffsetLocation;
	FRotator StartingRotation;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Sculpture = Cast<AChainedSculptureDropWeight>(Owner);
		StartingOffsetLocation = Sculpture.ActorLocation - Sculpture.Metal.ActorLocation;
		StartingRotation = Sculpture.ActorRotation;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (!Sculpture.bReturning)
			return false;
		
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (!Sculpture.bReturning)
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		AccelVector.SnapTo(Sculpture.ActorLocation);
		AccelRotator.SnapTo(Sculpture.ActorRotation);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Sculpture.AttachToComponent(Sculpture.Metal.RootComponent, NAME_None, EAttachmentRule::KeepWorld, EAttachmentRule::KeepWorld, EAttachmentRule::KeepWorld, false);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		AccelVector.AccelerateTo(Sculpture.Metal.ActorLocation + StartingOffsetLocation, 3.0, DeltaTime);
		AccelRotator.AccelerateTo(StartingRotation, 3.0, DeltaTime);

		FVector TargetLoc = Sculpture.Metal.ActorLocation + StartingOffsetLocation;
		Sculpture.ActorLocation = Math::VInterpConstantTo(Sculpture.ActorLocation, TargetLoc, DeltaTime, 1500.0);
		Sculpture.ActorRotation = Math::RInterpConstantTo(Sculpture.ActorRotation, StartingRotation, DeltaTime, 70.0);

		if (Sculpture.ActorLocation == TargetLoc)
			Sculpture.bReturning = false;
	}	
}