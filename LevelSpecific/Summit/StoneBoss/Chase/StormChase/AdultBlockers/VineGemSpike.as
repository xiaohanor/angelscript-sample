
event void FOnBreakVineGemSpike();
event void FOnVineGemActivated();

struct FVineGemCrystalShard
{
	UVineGemMeshComponent CrystalMesh;
	FVector OriginalPosition;
	FVector StartPosition;
	float DelayTime;
	float CurrentRuptureTime;
	float MinDelayTime = 0.0;
	float MaxDelayTime = 0.5;

	void SetDelayTime()
	{
		DelayTime = Math::RandRange(MinDelayTime, MaxDelayTime);
	}
}

class AVineGemSpike : AHazeActor
{
	UPROPERTY()
	FOnBreakVineGemSpike OnBreakVineGemSpike;

	UPROPERTY()
	FOnVineGemActivated OnVineGemActivated;

	UPROPERTY(DefaultComponent)
	UAdultDragonTailSmashModeResponseComponent ResponseComp;
	// default SpikeResponseComp.bShouldStopPlayer = false;

	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	UAdultDragonHomingTailSmashAutoAimComponent HomingSmashAutoAimComp;
	default HomingSmashAutoAimComp.AutoAimMaxAngle = 60.0;
	default HomingSmashAutoAimComp.TargetShape = FHazeShapeSettings::MakeBox(FVector(3700, 2700, 9250));
	default HomingSmashAutoAimComp.MaximumDistance = 20000;
	default HomingSmashAutoAimComp.RelativeLocation = FVector(0, 0, 9250);

	UPROPERTY(DefaultComponent, Attach = Root)
	UBoxComponent BoxComp;
	default BoxComp.SetCollisionResponseToAllChannels(ECollisionResponse::ECR_Block);

	UPROPERTY(DefaultComponent, Attach = Root)
	UBoxComponent DeathBoxComp;
	default DeathBoxComp.SetCollisionResponseToAllChannels(ECollisionResponse::ECR_Ignore);
	default DeathBoxComp.SetCollisionResponseToChannel(ECollisionChannel::PlayerCharacter, ECollisionResponse::ECR_Overlap);

	UPROPERTY(DefaultComponent, Attach = Root)
	UTargetableOutlineComponent TargetableOutlineComp;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent MeshRoot;

	UPROPERTY(Category = "DeathSettings")
	TSubclassOf<UDeathEffect> ImpactDeathEffect;

	UPROPERTY(EditAnywhere)
	ASerpentEventActivator EventActivator;

	UPROPERTY(EditAnywhere)
	APlayerTrigger PlayerTrigger;

	UPROPERTY(EditAnywhere)
	bool bStartShrunken = true;

	UPROPERTY(EditAnywhere)
	float CrystalsZOffset = 10000.0;

	UPROPERTY(EditAnywhere)
	float RuptureDuration = 1.0;

	UPROPERTY(EditDefaultsOnly)
	bool bUseStatueEyeDestructionVersion = false;

	UPROPERTY(EditDefaultsOnly)
	FRuntimeFloatCurve CrystalSpeedCurve;
	default CrystalSpeedCurve.AddDefaultKey(0.0, 0.0);
	default CrystalSpeedCurve.AddDefaultKey(1.0, 1.0);

	//TODO - For the crystal spawning
	TArray<UVineGemMeshComponent> CrystalMeshComps;
	TArray<FVineGemCrystalShard> CrystalShardData;

	bool bHasBeenActivated;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		GetComponentsByClass(UVineGemMeshComponent, CrystalMeshComps);

		for (UVineGemMeshComponent Comp : CrystalMeshComps)
		{
			FVineGemCrystalShard Data;
			Data.CrystalMesh = Comp;
			Data.OriginalPosition = Comp.WorldLocation;
			Data.SetDelayTime();

			CrystalShardData.Add(Data);
		}
	
		if (EventActivator != nullptr)
			EventActivator.OnSerpentEventTriggered.AddUFunction(this, n"ActivateSpike");

		if (PlayerTrigger != nullptr)
			PlayerTrigger.OnPlayerEnter.AddUFunction(this, n"OnPlayerEnter");

		if (bStartShrunken)
		{
			for (FVineGemCrystalShard& Data : CrystalShardData)
			{
				Data.CrystalMesh.WorldLocation -= Data.CrystalMesh.UpVector * CrystalsZOffset;
				Data.StartPosition = Data.CrystalMesh.WorldLocation;
			}	

			SetActorTickEnabled(false);
			HomingSmashAutoAimComp.Disable(this);
		}

		ResponseComp.OnHitBySmashMode.AddUFunction(this, n"OnHitBySmashMode");
		DeathBoxComp.OnComponentBeginOverlap.AddUFunction(this, n"OnComponentBeginOverlap");
	}

	UFUNCTION()
	private void OnHitBySmashMode(FTailSmashModeHitParams Params)
	{
		UVineGemSpikeEffectHandler::Trigger_OnCrystalDestroyed(this, FVineGemOnCrystalDestroyedParams(ActorLocation));
		USummitGemSpikeEffectHandler::Trigger_DestroyGem(this, FOnSummitGemSpikeDestroyedParams());

		HomingSmashAutoAimComp.Disable(this);
		AddActorDisable(this);
		OnBreakVineGemSpike.Broadcast();
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		if (!bStartShrunken)
			return;
		
		for (FVineGemCrystalShard& Data : CrystalShardData)
		{
			if (Data.DelayTime > 0.0)
			{
				Data.DelayTime -= DeltaSeconds;
			}
			else
			{
				Data.CurrentRuptureTime += DeltaSeconds;
				float MoveAlpha = Math::Clamp(Data.CurrentRuptureTime / RuptureDuration, 0.0, 1.0);
				Data.CrystalMesh.SetWorldLocation(Math::Lerp(Data.StartPosition, Data.OriginalPosition, CrystalSpeedCurve.GetFloatValue(MoveAlpha)));
				// Data.CrystalMesh.SetWorldLocation(Math::VInterpConstantTo(Data.CrystalMesh.WorldLocation, Data.OriginalPosition, DeltaSeconds, CrystalsZOffset * 1.5));
			}			
		}	
	}

	UFUNCTION()
	private void OnPlayerEnter(AHazePlayerCharacter Player)
	{
		if (bHasBeenActivated)
			return;

		ActivateSpike();
		bHasBeenActivated = true;
	}

	UFUNCTION()
	void ActivateSpike()
	{
		SetActorTickEnabled(true);
		HomingSmashAutoAimComp.Enable(this);

		for (FVineGemCrystalShard& Data : CrystalShardData)
		{
			Data.CrystalMesh.SetHiddenInGame(false);
			Data.CurrentRuptureTime = 0.0;
		}	

		USummitGemSpikeEffectHandler::Trigger_GrowGem(this, FOnSummitGemSpikeGrowParams(ActorLocation));

		BP_VineGemActivated();
		OnVineGemActivated.Broadcast();
	}

	UFUNCTION()
	private void OnComponentBeginOverlap(UPrimitiveComponent OverlappedComponent, AActor OtherActor,
								 UPrimitiveComponent OtherComp, int OtherBodyIndex,
								 bool bFromSweep, const FHitResult&in SweepResult)
	{
		AHazePlayerCharacter Player = Cast<AHazePlayerCharacter>(OtherActor);
		if (Player == nullptr)
			return;

		if (Player.IsAnyCapabilityActive(AdultDragonCapabilityTags::AdultDragonSmashMode) || Player.IsAnyCapabilityActive(AdultDragonTailSmash::Tags::AdultDragonTailSmash))
			return;

		Player.KillPlayer(FPlayerDeathDamageParams(-ActorRightVector), ImpactDeathEffect);
	}

	UFUNCTION(BlueprintEvent)
	void BP_VineGemActivated()
	{

	}
}

class UVineGemMeshComponent : UStaticMeshComponent
{
	default SetMobility(EComponentMobility::Movable);
	default SetCollisionEnabled(ECollisionEnabled::NoCollision);
}