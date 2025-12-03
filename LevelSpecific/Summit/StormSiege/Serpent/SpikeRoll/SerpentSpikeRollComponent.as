class USerpentSpikeRollComponent : UActorComponent
{
	UPROPERTY()
	float SpinDuration = 2.0;
	
	UPROPERTY(EditDefaultsOnly)
	FHazePlaySlotAnimationParams RollSequenceParams;
};