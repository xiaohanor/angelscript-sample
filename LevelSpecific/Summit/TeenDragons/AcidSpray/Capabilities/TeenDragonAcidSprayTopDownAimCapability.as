class UTeenDragonAcidSprayTopDownAimCapability : UHazePlayerCapability
{
	default CapabilityTags.Add(TeenDragonCapabilityTags::TeenDragon);
	default CapabilityTags.Add(TeenDragonCapabilityTags::TeenDragonAcidSpray);
	default CapabilityTags.Add(TeenDragonCapabilityTags::TeenDragonAcidSprayAim);
	default CapabilityTags.Add(CapabilityTags::GameplayAction);

	default DebugCategory = SummitDebugCapabilityTags::TeenDragon;

	default TickGroup = EHazeTickGroup::Input;
	default TickGroupOrder = 202;

	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	UPlayerAimingComponent AimComp;
	UPlayerAcidTeenDragonComponent DragonComp;
	UTeenDragonAcidSprayComponent SprayComp;
	UHazeAnimPlayerLookAtComponent LookAtComp;
	UPlayerMovementComponent MoveComp;

	ATeenDragonAcidSprayTopDownIndicator Indicator;
	float IndicatorOpacity = 0.0;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		AimComp = UPlayerAimingComponent::Get(Player);
		SprayComp = UTeenDragonAcidSprayComponent::Get(Player);
		DragonComp = UPlayerAcidTeenDragonComponent::Get(Player);
		LookAtComp = UHazeAnimPlayerLookAtComponent::Get(Player);
		MoveComp = UPlayerMovementComponent::Get(Player);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if(!DragonComp.bTopDownMode)
			return false;

		if(AimComp.IsAiming())
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(!DragonComp.bTopDownMode)
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		LookAtComp.DisableCameraLookAt(this);

		Player.BlockCapabilities(TeenDragonCapabilityTags::TeenDragonAcidSprayAim, this);
		Player.ApplySettings(SprayComp.TopDownAcidSpraySettings, this, EHazeSettingsPriority::Gameplay);
		Player.ApplyAiming2DPlaneConstraint(FVector::UpVector, this);

		FAimingSettings Settings;
		Settings.bUseAutoAim = true;
		Settings.bShowCrosshair = true;
		Settings.OverrideCrosshairWidget = SprayComp.TopDownAcidSprayCrosshair;
		Settings.bApplyAimingSensitivity = false;
		Settings.Crosshair2DSettings = SprayComp.Crosshair2DSettings;
		Settings.bCrosshairFollowsTarget = true;
		AimComp.StartAiming(DragonComp, Settings);

		Indicator = SpawnActor(SprayComp.TopDownAcidSprayDirectionIndicatorActorClass);
		Indicator.AttachToComponent(DragonComp.DragonMesh, n"Head");
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		LookAtComp.ClearDisabledCameraLookAt(this);

		Player.UnblockCapabilities(TeenDragonCapabilityTags::TeenDragonAcidSprayAim, this);
		Player.ClearSettingsByInstigator(this);
		Player.ClearAiming2DConstraint(this);

		AimComp.StopAiming(DragonComp);

		Indicator.DestroyActor();
		Indicator = nullptr;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		bool bShouldOverride = true;
		if(Player.IsUsingGamepad())
		{
			auto CameraInput = GetAttributeVector2D(AttributeVectorNames::CameraDirection);
			bShouldOverride = !CameraInput.IsNearlyZero();
		}

		if(bShouldOverride)
			DragonComp.DragonMesh.RequestOverrideFeature(TeenDragonLocomotionTags::AcidTeenShoot, SprayComp);

		if (bShouldOverride)
		{
			IndicatorOpacity = Math::FInterpConstantTo(IndicatorOpacity, 1.0, DeltaTime, 4.0);

			FAimingResult AimTarget = AimComp.GetAimingTarget(DragonComp);
			FVector GroundUp = DragonComp.DragonMesh.UpVector;
			if (MoveComp.HasGroundContact())
				GroundUp = MoveComp.GroundContact.Normal;

			FVector AimOnGround = AimTarget.Ray.Direction.ConstrainToPlane(GroundUp).GetSafeNormal();
			FTransform SocketTransform = DragonComp.DragonMesh.GetSocketTransform(n"Head");

			FTransform IndicatorTransform = FTransform::GetRelative(
				SocketTransform,
					FTransform(
					FRotator::MakeFromZX(
						GroundUp,
						AimOnGround
					),
					SocketTransform.Location + AimOnGround * 160.0,
					FVector(2.0),
				));
			Indicator.SetActorRelativeTransform(IndicatorTransform);
		}
		else
		{
			IndicatorOpacity = Math::FInterpConstantTo(IndicatorOpacity, 0.0, DeltaTime, 1.0);
		}

		Indicator.PlaneArrow.SetScalarParameterValueOnMaterials(n"Opacity", IndicatorOpacity);

	}
};