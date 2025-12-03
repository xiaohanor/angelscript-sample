class ASanctuaryLavamoleMortarProjectilePool : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent)
	UStaticMeshComponent LavaPoolMesh;

	UPROPERTY(DefaultComponent)
	UHazeActorRespawnableComponent RespawnComp;

	UPROPERTY(DefaultComponent)
	USanctuaryLavaApplierComponent LavaApplier;
	private UPlayerCentipedeComponent CentipedeComp;

	float AliveDuration = 0.0;
	const float AppearDuration = 1.5;
	const float /*What a*/ TimeToBeAlive = 5.0;
	const float DisappearDuration = 4.0;

	FVector OGScale = FVector::OneVector;
	bool bInactive = false;

	float HitRadius = 0.0;

	UFUNCTION(BlueprintOverride)
	void ConstructionScript()
	{
		// Ignore centipede body collisions for movement
		AddActorTag(CentipedeTags::IgnoreCentipedeBody);
	}

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		OGScale = LavaPoolMesh.GetWorldScale();
		AddActorTickBlock(this);
		AddActorVisualsBlock(this);
	}

	void Reset()
	{
		bInactive = false;
		AliveDuration = 0.0;
		RemoveActorTickBlock(this);
		RemoveActorVisualsBlock(this);
		LavaPoolMesh.SetHiddenInGame(false);
		USanctuaryLavamoleMortarProjectilePoolEventHandler::Trigger_OnAppear(this);
		BP_OnPoolStart();
	}

	UFUNCTION(BlueprintEvent)
	void BP_OnPoolStart() {}

	UFUNCTION(BlueprintEvent)
	void BP_OnPoolStop() {}

	void FightIsOver()
	{
		if (AliveDuration >= AppearDuration && AliveDuration <= TimeToBeAlive)
			AliveDuration = TimeToBeAlive;
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		if (!TryCacheThings())
			return;

		if (bInactive)
			return;

		AliveDuration += DeltaSeconds;
		if (AliveDuration < TimeToBeAlive)
		{
			const float GrowAlpha = Math::Clamp(AliveDuration / AppearDuration, 0.0, 1.0);
			const float ScalingMagnitude = SanctuaryLavamoleMortarPoolScaleInCurve.GetFloatValue(GrowAlpha);
			FVector UsedScale = OGScale * Math::Clamp(ScalingMagnitude, 0.01, 50.0);
			UsedScale.Z = OGScale.Z;

			LavaPoolMesh.SetWorldScale3D(UsedScale);
			
			const float CentipedeRadius = 50.0;
			const float PoolRadius = 150.0 * ScalingMagnitude;
			HitRadius = CentipedeRadius + PoolRadius;

		}
		else if (AliveDuration < TimeToBeAlive + DisappearDuration)
		{
			const float DisappearingTimer = AliveDuration - TimeToBeAlive;
			const float ScaleOutAlpha = Math::Saturate(DisappearingTimer / DisappearDuration);

			const float ScalingMagnitude = SanctuaryLavamoleMortarPoolScaleOutCurve.GetFloatValue(ScaleOutAlpha);
			if (ScalingMagnitude < 0.01)
				LavaPoolMesh.SetHiddenInGame(true);
			FVector UsedScale = OGScale * Math::Clamp(ScalingMagnitude, 0.01, 50.0);
			UsedScale.Z = OGScale.Z;

			LavaPoolMesh.SetWorldScale3D(UsedScale);
			
			const float CentipedeRadius = 50.0;
			const float PoolRadius = 150.0 * ScalingMagnitude;
			HitRadius = CentipedeRadius + PoolRadius;

		}
		else
		{
			bInactive = true;
			USanctuaryLavamoleMortarProjectilePoolEventHandler::Trigger_OnDisappear(this);
			AddActorTickBlock(this);
			AddActorVisualsBlock(this);
			RespawnComp.UnSpawn();
			BP_OnPoolStop();
		}

		if (bInactive)
			return;

		// Debug::DrawDebugSphere(ActorLocation, PoolRadius, 12, ColorDebug::Carrot, 5.0, 0.0, true);
		for (FVector Location: GetBodyLocations())
		{
			// Debug::DrawDebugSphere(Location, CentipedeRadius, 12, ColorDebug::Algae, 5.0, 0.0, true);
			if(!ActorLocation.IsWithinDist(Location, HitRadius))
				continue;
			//LavaApplier.OverlapSingleFrame(Location, HitRadius, false);
		}
	}

	private TArray<FVector> GetBodyLocations() const
	{
		TArray<FVector> Locations;
		if(ensure(CentipedeComp != nullptr, "Can only target centipede players!"))
			Locations = CentipedeComp.GetBodyLocations();
		Locations.Add(Game::Mio.ActorLocation);
		Locations.Add(Game::Zoe.ActorLocation);
		return Locations;
	}

	private bool TryCacheThings()
	{
		if (CentipedeComp == nullptr)
			CentipedeComp = UPlayerCentipedeComponent::Get(Game::Mio);
		return CentipedeComp != nullptr;
	}
};