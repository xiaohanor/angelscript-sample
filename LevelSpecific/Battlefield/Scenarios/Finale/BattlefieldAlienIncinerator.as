class ABattlefieldAlienIncinerator : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent MeshRoot;

	UPROPERTY(DefaultComponent, Attach = MeshRoot)
	UStaticMeshComponent MeshComp;

	// UPROPERTY()
	// FVector OffsetToTarget;
	// UPROPERTY()
	// FVector StartLocation;
	// UPROPERTY(EditAnywhere)
	// AActor TargetLocation;

	// UFUNCTION(BlueprintOverride)
	// void BeginPlay()
	// {
	// 	StartLocation = ActorLocation;
	// 	OffsetToTarget = TargetLocation.ActorLocation - ActorLocation;
	// 	SetActorTickEnabled(false);
	// }

	// UFUNCTION(BlueprintEvent)
	// void BP_ActivateIncinerator() {}
	
}