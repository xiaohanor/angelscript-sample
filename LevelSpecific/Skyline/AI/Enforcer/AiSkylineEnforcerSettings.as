class USkylineEnforcerSettings : UHazeComposableSettings
{
	// How long should death take (including FX and animations)
	UPROPERTY(Category = "Enforcer|Death")
	float DeathDuration = 3.0;

	// How long should we remain after glory kill duration before being removed
	UPROPERTY(Category = "Enforcer|Death")
	float GloryKillCorpseDuration = 2.0;

	UPROPERTY(Category = "Enforcer|Death")
	float GravityWhipMinDeathDuration = 3.0;

	// Do not move around on ground in combat, but still use jetpack to fly to new positions
	UPROPERTY(Category = "Enforcer|Movement")
	bool PreventCombatMovement = false;

	// Duration of roll dodge start
	UPROPERTY()
	float RollDodgeDistance = 500.0;

	// Duration of roll dodge start
	UPROPERTY()
	float RollDodgeStartDuration = 0.25;

	// Duration of roll dodge (excluding start and end)
	UPROPERTY()
	float RollDodgeDuration = 0.75;

	// Duration of roll dodge end
	UPROPERTY()
	float RollDodgeEndDuration = 0.25;

	// Wait at least this long before doing another roll dodge
	UPROPERTY()
	float RollDodgeCooldownMin = 8.0;

	// Wait at most this long before doing another roll dodge
	UPROPERTY()
	float RollDodgeCooldownMax = 12.0;

	// Distance to push character on hit
	UPROPERTY()
	float GravityBladeHitMoveFraction = 1.0;


	// Duration of being gravity whip thrown before recovering
	UPROPERTY()
	float GravityWhipThrownDuration = 0.1;

	// Duration of the gravity whip thrown recovery state
	UPROPERTY()
	float GravityWhipRecoverDuration = 1.8;

	// Duration of the gravity whip thrown impact state
	UPROPERTY()
	float GravityWhipImpactDuration = 4;

	// Duration of the gravity whip thrown impact recover state
	UPROPERTY()
	float GravityWhipImpactRecoverDuration = 1.8;

	// Move speed during the gravity whip thrown impact recover state
	UPROPERTY()
	float GravityWhipImpactRecoverMoveSpeed = 2500;

	// Move speed during the gravity whip thrown impact recover state
	UPROPERTY()
	float GravityWhipImpactRecoverDistance = 200;

	
	// Distance to player for triggering melee attack response
	UPROPERTY()
	float MeleeAttackActivationRange = 600;

	// Time to spend within MeleeAttackActivationRange before executing melee attack
	UPROPERTY()
	float MeleeAttackActivationTimer = 0.5;

	// Radius of HitSphere sweeping with attack animation
	UPROPERTY()
	float MeleeAttackHitSphereRadius = 100.0;

	// Damage
	UPROPERTY()
	float MeleeAttackDamage = 0.8;

	// Multiply damage by this while enforcers is whip grabbed
	UPROPERTY()
	float MeleeAttackDamageWhipGrabbedMultiplier = 2.0;

	// Player knockback distance
	UPROPERTY()
	float MeleeAttackKnockdownDistance = 500;

	// Knockdown time for player
	UPROPERTY()
	float MeleeAttackKnockdownDuration = 0.5;

	// How long maximum we try to chase the target to melee them
	UPROPERTY()
	float ChargeMeleeApproachMaxDuration = 3;

	// Damage
	UPROPERTY()
	float ChargeMeleeAttackDamage = 0.7;

	// Cost of this attack in gentleman system
	UPROPERTY(Category = "Cost")
	EGentlemanCost ChargeMeleeAttackGentlemanCost = EGentlemanCost::XSmall;

	// Distance to player for triggering melee attack behaviour
	UPROPERTY()
	float ChargeMeleeAttackActivationRange = 800;

	// Player knockback distance
	UPROPERTY()
	float ChargeMeleeAttackStumbleDistance = 200;

	// Knockdown time for player
	UPROPERTY()
	float ChargeMeleeAttackStumbleDuration = 0.25;

	// Distance enforcer jumps from a jump entrance point
	UPROPERTY()
	float JumpEntranceDistance = 500.0;

	// Height enforcer jumps from a jump entrance point
	UPROPERTY()
	float JumpEntranceHeight = 200.0;

	// Duration of gravity blade resist reaction, while they are invulnerable for example
	UPROPERTY()
	float ResistGravityBladeReactionDuration = 0.5;

	// At what range do we change from the current target to another target
	UPROPERTY()
	float EnforcerProximityTargetRange = 1000;

	// When a targeted target has lingered this long within range, we refocus on another target
	UPROPERTY()
	float EnforcerRetargetOnProximityDuration = 0.7;

	// Player invulnerability period is set to this time while we're alive
	UPROPERTY()
	float PlayerInvulnerabilityDurationAfterDamage = 0.0;

	// Player taking normal damage enough to die will instead become invulnerable for this long. Can only be used once until restored to full health again.
	UPROPERTY()
	float PlayerSecondChanceWhenKilledDuration = 0.8;

	UPROPERTY()
	float AreaAttackActivationRange = 500;

	UPROPERTY()
	float AreaAttackActivationTimer = 0.75;

	UPROPERTY()
	float AreaAttackHitSphereRadius = 500.0;

	UPROPERTY()
	float AreaAttackDamage = 0.8;

	UPROPERTY()
	float AreaAttackKnockdownDistance = 500;

	UPROPERTY()
	float AreaAttackKnockdownDuration = 0.5;

	UPROPERTY()
	float FleeSpeed = 1500.0;

	UPROPERTY()
	float FleeTurnDuration = 3.0;
}