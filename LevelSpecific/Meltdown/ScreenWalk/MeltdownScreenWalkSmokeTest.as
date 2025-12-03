class AMeltdownScreenWalkSmokeTest : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent)
	UNiagaraComponent Smoke;

	UPROPERTY(DefaultComponent)
	UMeltdownScreenWalkResponseComponent ResponseComp;
	default ResponseComp.bTriggerStompContinuously = true;

	UPROPERTY()
	float StartUpDelay;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
	}
};