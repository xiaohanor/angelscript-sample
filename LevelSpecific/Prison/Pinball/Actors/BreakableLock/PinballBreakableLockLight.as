UCLASS(Abstract)
class APinballBreakableLockLight : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent)
	UStaticMeshComponent MeshComp;

	UPROPERTY(DefaultComponent)
	UNiagaraComponent TractorBeamVFXComp;

	UPROPERTY(EditInstanceOnly)
	APinballBreakableLock LockActor; 

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		TractorBeamVFXComp.SetVectorParameter(n"BeamStart", ActorLocation);
		TractorBeamVFXComp.SetVectorParameter(n"BeamEnd", LockActor.ActorLocation);

		LockActor.OnLockBroken.AddUFunction(this, n"OnLockBroken");
	}

	UFUNCTION()
	private void OnLockBroken(APinballBreakableLock Lock)
	{
		BP_OnLockBroken();
	}

	UFUNCTION(BlueprintEvent)
	void BP_OnLockBroken() {}
};