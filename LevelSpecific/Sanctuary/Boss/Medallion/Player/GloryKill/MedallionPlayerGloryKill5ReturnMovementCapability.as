struct FMedallionPlayerGloryKill5ReturnMovementData
{
	FVector TargetLocation;
}

class UMedallionPlayerGloryKill5ReturnMovementCapability : UHazePlayerCapability
{
	default NetworkMode = EHazeCapabilityNetworkMode::ImmediateNetFunction;

	default CapabilityTags.Add(MedallionTags::MedallionTag);
	default CapabilityTags.Add(MedallionTags::MedallionGloryKill);
	default TickGroup = EHazeTickGroup::Movement;
	default TickGroupOrder = 60;

	UMedallionPlayerGloryKillComponent GloryKillComp;
	UMedallionPlayerGloryKillComponent OtherPlayerGloryKillComp;
	UMedallionPlayerReferencesComponent RefsComp;

	UMedallionPlayerTetherStarfallTrailComponent TrailComp;
	USanctuaryCompanionMegaCompanionPlayerComponent PlayerMegaCompanionComp;

	UPlayerMovementComponent MoveComp;
	USimpleMovementData MoveData;

	FVector TargetLocation;

	bool bLanding = false;

	FHazeRuntimeSpline MoveSpline;

	FVector ExitTangent;
	FVector EnterTangent;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		GloryKillComp = UMedallionPlayerGloryKillComponent::GetOrCreate(Player);
		OtherPlayerGloryKillComp = UMedallionPlayerGloryKillComponent::GetOrCreate(Player.OtherPlayer);
		RefsComp = UMedallionPlayerReferencesComponent::GetOrCreate(Player);
		MoveComp = UPlayerMovementComponent::GetOrCreate(Owner);
		MoveData = MoveComp.SetupSimpleMovementData();
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate(FMedallionPlayerGloryKill5ReturnMovementData & ActivationParams) const
	{
		if (RefsComp.Refs == nullptr)
			return false;
		if (GloryKillComp.GloryKillState != EMedallionGloryKillState::Return)
			return false;
		if (Player.bIsControlledByCutscene)
			return false;
		if (Player.AttachParentActor != nullptr)
			return false;
		if (RefsComp.Refs.HydraAttackManager.Phase >= EMedallionPhase::GloryKill3)
			return false;

		ActivationParams.TargetLocation = Player.IsMio() ? RefsComp.Refs.GloryKillExitLocationMio.ActorLocation : RefsComp.Refs.GloryKillExitLocationZoe.ActorLocation;
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (Player.bIsControlledByCutscene)
			return true;
		if (bLanding)
			return true;
		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FMedallionPlayerGloryKill5ReturnMovementData ActivationParams)
	{
		if (TrailComp == nullptr)
			TrailComp = UMedallionPlayerTetherStarfallTrailComponent::Get(Player);
		Player.BlockCapabilities(CameraTags::CameraAlignWithWorldUp, this);

		RefsComp.Refs.GloryKillCirclingSpotTemp.SetActorHiddenInGame(true);
		TArray<FVector> Points;
		Points.Add(Player.ActorLocation);
		TargetLocation = ActivationParams.TargetLocation;

		float TangentUpAlpha = Math::GetMappedRangeValueClamped(FVector2D(0.0, 90), FVector2D(0.0, 1.0), MedallionConstants::ReturnAndLand::LandingUpwardsAngle);
		float TangentOutAlpha = Math::GetMappedRangeValueClamped(FVector2D(0.0, 90), FVector2D(0.0, 1.0), MedallionConstants::ReturnAndLand::LandingOutwardsAngle);
		ExitTangent = Math::Lerp((Player.ActorLocation - TargetLocation).GetSafeNormal(), FVector::UpVector, TangentUpAlpha);
		FRotator Rot = FRotator::MakeFromXZ(TargetLocation - Player.ActorLocation, FVector::UpVector);
		FVector OutwardsTangent = Math::Lerp(FVector::ZeroVector, Rot.RightVector, TangentOutAlpha);
		float OutwardsSign = Player.IsMio() ? 1.0 : -1.0;
		ExitTangent += OutwardsTangent * OutwardsSign;
		
		ExitTangent = ExitTangent.GetSafeNormal();
		EnterTangent = Player.ActorForwardVector;

		const float TangentOffsetStrength = 2000;
		Points.Add(Player.ActorLocation + EnterTangent * TangentOffsetStrength);
		Points.Add(TargetLocation + ExitTangent * TangentOffsetStrength);
		Points.Add(TargetLocation);

		TrailComp.Activate(true);
		MoveSpline.SetPoints(Points);

		PlayerMegaCompanionComp = USanctuaryCompanionMegaCompanionPlayerComponent::Get(Player);
		TrailComp.MegaCompanionStartDisintegrating.Broadcast(PlayerMegaCompanionComp.MegaCompanion, Player.IsMio());
		PlayerMegaCompanionComp.MegaCompanion.MegaCompanionStartDisintegrating.Broadcast(PlayerMegaCompanionComp.MegaCompanion, Player.IsMio());
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Player.UnblockCapabilities(CameraTags::CameraAlignWithWorldUp, this);
		bLanding = false;
		GloryKillComp.bTetherToHydra = false;
		GloryKillComp.SetGloryKillState(EMedallionGloryKillState::None, this);
		UMedallionPlayerComponent MedallionComp = UMedallionPlayerComponent::GetOrCreate(Player);
		MedallionComp.StopMedallionFlying();
		TrailComp.Deactivate();
		//Player.SetActorVelocity(FVector());
		
		FVector LandingDirection = Player.ActorForwardVector.VectorPlaneProject(FVector::UpVector);
		FVector LandingVelocity = LandingDirection * MedallionConstants::ReturnAndLand::LandingImpulseStrength;

		Player.ForceHighSpeedLanding(LandingVelocity, 0.0);

		if (Player.IsMio())
		{
			if (RefsComp.Refs.HydraAttackManager.Phase <= EMedallionPhase::FlyingExitReturn1)
				RefsComp.Refs.HydraAttackManager.SetPhase(EMedallionPhase::Sidescroller2);
			else if (RefsComp.Refs.HydraAttackManager.Phase <= EMedallionPhase::FlyingExitReturn2)
				RefsComp.Refs.HydraAttackManager.SetPhase(EMedallionPhase::Sidescroller3);
		}

		PlayerMegaCompanionComp = USanctuaryCompanionMegaCompanionPlayerComponent::Get(Player);
		TrailComp.MegaCompanionFinishedDisintegrating.Broadcast(PlayerMegaCompanionComp.MegaCompanion, Player.IsMio());
		PlayerMegaCompanionComp.MegaCompanion.MegaCompanionFinishedDisintegrating.Broadcast(PlayerMegaCompanionComp.MegaCompanion, Player.IsMio());
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if (Player.bIsControlledByCutscene)
			return;

		FVector DesiredDelta;
		FRotator DesiredRotation = Player.ActorRotation;
		if (HasControl())
		{
			float Alpha = Math::Saturate(ActiveDuration / MedallionConstants::ReturnAndLand::ReturnDuration);
			Alpha = Math::EaseOut(0.0, 1.0, Alpha, 1.0);
			FVector NewLocation;
			FVector Direction;
			MoveSpline.GetLocationAndDirectionAtDistance(Alpha * MoveSpline.Length, NewLocation, Direction);
			if (SanctuaryMedallionHydraDevToggles::Draw::Spline.IsEnabled())
				MoveSpline.DrawDebugSpline();

			FVector Delta = NewLocation - Player.ActorLocation;
			DesiredDelta = Delta;
			if (Delta.Size() > SMALL_NUMBER)
				DesiredRotation = FRotator::MakeFromXZ(Delta.GetSafeNormal(), FVector::UpVector);

			if (Player.ActorLocation.Equals(TargetLocation, 50.0))
				bLanding = true;
		}

		if (!MoveComp.PrepareMove(MoveData, DesiredRotation.UpVector))
			return;

		if (HasControl())
		{
			MoveData.AddDelta(DesiredDelta);
			MoveData.SetRotation(DesiredRotation);
		}
		else
		{
			MoveData.ApplyCrumbSyncedAirMovement();
		}
		MoveComp.ApplyMove(MoveData);
	}
};