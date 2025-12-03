enum EWalkerHatch
{
	None,
	FrontLeft,
	RearLeft,
	FrontRight,
	RearRight,
}

namespace FeatureTagWalker
{
	const FName Intro = n"Intro";
	const FName Fall = n"Fall";
	const FName Hit = n"Hit";
	const FName JumpAttack = n"JumpAttack";
	const FName SweepingLaser = n"SweepingLaser";
	const FName SpinningLaser = n"SpinningLaser";
	const FName Spawner = n"Spawner";
	const FName Suspended = n"Suspended";
	const FName Exposed = n"Exposed";
	const FName ChargeAttack = n"ChargeAttack";
	const FName FireBurst = n"FireBurst";
	const FName Turn = n"Turn";
	const FName Walk = n"Walk";
	const FName SmashCage = n"SmashCage";
	const FName HeadSprayGas = n"HeadSprayGas";
	const FName HeadGrenadeReaction = n"HeadGrenadeReaction";
	const FName HeadHurtReaction = n"HeadHurtReaction";
	const FName HeadRiseFromPool = n"HeadRiseFromPool";
	const FName AtBottomOfPool = n"AtBottomOfPool";
	const FName HeadCrash = n"HeadCrash";
	const FName HatchFlight = n"HatchFlight";
	const FName OpenLegHatch = n"OpenLegHatch";
	const FName CloseLegHatch = n"CloseLegHatch";
	const FName ExposeSharkFin = n"ExposeSharkFin";
	const FName RetractSharkFin = n"RetractSharkFin";
}

struct FWalkerFeatureTags
{
	UPROPERTY()
	FName Intro = FeatureTagWalker::Intro;
	UPROPERTY()
	FName Fall = FeatureTagWalker::Fall;
	UPROPERTY()
	FName Hit = FeatureTagWalker::Hit;
	UPROPERTY()
	FName JumpAttack = FeatureTagWalker::JumpAttack;
	UPROPERTY()
	FName SweepingLaser = FeatureTagWalker::SweepingLaser;
	UPROPERTY()
	FName SpinningLaser = FeatureTagWalker::SpinningLaser;
	UPROPERTY()
	FName Spawner = FeatureTagWalker::Spawner;
	UPROPERTY()
	FName Suspended = FeatureTagWalker::Suspended;
	UPROPERTY()
	FName Exposed = FeatureTagWalker::Exposed;
	UPROPERTY()
	FName ChargeAttack = FeatureTagWalker::ChargeAttack;
	UPROPERTY()
	FName FireBurst = FeatureTagWalker::FireBurst;
	UPROPERTY()
	FName Turn = FeatureTagWalker::Turn;
	UPROPERTY()
	FName Walk = FeatureTagWalker::Walk;
	UPROPERTY()
	FName SmashCage = FeatureTagWalker::SmashCage;
	UPROPERTY()
	FName HeadSprayGas = FeatureTagWalker::HeadSprayGas;
	UPROPERTY()
	FName HeadGrenadeReaction = FeatureTagWalker::HeadGrenadeReaction;
	UPROPERTY()
	FName HeadHurtReaction = FeatureTagWalker::HeadHurtReaction;
	UPROPERTY()
	FName AtBottomOfPool = FeatureTagWalker::AtBottomOfPool;
	UPROPERTY()
	FName HeadRiseFromPool = FeatureTagWalker::HeadRiseFromPool;
	UPROPERTY()
	FName HeadCrash = FeatureTagWalker::HeadCrash;
	UPROPERTY()
	FName HatchFlight = FeatureTagWalker::HatchFlight;
	UPROPERTY()
	FName OpenLegHatch = FeatureTagWalker::OpenLegHatch;
	UPROPERTY()
	FName CloseLegHatch = FeatureTagWalker::CloseLegHatch;
	UPROPERTY()
	FName ExposeSharkFin = FeatureTagWalker::ExposeSharkFin;
	UPROPERTY()
	FName RetractSharkFin = FeatureTagWalker::RetractSharkFin;

}

namespace SubTagWalkerIntro
{
	const FName Idle = n"Idle";
	const FName End = n"End";
}

struct FWalkerIntroSubTags
{
	UPROPERTY()
	FName Idle = SubTagWalkerIntro::Idle;
	UPROPERTY()
	FName End = SubTagWalkerIntro::End;
}

namespace SubTagWalkerTurn
{
	const FName Left90 = n"Left90";
	const FName Left45 = n"Left45";
	const FName Left22 = n"Left22";
	const FName Right90 = n"Right90";
	const FName Right45 = n"Right45";
	const FName Right22 = n"Right22";
}

struct FWalkerTurnSubTags
{
	UPROPERTY()
	FName Left90 = SubTagWalkerTurn::Left90;
	UPROPERTY()
	FName Left45 = SubTagWalkerTurn::Left45;
	UPROPERTY()
	FName Left22 = SubTagWalkerTurn::Left22;
	UPROPERTY()
	FName Right90 = SubTagWalkerTurn::Right90;
	UPROPERTY()
	FName Right45 = SubTagWalkerTurn::Right45;
	UPROPERTY()
	FName Right22 = SubTagWalkerTurn::Right22;
}

namespace SubTagWalkerWalk
{
	const FName Forward = n"Forward";
	const FName Backward = n"Backward";
	const FName Left = n"Left";
	const FName Right = n"Right";
}

struct FWalkerWalkSubTags
{
	UPROPERTY()
	FName Forward = SubTagWalkerWalk::Forward;
	UPROPERTY()
	FName Backward = SubTagWalkerWalk::Backward;
	UPROPERTY()
	FName Left = SubTagWalkerWalk::Left;
	UPROPERTY()
	FName Right = SubTagWalkerWalk::Right;
}

namespace SubTagWalkerFall
{
	const FName Forward = n"Forward";
	const FName Left = n"Left";
	const FName Right = n"Right";
	const FName ForwardMh = n"ForwardMh";
	const FName LeftMh = n"LeftMh";
	const FName RightMh = n"RightMh";
}

struct FWalkerFallSubTags
{
	UPROPERTY()
	FName Forward = SubTagWalkerFall::Forward;
	UPROPERTY()
	FName Left = SubTagWalkerFall::Left;
	UPROPERTY()
	FName Right = SubTagWalkerFall::Right;
	UPROPERTY()
	FName ForwardMh = SubTagWalkerFall::ForwardMh;
	UPROPERTY()
	FName LeftMh = SubTagWalkerFall::LeftMh;
	UPROPERTY()
	FName RightMh = SubTagWalkerFall::RightMh;
}

namespace SubTagWalkerHit
{
	const FName Left = n"Left";
	const FName Right = n"Right";
}

struct FWalkerHitSubTags
{
	UPROPERTY()
	FName Left = SubTagWalkerHit::Left;
	UPROPERTY()
	FName Right = SubTagWalkerHit::Right;
}

namespace SubTagWalkerSweepingLaser
{
	const FName Start = n"Start";
	const FName End = n"End";
}

struct FWalkerSweepingLaserSubTags
{
	UPROPERTY()
	FName Start = SubTagWalkerSweepingLaser::Start;
	UPROPERTY()
	FName End = SubTagWalkerSweepingLaser::End;
}

namespace SubTagWalkerSpinningLaser
{
	const FName Start = n"Start";
	const FName End = n"End";
}

struct FWalkerSpinningLaserSubTags
{
	UPROPERTY()
	FName Start = SubTagWalkerSpinningLaser::Start;
	UPROPERTY()
	FName End = SubTagWalkerSpinningLaser::End;
}

namespace SubTagWalkerSpawner
{
	const FName Standing = n"Standing";
	const FName ProtectingLegs = n"ProtectingLegs";
	const FName ProtectingLegsEnd = n"ProtectingLegsEnd";
	const FName ProtectingLegsSpawning = n"ProtectingLegsSpawning";
	const FName ProtectingLegsMH = n"ProtectingLegsMH";
	const FName StandingSpawn = n"StandingSpawn";
}

struct FWalkerSpawnerSubTags
{
	UPROPERTY()
	FName Standing = SubTagWalkerSpawner::Standing;
	UPROPERTY()
	FName ProtectingLegs = SubTagWalkerSpawner::ProtectingLegs;
	UPROPERTY()
	FName ProtectingLegsSpawning = SubTagWalkerSpawner::ProtectingLegsSpawning;
	UPROPERTY()
	FName ProtectingLegsMH = SubTagWalkerSpawner::ProtectingLegsMH;
	UPROPERTY()
	FName ProtectingLegsEnd = SubTagWalkerSpawner::ProtectingLegsEnd;
	UPROPERTY()
	FName StandingSpawn = SubTagWalkerSpawner::StandingSpawn;
}

namespace SubTagWalkerSuspended
{
	const FName IntroForward = n"IntroForward";
	const FName IntroLeft = n"IntroLeft";
	const FName IntroRight = n"IntroRight";
	const FName Idle = n"Idle";
	const FName Spawning = n"Spawning";
	const FName SprayGas = n"SprayGas";
	const FName FrontShieldDown = n"FrontShieldDown";
	const FName RearShieldDown = n"RearShieldDown";
	const FName FrontHurtReaction = n"FrontHurtReaction";
	const FName RearHurtReaction = n"RearHurtReaction";
	const FName FrontCablesCut = n"FrontCablesCut";
	const FName RearCablesCut = n"RearCablesCut";
	const FName FallDownFrontFirst = n"FallDownFrontFirst";
	const FName FallDownRearFirst = n"FallDownRearFirst";
}

struct FWalkerSuspendedSubTags
{
	UPROPERTY()
	FName IntroForward = SubTagWalkerSuspended::IntroForward;
	UPROPERTY()
	FName IntroLeft = SubTagWalkerSuspended::IntroLeft;
	UPROPERTY()
	FName IntroRight = SubTagWalkerSuspended::IntroRight;
	UPROPERTY()
	FName Idle = SubTagWalkerSuspended::Idle;
	UPROPERTY()
	FName Spawning = SubTagWalkerSuspended::Spawning;
	UPROPERTY()
	FName SprayGas = SubTagWalkerSuspended::SprayGas;
	UPROPERTY()
	FName FrontShieldDown = SubTagWalkerSuspended::FrontShieldDown;
	UPROPERTY()
	FName RearShieldDown = SubTagWalkerSuspended::RearShieldDown;
	UPROPERTY()
	FName FrontHurtReaction = SubTagWalkerSuspended::FrontHurtReaction;
	UPROPERTY()
	FName RearHurtReaction = SubTagWalkerSuspended::RearHurtReaction;
	UPROPERTY()
	FName FrontCablesCut = SubTagWalkerSuspended::FrontCablesCut;
	UPROPERTY()
	FName RearCablesCut = SubTagWalkerSuspended::RearCablesCut;
	UPROPERTY()
	FName FallDownFrontFirst = SubTagWalkerSuspended::FallDownFrontFirst;
	UPROPERTY()
	FName FallDownRearFirst = SubTagWalkerSuspended::FallDownRearFirst;
}

namespace SubTagWalkerExposed
{
	const FName Idle = n"Idle";
	const FName Falling = n"Falling";
	const FName Exploded = n"Exploded";
}

struct FWalkerExposedSubTags
{
	UPROPERTY()
	FName Idle = SubTagWalkerExposed::Idle;
	UPROPERTY()
	FName Falling = SubTagWalkerExposed::Falling;
	UPROPERTY()
	FName Exploded = SubTagWalkerExposed::Exploded;
}

namespace SubTagWalkerChargeAttack
{
	const FName Telegraph = n"Telegraph";
	const FName Stop = n"Stop";
}

struct FWalkerChargeAttackSubTags
{
	UPROPERTY()
	FName Telegraph = SubTagWalkerChargeAttack::Telegraph;
	UPROPERTY()
	FName Stop = SubTagWalkerChargeAttack::Stop;
}

namespace SubTagWalkerSmashCage
{
	const FName Right = n"Right";
	const FName Left = n"Left";
	const FName Attack = n"Attack";
}

struct FWalkerSmashCageSubTags
{
	UPROPERTY()
	FName Right = SubTagWalkerSmashCage::Right;
	UPROPERTY()
	FName Left = SubTagWalkerSmashCage::Left;
	UPROPERTY()
	FName Attack = SubTagWalkerSmashCage::Attack;
}

namespace SubTagWalkerHeadSprayGas
{
	const FName Start = n"Start";
	const FName End = n"End";
}

struct FWalkerHeadSprayGasSubTags
{
	UPROPERTY()
	FName Start = SubTagWalkerHeadSprayGas::Start;
	UPROPERTY()
	FName End = SubTagWalkerHeadSprayGas::End;
}

namespace SubTagWalkerHeadGrenadeReaction
{
	const FName HitRight = n"HitRight";
	const FName HitLeft = n"HitLeft";
	const FName Eat = n"Eat";
	const FName EatenDetonate = n"EatenDetonate";
}

struct FWalkerHeadGrenadeReactionSubTags
{
	UPROPERTY()
	FName HitRight = SubTagWalkerHeadGrenadeReaction::HitRight;
	UPROPERTY()
	FName HitLeft = SubTagWalkerHeadGrenadeReaction::HitLeft;
	UPROPERTY()
	FName Eat = SubTagWalkerHeadGrenadeReaction::Eat;
	UPROPERTY()
	FName EatenDetonate = SubTagWalkerHeadGrenadeReaction::EatenDetonate;
}

namespace SubTagWalkerHeadHurtReaction
{
	const FName Repeat = n"Repeat";
}

struct FWalkerHeadHurtReactionSubTags
{
	UPROPERTY()
	FName Repeat = SubTagWalkerHeadHurtReaction::Repeat;
}

namespace SubTagWalkerHeadCrash
{
	const FName FallDown = n"FallDown";
	const FName StayCrashed = n"StayCrashed";
	const FName Attack = n"Attack";
	const FName Recover = n"Recover";
}

struct FWalkerHeadCrashSubTags
{
	UPROPERTY()
	FName FallDown = SubTagWalkerHeadCrash::FallDown;
	UPROPERTY()
	FName Attack = SubTagWalkerHeadCrash::Attack;
	UPROPERTY()
	FName StayCrashed = SubTagWalkerHeadCrash::StayCrashed;
	UPROPERTY()
	FName Recover = SubTagWalkerHeadCrash::Recover;
}

namespace SubTagWalkerHatchFlight
{
	const FName Mh = n"Mh";
	const FName ThrowOff = n"ThrowOff";
	const FName Hitreactions = n"HitReactions";
	const FName StartLiftOff = n"StartLiftOff";
}

struct FWalkerHatchFlightSubTags
{
	UPROPERTY()
	FName MH = SubTagWalkerHatchFlight::Mh;
	UPROPERTY()
	FName ThrowOff = SubTagWalkerHatchFlight::ThrowOff;
	UPROPERTY()
	FName Hitreactions = SubTagWalkerHatchFlight::Hitreactions;
	UPROPERTY()
	FName StartLiftOff = SubTagWalkerHatchFlight::StartLiftOff;
}

UCLASS(Abstract)
class UFeatureAnimInstanceWalker : UAnimInstanceAIBase
{
	default RootMotionMode = ERootMotionMode::RootMotionFromEverything;

	UPROPERTY(Category = "Sequences")
	FHazePlaySequenceData Intro;

	UPROPERTY(Category = "Sequences")
	FHazePlaySequenceData IntroEnd;

	UPROPERTY(Category = "Sequences")
	FHazePlaySequenceData Idle;

	UPROPERTY(Category = "Sequences")
	FHazePlaySequenceData WalkForward;

	UPROPERTY(Category = "Sequences")
	FHazePlaySequenceData WalkBackward;

	UPROPERTY(Category = "Sequences")
	FHazePlaySequenceData WalkLeft;

	UPROPERTY(Category = "Sequences")
	FHazePlaySequenceData WalkRight;

	UPROPERTY(Category = "Sequences")
	FHazePlaySequenceData TurnLeft90;

	UPROPERTY(Category = "Sequences")
	FHazePlaySequenceData TurnLeft45;

	UPROPERTY(Category = "Sequences")
	FHazePlaySequenceData TurnLeft22;

	UPROPERTY(Category = "Sequences")
	FHazePlaySequenceData TurnRight90;

	UPROPERTY(Category = "Sequences")
	FHazePlaySequenceData TurnRight45;

	UPROPERTY(Category = "Sequences")
	FHazePlaySequenceData TurnRight22;

	UPROPERTY(Category = "Sequences")
	FHazePlaySequenceData SweepingLaserStart;

	UPROPERTY(Category = "Sequences")
	FHazePlaySequenceData SweepingLaserMH;

	UPROPERTY(Category = "Sequences")
	FHazePlaySequenceData SweepingLaserEnd;

	UPROPERTY(Category = "Sequences")
	FHazePlaySequenceData SpinningLaserStart;

	UPROPERTY(Category = "Sequences")
	FHazePlaySequenceData SpinningLaserMH;

	UPROPERTY(Category = "Sequences")
	FHazePlaySequenceData SpinningLaserEnd;

	UPROPERTY(Category = "Sequences")
	FHazePlaySequenceData HitLeft;

	UPROPERTY(Category = "Sequences")
	FHazePlaySequenceData HitRight;

	UPROPERTY(Category = "Sequences")
	FHazePlaySequenceData JumpAttack;

	UPROPERTY(Category = "Sequences")
	FHazePlaySequenceData SpawnerStanding;

	UPROPERTY(Category = "Sequences")
	FHazePlaySequenceData SpawnerStandingMh;

	UPROPERTY(Category = "Sequences")
	FHazePlaySequenceData SpawnerProtectingLegsStart;

	UPROPERTY(Category = "Sequences")
	FHazePlaySequenceData SpawnerProtectingLegsMH;

	UPROPERTY(Category = "Sequences")
	FHazePlaySequenceData SpawnerProtectingLegsSpawnBuzzer;

	UPROPERTY(Category = "Sequences")
	FHazePlaySequenceData SpawnerProtectingLegsEnd;

	UPROPERTY(Category = "Sequences")
	FHazePlaySequenceData FallForward;

	UPROPERTY(Category = "Sequences")
	FHazePlaySequenceData FallLeft;

	UPROPERTY(Category = "Sequences")
	FHazePlaySequenceData FallRight;

	UPROPERTY(Category = "Sequences")
	FHazePlaySequenceData FireBurst;

	UPROPERTY(Category = "Sequences")
	FHazePlaySequenceData SmashCageTurnRight;

	UPROPERTY(Category = "Sequences")
	FHazePlaySequenceData SmashCageTurnLeft;

	UPROPERTY(Category = "Sequences")
	FHazePlaySequenceData SmashCageAttack;

	UPROPERTY(Category = "Sequences")
	FHazePlaySequenceData SuspendedIntroForward;

	UPROPERTY(Category = "Sequences")
	FHazePlaySequenceData SuspendedIntroLeft;

	UPROPERTY(Category = "Sequences")
	FHazePlaySequenceData SuspendedIntroRight;

	UPROPERTY(Category = "Sequences")
	FHazePlaySequenceData SuspendedMH;

	UPROPERTY(Category = "Sequences")
	FHazePlaySequenceData SuspendedMH_FrontCableCut;

	UPROPERTY(Category = "Sequences")
	FHazePlaySequenceData SuspendedMH_RearCableCut;

	UPROPERTY(Category = "Sequences")
	FHazePlaySequenceData SuspendedSpawning;

	UPROPERTY(Category = "Sequences")
	FHazePlayBlendSpaceData SuspendedSprayGas;

	UPROPERTY(Category = "Sequences")
	FHazePlaySequenceData SuspendedFrontShieldDown;

	UPROPERTY(Category = "Sequences")
	FHazePlaySequenceData SuspendedRearShieldDown;

	UPROPERTY(Category = "Sequences")
	FHazePlaySequenceData SuspendedFrontHurtReaction;

	UPROPERTY(Category = "Sequences")
	FHazePlaySequenceData SuspendedRearHurtReaction;

	UPROPERTY(Category = "Sequences")
	FHazePlaySequenceData SuspendedFrontCablesCut;

	UPROPERTY(Category = "Sequences")
	FHazePlaySequenceData SuspendedRearCablesCut;

	UPROPERTY(Category = "Sequences")
	FHazePlaySequenceData SuspendedFallDownFrontFirst;

	UPROPERTY(Category = "Sequences")
	FHazePlaySequenceData SuspendedFallDownRearFirst;

	UPROPERTY(Category = "Sequences")
	FHazePlaySequenceData HeadRiseFromPool;

	UPROPERTY(Category = "Sequences")
	FHazePlaySequenceData HeadIdle;

	UPROPERTY(Category = "Sequences")
	FHazePlaySequenceData HeadOpenJaw;

	UPROPERTY(Category = "Sequences")
	FHazePlaySequenceData HeadCloseJaw;

	UPROPERTY(Category = "Sequences")
	FHazePlaySequenceData HeadGrenadeHitLeft;

	UPROPERTY(Category = "Sequences")
	FHazePlaySequenceData HeadGrenadeHitRight;

	UPROPERTY(Category = "Sequences")
	FHazePlaySequenceData HeadGrenadeEat;

	UPROPERTY(Category = "Sequences")
	FHazePlaySequenceData HeadGrenadeEatDetonate;

	UPROPERTY(Category = "Sequences")
	FHazePlayRndSequenceData HeadHurtReaction;

	UPROPERTY(Category = "Sequences")
	FHazePlaySequenceData HeadCrash;

	UPROPERTY(Category = "Sequences")
	FHazePlaySequenceData HeadCrash_Mh;

	UPROPERTY(Category = "Sequences")
	FHazePlaySequenceData HeadCrash_Attack;

	UPROPERTY(Category = "Sequences")
	FHazePlaySequenceData HeadCrashRecover;

	UPROPERTY(Category = "Sequences")
	FHazePlaySequenceData HatchStartLiftOff;

	UPROPERTY(Category = "Sequences")
	FHazePlaySequenceData HatchMh;

	UPROPERTY(Category = "Sequences")
	FHazePlayRndSequenceData HatchHitReactions;

	UPROPERTY(Category = "Sequences")
	FHazePlaySequenceData HatchThrowOff;

	UPROPERTY(Category = "Sequences")
	FHazePlaySequenceData HeadHatchStruggle;

	UPROPERTY(Category = "Sequences")
	FHazePlaySequenceData HeadHatchOpening;

	UPROPERTY(Category = "Sequences")
	FHazePlaySequenceData HeadHatchClosing;

	UPROPERTY(Category = "Sequences")
	FHazePlaySequenceData OpenLegHatch;

	UPROPERTY(Category = "Sequences")
	FHazePlaySequenceData CloseLegHatch;

	UPROPERTY(Category = "Sequences")
	FHazePlaySequenceData ExposeSharkFin;

	UPROPERTY(Category = "Sequences")
	FHazePlaySequenceData RetractSharkFin;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	FWalkerFeatureTags FeatureTags;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	FWalkerIntroSubTags IntroSubTags;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	FWalkerWalkSubTags WalkSubTags;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	FWalkerTurnSubTags TurnSubTags;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	FWalkerSmashCageSubTags SmashCageSubTags;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	FWalkerFallSubTags FallSubTags;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	FWalkerHitSubTags HitSubTags;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	FWalkerSpawnerSubTags SpawnerSubTags;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	FWalkerSweepingLaserSubTags SweepingLaserSubTags;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	FWalkerSpinningLaserSubTags SpinningLaserSubTags;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	FWalkerSuspendedSubTags SuspendedSubTags;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	FWalkerExposedSubTags ExposedSubTags;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	FWalkerChargeAttackSubTags ChargeAttackSubTags;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	FWalkerHeadSprayGasSubTags HeadSprayGasSubTags;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	FWalkerHeadGrenadeReactionSubTags HeadGrenadeReactionSubTags;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	FWalkerHeadHurtReactionSubTags HeadHurtReactionSubTags;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	FWalkerHeadCrashSubTags HeadCrashSubTags;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	FWalkerHatchFlightSubTags HatchFlightSubTags;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	FRotator UpperBodyAdditionalRotation = FRotator::ZeroRotator;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	bool bFrontCableCut = false;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	bool bRearCableCut = false;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	float SuspendedSprayGasAlpha = 0.0;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	float SuspendedSpawningAlpha = 0.0;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable, Category = "Fin")
	bool bHeadFinDeployed;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable, Category = "HeadHatch")
	bool bHeadHatchOpening;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable, Category = "HeadHatch")
	bool bHeadHatchClosing;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable, Category = "HeadHatch")
	bool bHeadHatchStruggle;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable, Category = "LegHatch")
	EWalkerHatch CurrentHatch;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable, Category = "LegHatch")
	bool bPlayHatchOpenLeftFront;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable, Category = "LegHatch")
	bool bPlayHatchOpenLeftBack;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable, Category = "LegHatch")
	bool bPlayHatchOpenRightFront;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable, Category = "LegHatch")
	bool bPlayHatchOpenRightBack;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable, Category = "Legs")
	bool bSimulatePhysicsLeftFrontMiddleLeg;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable, Category = "Legs")
	bool bSimulatePhysicsLeftBackMiddleLeg;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable, Category = "Legs")
	bool bSimulatePhysicsRightFrontMiddleLeg;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable, Category = "Legs")
	bool bSimulatePhysicsRightBackMiddleLeg;

	UPROPERTY(EditDefaultsOnly)
	UHazePhysicalAnimationProfile PhysProfile;

	FHazeAcceleratedFloat AccSuspendedSprayGasAlpha;
	FHazeAcceleratedFloat AccSuspendedSpawningAlpha;

	UIslandWalkerSwivelComponent SwivelComp;
	UIslandWalkerComponent WalkerComp;
	UIslandWalkerHeadComponent HeadComp;

	UFUNCTION(BlueprintOverride)
	void BlueprintInitializeAnimation()
	{
		Super::BlueprintInitializeAnimation();

		if (HazeOwningActor == nullptr)
			return;

		SwivelComp = UIslandWalkerSwivelComponent::Get(HazeOwningActor);
		WalkerComp = UIslandWalkerComponent::Get(HazeOwningActor);
		HeadComp = UIslandWalkerHeadComponent::Get(HazeOwningActor);
		AccSuspendedSprayGasAlpha.SnapTo(0.0);
		AccSuspendedSpawningAlpha.SnapTo(0.0);

		if (WalkerComp != nullptr)
		{
			auto PhysComp = UHazePhysicalAnimationComponent::GetOrCreate(HazeOwningActor);
			if (PhysComp != nullptr)
				PhysComp.OnPhysProfileApplied.AddUFunction(this, n"UpdateSimulatedLegs");
		}
	}

	UFUNCTION(BlueprintOverride)
	void BlueprintUpdateAnimation(float DeltaTime)
	{
		Super::BlueprintUpdateAnimation(DeltaTime);

		if ((HazeOwningActor != nullptr) && HazeOwningActor.bIsControlledByCutscene)
			UpperBodyAdditionalRotation = FRotator::ZeroRotator;
		else if (SwivelComp != nullptr)
			UpperBodyAdditionalRotation.Yaw = SwivelComp.SwivelYaw;
		if (WalkerComp != nullptr)
		{
			bFrontCableCut = WalkerComp.bFrontCableCut;
			bRearCableCut = WalkerComp.bRearCableCut;
			CurrentHatch = WalkerComp.CurrentOpenHatch;

			// Auto-close hatch when protecting legs (visual only, you will still be able to destroy leg if you are quick enough)
			if (IsCurrentFeatureTag(FeatureTagWalker::Spawner) && IsCurrentSubTag(SubTagWalkerSpawner::ProtectingLegs))
				CurrentHatch = EWalkerHatch::None;

			if (GetAnimTrigger(n"LegDestroyed"))
			{
				auto PhysComp = UHazePhysicalAnimationComponent::GetOrCreate(HazeOwningActor);
				if (PhysComp != nullptr)
					PhysComp.ApplyProfileAsset(this, PhysProfile, 0);
				UpdateSimulatedLegs();
			}
		}
		if (HeadComp != nullptr)
		{
			bHeadHatchOpening = (HeadComp.HeadHatchState == EWalkerHeadHatchState::Open);
			bHeadHatchClosing = (HeadComp.HeadHatchState == EWalkerHeadHatchState::Closed);
			bHeadHatchStruggle = (HeadComp.HeadHatchState == EWalkerHeadHatchState::Struggling);
			bHeadFinDeployed = HeadComp.bFinDeployed;
		}

		SuspendedSprayGasAlpha = AccSuspendedSprayGasAlpha.AccelerateTo(IsCurrentSubTag(SubTagWalkerSuspended::SprayGas) ? 1.0 : 0.0, 5.0, DeltaTime);
		SuspendedSpawningAlpha = AccSuspendedSpawningAlpha.AccelerateTo(IsCurrentSubTag(SubTagWalkerSuspended::Spawning) ? 1.0 : 0.0, 2.0, DeltaTime);

		if (CurrentHatch == EWalkerHatch::FrontLeft)
			bPlayHatchOpenLeftFront = true;
		else if (CurrentHatch == EWalkerHatch::RearLeft)
			bPlayHatchOpenLeftBack = true;
		else if (CurrentHatch == EWalkerHatch::FrontRight)
			bPlayHatchOpenRightFront = true;
		else if (CurrentHatch == EWalkerHatch::RearRight)
			bPlayHatchOpenRightBack = true;
	}

	UFUNCTION()
	void AnimNotify_HatchLeftFront()
	{
		bPlayHatchOpenLeftFront = false;
	}

	UFUNCTION()
	void AnimNotify_HatchLeftBack()
	{
		bPlayHatchOpenLeftBack = false;
	}

	UFUNCTION()
	void AnimNotify_HatchRightFront()
	{
		bPlayHatchOpenRightFront = false;
	}

	UFUNCTION()
	void AnimNotify_HatchRightBack()
	{
		bPlayHatchOpenRightBack = false;
	}

	UFUNCTION()
	void UpdateSimulatedLegs(UHazePhysicalAnimationProfile Profile = nullptr)
	{
		if (HazeOwningActor == nullptr)
			return;

		auto PhysComp = UHazePhysicalAnimationComponent::GetOrCreate(HazeOwningActor);
		PhysComp.SetBoneSimulated(n"LeftFrontMiddleShoulder", WalkerComp.DestroyedLegs.Contains(n"LeftFrontMiddleLeg3"));
		PhysComp.SetBoneSimulated(n"LeftBackMiddleShoulder", WalkerComp.DestroyedLegs.Contains(n"LeftBackMiddleLeg4"));
		PhysComp.SetBoneSimulated(n"RightFrontMiddleShoulder", WalkerComp.DestroyedLegs.Contains(n"RightFrontMiddleLeg3"));
		PhysComp.SetBoneSimulated(n"RightBackMiddleShoulder", WalkerComp.DestroyedLegs.Contains(n"RightBackMiddleLeg4"));

		PhysComp.SetBoneSimulated(n"RightFrontMiddleLeg3", WalkerComp.DestroyedLegs.Contains(n"RightFrontMiddleLeg3"), 0);
		PhysComp.SetBoneSimulated(n"RightBackMiddleLeg4", WalkerComp.DestroyedLegs.Contains(n"RightBackMiddleLeg4"), 0);
		PhysComp.SetBoneSimulated(n"LeftBackMiddleLeg4", WalkerComp.DestroyedLegs.Contains(n"LeftBackMiddleLeg4"), 0);
		PhysComp.SetBoneSimulated(n"LeftFrontMiddleLeg3", WalkerComp.DestroyedLegs.Contains(n"LeftFrontMiddleLeg3"), 0);
	}
}
