class USanctuaryGhostAttackResponseComponent : UActorComponent
{
	TInstigated<bool> bIsAttacked;
	default bIsAttacked.DefaultValue = false;

	TInstigated<bool> bIsLifted;
	default bIsLifted.DefaultValue = false;

	TInstigated<ASanctuaryGhost> Ghosts;

	UPROPERTY(EditDefaultsOnly)
	UHazeCameraSettingsDataAsset CameraSettings;

	UPROPERTY(EditDefaultsOnly)
	TSubclassOf<UCameraShakeBase> CameraShake;

	UPROPERTY(EditDefaultsOnly)
	UForceFeedbackEffect ForceFeedbackEffect;

	UPROPERTY(EditDefaultsOnly)
	UAnimSequence LiftAnim;

	UPROPERTY(EditInstanceOnly)
	float SpeedScaleMin = 0.01;
};