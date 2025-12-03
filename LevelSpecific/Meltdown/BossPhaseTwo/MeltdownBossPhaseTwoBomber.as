UCLASS(Abstract)
class AMeltdownBossPhaseTwoBomber : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent)
	UMeltdownBossObjectFadeComponent ObjectFade;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		
	}
};

struct FMeltdownBossPhaseTwoBomberFireParams
{
	UPROPERTY()
	FVector BombSpawnLocation;
}

UCLASS(Abstract)
class UMeltdownBossPhaseTwoBomberEffectHandler : UHazeEffectEventHandler
{
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void SpawnBomber() {}
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void DespawnBomber() {}


	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void FireBomb(FMeltdownBossPhaseTwoBomberFireParams FireParams) {}
}