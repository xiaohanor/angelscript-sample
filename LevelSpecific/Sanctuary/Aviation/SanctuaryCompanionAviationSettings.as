
enum EStrangleHydraAttackMode
{
	None = 0,
	ButtonPress,
	ButtonMash,
	StickSpin
}

namespace CompanionAviation
{
	const bool bAviationAllowInvertedFlying = false;
	const bool bProgressToPhase2 = true;
	const bool bProgressToSkydive = false;

	const bool bUseLevelSequenceSwoop = true;

	const int HealthBarHeads = 6;
	const int HeadsToKill = 3;
	const bool bCoopKill = true;
	const bool bFullScreenKill = false;
	const bool bRequireInitiateAttackPrompt = true;
	const bool bAttackCenterHydra = true;

	const float SidescrollingCameraLerpSplineHeightFactor = 0.3;
	const float MegaCompanionScale = 6.0;
}

class UCompanionAviationSettings : UHazeComposableSettings
{
	UPROPERTY(Category = "ButtonMash Kill")
	FVector CoopButtonMashOffset = FVector::ZeroVector;
	UPROPERTY(Category = "ButtonMash Kill")
	bool bCoopButtonmashWidget = true;
	UPROPERTY(Category = "ButtonMash Kill")
	float MinDecayRateSeconds = 10.0;
	UPROPERTY(Category = "ButtonMash Kill")
	float MaxDecayRateSeconds = 5.0;
	UPROPERTY(Category = "ButtonMash Kill")
	float ButtonMashIncrement = 1.0;
	UPROPERTY(Category = "ButtonMash Kill")
	EButtonMashDifficulty ButtonMashDifficulty = EButtonMashDifficulty::Hard;
	UPROPERTY(Category = "ButtonMash Kill")
	FName ButtonMashButton = ActionNames::Interaction;

	UPROPERTY(Category = "StickSpin Kill")
	float StickSpinRequiredVelocity = 0.1;
	UPROPERTY(Category = "StickSpin Kill")
	float StickSpinRequiredDuration = 1.0;
	UPROPERTY(Category = "Misc")
	int FreeOrbsAfterFail = 0;
	UPROPERTY(Category = "Misc")
	float StartAviationImpulseReachAdditionalHeight = 500;

	// "Normal" aviation is when we're NOT in ToAttackMovement / SidewaysSwingMovement / AttackMovement
	UPROPERTY(Category = "Normal Aviation")
	float NormalAviationInterpolateDirectionDuration = 0.5; 
	UPROPERTY(Category = "Normal Aviation")
	float NormalAviationInterpolateDirectionSpeed = 120.0;

	UPROPERTY(Category = "Aviation Speeds")
	float TutorialSpeed = 3000.0;
	UPROPERTY(Category = "Aviation Speeds")
	float EntrySpeed = 10000.0;
	UPROPERTY(Category = "Aviation Speeds")
	float SwoopbackSpeed = 8000.0;
	UPROPERTY(Category = "Aviation Speeds")
	float SidewaysForwardSpeed = 2500.0;
	UPROPERTY(Category = "Aviation Speeds")
	float SidewaysStrafeSpeed = 2000.0;
	UPROPERTY(Category = "Aviation Speeds")
	float ToAttackForwardSpeed = 4000.0; //2000.0;
	UPROPERTY(Category = "Aviation Speeds")
	float InitiateAttackSpeed = 2500;
	UPROPERTY(Category = "Aviation Speeds")
	float StrangleStartSpeed = 14000.0;
	UPROPERTY(Category = "Aviation Speeds")
	float StrangleSlowSpeed = 7000.0;
	UPROPERTY(Category = "Aviation Speeds")
	float StrangleTightenSpeed = StrangleSlowSpeed * 1.5;
	UPROPERTY(Category = "Aviation Speeds")
	float ExitSpeed = 8000.0;

	// SWOOPBACK ARC / See more in ctrl+f BuildEntrySpline. Example of Swoopback runtime spline points:
	// from above
	// ^X        3
	// |     2       4
	// |   1     P     5
	//  -------------------->Y
	// from side
	// ^Z              5 < SwoopbackAdditionalStartHeight + SwoopbackAdditionalEndHeight
	// |             4
	// |         3
	// |     2
	// |   1     P       < SwoopbackAdditionalStartHeight (+ StartAviationImpulseReachAdditionalHeight + player original height)
	//  -------------------->Y
	
	UPROPERTY(Category = "Swoopback")
	float SwoopbackAdditionalStartHeight = 2000;
	UPROPERTY(Category = "Swoopback")
	float SwoopbackAdditionalEndHeight = 1000;
	UPROPERTY(Category = "Swoopback")
	float SwoopbackAdditionalDistance = 5200;
	UPROPERTY(Category = "Swoopback")
	float SwoopbackRadius = 1000;

	UPROPERTY(Category = "ToAttack")
	float ToAttackHeight = 3500;
	UPROPERTY(Category = "ToAttack")
	float ToAttackDistanceStart = 27000; // we want this on 29k but anim needs to make sequence work for that distance first (SPL-4566)
	UPROPERTY(Category = "ToAttack")
	float ToAttackDistanceStopBeforeHydra = 6000.0;
	UPROPERTY(Category = "InitiateAttack")
	float InitiateAttackHeavyAutoSteerInterpolateDirectionDuration = 0.1;

	UPROPERTY(Category = "InitiateAttack")
	float InitiateAttacTutorialWidgetDuration = 2.1;
	UPROPERTY(Category = "InitiateAttack")
	float InitiateAttackWindowDelay = 0.1;
	UPROPERTY(Category = "InitiateAttack")
	float InitiateAttackHeightClockwise = 5500.0;
	UPROPERTY(Category = "InitiateAttack")
	float InitiateAttackHeightCounterClockwise = 4800.0;
	UPROPERTY(Category = "InitiateAttack")
	float InitiateAttackRadius = 3000.0;

	UPROPERTY(Category = "SpeedEffect")
	float SpeedEffectIntensity = 0.2;

	// ⚠️ we currently use SidewaysSwingMovement atm instead. The ToAttackMovement is the more free form variant ⚠️
	// But I'm keeping it around since we're prototyping!
	UPROPERTY(Category = "ToAttackMovement")
	float ToAttackAllowedDistanceFromSpline = 900000.0;
	UPROPERTY(Category = "ToAttackMovement")
	float ToAttackFalloffDistanceFromSpline = 1000.0;
	UPROPERTY(Category = "ToAttackMovement")
	float ToAttackMaxInputWeight = 1.0; // 1 is free flight, 0 is follow spline
	UPROPERTY(Category = "ToAttackMovement")
	float ToAttackMovementPitchMaxAngle = 40.0;
	UPROPERTY(Category = "ToAttackMovement")
	float ToAttackMovementPitchSpringStiffness = 20.0;
	UPROPERTY(Category = "ToAttackMovement")
	float ToAttackMovementPitchSpringDampening = 0.3;
	UPROPERTY(Category = "ToAttackMovement")
	float ToAttackMovementStrafeMaxAngle = 60.0;
	UPROPERTY(Category = "ToAttackMovement")
	float ToAttackMovementStrafeInterpolationDuration = 0.3; // smaller number for more responsive
	UPROPERTY(Category = "ToAttackMovement")
	float ToAttackRotationRollSpeed = 0.0;
	// ToAttack Roll below is mostly visual. Use move speed modifiers above for actual movement ^
	UPROPERTY(Category = "ToAttackMovement")
	float ToAttackRotationRollAccelerationDuration = 0.05;
	UPROPERTY(Category = "ToAttackMovement")
	float ToAttackRotationUnrollSpeed = 800.0;
	UPROPERTY(Category = "ToAttackMovement")
	float ToAttackRotationUnrollAccelerationDuration = 0.1;
	UPROPERTY(Category = "ToAttackMovement")
	bool bToAttackClampRollRotation = true;
	UPROPERTY(Category = "ToAttackMovement")
	float ToAttackClampRollRotationMax = 20;

	// SidewaysSwingMovement feels like 3 lanes, but it's one runtime a spline and offsets to left and right.
	// Seen from above
	// ^X          -               0               +
	// |           -               0               +
	// |           -               0               +
	// |        -Y input           0          +Y input
	// | -SidewaysMovementDistance     +SidewaysMovementDistance
	// |--------------->Y

	// The higher SidewaysArcHeight, you will gain height further from 0 aka at the sides
	// Seen from side
	// ^Z           -                             +
	// |             @                           @ 
	// |                @                    @    
	// |        -Y input    @     0     @     +Y input
	// | -SidewaysMovementDistance     +SidewaysMovementDistance
	// |--------------->Y

	UPROPERTY(Category = "SidewaysSwingMovement")
	float TutorialVerticalMovementDistanceMax = 2000.0;

	UPROPERTY(Category = "SidewaysSwingMovement")
	float VerticalMovementDistanceMax = 2000.0;
	UPROPERTY(Category = "SidewaysSwingMovement")
	float VerticalMovementDistanceMin = 1500.0;
	UPROPERTY(Category = "SidewaysSwingMovement")
	float SidewaysMovementDistanceMax = 2500.0;
	UPROPERTY(Category = "SidewaysSwingMovement")
	float SidewaysMovementDistanceMin = 1400.0;
	UPROPERTY(Category = "SidewaysSwingMovement")
	float SidewaysArcHeight = 100.0;
	UPROPERTY(Category = "SidewaysSwingMovement")
	float SidewaysMovementRoll = 40.0; // we roll inwards
	UPROPERTY(Category = "SidewaysSwingMovement")
	float SidewaysDirectionInterpolationDuration = 0.01;
	UPROPERTY(Category = "SidewaysSwingMovement")
	float SidewaysSpeedInterpolationDuration = 0.2;
	UPROPERTY(Category = "SidewaysSwingMovement")
	float SidewaysPositionInterpolationDuration = 0.05;

	UPROPERTY(Category = "SidewaysSwingMovement")
	float SidewaysHorizontalInputDuration = 3.5;
	UPROPERTY(Category = "SidewaysSwingMovement")
	float SidewaysVerticalInputDuration = 3.5;
	UPROPERTY(Category = "SidewaysSwingMovement")
	float TutorialSidewaysHorizontalInputDuration = 3.5;
	UPROPERTY(Category = "SidewaysSwingMovement")
	float TutorialSidewaysVerticalInputDuration = 3.5;

	UPROPERTY(Category = "SidewaysSwingMovement")
	float SidewaysDeltaMoveSpeed = 5.0;
	UPROPERTY(Category = "SidewaysSwingMovement")
	float SidewaysDeltaMoveDuration = 3.1;

	float Multiplier2 = 0.5;

	UPROPERTY(Category = "SidewaysSwingMovement Camera")
	float CameraVerticalDistanceMax = VerticalMovementDistanceMax * 1.0 * Multiplier2;
	UPROPERTY(Category = "SidewaysSwingMovement Camera")
	float CameraVerticalDistanceMin = VerticalMovementDistanceMin * 1.0 * Multiplier2;
	UPROPERTY(Category = "SidewaysSwingMovement Camera")
	float CameraHorizontalDistanceMax = SidewaysMovementDistanceMax * 0.8 * Multiplier2;
	UPROPERTY(Category = "SidewaysSwingMovement Camera")
	float CameraHorizontalDistanceMin = SidewaysMovementDistanceMin * 0.8 * Multiplier2;

	float Multiplier = 0.5;

	UPROPERTY(Category = "SidewaysSwingMovement Camera")
	float TutorialCameraVerticalDistanceMax = VerticalMovementDistanceMax * Multiplier;
	UPROPERTY(Category = "SidewaysSwingMovement Camera")
	float TutorialCameraVerticalDistanceMin = VerticalMovementDistanceMin * Multiplier;
	UPROPERTY(Category = "SidewaysSwingMovement Camera")
	float TutorialCameraHorizontalDistanceMax = SidewaysMovementDistanceMax * Multiplier;
	UPROPERTY(Category = "SidewaysSwingMovement Camera")
	float TutorialCameraHorizontalDistanceMin = SidewaysMovementDistanceMin * Multiplier;

	UPROPERTY(Category = "Exit Aviation")
	float StopAviationDistance = 300.0; 
	UPROPERTY(Category = "Exit Aviation")
	float PostAttackCameraBlendInTime = 2.0;
	UPROPERTY(Category = "Exit Aviation")
	float PostAttackCameraBlendOutTime = 2.0;

	UPROPERTY(Category = "Strangling Attack")
	bool bStrangleCircleUseBoneZ = false;
	UPROPERTY(Category = "Strangling Attack")
	float EnterStranglingAttackDistance = 12000.0;
	UPROPERTY(Category = "Strangling Attack")
	float StartStranglingPromptDistance = 4000.0;
	UPROPERTY(Category = "Strangling Attack")
	float StartTightenStranglingDistance = 2000.0;
	UPROPERTY(Category = "Strangling Attack")
	float StranglingCameraBlendInTime = 3.0;
	UPROPERTY(Category = "Strangling Attack")
	float StranglingCameraBlendOutTime = 3.0;
	UPROPERTY(Category = "Strangling Attack")
	float StranglingMinRadius = 1400.0;
	UPROPERTY(Category = "Strangling Attack")
	float StranglingMaxRadius = 2500.0;
	UPROPERTY(Category = "Strangling Attack")
	float StranglingIntensifyingDuration = 2.0;
	UPROPERTY(Category = "Strangling Attack")
	float StranglingReceedDuration = 2.0;
	UPROPERTY(Category = "Strangling Attack")
	float StranglingMinAllowedDuration = 3.0;
	UPROPERTY(Category = "Strangling Attack")
	float StrangleSuccessWaitBeforePlayerMoveOn = 0.5;
	UPROPERTY(Category = "Strangling Attack")
	float StrangleSuccessWaitBeforeCameraMoveOn = 3.5;
};

asset SanctuaryAviationTutorialFlyingSidewaysAllowedCurve of UCurveFloat
{
	/*
	    ------------------------------------------------------------------
	1.0 |''''''''''''''''''''''''''''''''''''''''''''''·                 |
	    |                                               '.               |
	    |                                                 ·              |
	    |                                                  .             |
	    |                                                   .            |
	    |                                                                |
	    |                                                    '           |
	    |                                                     '          |
	    |                                                      ·         |
	    |                                                       .        |
	    |                                                                |
	    |                                                        '       |
	    |                                                         '      |
	    |                                                          '     |
	    |                                                           '.   |
	-0.0|                                                             ·..|
	    ------------------------------------------------------------------
	    0.0                                                            1.0
	*/
	AddAutoCurveKey(0.0, 1.0);
	AddCurveKeyBrokenTangent(0.7, 1.0, 0.0, 0.0);
	AddAutoCurveKey(1.0, -0.0);
}
