class UIslandRedBlueStickyGrenadeSettings : UHazeComposableSettings
{
	// How often you can throw a grenade.
	UPROPERTY(Category = "Settings")
	float GrenadeThrowCooldown = 0.5;

	// How long after throwing the grenade you are allowed to press LT to detonate it.
	UPROPERTY(Category = "Settings")
	float GrenadeDetonateCooldown = 0.5;

	UPROPERTY(Category = "Settings")
	float MaxThrowDistance = 5000.0;

	UPROPERTY(Category = "Settings")
	ECollisionChannel TraceChannel = ECollisionChannel::WeaponTracePlayer;

	// How far away from the actual grenade response components will be triggered.
	UPROPERTY(Category = "Grenade")
	float GrenadeExplosionRadius = 500.0;

	// How long the explosion is (this is how long the grenade explosion curve will be evaluated).
	UPROPERTY(Category = "Grenade")
	float GrenadeExplosionDuration = 0.8;

	// X axis represents time, 0 being when explosion starts, 1 when GrenadeExplosionDuration has elapsed. Y axis represents explosion radius, 0 being 0 radius, 1 being 1 * GrenadeExplosionRadius
	UPROPERTY(Category = "Grenade")
	FRuntimeFloatCurve GrenadeExplosionCurve;
	default GrenadeExplosionCurve.AddDefaultKey(0.0, 0.0);
	default GrenadeExplosionCurve.AddDefaultKey(0.1, 1.0);
	default GrenadeExplosionCurve.AddDefaultKey(0.9, 1.0);
	default GrenadeExplosionCurve.AddDefaultKey(1.0, 0.0);

	// How fast the grenade should move
	UPROPERTY(Category = "Grenade")
	float GrenadeMoveSpeed = 15000.0;

	// The grenades gravity (this will start being applied when the grenade has passed it's target point).
	UPROPERTY(Category = "Grenade")
	float GrenadeBaseGravity = 5000.0;

	UPROPERTY(Category = "Grenade")
	float GrenadeAdditionalVerticalityGravity = 2000.0;

	// When the grenade is this far away from the player, it will despawn
	UPROPERTY(Category = "Grenade")
	float DespawnDistance = 15000.0;

	// If the grenade has been in the air for more than this duration it will despawn, negative values means disabled
	UPROPERTY(Category = "Grenade")
	float MaxInAirTime = 5.0;

	/* What the initial strength the force feedback will be when throwing the grenade */
	UPROPERTY(Category = "Force Feedback")
	float ThrowForceFeedbackStartStrength = 0.02;

	/* What the max strength the force feedback will be when throwing the grenade */
	UPROPERTY(Category = "Force Feedback")
	float ThrowForceFeedbackMaxStrength = 0.4;

	/* How much strength the throw force will be increased each second */
	UPROPERTY(Category = "Force Feedback")
	float ThrowForceFeedbackStrengthIncreaseSpeed = 0.5;

	// Set this to true to draw a debug sphere to visualize the explosion radius when the grenade explodes
	UPROPERTY(Category = "Debug")
	bool bDebugGrenadeExplosionRadius = false;

	// Set this to true to draw out the arc and the target location of the grenades movement.
	UPROPERTY(Category = "Debug")
	bool bDebugGrenadeMovementArc = false;

	UPROPERTY(Category = "Debug")
	bool bDebugGrenadeMaxThrowDistance = false;

	// If set to true, it will draw a green line to any response components that was hit, and red ones with a impact string for any response components that were blocked with collision
	UPROPERTY(Category = "Debug")
	bool bDebugGrenadeResponseComponents = false;
}