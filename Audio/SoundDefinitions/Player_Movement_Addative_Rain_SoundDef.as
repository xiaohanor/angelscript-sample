
UCLASS(Abstract)
class UPlayer_Movement_Addative_Rain_SoundDef : USoundDefBase
{
	/* AUTO-GENERATED CODE - Anything from here to end should NOT be edited! */

	/* END OF AUTO-GENERATED CODE */

	TArray<FBoxSphereBounds> RainBlockerBounds;
	const float EDGE_ATTENUATION_FADE_DISTANCE = 1000;

	float PlayerRainAlpha = 1.0;	

	private UPlayerAudioMaterialComponent MaterialComp;

	UPROPERTY(EditDefaultsOnly)
	UPhysicalMaterialAudioAsset WaterPuddleAudioPhysMat;

	UFUNCTION(BlueprintEvent)
	void OnWaterFootstep_Left(FPlayerFootstepParams FootstepParams) {};

	UFUNCTION(BlueprintEvent)
	void OnWaterFootstep_Right(FPlayerFootstepParams FootstepParams) {};

	UFUNCTION(BlueprintEvent)
	void OnWaterHandImpact_Left(FPlayerHandImpactParams HandParams) {};

	UFUNCTION(BlueprintEvent)
	void OnWaterHandImpact_Right(FPlayerHandImpactParams HandParams) {};

	bool GetbIsInRainArea() const property
	{
		return PlayerRainAlpha > 0.0;
	}

	UFUNCTION(BlueprintPure, Meta = (CompactNodeTitle = "Get Rain Alpha"))
	float GetPlayerRainAlpha()
	{
		return PlayerRainAlpha;
	}

	UFUNCTION(BlueprintOverride)
	void ParentSetup()
	{
		MaterialComp = UPlayerAudioMaterialComponent::Get(PlayerOwner);

		TArray<ARainBlocker> RainBlockers = TListedActors<ARainBlocker>().Array;
		for(auto RainBlocker : RainBlockers)
		{
			RainBlockerBounds.Add(FBoxSphereBounds(RainBlocker.ActorLocation, RainBlocker.ActorTransform.Scale3D, RainBlocker.ActorTransform.Scale3D.Size()));
		}

		TArray<AKillParticleVolume> ParticleKillers = TListedActors<AKillParticleVolume>().Array;
		for(auto ParticleKiller : ParticleKillers)
		{
			RainBlockerBounds.Add(ParticleKiller.BrushComponent.Bounds);
		}
	}

	bool EdgeIntersectsBlocker(int CurrentBlockerIndex, const FVector Point)
	{
		// Try to find out if the closest edge of the current blocker intersects (or close to) with another blocker
		for(int i = 0; i < RainBlockerBounds.Num(); ++i)
		{
			if(i == CurrentBlockerIndex)
				continue;

			FBoxSphereBounds ItBlocker = RainBlockerBounds[i];
			
			// Good enough?
			if(ItBlocker.ComputeSquaredDistanceFromBoxToPoint(Point) < 10)
				return true;
		}

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaSeconds)
	{
		PlayerRainAlpha = 1.0;

		for(int i = 0; i < RainBlockerBounds.Num(); ++i)
		{				
			FBoxSphereBounds RainBlocker = RainBlockerBounds[i];
			if(IsDebugging())
			{
				Debug::DrawDebugString(RainBlocker.Origin, "Rain Blocker", Color = FLinearColor::DPink);
				Debug::DrawDebugBox(RainBlocker.Origin, RainBlocker.BoxExtent, LineColor = FLinearColor::DPink, Thickness = 20.0, bDrawInForeground = true);
			}

			const FVector PlayerLocation = PlayerOwner.ActorLocation;
			const bool bPlayerInBlocker = RainBlocker.Box.IsInside(PlayerLocation);
			if(bPlayerInBlocker)
			{
				FVector PlayerBoundsLocation = RainBlocker.Origin - PlayerLocation; 
				FVector NormalizedBoundsPlayerVector = PlayerBoundsLocation.GetAbs() / RainBlocker.BoxExtent;
				
				float X = 0.0;
				float Y = 0.0;

				FHazeTraceSettings Trace;
				Trace.TraceWithChannel(ECollisionChannel::ECC_WorldStatic);
				Trace.IgnoreActor(PlayerOwner);
				Trace.UseLine();

				FVector End = PlayerOwner.ActorCenterLocation;
				End.X += RainBlocker.BoxExtent.X * Math::Sign(PlayerLocation.X - RainBlocker.Origin.X) * (1 - NormalizedBoundsPlayerVector.X);
				
				if(IsDebugging())
					Trace.DebugDrawOneFrame();
				
				FHitResult XHitResult = Trace.QueryTraceSingle(PlayerOwner.ActorCenterLocation, End);

				if(!XHitResult.bBlockingHit && !EdgeIntersectsBlocker(i, End))
				{
					X = 1 - Math::Saturate(End.Distance(PlayerOwner.ActorLocation) / EDGE_ATTENUATION_FADE_DISTANCE);	
				}

				End = PlayerOwner.ActorCenterLocation;
				End.Y += RainBlocker.BoxExtent.Y * Math::Sign(PlayerLocation.Y - RainBlocker.Origin.Y) * (1 - NormalizedBoundsPlayerVector.Y);

				if(IsDebugging())
					Trace.DebugDrawOneFrame();

				FHitResult YHitResult = Trace.QueryTraceSingle(PlayerOwner.ActorCenterLocation, End);
				if(!YHitResult.bBlockingHit && !EdgeIntersectsBlocker(i, End))
				{
					Y = 1 - Math::Saturate(End.Distance(PlayerOwner.ActorLocation) / EDGE_ATTENUATION_FADE_DISTANCE);		
				}

				PlayerRainAlpha = Math::Pow(Math::Min(PlayerRainAlpha, Math::Max(X, Y)), 2.0);		
			}
		}	

		MaterialComp.bInRain=PlayerRainAlpha > 0.0;

		#if TEST
		auto Log = TEMPORAL_LOG(PlayerOwner, "Audio/Foot");
		Log.Value("Rain;Rain Alpha: ", PlayerRainAlpha);
		#endif
	}

	UFUNCTION(NotBlueprintCallable)
	void OnFootstepTrace_Left(FPlayerFootstepParams FootstepParams)
	{
		if(!bIsInRainArea)
		 	return;

		FPlayerFootstepParams WaterPuddleFootstepParams;
		WaterPuddleFootstepParams = FootstepParams;
		WaterPuddleFootstepParams.AudioPhysMat = WaterPuddleAudioPhysMat;

		bool bIsBothFeet;
		MaterialComp.GetMaterialEvent(n"Water_Puddle", WaterPuddleFootstepParams.MovementState, EFootType::Left, WaterPuddleFootstepParams.FootStepType, WaterPuddleFootstepParams.MaterialEvent, bIsBothFeet);

		OnWaterFootstep_Left(WaterPuddleFootstepParams);
	}

	UFUNCTION(NotBlueprintCallable)
	void OnFootstepTrace_Right(FPlayerFootstepParams FootstepParams)
	{
		if(!bIsInRainArea)
		 	return;

		FPlayerFootstepParams WaterPuddleFootstepParams;
		WaterPuddleFootstepParams = FootstepParams;
		WaterPuddleFootstepParams.AudioPhysMat = WaterPuddleAudioPhysMat;

		bool bIsBothFeet;
		MaterialComp.GetMaterialEvent(n"Water_Puddle", WaterPuddleFootstepParams.MovementState, EFootType::Right, WaterPuddleFootstepParams.FootStepType, WaterPuddleFootstepParams.MaterialEvent, bIsBothFeet);

		OnWaterFootstep_Left(WaterPuddleFootstepParams);
	}

	// UFUNCTION(NotBlueprintCallable)
	// void StartFootSlide(FPlayerFootSlideStartAudioParams SlideParams) {};

	// UFUNCTION(NotBlueprintCallable)
	// void StopFootSlide(FPlayerFootSlideStopAudioParams SlideParams) {};

	// UFUNCTION(NotBlueprintCallable)
	// void StartFootSlideLoop(FPlayerFootSlideStartAudioParams SlideParams) {};

	// UFUNCTION(NotBlueprintCallable)
	// void StopFootSlideLoop() {};

	// UFUNCTION(NotBlueprintCallable)
	// void TickFootSlide(FPlayerFootSlideTickParams TickParams) {};

	UFUNCTION(NotBlueprintCallable)
	void OnHandTrace_Left(FPlayerHandImpactParams ImpactParams)
	{
		if(!bIsInRainArea)
		 	return;

		FPlayerHandImpactParams WaterPuddleImpactParams = ImpactParams;
		WaterPuddleImpactParams.AudioPhysMat = WaterPuddleAudioPhysMat;
		
		MaterialComp.GetMaterialEvent(n"Water_Puddle", ImpactParams.MovementState, ImpactParams.ActionType, WaterPuddleImpactParams.MaterialEvent);
		OnWaterHandImpact_Left(WaterPuddleImpactParams);
	}

	UFUNCTION(NotBlueprintCallable)
	void OnHandTrace_Right(FPlayerHandImpactParams ImpactParams)
	{
		if(!bIsInRainArea)
		 	return;

		FPlayerHandImpactParams WaterPuddleImpactParams = ImpactParams;
		WaterPuddleImpactParams.AudioPhysMat = WaterPuddleAudioPhysMat;
		
		MaterialComp.GetMaterialEvent(n"Water_Puddle", ImpactParams.MovementState, ImpactParams.ActionType, WaterPuddleImpactParams.MaterialEvent);
		OnWaterHandImpact_Right(WaterPuddleImpactParams);
	}

	// UFUNCTION(NotBlueprintCallable)
	// void StartHandSlide(FPlayerHandSlideAudioParams StartParams) {};
	
	// UFUNCTION(NotBlueprintCallable)
	// void StopHandSlide(FPlayerHandSlideAudioParams StopParams) {};

	// UFUNCTION(NotBlueprintCallable)
	// void StartHandSlideLoop(FPlayerHandSlideAudioParams SlideParams) {};

	// UFUNCTION(NotBlueprintCallable)
	// void StopHandSlideLoop(FPlayerHandSlideAudioParams SlideParams) {};

	// UFUNCTION(NotBlueprintCallable)
	// void TickHandSlide(FPlayerHandSlideTickParams TickParams) {};

}