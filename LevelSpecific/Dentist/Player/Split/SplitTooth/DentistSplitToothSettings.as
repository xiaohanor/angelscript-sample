class UDentistSplitToothSettings : UHazeComposableSettings
{
	UPROPERTY(Category = "Ground")
	float GroundRotationSpeed = 10;
	
	UPROPERTY(Category = "Ground")
	float GroundDeceleration = 7500;

	UPROPERTY(Category = "Air")
	float AirMaxSpeed = 350;
	UPROPERTY(Category = "Air")
	float AirAcceleration = 250;
	UPROPERTY(Category = "Air")
	float AirRotationSpeed = 3;

	UPROPERTY(Category = "Steering")
	float ReboundFactor = 3;

	UPROPERTY(Category = "Ground")
	float LungeDirInterpSpeed = 100;
	UPROPERTY(Category = "Lunge")
	float LungePrepareDuration = 0.2;
	UPROPERTY(Category = "Lunge")
	float LungeHorizontalImpulse = 800;
	UPROPERTY(Category = "Lunge")
	float LungeVerticalImpulse = 500;
};

/**
 * Default overrides for the player.
 */
asset DentistSplitToothPlayerSettings of UDentistSplitToothSettings
{
	LungePrepareDuration = 0.2;
	LungeHorizontalImpulse = 800;
};

/**
 * Overrides for the player while waiting for the AI to finish being startled
 */
asset DentistSplitToothPlayerAwaitStartleSettings of UDentistSplitToothSettings
{
	// LungePrepareDuration = 0.3;
	// LungeHorizontalImpulse = 200;
	// AirAcceleration = 0;
};

/**
 * Overrides for the player while chasing (the AI is scaredycat)
 */
asset DentistSplitToothPlayerChaseSettings of UDentistSplitToothSettings
{
	// LungePrepareDuration = 0.2;
	// LungeHorizontalImpulse = 800;
};

/**
 * Default overrides for the AI.
 */
asset DentistSplitToothAISettings of UDentistSplitToothSettings
{
	LungePrepareDuration = 0.4;
};

/**
 * Overrides while the AI is scared and running away.
 */
asset DentistSplitToothAIScaredSettings of UDentistSplitToothSettings
{
	LungePrepareDuration = 0.5;
};