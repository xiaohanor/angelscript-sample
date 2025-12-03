class USiegeMagicBeamComponent : USceneComponent
{
	UPROPERTY()
	float WaitTime = 2.0;

	UPROPERTY()
	float BeamRange = 20000.0;

	UPROPERTY()
	float MinRangeRequired = 2000.0;

	UPROPERTY()
	float BeamWidth = 250.0;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
	}
};