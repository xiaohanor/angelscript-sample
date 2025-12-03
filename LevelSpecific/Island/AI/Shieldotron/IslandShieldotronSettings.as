

class UIslandShieldotronSettings : UHazeComposableSettings
{
	// Tell 'em to suck a lemon!
	UPROPERTY(Category = "LemonAttack")
	float LemonAttackDamage = 0.5;

	UPROPERTY(Category = "LemonAttack")
	int LemonAttackBurstNumber = 3;

	UPROPERTY(Category = "Attack")
	float AttackMinRange = 150.0;

	UPROPERTY(Category = "Attack")
	float AttackMaxRange = 7000.0;

	//
	// Melee Attack
	//

	// Convenience setting for scenario specific needs.
	UPROPERTY(Category = "MeleeAttack")
	bool bHasMeleeAttack = true;

	// Time to spend within MeleeAttackActivationRange before executing melee attack
	UPROPERTY(Category = "MeleeAttack")
	float MeleeAttackActivationTime = 0.4;

	// Duration of entire melee attack.
	UPROPERTY(Category = "MeleeAttack")
	float MeleeAttackDuration = 3.5;

	// Distance to player for triggering melee attack response
	UPROPERTY(Category = "MeleeAttack")
	float MeleeAttackActivationRange = 250;

	// Radius of HitSphere sweeping with attack animation
	UPROPERTY(Category = "MeleeAttack")
	float MeleeAttackHitSphereRadius = 100.0;

	// Damage
	UPROPERTY(Category = "MeleeAttack")
	float MeleeAttackDamage = 0.5;

	// Player knockback distance
	UPROPERTY(Category = "MeleeAttack")
	float MeleeAttackKnockdownDistance = 500;

	// Knockdown time for player
	UPROPERTY(Category = "MeleeAttack")
	float MeleeAttackKnockdownDuration = 0.5;

	UPROPERTY(Category = "MeleeAttack")
	float MeleeAttackCooldown = 0.5;

	//
	// Close range Attack
	//
	
	// Convenience setting for scenario specific needs.
	UPROPERTY(Category = "CloseRangeAttack")
	bool bHasCloseRangeAttack = true;

	UPROPERTY(Category = "CloseRangeAttack")
	float CloseRangeAttackActionDuration = 0.5;

	UPROPERTY(Category = "CloseRangeAttack")
	float CloseRangeAttackTelegraphDuration = 2.0;
	
	UPROPERTY(Category = "CloseRangeAttack")
	float CloseRangeAttackRecoveryDuration = 1.2;

	// Closest distance to chase towards player during charge phase.
	UPROPERTY(Category = "CloseRangeAttack")
	float CloseRangeAttackMinChaseRange = 200;

	// Distance to player for triggering melee attack response
	UPROPERTY(Category = "CloseRangeAttack")
	float CloseRangeAttackMinActivationRange = 100;

	// Distance to player for triggering melee attack response
	UPROPERTY(Category = "CloseRangeAttack")
	float CloseRangeAttackMaxActivationRange = 400;

	// Radius of HitSphere sweeping with attack animation
	UPROPERTY(Category = "CloseRangeAttack")
	float CloseRangeAttackHitSphereRadius = 200.0;

	// Damage
	UPROPERTY(Category = "CloseRangeAttack")
	float CloseRangeAttackDamage = 0.5;

	// Player knockback distance
	UPROPERTY(Category = "CloseRangeAttack")
	float CloseRangeAttackKnockdownDistance = 500;

	// Knockdown time for player
	UPROPERTY(Category = "CloseRangeAttack")
	float CloseRangeAttackKnockdownDuration = 1.50;

	UPROPERTY(Category = "CloseRangeAttack")
	float CloseRangeAttackCooldown = 0.75;


	//
	// Rocket Attack / Orb Attack
	//

	// Convenience setting for scenario specific needs.
	UPROPERTY(Category = "Rocket Attack")
	bool bHasRocketAttack = true;

	UPROPERTY(Category = "Rocket Attack")
	EGentlemanCost AttackGentlemanCost = EGentlemanCost::XSmall;
	
	UPROPERTY(Category = "Rocket Attack")
	int AttackBurstNumber = 1;

	UPROPERTY(Category = "Rocket Attack")
	int AttackCloseRangeBurstNumber = 3;
	
	UPROPERTY(Category = "Rocket Attack")
	float AttackProjectileLaunchSpeed = 500.0;
	
	UPROPERTY(Category = "Rocket Attack")
	float AttackProjectileSpeed = 500.0;

	// Divide by attack burst number to get shots per second
	UPROPERTY(Category = "Rocket Attack")
	float AttackDuration = 1.0;

	UPROPERTY(Category = "Rocket Attack")
	float AttackCooldown = 1.0;
		
	UPROPERTY(Category = "Rocket Attack")
	float AttackCooldownRandRangeMin = -0.25;
	
	UPROPERTY(Category = "Rocket Attack")
	float AttackCooldownRandRangeMax = 0.25;
		
	UPROPERTY(Category = "Rocket Attack")
	float AttackTelegraphDuration = 2.0;

	// Disable homing after going past target
	UPROPERTY(Category = "Rocket Attack")
	bool bHomingStopWhenPassed = true;
	
	// Homing steering force
	UPROPERTY(Category = "Rocket Attack")
	float RocketHomingStrength = 20.0;

	// How much damage does the rocket projectile deal
	UPROPERTY(Category = "Rocket Attack")
	float RocketDamagePlayer = 0.5;

	// Homing max steering speed (prevents oscillation)
	UPROPERTY(Category = "Combat|OrbAttack")
	float OrbProjectileMaxPlanarHomingSpeed = 1000.0;

	// How much damage does the orb projectile deal
	UPROPERTY(Category = "Combat|OrbAttack")
	float OrbDamagePlayer = 0.5;

	UPROPERTY(Category = "Combat|OrbAttack")
	float OrbProjectileExpirationTime = 6.0;

	UPROPERTY(Category = "Combat|OrbAttack")
	float PilotOrbProjectileExpirationTime = 8.0;

	//
	// Rocket Spread Attack
	//
	
	UPROPERTY(Category = "Rocket Spread Attack")
	bool bHasRocketSpreadAttack = true;

	// Divide by attack burst number to get shots per second
	UPROPERTY(Category = "Rocket Attack")
	float RocketSpreadAttackDuration = 3.0;

	UPROPERTY(Category = "Rocket Spread Attack")
	int RocketSpreadAttackBurstNumber = 3;

	UPROPERTY(Category = "Rocket Spread Attack")
	float RocketSpreadAttackMinRange = 100.0;

	UPROPERTY(Category = "Rocket Spread Attack")
	float RocketSpreadAttackMaxRange = 1000.0;

	//
	// Mortar attack
	//

	// Convenience setting for scenario specific needs.
	UPROPERTY(Category = "MortarAttack")
	bool bHasMortarAttack = true;
	
	// Can the Mortar attack knock down the player.
	UPROPERTY(Category = "MortarAttack")
	bool bHasMortarAttackKnockdown = true;

	UPROPERTY(Category = "MortarAttack")
	EGentlemanCost MortarAttackGentlemanCost = EGentlemanCost::Large;
	
	UPROPERTY(Category = "MortarAttack")
	float MortarAttackDamage = 0.5;
	
	UPROPERTY(Category = "MortarAttack")
	int MortarAttackBurstNumber = 6;
			
	UPROPERTY(Category = "MortarAttack")
	float MortarAttackProjectileLaunchSpeed = 1500.0;
	
	UPROPERTY(Category = "MortarAttack")
	float MortarAttackProjectileEndSpeed = 1500.0;

	UPROPERTY(Category = "MortarAttack")
	float MortarAttackKnockdownDuration = 0.75;
	
	UPROPERTY(Category = "MortarAttack")
	float MortarAttackKnockdownDistance = 500.0;
	
	UPROPERTY(Category = "MortarAttack")
	float MortarAttackHitSphereRadius = 100.0;


	// Divide by attack burst number to get shots per second
	UPROPERTY(Category = "MortarAttack")
	float MortarAttackDuration = 2.0;

	UPROPERTY(Category = "MortarAttack")
	float MortarAttackCooldown = 5.0;
		
	UPROPERTY(Category = "MortarAttack")
	float MortarAttackTelegraphDuration = 1.0;

	UPROPERTY(Category = "MortarAttack")
	float MortarAttackLandingSteepness = 1000.0;
	
	UPROPERTY(Category = "MortarAttack")
	float MortarAttackProjectileAirTime = 2.0;

	UPROPERTY(Category = "Attack")
	float MortarAttackMinRange = 1500.0;

	UPROPERTY(Category = "Attack")
	float MortarAttackMaxRange = 7000.0;

	
	//
	// Missile attack
	//

	// Convenience setting for scenario specific needs.
	UPROPERTY(Category = "MissileAttack")
	bool bHasMissileAttack = true;

	// Can the Missile attack knock down the player.
	UPROPERTY(Category = "MissileAttack")
	bool bHasMissileAttackKnockdown = true;

	UPROPERTY(Category = "MissileAttack")
	EGentlemanCost MissileAttackGentlemanCost = EGentlemanCost::Large;
	
	UPROPERTY(Category = "MissileAttack")
	float MissileAttackDamage = 0.5;
	
	UPROPERTY(Category = "MissileAttack")
	int MissileAttackBurstNumber = 6;
	
	UPROPERTY(Category = "MissileAttack")
	float MissileAttackProjectileSpeed = 1000.0;
	
	UPROPERTY(Category = "MissileAttack")
	float MissileAttackProjectileLaunchSpeed = 5000.0;
	
	UPROPERTY(Category = "MissileAttack")
	float MissileAttackKnockdownDuration = 3.0;
	
	UPROPERTY(Category = "MissileAttack")
	float MissileAttackKnockdownDistance = 500.0;
	
	UPROPERTY(Category = "MissileAttack")
	float MissileAttackHitSphereRadius = 100.0;


	// Divide by attack burst number to get shots per second
	UPROPERTY(Category = "MissileAttack")
	float MissileAttackDuration = 2.0;

	UPROPERTY(Category = "MissileAttack")
	float MissileAttackCooldown = 5.0;
		
	UPROPERTY(Category = "MissileAttack")
	float MissileAttackTelegraphDuration = 1.0;

	UPROPERTY(Category = "MissileAttack")
	float MissileAttackLandingSteepness = 1000.0;
	
	UPROPERTY(Category = "MissileAttack")
	float MissileAttackProjectileAirTime = 2.0;

	UPROPERTY(Category = "Attack")
	float MissileAttackMinRange = 1500.0;

	UPROPERTY(Category = "Attack")
	float MissileAttackMaxRange = 7000.0;


	//
	// Perception
	//

	UPROPERTY(Category = "Perception")
	float AwarenessRange = 8000;

	// Will detect target even if out of sight
	UPROPERTY(Category = "Perception")
	float OmniAwarenessRange = 3000;
	
	// Will not switch to closest target before new target is this much closer than curren target.
	UPROPERTY(Category = "Perception")
	float SwitchClosestTargetTresholdDist = 1000.0;

	//
	// Chase
	//

	// Speed when in chase behaviour
	UPROPERTY(Category = "Chase")
	float ChaseMoveSpeed = 450.0;

	// Stop chase when this close to target
	UPROPERTY(Category = "Chase")
	float ChaseMinRange = 200.0;
	
	// Will stop the chase for this duration after the min range has been reached
	UPROPERTY(Category = "Chase")
	float ChaseMinRangeCooldown = 1.5;

	//
	// CircleStrafe
	//

	// Speed at which we sidestep
	UPROPERTY(Category = "Sidestep")
	float SidestepStrafeSpeed = 450.0;

	// Speed at which we circle the target
	UPROPERTY(Category = "CircleStrafe")
	float CircleStrafeSpeed = 450.0;

	// We need to be within this range of target to start circling
	UPROPERTY(Category = "CircleStrafe")
	float CircleStrafeEnterRange = 2000.0;

	// If outside this range we will stop circling
	UPROPERTY(Category = "CircleStrafe")
	float CircleStrafeMaxRange = 3000.0;

	// If within this range, we do not circle
	UPROPERTY(Category = "CircleStrafe")
	float CircleStrafeMinRange = 100.0;


	//
	// Laser
	//

	// Cost of laser attack in gentleman system
	UPROPERTY(Category = "Laser")
	EGentlemanCost LaserGentlemanCost = EGentlemanCost::XSmall;

	// At what range does the laser behaviour activate
	UPROPERTY(Category = "Laser")
	float LaserMaxActivationRange = 1500.0;

	// At what range does the laser behaviour activate
	UPROPERTY(Category = "Laser")
	float LaserMinActivationRange = 500.0;

	// This is how far too try shooting with the laser, when we are within LaserRange
	UPROPERTY(Category = "Laser")
	float LaserTraceDistance = 1800.0;

	UPROPERTY(Category = "Laser")
	float LaserDamageInterval = 0.1;

	UPROPERTY(Category = "Laser")
	float LaserPlayerDamagePerSecond = 0.25;

	UPROPERTY(Category = "Laser")
	float LaserValidAngle = 60;

	UPROPERTY(Category = "Laser")
	float LaserFollowSpeed = 400;

	UPROPERTY(Category = "Laser")
	float LaserDuration = 4.0;

	// Cooldown for individual AI
	UPROPERTY(Category = "Laser")
	float LaserCooldown = 3.0;
	
	// Cooldown for whole team of AI
	UPROPERTY(Category = "Laser")
	float LaserTeamCooldown = 5.0;
	
	UPROPERTY(Category = "Laser")
	float LaserTelegraphDuration = 1.5;
	
	// Half of sweep
	UPROPERTY(Category = "Laser")
	float LaserHalfAngle = 60;

	
	//
	// Damage and Forcefield
	//

	UPROPERTY(Category = "ForceField")
	float ReplenishAmountPerSecond = 0.1;

	// Default damage to Shieldotron from player bullet
	UPROPERTY(Category = "Damage")
	float DefaultDamage = 0.012;

	UPROPERTY(Category = "Damage")
	float ForceFieldDepletedDamage = 0.02;

	UPROPERTY(Category = "Damage")
	float ForceFieldDefaultDamage = 0.08;
	
	UPROPERTY(Category = "Damage")
	float ForceFieldGrenadeDamage = 1.0;
	
	UPROPERTY(Category = "Damage")
	float ForceFieldDepletedCooldown = 4.0;
	
	UPROPERTY(Category = "Damage")
	float HurtReactionDuration = 0.5;

	UPROPERTY(Category = "Damage")
	float StunnedDuration = 1.5;
	
	UPROPERTY(Category = "Damage")
	float DeathDuration = 3.5;

	//
	// Landing
	//

	// Hack for enabling collision during entrance animation (falling from above) in tower hall combat.
	UPROPERTY(Category = "Animation")
	float CollisionDurationAtEndOfEntrance = 1.5;

	UPROPERTY(Category = "Landing")
	float LandingDelay = 0.75;

	//
	// Targeting
	//

	// Time before switching to closest target.
	UPROPERTY(Category = "Perception")
	float RetargetOnProximityDuration = 2.0;

	// Within this range, we refocus if a untargeted target lingers to long
	UPROPERTY(Category = "Perception")
	float RetargetOnProximityRange = 3000.0;

	//
	// Scenepoints
	//

	// Speed at which we circle the target
	UPROPERTY(Category = "Shuffle Scenepoint")
	float ShufflePointMoveSpeed = 450.0;


	// if true, try to use shuffle scene points.
	UPROPERTY(Category = "Shuffle Scenepoint")
	bool bUseShuffleScenepoints = true;

	//
	// Leap Traversal Chase
	//
	UPROPERTY(Category = "Leap Traversal|Chase")
	float ChaseActivationMinRange = 100;


	//
	// Leap Traversal Evade
	//

	UPROPERTY(Category = "Leap Traversal|Evade")
	float EvadeActivationMinRange = 5000;

	// Speed when moving towards jump point in evade behaviour
	UPROPERTY(Category = "Leap Traversal|Evade")
	float EvadeMoveSpeed = 300.0;


	//
	// Crowd avoidance
	//

	// When there are others within this range we will move away from them
	UPROPERTY(Category = "CrowdAvoidance")
	float CrowdAvoidanceMaxRange = 300.0;

	// Avoid getting this close to anybody as much as possible
	UPROPERTY(Category = "CrowdAvoidance")
	float CrowdAvoidanceMinRange = 80.0;

	// Max acceleration away from others
	UPROPERTY(Category = "CrowdAvoidance")
	float CrowdAvoidanceForce = 1000.0;

	//
	//	Jetski Shieldotron
	//

	// Override normal compound capability
	UPROPERTY(Category = "Jetski")
	bool bUseJetskiShieldotronBehaviour = false;

	UPROPERTY(Category = "Jetski|MortarAttack")
	EGentlemanCost JetskiMortarAttackGentlemanCost = EGentlemanCost::None;

	UPROPERTY(Category = "Jetski|MortarAttack")
	float JetskiMortarAttackCooldown = 1.0;

	UPROPERTY(Category = "Jetski|MortarAttack")
	float JetskiMortarAttackCooldownMinRandomRange = -0.5;

	UPROPERTY(Category = "Jetski|MortarAttack")
	float JetskiMortarAttackCooldownMaxRandomRange = 0.5;


	//
	// Damage on Touch
	//

	// Cooldown time until next contact damage may be dealt to player.
	UPROPERTY(Category = "DamageOnTouch")
	float DamageOnTouchHitCooldown = 0.5;

	// Damage dealt to player on contact
	UPROPERTY(Category = "DamageOnTouch")
	float DamageOnTouchDamage = 0.9;

	// Knockdown duration
	UPROPERTY(Category = "DamageOnTouch")
	float DamageOnTouchKnockdownDuration = 1.25;

	// Knockdown distance
	UPROPERTY(Category = "DamageOnTouch")
	float DamageOnTouchKnockdownDist = 300;
};
