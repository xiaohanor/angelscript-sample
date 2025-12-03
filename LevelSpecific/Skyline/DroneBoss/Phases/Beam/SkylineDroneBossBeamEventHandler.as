struct FSkylineDroneBossBeamRingSpawnedData
{
	UPROPERTY(BlueprintReadOnly)
	ASkylineDroneBossBeamRing Ring;
}

UCLASS(Abstract)
class USkylineDroneBossBeamEventHandler : UHazeEffectEventHandler
{
	UPROPERTY(NotVisible, BlueprintReadOnly)
	ASkylineDroneBoss Boss = nullptr;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Boss = Cast<ASkylineDroneBoss>(Owner);
	}
	
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void RingSpawned(FSkylineDroneBossBeamRingSpawnedData Data) {}
}