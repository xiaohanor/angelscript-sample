class URemoteHackableTelescopeRobotTelescopeCapability : UHazeCapability
{
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	default CapabilityTags.Add(CapabilityTags::GameplayAction);
	default CapabilityTags.Add(PrisonTags::Prison);

	default TickGroup = EHazeTickGroup::Gameplay;

	ARemoteHackableTelescopeRobot TelescopeRobot;
	UHazeMovementComponent MoveComp;
	AHazePlayerCharacter Player;

	UCameraSettings CameraSettings;

	float AcceleratedExtensionTarget;
	float ExtensionFraction;
	float InitialFov;

	bool bPerchSplineActive = false;

	bool bNetExtending;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		TelescopeRobot = Cast<ARemoteHackableTelescopeRobot>(Owner);
		MoveComp = UHazeMovementComponent::Get(Owner);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if(!TelescopeRobot.HackableComp.bHacked)
			return false;

		if(!WasActionStarted(ActionNames::SecondaryLevelAbility))
			return false;

		if(MoveComp.IsInAir())
			return false;

		if (TelescopeRobot.bDestroyed)
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (!IsActioning(ActionNames::SecondaryLevelAbility) && Math::IsNearlyZero(ExtensionFraction, 0.05))
			return true;

		if (TelescopeRobot.bDestroyed)
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Player = TelescopeRobot.HackableComp.HackingPlayer;
		CameraSettings = UCameraSettings::GetSettings(Player);
		InitialFov = CameraSettings.FOV.GetValue();

		bPerchSplineActive = true;
		if (TelescopeRobot.PerchSpline != nullptr)
			TelescopeRobot.PerchSpline.EnablePerchSpline(TelescopeRobot);

		CameraSettings.SensitivityFactor.Apply(0.25, this, Priority = EHazeCameraPriority::Low);

		TelescopeRobot.bExtended = true;

		TelescopeRobot.ExtendTelescope();
		
		Player.BlockCapabilities(CameraTags::CameraControl, this);
		Player.BlockCapabilities(CameraTags::CameraChaseAssistance, this);

		// I mean... it works?
		// UPlayerRemoteHackableTelescopeRobotResponseComponent::GetOrCreate(Player.OtherPlayer);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		if (TelescopeRobot.PerchSpline != nullptr && bPerchSplineActive)
			TelescopeRobot.PerchSpline.DisablePerchSpline(TelescopeRobot);

		Player.ClearCameraSettingsByInstigator(this, 1.0);
		CameraSettings = nullptr;

		TelescopeRobot.bExtended = false;

		TelescopeRobot.RetractTelescope();
		
		Player.UnblockCapabilities(CameraTags::CameraControl, this);
		Player.UnblockCapabilities(CameraTags::CameraChaseAssistance, this);
	}

	// Eman: Handle all rotation on movement capability
	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if (HasControl())
		{
			if (ShouldExtend() && !bNetExtending)
				CrumbSetExtending(true);
			else if (!ShouldExtend() && bNetExtending)
				CrumbSetExtending(false);
		}

		if (bNetExtending)
		{
			if (!bPerchSplineActive)
			{
				bPerchSplineActive = true;
				TelescopeRobot.PerchSpline.EnablePerchSpline(TelescopeRobot);
			}
		}
		else
		{
			if (bPerchSplineActive)
			{
				bPerchSplineActive = false;
				TelescopeRobot.PerchSpline.DisablePerchSpline(TelescopeRobot);
			}
		}

		float AccelerationTarget = bNetExtending ? 1.0 : 0.0;
		AcceleratedExtensionTarget = Math::FInterpTo(AcceleratedExtensionTarget, AccelerationTarget, DeltaTime, 6.0);
		float Speed = bNetExtending ? 5.0 : 8.0;
		ExtensionFraction = Math::FInterpTo(ExtensionFraction, AcceleratedExtensionTarget, DeltaTime, Speed);

		float ScaleShare = TelescopeRobot.TelescopeMaxScale / 3;

		float BaseScale = Math::Saturate(ExtensionFraction / 0.3);
		SetMeshScale(TelescopeRobot.TelescopeMesh, BaseScale * ScaleShare);

		float MiddleScale = Math::Saturate(Math::Max(0.0, ExtensionFraction - 0.4) / 0.3);
		SetMeshScale(TelescopeRobot.TelescopeMeshMiddle, MiddleScale * ScaleShare);

		float TipScale = Math::Saturate(Math::Max(0.0, ExtensionFraction - 0.8) / 0.2);
		SetMeshScale(TelescopeRobot.TelescopeMeshTip, TipScale * ScaleShare);

		// Update spline
		// Eman TODO: Handle player standing on ghost spline! (PlayerPerchComponent::VerifyReachedPerchSplineEnd())
		FVector WorldTipLocation = TelescopeRobot.TelescopeMeshTip.WorldLocation + TelescopeRobot.ActorForwardVector * TelescopeRobot.TelescopeMaxScale * TipScale * 100;
		TelescopeRobot.PerchSpline.Spline.SplinePoints.Last().RelativeLocation = TelescopeRobot.PerchSpline.ActorTransform.InverseTransformPositionNoScale(WorldTipLocation);
		TelescopeRobot.PerchSpline.Spline.UpdateSpline();

		UpdateTelescopeCollision(ScaleShare);

		// Modify fov based on extension
		float TargetFov = bNetExtending ? InitialFov - 5.0 : InitialFov;
		float Fov = Math::FInterpTo(CameraSettings.FOV.Value, TargetFov, DeltaTime, 3.0);
		CameraSettings.FOV.Apply(Fov, this, 0.0);

		// Add juicy FF rumble if player is still controlling
		if (TelescopeRobot.HackableComp.bHacked)
		{
			float Force = Math::IsNearlyZero(0.05) || AcceleratedExtensionTarget > 0.98 ? 0.0 : 0.1;
			if ((ExtensionFraction > 0.3 && ExtensionFraction < 0.4) || (ExtensionFraction > 0.7 && ExtensionFraction < 0.8))
				Force += 0.2;

			FHazeFrameForceFeedback ForceFeedback;
			ForceFeedback.LeftTrigger = Force * AcceleratedExtensionTarget;
			ForceFeedback.RightMotor = Force * AcceleratedExtensionTarget * 0.5;
			Player.SetFrameForceFeedback(ForceFeedback);
		}
	}

	void SetMeshScale(UStaticMeshComponent MeshComponent, float Alpha)
	{
		float SmallScale = Math::Max(Alpha, SMALL_NUMBER);
		FVector Scale = FVector(SmallScale, MeshComponent.RelativeScale3D.Y, MeshComponent.RelativeScale3D.Z);
		MeshComponent.SetRelativeScale3D(Scale);
	}

	void UpdateTelescopeCollision(float ScaleShare)
	{
		float TelescopeMeshLength = TelescopeRobot.TelescopeMesh.StaticMesh.BoundingBox.Extent.Max
								  + TelescopeRobot.TelescopeMeshMiddle.StaticMesh.BoundingBox.Extent.Max
								  + TelescopeRobot.TelescopeMeshTip.StaticMesh.BoundingBox.Extent.Max;

		TelescopeRobot.TelescopeCollision.SetRelativeLocation(FVector::ForwardVector * ExtensionFraction * TelescopeMeshLength);
		TelescopeRobot.TelescopeCollision.SetCapsuleHalfHeight(ExtensionFraction * TelescopeMeshLength * ScaleShare);

		// Check if we are hitting playa. I dunno? Do we want this?
		// FHazeTraceSettings Trace = Trace::InitFromPrimitiveComponent(TelescopeRobot.TelescopeCollision);
		// Trace.IgnoreActor(Player);
		// Trace.IgnoreActor(Owner);
		// FOverlapResultArray Overlaps = Trace.QueryOverlaps(TelescopeRobot.TelescopeCollision.WorldLocation);
		// for (auto Overlap : Overlaps)
		// {
		// 	if (Overlap.Actor != nullptr)
		// 	{
		// 		UPlayerRemoteHackableTelescopeRobotResponseComponent TelescopeResponseComponent = UPlayerRemoteHackableTelescopeRobotResponseComponent::Get(Overlap.Actor);
		// 		if (TelescopeResponseComponent != nullptr)
		// 			TelescopeResponseComponent.TelescopeOverlap(-Overlap.GetDepenetrationDelta(Trace.Shape, TelescopeRobot.TelescopeCollision.WorldLocation));
		// 	}
		// }
	}

	bool ShouldExtend() const
	{
		if (!TelescopeRobot.HackableComp.bHacked)
			return false;

		if (!IsActioning(ActionNames::SecondaryLevelAbility))
			return false;

		if (MoveComp.IsInAir())
			return false;

		if (TelescopeRobot.bDestroyed)
			return false;

		if (TelescopeRobot.bLaunched)
			return false;

		return true;
	}

	UFUNCTION(CrumbFunction)
	void CrumbSetExtending(bool bValue)
	{
		bNetExtending = bValue;
	}
}