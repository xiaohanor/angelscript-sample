class UBattlefieldHoverboardTrickSettings : UHazeComposableSettings
{
	UPROPERTY(Category = "Camera Shake")
	TSubclassOf<UCameraShakeBase> TrickStartCameraShake;

	UPROPERTY(Category = "Camera Settings")
	UHazeCameraSettingsDataAsset TrickCameraSettings;

	UPROPERTY(Category = "Trick")
	float TrickGroundValidationTraceLength = 500.0;

	UPROPERTY(Category = "Trick Landing")
	float TrickLandingBoostDuration = 1.0;

	UPROPERTY(Category = "Trick Landing")
	FRuntimeFloatCurve TrickLandingBoostCurve;
	default TrickLandingBoostCurve.AddDefaultKey(0.0, 0.0);
	default TrickLandingBoostCurve.AddDefaultKey(0.5, 1.0);
	default TrickLandingBoostCurve.AddDefaultKey(1.0, 0.0);

	UPROPERTY(Category = "Trick Landing")
	float TrickLandingBoostMaxSpeed = 500.0;

	UPROPERTY(Category = "Trick Landing")
	UHazeCameraSettingsDataAsset TrickLandingCameraSettings;

	UPROPERTY(Category = "Trick Landing")
	TSubclassOf<UCameraShakeBase> TrickLandingCameraShake;

	UPROPERTY(Category = "Trick Landing")
	FHazeCameraImpulse TrickLandingCameraImpulse;
	default TrickLandingCameraImpulse.CameraSpaceImpulse = FVector(-1000, 0.0, 0.0);
	default TrickLandingCameraImpulse.Dampening = 0.75;
	default TrickLandingCameraImpulse.ExpirationForce = 10.0;

	//Max score that the side bar can reach
	UPROPERTY(Category = "Trick Points")
	int TargetScore = 105000;

	UPROPERTY(Category = "Trick Points")
	int PointLossOnDeath = 1000;

	UPROPERTY(Category = "Trick Points")
	FRuntimeFloatCurve ScoreRubberBandingCurve;

	UPROPERTY(Category = "Trick Points")
	int XTrickPointAmount = 200;

	UPROPERTY(Category = "Trick Points")
	int YTrickPointAmount = 750;

	UPROPERTY(Category = "Trick Points")
	int BTrickPointAmount = 300;

	// UPROPERTY(Category = "Trick Points")
	// int GrindJumpPointAmount = 200;

	UPROPERTY(Category = "Trick Points")
	float BarFillStiffness = 150;

	UPROPERTY(Category = "Trick Points")
	float BarFillDamping = 0.5;

	UPROPERTY(Category = "Trick Points")
	float ComboPointUpdateDuration = 0.1;

	UPROPERTY(Category = "Trick Points")
	float ComboMultFallDelay = 0.1;

	UPROPERTY(Category = "Trick Points")
	float ComboPointFallDelay = 0.5;

	UPROPERTY(Category = "Trick Points")
	float ComboPointFallDuration = 0.3;

	UPROPERTY(Category = "Trick Points")
	float ComboPointFadeDelay = 0.5;

	UPROPERTY(Category = "Trick Points")
	float MultFadeDuration = 0.3;

	UPROPERTY(Category = "Trick Points")
	float ComboPointFadeDuration = 0.5;

	UPROPERTY(Category = "Trick Points")
	float GrindTrickPointsPerSecond = 200.0;

	UPROPERTY(Category = "Trick Points")
	float WallRunTrickPointsPerSecond = 300.0;

	UPROPERTY(Category = "Trick Points")
	TSubclassOf<UBattlefieldHoverboardTrickTotalPointsWidget> TotalPointWidgetClass;

	UPROPERTY(Category = "Trick Points")
	TSubclassOf<UBattlefieldHoverboardTrickComboPointsWidget> ComboPointWidgetClass;

	UPROPERTY(Category = "Trick Points")
	TSubclassOf<UBattlefieldHoverboardTrickComboHistoryWidget> ComboHistoryWidgetClass;

	UPROPERTY(Category = "Trick Points")
	TSubclassOf<UBattleFieldHoverboardPointsLostWidget> PointsLostWidget;

	UPROPERTY(Category = "Trick Multiplier")
	float TrickMultiplierIncreasePerDifferentTrick = 0.5;

	UPROPERTY(Category = "Trick Names")
	TMap<EBattlefieldHoverboardTrickType, FText> TrickNames;

	UPROPERTY(Category = "Widget")
	TPerPlayer<FLinearColor> Color2;
};