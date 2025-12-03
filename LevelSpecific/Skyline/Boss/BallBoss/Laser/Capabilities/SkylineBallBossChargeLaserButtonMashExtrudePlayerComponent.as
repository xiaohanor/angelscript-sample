enum ESkylineBallBossPlayerMashState
{
	None,
	Enter,
	Mashing,
	Cancel,
}

UCLASS(Abstract)
class USkylineBallBossChargeLaserButtonMashExtrudePlayerComponent : UActorComponent
{
	UPROPERTY(EditDefaultsOnly)
	FSkylineChargeLaserButtonMashAnimationSettings AnimationSettings;

	UPROPERTY(EditDefaultsOnly)
	UHazeCameraSpringArmSettingsDataAsset CameraSettings;

	ASkylineBallBossChargeLaser MashedLaser = nullptr;
	bool bDoBackflip = false;

	ESkylineBallBossPlayerMashState MashState;
}

struct FSkylineChargeLaserButtonMashAnimationSettings
{
	UPROPERTY(EditAnywhere)
	UAnimSequence EnterAnimation;

	UPROPERTY(EditAnywhere, DisplayName = "MH Animation")
	UAnimSequence MHAnimation;

	UPROPERTY(EditAnywhere)
	FHazePlayBlendSpaceData StruggleBlendSpace;

	UPROPERTY(EditAnywhere)
	UAnimSequence CancelAnimation;

	UPROPERTY(EditAnywhere)
	UAnimSequence BackflipAnimation;

	UPROPERTY(EditAnywhere)
	float BlendTime = 0.2;

	UPROPERTY(EditAnywhere, AdvancedDisplay)
    EHazeBlendType BlendType = EHazeBlendType::BlendType_Inertialization;
};