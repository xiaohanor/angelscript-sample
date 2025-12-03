class UGravityBikeFreeHoverSettings : UHazeComposableSettings
{
    /**
	 * Roll
	 */

	UPROPERTY(EditAnywhere, Category = "Roll")
    float MaxRoll = 40;

	UPROPERTY(EditAnywhere, Category = "Roll")
	float MaxRollVelocity = 200;

	UPROPERTY(EditAnywhere, Category = "Roll")
    float RollStiffness = 20;

	UPROPERTY(EditAnywhere, Category = "Roll")
    float RollDamping = 0.5;
	
	UPROPERTY(EditAnywhere, Category = "Roll")
    float AirRollAmount = 20;

	/**
	 * Pitch
	 */

	UPROPERTY(EditAnywhere, Category = "Pitch")
	float MaxPitch = 60;

	UPROPERTY(EditAnywhere, Category = "Pitch")
	float MaxPitchVelocity = 200;

	UPROPERTY(EditAnywhere, Category = "Pitch")
	float PitchAcceleration = 750;

	UPROPERTY(EditAnywhere, Category = "Pitch")
	bool bBounceWhenGrounded = true;

	UPROPERTY(EditAnywhere, Category = "Pitch")
	float PitchBonceRestitution = 0.5;

	UPROPERTY(EditAnywhere, Category = "Pitch")
	float PitchMinVelocityToBounce = 100;

	UPROPERTY(EditAnywhere, Category = "Pitch")
	int MaxBounces = 2;

	/**
	 * Impact
	 */

	UPROPERTY(EditAnywhere, Category = "Impact")
	float ImpactPitchMultiplier = 0.1;

	UPROPERTY(EditAnywhere, Category = "Impact")
	float ImpactRollMultiplier = 0.4;
};