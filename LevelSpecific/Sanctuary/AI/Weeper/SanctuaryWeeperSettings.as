class USanctuaryWeeperSettings : UHazeComposableSettings
{
	// Radius of view distance from camera center when we start freezing.
	UPROPERTY(Category = "Freeze")
	float FreezeRadius = 100.0;

	// Ignore mio in freeze view checks
	UPROPERTY(Category = "Freeze|Debug")
	bool FreezeIgnoreMioView = false;

	// Ignore mio in freeze view checks
	UPROPERTY(Category = "Freeze|Debug")
	bool FreezeIgnoreZoeView = false;

	// Cone angle at which players detect weepers in 2D
	UPROPERTY(Category = "Freeze")
	float Freeze2DAngle = 55.0;

	// At what speed do we fade/activate visual movement indicators
	UPROPERTY(Category = "Freeze")
	float FreezeIndicatorSpeed = 100.0;

	// Make Weeper invisible whenever it is not freezed
	UPROPERTY(Category = "Freeze|2D")
	bool FreezeHideIn2D = false;

	UPROPERTY(Category = "Freeze")
	float FrozenSpeed = 145;


	// Radius of view distance from camera center when we start doding. Should be bigger than FreezeRadius.
	UPROPERTY(Category = "Dodge")
	float DodgeRadius = 200.0;

	// Speed at which we try to dodge away from camera view.
	UPROPERTY(Category = "Dodge")
	float DodgeSpeed = 525.0;


	// The minimum speed we slow down to, this is the speed we will be when having reached attack range
	UPROPERTY(Category = "Chase")
	float ChaseAttackSlowdownMinSpeed = 100.0;

	// The range from the point of attack at which we start slowing down
	UPROPERTY(Category = "Chase")
	float ChaseAttackSlowdownRange = 500.0;


	UPROPERTY(Category = "Strafe")
	float CircleStrafeMinRange = 0;

	UPROPERTY(Category = "Strafe")
	float CircleStrafeSpeed = 115;


	// How many seconds we remain after death animation is done playing
	UPROPERTY(Category = "Strafe")
	float DeathAfterAnimationDuration = 3.0;
}
