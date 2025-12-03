UCLASS(HideCategories = "Hidden Rendering Cooking Input Actor LOD AssetUserData Debug Collision InternalHiddenObjects", Meta = (HighlightPlacement))
class ASplineFollowCustomRotationCameraActor : AHazeCameraActor
{
	UPROPERTY(OverrideComponent = Camera, ShowOnActor)
    UFocusTargetCustomRotationCamera Camera;
	default Camera.bSnapOnTeleport = false;

	UPROPERTY(DefaultComponent, ShowOnActor)
	UCameraWeightedTargetComponent FocusTargetComponent;

	UPROPERTY(DefaultComponent)
	UHazeSplineComponent SplineComponent;

	// Blends focus camera settings
	UPROPERTY(DefaultComponent, ShowOnActor)
	USegmentedSplineFocusCameraBlendComponent FocusBlendComponent;
	default FocusBlendComponent.SplineComponent = SplineComponent;

	UPROPERTY(DefaultComponent)
	USplineFollowCustomRotationCameraResponseComponent CameraActivationResponseComponent;


	UPROPERTY(DefaultComponent)
	UHazeRequestCapabilityOnPlayerComponent CapabilityRequestComponent;
	default CapabilityRequestComponent.PlayerSheets.Add(SegmentedSplineFocusCameraBlendSheet);


	// How long it will take to reach the wanted rotation
	UPROPERTY(EditAnywhere, Category = "Current Camera Settings|Focus Camera", meta = (EditCondition="FocusType != ECameraFocusMovementType::Location", EditConditionHides, ClampMin = "0.0"))
	float RotationDuration = 2;

	// How long it will take to reach the wanted location
	UPROPERTY(EditAnywhere, Category = "Current Camera Settings|Focus Camera", meta = (EditCondition="FocusType != ECameraFocusMovementType::Rotation", EditConditionHides, ClampMin = "0.0"))
	float LocationDuration = 2;

	// How much the camera is currently allowed to move towards the target value. Normally (1,1,1), if (0,0,0) it's locked in all axes, if (1,1,0) it's locked upwards/downwards.
    UPROPERTY(EditAnywhere, Category = "Current Camera Settings|Focus Camera|Advanced")
    FVector AxisFreedomFactor = FVector::OneVector;

	// If set, the camera will use this focus target as it's center to lock axes relative to. If not set, camera will always be locked relative to camera transform.
	UPROPERTY(EditAnywhere, Category = "Current Camera Settings|Focus Camera|Advanced", meta = (EditCondition="bInternalUseFreedomFactor", EditConditionHides))
	FHazeCameraWeightedFocusTargetInfo AxisFreedomCenter;
	default AxisFreedomCenter.SetFocusToActor(nullptr);

	// If set, camera will not be able to leave this volume. Note that volume should be convex, if it's concave you can "trap" the camera in a nook.
    UPROPERTY(EditAnywhere, Category = "Current Camera Settings|Focus Camera|Advanced")
	AVolume ConstraintVolume = nullptr;

	// If > 0, camera will try to start with an initial velocity matching that of it's focus targets. This means it will also try to start at an appropriate lagged position. Use this value to tweak how far behind it will lag.
	UPROPERTY(EditAnywhere, Category = "Current Camera Settings|Focus Camera|Advanced")
	float MatchInitialVelocityFactor = 0.0;
	
	UPROPERTY(EditConst, Category = "InternalHiddenObjects")
	protected bool bInternalUseFreedomFactor = false;

	UFUNCTION(BlueprintOverride)
	void ConstructionScript()
	{
		AxisFreedomFactor.X = Math::Clamp(AxisFreedomFactor.X, 0.0, 1.0);
		AxisFreedomFactor.Y = Math::Clamp(AxisFreedomFactor.Y, 0.0, 1.0);
		AxisFreedomFactor.Z = Math::Clamp(AxisFreedomFactor.Z, 0.0, 1.0);

		bInternalUseFreedomFactor = !AxisFreedomFactor.Equals(FVector::OneVector);

		FocusBlendComponent.FocusCamera = this;
	}

	UFUNCTION(BlueprintOverride)
	void PrepareUpdaterForUser(const UHazeCameraUserComponent HazeUser, UHazeCameraUpdater CameraData, FHazeCameraTransform CameraTransform) const
	{
		UCameraFocusTargetCustomRotationUpdater CameraUpdater = Cast<UCameraFocusTargetCustomRotationUpdater>(CameraData);
		FCameraFocusTargetCustomRotationData& Settings = CameraUpdater.UpdaterSettings;

		Settings.Init(HazeUser, ConstraintVolume, MatchInitialVelocityFactor);

#if EDITOR
		if(CameraData.Type == EHazeCameraUpdaterType::EditorPreview)
		{
			CameraUpdater.FocusTargets = FocusTargetComponent.GetEditorPreviewTargets();
			CameraUpdater.PrimaryTargets = FocusTargetComponent.GetEditorPreviewPrimaryTargets();

			if (AxisFreedomFactor != FVector::OneVector)
			{
				auto EditorAxisFreedomCenter = FocusTargetComponent.GetEditorPreviewFocus(AxisFreedomCenter);
				Settings.FocusTargetData.SetAxisFreedomFactor(AxisFreedomFactor, EditorAxisFreedomCenter.Location, Camera);
			}
		}
		else
#endif
		{
			auto PlayerOwner = HazeUser.GetPlayerOwner();
			if(PlayerOwner != nullptr)
			{
				CameraUpdater.FocusTargets = FocusTargetComponent.GetFocusTargets(PlayerOwner);
				CameraUpdater.PrimaryTargets = FocusTargetComponent.GetPrimaryTargetsOnly(PlayerOwner);

				if (AxisFreedomFactor != FVector::OneVector)
				{
					Settings.FocusTargetData.SetAxisFreedomFactor(AxisFreedomFactor, AxisFreedomCenter.GetFocusLocation(PlayerOwner), Camera);
				}
			}
		}

#if EDITOR
		if (CameraData.Type == EHazeCameraUpdaterType::EditorPreview)
			FocusBlendComponent.RefreshSplineKeys();
#endif

		// Get spline keys
		if (CameraUpdater.FocusTargets.Num() > 0)
		{
			FVector Location = CameraUpdater.FocusTargets.GetWeightedCenter();
			FocusBlendComponent.GetBlendKeyInfoAtLocation(Location, Settings.SplineKeyInfo);
		}

		// Acceleration info
		CameraUpdater.LocationDuration = Math::Max(LocationDuration, 0);
		CameraUpdater.RotationDuration = Math::Max(RotationDuration, 0);
	}

	FVector GetFocusCustomLocation(const UHazeCameraUserComponent HazeUser) const
	{
		// Eman TODO: Return debug location
		AHazePlayerCharacter Player = Cast<AHazePlayerCharacter>(HazeUser.Owner);
		if(Player == nullptr)
			return FVector::ZeroVector;

		if (SceneView::IsFullScreen())
			return (Player.ActorLocation + Player.OtherPlayer.ActorLocation) * 0.5;

		return Player.ActorLocation;
	}

	UFUNCTION(CallInEditor, Category = "Spline Keys")
	void CreateSplineKey()
	{
		FocusCameraBlend::Editor_CreateSplineKey(this);
	}

	UFUNCTION(BlueprintPure)
	bool IsActive()
	{
		for (auto Player : Game::Players)
		{
			if (Camera.IsUsedByPlayer(Player))
				return true;
		}

		return false;
	}

	UFUNCTION(BlueprintPure)
	bool IsUsedByPlayer(AHazePlayerCharacter Player) const
	{
		return Camera.IsUsedByPlayer(Player);
	}
}