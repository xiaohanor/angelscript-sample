class UBasicAIFlightComponent : UActorComponent
{
	UPROPERTY(EditAnywhere)
	float SpawnHeightOffset = 0.0;

	float SpawnHeight = 0.0;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Reset();
	}

	UFUNCTION(NotBlueprintCallable)
	void Reset()
	{
		SpawnHeight = Owner.ActorLocation.Z + SpawnHeightOffset;
	}
}