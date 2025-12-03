class ATundra_River_VinesThatHoldTheStoneWall : AHazeActor
{
	UPROPERTY(DefaultComponent)
	UHazeCrumbSyncedVectorComponent SyncedScale;

	UFUNCTION(BlueprintPure)
	FVector GetClampedSyncedScale()
	{
		return SyncedScale.Value.ComponentClamp(FVector(0.01), FVector(1.0));
	}
}