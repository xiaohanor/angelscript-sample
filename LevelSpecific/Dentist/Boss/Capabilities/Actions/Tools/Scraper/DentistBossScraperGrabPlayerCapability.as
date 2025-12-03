struct FDentistBossScraperGrabPlayerActivationParams
{
	float MoveDuration;
	float DragBackDuration;
	float TelegraphDuration;
}

class UDentistBossScraperGrabPlayerCapability : UHazeActionQueueCapability
{
	default CapabilityTags.Add(CapabilityTags::GameplayAction);
	default TickGroup = EHazeTickGroup::Gameplay;
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	ADentistBoss Dentist;
	ADentistBossToolScraper Scraper;
	
	UDentistBossTargetComponent TargetComp;

	FDentistBossScraperGrabPlayerActivationParams Params;

	UDentistBossSettings Settings;

	AHazePlayerCharacter TargetedPlayer;

	bool bHasCompletedTelegraph = false;
	bool bHasCapturedPlayer = false;
	float TimeLastCompletedTelegraph = -MAX_flt;
	float TimeLastCapturedPlayer = -MAX_flt;

	FTransform HookCaptureStartTransform;
	FTransform HookDragBackStartTransform;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Dentist = Cast<ADentistBoss>(Owner);
		TargetComp = UDentistBossTargetComponent::GetOrCreate(Dentist);

		Settings = UDentistBossSettings::GetSettings(Dentist);
	}

	UFUNCTION(BlueprintOverride)
	void OnBecomeFrontOfQueue(FDentistBossScraperGrabPlayerActivationParams InParams)
	{
		Params = InParams;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		auto Target = TargetComp.Target.Get();
		if(Target.IsPlayerDead())
			return false;

		if(!TargetComp.IsOnCake[Target])
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(ActiveDuration > Params.MoveDuration + Params.TelegraphDuration + Params.DragBackDuration)
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		TargetedPlayer = TargetComp.Target.Get();
		TargetComp.LastPlayerHooked = TargetedPlayer;

		auto Tool = Dentist.Tools[EDentistBossTool::Scraper];
		Scraper = Cast<ADentistBossToolScraper>(Tool);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Dentist.SetIKTransform(EDentistBossArm::LeftTop, GetTargetLocation(), GetTargetRotation());
		Dentist.ClearIKState(this);

		bHasCompletedTelegraph = false;
		bHasCapturedPlayer = false;
		
		Dentist.bHookTelegraphDone = false;
		Dentist.bHammerSplitPlayer = false;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if(Params.TelegraphDuration == 0)
			return;

		if(Params.MoveDuration == 0)
			return;

		if(Params.DragBackDuration == 0)
			return;

		auto TempLog = TEMPORAL_LOG(Dentist, "Hook Attack")
			.Value("TimeLastCompletedTelegraph", TimeLastCompletedTelegraph)
			.Value("TimeLastCapturedPlayer", TimeLastCapturedPlayer)
		;

		if(!bHasCompletedTelegraph)
		{
			float Alpha = ActiveDuration / Params.TelegraphDuration;
			if(Alpha >= 1.0)
			{
				Dentist.CurrentIKState.Apply(EDentistIKState::FullBody, this, EInstigatePriority::High);
				HookCaptureStartTransform = Dentist.GetIKTransform(EDentistBossArm::LeftTop);
				Dentist.bHookTelegraphDone = true;
				TimeLastCompletedTelegraph = Time::GameTimeSeconds;
				bHasCompletedTelegraph = true;
			}
			TempLog.Value("Alpha", Alpha);
		}
		else if(!bHasCapturedPlayer)
		{
			float TimeSinceCompletedTelegraph = Time::GetGameTimeSince(TimeLastCompletedTelegraph);
			float Alpha = TimeSinceCompletedTelegraph / Params.MoveDuration;
			Alpha = Math::EaseIn(0.0, 1.0, Alpha, 3.0);

			FVector TargetLocation = GetTargetLocation();
			FRotator TargetRotation = GetTargetRotation();

			FVector NewLocation;
			FRotator NewRotation;

			if(Alpha <= 1.0)
			{
				NewLocation = Math::Lerp(HookCaptureStartTransform.Location, TargetLocation, Alpha);
				float RotationAlpha = Math::EaseOut(0.0, 1.0, TimeSinceCompletedTelegraph / Params.MoveDuration, 10);
				NewRotation = Math::LerpShortestPath(HookCaptureStartTransform.Rotator(), TargetRotation, RotationAlpha);
			}
			else
			{
				NewLocation = TargetLocation;
				NewRotation = TargetRotation;
				Scraper.RestrainedPlayer.Set(TargetedPlayer);

				FDentistBossEffectHandlerOnScraperHookedPlayerParams EffectParams;
				EffectParams.HookTipLocation = Scraper.TipRoot.WorldLocation;
				EffectParams.HookTipRotation = Scraper.TipRoot.WorldRotation;
				EffectParams.HookedPlayer = TargetedPlayer;
				UDentistBossEffectHandler::Trigger_OnScraperHookedPlayer(Dentist, EffectParams);

				TargetedPlayer.PlayWorldCameraShake(Settings.HookedPlayerCameraShake, this, Scraper.ActorLocation, 1000, 2000);
				TargetedPlayer.PlayForceFeedback(Settings.HookedPlayerForceFeedback, false, true, this);
				TargetedPlayer.ApplyBlendToCurrentView(3.0);

				HookDragBackStartTransform = FTransform(TargetRotation, TargetLocation);

				TimeLastCapturedPlayer = Time::GameTimeSeconds;
				bHasCapturedPlayer = true;

			}
			Dentist.SetIKTransform(EDentistBossArm::LeftTop, NewLocation, NewRotation);
			TempLog.Value("Alpha", Alpha);
		}
		else
		{
			float TimeSinceCapturedPlayer = Time::GetGameTimeSince(TimeLastCapturedPlayer);
			float Alpha = TimeSinceCapturedPlayer / Params.DragBackDuration;
			Alpha = Math::EaseInOut(0.0, 1.0, Alpha, 3.0);
			Alpha = Math::Saturate(Alpha);

			FVector TargetLocation = GetTargetLocation();
			FRotator TargetRotation = GetTargetRotation();

			FVector NewLocation = Math::Lerp(HookDragBackStartTransform.Location, TargetLocation, Alpha);
			FRotator NewRotation = Math::LerpShortestPath(HookDragBackStartTransform.Rotator(), TargetRotation, Alpha);

			Dentist.SetIKTransform(EDentistBossArm::LeftTop, NewLocation, NewRotation);
			TempLog.Value("Alpha", Alpha);
		}
	}

	FVector GetTargetLocation() const 
	{
		auto TempLog = TEMPORAL_LOG(Dentist, "Hook Attack");
		FVector TargetLocation;
		if(!bHasCapturedPlayer)
		{
			TargetLocation = TargetedPlayer.ActorLocation + FVector::UpVector * DentistBossMeasurements::HookAttachUpOffset;
			TargetLocation -= DentistBossMeasurements::HookTipOffset;
		}
		else
			TargetLocation = Dentist.Cake.ActorLocation + DentistBossMeasurements::HookDragBackCakeRelativeLocation;

		TempLog.Sphere("Target Location", TargetLocation, 50, FLinearColor::Blue, 10);
		return TargetLocation;
	}

	FRotator GetTargetRotation() const
	{
		return FRotator::MakeFromXY(Dentist.ActorRightVector.RotateAngleAxis(90, FVector::UpVector), FVector::UpVector);
	}
};