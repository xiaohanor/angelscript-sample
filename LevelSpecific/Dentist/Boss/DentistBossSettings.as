class UDentistBossSettings : UHazeComposableSettings
{
	UPROPERTY(Category = "States")
	EDentistBossState InitialState = EDentistBossState::Start;

	UPROPERTY(Category = "Health")
	float TotalHealthPerArm = 0.5;

	UPROPERTY(Category = "Finisher")
	FButtonMashSettings DrillFinisherButtonMashSettings;
	default DrillFinisherButtonMashSettings.ButtonAction = ActionNames::Interaction;
	default DrillFinisherButtonMashSettings.ProgressionMode = EButtonMashProgressionMode::MashToProceedOnly;
	default DrillFinisherButtonMashSettings.Mode = EButtonMashMode::ButtonMash;
	default DrillFinisherButtonMashSettings.bAllowPlayerCancel = false;
	default DrillFinisherButtonMashSettings.bBlockOtherGameplay = true;
	default DrillFinisherButtonMashSettings.bShowButtonMashWidget = true;;
	default DrillFinisherButtonMashSettings.Duration = 20.0;
	
	UPROPERTY(Category = "Finisher")
	float DrillFinisherButtonMashProgressDuration = 0.5;

	UPROPERTY(Category = "Finisher")
	FHazePlayBlendSpaceParams MioDrillFinisherPushBSParams;

	UPROPERTY(Category = "Finisher")
	FHazePlayBlendSpaceParams ZoeDrillFinisherPushBSParams;

	UPROPERTY(Category = "Finisher")
	FHazePlaySlotAnimationParams MioDrillFinisherExitParams;

	UPROPERTY(Category = "Finisher")
	FHazePlaySlotAnimationParams ZoeDrillFinisherExitParams;

	// LOOK	
	/** How long it takes to look at the player while it has it as target */
	UPROPERTY(Category = "Look")
	float LookDuration = 0.5;

	/** How long it takes to look at the player when switching target */
	UPROPERTY(Category = "Look")
	float SwitchTargetDuration = 0.15;

	/** How long it takes to swap between targets when it doesn't have one specified */
	UPROPERTY(Category = "Look")
	float FallbackTargetSwapDelay = 5.0;

	UPROPERTY(Category = "Look")
	FDentistBossHeadlightSettings HasTargetSpotlightSettings;
	default HasTargetSpotlightSettings.Intensity = 20.0;
	default HasTargetSpotlightSettings.InnerConeAngle = 2.0;
	default HasTargetSpotlightSettings.OuterConeAngle = 6.0;
	default HasTargetSpotlightSettings.LightColor = FLinearColor(0.74, 0.09, 0.09);


	UPROPERTY(Category = "Look")
	FDentistBossHeadlightSettings HasNoTargetSpotlightSettings;
	default HasNoTargetSpotlightSettings.Intensity = 20.0;
	default HasNoTargetSpotlightSettings.InnerConeAngle = 2.0;
	default HasNoTargetSpotlightSettings.OuterConeAngle = 6.0;
	default HasNoTargetSpotlightSettings.LightColor = FLinearColor(1.00, 1.00, 1.00);

	// DRILL
	/** The Arm which the drill attaches to at the start */
	UPROPERTY(Category = "Drill")
	EDentistBossArm DrillArm = EDentistBossArm::LeftTop;

	/** The rotation speed of the drill when it's active */
	UPROPERTY(Category = "Drill")
	float DrillSpeed = -1000.0;

	/** How long it take for the drill to move back after attacking */
	UPROPERTY(Category = "Drill")
	float DrillMoveBackDuration = 0.1;

	/** How long the drill takes to move when it's attacking */
	UPROPERTY(Category = "Drill")
	float DrillAttackMoveDuration = 0.3;

	/** How much damage the drill does when it's drilling a player */
	UPROPERTY(Category = "Drill")
	float DrillDamagePerSecond = 0.25;

	UPROPERTY(Category = "Drill")
	bool bDrillCanKill = false;

	/** The difficulty of the buttonmash when being drilled */
	UPROPERTY(Category = "Drill")
	FButtonMashSettings DrillButtonMashSettings;
	default DrillButtonMashSettings.Mode = EButtonMashMode::ButtonMash;
	default DrillButtonMashSettings.Difficulty = EButtonMashDifficulty::Medium;
	default DrillButtonMashSettings.ButtonAction = ActionNames::Interaction;
	default DrillButtonMashSettings.ProgressionMode = EButtonMashProgressionMode::MashToProgress;
	default DrillButtonMashSettings.bAllowPlayerCancel = false;
	default DrillButtonMashSettings.bBlockOtherGameplay = true;
	default DrillButtonMashSettings.bShowButtonMashWidget = true;

	/** Camera shake which is active while being drilled */
	UPROPERTY(Category = "Drill")
	TSubclassOf<UCameraShakeBase> BeingDrilledCameraShake;

	/** The Force feedback when being drilled */
	UPROPERTY(Category = "Drill")
	UForceFeedbackEffect BeingDrilledForceFeedback;

	UPROPERTY(Category = "Drill")
	UHazeCameraSettingsDataAsset BeingDrilledCameraSettings;

	UPROPERTY(Category = "Drill")
	float BeingDrilledCameraTiltDegreesMax = 45.0;

	UPROPERTY(Category = "Drill")
	float BeingDrilledCameraTiltGoBackSpeed = 1.0;

	/** Require being hit by dash instead of buttonmash to exit the drill */
	UPROPERTY(Category = "Drill")
	bool bDashExitOutOfDrill = true;

	UPROPERTY(Category = "Drill")
	FTutorialPrompt DashOutOfDrillPrompt;
	default DashOutOfDrillPrompt.Action = ActionNames::MovementDash;
	default DashOutOfDrillPrompt.Mode = ETutorialPromptMode::Default;
	default DashOutOfDrillPrompt.Text = NSLOCTEXT("Dentist Boss", "Drill Dash Tutorial","Dash");
	default DashOutOfDrillPrompt.MaximumDuration = -1;

	UPROPERTY(Category = "Drill")
	float DrillMoveToAboveCakeDuration = 1.0;

	UPROPERTY(Category = "Drill")
	float DrillImpaleCakeDuration = 0.2;

	UPROPERTY(Category = "Drill")
	float DrillSpinCakeDuration = 3.0;

	UPROPERTY(Category = "Drill")
	float DrillCakeMoveBackDuration = 0.5;

	UPROPERTY(Category = "Drill")
	float DrillFindPlayerDelay = 2.0; 

	UPROPERTY(Category = "Drill")
	float DrillSplitOtherPlayerDuration = 15.0;


	UPROPERTY(Category = "Drill")
	FRuntimeFloatCurve DrillMoveThroughPlayerCurve;
	default DrillMoveThroughPlayerCurve.AddDefaultKey(0.0, 0.0);
	default DrillMoveThroughPlayerCurve.AddDefaultKey(0.985, 0.3);
	default DrillMoveThroughPlayerCurve.AddDefaultKey(1.0, 1.0);

	// CHAIR
	/** If escaping the chair is stick wiggle (otherwise is buttonmash) */
	UPROPERTY(Category = "Chair")
	bool bChairStickWiggleEscape = true;

	UPROPERTY(Category = "Chair")
	FStickWiggleSettings ChairStickWiggleSettings;
	default ChairStickWiggleSettings.bAllowPlayerCancel = false;
	default ChairStickWiggleSettings.bBlockOtherGameplay = true;
	default ChairStickWiggleSettings.bShowStickSpinWidget = true;
	default ChairStickWiggleSettings.WidgetPositionOffset = FVector(0.0, 0.0, 350.0);
	default ChairStickWiggleSettings.WiggleIntensityIncreaseTime = 5;
	default ChairStickWiggleSettings.WiggleIntensityDecreaseTime = 0.5;
	default ChairStickWiggleSettings.bChunkProgress = true;
	default ChairStickWiggleSettings.WigglesRequired = 30;

	UPROPERTY(Category = "Chair")
	FVector ChairWiggleTutorialPromptOffset = FVector(-200.0, 0.0, 375);

	/** Button mash settings to get out of chair */
	UPROPERTY(Category = "Chair")
	FButtonMashSettings ChairButtonMashSettings;
	default ChairButtonMashSettings.bAllowPlayerCancel = false;
	default ChairButtonMashSettings.bBlockOtherGameplay = true;
	default ChairButtonMashSettings.bShowButtonMashWidget = true;
	default ChairButtonMashSettings.Difficulty = EButtonMashDifficulty::Hard;
	default ChairButtonMashSettings.ProgressionMode = EButtonMashProgressionMode::MashToProgress;
	default ChairButtonMashSettings.ButtonAction = ActionNames::Interaction;

	UPROPERTY(Category = "Chair")
	FRotator ChairAdditionalRotationAtFullWiggle = FRotator(0, 40, 40);

	UPROPERTY(Category = "Chair")
	float ChairWiggleRotationFraction = 0.1;


	// GRABBER
	/** How many Ground Pounds you need to do before grabber gets destroyed */
	UPROPERTY(Category = "Grabber")
	float GrabberGroundPoundedDamageTaken = 0.34;

	UPROPERTY(Category = "Grabber")
	TSubclassOf<UCameraShakeBase> ArmExplosionCameraShake;

	UPROPERTY(Category = "Grabber")
	UForceFeedbackEffect ArmExplosionRumble;


	// DENTURES
	UPROPERTY(Category = "Dentures")
	bool bPlayersImmortalToDenturesDuringDash = true;

	UPROPERTY(Category = "Dentures")
	int DenturesTimesHitToDie = 3;

	UPROPERTY(Category = "Dentures")
	float DenturesShakeDurationAfterHit = 0.5;

	UPROPERTY(Category = "Dentures")
	bool bDenturesShakeStagger = true;

	UPROPERTY(Category = "Dentures")
	FVector DenturesShakeFrequency = FVector(29.0, 37.0, 12.0);

	UPROPERTY(Category = "Dentures")
	FVector DenturesShakeMagnitude = FVector(23.0, 39.0, 17.0);

	UPROPERTY(Category = "Dentures")
	FRuntimeFloatCurve DenturesShakeCurve;
	default DenturesShakeCurve.AddDefaultKey(0.0, 0.0);
	default DenturesShakeCurve.AddDefaultKey(0.1, 1.0);
	default DenturesShakeCurve.AddDefaultKey(1.0, 0.0);

	UPROPERTY(Category = "Dentures")
	bool bRefreshStaggerOnHit = true;

	UPROPERTY(Category = "Dentures")
	int DenturesJumpsBeforeRecharge = 5;

	UPROPERTY(Category = "Dentures")
	float DenturesJumpRechargeDuration = 5.5;

	UPROPERTY(Category = "Dentures")
	float DenturesRechargeRotateBackDuration = 0.5;

	UPROPERTY(Category = "Dentures")
	float DenturesWindupRotationSpeed = 500.0;

	UPROPERTY(Category = "Dentures")
	float DenturesWindDownRotationSpeed = 200.0;

	/** How long the dentures jump towards players depending on energy alpha */
	UPROPERTY(Category = "Dentures")
	FHazeRange DenturesJumpLength = FHazeRange(700.0, 700.0);

	UPROPERTY(Category = "Dentures")
	float DenturesLastJumpLength = 700.0;

	/** How high the dentures jump towards players depending on energy alpha */
	UPROPERTY(Category = "Dentures")
	FHazeRange DenturesJumpHeight = FHazeRange(250.0, 250.0);

	UPROPERTY(Category = "Dentures")
	float DenturesLastJumpHeight = 390.0;

	/** How long it takes for the dentures to rotate towards the players before jumping */
	UPROPERTY(Category = "Dentures")
	FHazeRange DenturesJumpRotateDuration = FHazeRange(0.6, 0.3);

	UPROPERTY(Category = "Dentures")
	float DenturesPlayerStandingOnImpulseUpwards = 1500.0;

	/** How long before the dentures start jumping towards players after initially landing */
	UPROPERTY(Category = "Dentures")
	float DenturesInitialCooldownLandingOnGround = 0.8;

	/** How long between jumps, depending on energy alpha */
	UPROPERTY(Category = "Dentures")
	FHazeRange DenturesJumpCooldown = FHazeRange(0.6, 0.3);

	/** How fast the dentures rotate towards where you are aiming when you are riding them */
	UPROPERTY(Category = "Dentures")
	float DenturesRidingRotationSpeed = 200;

	UPROPERTY(Category = "Dentures")
	float DenturesRidingJumpForwardSize = 1000.0;

	UPROPERTY(Category = "Dentures")
	float DenturesRidingJumpUpwardsSize = 1500.0;

	UPROPERTY(Category = "Dentures")
	FRuntimeFloatCurve DenturesDragCurve;
	default DenturesDragCurve.AddDefaultKey(0.0, 0.0);
	default DenturesDragCurve.AddDefaultKey(0.7, 0.0);
	default DenturesDragCurve.AddDefaultKey(1.0, 1.0);
	
	UPROPERTY(Category = "Dentures")
	float DenturesDragForwardLength = 500.0;

	UPROPERTY(Category = "Dentures")
	FRuntimeFloatCurve DenturesDragHeightCurve;
	default DenturesDragHeightCurve.AddDefaultKey(0.0, 0.0);
	default DenturesDragHeightCurve.AddDefaultKey(0.7, 1.0);
	default DenturesDragHeightCurve.AddDefaultKey(1.0, 0.0);

	UPROPERTY(Category = "Dentures")
	float DenturesDragMaxHeight = 500.0;

	UPROPERTY(Category = "Dentures")
	FRuntimeFloatCurve DenturesDragPitchCurve;
	default DenturesDragPitchCurve.AddDefaultKey(0.0, 0.0);
	default DenturesDragPitchCurve.AddDefaultKey(0.7, 1.0);
	default DenturesDragPitchCurve.AddDefaultKey(1.0, 0.0);

	UPROPERTY(Category = "Dentures")
	float DenturesDragMaxPitch = 20.0;

	UPROPERTY(Category = "Dentures")
	FButtonMashSettings DenturesBitingButtonMashSettings;
	default DenturesBitingButtonMashSettings.Difficulty = EButtonMashDifficulty::Medium;
	default DenturesBitingButtonMashSettings.ProgressionMode = EButtonMashProgressionMode::MashToProgress;
	default DenturesBitingButtonMashSettings.Mode = EButtonMashMode::ButtonMash;
	default DenturesBitingButtonMashSettings.ButtonAction = ActionNames::PrimaryLevelAbility;
	default DenturesBitingButtonMashSettings.bAllowPlayerCancel = false;
	default DenturesBitingButtonMashSettings.bBlockOtherGameplay = true;
	default DenturesBitingButtonMashSettings.Duration = 2.0;

	UPROPERTY(Category = "Dentures")
	float DenturesBitingRotateDuration = 0.2;

	UPROPERTY(Category = "Dentures")
	float DenturesBitingRotateMaxDegrees = 40.0;

	UPROPERTY(Category = "Dentures")
	FRuntimeFloatCurve DenturesBitingRotateCurve;
	default DenturesBitingRotateCurve.AddDefaultKey(0.0, 1.0);
	default DenturesBitingRotateCurve.AddDefaultKey(0.3, 0.0);
	default DenturesBitingRotateCurve.AddDefaultKey(1.0, 1.0);

	UPROPERTY(Category = "Dentures")
	float DenturesHitPlayerForwardImpulse = 3600.0;

	UPROPERTY(Category = "Dentures")
	float DenturesHitPlayerUpImpulse = 1800.0;
	
	UPROPERTY(Category = "Dentures")
	FDentistToothApplyRagdollSettings DenturesHitPlayerRagdollSettings;
	default DenturesHitPlayerRagdollSettings.bApplyRagdoll = true;
	default DenturesHitPlayerRagdollSettings.AngularImpulseMultiplier = 1.5;
	default DenturesHitPlayerRagdollSettings.RagdollDuration = 2.0;

	UPROPERTY(Category = "Dentures")
	float DenturesHitPlayerDamage = 0.5;

	UPROPERTY(Category = "Dentures")
	FTutorialPrompt DenturesTutorial;
	default DenturesTutorial.Action = ActionNames::PrimaryLevelAbility;
	default DenturesTutorial.Mode = ETutorialPromptMode::Default;
	default DenturesTutorial.Text = NSLOCTEXT("Dentist Boss", "Dentures Tutorial", "Attack");
	default DenturesTutorial.DisplayType = ETutorialPromptDisplay::Action;

	// SCRAPER
	/** The Camera shake when the hook lands on the player*/
	UPROPERTY(Category = "Scraper")
	TSubclassOf<UCameraShakeBase> HookedPlayerCameraShake;

	/** The Force feedback when the hook lands on the player*/
	UPROPERTY(Category = "Scraper")
	UForceFeedbackEffect HookedPlayerForceFeedback;

	/** The Camera shake when the tooth is split*/
	UPROPERTY(Category = "Scraper")
	TSubclassOf<UCameraShakeBase> ToothSplitCameraShake;

	/** The Force feedback when the tooth is split*/
	UPROPERTY(Category = "Scraper")
	UForceFeedbackEffect ToothSplitForceFeedback;

	UPROPERTY(Category = "Scraper")
	TSubclassOf<UCameraShakeBase> HammerHitScraperCameraShake;

	UPROPERTY(Category = "Scraper")
	UForceFeedbackEffect HammerHitScraperForceFeedback;

	UPROPERTY(Category = "Scraper")
	float HammerHitScraperDamage = 0.2;

	UPROPERTY(Category = "Scraper")
	float ToothSplitDamage = 0.35;


	// CUP ATTACK
	UPROPERTY(Category = "Cup Attack")
	FTutorialPrompt DashToOpenCupPrompt;
	default DashToOpenCupPrompt.Action = ActionNames::MovementDash;
	default DashToOpenCupPrompt.Mode = ETutorialPromptMode::Default;
	default DashToOpenCupPrompt.Text = NSLOCTEXT("Dentist Boss", "Cup Attack Dash Tutorial","Dash");
	default DashToOpenCupPrompt.MaximumDuration = -1;
	
	UPROPERTY(Category = "Cup Attack")
	FVector DashToOpenPromptOffset = FVector(DentistBossMeasurements::CupHeight * 0.5, 0.0, 0.0);

	UPROPERTY(Category = "Cup Attack")
	float CupDisappearDelayAfterFlattened = 0.5;

	UPROPERTY(Category = "Cup Attack")
	FButtonMashSettings CupPlayerFlattenedButtonMashSettings;
	default CupPlayerFlattenedButtonMashSettings.Difficulty = EButtonMashDifficulty::Hard;
	default CupPlayerFlattenedButtonMashSettings.ProgressionMode = EButtonMashProgressionMode::MashToProgress;
	default CupPlayerFlattenedButtonMashSettings.Mode = EButtonMashMode::ButtonMash;
	default CupPlayerFlattenedButtonMashSettings.ButtonAction = ActionNames::Interaction;
	default CupPlayerFlattenedButtonMashSettings.bAllowPlayerCancel = false;
	default CupPlayerFlattenedButtonMashSettings.bBlockOtherGameplay = true;
	default CupPlayerFlattenedButtonMashSettings.Duration = 1.5;

	UPROPERTY(Category = "Cup Attack")
	float CupSmashMinScale = 0.05;

	UPROPERTY(Category = "Cup Attack")
	FVector CupSmashedPlayerScale = FVector(0.2, 1.5, 1.5);

	UPROPERTY(Category = "Cup Attack")
	FRuntimeFloatCurve CupSmashedPlayerScaleCurve;
	default CupSmashedPlayerScaleCurve.AddDefaultKey(0.0, 0.0);
	default CupSmashedPlayerScaleCurve.AddDefaultKey(1.0, 1.0);

	UPROPERTY(Category = "Cup Attack")
	float CupSmashedPlayerButtonMashCompletedImpulseScale = 1000.0;

	UPROPERTY(Category = "Cup Attack")
	TSubclassOf<UCameraShakeBase> CupFlattenPlayerCameraShake;

	UPROPERTY(Category = "Cup Attack")
	UForceFeedbackEffect CupFlattenPlayerForceFeedback;

	UPROPERTY(Category = "Cup Attack")
	float CupFlattenPlayerDamage = 0.99;



	// TOOTH BRUSH
	UPROPERTY(Category = "Tooth Brush")
	float ToothBrushHorizontalImpulseSize = 3000.0;

	UPROPERTY(Category = "Tooth Brush")
	float ToothBrushVerticalImpulseSize = 1500.0;


	// TOOTH PASTE TUBE
	UPROPERTY(Category = "Tooth Paste Tube")
	float ToothPasteGlobGravityAmount = 3000.0;

	UPROPERTY(Category = "Tooth Paste Tube")
	float ToothPasteGlobHorizontalSpeed = 3000.0;

	UPROPERTY(Category = "Tooth Paste Tube")
	FStickWiggleSettings ToothPasteGlobStickWiggleSettings;
	default ToothPasteGlobStickWiggleSettings.bAllowPlayerCancel = false;
	default ToothPasteGlobStickWiggleSettings.bBlockOtherGameplay = true;
	default ToothPasteGlobStickWiggleSettings.bShowStickSpinWidget = true;
	default ToothPasteGlobStickWiggleSettings.WiggleIntensityIncreaseTime = 2.0;
	default ToothPasteGlobStickWiggleSettings.WiggleIntensityDecreaseTime = 0.5;
	default ToothPasteGlobStickWiggleSettings.bChunkProgress = true;
	default ToothPasteGlobStickWiggleSettings.WigglesRequired = 15;


	UPROPERTY(Category = "Tooth Paste Tube")
	float TimeStuckInToothPasteGlobBeforeDrill = 1.0;

	UPROPERTY(Category = "Tooth Paste Tube")
	float ToothPasteGlobSuckInPlayerSpeed = 15.0;

	UPROPERTY(Category = "Tooth Paste Tube")
	int ToothPasteCount = 10;

	UPROPERTY(Category = "Tooth Paste Tube")
	bool bDrillPlayersStuckInToothPaste = false;

	UPROPERTY(Category = "Tooth Paste Tube")
	float ToothPasteScaleUpTime = 0.5; 

	UPROPERTY(Category = "Split Tooth")
	FApplyPointOfInterestSettings SplitToothPoISettings;
	default SplitToothPoISettings.BlendInAccelerationType = ECameraPointOfInterestAccelerationType::Fast;
	default SplitToothPoISettings.Duration = 3.0;
	default SplitToothPoISettings.ClearOnInput = SplitToothPoIClearOnInputSettings;

	UPROPERTY(Category = "Split Tooth")
	UCameraPointOfInterestClearOnInputSettings SplitToothPoIClearOnInputSettings;
}

struct FDentistBossHeadlightSettings
{
	float Intensity = 20;
	float InnerConeAngle = 0.0;
	float OuterConeAngle = 12.0;
	FLinearColor LightColor = FLinearColor(1.00, 1.00, 1.00);

	void LerpSettings(FDentistBossHeadlightSettings A, FDentistBossHeadlightSettings B, float Alpha)
	{
		Intensity = Math::Lerp(A.Intensity, B.Intensity, Alpha);
		InnerConeAngle = Math::Lerp(A.InnerConeAngle, B.InnerConeAngle, Alpha);
		OuterConeAngle = Math::Lerp(A.OuterConeAngle, B.OuterConeAngle, Alpha);
		LightColor = Math::Lerp(A.LightColor, B.LightColor, Alpha);
	}

	void ApplySettings(USpotLightComponent Spotlight, UGodrayComponent GodrayComp, ULensFlareComponent LensFlareComp)
	{
		Spotlight.SetIntensity(Intensity);
		Spotlight.InnerConeAngle = InnerConeAngle;
		Spotlight.OuterConeAngle = OuterConeAngle;
		Spotlight.LightColor = LightColor;

		GodrayComp.Template.Color = LightColor;
		GodrayComp.UpdateDynamicMaterialInstance();
		LensFlareComp.Tint = LightColor;
		LensFlareComp.InitDynamicMaterial();
	}
}

asset DentistBossNoHitReactionSettings of UDeathRespawnEffectSettings
{
	bPlayAdditiveDamageAnimations = false;
}