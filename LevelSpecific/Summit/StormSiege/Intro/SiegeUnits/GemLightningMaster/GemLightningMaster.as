class AGemLightningMaster : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	UCapsuleComponent CapsuleComp;
	default CapsuleComp.SetCollisionEnabled(ECollisionEnabled::QueryAndPhysics);
	default CapsuleComp.SetCollisionResponseToAllChannels(ECollisionResponse::ECR_Ignore);
	default CapsuleComp.SetCollisionResponseToChannel(ECollisionChannel::PlayerCharacter, ECollisionResponse::ECR_Block);

	UPROPERTY(DefaultComponent, Attach = Root)
	UStaticMeshComponent MeshComp;

	UPROPERTY(DefaultComponent)
	UHazeCapabilityComponent CapabilityComp;
	default CapabilityComp.DefaultCapabilities.Add(n"GemLightningMasterAttackCapability");
	default CapabilityComp.DefaultCapabilities.Add(n"GemLightningMasterShockwaveCapability");

	UPROPERTY(DefaultComponent, ShowOnActor)
	UStormSiegeDetectPlayerComponent DetectPlayerComp;
	default DetectPlayerComp.AggressionRange = 25000.0;

	UPROPERTY(DefaultComponent)
	UAdultDragonTailSmashModeResponseComponent ResponseComp;

	UPROPERTY()
	TSubclassOf<UCameraShakeBase> CameraShake;

	float ShockwaveWaitTime = 5.0;
	float LightningWaitTime = 5.0;
	float ShockwaveAttackDelay = 2.5;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		ResponseComp.OnHitBySmashMode.AddUFunction(this, n"OnHitBySmashMode");
	}

	UFUNCTION()
	private void OnHitBySmashMode(FTailSmashModeHitParams Params)
	{
		MeshComp.SetHiddenInGame(true);
		CapsuleComp.SetCollisionEnabled(ECollisionEnabled::NoCollision);
		
		FOnSummitGemSpikeDestroyedParams DestroyParams;
		DestroyParams.Location = ActorLocation;
		DestroyParams.Rotation = ActorRotation;
		DestroyParams.Scale = 1.0;
		USummitGemSpikeEffectHandler::Trigger_DestroyGem(this, DestroyParams);
	}
}