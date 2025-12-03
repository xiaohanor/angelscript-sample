struct FAdultDragonHomingTailSmashTriggeredParams
{
	UPROPERTY()
	UHazeCharacterSkeletalMeshComponent DragonMesh;
}

UCLASS(Abstract)
class UAdultDragonHomingTailSmashEffectHandler : UHazeEffectEventHandler
{
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void TailSmashTriggered(FAdultDragonHomingTailSmashTriggeredParams Params){}
};