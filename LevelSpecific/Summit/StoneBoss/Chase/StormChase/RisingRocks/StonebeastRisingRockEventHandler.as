struct FStonebeastRisingRockParams
{
	UPROPERTY()
	FVector Location;

	FStonebeastRisingRockParams(FVector NewLocation)
	{
		Location = NewLocation;
	}
}

UCLASS(Abstract)
class UStonebeastRisingRockEventHandler : UHazeEffectEventHandler
{
	//UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	//void RisingRockInitiate(FStonebeastRisingRockParams Params) {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void RisingRockInitiate() {}
};