event void FCellBlockGuardSpawnerDestroyedEvent();

UCLASS(Abstract)
class ACellBlockGuardSpawner : AHazeActorSpawnerBase
{
	UPROPERTY(DefaultComponent)
	UStaticMeshComponent SpawnerMeshComp;

	UPROPERTY(DefaultComponent)
	UHazeActorSpawnPatternInterval LeftSpawnerComp;

	UPROPERTY(DefaultComponent)
	UHazeActorSpawnPatternInterval RightSpawnerComp;

	UPROPERTY(DefaultComponent)
	UFauxPhysicsAxisRotateComponent LeftLidRoot;
	default LeftLidRoot.NetworkMode = EFauxPhysicsAxisRotateNetworkMode::SyncedFromZoeControl;

	UPROPERTY(DefaultComponent)
	UFauxPhysicsAxisRotateComponent RightLidRoot;
	default RightLidRoot.NetworkMode = EFauxPhysicsAxisRotateNetworkMode::SyncedFromZoeControl;

	UPROPERTY(DefaultComponent)
	UMagneticFieldResponseComponent MagneticFieldResponseComp;

	UPROPERTY(DefaultComponent)
	UDisableComponent DisableComp;
	default DisableComp.bAutoDisable = true;
	default DisableComp.AutoDisableRange = 20000;

	UPROPERTY(EditInstanceOnly)
	ADeathVolume PostExplosionDeathVolume;

	UPROPERTY()
	FCellBlockGuardSpawnerDestroyedEvent OnSpawnerDestroyed;

	bool bDestroyed = false;

	bool bBurstCooldownActive = false;
	bool bBurstSpamCounterForceActive = false;


	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Super::BeginPlay();
		
		MagneticFieldResponseComp.OnBurst.AddUFunction(this, n"BurstActivated");

		if (PostExplosionDeathVolume != nullptr)
			PostExplosionDeathVolume.DisableDeathVolume(this);
	}

	UFUNCTION()
	private void BurstActivated(FMagneticFieldData Data)
	{
		if (bBurstCooldownActive)
			bBurstSpamCounterForceActive = true;

		bBurstCooldownActive = true;

		Timer::SetTimer(this, n"ResetBurstCooldown", 2.0);
	}

	UFUNCTION()
	private void ResetBurstCooldown()
	{
		bBurstCooldownActive = false;
		bBurstSpamCounterForceActive = false;
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		if (bDestroyed)
		{
			LeftLidRoot.ApplyAngularForce(15.0);
			RightLidRoot.ApplyAngularForce(-15.0);
			return;
		}

		if (bBurstSpamCounterForceActive)
		{
			LeftLidRoot.ApplyAngularForce(-2.0);
			RightLidRoot.ApplyAngularForce(2.0);
		}

		if (!MagneticFieldResponseComp.WasMagneticallyAffectedThisFrame())
		{
			LeftLidRoot.ApplyAngularForce(-10.0);
			RightLidRoot.ApplyAngularForce(10.0);

			if (bBurstSpamCounterForceActive)
			{
				LeftLidRoot.ApplyAngularForce(-5.0);
				RightLidRoot.ApplyAngularForce(5.0);
			}
		}
	}

	UFUNCTION()
	void ForceDestroy()
	{
		DestroySpawner();
	}

	void DestroySpawner()
	{
		if (bDestroyed)
			return;

		MagneticFieldResponseComp.SetMagnetizedStatus(false);
		bDestroyed = true;
		DeactivateSpawner();
		OnSpawnerDestroyed.Broadcast();
		BP_DestroySpawner();

		if (PostExplosionDeathVolume != nullptr)
			PostExplosionDeathVolume.EnableDeathVolume(this);
	}

	UFUNCTION(BlueprintEvent)
	void BP_DestroySpawner() {}
}

UCLASS(Abstract)
class ACellBlockGuardSpawnerCore : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent RootComp;

	UPROPERTY(DefaultComponent, Attach = RootComp)
	USceneComponent CoreRoot;

	UPROPERTY(DefaultComponent)
	UBasicAIHealthComponent HealthComp;
	default HealthComp.MaxHealth = 3.0;

	UPROPERTY(DefaultComponent)
	UBasicAIHealthBarComponent HealthBarComp;

	UPROPERTY(DefaultComponent, Attach = CoreRoot)
	UCameraShakeForceFeedbackComponent CamShakeFFComp;

	UPROPERTY(EditInstanceOnly)
	ACellBlockGuardSpawner Spawner;

	bool bDestroyed = false;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{	
		HealthComp.OnTakeDamage.AddUFunction(this, n"TakeDamage");
		SetActorControlSide(Game::Mio);
	}

	UFUNCTION()
	private void TakeDamage(AHazeActor ActorTakingDamage, AHazeActor Attacker, float Damage, EDamageType DamageType)
	{
		if (bDestroyed)
			return;

		AHazePlayerCharacter Player = Cast<AHazePlayerCharacter>(Attacker);
		if (Player != nullptr)
		{
			FVector Dir = (Player.ActorLocation - ActorLocation).GetSafeNormal();
			FVector ImpactLocation = ActorLocation + (Dir * 300.0);

			FCellBlockGuardSpawnerShootCoreImpactData ImpactData;
			ImpactData.ImpactLocation = ImpactLocation;
			ImpactData.ImpactNormal = Dir;
			UCellBlockGuardSpawnerCoreEffectEventHandler::Trigger_ShootCore(this, ImpactData);
		}

		if (HealthComp.CurrentHealth <= 0.0)
		{
			if(HasControl())
				CrumbDestroy();
		}
	}

	UFUNCTION(NotBlueprintCallable, CrumbFunction)
	private void CrumbDestroy()
	{
		if (bDestroyed)
			return;

		bDestroyed = true;

		if (Spawner != nullptr)
			Spawner.DestroySpawner();

		CamShakeFFComp.ActivateCameraShakeAndForceFeedback();

		UCellBlockGuardSpawnerCoreEffectEventHandler::Trigger_Explode(this);

		BP_Destroy();
	}

	UFUNCTION(BlueprintEvent)
	void BP_Destroy() {}
}

class UCellBlockGuardSpawnerCoreEffectEventHandler : UHazeEffectEventHandler
{
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void ShootCore(FCellBlockGuardSpawnerShootCoreImpactData Data) {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void Explode() {}
}

struct FCellBlockGuardSpawnerShootCoreImpactData
{
	UPROPERTY()
	FVector ImpactLocation;

	UPROPERTY()
	FVector ImpactNormal;
}