struct FSummitAIArmorEnemyParams
{
	UPROPERTY()
	FVector Location;

	UPROPERTY()
	FRotator Rotation;
}

UCLASS(Abstract)
class UAISummitArmorEnemyEffectsHandler : UHazeEffectEventHandler
{

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void ShardDestroyed(FSummitAIArmorEnemyParams Params) 
	{
	}
} 