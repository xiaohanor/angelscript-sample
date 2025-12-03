
struct FBasicBehaviourCustomSettings
{
	UPROPERTY()
	TMap<FName, float> Values;
}


class UBasicAISettings : UHazeComposableSettings
{
	UPROPERTY(Category = CustomSettings)
	TMap<FName, FBasicBehaviourCustomSettings> Custom;

	/////////////////////////////////////////////////////////////
	// PERCEPTION
	/////////////////////////////////////////////////////////////

	// Within this range we automatically become aware of potential targets, regardless of line of sight etc
	UPROPERTY(Category = "Perception")
	float AwarenessRange = 10000.0;

	// Within this range we automatically become aware of anyone attacking us
	UPROPERTY(Category = "Perception")
	float DetectAttackerRange = 100000.0;

	// Within this range any targets we're told about are interesting
	UPROPERTY(Category = "Perception")
	float RespondToAlarmRange = 10000.0;

	// Within this range, we refocus if a untargeted target lingers to long
	UPROPERTY(Category = "Perception")
	float RetargetOnProximityRange = 200.0;

	// When a untargeted target has lingered this long within range, we refocus on them
	UPROPERTY(Category = "Perception")
	float RetargetOnProximityDuration = 0.7;

	// Always make this player the priority target
	UPROPERTY(Category = "Perception")
	EHazePlayer PriorityTarget = EHazePlayer::MAX;

	/////////////////////////////////////////////////////////////
	// IDLE BEHAVIOURs												
	/////////////////////////////////////////////////////////////

	// If true we never forget perceived target
	UPROPERTY(Category = "Idle|FindTarget")
	bool bAlwaysRememberTarget = true;

	// For how long do we remember attackers
	UPROPERTY(Category = "Idle|FindTarget")
	float FindTargetRememberAttackerDuration = 10.0;

	// We wait at least this long before repsonding to an alarm 
	UPROPERTY(Category = "Idle|FindTarget")
	float FindTargetRespondToAlarmDelay = 0.8;

	// When responding to an alarm, we wait at least this long before  
	UPROPERTY(Category = "Idle|FindTarget")
	float FindTargetRememberAlarmDuration = 10.0;

	UPROPERTY(Category = "Idle|FindTarget")
	float FindTargetLineOfSightInterval = 0.5;

	UPROPERTY(Category = "Idle|GentlemanQueueSwitching")
	float GentlemanQueueSwitchingCooldown = 4.0;

	// When roaming we always abort after this long even if we did not reach destination
	UPROPERTY(Category = "Idle|Roam")
	float RoamMaxDuration = 10.0;

	// When at a roam destination we pause at least this many seconds before roaming somewhere else
	UPROPERTY(Category = "Idle|Roam")
	float RoamDestinationPauseMin = 3.0;

	// When at a roam destination we pause at most this many seconds before roaming somewhere else
	UPROPERTY(Category = "Idle|Roam")
	float RoamDestinationPauseMax = 5.0;

	// Radius within which we look for roam destinations
	UPROPERTY(Category = "Idle|Roam")
	float RoamRadius = 4000.0;

	// Speed when in roam behaviour
	UPROPERTY(Category = "Idle|Roam")
	float RoamMoveSpeed = 150.0;

	// Max altitude above starting location when roaming
	UPROPERTY(Category = "Idle|Roam")
	float FlyingRoamMaxSpawnHeightOffset = 400.0;

	// Min altitude above ground when roaming
	UPROPERTY(Category = "Idle|Roam")
	float FlyingRoamMinHeightAboveGround = 200.0;

	// Speed when in scenepoint entry behaviour
	UPROPERTY(Category = "Idle|ScenepointEntry")
	float ScenepointEntryMoveSpeed = 450.0;

	// If true, we abort entry when taking damage
	UPROPERTY(Category = "Idle|ScenepointEntry")
	bool bScenepointEntryAbortOnDamage = true;

	// Speed when in spline entrance behaviour
	UPROPERTY(Category = "Idle|SplineEntrance")
	float SplineEntranceMoveSpeed = 450.0;

	// Distance from end of spline we need to reach to consider entrance done
	UPROPERTY(Category = "Idle|SplineEntrance")
	float SplineEntranceCompletionRange = 40.0;

	/////////////////////////////////////////////////////////////
	// COMBAT BEHAVIOURS												
	/////////////////////////////////////////////////////////////

	// Gentleman behaviour will be used when target has at least this gentleman score, see 
	UPROPERTY(Category = "Combat|Gentleman")
	float GentlemanScore = 1.0;

	// Gentleman behaviours will be considered when within this range of a target
	UPROPERTY(Category = "Combat|Gentleman")
	float GentlemanRange = 500.0;

	// When in gentleman behaviours we try to keep at least this distance to target
	UPROPERTY(Category = "Combat|Gentleman")
	float GentlemanStepBackRange = 250.0;

	// Speed when moving in gentleman behaviours
	UPROPERTY(Category = "Combat|Gentleman")
	float GentlemanMoveSpeed = 150.0;

	// Speed when in chase behaviour
	UPROPERTY(Category = "Combat|Chase")
	float ChaseMoveSpeed = 1450.0;

	// Stop chase when this close to target
	UPROPERTY(Category = "Combat|Chase")
	float ChaseMinRange = 100.0;

	// Will stop the chase for this duration after the min range has been reached
	UPROPERTY(Category = "Combat|Chase")
	float ChaseMinRangeCooldown = 0.5;

	// Try to keep to this height above target when chasing
	UPROPERTY(Category = "Combat|Chase")
	float FlyingChaseHeight = 200.0;

	// Speed at which we circle the target
	UPROPERTY(Category = "Combat|CircleStrafe")
	float CircleStrafeSpeed = 150.0;

	// We need to be within this range of target to start circling
	UPROPERTY(Category = "Combat|CircleStrafe")
	float CircleStrafeEnterRange = 400.0;

	// If outside this range we will stop circling
	UPROPERTY(Category = "Combat|CircleStrafe")
	float CircleStrafeMaxRange = 600.0;

	// If within this range, we do not circle
	UPROPERTY(Category = "Combat|CircleStrafe")
	float CircleStrafeMinRange = 100.0;

	// Try to keep to this height above target when circling
	UPROPERTY(Category = "Combat|CircleStrafe")
	float FlyingCircleStrafeHeight = 400.0;

	// Minimum duration of evasive behaviour
	UPROPERTY(Category = "Combat|Evade")
	float EvadeMinDuration = 0.5;

	// Maximum duration of evasive behaviour
	UPROPERTY(Category = "Combat|Evade")
	float EvadeMaxDuration = 3.0;

	// When outside this range of target we will stop evading
	UPROPERTY(Category = "Combat|Evade")
	float EvadeRange = 150.0;

	// Speed when in evasive behaviour
	UPROPERTY(Category = "Combat|Evade")
	float EvadeMoveSpeed = 450.0;

	// We are allowed to raise alarm initially this many seconds after engaged in combat
	UPROPERTY(Category = "Combat|RaiseAlarm")
	float RaiseAlarmDelay = 0.5;

	// When raising the alarm, we notify all team members within this radius
	UPROPERTY(Category = "Combat|RaiseAlarm")
	float RaiseAlarmRadius = 1000.0;

	// We raise the alarm every this many seconds.
	UPROPERTY(Category = "Combat|RaiseAlarm")
	float RaiseAlarmInterval = 5.0;

	// Range at which we make a telegraph taunt to show that attack are forthcoming
	UPROPERTY(Category = "Combat|Telegraph")
	float TelegraphAttackRange = 800.0;

	// We need to spend this much time in current state before allowing telegraph taunt
	UPROPERTY(Category = "Combat|Telegraph")
	float TelegraphAttackMinStateDuration = 1.0;

	// Maximum attack range
	UPROPERTY(Category = "Combat|Attack")
	float AttackRange = 200.0;

	// DEPRECATED! If true we require a telegraph behaviour to run before we consider a melee attack
	UPROPERTY(Category = "Combat|Attack")
	bool bAttackRequiresTelegraph = false;

	// Minimum cooldown after completing an attack
	UPROPERTY(Category = "Combat|Attack")
	float AttackCooldown = 0.5;

	// DEPRECATED! (Chance (0..1) of recovering after making an attack for old behaviours)
	UPROPERTY(Category = "Combat|Attack")
	float PostAttackRecoveryChance = 0.0;

	// Horizontal scatter in degrees of ranged attacks (DEPRECATED, move to individual weapon settings)
	UPROPERTY(Category = "Combat|Attack")
	float RangedAttackScatterYaw = 4.0;

	// Vertical scatter in degrees of ranged attacks (DEPRECATED, move to individual weapon settings)
	UPROPERTY(Category = "Combat|Attack")
	float RangedAttackScatterPitch = 3.0;

	// If true we require line of sight to perform ranged attacks
	UPROPERTY(Category = "Combat|Attack")
	bool RangedAttackRequireVisibility = true;

	// DEPRECATED! If true we require a telegraph behaviour to run before we consider a charge
	UPROPERTY(Category = "Combat|Charge")
	bool bChargeRequiresTelegraph = true;

	// How far away we can initiate a charge
	UPROPERTY(Category = "Combat|Charge")
	float ChargeRange = 1000.0;

	// Local offset for charge destination
	UPROPERTY(Category = "Combat|Charge")
	FVector ChargeOffset = FVector(0.0, 0.0, 100.0);

	// Movement speed during charge
	UPROPERTY(Category = "Combat|Charge")
	float ChargeMoveSpeed = 800.0;

	// Charge ends when we've passed target or after this time
	UPROPERTY(Category = "Combat|Charge")
	float ChargeMaxDuration = 5.0;

	// Keep moving towards target until within this range, then we charge straight ahead
	UPROPERTY(Category = "Combat|Charge")
	float ChargeTrackTargetRange = 400.0;

	// Always wait at least this long before charging again after a completed charge
	UPROPERTY(Category = "Combat|Charge")
	float ChargeCooldown = 3.0;

	// When there are others within this range we will move away from them
	UPROPERTY(Category = "Combat|CrowdAvoidance")
	float CrowdAvoidanceMaxRange = 300.0;

	// Avoid getting this close to anybody as much as possible
	UPROPERTY(Category = "Combat|CrowdAvoidance")
	float CrowdAvoidanceMinRange = 80.0;

	// Max acceleration away from others
	UPROPERTY(Category = "Combat|CrowdAvoidance")
	float CrowdAvoidanceForce = 500.0;

	// Max range at which we track targets
	UPROPERTY(Category = "Combat|TrackTarget")
	float TrackTargetRange = 4000.0;

	// Should we only track tragets when they are in line of sight
	UPROPERTY(Category = "Combat|TrackTarget")
	bool bTrackTargetsRequireVisibility = false;

	// Max range at which we use encircling
	UPROPERTY(Category = "Combat|CrowdEncircle")
	float CrowdEncircleMaxRange = 1500.0;

	// We want to be at this range from the target at our encircling location
	UPROPERTY(Category = "Combat|CrowdEncircle")
	float CrowdEncircleRange = 500.0;

	// We add between 0 and this much variability to the desired crowd encircling range
	UPROPERTY(Category = "Combat|CrowdEncircle")
	float CrowdEncircleRangeVariable = 150.0;

	// We move this fast when going to our encircling location
	UPROPERTY(Category = "Combat|CrowdEncircle")
	float CrowdEncircleSpeed = 500.0;

	// We start moving towards our location when going outside this range of it
	UPROPERTY(Category = "Combat|CrowdEncircle")
	float CrowdEncircleActivationRange = 100.0;

	// We stop towards our encircle location when within this range of it
	UPROPERTY(Category = "Combat|CrowdEncircle")
	float CrowdEncircleDeactivationRange = 50.0;

	UPROPERTY(Category = "Combat|CrowdEncircle")
	float FlyingCrowdEncircleHeight = 400;

	// Speed when in shuffle behaviour
	UPROPERTY(Category = "Combat|Shuffle")
	float ShuffleMoveSpeed = 150.0;

	// Minimum time of shuffle behaviour
	UPROPERTY(Category = "Combat|Shuffle")
	float ShuffleDurationMin = 5.0;

	// Maximum time of shuffle behaviour
	UPROPERTY(Category = "Combat|Shuffle")
	float ShuffleDurationMax = 10.0;

	// Minimum cooldown time of shuffle
	UPROPERTY(Category = "Combat|Shuffle")
	float ShuffleCooldownMin = 2.0;

	// Maximum cooldown time of shuffle
	UPROPERTY(Category = "Combat|Shuffle")
	float ShuffleCooldownMax = 3.0;

	/////////////////////////////////////////////////////////////
	// RECOVER BEHAVIOURS											
	/////////////////////////////////////////////////////////////

	// For how long we recover until returning to idle
	UPROPERTY(Category = "Recover|Rest")
	float RestDuration = 1.0;

	// For how long we drift until returning to idle
	UPROPERTY(Category = "Recover|Rest")
	float FlyingDriftDuration = 2.0;

	// Height above target which we rise to when drifting
	UPROPERTY(Category = "Recover|Rest")
	float FlyingDriftHeight = 400.0;

	/////////////////////////////////////////////////////////////
	// REACTION BEHAVIOURS											
	/////////////////////////////////////////////////////////////

	// When first entering this range we can show a 'spot target' reaction
	UPROPERTY(Category = "Reactions|SpotTarget")
	float SpotTargetReactionMaxRange = 4000.0;

	// Within this range, the spot target reaction will never be used.
	UPROPERTY(Category = "Reactions|SpotTarget")
	float SpotTargetReactionMinRange = 500.0;

	// How frequently (seconds) we can use spot target reaction. 
	UPROPERTY(Category = "Reactions|SpotTarget")
	float SpotTargetReactionCooldown = 1000.0;

	// How frequently (seconds) the spot target reaction can be used by any AI in our team.
	UPROPERTY(Category = "Reactions|SpotTarget")
	float SpotTargetReactionTeamCooldown = 5.0;

	// Duration of spot target reaction (if 0, we use animation duration)
	UPROPERTY(Category = "Reactions|SpotTarget")
	float SpotTargetReactionDuration = 0.0;

	/////////////////////////////////////////////////////////////
	// STUNNED BEHAVIOURS											
	/////////////////////////////////////////////////////////////

	// For how long we stay knocked down
	UPROPERTY(Category = "Stunned|Knockdown")
	float KnockdownDuration = 3.0;

	// Damage types causing knockdown. If empty, any damage type can cause knockdown.
	UPROPERTY(Category = "Stunned|Knockdown")
	TArray<EDamageType> KnockdownDamageTypes;

	// For how long we stay hurt
	UPROPERTY(Category = "Stunned|Hurt")
	float HurtDuration = 0.5;

	// Damage types causing the NPC to stop and play a hurt animation. If empty, any damage type can cause hurt.
	UPROPERTY(Category = "Stunned|Hurt")
	TArray<EDamageType> HurtDamageTypes;

	// Duration of stun when pushed back
	UPROPERTY(Category = "Stunned|PushedBack")
	float PushedBackDuration = 1.0;

	// Impulse force when pushed back
	UPROPERTY(Category = "Stunned|PushedBack")
	float PushedBackForce = 200.0;

	// Damage multiplied by this gives additional impulse force when pushed back 
	UPROPERTY(Category = "Stunned|PushedBack")
	float PushedBackDamageFactor = 0.0;

	// Damage types causing the NPC to et pushed back. If empty, any damage type can cause pushback.
	UPROPERTY(Category = "Stunned|PushedBack")
	TArray<EDamageType> PushedBackDamageTypes;

	// For how long we should stay floating
	UPROPERTY(Category = "Stunned|Floating")
	float FloatingDuration = 2.0;

	// At what height above start location we should float up to
	UPROPERTY(Category = "Stunned|Floating")
	float FloatingHeight = 110.0;

	// How fast we accelerate when floating upwards
	UPROPERTY(Category = "Stunned|Floating")
	float FloatingAcceleration = 500.0;
	
	/////////////////////////////////////////////////////////////
	// FLEE BEHAVIOURS											
	/////////////////////////////////////////////////////////////

	// How fast we accelerate when fleeing
	UPROPERTY(Category = "Flee")
	float FleeAcceleration = 500.0;

	UPROPERTY(Category = "Flee")
	float StartFleeingDuration = 1.0;
}

UCLASS(Meta = (ComposeSettingsOnto = "UBasicAISettings"))
class UBasicAISettings_Melee : UBasicAISettings
{
}

UCLASS(Meta = (ComposeSettingsOnto = "UBasicAISettings"))
class UBasicAISettings_Ranged : UBasicAISettings
{
	default bOverride_ChaseMinRange = true;
	default ChaseMinRange = 800.0;

	default bOverride_CircleStrafeEnterRange = true;
	default CircleStrafeEnterRange = 2000.0;
	default bOverride_CircleStrafeMaxRange = true;
	default CircleStrafeMaxRange = 2500.0;
	default bOverride_CircleStrafeMinRange = true;
	default CircleStrafeMinRange = 500.0;

	default bOverride_AttackRange = true;
	default AttackRange = 10000.0;

	default bOverride_EvadeRange = true;
	default EvadeRange = 500.0;
	default bOverride_EvadeMoveSpeed = true;
	default EvadeMoveSpeed = 150.0;
}

UCLASS(Meta = (ComposeSettingsOnto = "UBasicAISettings"))
class UBasicAISettings_FlyingMelee : UBasicAISettings
{
	default bOverride_RoamMoveSpeed = true;
	default RoamMoveSpeed = 1000.0;
	default bOverride_RoamDestinationPauseMin = true;
	default RoamDestinationPauseMin = 0.0;
	default bOverride_RoamDestinationPauseMax = true;
	default RoamDestinationPauseMax = 0.0;

	default bOverride_ScenepointEntryMoveSpeed = true;
	default ScenepointEntryMoveSpeed = 1000.0;

	default bOverride_GentlemanRange = true;
	default GentlemanRange = 1200.0;
	default bOverride_GentlemanStepBackRange = true;
	default GentlemanStepBackRange = 800.0;
	default bOverride_GentlemanMoveSpeed = true;
	default GentlemanMoveSpeed = 1000.0;

	default bOverride_ChaseMinRange = true;
	default ChaseMinRange = 800.0;
	default bOverride_ChaseMoveSpeed = true;
	default ChaseMoveSpeed = 2000.0;

	default bOverride_CircleStrafeSpeed = true;
	default CircleStrafeSpeed = 1000.0;
	default bOverride_CircleStrafeEnterRange = true;
	default CircleStrafeEnterRange = 1500.0;
	default bOverride_CircleStrafeMaxRange = true;
	default CircleStrafeMaxRange = 2000.0;
	default bOverride_CircleStrafeMinRange = true;
	default CircleStrafeMinRange = 300.0;

	default bOverride_EvadeRange = true;
	default EvadeRange = 500.0;
	default bOverride_EvadeMoveSpeed = true;
	default EvadeMoveSpeed = 1000.0;

	default bOverride_ChargeMoveSpeed = true;
	default ChargeMoveSpeed = 2000.0;
	default bOverride_ChargeOffset = true;
	default ChargeOffset = FVector(0.0, 0.0, 200.0);

	default bOverride_CrowdAvoidanceForce = true;
	default CrowdAvoidanceForce = 50.0;

	default bOverride_CrowdAvoidanceMaxRange = true;
	default CrowdAvoidanceMaxRange = 200.0;

	default bOverride_FleeAcceleration = true;
	default FleeAcceleration = 2000.0;
}

UCLASS(Meta = (ComposeSettingsOnto = "UBasicAISettings"))
class UBasicAISettings_FlyingRanged : UBasicAISettings_FlyingMelee
{
	default bOverride_ChaseMinRange = true;
	default ChaseMinRange = 800.0;

	default bOverride_CircleStrafeEnterRange = true;
	default CircleStrafeEnterRange = 2000.0;
	default bOverride_CircleStrafeMaxRange = true;
	default CircleStrafeMaxRange = 2500.0;
	default bOverride_CircleStrafeMinRange = true;
	default CircleStrafeMinRange = 500.0;

	default bOverride_AttackRange = true;
	default AttackRange = 10000.0;
}

