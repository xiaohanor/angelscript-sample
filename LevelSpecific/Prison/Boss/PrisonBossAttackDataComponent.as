class UPrisonBossAttackDataComponent : UActorComponent
{
	UPROPERTY(EditDefaultsOnly, Category = "Attack Classes")
	TSubclassOf<APrisonBossGroundTrailAttack> GroundTrailClass;

	UPROPERTY(EditDefaultsOnly, Category = "Attack Classes")
	TSubclassOf<APrisonBossHackableMagneticProjectile> HackableMagneticProjectileClass;

	UPROPERTY(EditDefaultsOnly, Category = "Attack Classes")
	TSubclassOf<APrisonBossHorizontalSlashActor> HorizontalSlashClass;
	
	UPROPERTY(EditDefaultsOnly, Category = "Attack Classes")
	TSubclassOf<APrisonBossWaveSlashActor> WaveSlashClass;

	UPROPERTY(EditDefaultsOnly, Category = "Attack Classes")
	TSubclassOf<APrisonBossClone> CloneClass;

	UPROPERTY(EditDefaultsOnly, Category = "Attack Classes")
	TSubclassOf<APrisonBossVolleyProjectile> VolleyClass;

	UPROPERTY(EditDefaultsOnly, Category = "Attack Classes")
	TSubclassOf<APrisonBossZigZagAttack> ZigZagClass;

	UPROPERTY(EditDefaultsOnly, Category = "Attack Classes")
	TSubclassOf<APrisonBossDonutAttack> DonutClass;

	UPROPERTY(EditDefaultsOnly, Category = "Attack Classes")
	TSubclassOf<APrisonBossScissorsAttack> ScissorsClass;

	UPROPERTY(EditDefaultsOnly, Category = "Curves")
	UCurveFloat EaseInCurve;

	UPROPERTY(EditDefaultsOnly, Category = "Curves")
	UCurveFloat EaseInOutCurve;

	UPROPERTY(EditDefaultsOnly, Category = "Curves")
	UCurveFloat ScissorsSweepCurve;

	UPROPERTY(EditDefaultsOnly, Category = "Curves")
	UCurveFloat GroundTrailExitCurve;

	UPROPERTY(EditDefaultsOnly, Category = "Curves")
	UCurveFloat GroundTrailExitVerticalCurve;

	UPROPERTY(EditDefaultsOnly, Category = "Curves")
	UCurveFloat SpiralEnterCurve;

	UPROPERTY(EditDefaultsOnly, Category = "Camera")
	UHazeCameraSpringArmSettingsDataAsset CloneCamSettings;

	UPROPERTY(EditDefaultsOnly, Category = "Camera")
	UHazeCameraSpringArmSettingsDataAsset MagneticSlamCamSettings;

	UPROPERTY(EditDefaultsOnly, Category = "Effects")
	UMaterialInterface GroundTrailSlamDecalMaterial;

	UPROPERTY(EditDefaultsOnly, Category = "Effects")
	UMaterialInterface MagneticSlamDecalMaterial;
}