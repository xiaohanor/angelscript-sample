struct FPlayerZipKiteSwingDeactivationParams
{
	bool bMoveCompleted = false;
}

class UPlayerZipKiteSwingCapability : UHazePlayerCapability
{
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	default CapabilityTags.Add(CapabilityTags::Movement);
	default CapabilityTags.Add(KiteTags::Kite);
	default CapabilityTags.Add(KiteTags::ZipKite);

	default DebugCategory = n"Movement";
	default TickGroup = EHazeTickGroup::ActionMovement;
	default TickGroupOrder = 4;
	default TickGroupSubPlacement = 5;

	UZipKitePlayerComponent ZipKitePlayerComp;
	UPlayerGrappleComponent GrappleComp;
	UPlayerTargetablesComponent TargetablesComp;
	UPlayerMovementComponent MoveComp;
	USimpleMovementData Movement;

	AZipKite Kite;
	AZipKiteFocusActor FocusActor;
	AZipKiteFocusActor ButtonMashAttachActor;

	bool bMoveCompleted = false;

	FVector TargetLocation;
	FRotator TargetRotation;

	FVector InitialAlignedVelocity;

	float CurrentZipLineDistance = 800;
	float CurrentZipSpeed;
	float InterpedMashRate;
	float AdditiveFov = 0;

	bool bButtonMashActive = false;

	FVector TargetRopeLocation;
	UHazeCrumbSyncedFloatComponent ZipDistanceSyncComp;
	UHazeCrumbSyncedFloatComponent ZipInterpedMashRateSyncComp;

	//
	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		MoveComp = UPlayerMovementComponent::Get(Player);
		Movement = MoveComp.SetupSimpleMovementData();
		GrappleComp = UPlayerGrappleComponent::Get(Player);
		ZipKitePlayerComp = UZipKitePlayerComponent::Get(Player);

		ZipDistanceSyncComp = UHazeCrumbSyncedFloatComponent::GetOrCreate(Player, n"ZipSync");
		ZipDistanceSyncComp.OverrideSyncRate(EHazeCrumbSyncRate::PlayerSynced);

		ZipInterpedMashRateSyncComp = UHazeCrumbSyncedFloatComponent::GetOrCreate(Player, n"InterpedMashZipSync");
		ZipInterpedMashRateSyncComp.OverrideSyncRate(EHazeCrumbSyncRate::PlayerSynced);

		FocusActor = SpawnActor(AZipKiteFocusActor, bDeferredSpawn = true);
		FocusActor.MakeNetworked(this, n"FocusActor");
		FinishSpawningActor(FocusActor);

		ButtonMashAttachActor = SpawnActor(AZipKiteFocusActor, bDeferredSpawn = true);
		ButtonMashAttachActor.MakeNetworked(this, n"ButtonMashAttachActor");
		FinishSpawningActor(ButtonMashAttachActor);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate(FPlayerZipKiteActivationParams& Params) const
	{
		if (MoveComp.HasMovedThisFrame())
        	return false;

		if (ZipKitePlayerComp.ZipKiteToForceActivate != nullptr)
		{
			Params.ZipPoint = ZipKitePlayerComp.ZipKiteToForceActivate;
			return true;
		}

		if (ZipKitePlayerComp.CurrentKite == nullptr)
			return false;

		if (ZipKitePlayerComp.PlayerKiteData.PlayerState != EZipKitePlayerStates::ZipLining)
			return false;

		Params.ZipKiteData = ZipKitePlayerComp.PlayerKiteData;
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate(FPlayerZipKiteSwingDeactivationParams& Params) const
	{
		if (MoveComp.HasMovedThisFrame())
			return true;

		if (bMoveCompleted)
		{
			Params.bMoveCompleted = true;
			return true;
		}

		if (ZipKitePlayerComp.PlayerKiteData.PlayerState != EZipKitePlayerStates::ZipLining)
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FPlayerZipKiteActivationParams Params)
	{
		Player.BlockCapabilities(PlayerMovementTags::CoreMovement, this);
		Player.BlockCapabilities(CapabilityTags::GameplayAction, this);
		Player.BlockCapabilities(PlayerMovementTags::ContextualMovement, this);

		if(Params.ZipPoint != nullptr)
		{
			ZipKitePlayerComp.ZipKiteToForceActivate = nullptr;
			ZipKitePlayerComp.PlayerKiteData.CurrentKite = Cast<AZipKite>(Params.ZipPoint.Owner);
			ZipKitePlayerComp.PlayerKiteData.PlayerState = EZipKitePlayerStates::ZipLining;

			GrappleComp.Grapple.CheckMaterial();
			//We are currently respawning inside the zipline so calculation based on ropelocation will give a faulty material tiling calc, so we cheat it a little here
			GrappleComp.SetGrappleMaterialParams(Player.ActorLocation + (MoveComp.WorldUp * ZipKitePlayerComp.CurrentKite.ZipPointHeight));

			GrappleComp.Grapple.SetActorLocation(TargetRopeLocation);
			GrappleComp.Grapple.SetActorHiddenInGame(false);
		}
		else
		{
			ZipKitePlayerComp.PlayerKiteData = Params.ZipKiteData;
		}

		Kite = ZipKitePlayerComp.CurrentKite;
		TargetLocation = ZipKitePlayerComp.GetRopeAttachLocationAtDistance(ZipKitePlayerComp.CurrentKite.ZipPointHeight);

		ZipKitePlayerComp.FocusActor = FocusActor;

		InitialAlignedVelocity = MoveComp.HorizontalVelocity;
		CurrentZipSpeed = InitialAlignedVelocity.Size();

		ZipKitePlayerComp.CurrentMashSpeedMultiplier = 0.0;
		ZipDistanceSyncComp.SetValue(0.0);
		CurrentZipLineDistance = Kite.ZipPointHeight;

		InterpedMashRate = 0;
		ZipInterpedMashRateSyncComp.SetValue(0.0);

		FButtonMashSettings MashSettings;
		MashSettings.WidgetAttachComponent = ButtonMashAttachActor.RootComp;
		MashSettings.bBlockOtherGameplay = false;
		MashSettings.ProgressionMode = EButtonMashProgressionMode::MashRateOnly;
		Player.StartButtonMash(MashSettings, this);
		Player.SetButtonMashAllowCompletion(this, false);
		bButtonMashActive = true;

		//Maybe we could trigger a view blend here instead of having a long blend time for the PoI
		if (Kite.bApplyPointOfInterest)
		{
			FHazePointOfInterestFocusTargetInfo FocusTargetInfo;
			FocusTargetInfo.SetFocusToActor(FocusActor);
			FocusTargetInfo.SetLocalOffset(Kite.PoiOffset);
			FApplyPointOfInterestSettings PoiSettings;
			Player.ApplyPointOfInterest(ZipKitePlayerComp, FocusTargetInfo, PoiSettings, 4);
		}

		SpeedEffect::RequestSpeedEffect(Player, 1.0, this, EInstigatePriority::High);

		UHazeCameraSpringArmSettingsDataAsset CamSettings = Kite.CamSettingsOverride == nullptr ? ZipKitePlayerComp.CamSettings : Kite.CamSettingsOverride;
		Player.ApplyCameraSettings(CamSettings, 0.5, this);
		Player.PlayCameraShake(ZipKitePlayerComp.ConstantCamShake, this);

		AdditiveFov = 0;

		Kite.OnPlayerAttached.Broadcast(Player);

		UZipKitePlayerEffectEventHandler::Trigger_StartZipping(Player);
		UKiteTownVOEffectEventHandler::Trigger_ZipStarted(Game::Mio, KiteTown::GetVOEffectEventParams(Player));
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FPlayerZipKiteSwingDeactivationParams Params)
	{
		Player.UnblockCapabilities(PlayerMovementTags::CoreMovement, this);
		Player.UnblockCapabilities(CapabilityTags::GameplayAction, this);
		Player.UnblockCapabilities(PlayerMovementTags::ContextualMovement, this);

		StopButtonMash();

		if(ZipKitePlayerComp.PlayerKiteData.PlayerState == EZipKitePlayerStates::SwingUp)
		{

		}
		else
		{
			ZipKitePlayerComp.PlayerKiteData.ResetData();
			GrappleComp.Grapple.AttachToActor(Player, n"LeftAttach", EAttachmentRule::SnapToTarget);
			GrappleComp.Grapple.SetActorHiddenInGame(true);
			Player.ClearPointOfInterestByInstigator(ZipKitePlayerComp);
		}

		Player.StopCameraShakeByInstigator(this);
		Player.ClearCameraSettingsByInstigator(this, 1.0);

		SpeedEffect::ClearSpeedEffect(Player, this);
	}

	void StopButtonMash()
	{
		if (!bButtonMashActive)
			return;

		bButtonMashActive = false;
		Player.StopButtonMash(this);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if (MoveComp.PrepareMove(Movement))
		{
			if (HasControl())
			{
				CalculateZipLineDistance(DeltaTime);
				float RopeOffsetDistance = CurrentZipLineDistance + 200 + (400 * InterpedMashRate);
				TargetRopeLocation = ZipKitePlayerComp.GetRopeAttachLocationAtDistance(RopeOffsetDistance >= (ZipKitePlayerComp.CurrentKite.RuntimeSplineRope.Length - ZipKitePlayerComp.PlayerKiteData.CurrentKite.ZipExitDistance) ? ZipKitePlayerComp.CurrentKite.RuntimeSplineRope.Length - ZipKitePlayerComp.PlayerKiteData.CurrentKite.ZipExitDistance : RopeOffsetDistance);
				TargetLocation = ZipKitePlayerComp.CalculateTargetPlayerLocation();
				TargetRotation = ZipKitePlayerComp.GetRopeAttachRotationAtDistance(CurrentZipLineDistance);

				FVector ToTarget = (TargetLocation - Player.ActorLocation);
				FVector DeltaMove = (ToTarget.GetSafeNormal() * CurrentZipSpeed) * DeltaTime;
			
				if(ToTarget.Size() < DeltaMove.Size())
				{
					DeltaMove = DeltaMove.GetSafeNormal() * ToTarget.Size();
				}

				Movement.AddDelta(DeltaMove);
				Movement.SetRotation(TargetRotation);

				float FFFrequency = 30.0;
				float FFIntensity = 0.4;

				FHazeFrameForceFeedback FF;
				FF.LeftMotor = Math::Sin(ActiveDuration * FFFrequency) * FFIntensity;
				FF.RightMotor = Math::Sin(-ActiveDuration * FFFrequency) * FFIntensity;
				Player.SetFrameForceFeedback(FF);
				
				FocusActor.SetActorLocationAndRotation(TargetRopeLocation, TargetRotation);
				ButtonMashAttachActor.SetActorLocation(TargetRopeLocation);
				
				CalculateAnimData();
			}
			else
			{
				float RopeOffsetDistance = ZipDistanceSyncComp.Value + 200 + (400 * ZipInterpedMashRateSyncComp.Value);
				TargetRopeLocation = ZipKitePlayerComp.GetRopeAttachLocationAtDistance(RopeOffsetDistance >= (ZipKitePlayerComp.CurrentKite.RuntimeSplineRope.Length - ZipKitePlayerComp.PlayerKiteData.CurrentKite.ZipExitDistance) ? ZipKitePlayerComp.CurrentKite.RuntimeSplineRope.Length - ZipKitePlayerComp.PlayerKiteData.CurrentKite.ZipExitDistance : RopeOffsetDistance);
				TargetRotation = ZipKitePlayerComp.GetRopeAttachRotationAtDistance(ZipDistanceSyncComp.Value);

				FocusActor.SetActorLocationAndRotation(TargetRopeLocation, TargetRotation);
				ButtonMashAttachActor.SetActorLocation(TargetRopeLocation);

				CalculateRemoteAnimData();

				// Follow the crumb trail on the remote side
				Movement.ApplyCrumbSyncedGroundMovement();
			}

			HandleGrappleCable();

			float TargetFov = Math::Lerp(0.0, 12.0, InterpedMashRate);
			AdditiveFov = Math::FInterpTo(AdditiveFov, TargetFov, DeltaTime, 0.3);
			UCameraSettings::GetSettings(Player).FOV.ApplyAsAdditive(AdditiveFov, this, 0.0, EHazeCameraPriority::VeryHigh);

			SpeedEffect::RequestSpeedEffect(Player, 1.0, this, EInstigatePriority::High, 1 + (0.5 * InterpedMashRate));

			MoveComp.ApplyMoveAndRequestLocomotion(Movement, n"ZipKites");

			if(VerifyReachedEndLocation())
			{
				ZipKitePlayerComp.PlayerKiteData.PlayerState = EZipKitePlayerStates::SwingUp;
			
				StopButtonMash();
			}
		}
	}

	void CalculateZipLineDistance(float DeltaTime)
	{
#if !RELEASE
		FTemporalLog Log = TEMPORAL_LOG(this);
#endif
		float MashRate = 0.0;
		bool bMashRateSufficient = false;
		Player.GetButtonMashCurrentRate(this, MashRate, bMashRateSufficient);
		float MashSpeedMultiplier = Math::GetMappedRangeValueClamped(FVector2D(0, 8), FVector2D(0, 1), MashRate);
		InterpedMashRate = Math::FInterpTo(InterpedMashRate, MashSpeedMultiplier, DeltaTime, ZipKitePlayerComp.Settings.MashRateInterpSpeed);
		ZipKitePlayerComp.CurrentMashSpeedMultiplier = InterpedMashRate;
		ZipInterpedMashRateSyncComp.SetValue(InterpedMashRate);

		//Modulate our target speed based on mash multiplier
		float TargetZipSpeed = Math::Lerp(Kite.ZipSpeed, Kite.ZipMashMaxSpeed, InterpedMashRate);

		//Interp towards our target speed,
		CurrentZipSpeed = Math::FInterpConstantTo(CurrentZipSpeed, TargetZipSpeed, DeltaTime,
							 Math::GetMappedRangeValueClamped(FVector2D(0, 1), FVector2D(ZipKitePlayerComp.Settings.ZipSpeedDecelerationInterpSpeed, ZipKitePlayerComp.Settings.ZipSpeedAccelerationInterpSpeed), InterpedMashRate));

#if !RELEASE
		Log.Value("TargetZipSpeed: ", TargetZipSpeed);
		Log.Value("ZipSpeed: ", CurrentZipSpeed);
		Log.Value("MashRate: ", MashSpeedMultiplier);
		Log.Value("InterpedMashRate: ", InterpedMashRate);
		Log.Value("HorizontalVel: ", MoveComp.HorizontalVelocity.Size());
		Log.Value("Distance: ", CurrentZipLineDistance);
		Log.Value("TotalDistance:",  Kite.RuntimeSplineRope.Length);
#endif
		CurrentZipLineDistance += CurrentZipSpeed * DeltaTime;
		ZipKitePlayerComp.PlayerKiteData.CurrentDistance = CurrentZipLineDistance;
		ZipDistanceSyncComp.SetValue(CurrentZipLineDistance);
	}

	bool VerifyReachedEndLocation() const 
	{
		return CurrentZipLineDistance >= Kite.RuntimeSplineRope.Length - ZipKitePlayerComp.PlayerKiteData.CurrentKite.ZipExitDistance;
	}

	void CalculateAnimData()
	{
		FRotator TetherPlayerRotation = FRotator::MakeFromZY(TargetRopeLocation - Player.ActorLocation, Owner.ActorRightVector);
		FQuat TetherPlayerRotationRelative = Player.ActorTransform.InverseTransformRotation(TetherPlayerRotation.Quaternion());
		ZipKitePlayerComp.AnimData.SwingRotation = TetherPlayerRotationRelative.Rotator();

		//Add some marginal noise to the BS sway
		float AdditionalVelocitySway =  (ZipKitePlayerComp.Settings.AdditionalAnimSway + (ZipKitePlayerComp.Settings.AdditionalAnimSway / 2 * InterpedMashRate))
										  * (Math::Sin(Time::GameTimeSeconds * (4)));

		//Doing some weird constraints on the relativeVelocity for animation purposes since we are repurposing swing assets
		// ZipKitePlayerComp.AnimData.RelativeVelocity.Y = Math::Min(ZipKitePlayerComp.CurrentKite.RuntimeSplineRope.GetTangent(CurrentZipLineDistance).GetSafeNormal().DotProduct(MoveComp.Velocity), ZipKitePlayerComp.Settings.MaxBlendSpaceAffectFromVelocity);
		ZipKitePlayerComp.AnimData.RelativeVelocity.Y = Math::Min(Player.ActorTransform.InverseTransformVectorNoScale(MoveComp.Velocity).X, ZipKitePlayerComp.Settings.MaxBlendSpaceAffectFromVelocity) + AdditionalVelocitySway;
		ZipKitePlayerComp.AnimData.MashRate = InterpedMashRate;
	}

	void CalculateRemoteAnimData()
	{
		FRotator TetherPlayerRotation = FRotator::MakeFromZY(TargetRopeLocation - Player.ActorLocation, Owner.ActorRightVector);
		FQuat TetherPlayerRotationRelative = Player.ActorTransform.InverseTransformRotation(TetherPlayerRotation.Quaternion());
		ZipKitePlayerComp.AnimData.SwingRotation = TetherPlayerRotationRelative.Rotator();

		//Add some marginal noise to the BS sway
		float AdditionalVelocitySway =  (ZipKitePlayerComp.Settings.AdditionalAnimSway + (ZipKitePlayerComp.Settings.AdditionalAnimSway / 2 * ZipInterpedMashRateSyncComp.Value))
										  * (Math::Sin(Time::GameTimeSeconds * (4)));

		//Doing some weird constraints on the relativeVelocity for animation purposes since we are repurposing swing assets
		// ZipKitePlayerComp.AnimData.RelativeVelocity.Y = Math::Min(ZipKitePlayerComp.CurrentKite.RuntimeSplineRope.GetTangent(CurrentZipLineDistance).GetSafeNormal().DotProduct(MoveComp.Velocity), ZipKitePlayerComp.Settings.MaxBlendSpaceAffectFromVelocity) + AdditionalVelocitySway;
		ZipKitePlayerComp.AnimData.RelativeVelocity.Y = Math::Min(Player.ActorTransform.InverseTransformVectorNoScale(MoveComp.Velocity).X, ZipKitePlayerComp.Settings.MaxBlendSpaceAffectFromVelocity) + AdditionalVelocitySway;
		ZipKitePlayerComp.AnimData.MashRate = InterpedMashRate;
	}

	void HandleGrappleCable()
	{
		GrappleComp.Grapple.SetActorLocation(TargetRopeLocation);
	}
};