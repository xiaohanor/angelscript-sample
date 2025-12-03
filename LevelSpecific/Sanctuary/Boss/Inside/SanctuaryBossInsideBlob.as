UCLASS(Abstract)
class USanctuaryBossInsideBlobEventHandler : UHazeEffectEventHandler
{
	UFUNCTION(BlueprintOverride)
	void Setup()
	{
	}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnStartGrowing()
	{
	}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnExplode()
	{
	}

};	
class ASanctuaryBossInsideBlob : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent)
	USceneComponent BlobRoot;

	UPROPERTY(DefaultComponent, Attach = BlobRoot)
	UStaticMeshComponent BlobMesh;

	FVector InitialScale;

	UPROPERTY(Category = TimeLikes)
	FHazeTimeLike GrowTimeLike;

	UPROPERTY(EditDefaultsOnly)
	TSubclassOf<ASanctuaryInsideBlobClusterBomb> ClusterProjectileClass;

	UPROPERTY(DefaultComponent)
	USphereComponent ExplodeRadius;
	default ExplodeRadius.bDisableUpdateOverlapsOnComponentMove = true;

	UPROPERTY(DefaultComponent)
	USphereComponent ActivateCollision;
	default ActivateCollision.bDisableUpdateOverlapsOnComponentMove = true;

	UPROPERTY(DefaultComponent)
	UHazeSphereComponent HazeSphere;

	UPROPERTY(DefaultComponent)
	USceneComponent ProjectileLandLocation1;
	
	UPROPERTY(DefaultComponent)
	USceneComponent ProjectileLandLocation3;

	UPROPERTY(DefaultComponent)
	USceneComponent ProjectileLandLocation2;

	UPROPERTY(DefaultComponent)
	UCameraShakeForceFeedbackComponent CameraShakeForceFeedbackComponent;

	
	UPROPERTY(DefaultComponent)
	UCameraShakeForceFeedbackComponent CameraShakeForceFeedbackComponent2;

	UPROPERTY(DefaultComponent)
	UDisableComponent DisableComp;
	default DisableComp.bAutoDisable = true;
	default DisableComp.AutoDisableRange = 15000;

	float StartOpacity;

	UPROPERTY(EditAnywhere)
	float GrowValue = 1.15;

	UPROPERTY(EditAnywhere)
	float ExplodeGrowth = 2.0;

	UPROPERTY(DefaultComponent)
	UHazeActionQueueComponent ActionQueComp;
	UPROPERTY()
	FRuntimeFloatCurve FloatCurve;

	bool bDoOnce = true;
	int ProjectilesToSpawn = 3;
	float ProjectileSpeedSpread = 800.0;
	

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		GrowTimeLike.BindUpdate(this, n"HandleTimeLikeUpdate");
		ActivateCollision.OnComponentBeginOverlap.AddUFunction(this, n"HandleBeginOverlap");
		StartOpacity = HazeSphere.Opacity;
		InitialScale = BlobRoot.RelativeScale3D;


		Timer::SetTimer(this, n"StartGrowing", Math::RandRange(0.1, 1.0));
		
	}


	UFUNCTION()
	private void StartGrowing()
	{
		GrowTimeLike.Play();
	}

	UFUNCTION()
	private void HandleBeginOverlap(UPrimitiveComponent OverlappedComponent, AActor OtherActor,
	                                UPrimitiveComponent OtherComp, int OtherBodyIndex, bool bFromSweep,
	                                const FHitResult&in SweepResult)
	{
			auto Player = Cast<AHazePlayerCharacter>(OtherActor);
		if (Player == nullptr)
			return;
		
		if(!bDoOnce)
			return;
		
		GrowTimeLike.Stop();
		bDoOnce = false;
		InitialScale = BlobRoot.RelativeScale3D;
		HazeSphere.SetOpacityOverTime(1.9, 0.45);
		USanctuaryBossInsideBlobEventHandler::Trigger_OnStartGrowing(this);
		CameraShakeForceFeedbackComponent.ActivateCameraShakeAndForceFeedback();
		ActionQueComp.Duration(2.0, this, n"HandleExplode");
		ActionQueComp.Event(this, n"Explode");
		
	}

	UFUNCTION()
	private void HandleExplode(float Alpha)
	{
		BlobRoot.SetRelativeScale3D(Math::Lerp(InitialScale, InitialScale * ExplodeGrowth, Alpha));
	}

	UFUNCTION()
	private void Explode()
	{
		for (auto Player : Game::Players)
		{
			if (ExplodeRadius.IsOverlappingActor(Player))
			{
				FVector KnockdownMove = (Player.ActorLocation - ExplodeRadius.WorldLocation).GetSafeNormal() * 500.0;
				Player.ApplyKnockdown(KnockdownMove, 1.5);
				Player.DamagePlayerHealth(0.5);
			}
		}

		CameraShakeForceFeedbackComponent2.ActivateCameraShakeAndForceFeedback();
		HazeSphere.SetOpacityValue(0.0);
		BlobMesh.SetHiddenInGame(true);
		BlobMesh.SetCollisionEnabled(ECollisionEnabled::NoCollision);
		USanctuaryBossInsideBlobEventHandler::Trigger_OnExplode(this);
		
		BP_Explode();

		for (int i = 0; i < ProjectilesToSpawn; i++)
		{
			const float Alpha = float(i) / (ProjectilesToSpawn - 1);
		
			auto ClusterProjectile = SpawnActor(ClusterProjectileClass, ActorLocation, ActorRotation, bDeferredSpawn = true);	
			
			if(i==0)
			{
				ClusterProjectile.TargetLocation = ProjectileLandLocation1.GetWorldLocation();
			}else if(i==1){
				ClusterProjectile.TargetLocation = ProjectileLandLocation2.GetWorldLocation();
			}else{
				ClusterProjectile.TargetLocation = ProjectileLandLocation3.GetWorldLocation();
			}

			FinishSpawningActor(ClusterProjectile);	
		}
	
	}

	UFUNCTION(BlueprintEvent)
	void BP_Explode()
	{
	}

	UFUNCTION()
	private void HandleTimeLikeUpdate(float CurrentValue)
	{
		BlobRoot.SetRelativeScale3D(Math::Lerp(InitialScale, InitialScale * GrowValue, CurrentValue));
	}


};