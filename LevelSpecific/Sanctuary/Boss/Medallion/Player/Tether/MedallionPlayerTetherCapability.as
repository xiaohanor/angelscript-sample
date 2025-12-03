class UMedallionPlayerTetherCapability : UHazePlayerCapability
{
	default CapabilityTags.Add(MedallionTags::MedallionTag);
	default CapabilityTags.Add(MedallionTags::MedallionCoopFlying);
	default TickGroup = EHazeTickGroup::AfterGameplay;
	AHazePlayerCharacter OtherPlayer;

	UMedallionPlayerTetherComponent TetherComp;
	UMedallionPlayerGloryKillComponent GloryKillComp;
	UMedallionPlayerReferencesComponent RefsComp;
	UMedallionPlayerComponent MedallionComp;
	USanctuaryCompanionMegaCompanionPlayerComponent CompanionComp;
	USanctuaryCompanionMegaCompanionPlayerComponent OtherCompanionComp;

	FHazeAcceleratedFloat AccOpacity;

	// BP_GetMegaCompanion

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		OtherPlayer = Player.OtherPlayer;
		GloryKillComp = UMedallionPlayerGloryKillComponent::GetOrCreate(Player);
		RefsComp = UMedallionPlayerReferencesComponent::GetOrCreate(Player);
		MedallionComp = UMedallionPlayerComponent::GetOrCreate(Player);
		CompanionComp = USanctuaryCompanionMegaCompanionPlayerComponent::Get(Player);
	}

	private void CreateTetherComp()
	{
		UMedallionPlayerAssetsComponent AssetComp = UMedallionPlayerAssetsComponent::Get(Player);
		TetherComp = Cast<UMedallionPlayerTetherComponent>(Player.CreateComponent(AssetComp.TetherVFXCompClass));
		if (AssetComp != nullptr)
		{
			if (Player == Game::Mio)
				TetherComp.SetAsset(AssetComp.MioTetherVFX);
			else
				TetherComp.SetAsset(AssetComp.ZoeTetherVFX);
			TetherComp.SetNiagaraVariableFloat("OPACITY_GlobalFade", 0.0);
			TetherComp.Deactivate();
		}

		Player.CreateComponent(AssetComp.TrailStarfallVFXCompClass);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (RefsComp.Refs == nullptr)
			return false;
		if (!ShouldBeVisible())
			return false;
		return true;
	}

	bool ShouldBeVisible() const
	{
		if (!CompanionComp.MegaCompanion.bIsControlledByCutscene && !MedallionComp.IsMedallionCoopFlying())
			return false;
		if (GloryKillComp.GloryKillState == EMedallionGloryKillState::ExecuteSequence)
			return false;
		if (GloryKillComp.GloryKillState == EMedallionGloryKillState::Return)
			return false;
		if (!MedallionComp.bCutsceneAllowShowTether)
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (AccOpacity.Value > KINDA_SMALL_NUMBER)
			return false;
		if (!ShouldBeVisible())
			return true;
		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		if (TetherComp == nullptr)
			CreateTetherComp();
		OtherCompanionComp = USanctuaryCompanionMegaCompanionPlayerComponent::Get(Player.OtherPlayer);
		AccOpacity.SnapTo(0.0);
		TetherComp.AttachToComponent(CompanionComp.MegaCompanion.SkeletalMesh, n"Hips");
		TetherComp.SetNiagaraVariableFloat("OPACITY_GlobalFade", 0.0);
		TetherComp.Activate();
		
		if(Player == Hydra::GetAudioTetherPlayerOwner())
			UMedallionPlayerTetherEventHandler::Trigger_OnTetherActivated(Player);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		TetherComp.Deactivate();
		MedallionComp.bCutsceneAllowShowTether = false;

		if(Player == Hydra::GetAudioTetherPlayerOwner())
			UMedallionPlayerTetherEventHandler::Trigger_OnTetherDeactivated(Player);

		AccOpacity.SnapTo(0.0);
		TetherComp.SetNiagaraVariableFloat("OPACITY_GlobalFade", 0.0);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		bool bShouldBeVisible = ShouldBeVisible() && !Player.IsPlayerDead() && !Player.OtherPlayer.IsPlayerDead();
		float FadeDuration = bShouldBeVisible ? 20 : 0.2;
		AccOpacity.AccelerateToWithStop(bShouldBeVisible ? 1.0 : 0.0, FadeDuration, DeltaTime, 0.01);

		{
			TetherComp.SetNiagaraVariableFloat("OPACITY_GlobalFade", AccOpacity.Value);
		}

		{
			FVector ToOtherPlayer = Player.OtherPlayer.MeshOffsetComponent.WorldLocation - Player.MeshOffsetComponent.WorldLocation;
			FVector EndPoint = Player.MeshOffsetComponent.WorldLocation + ToOtherPlayer * 1;
			FVector StartPoint = Player.MeshOffsetComponent.WorldLocation;

			bool bAttachToOtherCompanion = GloryKillComp.GloryKillState == EMedallionGloryKillState::None || GloryKillComp.GloryKillState >= EMedallionGloryKillState::ExecuteSequence;
			if (bAttachToOtherCompanion)
				EndPoint = GetBeamOtherCompanionPoint();
			else if (GloryKillComp.bTetherToHydra)
				EndPoint = GetAttachmentLocationOnHelix();

			if (Player.bIsControlledByCutscene)
				StartPoint = GetBeamCompanionPoint();

			FVector UILocation = Math::Lerp(StartPoint, EndPoint, 0.25);
			if (SanctuaryMedallionHydraDevToggles::Draw::Tether.IsEnabled())
			{
				Debug::DrawDebugSphere(EndPoint, 20, 12, Player.GetPlayerUIColor(), 10, bDrawInForeground = true);
				Debug::DrawDebugLine(StartPoint, EndPoint, Player.GetPlayerUIColor(), 10, bDrawInForeground = true);
				Debug::DrawDebugSphere(UILocation, 100, 12, Player.GetPlayerUIColor(), 10, bDrawInForeground = true);
				Debug::DrawDebugString(UILocation, "Opacity " + AccOpacity.Value);
			}

			if (Player.IsMio())
				RefsComp.Refs.GloryKillCirclingSpotTemp.MioUIAttachComp.SetWorldLocation(UILocation);
			else
				RefsComp.Refs.GloryKillCirclingSpotTemp.ZoeUIAttachComp.SetWorldLocation(UILocation);
			
			if (StartPoint.Distance(EndPoint) > KINDA_SMALL_NUMBER)
			{
				TetherComp.SetVectorParameter(n"BeamStart", StartPoint);
				TetherComp.SetVectorParameter(n"BeamEnd", EndPoint);
			}
		}
	}

	FVector GetBeamCompanionPoint()
	{
		return CompanionComp.MegaCompanion.SkeletalMesh.GetSocketLocation(n"Hips");
	}

	FVector GetBeamOtherCompanionPoint()
	{
		return OtherCompanionComp.MegaCompanion.SkeletalMesh.GetSocketLocation(n"Hips");
	}

	FVector GetAttachmentLocationOnHelix()
	{
		FVector WorldLocation = GetBeamCompanionPoint();
		bool bClockwise = Player.IsMio();

		AMedallionPlayerStranglingTetherDonut Helix = RefsComp.Refs.GloryKillCirclingSpotTemp;

		FVector ClosestOnPlane = Math::LinePlaneIntersection(WorldLocation + FVector::UpVector * 10000, WorldLocation - FVector::UpVector * 10000, Helix.ActorCenterLocation, Helix.ActorUpVector);
		FVector Direction = ClosestOnPlane - Helix.ActorCenterLocation;

		FRotator RotatationTowardsPlayer = FRotator::MakeFromZX(Helix.ActorUpVector, Direction);
		// start at center and then move 90 degrees outwards, to give a visual strangling effect
		//FVector ToPlayerAttachDirection = FQuat::MakeFromXZ(bClockwise ? -RotatationTowardsPlayer.RightVector : RotatationTowardsPlayer.RightVector, Helix.ActorUpVector).ForwardVector;

		const float Radius = Helix.GetRadius();

		if (SanctuaryMedallionHydraDevToggles::Draw::HelixDonut.IsEnabled())
		{
			Debug::DrawDebugLine(Helix.ActorLocation, Helix.ActorLocation - Helix.ActorForwardVector * Radius, ColorDebug::Lavender, 10, bDrawInForeground = true);
			Debug::DrawDebugLine(Helix.ActorLocation, Helix.ActorLocation + RotatationTowardsPlayer.ForwardVector * Radius, Player.GetPlayerUIColor(), 10, bDrawInForeground = true);
		}

		FVector HydraBellyForward = -Helix.ActorForwardVector; // the bone is pointing towards the hydra back
		FVector ToPlayerDirection = RotatationTowardsPlayer.ForwardVector;

		const bool bOnRightSide = Helix.ActorRightVector.DotProduct(ToPlayerDirection) > 0;
		const bool bOnSecondHalf = (bOnRightSide && bClockwise) || (!bOnRightSide && !bClockwise);
		float CurrentLapDegrees = Math::RadiansToDegrees(HydraBellyForward.AngularDistance(ToPlayerDirection));

		// only update in strangle seq
		if (Player.bIsControlledByCutscene)
		{
			if (bOnSecondHalf)
				CurrentLapDegrees = 360.0 - CurrentLapDegrees;

			bool bFirstFrame = Helix.PlayerLaps[Player] == 0 && Math::IsNearlyEqual(Helix.PlayerLoopDegrees[Player], 0.0, 1.0);
			bool bLapped = !bFirstFrame && !Math::IsNearlyEqual(Helix.PlayerLoopDegrees[Player], CurrentLapDegrees, 270.0) && CurrentLapDegrees < Helix.PlayerLoopDegrees[Player];
			if (bLapped)
			{
				RefsComp.Refs.GloryKillCirclingSpotTemp.PlayerLaps[Player]++;
				RefsComp.Refs.GloryKillCirclingSpotTemp.PlayerLoopDegrees[Player] = CurrentLapDegrees;
			}
			else
			{
				RefsComp.Refs.GloryKillCirclingSpotTemp.PlayerLoopDegrees[Player] = Math::Max(Helix.PlayerLoopDegrees[Player], CurrentLapDegrees); // don't allow to go backwards
			}
		}

		if (SanctuaryMedallionHydraDevToggles::Draw::HelixDonut.IsEnabled())
		{
			Debug::DrawDebugString(Player.ActorLocation, "SECOND: " + bOnSecondHalf, Color = Player.GetPlayerUIColor(), Scale = 3.0);
			Debug::DrawDebugString(Player.ActorLocation, "\n\nLAPS: " + Helix.PlayerLaps[Player], Scale = 3.0);
			Debug::DrawDebugString(Player.ActorLocation, "\n\n\n\nDEG : " + CurrentLapDegrees, Scale = 3.0);
		}

		const float AngleDegrees = Math::Wrap(Helix.GetTotalDegreesForPlayerWithOffset(Player), 0.0, 360.0);
		const float AngleRadians = bClockwise ? Math::DegreesToRadians(AngleDegrees) : -Math::DegreesToRadians(AngleDegrees);
		FQuat RelativeRotation = FQuat(FVector::UpVector, AngleRadians);
		FQuat WorldRotation = FQuat::MakeFromZX(Helix.ActorUpVector, HydraBellyForward);
		FQuat AttachDirection = FQuat::ApplyRelative(WorldRotation, RelativeRotation);
		FVector CoilXYOffset = AttachDirection.ForwardVector * Radius;

		// coiling height offset
		float NumPlayerCoilsMultiplier = Helix.GetTotalDegreesForPlayerWithOffset(Player) / 360.0;
		float HeightOffset = NumPlayerCoilsMultiplier * Helix.HelixSpiralHeightBetweenCoils;
		float HeightOffsetMultiplier = bClockwise ? HeightOffset * -1.0 : HeightOffset;
		FVector CoilHeightOffset = Helix.ActorUpVector * HeightOffsetMultiplier;

		if (SanctuaryMedallionHydraDevToggles::Draw::HelixDonut.IsEnabled())
		{
			//Debug::DrawDebugString(Player.ActorLocation, "\n\n\n\n\n\nTot : " + AngleDegrees, Color = Player.GetPlayerUIColor(), Scale = 3.0);
			Debug::DrawDebugLine(Helix.ActorLocation, Helix.ActorLocation + Helix.ActorUpVector * Radius, ColorDebug::Blue, 10, bDrawInForeground = true);
			Debug::DrawDebugLine(Helix.ActorLocation, Helix.ActorLocation + CoilXYOffset, Player.GetPlayerUIColor() * 0.5, 10, bDrawInForeground = true);
			Debug::DrawDebugPlane(Helix.ActorLocation, Helix.ActorUpVector, Radius, Radius);
			Debug::DrawDebugSphere(Helix.ActorLocation + CoilXYOffset, 50, LineColor = Player.GetPlayerUIColor(), bDrawInForeground = true);
			Debug::DrawDebugString(Player.ActorLocation, "\n\n\n\n\n\nHeight : " + NumPlayerCoilsMultiplier, Scale = 3.0);
		}

		return Helix.ActorCenterLocation + CoilHeightOffset + CoilXYOffset;
	}
};