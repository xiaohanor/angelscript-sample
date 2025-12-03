// Handles automate activation of system when camera activates
class USplineFollowCustomRotationCameraResponseComponent : UHazeCameraResponseComponent
{
	ASplineFollowCustomRotationCameraActor SplineFollowCustomRotationCameraOwner = nullptr;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		SplineFollowCustomRotationCameraOwner = Cast<ASplineFollowCustomRotationCameraActor>(Owner);
	}

	UFUNCTION(BlueprintOverride)
	void OnCameraActivated(UHazeCameraUserComponent User)
	{
		if (SplineFollowCustomRotationCameraOwner != nullptr)
		{
			// Eman TODO: Add priority
			AHazePlayerCharacter Player = User.GetPlayerOwner();
			SplineFollowCustomRotationCameraOwner.FocusBlendComponent.ActivateForPlayer(SplineFollowCustomRotationCameraOwner, Player, EHazeCameraPriority::Medium);

			USplineFocusCameraBlendPlayerComponent FocusCameraBlendPlayerComponent = USplineFocusCameraBlendPlayerComponent::GetOrCreate(Player);
			FocusCameraBlendPlayerComponent.SplineFocusCameraBlendComponent = SplineFollowCustomRotationCameraOwner.FocusBlendComponent;
		}
	}

	UFUNCTION(BlueprintOverride)
	void OnCameraDeactivated(UHazeCameraUserComponent User)
	{
		if (SplineFollowCustomRotationCameraOwner != nullptr)
			SplineFollowCustomRotationCameraOwner.FocusBlendComponent.DeactivateForPlayer(User.GetPlayerOwner());
	}
}