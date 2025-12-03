struct FMedallionPlayerGloryKill0SelectHydraData
{
	ASanctuaryBossMedallionHydra SelectedHydra;
}

class UMedallionPlayerGloryKill0SelectHydraCapability : UHazePlayerCapability
{
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;
	default CapabilityTags.Add(MedallionTags::MedallionTag);
	default CapabilityTags.Add(MedallionTags::MedallionGloryKill);
	default TickGroup = EHazeTickGroup::Gameplay;

	UMedallionPlayerComponent MedallionComp;
	UMedallionPlayerReferencesComponent RefsComp;

	UMedallionPlayerGloryKillComponent GloryKillComp;
	UMedallionPlayerGloryKillComponent OtherGloryKillComp;

	UMedallionPlayerFlyingMovementComponent AirMoveDataComp;
	UMedallionPlayerFlyingMovementComponent OtherAirMoveDataComp;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		MedallionComp = UMedallionPlayerComponent::GetOrCreate(Player);
		GloryKillComp = UMedallionPlayerGloryKillComponent::GetOrCreate(Player);
		OtherGloryKillComp = UMedallionPlayerGloryKillComponent::GetOrCreate(Player.OtherPlayer);
		RefsComp = UMedallionPlayerReferencesComponent::GetOrCreate(Player);
		AirMoveDataComp = UMedallionPlayerFlyingMovementComponent::GetOrCreate(Owner);
		OtherAirMoveDataComp = UMedallionPlayerFlyingMovementComponent::GetOrCreate(Player.OtherPlayer);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate(FMedallionPlayerGloryKill0SelectHydraData & Params) const
	{
		if (Player.IsZoe()) // only one player decides plz!
			return false;
		if (SanctuaryMedallionHydraDevToggles::Hydra::DisableKillHydra.IsEnabled())
			return false;
		if (RefsComp.Refs == nullptr)
			return false;
		if (GloryKillComp.GloryKillState != EMedallionGloryKillState::None)
			return false;
		if (!MedallionComp.IsMedallionCoopFlying())
			return false;
		if (Player.IsPlayerDead())
			return false;
		if (Player.OtherPlayer.IsPlayerDead())
			return false;

		ASanctuaryBossMedallionHydra HydraToStrangle = TryFindStrangleHydra();
		if (HydraToStrangle == nullptr)
			return false;
		
		Params.SelectedHydra = HydraToStrangle;
		return true;
	}

	ASanctuaryBossMedallionHydra TryFindStrangleHydra() const
	{
		ASanctuaryBossMedallionSpline FlyingSpline = RefsComp.Refs.MedallionBossPlane2D.GetFlyingSpline();
		float32 OurSplineDist = RefsComp.Refs.MedallionBossPlane2D.AccSplineDistance.Value;

		if (SanctuaryMedallionHydraDevToggles::Draw::SelectHydra.IsEnabled())
			Debug::DrawDebugString(RefsComp.Refs.MedallionBossPlane2D.ActorCenterLocation, "Plane Dist: " + OurSplineDist, ColorDebug::Pink);
		
		for (ASanctuaryBossMedallionHydra Hydra : RefsComp.Refs.Hydras)
		{
			if (Hydra.bDead)
				continue;
			if (Hydra.bSubmerged)
				continue;

			// float Diff = (RefsComp.Refs.MedallionBossPlane2D.ActorCenterLocation - Hydra.ActorLocation).Size();
			// if (Diff > RefsComp.Refs.MedallionBossPlane2D.PlaneExtents.X * 3.0) // lodded away lolol
			// 	continue;

			if (SanctuaryMedallionHydraDevToggles::Draw::SelectHydra.IsEnabled())
			{
				float HydraDist = FlyingSpline.Spline.GetClosestSplineDistanceToWorldLocation(Hydra.ActorLocation);
				DebugDrawHydra(Hydra, HydraDist);
			}

			FTransform CutoffBoneTransform = Hydra.GetCutBoneTransform();
			FVector PlaneLocation = RefsComp.Refs.MedallionBossPlane2D.ActorLocation;
			FVector HydraRelativeToPlane = CutoffBoneTransform.Location - PlaneLocation;
			float HydraClosestDistanceToPlane = RefsComp.Refs.MedallionBossPlane2D.ActorForwardVector.DotProduct(HydraRelativeToPlane);

			if (HydraClosestDistanceToPlane > 0.0 && HydraClosestDistanceToPlane < MedallionConstants::SelectHydra::PlaneDistanceStartTryKill && PlayersAreOnEachSideOfHydra(Hydra))
			{
				return Hydra;
			}
		}

		return nullptr;
	}

	bool PlayersAreOnEachSideOfHydra(ASanctuaryBossMedallionHydra Hydra) const
	{
		FTransform CutoffBoneTransform = Hydra.GetCutBoneTransform();
		FVector2D HydraProjectedLocation = RefsComp.Refs.MedallionBossPlane2D.GetLocationOnPlane(CutoffBoneTransform.Location);
		if (SanctuaryMedallionHydraDevToggles::Draw::SelectHydra.IsEnabled())
			Debug::DrawDebugCoordinateSystem(RefsComp.Refs.MedallionBossPlane2D.GetLocationInWorld(HydraProjectedLocation), CutoffBoneTransform.Rotator(), 1000.0, 10.0, 5.0, true);
		bool bSomeoneIsLeft = HydraProjectedLocation.X > AirMoveDataComp.SyncedSideways.Value || HydraProjectedLocation.X > OtherAirMoveDataComp.SyncedSideways.Value;
		bool bSomeoneIsRight = HydraProjectedLocation.X < AirMoveDataComp.SyncedSideways.Value || HydraProjectedLocation.X < OtherAirMoveDataComp.SyncedSideways.Value;			
		return bSomeoneIsLeft && bSomeoneIsRight;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		return true;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FMedallionPlayerGloryKill0SelectHydraData Params)
	{
		if (RefsComp.Refs.StartGloryKillSequence != nullptr)
			RefsComp.Refs.StartGloryKillSequence.SetActorTransform(Params.SelectedHydra.ActorTransform);
		if (RefsComp.Refs.EndGloryKillSequence != nullptr)
			RefsComp.Refs.EndGloryKillSequence.SetActorTransform(Params.SelectedHydra.ActorTransform);

		GloryKillComp.SetGloryKillState(EMedallionGloryKillState::Enter, this);
		OtherGloryKillComp.SetGloryKillState(EMedallionGloryKillState::Enter, this);
		GloryKillComp.AttackedHydra = Params.SelectedHydra;
		OtherGloryKillComp.AttackedHydra = Params.SelectedHydra;
		GloryKillComp.AttackedHydra.bIsStrangleAttacked = true;

		Params.SelectedHydra.AttackedTransformOverride.Add(MedallionConstants::Tags::StrangleBlockRotation);
		Params.SelectedHydra.AttackedTransformStartRotation = Params.SelectedHydra.ActorQuat;
		
		if (RefsComp.Refs.HydraAttackManager.Phase <= EMedallionPhase::Flying1LoopBack)
			RefsComp.Refs.HydraAttackManager.SetPhase(EMedallionPhase::Strangle1Sequence);
		else if (RefsComp.Refs.HydraAttackManager.Phase <= EMedallionPhase::Flying2LoopBack)
			RefsComp.Refs.HydraAttackManager.SetPhase(EMedallionPhase::Strangle2Sequence);
		else
			RefsComp.Refs.HydraAttackManager.SetPhase(EMedallionPhase::Strangle3Sequence);

		FSanctuaryBossHydraPlayerTetherEventParams EventParams;
		EventParams.Hydra = Params.SelectedHydra;
		UMedallionPlayerTetherEventHandler::Trigger_OnStartHydraGloryKill(Hydra::GetAudioTetherPlayerOwner(), EventParams);
	}

	void DebugDrawHydra(ASanctuaryBossMedallionHydra Hydra, float HydraDist) const
	{
		// FTransform TargetTransform = Hydra.GetCutBoneTransform();
		// FVector2D HydraProjectedLocation = RefsComp.Refs.MedallionBossPlane2D.GetLocationOnPlane(TargetTransform.Location);
		// if (Math::Abs(HydraProjectedLocation.X) > RefsComp.Refs.MedallionBossPlane2D.PlaneExtents.X * 1.5)
		// 	return;

		// FTransform PlaceTransform = FlyingSpline.Spline.GetWorldTransformAtSplineDistance(HydraDist + MedallionConstants::SelectHydra::SplineDistanceStartTryKill);
		// Debug::DrawDebugLine(PlaceTransform.Location - FVector::UpVector * 15000, PlaceTransform.Location + FVector::UpVector * 15000, Hydra.DebugColor * 0.5, 30, 0.0, true);

		// FVector HydraWorldLocationOnPlane = RefsComp.Refs.MedallionBossPlane2D.GetLocationSnappedToPlane(TargetTransform.Location);
		// FVector HydraPlaneLocationOnPlace = PlaceTransform.Location + (PlaceTransform.Rotation.RightVector * HydraProjectedLocation.X) + (PlaceTransform.Rotation.UpVector * HydraProjectedLocation.Y);
		// FVector DebugLocationOnOurPlane = HydraWorldLocationOnPlane;

		// FTransform KnockTransform = FlyingSpline.Spline.GetWorldTransformAtSplineDistance(HydraDist - MedallionConstants::Flying::KnockedRangeInFrontOfHydra);
		// FLinearColor Coloring = Hydra.DebugColor;
		// Coloring.A = 0.05;
		// //Debug::DrawDebugSolidPlane(KnockTransform.Location, -KnockTransform.Rotation.ForwardVector, 5000, MedallionConstants::Flying::KnockedRangeSidewaysOfHydra * 2.0, Coloring);
		// //Debug::DrawDebugSolidPlane(KnockTransform.Location, -KnockTransform.Rotation.ForwardVector, 5000, MedallionConstants::Flying::KnockedRangeSidewaysOfHydra * 2.0, Coloring);
		// Debug::DrawDebugString(PlaceTransform.Location, "Hydra: " + Hydra.HydraType);

		// FVector TextLocation = DebugLocationOnOurPlane;
		// TextLocation.Z = Player.ActorLocation.Z;
		// Debug::DrawDebugString(TextLocation, "Hydra " + Hydra.GetName() + "\nx:" + HydraProjectedLocation.X + "\n\ndist: " + HydraDist);

		// float Diff = HydraDist - AirMoveDataComp.CachedOurSplineDist;

		// FVector2f InputRange = FVector2f(float32(MedallionConstants::SelectHydra::SplineDistanceStartTryKill), float32(MedallionConstants::SelectHydra::SplineDistanceEndTryKill));
		// float Alpha = Math::GetMappedRangeValueClamped(InputRange, FVector2f(0.0, 1.0), Diff);
		// FLinearColor FadedColor = FLinearColor::LerpUsingHSV(Hydra.DebugColor * 0.4, Hydra.DebugColor, Alpha);

		// float Dist = HydraPlaneLocationOnPlace.Distance(DebugLocationOnOurPlane);
		// float Steps = Math::TruncFloatDecimals(Dist / 500.0, 0.0);
/*
		for (float iStep = Steps; iStep >= 0; --iStep)
		{
			if (Steps <= KINDA_SMALL_NUMBER)
				break;
			float StepAlpha = iStep / Steps;
			FVector InBetweenLocation = Math::Lerp(HydraPlaneLocationOnPlace, DebugLocationOnOurPlane, StepAlpha);
			float DiffToResolve = HydraPlaneLocationOnPlace.Distance(InBetweenLocation);
			if (DiffToResolve < MedallionConstants::SelectHydra::SplineDistanceStartTryKill)
				FadedColor = Hydra.DebugColor;
			// on future plane
			Debug::DrawDebugLine(InBetweenLocation, InBetweenLocation + FVector::UpVector * 15000, FadedColor, 10, 0.0, true);
		}
*/
		// Debug::DrawDebugLine(DebugLocationOnOurPlane, DebugLocationOnOurPlane + FVector::UpVector * 15000, Hydra.DebugColor, 30, 0.0, true);
		// Debug::DrawDebugLine(DebugLocationOnOurPlane, TargetTransform.Location, Hydra.DebugColor, 30, 0.0, true);
	}

};