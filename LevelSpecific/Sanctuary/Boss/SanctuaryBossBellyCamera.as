UCLASS(hideCategories="Rendering Cooking Input Actor LOD AssetUserData Debug Collision, InternalHiddenObjects")
class ASanctuaryBossBellyCamera : AHazeCameraActor
{   
    UPROPERTY(OverrideComponent = Camera, ShowOnActor)
    UFocusTargetCamera Camera;
	default Camera.bSnapOnTeleport = false;

	UPROPERTY(DefaultComponent, ShowOnActor)
	UCameraWeightedTargetComponent FocusTargetComponent;
	default FocusTargetComponent.Targets.SetNum(2);
	default FocusTargetComponent.Targets[0].SetFocusToPlayerMio();
	default FocusTargetComponent.Targets[1].SetFocusToPlayerZoe();

	UFUNCTION(BlueprintOverride)
	void PrepareUpdaterForUser(const UHazeCameraUserComponent HazeUser, UHazeCameraUpdater CameraData, FHazeCameraTransform CameraTransform) const
	{
		auto KeepInViewData = Cast<UCameraFocusTargetUpdater>(CameraData);
		auto& Settings = KeepInViewData.UpdaterSettings;
		Settings.Init(HazeUser);
	
		#if EDITOR

		if(CameraData.Type == EHazeCameraUpdaterType::EditorPreview)
		{
			KeepInViewData.FocusTargets = FocusTargetComponent.GetEditorPreviewTargets();
			KeepInViewData.PrimaryTargets = FocusTargetComponent.GetEditorPreviewPrimaryTargets();
		}
		else
		#endif
		{
			auto PlayerOwner = HazeUser.GetPlayerOwner();
			if(PlayerOwner != nullptr)
			{
				KeepInViewData.FocusTargets = FocusTargetComponent.GetFocusTargets(PlayerOwner);
				KeepInViewData.PrimaryTargets = FocusTargetComponent.GetPrimaryTargetsOnly(PlayerOwner);
			}
		}

		KeepInViewData.UseFocusLocation();		
	}
}