class ASplitTraversalCableFlower : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	UStaticMeshComponent FlowerMeshComp;

	UPROPERTY()
	UNiagaraSystem VFXSystem;

	FHazeTimeLike FlowerScaleTimeLike;
	default FlowerScaleTimeLike.UseSmoothCurveZeroToOne();
	default FlowerScaleTimeLike.Duration = 0.3;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		FlowerScaleTimeLike.BindUpdate(this, n"FlowerScaleTimeLikeUpdate");
		FlowerScaleTimeLike.Play();
		Niagara::SpawnOneShotNiagaraSystemAttached(VFXSystem, Root);
	}

	UFUNCTION()
	private void FlowerScaleTimeLikeUpdate(float CurrentValue)
	{
		FlowerMeshComp.SetWorldScale3D(FVector(CurrentValue));
	}
};