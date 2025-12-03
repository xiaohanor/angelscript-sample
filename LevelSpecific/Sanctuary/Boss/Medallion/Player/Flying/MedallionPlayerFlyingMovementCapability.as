struct FSanctuaryMedallionMovementPlayerActivationParams
{
	FVector StartRelativeLocation;
}

class UMedallionPlayerFlyingMovementCapability : UHazePlayerCapability
{
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	FSanctuaryMedallionMovementPlayerActivationParams ActivationParams;

	default CapabilityTags.Add(MedallionTags::MedallionTag);
	default CapabilityTags.Add(MedallionTags::MedallionCoopFlyingActive);
	default CapabilityTags.Add(MedallionTags::MedallionCoopFlying);
	default CapabilityTags.Add(CapabilityTags::Movement);

	default TickGroup = EHazeTickGroup::Movement;
	default TickGroupOrder = 70;
	UMedallionPlayerFlyingInputComponent IntputComp;

	UPlayerMovementComponent MoveComp;
	USimpleMovementData MoveData;
	UMedallionPlayerFlyingMovementComponent AirMoveDataComp;
	UMedallionPlayerFlyingMovementComponent OtherAirMoveDataComp;
	UMedallionPlayerComponent MedallionComp;
	UMedallionPlayerReferencesComponent RefsComp;
	UMedallionPlayerGloryKillComponent GloryKillComp;

	float LastUpwards = 0.0;
	float LastForwards = 0.0;
	FStickSnapbackDetector SnapbackDetector;

	FHazeAcceleratedVector2D AccLocation;

	FVector2D RelativeMovementLocation;

	FHazeAcceleratedFloat AccVisualHorizontal;
	FHazeAcceleratedFloat AccVisualVertical;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		GloryKillComp = UMedallionPlayerGloryKillComponent::GetOrCreate(Player);
		AirMoveDataComp = UMedallionPlayerFlyingMovementComponent::GetOrCreate(Owner);
		OtherAirMoveDataComp = UMedallionPlayerFlyingMovementComponent::GetOrCreate(Player.OtherPlayer);
		MedallionComp = UMedallionPlayerComponent::GetOrCreate(Owner);
		MoveComp = UPlayerMovementComponent::GetOrCreate(Owner);
		MoveData = MoveComp.SetupSimpleMovementData();
		IntputComp = UMedallionPlayerFlyingInputComponent::GetOrCreate(Owner);
		RefsComp = UMedallionPlayerReferencesComponent::GetOrCreate(Player);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate(FSanctuaryMedallionMovementPlayerActivationParams& OutParams) const
	{
		if (RefsComp.Refs == nullptr)
			return false;
		if (!MedallionComp.IsMedallionCoopFlying())
			return false;
		if (GloryKillComp.GloryKillState != EMedallionGloryKillState::None)
			return false;
		FVector StartTarget = FVector();
		if (DeactiveDuration > 1.0)
			StartTarget = RefsComp.Refs.MedallionBossPlane2D.GetLocationInWorld(Player.IsMio() ? MedallionConstants::Flying::MioStartFlyingOffset : MedallionConstants::Flying::ZoeStartFlyingOffset);

		OutParams.StartRelativeLocation = Player.ActorLocation - StartTarget;
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (Player.IsPlayerDead())
			return true;
		if (!MedallionComp.IsMedallionCoopFlying())
			return true;
		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FSanctuaryMedallionMovementPlayerActivationParams Params)
	{
		ActivationParams = Params;
		// RelativeMovementLocation.X = Math::Clamp(Params.TargetRelativeLocation.X, -RefsComp.Refs.MedallionBossPlane2D.PlaneExtents.X, RefsComp.Refs.MedallionBossPlane2D.PlaneExtents.X);
		// RelativeMovementLocation.Y = Math::Clamp(Params.TargetRelativeLocation.Y, -RefsComp.Refs.MedallionBossPlane2D.PlaneExtents.Y, RefsComp.Refs.MedallionBossPlane2D.PlaneExtents.Y);
		// RelativeMovementLocation.Y += Player.IsMio() ? MedallionConstants::Player::MioVerticalEnterOffset : 0.0;

		RelativeMovementLocation = Player.IsMio() ? MedallionConstants::Flying::MioStartFlyingOffset : MedallionConstants::Flying::ZoeStartFlyingOffset;

		AccLocation.SnapTo(RelativeMovementLocation);
		AirMoveDataComp.SyncedSideways.SetValue(AccLocation.Value.X);
		AirMoveDataComp.SyncedUpwards.SetValue(AccLocation.Value.Y);

		Player.BlockCapabilities(PlayerMovementTags::Grapple, this);
		Player.BlockCapabilities(PlayerMovementTags::Swing, this);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		SnapbackDetector.ClearSnapbackDetection();
		Player.StopSlotAnimation();
		Player.UnblockCapabilities(PlayerMovementTags::Grapple, this);
		Player.UnblockCapabilities(PlayerMovementTags::Swing, this);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		float BarrelRollSign = AirMoveDataComp.bBarrelRollClockwise ? 1.0 : -1.0 ;
		if (HasControl())
		{
			const FVector2D RawStick = IntputComp.Input; //GetAttributeVector2D(AttributeVectorNames::MovementRaw);;//
			const FVector StickInput(RawStick.X, RawStick.Y, 0);
			FVector NoSnapInput = SnapbackDetector.RemoveStickSnapbackJitter(StickInput, StickInput);

			float UpMoveSpeed = NoSnapInput.X * MedallionConstants::Flying::MoveSpeedVertical;
			float SidewaysMoveSpeed = NoSnapInput.Y * MedallionConstants::Flying::MoveSpeedHorizontal;

			FVector2D ToOtherPlayer = FVector2D(OtherAirMoveDataComp.SyncedSideways.Value, OtherAirMoveDataComp.SyncedUpwards.Value) - FVector2D(AirMoveDataComp.SyncedSideways.Value, AirMoveDataComp.SyncedUpwards.Value);
			float DistanceBetweenPlayers2D = ToOtherPlayer.Size();
			float RubberbandToOtherPlayerAlpha = Math::GetMappedRangeValueClamped(FVector2D(MedallionConstants::Flying::RubberbandPlayersMinDistance, MedallionConstants::Flying::RubberbandPlayersMaxDistance), FVector2D(0.0, 1.0), DistanceBetweenPlayers2D);

			if (RubberbandToOtherPlayerAlpha < KINDA_SMALL_NUMBER && AirMoveDataComp.AccDashAlpha.Value > KINDA_SMALL_NUMBER && NoSnapInput.Size() > KINDA_SMALL_NUMBER)
			{
				UpMoveSpeed = UpMoveSpeed * 0.5 + Math::Sign(NoSnapInput.X) * MedallionConstants::Flying::DashExtraSpeedVertical;
				SidewaysMoveSpeed = SidewaysMoveSpeed * 0.5 + -BarrelRollSign * MedallionConstants::Flying::DashExtraSpeedHorizontal;
			}
			
			if (AirMoveDataComp.AccKnockedAlpha.Value > KINDA_SMALL_NUMBER)
			{
				UpMoveSpeed = UpMoveSpeed * 0.1;
				SidewaysMoveSpeed = SidewaysMoveSpeed * 0.1 + AirMoveDataComp.KnockedDirectionSign * MedallionConstants::Flying::KnockedSpeed;
			}

			float SidewaysCurrentAlpha = GetSidewaysCurrentAlpha();
			SidewaysMoveSpeed += SidewaysCurrentAlpha * MedallionConstants::Flying::MoveSpeedHorizontal * (RelativeMovementLocation.X > 0.0 ? -1.0 : 1.0);;

			float UpCurrentAlpha = GetUpCurrentAlpha();
			UpMoveSpeed += UpCurrentAlpha * MedallionConstants::Flying::MoveSpeedVertical * (RelativeMovementLocation.Y > 0.0 ? -1.0 : 1.0);

			FVector2D ToOtherPlayerDirection = ToOtherPlayer.GetSafeNormal();
			SidewaysMoveSpeed += ToOtherPlayerDirection.X * RubberbandToOtherPlayerAlpha * MedallionConstants::Flying::RubberbandMaxForce;
			UpMoveSpeed += ToOtherPlayerDirection.Y * RubberbandToOtherPlayerAlpha * MedallionConstants::Flying::RubberbandMaxForce;

			float FFStrength = Math::Saturate(SidewaysCurrentAlpha + UpCurrentAlpha + RubberbandToOtherPlayerAlpha) * 0.5;
			FHazeFrameForceFeedback FF;
			FF.LeftMotor = FFStrength;
			FF.RightMotor = FFStrength;
			FF.LeftTrigger = FFStrength;
			FF.RightTrigger = FFStrength;

			Player.SetFrameForceFeedback(FF);

			FVector2D RawMoveSpeed = FVector2D(SidewaysMoveSpeed, UpMoveSpeed);
			RelativeMovementLocation += RawMoveSpeed * DeltaTime;
			RelativeMovementLocation.X = Math::Clamp(RelativeMovementLocation.X, -RefsComp.Refs.MedallionBossPlane2D.PlaneExtents.X, RefsComp.Refs.MedallionBossPlane2D.PlaneExtents.X);
			RelativeMovementLocation.Y = Math::Clamp(RelativeMovementLocation.Y, -RefsComp.Refs.MedallionBossPlane2D.PlaneExtents.Y, RefsComp.Refs.MedallionBossPlane2D.PlaneExtents.Y);

			AccLocation.AccelerateTo(RelativeMovementLocation, 1.0, DeltaTime);

			AirMoveDataComp.SyncedSideways.SetValue(AccLocation.Value.X);
			AirMoveDataComp.SyncedUpwards.SetValue(AccLocation.Value.Y);
		}

		FVector WorldLocation = RefsComp.Refs.MedallionBossPlane2D.GetLocationInWorld(FVector2D(AirMoveDataComp.SyncedSideways.Value, AirMoveDataComp.SyncedUpwards.Value));
		float StartOffsetAlpha = Math::Saturate(ActiveDuration / MedallionConstants::Flying::LerpDurationFlyingOffset);
		FVector StartOffsetToRemove = Math::Lerp(ActivationParams.StartRelativeLocation, FVector(), StartOffsetAlpha);
		WorldLocation += StartOffsetToRemove;

		FRotator PlayerRotation = FRotator::MakeFromXZ(RefsComp.Refs.MedallionBossPlane2D.ActorForwardVector, RefsComp.Refs.MedallionBossPlane2D.ActorUpVector);
		
		float InverseBarrelRollAlpha = Math::Saturate(1.0 - AirMoveDataComp.BarrelRollAlpha);
		PlayerRotation.Roll += BarrelRollSign * 360.0 * SanctuaryMedallionBarrelrollCurve.GetFloatValue(InverseBarrelRollAlpha);

		float InverseKnockedPitchAlpha = Math::Saturate(1.0 - AirMoveDataComp.KnockRotationAlpha);
		PlayerRotation.Pitch -= 360.0 * SanctuaryMedallionKnockedPitchCurve.GetFloatValue(InverseKnockedPitchAlpha);

		FVector KnockIntoScreenOffset = RefsComp.Refs.MedallionBossPlane2D.ActorForwardVector * AirMoveDataComp.AccKnockedIntoScreen.Value;
		WorldLocation += KnockIntoScreenOffset;

		if (!MoveComp.PrepareMove(MoveData, PlayerRotation.UpVector))
			return;
	
		FVector Delta = WorldLocation - Player.ActorLocation;
		MoveData.AddDelta(Delta);
		MoveData.SetRotation(PlayerRotation);
		MoveComp.ApplyMove(MoveData);
		
		if (SanctuaryMedallionHydraDevToggles::Draw::Players.IsEnabled())
		{
			const float PlaneLength = 320.0;
			// Debug::DrawDebugBox(WorldLocation - PlayerRotation.ForwardVector * 40.0, FVector(PlaneLength, 90.0, 70.0) * 1.1, PlayerRotation, Player.GetPlayerUIColor(), 10.0, 0.0, true);
			// Debug::DrawDebugBox(WorldLocation - PlayerRotation.ForwardVector * PlaneLength, FVector(30.0, 20.0, 130.0) * 1.1, PlayerRotation, Player.GetPlayerUIColor(), 30.0, 0.0, true);
			Debug::DrawDebugBox(WorldLocation, FVector(50.0, 70.0, 20.0), PlayerRotation, Player.GetPlayerUIColor(), 30.0, 0.0, true);
		}
	}

	float GetSidewaysCurrentAlpha()
	{
		float NegativeSidewaysDistToEdge = Math::Abs(RelativeMovementLocation.X) - RefsComp.Refs.MedallionBossPlane2D.PlaneExtents.X;					
		float SidewaysCurrentProgress = Math::Clamp(NegativeSidewaysDistToEdge + MedallionConstants::Flying::HorizontalCurrentDistance, 0.0, MedallionConstants::Flying::HorizontalCurrentDistance);
		return SidewaysCurrentProgress / MedallionConstants::Flying::HorizontalCurrentDistance;
	}

	float GetUpCurrentAlpha()
	{
		float NegativeUpDistToEdge = Math::Abs(RelativeMovementLocation.Y) - RefsComp.Refs.MedallionBossPlane2D.PlaneExtents.Y;
		float UpCurrentProgress = Math::Clamp(NegativeUpDistToEdge + MedallionConstants::Flying::VerticalCurrentDistance, 0.0, MedallionConstants::Flying::VerticalCurrentDistance);
		return UpCurrentProgress / MedallionConstants::Flying::VerticalCurrentDistance;
	}
};