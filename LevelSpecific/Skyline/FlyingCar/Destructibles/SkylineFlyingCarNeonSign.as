UCLASS(Abstract)
class USkylineFlyingCarNeonSignEventHandler : UHazeEffectEventHandler
{

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnBulletHit() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnBroken() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnDestroyed() {}
}
class ASkylineFlyingCarNeonSign : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent)
	USkylineFlyingCarDestructibleComponent DestructionComp;

	UPROPERTY(DefaultComponent)
	UStaticMeshComponent SignMesh;

	UPROPERTY(DefaultComponent)
	UStaticMeshComponent BrokenMesh;
	default BrokenMesh.SetHiddenInGame(true);
	default BrokenMesh.SetCollisionEnabled(ECollisionEnabled::NoCollision);

	UPROPERTY(DefaultComponent)
	USceneComponent ExplosionLoc;

	UPROPERTY(DefaultComponent)
	USceneComponent DamageLoc;

	UPROPERTY(DefaultComponent)
	UBasicAIHealthComponent HealthComp;

	UPROPERTY(DefaultComponent)
	USkylineFlyingCarImpactResponseComponent ImpactResponseComp;

	UPROPERTY(EditAnywhere)
	UNiagaraSystem ExplosionVFX;

	UPROPERTY(EditAnywhere)
	UNiagaraSystem TakeDamageVFX;

	UPROPERTY(EditDefaultsOnly)
	UForceFeedbackEffect ForceFeedback;

	ASkylineFlyingCar Car;

	FHazeTimeLike SignDestruction;
	default SignDestruction.Duration = 3.5;
	default SignDestruction.UseLinearCurveZeroToOne();

	bool bDoOnce = true;
	bool bChangeMaterial = true;

	UPROPERTY(DefaultComponent)
	UDisableComponent DisableComp;
	default DisableComp.bAutoDisable = true;
	default DisableComp.AutoDisableRange = 60000.0;

	UMaterialInstanceDynamic SignCrumbleMID;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		HealthComp.OnTakeDamage.AddUFunction(this, n"HandleTakeDamage");
		ImpactResponseComp.OnImpactedByFlyingCar.AddUFunction(this, n"OnImpactedByFlyingCar");
		ImpactResponseComp.OnImpactedByCarEnemy.AddUFunction(this, n"OnImpactedByCarEnemy");
		SignDestruction.BindUpdate(this, n"DestroyingSign");

		SignCrumbleMID = Material::CreateDynamicMaterialInstance(this, BrokenMesh.GetMaterial(0));
		BrokenMesh.SetMaterial(0, SignCrumbleMID);
	}

	UFUNCTION()
	private void HandleTakeDamage(AHazeActor ActorTakingDamage, AHazeActor Attacker, float Damage,
	                              EDamageType DamageType)
	{
		USkylineFlyingCarNeonSignEventHandler::Trigger_OnBulletHit(this);

		if(bChangeMaterial)
		{
			bChangeMaterial = false;
			USkylineFlyingCarNeonSignEventHandler::Trigger_OnBroken(this);
			ChangeMaterial();
		}

		if(HealthComp.GetCurrentHealth() <= 0.0 && bDoOnce)
		{
			bDoOnce = false;
			USkylineFlyingCarNeonSignEventHandler::Trigger_OnDestroyed(this);
			Niagara::SpawnOneShotNiagaraSystemAttached(ExplosionVFX, ExplosionLoc);
			SignDestruction.PlayFromStart();
			SignMesh.SetHiddenInGame(true);
			BrokenMesh.SetHiddenInGame(false);
			BP_DestroyedFromBullets();
		}
			
	}

	UFUNCTION(BlueprintEvent)
	void BP_DestroyedFromBullets()
	{
	}

	UFUNCTION()
	private void OnImpactedByFlyingCar(ASkylineFlyingCar FlyingCar, FFlyingCarOnImpactData ImpactData)
	{
		SignMesh.SetHiddenInGame(true);
		BrokenMesh.SetHiddenInGame(false);
		SignDestruction.PlayFromStart();
		SignExplode(ImpactData.ImpactPoint);
		ForceFeedback::PlayWorldForceFeedback(FlyingCar.ImpactForceFeedback, ActorLocation, false, this, 500, 800, 1.0, 1.0, EHazeSelectPlayer::Both);
		FlyingCar.Gunner.PlayCameraShake(FlyingCar.LightCollisionCameraShake, this);
		FlyingCar.Pilot.PlayCameraShake(FlyingCar.LightCollisionCameraShake, this);
	}

	UFUNCTION()
	private void OnImpactedByCarEnemy(ASkylineFlyingCarEnemy CarEnemy, FFlyingCarOnImpactData ImpactData)
	{
		SignMesh.SetHiddenInGame(true);
		BrokenMesh.SetHiddenInGame(false);
		SignDestruction.PlayFromStart();
		SignExplode(ImpactData.ImpactPoint);
		ForceFeedback::PlayWorldForceFeedback(ForceFeedback, ActorLocation, false, this, 500, 800, 1.0, 0.5, EHazeSelectPlayer::Both);
	}

	UFUNCTION()
	private void DestroyingSign(float CurrentValue)
	{
		SignCrumbleMID.SetScalarParameterValue(n"VAT_DisplayTime", Math::Lerp(0,1,CurrentValue));
	}

	UFUNCTION(BlueprintEvent)
	void ChangeMaterial()
	{
	}

	UFUNCTION(BlueprintEvent, BlueprintCallable)
	void SignExplode(FVector ImpactPoint)
	{
	}
};