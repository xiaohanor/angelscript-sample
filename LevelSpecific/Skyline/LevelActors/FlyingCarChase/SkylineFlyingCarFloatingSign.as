UCLASS(Abstract)
class ASkylineFlyingCarFloatingSign : AHazeActor
{
	default PrimaryActorTick.bStartWithTickEnabled = false;

	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent)
	USceneComponent MeshRoot;

	UPROPERTY(DefaultComponent,Attach = MeshRoot)
	UStaticMeshComponent MeshComp;

	UPROPERTY(DefaultComponent)
	USceneComponent ExplosionLoc;

	UPROPERTY(DefaultComponent)
	UBasicAIHealthComponent HealthComp;

	UPROPERTY(DefaultComponent)
	USkylineFlyingCarImpactResponseComponent ImpactResponseComp;

	UPROPERTY(EditAnywhere)
	UNiagaraSystem ExplosionVFX;

	UPROPERTY(EditAnywhere)
	UNiagaraSystem TakeDamageVFX;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		HealthComp.OnTakeDamage.AddUFunction(this, n"HandleTakeDamage");
		ImpactResponseComp.OnImpactedByFlyingCar.AddUFunction(this, n"OnImpactedByFlyingCar");
		ImpactResponseComp.OnImpactedByCarEnemy.AddUFunction(this, n"OnImpactedByCarEnemy");
	}

	UFUNCTION()
	private void HandleTakeDamage(AHazeActor ActorTakingDamage, AHazeActor Attacker, float Damage,
	                              EDamageType DamageType)
	{

		USkylineFlyingCarNeonSignEventHandler::Trigger_OnBulletHit(this);

		if(HealthComp.GetCurrentHealth() <= 0.0)
		{
			USkylineFlyingCarNeonSignEventHandler::Trigger_OnDestroyed(this);
			Niagara::SpawnOneShotNiagaraSystemAttached(ExplosionVFX, ExplosionLoc);
			DestroyActor();
		}
	}

	UFUNCTION()
	private void OnImpactedByFlyingCar(ASkylineFlyingCar FlyingCar, FFlyingCarOnImpactData ImpactData)
	{
		FlyingCar.TakeDamage(FSkylineFlyingCarDamage());

		AddActorCollisionBlock(this);
		BP_Explode();
	}

	UFUNCTION()
	private void OnImpactedByCarEnemy(ASkylineFlyingCarEnemy CarEnemy, FFlyingCarOnImpactData ImpactData)
	{
		AddActorCollisionBlock(this);
		BP_Explode();
	}

	UFUNCTION(BlueprintEvent)
	void BP_Explode() {};
};