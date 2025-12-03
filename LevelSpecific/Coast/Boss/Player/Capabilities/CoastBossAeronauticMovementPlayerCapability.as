struct FCoastBossAeronauticMovementPlayerActivationParams
{
	FVector2D StartRelativeLocation;
}

class UCoastBossAeronauticMovementPlayerCapability : UHazePlayerCapability
{
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	default CapabilityTags.Add(CapabilityTags::Movement);
	default CapabilityTags.Add(CoastBossTags::CoastBossTag);
	default TickGroup = EHazeTickGroup::Movement;
	ACoastBossActorReferences References;

	UPlayerMovementComponent MoveComp;
	USimpleMovementData MoveData;
	UCoastBossAeronauticComponent AirMoveDataComp;
	FStickSnapbackDetector SnapbackDetector;

	FHazeAcceleratedVector2D AccLocation;

	FVector2D RelativeMovementLocation;

	FHazeAcceleratedFloat AccPitch;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		TListedActors<ACoastBossActorReferences> LevelReferencesActor;
		References = LevelReferencesActor.Single;
		AirMoveDataComp = UCoastBossAeronauticComponent::GetOrCreate(Owner);
		MoveComp = UPlayerMovementComponent::GetOrCreate(Owner);
		MoveData = MoveComp.SetupSimpleMovementData();
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate(FCoastBossAeronauticMovementPlayerActivationParams& OutParams) const
	{
		if (References == nullptr)
			return false;
		if (!AirMoveDataComp.bAttached)
			return false;
		if (AirMoveDataComp.bShouldPlayerEnter)
			return false;

		if (References.PlaneRespawnPoint != nullptr)
			OutParams.StartRelativeLocation = References.CoastBossPlane2D.GetLocationOnPlane(References.PlaneRespawnPoint.ActorLocation);
		else
			OutParams.StartRelativeLocation = FVector2D();

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (References == nullptr)
			return true;
		if (!AirMoveDataComp.bAttached)
			return true;
		if (Player.IsPlayerDead())
			return true;
		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCoastBossAeronauticMovementPlayerActivationParams Params)
	{
		MoveComp.ActiveConstrainRotationToHorizontalPlane.Apply(false, this);
		MoveComp.ApplyCrumbSyncedRelativePosition(this, References.CoastBossPlane2D.Root);
		RelativeMovementLocation.X = Math::Clamp(Params.StartRelativeLocation.X, -References.CoastBossPlane2D.PlaneExtents.X, References.CoastBossPlane2D.PlaneExtents.X);
		RelativeMovementLocation.Y = Math::Clamp(Params.StartRelativeLocation.Y, -References.CoastBossPlane2D.PlaneExtents.Y, References.CoastBossPlane2D.PlaneExtents.Y);
		RelativeMovementLocation.Y += Player.IsMio() ? CoastBossConstants::Player::MioVerticalEnterOffset : 0.0;

		AccLocation.SnapTo(RelativeMovementLocation);
		AirMoveDataComp.Forwards = AccLocation.Value.X;
		AirMoveDataComp.Upwards = AccLocation.Value.Y;

		FHazePlaySlotAnimationParams AnimParams;

		if(Player.IsMio())
		{
			AnimParams.Animation = AirMoveDataComp.RideDroneAnimation;
		}
		else
		{
			AnimParams.Animation = AirMoveDataComp.ZoeRideDroneAnimation;
		}

		AnimParams.bLoop = true;
		Player.PlaySlotAnimation(AnimParams);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		MoveComp.ActiveConstrainRotationToHorizontalPlane.Clear(this);
		MoveComp.ClearCrumbSyncedRelativePosition(this);
		SnapbackDetector.ClearSnapbackDetection();
		Player.StopSlotAnimation();
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if (MoveComp.PrepareMove(MoveData))
		{
			if(HasControl())
			{
				FVector2D RawStick = GetAttributeVector2D(AttributeVectorNames::MovementRaw);
				if(References.Boss.bDead)
					RawStick = FVector2D::ZeroVector;

				const FVector StickInput(RawStick.X, RawStick.Y, 0);
				FVector NoSnapInput = SnapbackDetector.RemoveStickSnapbackJitter(StickInput, StickInput);

				float SpeedDashMultiplier = 1.0 + CoastBossConstants::Player::DashAddedMoveMultiplier * AirMoveDataComp.AccDashAlpha.Value;
				float UpMove = NoSnapInput.X * CoastBossConstants::Player::MoveSpeedVertical * SpeedDashMultiplier;
				float ForwardMove = NoSnapInput.Y * CoastBossConstants::Player::MoveSpeedHorizontal * SpeedDashMultiplier;

				FVector2D RawMove = FVector2D(ForwardMove, UpMove);
				RelativeMovementLocation += RawMove * DeltaTime;
				RelativeMovementLocation.X = Math::Clamp(RelativeMovementLocation.X, -References.CoastBossPlane2D.PlaneExtents.X, References.CoastBossPlane2D.PlaneExtents.X);
				RelativeMovementLocation.Y = Math::Clamp(RelativeMovementLocation.Y, -References.CoastBossPlane2D.PlaneExtents.Y, References.CoastBossPlane2D.PlaneExtents.Y);

				float SinValue = Time::GetGameTimeSeconds() * 4;
				if(Player.IsMio())
				{
					SinValue += 1;
				}


				float SinOffset = Math::Sin(SinValue) * 36;
				float SinAlpha = Math::Saturate(ActiveDuration / 1.0);
				SinAlpha = Math::EaseInOut(0.0, 1.0, SinAlpha, 2.0);
				SinOffset = Math::Lerp(0.0, SinOffset, SinAlpha);

				AccLocation.AccelerateTo(RelativeMovementLocation + FVector2D(0, 1) * SinOffset, 0.1, DeltaTime);

				AirMoveDataComp.Forwards = AccLocation.Value.X;
				AirMoveDataComp.Upwards = AccLocation.Value.Y;

				FVector WorldLocation = References.CoastBossPlane2D.GetLocationInWorld(FVector2D(AirMoveDataComp.Forwards, AirMoveDataComp.Upwards));
				FRotator PlayerRotation = FRotator::MakeFromXZ(References.CoastBossPlane2D.ActorRightVector, References.CoastBossPlane2D.ActorUpVector);

				float VerticalMultiplier = NoSnapInput.X;
				float HorizontalMultiplier = -Math::Clamp(NoSnapInput.Y, -1.0, 0.0);
				float CombinedMultiplier = Math::Clamp(VerticalMultiplier + HorizontalMultiplier, -1.0, 1.0);

				float TargetPitch = CombinedMultiplier * CoastBossConstants::Player::ShipTiltDegrees;
				// if(TargetPitch > KINDA_SMALL_NUMBER)
				// {
				// 	TargetPitch = CoastBossConstants::Player::ShipTiltDegrees * NoSnapInput.Size();
				// }
				// else if(TargetPitch < -KINDA_SMALL_NUMBER)
				// {
				// 	TargetPitch = -CoastBossConstants::Player::ShipTiltDegrees * NoSnapInput.Size();
				// }

				AccPitch.AccelerateTo(TargetPitch, 0.5, DeltaTime);
				PlayerRotation.Pitch += AccPitch.Value;
			
				FVector Delta = WorldLocation - Player.ActorLocation;
				MoveData.AddDelta(Delta);
				MoveData.SetRotation(PlayerRotation);
			}
			else
			{
				MoveData.ApplyCrumbSyncedAirMovement();
			}

			MoveComp.ApplyMove(MoveData);
		}

		if (CoastBossDevToggles::Draw::DrawDebugPlayers.IsEnabled())
		{
			const float PlaneLength = 320.0;
			Debug::DrawDebugBox(Player.ActorLocation - Player.ActorRotation.ForwardVector * 40.0, FVector(PlaneLength, 90.0, 70.0) * 1.1, Player.ActorRotation, Player.GetPlayerUIColor(), 10.0, 0.0, true);
			Debug::DrawDebugBox(Player.ActorLocation - Player.ActorRotation.ForwardVector * PlaneLength, FVector(30.0, 20.0, 130.0) * 1.1, Player.ActorRotation, Player.GetPlayerUIColor(), 30.0, 0.0, true);
			Debug::DrawDebugBox(Player.ActorLocation, FVector(50.0, 270.0, 20.0), Player.ActorRotation, Player.GetPlayerUIColor(), 30.0, 0.0, true);
		}
	}
}