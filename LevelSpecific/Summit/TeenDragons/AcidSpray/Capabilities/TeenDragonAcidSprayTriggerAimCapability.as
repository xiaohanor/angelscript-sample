
class UTeenDragonAcidSprayTriggerAimCapability : UHazePlayerCapability
{
	default CapabilityTags.Add(TeenDragonCapabilityTags::TeenDragon);
	default CapabilityTags.Add(TeenDragonCapabilityTags::TeenDragonAcidSpray);
	default CapabilityTags.Add(TeenDragonCapabilityTags::TeenDragonAcidSprayAim);
	default CapabilityTags.Add(CapabilityTags::GameplayAction);

	default DebugCategory = SummitDebugCapabilityTags::TeenDragon;

	default TickGroup = EHazeTickGroup::Input;
	default TickGroupOrder = 200;

	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	UPlayerAimingComponent AimComp;
	UPlayerAcidTeenDragonComponent DragonComp;
	UTeenDragonAcidSprayComponent SprayComp;
	UCameraUserComponent CameraUserComp;

	FHazeAcceleratedVector AccCameraOffset;

	UCameraSettings CameraSettings;
	UTeenDragonAcidSpraySettings SpraySettings;

	const float BlendTime = 0.5;
	const float BlendOutTime = 2.0;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		AimComp = UPlayerAimingComponent::Get(Player);
		DragonComp = UPlayerAcidTeenDragonComponent::Get(Player);
		SprayComp = UTeenDragonAcidSprayComponent::Get(Player);
		CameraUserComp = UCameraUserComponent::Get(Player);

		CameraSettings = UCameraSettings::GetSettings(Player);
		SpraySettings = UTeenDragonAcidSpraySettings::GetSettings(Player);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if(DragonComp.bTopDownMode)
			return false;

		if(AimComp.IsAiming())
			return false;

		if(DragonComp.AimMode == ETeenDragonAcidAimMode::LeftTriggerMode
		&& IsActioning(ActionNames::SecondaryLevelAbility))
			return true;

		if(DragonComp.AimMode == ETeenDragonAcidAimMode::OffsetWhenShooting
		&& IsActioning(ActionNames::PrimaryLevelAbility))	
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(DragonComp.AimMode == ETeenDragonAcidAimMode::LeftTriggerMode
		&& IsActioning(ActionNames::SecondaryLevelAbility))
			return false;

		if(DragonComp.AimMode == ETeenDragonAcidAimMode::OffsetWhenShooting
		&& IsActioning(ActionNames::PrimaryLevelAbility))
			return false;

		if(DragonComp.bTopDownMode)
			return true;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		FAimingSettings Settings;
		Settings.bShowCrosshair = true;
		Settings.bUseAutoAim = true;
		Settings.OverrideCrosshairWidget = SprayComp.AcidSprayCrosshair;
		Settings.bApplyAimingSensitivity = true;
		Settings.bCrosshairFollowsTarget = true;
		Settings.OverrideAutoAimTarget = UTeenDragonAcidAutoAimComponent;
		AimComp.StartAiming(DragonComp, Settings);
		AccCameraOffset.SnapTo(CameraSettings.CameraOffset.Value, CameraUserComp.ViewVelocity);

		Player.BlockCapabilities(CameraTags::CameraChaseAssistance, this);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		AimComp.StopAiming(DragonComp);

		Player.ClearCameraSettingsByInstigator(this, BlendOutTime);

		Player.UnblockCapabilities(CameraTags::CameraChaseAssistance, this);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		auto TempLog = TEMPORAL_LOG(Player, "Acid Spray Camera Offset");

		if(DragonComp.DragonMesh.CanRequestOverrideFeature())
			DragonComp.DragonMesh.RequestOverrideFeature(TeenDragonLocomotionTags::AcidTeenShoot, SprayComp);
		
		FVector CameraRelativeOffset = FVector::ZeroVector;
		if(!DragonComp.bNonOffsetAimCamera)
		{
			FVector TargetOffset = FVector::ZeroVector;
			FVector HeadLocation = DragonComp.DragonMesh.GetSocketLocation(n"Head");
			FVector HeadOffset = HeadLocation - Player.ActorLocation;
			HeadOffset = HeadOffset.ConstrainToPlane(FVector::UpVector);

			TargetOffset += HeadOffset;

			auto ControlRotation = CameraUserComp.ControlRotation;
			FVector CameraOffset = ControlRotation.RotateVector(SpraySettings.CameraOffset);
			TargetOffset += CameraOffset;

			FVector PivotLocation = CameraUserComp.ActiveCameraPivotLocation - CameraSettings.WorldPivotOffset.Value;
			FVector PivotTargetLocation = PivotLocation + TargetOffset;
			
			TempLog
				.DirectionalArrow("HeadOffset", Player.ActorLocation, HeadOffset, 5, 40, FLinearColor::Blue)
				.Value("World Pivot Offset", CameraSettings.WorldPivotOffset.Value)
				.Sphere("Pivot Location", PivotLocation, 5, FLinearColor::LucBlue, 1)
				.Sphere("Pivot target location", PivotTargetLocation, 5, FLinearColor::DPink, 1)
				.Sphere("Active Camera pivot Location", CameraUserComp.ActiveCameraPivotLocation, 5, FLinearColor::Green, 1)
			;

			FVector WorldOffset = PivotTargetLocation - PivotLocation;
			CameraRelativeOffset = CameraUserComp.ViewTransform.InverseTransformVector(WorldOffset);
		}

		FHazeTraceSettings Trace;
		Trace.UseLine();
		Trace.TraceWithChannel(ECollisionChannel::WeaponTraceMio);
		Trace.IgnorePlayers();
		Trace.IgnoreActor(Owner);
		bool bIsAimingAtTarget = false;
		if (AimComp.IsAiming(DragonComp))
		{
			auto AimResult = AimComp.GetAimingTarget(DragonComp);

			// Note: range is a rough approximation but it is slightly shorter than the maximum you can hit stuff from
			// so you are more incentivized to move a bit closer than you actually have to hit
			float Range = SpraySettings.AcidSprayRange + 3850;
			FVector EndLocation = AimResult.AimOrigin + AimResult.AimDirection * Range;
			auto HitResult = Trace.QueryTraceSingle(AimResult.AimOrigin, EndLocation);
			if (HitResult.bBlockingHit)
			{
				auto ResponseComp = UAcidResponseComponent::Get(HitResult.Actor);
				if (ResponseComp != nullptr)
					bIsAimingAtTarget = true;
			}
		}
		DragonComp.bIsAimingAtTarget = bIsAimingAtTarget;
		AccCameraOffset.AccelerateTo(CameraRelativeOffset, BlendTime, DeltaTime);
		CameraSettings.CameraOffset.ApplyAsAdditive(AccCameraOffset.Value, this, 0.0, EHazeCameraPriority::VeryHigh);
	}
}