class UMedallionPlayerFlyingCheckHydrasCapability : UHazePlayerCapability
{
	default CapabilityTags.Add(MedallionTags::MedallionTag);
	default TickGroup = EHazeTickGroup::BeforeGameplay;

	UMedallionPlayerComponent MedallionComp;
	UMedallionPlayerReferencesComponent RefsComp;

	UMedallionPlayerGloryKillComponent GloryKillComp;

	UMedallionPlayerFlyingMovementComponent AirMoveDataComp;

	ASanctuaryBossMedallionSpline FlyingSpline;
	float LastSplineDist;
	float RealDistanceClosest = 0.0;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		MedallionComp = UMedallionPlayerComponent::GetOrCreate(Player);
		GloryKillComp = UMedallionPlayerGloryKillComponent::GetOrCreate(Player);
		RefsComp = UMedallionPlayerReferencesComponent::GetOrCreate(Player);
		AirMoveDataComp = UMedallionPlayerFlyingMovementComponent::GetOrCreate(Owner);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (RefsComp.Refs == nullptr)
			return false;
		if (!MedallionComp.IsMedallionCoopFlying())
			return false;
		if (GloryKillComp.GloryKillState != EMedallionGloryKillState::None)
			return false;
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (GloryKillComp.GloryKillState != EMedallionGloryKillState::None)
			return true;
		if (!MedallionComp.IsMedallionCoopFlying())
			return true;
		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		FlyingSpline = RefsComp.Refs.MedallionBossPlane2D.GetFlyingSpline();
		LastSplineDist = RefsComp.Refs.MedallionBossPlane2D.AccSplineDistance.Value;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		// FlyingSpline = RefsComp.Refs.MedallionBossPlane2D.GetFlyingSpline();
		// AirMoveDataComp.CachedOurSplineDist = RefsComp.Refs.MedallionBossPlane2D.AccSplineDistance.Value;
		// RealDistanceClosest = BIG_NUMBER;

		// if (SanctuaryMedallionHydraDevToggles::Draw::SelectHydra.IsEnabled())
		// 	Debug::DrawDebugString(RefsComp.Refs.MedallionBossPlane2D.ActorCenterLocation, "Plane Dist: " + AirMoveDataComp.CachedOurSplineDist, ColorDebug::Pink);
		
		// for (ASanctuaryBossMedallionHydra Hydra : RefsComp.Refs.Hydras)
		// {
		// 	if (Hydra.bDead)
		// 		continue;

		// 	float HydraDist = FlyingSpline.Spline.GetClosestSplineDistanceToWorldLocation(Hydra.ActorLocation);
		// 	float Diff = (RefsComp.Refs.MedallionBossPlane2D.ActorCenterLocation - Hydra.ActorLocation).Size();
		// 	// if (Diff > RefsComp.Refs.MedallionBossPlane2D.PlaneExtents.X * 2.0) // lodded away lolol
		// 	// 	continue;

		// 	if (SanctuaryMedallionHydraDevToggles::Draw::SelectHydra.IsEnabled())
		// 		DebugDrawHydra(Hydra, HydraDist);

		// 	bool bTriggerKill = false;
		// 	bool bTriggerKnocked = false;

		// 	FTransform CutoffBoneTransform = Hydra.GetCutBoneTransform();
		// 	FVector PlaneLocation = RefsComp.Refs.MedallionBossPlane2D.ActorLocation;
		// 	FVector HydraRelativeToPlane = CutoffBoneTransform.Location - PlaneLocation;
		// 	float HydraClosestDistanceToPlane = RefsComp.Refs.MedallionBossPlane2D.ActorForwardVector.DotProduct(HydraRelativeToPlane);

		// 	if (HydraClosestDistanceToPlane > 0.0 && HydraClosestDistanceToPlane < MedallionConstants::SelectHydra::PlaneDistanceStartTryKill)
		// 	{
		// 		bTriggerKill = true;
		// 	}

		// 	float SplineDiff = Math::Abs(HydraDist - AirMoveDataComp.CachedOurSplineDist);
		// 	if (SplineDiff < AirMoveDataComp.FlyingClosestHydraDistance && Diff < RealDistanceClosest)
		// 	{
		// 		RealDistanceClosest = Diff;
		// 		AirMoveDataComp.bWithinGettingKnockDistance = bTriggerKnocked;
		// 		AirMoveDataComp.bWithinHydraStrangleDistance = bTriggerKill;
		// 		AirMoveDataComp.FlyingClosestHydraDistance = SplineDiff;
		// 		AirMoveDataComp.FlyingClosestHydra = Hydra;

		// 		if (bTriggerKill)
		// 			break;
		// 	}
		// }

		if (SanctuaryMedallionHydraDevToggles::Draw::Spline.IsEnabled())
		{ 
			Debug::DrawDebugString(Player.ActorLocation, Player.GetName() + " x:\n" + AirMoveDataComp.SyncedSideways.Value);
		}

		// LastSplineDist = AirMoveDataComp.CachedOurSplineDist;
	}

	
};