UCLASS(NotBlueprintable)
class APirateShipTelescopeCamera : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent)
	UHazeCameraComponent CameraComp;

	UPROPERTY(EditAnywhere)
	float DistanceFromGround = 200;

#if EDITOR
	UFUNCTION(BlueprintOverride)
	void OnActorModifiedInEditor()
	{
		UpdateCameraLocation();
	}
#endif

	void UpdateCameraLocation()
	{
		CameraComp.SetWorldLocation(GetTargetCameraLocation());
	}

	FVector GetTargetCameraLocation() const
	{
		return Root.WorldLocation + FVector::UpVector * DistanceFromGround;
	}
};