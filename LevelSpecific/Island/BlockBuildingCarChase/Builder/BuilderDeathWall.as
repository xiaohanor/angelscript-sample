
UCLASS(Abstract)
class ABuilderDeathWall : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent RootComp;
	UPROPERTY(DefaultComponent, Attach = RootComp)
	UStaticMeshComponent Mesh;
	UPROPERTY(EditAnywhere)
	float SpeedMultiplier = 1;
	
	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		
	}
	
	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		AddActorWorldOffset(FVector(0,-15 * SpeedMultiplier,0));
	}
}

