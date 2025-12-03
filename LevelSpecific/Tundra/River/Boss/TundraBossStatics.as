enum ETundraBossStates
{
	Wait,
	WaitUnlimited,
	NotSpawned,
	Spawn,
	SpawnLastPhase,
	Defeated,
	ReturnAfterFirstSphereHit,
	JumpToNextLocation,
	TriggerFallingIceSpikes,
	TriggerFallingIceSpikesSlowVersion,
	TriggerRedIce,
	TriggerRedIceSlowVersion,
	StopFallingIceSpikes,
	StopRedIce,
	BreakingIce,
	RingsOfIceSpikes,
	ClawAttack,
	ClawAttackShort,
	ChargeAttack,
	IceBreathe,
	SphereDamage,
	PunchDamage,
	Grabbed,
	BreakFree,
	BreakFreeFromStruggle,
	Whirlwind,
	WhirlwindWithJump,
	Furball,
	FurballUnlimited,
	StopFurball,
	GetBackUpAfterSphere,
	FinalPunch,
	Hidden,
	None
}

enum ETundraBossPhases
{
	None,
	Phase_1A,
	Phase_1A_Repeat,
	Phase_1B,
	Phase_1B_Repeat,
	Phase_1C,
	Phase_1C_Repeat,
	Phase_2A,
	Phase_2A_Repeat,
	Phase_2B,
	Phase_2B_Repeat,
	Phase_2C,
	Phase_2C_Repeat,
	Dead,
	DevTest,
}

struct FTundraBossAttackQueueStruct
{
	UPROPERTY()
	TArray<ETundraBossStates> Queue;

	UPROPERTY()
	ETundraBossPhases NextPhaseIfNotDamaged;

	UPROPERTY()
	ETundraBossPhases NextPhaseIfDamaged;

	UPROPERTY()
	float HealthDuringPhase = 1;

	UPROPERTY()
	float HealthAfterDamagedInPhase = 1;

	UPROPERTY()
	bool bBossDiesAfterPhase = false;

	UPROPERTY()
	ATundraShapeshiftingRespawnPoint RespawnPointInPhase;

	UPROPERTY()
	bool bCloseAttackActive = true;
}

enum ETundraBossDamageSource
{
	None,
	GroundSlam,
	SphereLauncher
}

enum ETundraBossGrabStates
{
	Struggle,
	DraggedDown,
	Loop,
	MAX,
}