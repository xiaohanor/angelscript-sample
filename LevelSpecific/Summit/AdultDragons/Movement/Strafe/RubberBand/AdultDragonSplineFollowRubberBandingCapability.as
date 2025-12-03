class UAdultDragonSplineFollowRubberBandingCapability : UHazePlayerCapability
{
	default CapabilityTags.Add(CapabilityTags::GameplayAction);

	default TickGroup = EHazeTickGroup::Gameplay;

	UAdultDragonSplineFollowManagerComponent SplineFollowComp;
	UPlayerAdultDragonComponent DragonComp;
	AAdultDragonBoundarySpline BoundarySpline;
	UAdultDragonSplineFollowRubberBandingSettings RubberBandSettings;

	// DEBUG for testing swappes
	// bool bHasSwapped = false;
	// float DebugSwapLeft = 0;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		RubberBandSettings = UAdultDragonSplineFollowRubberBandingSettings::GetSettings(Player);
		DragonComp = UPlayerAdultDragonComponent::Get(Player);
		BoundarySpline = TListedActors<AAdultDragonBoundarySpline>().GetSingle();
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		SplineFollowComp.RubberBandingMoveSpeedMultiplier = 1;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if (SplineFollowComp == nullptr)
			SplineFollowComp = UAdultDragonSplineFollowManagerComponent::Get(Player);

		// DEBUG for testing swappes
		// {
		// 	DebugSwapLeft -= DeltaTime;
		// 	if(DebugSwapLeft < 0)
		// 	{
		// 		DebugSwapLeft = 10;
		// 		if(!bHasSwapped)
		// 			UAdultDragonSplineFollowRubberBandingSettings::SetPreferredAheadPlayer(Player, EHazePlayer::Mio, this);
		// 		else
		// 			UAdultDragonSplineFollowRubberBandingSettings::SetPreferredAheadPlayer(Player, EHazePlayer::Zoe, this);

		// 		bHasSwapped = !bHasSwapped;
		// 	}
		// }

		auto MainSpline = BoundarySpline;
		auto OtherMainSpline = BoundarySpline;

		if (MainSpline == nullptr)
		{
			SplineFollowComp.RubberBandingMoveSpeedMultiplier = 1;
			return;
		}

		if (OtherMainSpline == nullptr)
		{
			SplineFollowComp.RubberBandingMoveSpeedMultiplier = 1;
			return;
		}

		auto SplinePos = MainSpline.Spline.GetClosestSplinePositionToWorldLocation(Player.ActorLocation);
		if (!SplinePos.IsValid())
		{
			SplineFollowComp.RubberBandingMoveSpeedMultiplier = 1;
			return;
		}

		auto OtherSplinePos = OtherMainSpline.Spline.GetClosestSplinePositionToWorldLocation(Player.OtherPlayer.ActorLocation);
		if (!OtherSplinePos.IsValid())
		{
			SplineFollowComp.RubberBandingMoveSpeedMultiplier = 1;
			return;
		}

		const float MinDistance = RubberBandSettings.MinDistance;
		const float MaxDistance = RubberBandSettings.MaxDistance;
		const float Diff = SplinePos.CurrentSplineDistance - OtherSplinePos.CurrentSplineDistance;
		const float AbsDiff = Math::Abs(Diff);

		float Alpha = 0;
		if (AbsDiff < MinDistance)
			Alpha = 1 - (AbsDiff / MinDistance);
		else
		{
			float AmountOverThreshold = AbsDiff - MinDistance;
			float RubberBandLength = MaxDistance - MinDistance;
			if (Math::IsNearlyZero(RubberBandLength))
				Alpha = 1;
			else
				Alpha = AmountOverThreshold / RubberBandLength;
		}

		Alpha = Math::Saturate(Alpha);
		Alpha = Math::Pow(Alpha, 2);

		AHazePlayerCharacter WantedHeadPlayer = Game::GetPlayer(RubberBandSettings.PreferredAheadPlayer);
		AHazePlayerCharacter CurrentAheadPlayer = Diff > 0 ? Player : Player.OtherPlayer;

// We want to be ahead
#if !RELEASE
		FLinearColor DebugColor = FLinearColor::White;
#endif

		if (WantedHeadPlayer == Player)
		{
			// We are behind and need to quickly get ahead
			if (CurrentAheadPlayer != Player || AbsDiff < MinDistance)
			{
#if !RELEASE
				DebugColor = FLinearColor::Red;
#endif

				SplineFollowComp.RubberBandingMoveSpeedMultiplier = Math::FInterpTo(SplineFollowComp.RubberBandingMoveSpeedMultiplier, RubberBandSettings.MaxBehindSpeedMultiplier, DeltaTime, 1);
			}
			else
			{
#if !RELEASE
				DebugColor = FLinearColor::LucBlue;
#endif
				float TargetMultiplier = Math::Lerp(1, RubberBandSettings.MaxAHeadSpeedMultiplier, Alpha);
				SplineFollowComp.RubberBandingMoveSpeedMultiplier = Math::FInterpTo(SplineFollowComp.RubberBandingMoveSpeedMultiplier, TargetMultiplier, DeltaTime, 1);
			}
		}
		// We want to be behind
		else
		{
			// We are ahead and need to quickly get behind the other player
			if (CurrentAheadPlayer == Player || AbsDiff < MinDistance)
			{
#if !RELEASE
				DebugColor = FLinearColor::Blue;
#endif

				SplineFollowComp.RubberBandingMoveSpeedMultiplier = Math::FInterpTo(SplineFollowComp.RubberBandingMoveSpeedMultiplier, RubberBandSettings.MaxAHeadSpeedMultiplier, DeltaTime, 1);
			}
			else
			{
#if !RELEASE
				DebugColor = FLinearColor::DPink;
#endif
				float TargetMultiplier = Math::Lerp(1, RubberBandSettings.MaxBehindSpeedMultiplier, Alpha);
				SplineFollowComp.RubberBandingMoveSpeedMultiplier = Math::FInterpTo(SplineFollowComp.RubberBandingMoveSpeedMultiplier, TargetMultiplier, DeltaTime, 1);
			}
		}

#if !RELEASE
		TEMPORAL_LOG(Player, "RubberBand")
			.Value("Prefered Ahead", WantedHeadPlayer)
			.Value("Current Ahead", CurrentAheadPlayer)
			.Value("Distance", AbsDiff)
			.Value("MinDistance", RubberBandSettings.MinDistance)
			.Value("MaxDistance", RubberBandSettings.MaxDistance)
			.Value("Multiplier", SplineFollowComp.RubberBandingMoveSpeedMultiplier)
			.Sphere("Rubberband", Player.ActorCenterLocation, 1000, DebugColor);
#endif
	}
};
