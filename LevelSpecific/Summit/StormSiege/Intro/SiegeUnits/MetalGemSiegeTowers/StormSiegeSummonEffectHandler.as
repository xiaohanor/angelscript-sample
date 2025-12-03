struct FStormSiegeSummonEnemyParams
{
	UPROPERTY()
	FVector Location;
}

UCLASS(Abstract)
class UStormSiegeSummonEffectHandler : UHazeEffectEventHandler
{
	UFUNCTION(BlueprintOverride)
	void Setup()
	{
	}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void SummonEnemy(FStormSiegeSummonEnemyParams Params)
	{
	}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void DeSummonEnemy(FStormSiegeSummonEnemyParams Params)
	{
	}
};