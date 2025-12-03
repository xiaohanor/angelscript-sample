
asset RollingLiftSplineLockEnterSettings of UPlayerSplineLockEnterSettings
{
	EnterType = EPlayerSplineLockEnterType::SmoothLerp;
	EnterSmoothLerpDuration = 0.5;
}

class USummitRollingLiftDriverCapability : UHazePlayerCapability
{
	// Need this so we start after the interaction is finished
	default CapabilityTags.Add(n"InteractionCancel");

	default TickGroup = EHazeTickGroup::Gameplay;

	USummitTeenDragonRollingLiftComponent LiftComp;
	ASummitRollingLift CurrentRollingLift;
	AHazeActor CurrentLockedSpline;

	FPlayerMovementSplineLockProperties LockProperties;
	default LockProperties.AllowedHorizontalDeviation = 50;
	default LockProperties.bRedirectMovementInput = true;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		LiftComp = USummitTeenDragonRollingLiftComponent::Get(Player);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		CurrentRollingLift = LiftComp.CurrentRollingLift;
		const float CollisionRadiusOverride = CurrentRollingLift.CollisionSphere.SphereRadius;
		Player.CapsuleComponent.OverrideCapsuleSize(CollisionRadiusOverride, CollisionRadiusOverride, this, EInstigatePriority::High);
		
		CurrentRollingLift.AddActorCollisionBlock(this);

		Player.TeleportActor(CurrentRollingLift.GetActorLocation(), CurrentRollingLift.GetActorRotation(), this, false);
	
		// Make sure we keep whatever velocity we had
		CurrentRollingLift.CurrentMoveComp = UHazeMovementComponent::Get(Player);
		Player.SetActorVelocity(CurrentRollingLift.ActorVelocity);

		CurrentRollingLift.AttachRootComponentTo(Player.RootComponent, NAME_None, EAttachLocation::KeepWorldPosition);
		CurrentRollingLift.RootComponent.SetRelativeLocation(FVector::ZeroVector);
			
		if (CurrentRollingLift.Camera != nullptr)
			Player.ActivateCamera(CurrentRollingLift.Camera, 0.5, this);

		Player.ApplyCameraSettings(CurrentRollingLift.CameraSettings, 0.5, this, EHazeCameraPriority::Medium);	
		Player.BlockCapabilities(TeenDragonCapabilityTags::TeenDragonLandingCamera, this);
		
		CurrentLockedSpline = Cast<AHazeActor>(CurrentRollingLift.CurrentSpline.Owner);
		Player.LockPlayerMovementToSpline(CurrentLockedSpline, this, LockProperties = LockProperties, EnterSettings = RollingLiftSplineLockEnterSettings);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		CurrentRollingLift.DetachRootComponentFromParent();
		CurrentRollingLift.RemoveActorCollisionBlock(this);
		
		Player.DeactivateCamera(CurrentRollingLift.Camera);

		Player.ClearCameraSettingsByInstigator(this);
		Player.UnblockCapabilities(TeenDragonCapabilityTags::TeenDragonLandingCamera, this);

		Player.TeleportActor(CurrentRollingLift.DriverExitLocation.WorldLocation, CurrentRollingLift.DriverExitLocation.WorldRotation, this, true);

		LiftComp.CurrentRollingLift = nullptr;

		Player.UnlockPlayerMovementFromSpline(this);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		auto Spline = CurrentRollingLift.UpdateBestGuideSpline(Player);
		auto SplineActor = Cast<AHazeActor>(Spline.CurrentSpline.Owner);
		if(CurrentLockedSpline != SplineActor)
		{
			CurrentLockedSpline = SplineActor;
			Player.LockPlayerMovementToSpline(CurrentLockedSpline, this, LockProperties = LockProperties);
		}
	}
};