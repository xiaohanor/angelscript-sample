UCLASS(Abstract)
class USkylineGardenStatueEventHandler : UHazeEffectEventHandler
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
	void OnStatueFinished()
	{
	}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnStatueDestroyed()
	{
	}


};
class ASkylineGardenStatue : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent)
	UNiagaraComponent LeafVFX;

	UPROPERTY(DefaultComponent)
	USceneComponent VfxLoc;

	UPROPERTY(DefaultComponent)
	UStaticMeshComponent DefaultBushMesh;

	UPROPERTY(DefaultComponent)
	UStaticMeshComponent Stage2Mesh;

	UPROPERTY(DefaultComponent)
	UStaticMeshComponent Stage3Mesh;

	UPROPERTY(DefaultComponent)
	UStaticMeshComponent StageBranchMesh;

	UPROPERTY(DefaultComponent)
	UGravityBladeCombatResponseComponent ResponseComp;

	int HitTimes = 0;

	bool bPlantDead = false;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		ResponseComp.OnHit.AddUFunction(this, n"HandleOnHit");
		LeafVFX.OnSystemFinished.AddUFunction(this, n"HandleVFXFinished");
		
	}



	UFUNCTION()
	private void HandleVFXFinished(UNiagaraComponent PSystem)
	{
		LeafVFX.Deactivate();
	}

	UFUNCTION()
	private void HandleOnHit(UGravityBladeCombatUserComponent CombatComp, FGravityBladeHitData HitData)
	{
		if(bPlantDead)
			return;

		if(LeafVFX.IsActive())
			LeafVFX.ResetSystem();

		LeafVFX.Activate();
		USkylineGardenStatueEventHandler::Trigger_OnSliced(this);
		HitTimes++;

		if(HitTimes==3)
		{
			CutLeafs();
		}

		if(HitTimes==6)
		{
			Stage2Mesh.SetHiddenInGame(true);
			Stage2Mesh.AddComponentCollisionBlocker(this);
			StageBranchMesh.SetHiddenInGame(false);
			bPlantDead = true;
			USkylineGardenStatueEventHandler::Trigger_OnStatueDestroyed(this);
			ResponseComp.RemoveResponseComponentDisable(this, true);
		}
	}

	void CutLeafs()
	{
		USkylineGardenStatueEventHandler::Trigger_OnStatueFinished(this);
		DefaultBushMesh.SetHiddenInGame(true);
		DefaultBushMesh.AddComponentCollisionBlocker(this);
		Stage2Mesh.SetHiddenInGame(false);
	}
};