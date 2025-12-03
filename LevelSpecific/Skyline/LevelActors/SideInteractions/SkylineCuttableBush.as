UCLASS(Abstract)
class UAkylineCuttableBushEventHandler : UHazeEffectEventHandler
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

};

class ASkylineCuttableBush : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent)
	UNiagaraComponent LeafVFX;

	UPROPERTY(DefaultComponent)
	UStaticMeshComponent BushMesh;
	default BushMesh.CollisionProfileName = n"NoCollision";

	UPROPERTY(DefaultComponent)
	UGravityBladeCombatResponseComponent ResponseComp;

	UPROPERTY(DefaultComponent)
	USphereComponent BladeCollision;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		ResponseComp.OnHit.AddUFunction(this, n"HandleOnHit");
		LeafVFX.OnSystemFinished.AddUFunction(this, n"HandleVFXFinished");
	}

	UFUNCTION()
	private void HandleOnHit(UGravityBladeCombatUserComponent CombatComp, FGravityBladeHitData HitData)
	{
		TArray<UMeshComponent> AttachChildren;
			BushMesh.GetChildrenComponentsByClass(UMeshComponent, true, AttachChildren);
		for (UMeshComponent Child : AttachChildren)
		{
			Child.AddComponentVisualsBlocker(this);
		}

		USkylineGardenStatueEventHandler::Trigger_OnSliced(this);
		USkylineGardenStatueEventHandler::Trigger_OnStatueFinished(this);
		BushMesh.AddComponentVisualsBlocker(this);
		BladeCollision.AddComponentCollisionBlocker(this);
		LeafVFX.Activate();
	}

	UFUNCTION()
	private void HandleVFXFinished(UNiagaraComponent PSystem)
	{
		LeafVFX.Deactivate();
	}
};