class ASolarFlareAutoRotatingObject : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent MeshRoot;

	UPROPERTY(DefaultComponent, Attach = MeshRoot)
	USolarFlareCoverOverlapComponent CoverOverlapComp;

	UPROPERTY(DefaultComponent)
	USolarFlareEffectComponent EffectComp;

	UPROPERTY(EditAnywhere)
	FRotator RotationPerSecond;

	UPROPERTY(EditAnywhere)
	bool bStartActive = true;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		if (!bStartActive)
			SetActorTickEnabled(false);
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		MeshRoot.AddLocalRotation(RotationPerSecond * DeltaSeconds);
	}

	UFUNCTION()
	void ActivateAutoRotation()
	{
		SetActorTickEnabled(true);
	}
}