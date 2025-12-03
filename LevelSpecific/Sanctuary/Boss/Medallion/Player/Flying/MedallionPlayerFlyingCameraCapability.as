
class UMedallionPlayerFlyingCameraCapability : UHazePlayerCapability
{
	default CapabilityTags.Add(CapabilityTags::Camera);
	default CapabilityTags.Add(MedallionTags::MedallionTag);
	default CapabilityTags.Add(MedallionTags::MedallionCoopFlying);

	default TickGroup = EHazeTickGroup::BeforeMovement;
	UMedallionPlayerComponent MedallionComp;
	UMedallionPlayerReferencesComponent RefsComp;
	UMedallionPlayerGloryKillComponent GloryKillComp;
	UMedallionPlayerFlyingMovementComponent AirMoveDataComp;
	UMedallionPlayerFlyingMovementComponent OtherAirMoveDataComp;

	FVector OGRelativeLocation;

	FHazeAcceleratedFloat AccRelativeYaw;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		MedallionComp = UMedallionPlayerComponent::GetOrCreate(Player);
		RefsComp = UMedallionPlayerReferencesComponent::GetOrCreate(Player);
		GloryKillComp = UMedallionPlayerGloryKillComponent::GetOrCreate(Player);
		AirMoveDataComp = UMedallionPlayerFlyingMovementComponent::GetOrCreate(Owner);
		OtherAirMoveDataComp = UMedallionPlayerFlyingMovementComponent::GetOrCreate(Player.OtherPlayer);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate(FMedallionImmediateBlendParams &ActivationParams) const
	{
		if (RefsComp.Refs == nullptr)
			return false;
		if (RefsComp.Refs.FlyingCamera == nullptr)
			return false;
		if (!MedallionComp.IsMedallionCoopFlying())
			return false;
		if (GloryKillComp.GloryKillState == EMedallionGloryKillState::ExecuteSequence)
			return false;
		if (GloryKillComp.GloryKillState == EMedallionGloryKillState::Return)
			return false;
		
		ActivationParams.bImmediateBlend = DeactiveDuration < 1.0;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (!MedallionComp.IsMedallionCoopFlying())
			return true;
		if (GloryKillComp.GloryKillState == EMedallionGloryKillState::ExecuteSequence)
			return true;
		if (GloryKillComp.GloryKillState == EMedallionGloryKillState::Return)
			return true;
		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FMedallionImmediateBlendParams ActivationParams)
	{
		OGRelativeLocation = RefsComp.Refs.FlyingCamera.ActorRelativeLocation;

		Player.BlockCapabilities(CameraTags::CameraAlignWithWorldUp, this);

		if (ActivationParams.bImmediateBlend)
		{
			Player.ActivateCamera(RefsComp.Refs.FlyingCamera, 0.0, this, EHazeCameraPriority::High);
		}
		else
		{
			Player.ActivateCamera(RefsComp.Refs.FlyingCamera, 1.0, this, EHazeCameraPriority::High);
		}

		AccRelativeYaw.SnapTo(0.0);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Player.UnblockCapabilities(CameraTags::CameraAlignWithWorldUp, this);
		Player.DeactivateCamera(RefsComp.Refs.FlyingCamera, 0.2);
		RefsComp.Refs.FlyingCamera.SetActorRelativeLocation(OGRelativeLocation);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		float PlayersAverageX = (OtherAirMoveDataComp.SyncedSideways.Value + AirMoveDataComp.SyncedSideways.Value) * 0.5;
		
		FVector2D PlaneXExtents = FVector2D(-RefsComp.Refs.MedallionBossPlane2D.PlaneExtents.X, RefsComp.Refs.MedallionBossPlane2D.PlaneExtents.X);
		FVector2D PlaneXExtentsWithBuffer = PlaneXExtents;
		PlaneXExtentsWithBuffer.X += MedallionConstants::Flying::RubberbandPlayersMinDistance;
		PlaneXExtentsWithBuffer.Y -= MedallionConstants::Flying::RubberbandPlayersMinDistance;

		FVector2D CameraYawRange = FVector2D(-MedallionConstants::Flying::CameraYawMaxAngle, MedallionConstants::Flying::CameraYawMaxAngle);

		float RelativeYaw = Math::GetMappedRangeValueClamped(
			PlaneXExtentsWithBuffer, 
			CameraYawRange,
			PlayersAverageX);

		AccRelativeYaw.AccelerateTo(RelativeYaw, 2.0, DeltaTime);

		FRotator RelativeRotation = RefsComp.Refs.FlyingCamera.ActorRelativeRotation;
		RelativeRotation.Yaw = AccRelativeYaw.Value;

		RefsComp.Refs.FlyingCamera.SetActorRelativeRotation(RelativeRotation);
		FVector RelativeLocation = OGRelativeLocation;
		RelativeLocation.Y += AccRelativeYaw.Value * 100.0;
		//RefsComp.Refs.FlyingCamera.SetActorRelativeLocation(RelativeLocation);

		//Debug::DrawDebugSphere(RefsComp.Refs.FlyingCamera.ActorLocation, LineColor = ColorDebug::Rainbow(2.0), bDrawInForeground = true);
	}
};