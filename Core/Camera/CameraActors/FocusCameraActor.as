
/**
 * 
 */
enum ECameraFocusMovementType
{
	// Focus on target by moving camera
	Location,

	// Focus on target by rotating camera
	Rotation,

	// Focus on target by rotating and moving camera
	LocationAndRotation,
}


UCLASS(hideCategories="Rendering Cooking Input Actor LOD AssetUserData Debug Collision", Meta = (HighlightPlacement))
class AFocusCameraActor : AHazeCameraActor
{   
	UPROPERTY(OverrideComponent = Camera, ShowOnActor)
    UFocusTargetCamera Camera;
	default Camera.bSnapOnTeleport = false;

	UPROPERTY(DefaultComponent, ShowOnActor)
	UCameraWeightedTargetComponent FocusTargetComponent;

	// How the camera should move to focus on the targets
	UPROPERTY(EditAnywhere, Category = "Current Camera Settings|Focus Camera")
	ECameraFocusMovementType FocusType = ECameraFocusMovementType::Rotation;

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
	}

	UFUNCTION(BlueprintOverride)
	void PrepareUpdaterForUser(const UHazeCameraUserComponent HazeUser, UHazeCameraUpdater CameraData, FHazeCameraTransform CameraTransform) const
	{
		auto FocusData = Cast<UCameraFocusTargetUpdater>(CameraData);
		auto& Settings = FocusData.UpdaterSettings;
		Settings.Init(HazeUser, ConstraintVolume, MatchInitialVelocityFactor);
	
		#if EDITOR

		if(CameraData.Type == EHazeCameraUpdaterType::EditorPreview)
		{
			FocusData.FocusTargets = FocusTargetComponent.GetEditorPreviewTargets();
			FocusData.PrimaryTargets = FocusTargetComponent.GetEditorPreviewPrimaryTargets();

			if (AxisFreedomFactor != FVector::OneVector)
			{
				auto EditorAxisFreedomCenter = FocusTargetComponent.GetEditorPreviewFocus(AxisFreedomCenter);
				Settings.SetAxisFreedomFactor(AxisFreedomFactor, EditorAxisFreedomCenter.Location, Camera);
			}
		}
		else
		#endif
		{
			auto PlayerOwner = HazeUser.GetPlayerOwner();
			if(PlayerOwner != nullptr)
			{
				FocusData.FocusTargets = FocusTargetComponent.GetFocusTargets(PlayerOwner);
				FocusData.PrimaryTargets = FocusTargetComponent.GetPrimaryTargetsOnly(PlayerOwner);

				if (AxisFreedomFactor != FVector::OneVector)
				{
					Settings.SetAxisFreedomFactor(AxisFreedomFactor, AxisFreedomCenter.GetFocusLocation(PlayerOwner), Camera);
				}
			}
		}

		if(FocusType != ECameraFocusMovementType::Location)
			FocusData.UseFocusRotation(RotationDuration);	

		if(FocusType != ECameraFocusMovementType::Rotation)
			FocusData.UseFocusLocation(LocationDuration);		
	}	
}
