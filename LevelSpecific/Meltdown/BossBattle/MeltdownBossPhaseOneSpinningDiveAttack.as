class AMeltdownBossPhaseOneSpinningDiveAttack : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	UStaticMeshComponent Cube;

	UPROPERTY(DefaultComponent)
	UMeltdownBossCubeGridDisplacementComponent Displacement;

	UPROPERTY(DefaultComponent)
	URotatingMovementComponent Rotator;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
	}
};