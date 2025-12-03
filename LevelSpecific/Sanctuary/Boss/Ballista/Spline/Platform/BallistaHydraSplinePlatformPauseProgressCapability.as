class UBallistaHydraSplinePlatformPauseProgressCapability : UHazeCapability
{
	default TickGroup = EHazeTickGroup::Gameplay;

	AHazePlayerCharacter Mio;
	AHazePlayerCharacter Zoe;
	ABallistaHydraSplinePlatform Platform;
	UMedallionPlayerReferencesComponent MioRefsComp;

	const float LeftPhaseWaitDuration = 5.0;
	float LeftPhaseTimestamp;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Mio = Game::Mio;
		Zoe = Game::Zoe;
		MioRefsComp = UMedallionPlayerReferencesComponent::GetOrCreate(Mio);
		Platform = Cast<ABallistaHydraSplinePlatform>(Owner);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (!Platform.PauseSplineStartPhase.IsSet())
				return false;
		if (!Platform.PauseSplineLastPhase.IsSet())
			return false;
		if (MioRefsComp.Refs == nullptr)
			return false;
		if (!IsInPausedPhase())
			return false;
		if (Platform.ParentSpline == nullptr)
			return false;
		if (Platform.PlatformCurrentSplineDist < Platform.ParentSpline.PlatformsSinkDistance - Platform.PauseBeforeSinkingDistance)
			return false;
		if (Platform.GetIsUnderWater())
			return false;
		return true;
	}

	bool IsInPausedPhase() const
	{
		if (MioRefsComp.Refs.HydraAttackManager.Phase >= Platform.PauseSplineStartPhase.Value && MioRefsComp.Refs.HydraAttackManager.Phase <= Platform.PauseSplineLastPhase.Value)
			return true;
		return false;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (Time::GameTimeSeconds < LeftPhaseTimestamp + LeftPhaseWaitDuration)
			return false;
		return true;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Platform.ParentSpline.PauseProgressInstigators.Add(this);
		LeftPhaseTimestamp = Time::GameTimeSeconds;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Platform.ParentSpline.PauseProgressInstigators.Remove(this);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if (IsInPausedPhase())
			LeftPhaseTimestamp = Time::GameTimeSeconds;
		if (SanctuaryBallistaHydraDevToggles::Draw::Spline.IsEnabled())
		{
			Debug::DrawDebugString(Platform.ActorLocation, "PAUSED SPLINE");
		}
	}
};