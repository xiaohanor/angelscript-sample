class USanctuaryBossMedallionHydraMovePivotCapability : UHazeCapability
{
	default TickGroup = EHazeTickGroup::AfterGameplay;

	USanctuaryBossMedallionHydraMovePivotComponent HeadComp;
	ASanctuaryBossMedallionHydra Hydra;
	FTransform IdleRelativeTransform;

	FSanctuaryBossMedallionHydraMovePivotRequest PreviousRequest;
	FSanctuaryBossMedallionHydraMovePivotRequest LastRequest;
	FHazeAcceleratedTransform AccHeadTransform;
	FHazeAcceleratedFloat AccUsePivotAlpha;
	FTransform StartTransform;

	float StartBlendTimestamp;
	bool bLastRequestSnap = false;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		HeadComp = USanctuaryBossMedallionHydraMovePivotComponent::GetOrCreate(Owner);
		Hydra = Cast<ASanctuaryBossMedallionHydra>(Owner);
		IdleRelativeTransform = Hydra.HeadPivot.RelativeTransform;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (HeadComp.MovePivotRequests.Num() == 0)
			return false;
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (HeadComp.MovePivotRequests.Num() > 0)
			return false;
		if (AccUsePivotAlpha.Value > KINDA_SMALL_NUMBER)
			return false;
		return true;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		StartTransform = Hydra.HeadPivot.WorldTransform;
		AccHeadTransform.SnapTo(StartTransform);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		const bool bCutsceneDisabled = Hydra.bIsControlledByCutscene && !Hydra.bAllowCinematicHeadPivot;
		const bool bNoBlend = bCutsceneDisabled || Hydra.HeadPivotBlockers.Num() > 0;
		if (HeadComp.MovePivotRequests.Num() == 0 || bNoBlend)
			FadeOutPivot(DeltaTime, bNoBlend);
		else
		{
			FadeInPivot(DeltaTime);
			TEMPORAL_LOG(Hydra, "Requesters").Sphere("Transforms Head Pivot Loc", LastRequest.SceneComponentToFollow.WorldLocation, 100.0, ColorDebug::White);
		}
		
		Hydra.HeadPivot.SetWorldTransform(AccHeadTransform.Value);
		Hydra.HeadPivotLookAlpha = AccUsePivotAlpha.Value;

		TEMPORAL_LOG(Hydra, "Requesters").Value("Transforms Head Pivot Alpha", Hydra.HeadPivotLookAlpha);
		if (SanctuaryMedallionHydraDevToggles::Draw::HydraHeadPivot.IsEnabled())
		{
			Debug::DrawDebugString(Hydra.HeadPivot.WorldLocation, "Alpha: " + Hydra.HeadPivotLookAlpha, ColorDebug::White, 0.0, 0.8);
			Debug::DrawDebugCoordinateSystem(Hydra.HeadPivot.WorldLocation, Hydra.HeadPivot.WorldRotation, 2000 * Hydra.HeadPivotLookAlpha, 20, 0.0, true);
		}
	}

	void FadeOutPivot(float DeltaTime, bool bNoBlend)
	{
		if (LastRequest.Instigator != nullptr)
		{
			StartTransform = AccHeadTransform.Value;
			StartBlendTimestamp = Time::GameTimeSeconds;
			LastRequest.Instigator = nullptr;
		}
		if (bNoBlend || LastRequest.bSnapOnExit)
			AccUsePivotAlpha.SnapTo(0.0);
		else
			AccUsePivotAlpha.AccelerateToWithStop(0.0, 1.0, DeltaTime, 0.01);
	}

	void FadeInPivot(float DeltaTime)
	{
		FSanctuaryBossMedallionHydraMovePivotRequest ActiveRequest = HeadComp.MovePivotRequests[0];
		if (LastRequest.Instigator != ActiveRequest.Instigator)
			UpdateRequest(ActiveRequest);

		// from 0 to 1 over duration
		float BlendDurationAlpha = Math::GetMappedRangeValueClamped(FVector2D(StartBlendTimestamp, StartBlendTimestamp + LastRequest.BlendInDuration), FVector2D(0.0, 1.0), Time::GameTimeSeconds);
		float EasedDurationAlpha = Math::EaseInOut(0.0, 1.0, BlendDurationAlpha, 2);
		
		// from 1 to 0 over duration
		float ReverseDurationAlpha = Math::Saturate(1.0 - EasedDurationAlpha);
		bool bBlendDone = ReverseDurationAlpha < KINDA_SMALL_NUMBER;
		
		if (bBlendDone)
			AccUsePivotAlpha.AccelerateToWithStop(1.0, ReverseDurationAlpha, DeltaTime, 0.01);
		else
			AccUsePivotAlpha.SnapTo(1.0);

		bool bShouldSnap = (LastRequest.bSnapFirstTime && HeadComp.MovePivotRequests[0].NumActivations == 1) || bLastRequestSnap;
		if (bShouldSnap || bBlendDone)
			AccHeadTransform.SnapTo(LastRequest.SceneComponentToFollow.WorldTransform);
		else // blend
		{
			FVector BlendedLocation = Math::Lerp(StartTransform.Location, LastRequest.SceneComponentToFollow.WorldLocation, EasedDurationAlpha);
			FQuat BlendedRotation = FQuat::Slerp(StartTransform.Rotation, LastRequest.SceneComponentToFollow.WorldRotation.Quaternion(), EasedDurationAlpha);
			FTransform BlendedTransform(BlendedRotation, BlendedLocation);
			AccHeadTransform.SnapTo(BlendedTransform);
		}

		if (SanctuaryMedallionHydraDevToggles::Draw::HydraHeadPivot.IsEnabled())
		{

			if (PreviousRequest.SceneComponentToFollow != nullptr)
			{
				FVector End = ActiveRequest.SceneComponentToFollow.WorldLocation;
				FVector StartLocation = PreviousRequest.SceneComponentToFollow.WorldLocation;
				FVector Direction = StartLocation - End;
				Debug::DrawDebugLine(StartLocation, End, Hydra.DebugColor, 5.0, 0.0, true);
				Debug::DrawDebugCone(End, Direction, 200, LineColor = Hydra.DebugColor, bDrawInForeground = true);

				Debug::DrawDebugString(End, "\n\n\n\n\nCurrent:" + ActiveRequest.SceneComponentToFollow.Owner.ActorNameOrLabel + "\n\nsnap: " + bShouldSnap);
				//Debug::DrawDebugString(StartLocation, "\n\n\n\n\nLast:" + PreviousRequest.SceneComponentToFollow.Owner.ActorNameOrLabel + "\n\nsnap: " + bShouldSnap);
			}
		}

	}

	void UpdateRequest(FSanctuaryBossMedallionHydraMovePivotRequest ActiveRequest)
	{
		PreviousRequest = LastRequest;
		bLastRequestSnap = LastRequest.bSnapOnExit;
		StartTransform = AccHeadTransform.Value;
		StartBlendTimestamp = Time::GameTimeSeconds;
		LastRequest = ActiveRequest;
		HeadComp.MovePivotRequests[0].NumActivations += 1;
	}
};