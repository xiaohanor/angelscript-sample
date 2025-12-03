class UEnforcerRocketLauncherProjectileIndicatorWidget : UHazeUserWidget
{
	default bAttachToEdgeOfScreen = true;

	UPROPERTY()
	bool bIsOffScreen = false;

	UPROPERTY()
	float ShowDistance = 6000.0;

	UPROPERTY()
	float ShowFadeDistance = 200.0;

	// Screen space offset at minimum distance
	UPROPERTY()
	float MinDistScreenSpaceOffset = 20.0;

	// Screen space offset at maximum distance
	UPROPERTY()
	float MaxDistScreenSpaceOffset = 20.0;

	// Distance at which the maximum screen space offset is reached
	UPROPERTY()
	float MaxOffsetDist = 10000.0;

	float OffscreenLerp = -1.0;
	float DistanceHideLerp = -1.0;

	float PrevOffset = 0.0;
	float PrevHeadingAngle = 0.0;
	float PrevScreenSpaceOffset = 0.0;

	float AlwaysVisibleLerp = 0.0;
	float HiddenLerp = 1.0;

	UFUNCTION(BlueprintOverride)
	void OnAttachToEdgeOfScreen()
	{
		bIsOffScreen = true;
	}

	UFUNCTION(BlueprintOverride)
	void OnDetachFromEdgeOfScreen()
	{
		bIsOffScreen = false;
	}

	UFUNCTION(BlueprintOverride)
	void Tick(FGeometry MyGeometry, float DeltaTime)
	{
		float Distance = Player.GetDistanceTo(Player.OtherPlayer); 
		float PrevDistanceLerp = DistanceHideLerp;
		float PrevOffscreenLerp = OffscreenLerp;
		float PrevAlwaysVisibleLerp = AlwaysVisibleLerp;
		float PrevHiddenLerp = HiddenLerp;

		DistanceHideLerp = Math::Saturate((Distance - ShowDistance) / ShowFadeDistance);

		AlwaysVisibleLerp = Math::FInterpConstantTo(AlwaysVisibleLerp, 0.0, DeltaTime, 3.0);

		if (Player.OtherPlayer.IsPlayerDead())
			HiddenLerp = Math::FInterpConstantTo(HiddenLerp, 0.0, DeltaTime, 3.0);
		else
			HiddenLerp = Math::FInterpConstantTo(HiddenLerp, 1.0, DeltaTime, 3.0);

		if (bIsOffScreen)
			OffscreenLerp = Math::Saturate(OffscreenLerp + (DeltaTime * 3.0));
		else
			OffscreenLerp = Math::Saturate(OffscreenLerp - (DeltaTime * 3.0));

		if (PrevDistanceLerp != DistanceHideLerp || PrevOffscreenLerp != OffscreenLerp
			|| PrevAlwaysVisibleLerp != AlwaysVisibleLerp || PrevHiddenLerp != HiddenLerp)
		{
			float HeadingAngle = FVector(EdgeAttachDirection.X, EdgeAttachDirection.Y, 0.0).HeadingAngle();
			PrevHeadingAngle = HeadingAngle;

			float FinalOpacity = Math::Max3(DistanceHideLerp, OffscreenLerp, AlwaysVisibleLerp);
			FinalOpacity = Math::Min(FinalOpacity, HiddenLerp);
		}
		else if (OffscreenLerp > 0.0)
		{
			float HeadingAngle = FVector(EdgeAttachDirection.X, EdgeAttachDirection.Y, 0.0).HeadingAngle();
			if (PrevHeadingAngle != HeadingAngle)
			{
				PrevHeadingAngle = HeadingAngle;
			}
		}

		float NewScreenSpaceOffset = 
			Math::Lerp(
				Math::Lerp(MinDistScreenSpaceOffset, MaxDistScreenSpaceOffset, Math::Saturate(Distance / MaxOffsetDist)),
				0.0,
				OffscreenLerp
			);
		if (NewScreenSpaceOffset != PrevScreenSpaceOffset)
		{
			PrevScreenSpaceOffset = NewScreenSpaceOffset;
		}
		
	}
};