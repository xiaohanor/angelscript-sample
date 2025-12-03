class ABattlefieldSlowMoGrappleManager : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

#if EDITOR
	UPROPERTY(DefaultComponent, Attach = Root)
	UBillboardComponent Visual;
	default Visual.SetWorldScale3D(FVector(5.0));
#endif

	UPROPERTY(DefaultComponent)
	UHazeListedActorComponent ListComp;

	UPROPERTY(DefaultComponent)
	UHazeCapabilityComponent CapabilityComp;
	default CapabilityComp.DefaultCapabilities.Add(n"BattlefieldSlowMoGrappleCheckCapability");
	default CapabilityComp.DefaultCapabilities.Add(n"BattlefieldSlowMoGrappleActiveCapability");

	UPROPERTY(EditInstanceOnly)
	TPerPlayer<APropLine> Grinds;
	TPerPlayer<UHazeSplineComponent> SplineComps;

	UPROPERTY(EditAnywhere)
	UPlayerHealthSettings HealthSettings;

	UPROPERTY(EditInstanceOnly)
	TArray<AAlienCruiserMissileDestructionPlatform> Platforms;
	  
	UPROPERTY(EditInstanceOnly)
	ARespawnOnSplineNearOtherPlayerVolume SplineRespawn;

	UPROPERTY(EditInstanceOnly)
	TPerPlayer<UHazeCameraSpringArmSettingsDataAsset> CameraSetting;

	UPROPERTY(EditInstanceOnly)
	FSoundDefReference SoundDef;

	bool bBeginSlowMo;
	TPerPlayer<bool> bPlayersEngaged;

	bool bGrappleCompleted;

	float DistanceLookAhead = 2500.0;

	int DestroyedCounter;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		if(SoundDef.IsValid())
			SoundDef.SpawnSoundDefAttached(this);
		
		SplineComps[Game::Mio] = UHazeSplineComponent::Get(Grinds[Game::Mio]);
		SplineComps[Game::Zoe] = UHazeSplineComponent::Get(Grinds[Game::Zoe]);

		for(AAlienCruiserMissileDestructionPlatform Platform : Platforms)
		{
			Platform.OnAlienCruiserPlatformDestroyed.AddUFunction(this, n"OnAlienCruiserPlatformDestroyed");
		}
	}

	UFUNCTION()
	private void OnAlienCruiserPlatformDestroyed()
	{
		DestroyedCounter++;
		if (DestroyedCounter >= Platforms.Num())
		{
			auto BFGrind1 = UBattlefieldHoverboardGrindSplineComponent::Get(Grinds[0]);
			BFGrind1.bAllowedToGrappleTo = true;
			auto BFGrind2 = UBattlefieldHoverboardGrindSplineComponent::Get(Grinds[1]);
			BFGrind2.bAllowedToGrappleTo = true;			
		}
	}

	void PlayerLaunched(AHazePlayerCharacter Player)
	{
		bPlayersEngaged[Player] = true;

		if (bPlayersEngaged[Player.OtherPlayer])
			StartSlowMo();
	}

	void StartSlowMo()
	{
		bBeginSlowMo = true;

		auto BFGrind1 = UBattlefieldHoverboardGrindSplineComponent::Get(Grinds[0]);
		BFGrind1.bAllowedToGrappleTo = true;
		auto BFGrind2 = UBattlefieldHoverboardGrindSplineComponent::Get(Grinds[1]);
		BFGrind2.bAllowedToGrappleTo = true;

		for (AHazePlayerCharacter Player : Game::Players)
			Player.ApplySettings(HealthSettings, this, EHazeSettingsPriority::Override);

		UBattlefieldSlowMoGrappleEventHandler::Trigger_OnSlowMoStarted(this);
	}

	void CompleteDoubleGrapple()
	{
		bGrappleCompleted = true;

		auto BFGrind1 = UBattlefieldHoverboardGrindSplineComponent::Get(Grinds[0]);
		BFGrind1.bAllowedToGrappleTo = false;
		auto BFGrind2 = UBattlefieldHoverboardGrindSplineComponent::Get(Grinds[1]);
		BFGrind2.bAllowedToGrappleTo = false;

		UBattlefieldSlowMoGrappleEventHandler::Trigger_OnSlowMoStopped(this);
	}

	void AnyPlayerGrappleClearSplineRespawn()
	{
		SplineRespawn.DisablePlayerTrigger(this);
	}

	FVector GetSplineLocation(AHazePlayerCharacter Player)
	{
		float StartingDistance = SplineComps[Player].GetClosestSplineDistanceToWorldLocation(Player.ActorLocation);
		float TargetDistance = StartingDistance + DistanceLookAhead;
		return SplineComps[Player].GetWorldLocationAtSplineDistance(TargetDistance);
	}
};