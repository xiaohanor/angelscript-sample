class USkylineTorHammerOffsetCapability : UHazeCapability
{
	USkylineTorHammerComponent HammerComp;
	FHazeAcceleratedVector AccOffset;
	FVector OriginalOffset;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		HammerComp = USkylineTorHammerComponent::GetOrCreate(Owner);
		OriginalOffset = HammerComp.HoldHammerComp.Hammer.InvertedFauxRotateComp.RelativeLocation;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		return false;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		FVector Offset = HammerComp.bGroundOffset.Get() ? OriginalOffset + FVector::UpVector * 75 : OriginalOffset;
		AccOffset.AccelerateTo(Offset, 1, DeltaTime);
		HammerComp.HoldHammerComp.Hammer.InvertedFauxRotateComp.RelativeLocation = AccOffset.Value;
	}
}