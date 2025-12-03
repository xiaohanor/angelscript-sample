UCLASS(Meta = (ComposeSettingsOnto = "UTeenDragonRollSettings"))
class UTeenDragonRollSettings : UHazeComposableSettings
{
	UPROPERTY(Category = "Input")
	FName RollInputActionName = ActionNames::PrimaryLevelAbility;

	// WIND UP
	// Time before roll reaches start speed (Cannot collide during windup)
	UPROPERTY(Category = "Roll Start")
	float RollWindUpTime = 0.2;

	// Turning steering speed left/right when winding up
	UPROPERTY(Category = "Roll Start")
	float WindUpTurnRate = 800.0;
	
	// The speed you have when windup is done
	UPROPERTY(Category = "Roll Start")
	float RollStartSpeed = 2200.0;
	
	// Curve for acceleration at start of roll
	UPROPERTY(Category = "Roll Start")
	FRuntimeFloatCurve RollStartSpeedCurve;
	default RollStartSpeedCurve.AddDefaultKey(0.0, 0.0);
	default RollStartSpeedCurve.AddDefaultKey(1.0, 1.0);
	// ***

	// Cooldown after rolling before we can roll again
	UPROPERTY(Category = "Speed")
	float RollCooldown = 0.2;

	// Minimum duration the roll lasts for
	UPROPERTY(Category = "Speed")
	float RollMinDuration = 0.5;

	// Turning steering speed left/right when going at the minimum speed
	UPROPERTY(Category = "Speed")
	float RollTurnRateMinSpeed = 280.0;

	// Turning steering speed left/right when at the maximum speed
	UPROPERTY(Category = "Speed")
	float RollTurnRateMaxSpeed = 100.0;

	// If our speed drops below this, stop rolling
	UPROPERTY(Category = "Speed")
	float MinimumRollSpeed = 1800.0;

	// Maximum speed (Cannot exceed this from slopes)
	UPROPERTY(Category = "Speed")
	float MaximumRollSpeed = 3500.0;

	
	UPROPERTY(Category = "Speed")
	float RollUnderSpeedAcceleration = 2000.0;
	
	UPROPERTY(Category = "Speed")
	float RollOverSpeedDeceleration = 500.0;

	// Speed lost while on ground
	UPROPERTY(Category = "Speed")
	float BaseFloorSpeedLoss = 400.0;

	// Speed gained going down slopes multiplier
	UPROPERTY(Category = "Speed")
	float GravityDownSlopeMultiplier = 0.8;

	// Speed lost going up slopes multiplier
	UPROPERTY(Category = "Speed")
	float GravityUpSlopeMultiplier = 0.7;

	// Damage dealt to enemies hit by the roll impact
	UPROPERTY(Category = "Speed")
 	float RollImpactDamage = 0.5;

	UPROPERTY(Category = "Speed")
	float RollSidewaysDecelerationSpeed = 5.2;


	// CAMERA FOLLOW
	/** Speed at which the camera follow starts following */
	UPROPERTY(Category = "Camera Follow")
	float CameraFollowMinRollingSpeed = 2000.0;

	/** How fast the rolling needs to go for the minimum camera follow time */
	UPROPERTY(Category = "Camera Follow")
	float CameraFollowRollingSpeedForMinDuration = 3000.0;

	/** How long the camera takes to go to the velocity direction, when at the minimum speed
	 * Value is lerped between min rolling speed and the speed for min duration
	 */
	UPROPERTY(Category = "Camera Follow")
	float CameraFollowMinDuration = 3.0;

	UPROPERTY(Category = "Camera Follow")
	float CameraFollowMaxDuration = 7.0;

	UPROPERTY(Category = "Camera Follow")
	float CameraFollowPitchMinDuration = 4.0;

	UPROPERTY(Category = "Camera Follow")
	float CameraFollowPitchMaxDuration = 14.0;

	/** How long the camera stays after player giving camera input */
	UPROPERTY(Category = "Camera Follow")
	float CameraFollowDelayAfterInput = 1.0;

	UPROPERTY(Category = "Camera Follow")
	float CameraFollowPitchDownDegrees = 15.0;

	UPROPERTY(Category = "Camera Follow")
	FHazeRange CameraFollowPitchRange = FHazeRange(-40, -10.0);


	// CAMERA LEAN
	UPROPERTY(Category = "Camera Lean")
	float CameraLeanMaxDegrees = 2.5;

	UPROPERTY(Category = "Camera Lean")
	float CameraLeanDeactivateAccelerateDuration = 1.0;

	UPROPERTY(Category = "Camera Lean")
	float CameraLeanMinSpeed = 2000.0;

	UPROPERTY(Category = "Camera Lean")
	float CameraLeanSpeedForMinDuration = 3000.0;

	UPROPERTY(Category = "Camera Lean")
	float CameraLeanMinDuration = 1.0;

	UPROPERTY(Category = "Camera Lean")
	float CameraLeanMaxDuration = 2.0;

	UPROPERTY(Category = "Camera Lean")
	float CameraLeanMaxInput = 0.2;

	// JUMP
	// Turning steering speed left/right while in air
	UPROPERTY(Category = "Jump")
	float RollAirTurnRate = 50.0;

	// Speed upwards gained on jump
	UPROPERTY(Category = "Jump")
	float RollJumpImpulse = 2200.0;

	UPROPERTY(Category = "Jump")
	float RollSidewaysInputAcceleration = 4000.0;

	UPROPERTY(Category = "Air Movement")
	float RollSidewaysMaxSpeed = 1000.0;

	UPROPERTY(Category = "Air Movement")
	float RollImpulseInputMaxSpeed = 1500.0;


	// BOUNCE
	UPROPERTY(Category = "Bounce")
	bool bShouldBounce = true;

	UPROPERTY(Category = "Bounce")
	bool bShouldOnlyBounceOnce = true;

	UPROPERTY(Category = "Bounce")
	float BounceVerticalSpeedThreshold = 3500.0;

	UPROPERTY(Category = "Bounce")
	float MinBounceSpeed = 300.0;

	UPROPERTY(Category = "Bounce")
	float MaxBounceSpeed = 600.0;

	UPROPERTY(Category = "Bounce")
	float BounceRestitution = 0.25;


	// How much the dragon jumps up when the attack is started 
	UPROPERTY(Category = "Homing")
	float HomingAttackJumpUpImpulse = 2000.0;	

	// How fast the dragon is launched towards the target
	UPROPERTY(Category = "Homing")
	float HomingAttackForwardLaunchImpulse = 5000.0; 

	/** The maximum height the homing  */
	UPROPERTY(Category = "Homing")
	float HomingAttackMaxJumpUpHeight = 1000.0;

	/** The minimum height of the jump, when very close to the target */
	UPROPERTY(Category = "Homing")
	float HomingAttackMinJumpUpHeight = 100.0;

	/** At which distance horizontally from the target max height is achieved */
	UPROPERTY(Category = "Homing")
	float HomingAttackMaxJumpUpHeightDistance = 2000.0;

	/** How far towards the target the jump up goes */
	UPROPERTY(Category = "Homing")
	float HomingAttackJumpUpTowardsTargetDistance = 50.0;

	/** How fast the homing attack rotates the camera towards the target */
	UPROPERTY(Category = "Homing")
	float HomingAttackCameraRotationDuration = 0.3;

	/** How fast the Dragon rotates towards the target */
	UPROPERTY(Category = "Homing")
	float HomingAttackRotationInterpSpeed = 7.5;
}

asset TeenDragonRollSteppingSettings of UMovementSteppingSettings
{
	StepDownSize = FMovementSettingsValue::MakePercentage(0.3);
	bOverride_StepUpSize = true;
	StepUpSize = FMovementSettingsValue::MakePercentage(1.0);
	bOverride_bSweepStep = true;
	bSweepStep = false;
}

asset TeenDragonRollStandardMovementSettings of UMovementStandardSettings
{
	WalkableSlopeAngle = 50.0;
}
