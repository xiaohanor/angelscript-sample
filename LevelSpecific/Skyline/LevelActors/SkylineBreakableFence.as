event void FSkylineBreakableFenceSignature();
class ASkylineBreakableFence : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent)
	UStaticMeshComponent Fence;

	UPROPERTY(DefaultComponent)
	UGravityBladeCombatResponseComponent BladeCombatRespComp;

	UPROPERTY(DefaultComponent)
	UGravityBladeCombatTargetComponent BladeTargetComp;

	UPROPERTY(DefaultComponent, Attach = BladeTargetComp)
	UTargetableOutlineComponent TargetOutlineComp;

	UPROPERTY(EditAnywhere)
	UNiagaraSystem ExplosionVFX;

	FVector ExplosionScale = FVector(0.1, 0.1, 0.1);
	
	UPROPERTY()
	FSkylineBreakableFenceSignature OnSliced;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		BladeCombatRespComp.OnHit.AddUFunction(this, n"HandleHit");
	}

	UFUNCTION()
	private void HandleHit(UGravityBladeCombatUserComponent CombatComp, FGravityBladeHitData HitData)
	{
			Niagara::SpawnOneShotNiagaraSystemAtLocation(ExplosionVFX, ActorLocation, ActorRotation);
			OnSliced.Broadcast();
			DestroyActor();
	}
};