class UDiscSlideHydraBuildGrindSplineCapability : UHazeCapability
{
	ADiscSlideHydraSurface Hydra;
	USkeletalMeshComponent HydraSkelly;
	TArray<FVector> Points;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Hydra = Cast<ADiscSlideHydraSurface>(Owner);
		HydraSkelly = Hydra.SkeletalMesh;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (!Hydra.bHasSpline)
			return false;
		if (HydraSkelly == nullptr)
			return false;
		if (!Hydra.bPlayersAreGrinding)
			return false;
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
		HydraSkelly.VisibilityBasedAnimTickOption = EVisibilityBasedAnimTickOption::AlwaysTickPoseAndRefreshBones;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		HydraSkelly.VisibilityBasedAnimTickOption = EVisibilityBasedAnimTickOption::OnlyTickPoseWhenRendered;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		int Granularity = 1; // Every third bone is enough. I think <- scrap that, need one for each bone otherwise approximations get whack ; v ;
		int ExpectedPoints = Math::IntegerDivisionTrunc(Hydra.BoneNames.Num(), Granularity) +1;
		Points.Reset(ExpectedPoints);
		for (int i = Hydra.BoneNames.Num() -1; i >= 0; i -= Granularity)
		{
			FTransform SocketTransform = HydraSkelly.GetSocketTransform(Hydra.BoneNames[i]);
			const float HydraNeckMeshRadius = Hydra.GrindRadius;
			// FVector OffsetToBack = SocketTransform.Rotation.ForwardVector * HydraNeckMeshRadius * Hydra.ActorScale3D.Z; // bone y axis (forward) is mesh z axis (upward) ¯\_(ツ)_/¯
			FVector OffsetToBack = FVector::UpVector * HydraNeckMeshRadius * Hydra.ActorScale3D.Z; // We wished to try global up insteadz
			Points.Add(SocketTransform.Location + OffsetToBack);
		}
		Hydra.RuntimeSpline.SetPoints(Points);
		if (SlidingDiscDevToggles::DrawDisc.IsEnabled())
		{
			Hydra.RuntimeSpline.DrawDebugSpline(150, 10, 0.0, true);
		}
	}
}
