UCLASS(Abstract)
class ALiftSectionSpinningFlamethrower : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent RootComp;
	UPROPERTY(DefaultComponent, Attach = RootComp)
	USceneComponent RotationComp;
	UPROPERTY(DefaultComponent, Attach = RotationComp)
	UStaticMeshComponent StaticMesh;
	UPROPERTY(DefaultComponent, Attach = RotationComp)
	UNiagaraComponent VFX;

	default SetActorHiddenInGame(true);

	bool bIsActive = false;
	
	UPROPERTY(EditAnywhere)
	float SpeedMultiplier = 5;


	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
	
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		if(bIsActive == false)
			return;

		FRotator CurrentRotationOffset = FRotator(0, 10 * DeltaTime * SpeedMultiplier, 0);
		RotationComp.AddLocalRotation(CurrentRotationOffset);
	}

	UFUNCTION()
	void StartFlamethrower()
	{
		SetActorHiddenInGame(false);
		bIsActive = true;
		VFX.Activate();
	}
	UFUNCTION()
	void StopFlamethrower()
	{
		SetActorHiddenInGame(true);
		bIsActive = false;
		VFX.Deactivate();
	}
}