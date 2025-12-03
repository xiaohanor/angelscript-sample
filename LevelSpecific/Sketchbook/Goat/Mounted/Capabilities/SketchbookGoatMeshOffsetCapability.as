class USketchbookGoatMeshOffsetCapability : UHazeCapability
{
	default NetworkMode = EHazeCapabilityNetworkMode::Local;

	default CapabilityTags.Add(Sketchbook::Goat::Tags::SketchbookGoat);

	default TickGroup = EHazeTickGroup::Gameplay;

	ASketchbookGoat Goat;
	USketchbookGoatSplineMovementComponent SplineComp;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Goat = Cast<ASketchbookGoat>(Owner);
		SplineComp = USketchbookGoatSplineMovementComponent::Get(Goat);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if(Goat.CopyStencilDepthFrom != EHazePlayer::Mio)
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Goat.RootOffsetComp.ClearOffset(this);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		Goat.Mesh.SetWorldLocation(Goat.ActorLocation + FVector::ForwardVector * -60);
	}
};