struct FPlayerAdultDragonSwimmingData
{
	UPROPERTY()
	UHazeSkeletalMeshComponentBase SkelMesh;

	FPlayerAdultDragonSwimmingData(UHazeSkeletalMeshComponentBase NewSkel)
	{
		SkelMesh = NewSkel;
	}
}

UCLASS(Abstract)
class UPlayerAdultDragonSwimmingEventHandler : UHazeEffectEventHandler
{
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void EnterWater(FPlayerAdultDragonSwimmingData Params) {}
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void ExitWater(FPlayerAdultDragonSwimmingData Params) {}
};