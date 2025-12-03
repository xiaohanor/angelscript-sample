event void FOnSolarFlareMovementStickApplied(FVector2D Input);
event void FOnSolarFlareMovementStickStop();
event void FOnSolarFlareMovementStickInteractionStarted(UInteractionComponent Interaction, AHazePlayerCharacter Player);
event void FOnSolarFlareMovementStickInteractionStopped(UInteractionComponent Interaction, AHazePlayerCharacter Player);

class ASolarFlareStickInteraction : AHazeActor
{
	UPROPERTY()
	FOnSolarFlareMovementStickApplied OnSolarFlareMovementStickApplied;

	UPROPERTY()
	FOnSolarFlareMovementStickStop OnSolarFlareMovementStickStop;

	UPROPERTY()
	FOnSolarFlareMovementStickInteractionStarted OnSolarFlareMovementStickInteractionStarted;

	UPROPERTY()
	FOnSolarFlareMovementStickInteractionStopped OnSolarFlareMovementStickInteractionStopped;

	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent MeshRoot;

	UPROPERTY(DefaultComponent, Attach = Root)
	UInteractionComponent InteractComp;

	UPROPERTY(EditAnywhere)
	AStaticCameraActor Camera;
	UPROPERTY(EditAnywhere)
	float BlendIn = 1.0;
	UPROPERTY(EditAnywhere)
	float BlendOut = 1.0;
	UPROPERTY(EditAnywhere)
	float StickDirectionMultiplier = 1.0;
	UPROPERTY(EditAnywhere)
	bool bRotateRoll = true;
	UPROPERTY(EditAnywhere)
	bool bRotatePitch = false;

	FRotator TargetRot;
	FRotator CurrentRot;
	float RotationTarget = 45.0;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		InteractComp.OnInteractionStarted.AddUFunction(this, n"OnInteractionStarted");
		InteractComp.OnInteractionStopped.AddUFunction(this, n"OnInteractionStopped");
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		CurrentRot = Math::QInterpTo(CurrentRot.Quaternion(), TargetRot.Quaternion(), DeltaSeconds, 5.0).Rotator();
		MeshRoot.RelativeRotation = Math::QInterpTo(MeshRoot.RelativeRotation.Quaternion(), CurrentRot.Quaternion(), DeltaSeconds, 25.0).Rotator();
	}

	void StickRotation(FVector2D Input)
	{
		float Roll = 0.0; 
		float Pitch = 0.0;
		
		if (bRotateRoll)
			Roll = Input.X * RotationTarget;
		if (bRotatePitch)
			Pitch = -Input.Y * RotationTarget;

		TargetRot = FRotator(Pitch, 0.0, Roll);
	}

	UFUNCTION()
	private void OnInteractionStarted(UInteractionComponent Interaction, AHazePlayerCharacter Player)
	{
		OnSolarFlareMovementStickInteractionStarted.Broadcast(Interaction, Player);
		BlendCamera(true, Player);
	}

	UFUNCTION()
	private void OnInteractionStopped(UInteractionComponent Interaction, AHazePlayerCharacter Player)
	{
		OnSolarFlareMovementStickInteractionStopped.Broadcast(Interaction, Player);
		BlendCamera(false, Player);
	}

	void BlendCamera(bool ShouldActivate, AHazePlayerCharacter Player)
	{
		if (Camera == nullptr)
			return;

		UCameraSettings CamSettings = UCameraSettings::GetSettings(Player);

		if (ShouldActivate)
		{
			Player.ActivateCamera(Camera, BlendIn, this);
			CamSettings.FOV.ApplyAsAdditive(-5, this, BlendIn);
			Player.ApplyViewSizeOverride(this, EHazeViewPointSize::Large);
		}
		else
		{
			Player.DeactivateCamera(Camera, BlendOut);
			CamSettings.FOV.Clear(this, BlendOut);
			Player.ClearViewSizeOverride(this);
		}
	}
}