event void FSkylineWhippableEngineWeakpointExplodedSignature();

UCLASS(Abstract)
class ASkylineWhippableEngineWeakpoint : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent)
	UStaticMeshComponent Mesh;

	UPROPERTY(DefaultComponent)
	UGravityBladeCombatResponseComponent BladeResponse;

	UPROPERTY(DefaultComponent, Attach = "Mesh")
	UGravityBladeCombatTargetComponent BladeTarget;

	UPROPERTY(DefaultComponent, Attach = "BladeTarget")
	UTargetableOutlineComponent BladeOutline;

	UPROPERTY(EditAnywhere)
	UNiagaraSystem ExplodeFX;

	UPROPERTY()
	FSkylineWhippableEngineWeakpointExplodedSignature OnExploded;

	UPROPERTY()
	bool bExploded;

	bool bExposed;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		BladeResponse.OnHit.AddUFunction(this, n"OnHit");
	}

	UFUNCTION()
	private void OnHit(UGravityBladeCombatUserComponent CombatComp, FGravityBladeHitData HitData)
	{
		if(!bExposed)
			return;
		Niagara::SpawnOneShotNiagaraSystemAtLocation(ExplodeFX, ActorLocation);
		bExploded = true;
		AddActorDisable(this);
		OnExploded.Broadcast();
	}

	void Expose()
	{
		BladeTarget.Enable(this);
		bExposed = true;
	}

	void Unexpose()
	{
		BladeTarget.Disable(this);
		bExposed = false;
	}
}