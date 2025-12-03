UCLASS(Abstract)
class UDentistToothWaterDeathComponent : UActorComponent
{
	UPROPERTY(EditDefaultsOnly)
	TSubclassOf<UDeathEffect> DeathEffect;

	UPROPERTY(BlueprintReadOnly)
	FVector DeathLocation;

	UPROPERTY(BlueprintReadOnly)
	FVector DeathNormal;

	ALandscape ChocolateWaterLandscape;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		ChocolateWaterLandscape = Dentist::GetChocolateWaterLandscape();
	}

	float GetChocolateWaterHeight(FVector SampleLocation) const
	{
		if (ChocolateWaterLandscape == nullptr)
			return SampleLocation.Z - 1000;
		float32 ChocolateWaterHeight = 0;
		if(!ChocolateWaterLandscape.GetHeightAtLocation(SampleLocation, ChocolateWaterHeight))
			return SampleLocation.Z - 1000;

		return ChocolateWaterHeight;
	}

	FVector GetChocolateWaterSurfaceLocation(FVector SampleLocation) const
	{
		FVector Location = SampleLocation;
		float32 ChocolateWaterHeight = 0;
		if(!ChocolateWaterLandscape.GetHeightAtLocation(SampleLocation, ChocolateWaterHeight))
			return Location;

		Location.Z = ChocolateWaterHeight;
		return Location;
	}

	FVector GetChocolateWaterSurfaceNormal(FVector SampleLocation) const
	{
		const FVector Offset = FVector::ForwardVector * 50;
		const FVector SampleOne = GetChocolateWaterSurfaceLocation(SampleLocation + Offset);
		const FVector SampleTwo = GetChocolateWaterSurfaceLocation(SampleLocation + FQuat(FVector::UpVector, Math::DegreesToRadians(120)) * Offset);
		const FVector SampleThree = GetChocolateWaterSurfaceLocation(SampleLocation + FQuat(FVector::UpVector, Math::DegreesToRadians(240)) * Offset);
		return FPlane(SampleOne, SampleTwo, SampleThree).Normal;
	}
};