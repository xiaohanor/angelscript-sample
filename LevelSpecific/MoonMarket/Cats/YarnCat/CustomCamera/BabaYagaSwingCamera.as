asset BabaYagaSwingUpCameraBlend of UCameraDefaultBlend
{
	bLockSourceViewRotation = false;
}

class ABabaYagaSwingCamera : AHazeCameraActor
{
	UPROPERTY(OverrideComponent = Camera, ShowOnActor)  
    UHazeCameraComponent Camera;

	UPROPERTY(DefaultComponent)
	UHazeCapabilityComponent CapabilityComp;
	default CapabilityComp.DefaultCapabilities.Add(n"BabaYagaSwingCameraCapability");

	UPROPERTY(EditInstanceOnly)
	AActor FocusPoint;

	UPROPERTY(EditInstanceOnly)
	TSubclassOf<UCameraShakeBase> CameraShake;

	AHazePlayerCharacter TargetPlayer;
	AActor TargetFollowActor;


	bool bPlayerSwinging;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
	}

	UFUNCTION()
	void ActivateSwingCamera(AHazePlayerCharacter Player, AActor FollowActor)
	{
		if (bPlayerSwinging)
			return;
		
		bPlayerSwinging = true;
		TargetPlayer = Player;
		TargetFollowActor = FollowActor;
	}

	UFUNCTION()
	void DeactivateSwingCamera(AHazePlayerCharacter Player)
	{
		bPlayerSwinging = false;
		TargetPlayer = nullptr;
	}
};