class USkylineGeckoSettings : UHazeComposableSettings
{
	// Stop chase when this close to target
	UPROPERTY(Category = "Chase")
	float ChaseMinRange = 400.0;

	// Speed when in chase behaviour
	UPROPERTY(Category = "Chase")
	float ChaseMoveSpeed = 800.0;

	// Will stop the chase for this duration after the min range has been reached
	UPROPERTY(Category = "Chase")
	float ChaseMinRangeCooldown = 1.2;

	UPROPERTY(Category = "Chase")
	float JumpToSplineSpeed = 2000.0;

	UPROPERTY(Category = "Chase")
	float JumpFromPerchSpeed = 2000.0;

	UPROPERTY(Category = "Chase")
	float ClimbChaseSplineRange = 2000.0;

	UPROPERTY(Category = "Chase")
	float ClimbChaseMinTime = 2.0;

	UPROPERTY(Category = "Chase")
	float ClimbChaseMaxTime = 4.0;

	UPROPERTY(Category = "Chase")
	float ClimbChaseCooldown = 4.0;


	UPROPERTY(Category = "IdleMove")
	float IdleMoveCooldown = 0.7;

	UPROPERTY(Category = "IdleMove")
	float IdleMovePauseDuration = 0.6;

	UPROPERTY(Category = "IdleMove")
	float IdleMoveSpeed = 300.0;


	UPROPERTY(Category = "Damage")
	float BladeDamage = 1.0;

	UPROPERTY(Category = "Damage")
	float DebrisDamage = 0.2; 

	UPROPERTY(Category = "Damage")
	float WhipDamage = 0.5;

	UPROPERTY(Category = "Damage")
	float ThrownImpactDamage = 1.0; 

	UPROPERTY(Category = "Damage")
	float HitByThrownGeckoDamage = 0.0; 

	UPROPERTY(Category = "Damage")
	float HitByThrownGeckoRadius = 500.0; 

	UPROPERTY(Category = "Damage")
	float DirectHitByThrownGeckoDamage = 1.0; 

	UPROPERTY(Category = "Damage")
	float DirectHitByThrownGeckoRadius = 150.0; 

	UPROPERTY(Category = "Damage")
	float HitByThrownGeckoPushForce = 4000.0; 

	UPROPERTY(Category = "Damage")
	float HitByDeathExplosionPushForce = 4000.0; 

	UPROPERTY(Category = "Damage")
	bool bCanBeKilledByBlade = true; 

	UPROPERTY(Category = "Dodge")
	float HitReactionFlinchSpeed = 3000.0;

	// How long the Gecko's hit reaction lasts
	UPROPERTY(Category = "Hit")
	float HitDuration = 0.6;

	// How long the Gecko stays stunned
	UPROPERTY(Category = "Stunned")	
	float StunnedDuration = 1.5;

	// How long after being killed we explode (unless grabbed by whip)
	UPROPERTY(Category = "Death")
	float DeathDuration = 0;

	UPROPERTY(Category = "Death")
	bool bCanBeKilledWhenGrabbed = true;

	UPROPERTY(Category = "Death")
	float DeathExplosionRadius = 300.0;

	UPROPERTY(Category = "Death")
	float DeathExplosionPlayerDamage = 0;

	UPROPERTY(Category = "Death")
	float DeathExplosionAIDamage = 0.0;

	UPROPERTY(Category = "Death")
	float DeathExplosionAIPushForce = 4000.0;

	UPROPERTY(Category = "Death")
	float DeathExplosionPlayerKnockbackForce = 0.0;

	UPROPERTY(Category = "Death")
	float DeathExplosionPlayerKnockbackDuration = 0.7;


	UPROPERTY(Category = "PounceAttack")
	float PounceTelegraphDuration = 1;

	UPROPERTY(Category = "PounceAttack")
	float PounceJumpDuration = 0.5;

	UPROPERTY(Category = "PounceAttack")
	float PounceAttackDuration = 1.8;

	UPROPERTY(Category = "PounceAttack")
	float PounceRecoverDuration = 0.5;

	UPROPERTY(Category = "PounceAttack")
	float PounceSpeed = 1000.0;

	UPROPERTY(Category = "PounceAttack")
	float PounceHeight = 400.0;

	UPROPERTY(Category = "PounceAttack")
	float PounceAttackCooldownDuration = 1.0;

	UPROPERTY(Category = "PounceAttack")
	float PounceAttackRange = 1200.0;

	UPROPERTY(Category = "PounceAttack")
	float PounceAttackMinRange = 0.0;

	UPROPERTY(Category = "PounceAttack")
	float PounceAttackHitRadius = 200.0;

	UPROPERTY(Category = "PounceAttack")
	float PounceAttackDamagePlayer = 0.4;

	UPROPERTY(Category = "PounceAttack")
	bool PounceAttackAllowedWhenPlayerDown = true;

	UPROPERTY(Category = "PounceAttack")
	bool bPounceCanGrapple = false;

	UPROPERTY(Category = "PounceAttack")
	float PounceCooldown = 2.0;

	UPROPERTY(Category = "PounceAttack")
	float PounceKeepTokenDuration = 0.4;

	UPROPERTY(Category = "PlayerKnockback")
	float PlayerKnockbackForce = 200.0;

	UPROPERTY(Category = "PlayerKnockback")
	float PlayerKnockbackDuration = 0.4;

	UPROPERTY(Category = "PounceAttack")
	int PounceSequenceMax = 5;

	UPROPERTY(Category = "PounceAttack")
	float PounceSequenceCooldown = 1.5;


	UPROPERTY(Category = "ConstrainAttack")
	float ConstrainTelegraphDuration = 0.5;

	UPROPERTY(Category = "ConstrainAttack")
	float ConstrainAnticipationDuration = 0.5;

	UPROPERTY(Category = "ConstrainAttack")
	float ConstrainAttackDuration = 1.8;

	UPROPERTY(Category = "ConstrainAttack")
	float ConstrainRecoverDuration = 0.5;

	UPROPERTY(Category = "ConstrainAttack")
	float ConstrainAttackCooldownDuration = 1.0;


	UPROPERTY(Category = "Dodge")
	bool DodgeBladeInvulnerable = false;

	UPROPERTY(Category = "Dodge")
	float DodgeDuration = 1.0;

	UPROPERTY(Category = "Dodge")
	float DodgeSpeed = 1200.0;

	UPROPERTY(Category = "Dodge")
	float DodgeBladeDistance = 600.0;

	UPROPERTY(Category = "Dodge")
	float DodgeBladeCooldown = 5.0;

	UPROPERTY(Category = "Dodge")
	float DodgeWhipThreatRange = 2000.0;

	UPROPERTY(Category = "Dodge")
	float DodgeWhipDistance = 400.0;

	UPROPERTY(Category = "Dodge")
	float DodgeWhipCooldown = 0.0;

	UPROPERTY(Category = "Dodge")
	int DodgeToSplineAfterDodgesInARow = 1;


    UPROPERTY(Category = "Entry")
	float SplineEntryUseAgeThreshold = 10.0;

    UPROPERTY(Category = "Entry")
	float SplineEntrySpeed = 800.0;


	// How long Gecko delays before entering falling state
	UPROPERTY(Category = "Overturned")
	float OverturnedStartDuration = 0.5;

	// How long Gecko stays overturned
	UPROPERTY(Category = "Overturned")
	float OverturnedDuration = 0.5;

	// How long Gecko recovers from overturned state
	UPROPERTY(Category = "Overturned")
	float OverturnedRecoverDuration = 1.0;

	UPROPERTY(Category = "Overturned")
	float OverturnedGravityScale = 3.0;

	UPROPERTY(Category = "Overturned")
	float OverturnedAwayFromWallsPush = 800.0; 

	UPROPERTY(Category = "Overturned")
	float OverturnedGravityChangeDuration = 1.0;


	// Default friction when on ground
    UPROPERTY(Category = "Movement")
	float GroundFriction = 10.0;

	// Default friction when in air
    UPROPERTY(Category = "Movement")
	float AirFriction = 0.6;

	// How fast we turn in when moving
    UPROPERTY(Category = "Movement")
	float TurnDuration = 1.0;


    UPROPERTY(Category = "ArenaDeathBounds")
	float ArenaDeathBoundsRadius = 4500.0;

    UPROPERTY(Category = "ArenaDeathBounds")
	float ArenaDeathBoundsAbove = 2500.0;

    UPROPERTY(Category = "ArenaDeathBounds")
	float ArenaDeathBoundsBelow = 1200.0;


    UPROPERTY(Category = "ConstrainPlayer")
	float ConstrainedButtonMashDuration = 5.0;

    UPROPERTY(Category = "ConstrainPlayer")
	EButtonMashDifficulty ConstrainedButtonMashDifficulty = EButtonMashDifficulty::Medium;

    UPROPERTY(Category = "ConstrainPlayer")
	float ConstrainCooldown = 2.0;

    UPROPERTY(Category = "ConstrainPlayer")
	bool bOnlyKillFromConstrain = true;

	UPROPERTY(Category = "ConstrainPlayer")
	float ConstrainedInputUnblockRecoverTime = 2.0;


	// Deprecated stuff below //////////////////////////////////////

    UPROPERTY(Category = "WhipDragged")
	float WhipDraggedMinRange = 400.0;

    UPROPERTY(Category = "WhipDragged")
	float WhipDraggedMaxRange = 1200.0;


	UPROPERTY(Category = "Return")
	float ReturnStartDuration = 0.5;

	UPROPERTY(Category = "Return")
	float ReturnSpeed = 800;

	
	UPROPERTY(Category = "Whip")
	float ResistWhipDuration = 0.5;


	// Time before blob explodes when there are no obstructions
	UPROPERTY(Category = "Blob")
	float BlobBounceDuration = 4.0;

	UPROPERTY(Category = "Blob")
	float BlobExpirationDelay = 2.0;

	// How many times initial projectile is split when there are no obstructions
	UPROPERTY(Category = "Blob")
	int BlobSplits = 2; // 4 Blobs total

	UPROPERTY(Category = "Blob")
	int BlobSplitYaw = 20.0;

	UPROPERTY(Category = "Blob")
	float BlobSplitSlowdown = 0.85;

	UPROPERTY(Category = "Blob")
	float BlobGravity = 982.0 * 3.0;

	UPROPERTY(Category = "Blob")
	float BlobLaunchHeight = 200.0;

	UPROPERTY(Category = "Blob")
	float BlobLaunchSpeed = 800.0;

	UPROPERTY(Category = "Blob")
	float BlobBounceElasticity = 0.9;

	// Wait this long after performing an attack
	UPROPERTY(Category = "Blob")
	float BlobInitialCooldown = 6.0;

	// Wait this long after performing an attack
	UPROPERTY(Category = "Blob")
	float BlobInterval = 4.0;

	// For how long the Gecko telegraphs before launching projectiles
	UPROPERTY(Category = "Blob")
	float BlobTelegraphDuration = 0.8;

	UPROPERTY(Category = "Blob")
	float BlobAttackLaunchDelay = 0.3;

	// For how long the Gecko does its launching projectile state
	UPROPERTY(Category = "Blob")
	float BlobAttackDuration = 2.0;

	// Cost of this attack in gentleman system
	UPROPERTY(Category = "Blob")
	EGentlemanCost BlobGentlemanCost = EGentlemanCost::Large;

	// Maximum distance for using weapon
	UPROPERTY(Category = "Blob")
	float BlobAttackRange = 10000.0;

	// Minimum distance for using weapon
	UPROPERTY(Category = "Blob")
	float BlobMinimumAttackRange = 300.0;

	// How much damage does the blob deal
	UPROPERTY(Category = "Blob")
	float BlobDamagePlayer = 0.3;

	// Blob token cooldown duration
	UPROPERTY(Category = "Blob")
	float BlobAttackGlobalCooldown = 5.0;


	// For how long the Gecko telegraphs before launching projectiles
	UPROPERTY(Category = "Dakka")
	float DakkaTelegraphDuration = 0.8;

	// Attacks will be divided into this many bursts
	UPROPERTY(Category = "Dakka")
	int DakkaBurstNumber = 5;

	// Time in between each burst
	UPROPERTY(Category = "Dakka")
	float DakkaBurstInterval = 0.4;

	// Time in between each projectile launch within a burst
	UPROPERTY(Category = "Dakka")
	float DakkaLaunchInterval = 0.1;

	// Time from start of first burst to end of last
	UPROPERTY(Category = "Dakka")
	float DakkaAttackDuration = 5.0;

	// Shots will be aimed at target location this long ago (actor loc, move your feet greenhorn!)
	UPROPERTY(Category = "Dakka")
	float DakkaAttackAimLocationAge = 0.5;

	// Cost of this attack in gentleman system
	UPROPERTY(Category = "Dakka")
	EGentlemanCost DakkaGentlemanCost = EGentlemanCost::Large;

	// Maximum distance for using weapon
	UPROPERTY(Category = "Dakka")
	float DakkaAttackRange = 1500.0;

	// Minimum distance for using weapon
	UPROPERTY(Category = "Dakka")
	float DakkaMinimumAttackRange = 400.0;

	// How much damage does the dakka do per second (assuming every shot hits)
	UPROPERTY(Category = "Dakka")
	float DakkaDamagePerSecond = 0.7;

	// Wait this long after completed attack before exiting behaviour
	UPROPERTY(Category = "Dakka")
	float DakkaRecoveryDuration = 1.0;

	UPROPERTY(Category = "Dakka")
	float DakkaProjectileSpeed = 5000.0;

	// Dakka token cooldown duration
	UPROPERTY(Category = "Dakka")
	float DakkaAttackTokenCooldown = 3.0;


	UPROPERTY(Category = "GroundChargeAttack")
	EGentlemanCost GroundChargeGentlemanCost = EGentlemanCost::Large;

	UPROPERTY(Category = "GroundChargeAttack")
	float GroundChargeTokenCooldown = 1.5;

	UPROPERTY(Category = "GroundChargeAttack")
	float GroundChargeTelegraphDuration = 0.65;

	UPROPERTY(Category = "GroundChargeAttack")
	float GroundChargeMaxDuration = 2.0;

	UPROPERTY(Category = "GroundChargeAttack")
	float GroundChargeSettleDuration = 1.0;

	UPROPERTY(Category = "GroundChargeAttack")
	float GroundChargeCooldownDuration = 1;

	UPROPERTY(Category = "GroundChargeAttack")
	float GroundChargeRange = 1500.0;

	UPROPERTY(Category = "GroundChargeAttack")
	float GroundChargeOvershootRange = 400.0;

	UPROPERTY(Category = "GroundChargeAttack")
	float GroundChargeMoveSpeed = 3000.0;

	UPROPERTY(Category = "GroundChargeAttack")
	float GroundChargeTrailAge = 0.0;

	UPROPERTY(Category = "GroundChargeAttack")
	float GroundChargePredictionDuration = 0.2;

	UPROPERTY(Category = "GroundChargeAttack")
	float GroundChargeHitRadius = 100.0;

	UPROPERTY(Category = "GroundChargeAttack")
	float GroundChargeDamagePlayer = 0.3;


	UPROPERTY(Category = "Counter")
	float CounterMoveSpeed = 2500;

	UPROPERTY(Category = "Counter")
	float CounterDistance = 600;

	UPROPERTY(Category = "Counter")
	float CounterMaxDuration = 3;

	// When within this range we can sniff the ground etc while pursuing the player
	UPROPERTY(Category = "Reactions|Tracking")
	float TrackingReactionMaxRange = 4000.0;

	// Within this range we never track the player, but go straight for her
	UPROPERTY(Category = "Reactions|Tracking")
	float TrackingReactionMinRange = 1500.0;

	// Chance per second (percent) of using tracking reaction, once past cooldown
	UPROPERTY(Category = "Reactions|Tracking")
	float TrackingReactionChance = 20.0;

	// How frequently (seconds) we can use tracking reaction. 
	UPROPERTY(Category = "Reactions|Tracking")
	float TrackingReactionCooldown = 10.0;

	// How frequently (seconds) the tracking reaction can be used by any AI in our team.
	UPROPERTY(Category = "Reactions|Tracking")
	float TrackingReactionTeamCooldown = 4.0;

	// Duration of tracking reaction (if 0, we use animation duration)
	UPROPERTY(Category = "Reactions|Tracking")
	float TrackingReactionDuration = 0.0;


	// Cost of pounce attack in gentleman system
	UPROPERTY(Category = "PounceAttack")
	EGentlemanCost Pounce2DAttackGentlemanCost = EGentlemanCost::Large;

	// pounce attack token cooldown duration
	UPROPERTY(Category = "PounceAttack")
	float Pounce2DAttackTokenCooldown = 1.5;

	// pounce attack telegraph duration
	UPROPERTY(Category = "PounceAttack")
	float Pounce2DAttackTelegraphDuration = 0.65;

	// Pounce attack will always end after this long
	UPROPERTY(Category = "PounceAttack")
	float Pounce2DAttackMaxDuration = 2.0;

	// Remain in place this long after reaching target position
	UPROPERTY(Category = "PounceAttack")
	float Pounce2DAttackSettleDuration = 1.0;

	// pounce attack cooldown duration
	UPROPERTY(Category = "PounceAttack")
	float Pounce2DAttackCooldownDuration = 1;

	// Maximum distance for using pounce attack
	UPROPERTY(Category = "PounceAttack")
	float Pounce2DAttackRange = 1200.0;

	// How far beyond target we try to pounce
	UPROPERTY(Category = "PounceAttack")
	float Pounce2DAttackOvershootRange = 400.0;

	// How fast the pounce attack moves
	UPROPERTY(Category = "PounceAttack")
	float Pounce2DAttackMoveSpeed = 3000.0;

	// When telegraphing, we update target location to where target were this long ago (plus prediction)
	UPROPERTY(Category = "PounceAttack")
	float Pounce2DAttackTrailAge = 0.0;

	// How long a trail span we use for predicting where to adjust target location
	UPROPERTY(Category = "PounceAttack")
	float Pounce2DAttackPredictionDuration = 0.2;

	// What distance from us we count as hitting players that we pass by.
	UPROPERTY(Category = "PounceAttack")
	float Pounce2DAttackHitRadius = 100.0;

	// How much damage does the pounce attack deal
	UPROPERTY(Category = "PounceAttack")
	float Pounce2DAttackDamagePlayer = 0.3;


	UPROPERTY(Category = "Stalking")
	float StalkMoveSpeedMin = 200.0;

	UPROPERTY(Category = "Stalking")
	float StalkMoveSpeedLow = 400.0;

	UPROPERTY(Category = "Stalking")
	float StalkMoveSpeedMedium = 700.0;

	UPROPERTY(Category = "Stalking")
	float StalkMoveSpeedHigh = 1000.0;

	UPROPERTY(Category = "Stalking")
	float StalkAtDestinationRange = 100.0;

	UPROPERTY(Category = "Stalking")
	float StalkSpeedChangeInterval = 4.0;

	UPROPERTY(Category = "Stalking")
	float StalkSpeedChangeDuration = 6.0;

	UPROPERTY(Category = "Stalking")
	float StalkInViewMaxDirectionChange = 60.0;

	UPROPERTY(Category = "Stalking")
	float StalkAvoidPlayerRange = 500.0;

	UPROPERTY(Category = "Stalking")
	float StalkAboveZoeHeight = 600.0;

	UPROPERTY(Category = "Stalking")
	float StalkMaxRange = 6000.0;

	UPROPERTY(Category = "Stalking")
	float StalkMaxDuration = 7.0;

	UPROPERTY(Category = "Stalking")
	float StalkPause = 1.5;


	// Speed when moving to perch position
	UPROPERTY(Category = "PerchPositioning")
	float PerchPositioningMoveSpeed = 800.0;

	UPROPERTY(Category = "PerchPositioning")
	float PerchPositioningSpacing = 400.0;

	UPROPERTY(Category = "PerchPositioning")
	float PerchPositioningCooldown = 1.0;

	UPROPERTY(Category = "PerchPositioning")
	bool bAllowBladeHitsWhenPerching = false;

	UPROPERTY(Category = "PerchPositioning")
	float PerchPositioningDoneRange = 80.0;

	UPROPERTY(Category = "PerchPositioning")
	int PerchingMaxGeckos = 3;


	// Speed when moving down to ground
	UPROPERTY(Category = "GroundPositioning")
	float GroundPositioningMoveSpeed = 1000.0;

	UPROPERTY(Category = "GroundPositioning")
	float GroundPositioningIdealDistance = 800.0;

	UPROPERTY(Category = "GroundPositioning")
	float GroundPositioningMinDistance = 400.0;

	UPROPERTY(Category = "GroundPositioning")
	float GroundPositioningCooldown = 1.0;

	UPROPERTY(Category = "GroundPositioning")
	float GroundPositioningMaxDuration = 5.0;

	UPROPERTY(Category = "GroundPositioning")
	float GroundPositioningDoneRange = 80.0;

	// There will never be more than this number of geckos preparing a ground attack
	UPROPERTY(Category = "GroundPositioning")
	int GroundedMaxGeckos = 1;
}
