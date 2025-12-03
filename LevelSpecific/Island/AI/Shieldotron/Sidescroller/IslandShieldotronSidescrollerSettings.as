class UIslandShieldotronSidescrollerSettings : UHazeComposableSettings
{
	// Tell 'em to suck a lemon!
	UPROPERTY(Category = "Sidescroller|LemonAttack")
	float LemonAttackDamage = 0.34;

	UPROPERTY(Category = "Sidescroller|LemonAttack")
	int LemonAttackBurstNumber = 3;

	UPROPERTY(Category = "Sidescroller|Attack")
	float AttackMinRange = 0.0;

	UPROPERTY(Category = "Sidescroller|Attack")
	float AttackMaxRange = 2000.0;

	UPROPERTY(Category = "Sidescroller|Attack")
	float AttackScatterPitch = 1.0;

	//
	// Melee Attack
	//

	// Time to spend within MeleeAttackActivationRange before executing melee attack
	UPROPERTY(Category = "Sidescroller|MeleeAttack")
	float MeleeAttackActivationTime = 0.4;

	// Duration of entire melee attack.
	UPROPERTY(Category = "Sidescroller|MeleeAttack")
	float MeleeAttackDuration = 3.5;

	// Distance to player for triggering melee attack response
	UPROPERTY(Category = "Sidescroller|MeleeAttack")
	float MeleeAttackActivationRange = 250;

	// Radius of HitSphere sweeping with attack animation
	UPROPERTY(Category = "Sidescroller|MeleeAttack")
	float MeleeAttackHitSphereRadius = 100.0;

	// Damage
	UPROPERTY(Category = "Sidescroller|MeleeAttack")
	float MeleeAttackDamage = 0.5;

	// Player knockback distance	
	UPROPERTY(Category = "Sidescroller|MeleeAttack")
	float MeleeAttackKnockdownDistance = 350.0;

	// Knockdown time for player
	UPROPERTY(Category = "Sidescroller|MeleeAttack")
	float MeleeAttackKnockdownDuration = 0.5;

	UPROPERTY(Category = "Sidescroller|MeleeAttack")
	float MeleeAttackCooldown = 0.5;

	//
	// Rocket Attack
	//

	// Convenience setting for scenario specific needs.
	UPROPERTY(Category = "Sidescroller|Rocket Attack")
	bool bHasRocketAttack = true;

	UPROPERTY(Category = "Sidescroller|Rocket Attack")
	EGentlemanCost AttackGentlemanCost = EGentlemanCost::XSmall;
	
	UPROPERTY(Category = "Sidescroller|Rocket Attack")
	int AttackBurstNumber = 1;
	
	UPROPERTY(Category = "Sidescroller|Rocket Attack")
	float AttackProjectileLaunchSpeed = 1000.0;
	
	UPROPERTY(Category = "Sidescroller|Rocket Attack")
	float AttackProjectileSpeed = 1000.0;

	// Divide by attack burst number to get shots per second
	UPROPERTY(Category = "Sidescroller|Rocket Attack")
	float AttackDuration = 1.0;

	UPROPERTY(Category = "Sidescroller|Rocket Attack")
	float AttackCooldown = 1.0;	
	
	UPROPERTY(Category = "Sidescroller|Rocket Attack")
	float AttackTelegraphDuration = 1.0;

	// Disable homing after going past target
	UPROPERTY(Category = "Sidescroller|Rocket Attack")
	bool bHomingStopWhenPassed = true;
	
	// Homing steering force
	UPROPERTY(Category = "Sidescroller|Rocket Attack")
	float RocketHomingStrength = 20.0;

	// How much damage does the rocket projectile deal
	UPROPERTY(Category = "Sidescroller|Rocket Attack")
	float RocketDamagePlayer = 0.5;

	
	//
	// Mortar attack
	//

	// Convenience setting for scenario specific needs.
	UPROPERTY(Category = "Sidescroller|MortarAttack")
	bool bHasMortarAttack = true;

	// Can the Mortar attack knock down the player.
	UPROPERTY(Category = "Sidescroller|MortarAttack")
	bool bHasMortarAttackKnockdown = true;

	UPROPERTY(Category = "Sidescroller|MortarAttack")
	EGentlemanCost MortarAttackGentlemanCost = EGentlemanCost::Large;
	
	UPROPERTY(Category = "Sidescroller|MortarAttack")
	float MortarAttackDamage = 0.5;
	
	UPROPERTY(Category = "Sidescroller|MortarAttack")
	int MortarAttackBurstNumber = 6;
	
	UPROPERTY(Category = "Sidescroller|MortarAttack")
	float MortarAttackProjectileSpeed = 1000.0;
	
	UPROPERTY(Category = "Sidescroller|MortarAttack")
	float MortarAttackProjectileLaunchSpeed = 5000.0;
	
	UPROPERTY(Category = "Sidescroller|MortarAttack")
	float MortarAttackKnockdownDuration = 3.0;
	
	UPROPERTY(Category = "Sidescroller|MortarAttack")
	float MortarAttackKnockdownDistance = 500.0;
	
	UPROPERTY(Category = "Sidescroller|MortarAttack")
	float MortarAttackHitSphereRadius = 100.0;


	// Divide by attack burst number to get shots per second
	UPROPERTY(Category = "Sidescroller|MortarAttack")
	float MortarAttackDuration = 2.0;

	UPROPERTY(Category = "Sidescroller|MortarAttack")
	float MortarAttackCooldown = 5.0;
		
	UPROPERTY(Category = "Sidescroller|MortarAttack")
	float MortarAttackTelegraphDuration = 1.0;

	UPROPERTY(Category = "Sidescroller|MortarAttack")
	float MortarAttackLandingSteepness = 1000.0;
	
	UPROPERTY(Category = "Sidescroller|MortarAttack")
	float MortarAttackProjectileAirTime = 2.0;

	UPROPERTY(Category = "Sidescroller|Attack")
	float MortarAttackMinRange = 100.0;

	UPROPERTY(Category = "Sidescroller|Attack")
	float MortarAttackMaxRange = 7000.0;


	//
	// Perception
	//

	UPROPERTY(Category = "Sidescroller|Perception")
	float AwarenessRange = 8000;

	// Will detect target even if out of sight
	UPROPERTY(Category = "Sidescroller|Perception")
	float OmniAwarenessRange = 3000;

	//
	// Chase
	//

	// Speed when in chase behaviour
	UPROPERTY(Category = "Sidescroller|Chase")
	float ChaseMoveSpeed = 500.0;

	// Stop chase when this close to target
	UPROPERTY(Category = "Sidescroller|Chase")
	float ChaseMinRange = 700.0;
	
	// Stop chase when too far from to target
	UPROPERTY(Category = "Sidescroller|Chase")
	float ChaseMaxRange = 1500.0;
	

	// Will stop the chase for this duration after the min range has been reached
	UPROPERTY(Category = "Sidescroller|Chase")
	float ChaseMinRangeCooldown = 2.5;
	
	//
	// Damage and Forcefield
	//

	UPROPERTY(Category = "Sidescroller|ForceField")
	float ReplenishAmountPerSecond = 0.1;

	// Default damage to Shieldotron from player bullet
	UPROPERTY(Category = "Sidescroller|Damage")
	float DefaultDamage = 0.015;

	UPROPERTY(Category = "Sidescroller|Damage")
	float ForceFieldDepletedDamage = 0.02;

	UPROPERTY(Category = "Sidescroller|Damage")
	float ForceFieldGrenadeDamage = 1.0;
	
	UPROPERTY(Category = "Sidescroller|Damage")
	float HurtReactionDuration = 0.5;

	UPROPERTY(Category = "Sidescroller|Damage")
	float StunnedDuration = 0.8;
	
	UPROPERTY(Category = "Sidescroller|Damage")
	float ForceFieldDepletedCooldown = 4.0;
	
	UPROPERTY(Category = "Sidescroller|Damage")
	float DeathDuration = 3.5;

	//
	// Landing
	//

	// Hack for enabling collision during entrance animation (falling from above) in tower hall combat.
	UPROPERTY(Category = "Sidescroller|Animation")
	float CollisionDurationAtEndOfEntrance = 1.5;

	UPROPERTY(Category = "Sidescroller|Landing")
	float LandingDelay = 0.75;

	//
	// Targeting
	//

	// Time before switching to closest target.
	UPROPERTY(Category = "Sidescroller|Perception")
	float RetargetOnProximityDuration = 2.0;

	// Within this range, we refocus if a untargeted target lingers to long
	UPROPERTY(Category = "Sidescroller|Perception")
	float RetargetOnProximityRange = 3000.0;

	//
	// Scenepoints
	//

	// Speed at which we circle the target
	UPROPERTY(Category = "Sidescroller|Shuffle Scenepoint")
	float ShufflePointMoveSpeed = 450.0;


	// if true, try to use shuffle scene points.
	UPROPERTY(Category = "Sidescroller|Shuffle Scenepoint")
	bool bUseShuffleScenepoints = true;

	//
	// Leap Traversal Chase
	//
	UPROPERTY(Category = "Sidescroller|Leap Traversal|Chase")
	float ChaseActivationMinRange = 100;


	//
	// Leap Traversal Evade
	//

	UPROPERTY(Category = "Sidescroller|Leap Traversal|Evade")
	float EvadeActivationMinRange = 5000;

	// Speed when moving towards jump point in evade behaviour
	UPROPERTY(Category = "Sidescroller|Leap Traversal|Evade")
	float EvadeMoveSpeed = 300.0;


	//
	// Crowd avoidance
	//

	// When there are others within this range we will move away from them
	UPROPERTY(Category = "Sidescroller|CrowdAvoidance")
	float CrowdAvoidanceMaxRange = 300.0;

	// Avoid getting this close to anybody as much as possible
	UPROPERTY(Category = "Sidescroller|CrowdAvoidance")
	float CrowdAvoidanceMinRange = 80.0;

	// Max acceleration away from others
	UPROPERTY(Category = "Sidescroller|CrowdAvoidance")
	float CrowdAvoidanceForce = 1000.0;

};
