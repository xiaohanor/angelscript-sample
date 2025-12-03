class UAdultDragonTailSmashModeSettings : UHazeComposableSettings
{
	// STAMINA 

	// How much stamina the Tail Dragon has to Air Dash with
	UPROPERTY()
	float SmashModeStaminaMax = 1.0;

	/**
	* If the value is used, the dash will auto smash without the user giving input.
	* If the value is -1, the 'SmashModeStaminaMax' will be used as auto stamina
	*/
	UPROPERTY()
	float SmashModeAutoStamina = -1;

	// How much the Stamina drains per second while air dashing
	UPROPERTY()
	float SmashModeStaminaDrain = 1.0;

	// How much stamina recharges per second while not air dashing
	UPROPERTY()
	float SmashModeStaminaRecharge = 5.0;

	// At which faction of the stamina the air dash is allowed to activate
	// So as to not spam the activation
	UPROPERTY()
	float SmashModeStaminaActivationThreshold = 0.5;
	
	UPROPERTY()
	TSubclassOf<UHazeUserWidget> ChargeBarWidget;

	// How far away from the root of the dragon the widget gets attached 
	UPROPERTY()
	FVector WidgetAttachOffset = FVector(0, -100 , 250);

	
	UPROPERTY()
	float SmashModeCooldown = 0.4;
	
	UPROPERTY()
	float ImpactDamage = 0.05;

	// ROTATION

	// How fast the wanted pitch is updated
	UPROPERTY()
	float WantedPitchSpeed = 30.0;

	// How fast the wanted yaw is updated
	UPROPERTY()
	float WantedYawSpeed = 50.0;

	// The maximum the dragon can pitch up or down
	UPROPERTY()
	float PitchMaxAmount = 80;

	// How fast the dragon rotates towards the wanted rotation while there is steering input
	UPROPERTY()
	float RotationDurationDuringInput = 4.5;

	// How fast the dragon rotates towards the wanted rotation while there is no steering input
	UPROPERTY()
	float RotationDuration = 1.5;

	// SPEED

	UPROPERTY()
	float MinSpeed = 10000;

	UPROPERTY()
	float MaxSpeed = 20000;

	// The amount of speed gained per second per degree while going downwards
	UPROPERTY()
	float SpeedGainedGoingDown = 800;

	// The amount of speed lost per second per degree while going upwards
	UPROPERTY()
	float SpeedLostGoingUp = 800;

	// Additional Speed During Smash Mode
	UPROPERTY()
	float SmashModeSpeedBoost = 2000.0;

	// CAMERA

	UPROPERTY()
	float CameraBlendInTime = 1.0;

	UPROPERTY()
	float CameraBlendOutTime = 3.0;

	/* How much speed is lost when flying into a wall
	If set to 1, all speed is lost with a full on collision*/
	UPROPERTY()
	float CollisionSpeedLossMultiplier = 1.0;
}