UCLASS(Abstract)
class ALiftSectionStomperFloor : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent RootComp;
	UFUNCTION(BlueprintOverride)
	void ConstructionScript(){}
	default SetActorHiddenInGame(true);


	UFUNCTION(BlueprintOverride)
	void BeginPlay(){}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime){}

	UFUNCTION()
	void ActivateStomperFloor()
	{
		SetActorHiddenInGame(false);
	}
	UFUNCTION()
	void DeactivateStomperFloor()
	{
		SetActorHiddenInGame(true);
	}

}