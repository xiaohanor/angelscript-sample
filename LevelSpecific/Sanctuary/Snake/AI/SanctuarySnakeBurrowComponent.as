class USanctuarySnakeBurrowComponent : UActorComponent
{
	UPROPERTY()
	TArray<TSubclassOf<ASanctuarySnakeBurrowTarget>> BurrowTargetClasses;

	TArray<ASanctuarySnakeBurrowTarget> BurrowTargets;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		for (auto BurrowTargetClass : BurrowTargetClasses)
			BurrowTargets.Add(SpawnActor(BurrowTargetClass));
	}
}