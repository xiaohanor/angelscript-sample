UCLASS(Abstract)
class USkylineSabreBottleEventHandler : UHazeEffectEventHandler
{
	UFUNCTION(BlueprintOverride)
	void Setup()
	{
	}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnSliced()
	{
	}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnStartSpray()
	{
	}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnStopSpray()
	{
	}

};
class ASkylineSabreBottle : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent)
	UStaticMeshComponent BottleMesh;

	UPROPERTY(DefaultComponent)
	UGravityBladeCombatInteractionResponseComponent ResponseComp;

	UPROPERTY(DefaultComponent)
	UNiagaraComponent SprayVFX;

	UPROPERTY(DefaultComponent)
	UStaticMeshComponent CorkMesh;

	bool bDoOnce = true;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		ResponseComp.OnHit.AddUFunction(this, n"HandleOnHit");
	}

	UFUNCTION()
	private void HandleOnHit(UGravityBladeCombatUserComponent CombatComp, FGravityBladeHitData HitData)
	{
		if(bDoOnce)
		{
			USkylineSabreBottleEventHandler::Trigger_OnSliced(this);
			USkylineSabreBottleEventHandler::Trigger_OnStartSpray(this);
			CorkMesh.SetHiddenInGame(true);
			SprayVFX.Activate(true);
			Timer::SetTimer(this, n"StopSpraying", 3.0);
			bDoOnce = false;
		}
		
	}

	UFUNCTION()
	private void StopSpraying()
	{
		USkylineSabreBottleEventHandler::Trigger_OnStopSpray(this);
		SprayVFX.Deactivate();
	}
};