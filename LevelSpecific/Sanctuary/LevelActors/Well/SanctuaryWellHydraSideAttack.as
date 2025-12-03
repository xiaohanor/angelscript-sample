class ASanctuaryWellHydraSideAttack : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	UStaticMeshComponent HydraMesh;

	UPROPERTY(DefaultComponent, Attach = Root)
	UNiagaraComponent VFXComp;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		SetActorTickEnabled(false);
		HydraMesh.SetHiddenInGame(true);
	}

	UFUNCTION()
	void Attack()
	{
		HydraMesh.SetHiddenInGame(false);
		VFXComp.Activate();
		SetActorTickEnabled(true);
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		HydraMesh.AddRelativeLocation(FVector::ForwardVector * 4000.0 * DeltaSeconds);
	}
};