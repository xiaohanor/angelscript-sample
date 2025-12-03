struct FDentistBossToothBrushAttackActivationParams
{
	float MoveDuration;
	float Duration;
	bool bBrushFromRight = true;
}

class UDentistBossToothBrushAttackCapability : UHazeActionQueueCapability
{
	default CapabilityTags.Add(CapabilityTags::GameplayAction);
	default TickGroup = EHazeTickGroup::Gameplay;
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	ADentistBoss Dentist;
	ADentistBossToolToothBrush ToothBrush;
	ADentistBossCake Cake;

	FDentistBossToothBrushAttackActivationParams Params;

	UDentistBossSettings Settings;

	FVector PreviousLocation;

	const float BrushFrequency = 1.8;
	const float GlobCheckDistance = 200.0;

	bool bEffectHasStarted = false;

	TArray<ADentistBossToothPasteGlob> CachedGlobs;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Dentist = Cast<ADentistBoss>(Owner);
		Cake = Dentist.Cake;
		
		Settings = UDentistBossSettings::GetSettings(Dentist);
	}

	UFUNCTION(BlueprintOverride)
	void OnBecomeFrontOfQueue(FDentistBossToothBrushAttackActivationParams InParams)
	{
		Params = InParams;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(ActiveDuration > Params.Duration + Params.MoveDuration)
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		ToothBrush = Cast<ADentistBossToolToothBrush>(Dentist.Tools[EDentistBossTool::ToothBrush]);

		PreviousLocation = ToothBrush.TraceRoot.WorldLocation;

		bEffectHasStarted = false;
		TListedActors<ADentistBossToothPasteGlob> ListedGlobs;
		CachedGlobs = ListedGlobs.Array;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		UDentistBossEffectHandler::Trigger_OnToothBrushStoppedBrushing(Dentist);
		Dentist.CurrentAnimationState.Clear(this);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if(!bEffectHasStarted)
		{
			FDentistBossEffectHandlerOnToothBrushStartedBrushingParams EffectParams;
			EffectParams.BrushEffectRoot = ToothBrush.BrushEffectRoot;
			UDentistBossEffectHandler::Trigger_OnToothBrushStartedBrushing(Dentist, EffectParams);
			bEffectHasStarted = true;
			Dentist.CurrentAnimationState.Clear(this);
		}

		FVector Start = PreviousLocation;
		FVector End = ToothBrush.TraceRoot.WorldLocation;

		if(!(Start - End).IsNearlyZero())
		{
			FHazeTraceSettings Trace;
			Trace.UseSphereShape(GlobCheckDistance);
			Trace.TraceWithChannel(ECollisionChannel::WeaponTraceEnemy);
			Trace.IgnoreActor(ToothBrush);
			Trace.IgnoreActor(Dentist);
			
			auto Hits = Trace.QueryTraceMulti(Start, End);
			
			TEMPORAL_LOG(ToothBrush)
				.HitResults("Tooth Paste Trace", Hits, Start, End, FHazeTraceShape::MakeSphere(GlobCheckDistance))
			;

			for(auto Hit : Hits)
			{
				if(!Hit.bBlockingHit)
					continue;

				auto Glob = Cast<ADentistBossToothPasteGlob>(Hit.Actor);
				if(Glob != nullptr)
				{
					BrushRemoveGlob(Glob);
				}

				auto Player = Cast<AHazePlayerCharacter>(Hit.Actor);
				if(Player != nullptr)
				{
					ToothBrush.LaunchPlayer(Player);
				}
			}
			PreviousLocation = End;
		}

		if (ActiveDuration > 0.2)
		{
			FVector BrushSidewaysVector = Cake.ActorForwardVector;
			FVector BrushingDirection = BrushSidewaysVector;
			if(Params.bBrushFromRight)
				BrushingDirection *= -1;

			TEMPORAL_LOG(Dentist, "Tooth Brush")
				.DirectionalArrow("Brushing direction", ToothBrush.ActorLocation, BrushingDirection * 500, 10, 400, FLinearColor::Red)
			;

			for (ADentistBossToothPasteGlob Globby : CachedGlobs)
			{
				if (Globby.bActive)
				{
					FVector ToGlob = Globby.ActorLocation - ToothBrush.ActorLocation;
					bool bHaveBrushedPast = BrushingDirection.DotProduct(ToGlob) < 0.0;
					if (bHaveBrushedPast)
						BrushRemoveGlob(Globby);
				}
			}
		}

		// ColorDebug::DrawTintedTransform(ActivateLocation, ActivateRotation, ColorDebug::Yellow, 500.0);
		// ColorDebug::DrawTintedTransform(ToothBrush.ActorLocation, ToothBrush.ActorRotation, ColorDebug::Yellow, 500.0);
	}

	private void BrushRemoveGlob(ADentistBossToothPasteGlob Glob)
	{
		FDentistBossEffectHandlerOnToothBrushHitToothPasteParams EffectParams;
		EffectParams.ToothPasteLocation = Glob.ActorLocation;
		UDentistBossEffectHandler::Trigger_OnToothBrushHitToothPaste(Dentist, EffectParams);
		Glob.GetRemoved();
	}
};