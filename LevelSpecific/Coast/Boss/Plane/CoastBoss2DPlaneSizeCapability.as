class UCoastBoss2DPlaneSizeCapability : UHazeCapability
{
	default CapabilityTags.Add(CoastBossTags::CoastBossTag);
	default TickGroup = EHazeTickGroup::Gameplay;
	UHazeCameraComponent Camera;
	ACoastBoss2DPlane Plane;

	float CheckNewCameraCooldown = 0.0;

	FHazeAcceleratedFloat AccPlaneWidth;
	float PlaneWidthTarget = 0.0;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Plane = Cast<ACoastBoss2DPlane>(Owner);
		PlaneWidthTarget = Plane.PlaneExtents.X;
		AccPlaneWidth.SnapTo(PlaneWidthTarget);
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
	void TickActive(float DeltaTime)
	{
		CheckNewCameraCooldown -= DeltaTime;
		if (CheckNewCameraCooldown < 0.0)
		{
			CheckNewCameraCooldown = 1.0;
			Camera = Game::Mio.GetCurrentlyUsedCamera();

			FVector2D SupposedPlaneExtents = FVector2D(Plane.PlayersSmallestRatio, 1.0) * Plane.PlaneHeight * 0.5;
			if (!Math::IsNearlyEqual(SupposedPlaneExtents.X, Plane.PlaneExtents.X, KINDA_SMALL_NUMBER))
			{
				FVector2D NewRatio = FVector2D(Plane.PlayersSmallestRatio, 1.0);
				FVector2D NewExtents = NewRatio * Plane.PlaneHeight * 0.5;
				PlaneWidthTarget = NewExtents.X;
			}
		}

		AccPlaneWidth.AccelerateTo(PlaneWidthTarget, 0.5, DeltaTime);
		Plane.PlaneExtents.X = AccPlaneWidth.Value;
		if (CoastBossDevToggles::Draw::Draw2DPlane.IsEnabled())
		{
			Debug::DrawDebugString(Plane.ActorLocation, "Plane Width: " + Plane.PlaneExtents.X * 2.0, ColorDebug::White, 0.0, 1.2);
			Debug::DrawDebugString(Plane.ActorLocation, "\n\nPlane Height: " + Plane.PlaneExtents.Y * 2.0, ColorDebug::White, 0.0, 1.2);
		}
	}
};