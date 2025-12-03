event void FMioReachedInside();
event void FMioReachedOutside();
event void FBallBossDied();
event void FBallBossCritEvent();
event void FBallBossPhaseChanged(ESkylineBallBossPhase NewPhase);
event void FBallBossChaseLaserSplineChanged();

event void FBallBossTelegraphEyeStart();
event void FBallBossTelegraphEyeStop();

enum ESkylineBallBossPhase
{
	Chase,
	PostChaseElevator,
	Top,
	TopGrappleFailed1,
	TopMioOn1,
	TopAlignMioToStage,
	TopShieldShockwave,
	TopMioOff2,
	TopGrappleFailed2,
	TopMioOn2,
	TopMioOnEyeBroken,
	TopMioIn,
	TopMioInKillWeakpoint,
	TopDeath,
	TopSmallBoss
}

namespace SkylineBallBossTags
{
	const FName BallBossBlockedInCutsceneTag = n"BallBossBlockedInCutscene";
	const FName BallBoss = n"BallBoss";
	const FName Rotation = n"Rotation";
	const FName RotationOffset = n"RotationOffset";
	const FName RotationDetonateOffset = n"RotationDetonateOffset";
	const FName RotationOffsetIdle = n"RotationOffsetIdle";
	const FName Position = n"Position";
	const FName PositionDash = n"PositionDash";
	const FName PositionSelection = n"PositionSelection";
	const FName Action = n"Action";
	const FName Debug = n"Debug";
	const FName SmallBoss = n"SmallBoss";
}

enum EBallBossAlignRotationDataPrio
{
	Lowest,
	Low,
	Medium,
	High
}

struct FBallBossAlignRotationData
{
	USceneComponent PartComp;
	USceneComponent OverrideTargetComp;
	FVector BallLocalDirection = FVector::ZeroVector;
	float HeightOffset = 0.0;
	bool bUseRandomOffset = false;
	bool bAccelerateAlignTowardsTarget = false;
	bool bSnapOverTime = false;
	bool bContinuousUpdate = true;
	EBallBossAlignRotationDataPrio Priority = EBallBossAlignRotationDataPrio::Low;

	bool IsPartOrTarget(USceneComponent SceneComp) const
	{
	 	return PartComp == SceneComp || SceneComp == OverrideTargetComp;
	}
}

struct FBallBossShieldEffectData
{
	UNiagaraComponent VFXComp = nullptr;
	float VFXLifetime = 0.0;
}
