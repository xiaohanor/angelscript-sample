class USummitExplodyFruitExplodeCapability : UHazeCapability
{
	default CapabilityTags.Add(CapabilityTags::GameplayAction);

	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	default TickGroup = EHazeTickGroup::Gameplay;

	ASummitExplodyFruit Fruit;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Fruit = Cast<ASummitExplodyFruit>(Owner);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if(!Fruit.bIsEnabled)
			return false;

		if(Fruit.TimeLastHitByAcid.IsSet())
			return true;

		if(Fruit.TimeToExplodeFromAdjacentExplosion.IsSet())
			return true;

		if(Fruit.bHasHitDespawnVolume)
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(!Fruit.bIsEnabled)
			return true;

		if(ActiveDuration >= Fruit.FuseDuration)
			return true;

		if(Fruit.TimeToExplodeFromAdjacentExplosion.IsSet()
			&& Time::GameTimeSeconds >= Fruit.TimeToExplodeFromAdjacentExplosion.Value)
			return true;

		if(Fruit.bHasHitDespawnVolume)
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		FHazeTraceSettings Trace;
		Trace.UseSphereShape(Fruit.ExplosionRadius);
		Trace.TraceWithProfileFromComponent(Fruit.SphereComp);
		Trace.IgnoreActor(Fruit);
		FVector ExplodeLocation = Fruit.CenterScaleRoot.WorldLocation;
		auto Overlaps = Trace.QueryOverlaps(ExplodeLocation);

		TArray<AActor> ExplodedActors;

		const float MultiExplosionDelayDuration = 0.1;
		float MultiExplosionDelay = MultiExplosionDelayDuration;

		bool bExplodedNearWall = false;
		for(auto Overlap : Overlaps)
		{
			if(ExplodedActors.Contains(Overlap.Actor))
				continue;

			auto Player = Cast<AHazePlayerCharacter>(Overlap.Actor);
			if(Player != nullptr)
				Player.KillPlayer();
			
			auto OverlappingFruit = Cast<ASummitExplodyFruit>(Overlap.Actor);
			if(OverlappingFruit != nullptr
			&& !OverlappingFruit.bIsGrowing)
			{
				OverlappingFruit.TimeToExplodeFromAdjacentExplosion.Set(Time::GameTimeSeconds + MultiExplosionDelay);
				MultiExplosionDelay += MultiExplosionDelayDuration;
			}

			if(Overlap.Actor.IsA(ASummitExplodyFruitWallCrack))
			{
				bExplodedNearWall = true;
			}

			auto ResponseComp = USummitExplodyFruitResponseComponent::Get(Overlap.Actor);
			if(ResponseComp != nullptr)
			{
				FSummitExplodyFruitExplosionParams Params;
				Params.ExplosionLocation = ExplodeLocation;
				Params.HitComponent = Overlap.Component;
				ResponseComp.OnFruitExplode.Broadcast(Params);
			}

			ExplodedActors.AddUnique(Overlap.Actor);
		}

		if(bExplodedNearWall)
			USummitExplodyFruitTreeEffectHandler::Trigger_OnFruitExplodingWithWall(Fruit);
		else
			USummitExplodyFruitTreeEffectHandler::Trigger_OnFruitExploding(Fruit);

		for (AHazePlayerCharacter Player : Game::Players)
		{
			Player.PlayWorldCameraShake(Fruit.CameraShake, this, Fruit.ActorLocation, 2000, 15000);
		}

		if(Fruit.TimeToExplodeFromAdjacentExplosion.IsSet())
			Fruit.TimeToExplodeFromAdjacentExplosion.Reset();

		if(Fruit.TimeLastHitByAcid.IsSet())
			Fruit.TimeLastHitByAcid.Reset();

		if(Fruit.CurrentAttachment.IsSet())
			Fruit.CurrentAttachment.Reset();

		Fruit.CenterScaleRoot.SetRelativeScale3D(FVector::OneVector);
		Fruit.OnExploded.Broadcast(Fruit);
		Fruit.TimeLastExploded = Time::GameTimeSeconds;

		Fruit.bIsEnabled = false;
		Fruit.bHasHitDespawnVolume = false;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		float ExplosionAlpha = ActiveDuration / Fruit.FuseDuration;
		float ExplosionScaleUpFrequency = Math::Lerp(Fruit.ExplosionScaleUpPulseFrequencyStart, Fruit.ExplosionScaleUpPulseFrequencyEnd, ExplosionAlpha);

		float ScaleMagnitude = 1 - (Math::Sin(ActiveDuration * ExplosionScaleUpFrequency) * Fruit.LitScaleUpMagnitude);

		Fruit.CenterScaleRoot.SetRelativeScale3D(FVector::OneVector * ScaleMagnitude);
	}
};