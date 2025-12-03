event void FOnSplineFighterDestroyableReachedEnd();

class ABattlefieldSplineFighterDestroyable : AHazeActor
{
	UPROPERTY()
	FOnSplineFighterDestroyableReachedEnd OnSplineFighterDestroyableReachedEnd;

	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent MeshRoot;

	UPROPERTY(DefaultComponent, Attach = Root)
	UBattlefieldProjectileComponent ProjComp;
	default ProjComp.bAutoBehaviour = false;

	UPROPERTY(DefaultComponent, Attach = Root)
	UNiagaraComponent FireTrail;
	default FireTrail.SetAutoActivate(false);

	UPROPERTY(DefaultComponent, Attach = Root)
	UNiagaraComponent EngineTrail;

	UPROPERTY(DefaultComponent, ShowOnActor)
	UBattlefieldSplineFollowComponent SplineFollowComp;
	default SplineFollowComp.bStartActive = false;

	UPROPERTY(DefaultComponent)
	UBattlefieldBreakableObjectComponent BreakableObjectComp;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		SplineFollowComp.OnBattlefieldReachedSplineEnd.AddUFunction(this, n"OnBattlefieldReachedSplineEnd");
	}

	UFUNCTION()
	private void OnBattlefieldReachedSplineEnd()
	{
		CrashFighterJet();
		OnSplineFighterDestroyableReachedEnd.Broadcast();
	}

	UFUNCTION()
	void CrashFighterJet()
	{
		FBattlefieldFighterCrashParams Params;
		Params.CrashLocation = ActorLocation;
		UBattlefieldFighterDestroyableEffectHandler::Trigger_OnFighterJetCrash(this, Params);
		BreakableObjectComp.BreakBattlefieldObject(FVector(0.0), 120000.0, false);
	}

	UFUNCTION()
	void HitFighterJet()
	{
		FBattlefieldFighterHitParams Params;
		Params.HitLocation = ActorLocation;
		UBattlefieldFighterDestroyableEffectHandler::Trigger_OnFighterHit(this, Params);
		BreakableObjectComp.BreakBattlefieldObject(FVector(0.0), 120000.0);	
		FireTrail.Activate();
	}
}