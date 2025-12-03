class UTeenDragonRollWallKnockbackSettings : UHazeComposableSettings
{
	UPROPERTY(Category = "Knockback")
	float KnockbackWallImpactHorizontalMultiplier = 0.4;

	// How much speed which goes upwards
	UPROPERTY(Category = "Knockback")
	float KnockbackWallImpactVerticalMultiplier = 0.6;

	// How much speed which continues sliding along the wall
	UPROPERTY(Category = "Knockback")
	float KnockbackAlongWallVelocityMultiplier = 0.5;

	// How much speed is the minimum when you get knocked back
	UPROPERTY(Category = "Knockback")
	float MinVelocityKnockback = 1500.0;

	UPROPERTY(Category = "Knockback")
	float MaxKnockbackSize = 5000.0;

	UPROPERTY(Category = "Knockback")
	float WallKnockbackCameraImpulsePerSpeedIntoWall = 0.75;

	UPROPERTY(Category = "Knockback")
	float WallKnockbackCameraImpulseMaxSize = 1400.0;

	UPROPERTY(Category = "Knockback")
	float WallKnockbackCameraImpulseMinSize = 1200.0;

	UPROPERTY(Category = "Knockback")
	float WallKnockbackCameraImpulseExpirationForce = 10.0;

	UPROPERTY(Category = "Knockback")
	float WallKnockbackCameraImpulseDampening = 0.75;
	
	UPROPERTY(Category = "Knockback")
	float WallKnockbackMinThreshold = 30.0;

	UPROPERTY(Category = "Knockback")
	float WallKnockbackDuration = 0.5;

	UPROPERTY(Category = "Reflect")
	float ReflectOffWallMaxThreshold = 70.0;
	
	/** How much you get impulsed horizontally when you reflect off a wall
	 * In the direction of the wall normal
	 * Based on the speed towards the wall normal
	 */
	UPROPERTY(Category = "Reflect")
	float ReflectHorizontalImpulsePerSpeed = 0.2;

	/** How much you get impulsed vertically
	 * Directed upwards
	 * Based on the speed towards the wall normal
	 */
	UPROPERTY(Category = "Reflect")
	float ReflectVerticalImpulsePerSpeed = 0.0;

	UPROPERTY(Category = "Reflect")
	float ReflectBounceRestitution = 0.5;

	UPROPERTY(Category = "Reflect")
	float ReflectMeshRotateDuration = 0.2;

	UPROPERTY(Category = "Reflect")
	float ReflectSteeringSlowdownFraction = 0.2; 

	UPROPERTY(Category = "Reflect")
	float ReflectSteeringSlowdownDuration = 2.0;

	UPROPERTY(Category = "Reflect")
	float ReflectCameraImpulsePerSpeedIntoWall = 0.75;

	UPROPERTY(Category = "Reflect")
	float ReflectCameraImpulseMaxSize = 1650.0;

	UPROPERTY(Category = "Reflect")
	float ReflectCameraImpulseMinSize = 1500.0;

	UPROPERTY(Category = "Reflect")
	float ReflectCameraImpulseExpirationForce = 10.0;

	UPROPERTY(Category = "Reflect")
	float ReflectCameraImpulseDampening = 0.75;

	UPROPERTY(Category = "Reflect")
	float ReflectDegreesMultiplier = 1.75;


	UPROPERTY(Category = "Rotate Along Wall")
	float RotateAlongWallSpeed = 300.0;
}