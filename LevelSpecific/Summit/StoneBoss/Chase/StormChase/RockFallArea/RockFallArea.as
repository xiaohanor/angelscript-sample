class ARockFallArea : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	UBoxComponent BoxComp;
	default BoxComp.SetCollisionEnabled(ECollisionEnabled::NoCollision);

	UPROPERTY()
	TSubclassOf<AFallingRock> RockClass;

	FVector Bounds;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		FVector Origin;
		GetActorBounds(false, Origin, Bounds);
		SetActorTickEnabled(false);
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		
	}

	UFUNCTION()
	void ActivateRockFall()
	{
		SetActorTickEnabled(true);
	}
}