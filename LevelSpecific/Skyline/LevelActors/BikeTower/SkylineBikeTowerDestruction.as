class ASkylineBikeTowerDestruction : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent)
	UStaticMeshComponent Mesh;

	UPROPERTY(DefaultComponent)
	UStaticMeshComponent Broken;

	UPROPERTY(DefaultComponent)
	USceneComponent DestructionEffectLocation;

	UPROPERTY(DefaultComponent)
	USkylineInterfaceComponent InterfaceComp;

	UPROPERTY(EditAnywhere)
	UNiagaraSystem DestructionEffect;

	bool bBroken = false;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Broken.SetVisibility(bBroken);

		InterfaceComp.OnActivated.AddUFunction(this, n"HandleActivated");
	}

	UFUNCTION()
	private void HandleActivated(AActor Caller)
	{
		TriggerDestruction();
	}

	UFUNCTION()
	void TriggerDestruction()
	{
		if (bBroken)
			return;

		bBroken = true;

		Niagara::SpawnOneShotNiagaraSystemAtLocation(DestructionEffect, DestructionEffectLocation.WorldLocation, DestructionEffectLocation.WorldRotation, ActorScale3D);
		Mesh.SetVisibility(!bBroken);
		Broken.SetVisibility(bBroken);

		BP_TriggerDestruction();
	}

	UFUNCTION(BlueprintEvent)
	void BP_TriggerDestruction() {}
};