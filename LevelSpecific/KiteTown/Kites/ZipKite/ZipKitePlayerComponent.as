class UZipKitePlayerComponent : UActorComponent
{
	AZipKite CurrentKite;

	UPROPERTY()
	TSubclassOf<UCameraShakeBase> ConstantCamShake;

	UPROPERTY()
	UAnimSequence EnterAnim;

	UPROPERTY()
	UBlendSpace BlendSpace;

	UPROPERTY()
	UAnimSequence SwingUpAnim;

	UPROPERTY()
	UHazeCameraSpringArmSettingsDataAsset CamSettings;

	UPROPERTY()
	UHazeCameraSpringArmSettingsDataAsset SwingUpCamSettings;

	UPROPERTY()
	UCurveFloat CameraFractionCurve;

	UPlayerZipKiteSettings Settings;

	FZipKitePlayerData PlayerKiteData;
	FZipKiteAnimData AnimData;
	UZipKitePointComponent ZipKiteToForceActivate = nullptr;
	AZipKiteFocusActor FocusActor;
	UPlayerMovementComponent MoveComp;

	UPROPERTY(BlueprintReadOnly)
	float CurrentMashSpeedMultiplier = 0.0;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Settings = UPlayerZipKiteSettings::GetSettings(Cast<AHazeActor>(Owner));
		MoveComp = UPlayerMovementComponent::Get(Owner);
	}

	FVector GetRopeAttachLocationAtDistance(float Distance) const
	{
		return CurrentKite.RuntimeSplineRope.GetLocationAtDistance(Distance);
	}

	//Returns a yaw rotation
	FRotator GetRopeAttachRotationAtDistance(float Distance) const
	{
		FRotator RopeAttachRot = CurrentKite.RuntimeSplineRope.GetRotationAtDistance(Distance);
		RopeAttachRot.Roll = 0.0;
		RopeAttachRot.Pitch = 0.0;

		return RopeAttachRot;
	}

	FVector CalculateTargetPlayerLocation() const
	{
		return GetRopeAttachLocationAtDistance(PlayerKiteData.CurrentDistance)
			 + (GetRopeAttachRotationAtDistance(PlayerKiteData.CurrentDistance).ForwardVector * PlayerKiteData.CurrentKite.ZipOffset.X)
			 	 + (GetRopeAttachRotationAtDistance(PlayerKiteData.CurrentDistance).RightVector * PlayerKiteData.CurrentKite.ZipOffset.Y)
				 	 + (MoveComp.WorldUp * PlayerKiteData.CurrentKite.ZipOffset.Z) + (MoveComp.WorldUp * (AnimData.MashRate * Settings.AdditionalMashPlayerVerticalOffset));
	}
}

struct FZipKitePlayerData
{
	EZipKitePlayerStates PlayerState;
	AZipKite CurrentKite;

	float CurrentDistance;

	void ResetData()
	{
		CurrentKite = nullptr;
		CurrentDistance = 0;
		PlayerState = EZipKitePlayerStates::Inactive;
	}
}

struct FZipKiteAnimData
{
	UPROPERTY()
	FVector2D SwingBSValues;

	UPROPERTY()
	float SwingAngle;

	UPROPERTY()
	FRotator SwingRotation;

	UPROPERTY()
	FVector2D RelativeVelocity;

	UPROPERTY()
	float MashRate;
	
	void ResetData()
	{
		SwingBSValues = FVector2D(0, 0);
		MashRate = 0;
		SwingAngle = 0;
		SwingRotation = FRotator::ZeroRotator;
	}
}

enum EZipKitePlayerStates
{
	Inactive,
	Enter,
	ZipLining,
	SwingUp,
	AerialExit
}