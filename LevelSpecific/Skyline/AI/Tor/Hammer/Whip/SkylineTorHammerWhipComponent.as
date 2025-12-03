class USkylineTorHammerWhipComponent : UActorComponent
{
	UPROPERTY(EditDefaultsOnly)
	UHazeCameraSpringArmSettingsDataAsset WhipAttackCameraSettings;

	UPROPERTY(EditDefaultsOnly)
	UHazeCameraSpringArmSettingsDataAsset GrabMashCameraSettings;

	bool bThrow;
	bool bAttack;
}