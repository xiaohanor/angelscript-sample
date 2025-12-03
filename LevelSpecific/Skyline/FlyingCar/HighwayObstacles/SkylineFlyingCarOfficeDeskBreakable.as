UCLASS(Abstract)
class USkylineFlyingCarOfficeDeskBreakableEventHandler : UHazeEffectEventHandler
{
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnDestroyed() {}
}

class ASkylineFlyingCarOfficeDeskBreakable : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent)
	UBoxComponent Collision;
	default Collision.CollisionProfileName = n"BlockAllDynamic";
	default Collision.bGenerateOverlapEvents = false;

	UPROPERTY(DefaultComponent)
	UStaticMeshComponent DeskMesh;
	default DeskMesh.CollisionEnabled = ECollisionEnabled::NoCollision;

	UPROPERTY(DefaultComponent)
	UStaticMeshComponent Computer1;
	default DeskMesh.CollisionEnabled = ECollisionEnabled::NoCollision;

	UPROPERTY(DefaultComponent)
	UStaticMeshComponent Computer2;
	default DeskMesh.CollisionEnabled = ECollisionEnabled::NoCollision;

	UPROPERTY(DefaultComponent)
	UStaticMeshComponent BrokenMesh;
	default BrokenMesh.SetHiddenInGame(true);
	default BrokenMesh.SetCollisionEnabled(ECollisionEnabled::NoCollision);

	UPROPERTY(DefaultComponent)
	UDisableComponent DisableComp;
	default DisableComp.bAutoDisable = true;
	default DisableComp.AutoDisableRange = 15000;

	UPROPERTY(DefaultComponent)
	USkylineFlyingCarImpactResponseComponent ImpactResponseComp;
	default ImpactResponseComp.VelocityLostOnImpact = 0;

	UPROPERTY(EditDefaultsOnly)
	UNiagaraSystem DeskDestroyVFX;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		
		ImpactResponseComp.OnImpactedByFlyingCar.AddUFunction(this, n"OnImpactedByFlyingCar");
	}

	UFUNCTION()
	private void OnImpactedByFlyingCar(ASkylineFlyingCar FlyingCar, FFlyingCarOnImpactData ImpactData)
	{
		BP_OnImpactedByFlyingCar();
		
		USkylineFlyingCarOfficeDeskBreakableEventHandler::Trigger_OnDestroyed(this);

		Niagara::SpawnOneShotNiagaraSystemAttached(DeskDestroyVFX, DeskMesh);

		DeskMesh.AddComponentVisualsBlocker(this);
		Computer1.AddComponentVisualsBlocker(this);
		Computer2.AddComponentVisualsBlocker(this);

		AddActorCollisionBlock(this);
	}

	UFUNCTION(BlueprintEvent)
	void BP_OnImpactedByFlyingCar() {}
};