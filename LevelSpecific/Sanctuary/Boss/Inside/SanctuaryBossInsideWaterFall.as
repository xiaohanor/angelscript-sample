UCLASS(Abstract)
class USanctuaryBossInsideWaterFallEventHandler : UHazeEffectEventHandler
{
	UFUNCTION(BlueprintOverride)
	void Setup()
	{
	}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnStart()
	{
	}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnStop()
	{
	}



};	
class ASanctuaryBossInsideWaterFall : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent)
	ULightBirdResponseComponent ResponseComp;

	UPROPERTY(DefaultComponent)
	UNiagaraComponent WaterfallVFX;

	UPROPERTY(DefaultComponent)
	UNiagaraComponent WaterfallImpactVFX;

	UPROPERTY(DefaultComponent)
	UBoxComponent BoxCollision;

	UPROPERTY(DefaultComponent)
	USpotSoundComponent SpotSoundComp;
	default SpotSoundComp.Settings.bPlayOnStart = false;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		ResponseComp.OnIlluminated.AddUFunction(this, n"HandleOnIlluminated");
		ResponseComp.OnUnilluminated.AddUFunction(this, n"HandleOnUnIlluminated");
		BoxCollision.OnComponentBeginOverlap.AddUFunction(this, n"HandleOnBeginOverlap");
		USanctuaryBossInsideWaterFallEventHandler::Trigger_OnStart(this);
		SpotSoundComp.Start();		
	}

	UFUNCTION()
	private void HandleOnBeginOverlap(UPrimitiveComponent OverlappedComponent, AActor OtherActor,
	                                  UPrimitiveComponent OtherComp, int OtherBodyIndex, bool bFromSweep,
	                                  const FHitResult&in SweepResult)
	{
		auto Player = Cast<AHazePlayerCharacter>(OtherActor);
		if(Player != nullptr && !ResponseComp.IsIlluminated())
		{
			Player.ApplyKnockdown(ActorForwardVector * 1500.0, 2.0);
			Player.DamagePlayerHealth(0.1);
		}
			
	}

	UFUNCTION()
	private void HandleOnIlluminated()
	{
		WaterfallVFX.Deactivate();
		WaterfallImpactVFX.Deactivate();
		USanctuaryBossInsideWaterFallEventHandler::Trigger_OnStop(this);
		SpotSoundComp.Stop();

		if(SpotSoundComp.AssetData.SoundDefAsset.IsValid())
		{
			RemoveSoundDef(SpotSoundComp.AssetData.SoundDefAsset);
		}
	}

	UFUNCTION()
	private void HandleOnUnIlluminated()
	{
		WaterfallVFX.Activate();
		WaterfallImpactVFX.Activate();
		USanctuaryBossInsideWaterFallEventHandler::Trigger_OnStart(this);		
		SpotSoundComp.Start();		
		
		for(auto Player : Game::Players)
			{
				if(BoxCollision.IsOverlappingActor(Player))
				{
					Player.ApplyKnockdown(ActorForwardVector * 1500.0, 2.0);	
					Player.DamagePlayerHealth(0.1);
				}
			}
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		
	}
};