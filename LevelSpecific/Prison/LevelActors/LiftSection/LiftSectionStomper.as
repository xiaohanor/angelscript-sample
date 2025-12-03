UCLASS(Abstract)
class ALiftSectionStomper : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent RootComp;
	UPROPERTY(DefaultComponent)
	UNiagaraComponent VFX;
	UPROPERTY(DefaultComponent)
	USceneComponent MoveRoot;
	UPROPERTY(DefaultComponent, Attach = MoveRoot)
	UStaticMeshComponent StaticMesh;

	FHazeAcceleratedFloat AcceleratedFloat;


	UFUNCTION(BlueprintOverride)
	void ConstructionScript(){}

	UPROPERTY(EditAnywhere)
	bool bIsActive = false;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		MoveRoot.SetRelativeLocation(FVector(0,0, 0));
		AcceleratedFloat.Value = 0;
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		MoveRoot.SetRelativeLocation(FVector(0,0, AcceleratedFloat.Value));

		if(bIsActive == true)
		{
			AcceleratedFloat.SpringTo(-3000, 50, 1, DeltaTime);
		}
		else
		{
			AcceleratedFloat.SpringTo(0, 20, 1, DeltaTime);
		}
	}

	UFUNCTION()
	void ActivateStomper()
	{
		bIsActive = true;
	}
	UFUNCTION()
	 void DeactivateStomper()
	{
		bIsActive = false;
	}
}