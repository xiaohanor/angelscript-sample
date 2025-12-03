namespace SummitKnightFeatureTags
{
	const FName Swoop = n"Swoop";
	const FName SmashCrystal = n"SmashCrystal";
	const FName HurtReaction = n"HurtReaction";
	const FName SlamAttack = n"SlamAttack";
	const FName CirclingIntro = n"CirclingIntro";
	const FName SingleSlash = n"SingleSlash";
	const FName DualSlash = n"DualSlash";
	const FName SpinningShockwave = n"SpinningShockwave";
	const FName HomingFireballs = n"HomingFireballs";
	const FName MetalWall = n"MetalWall";
	const FName SpikeTrail = n"SpikeTrail";
	const FName SummonCritters = n"SummonCritters";
	const FName SummonObstacles = n"SummonObstacles";
	const FName LargeAreaStrike = n"LargeAreaStrike";
	const FName SmashGround = n"SmashGround";
	const FName AlmostDeadRecoil = n"AlmostDeadRecoil";
	const FName Death = n"Death";
}


struct FSummitRubyKnightFeatureTags
{
	UPROPERTY()
	FName Swoop = SummitKnightFeatureTags::Swoop;
	UPROPERTY()
	FName SmashCrystal = SummitKnightFeatureTags::SmashCrystal;
	UPROPERTY()
	FName HurtReaction = SummitKnightFeatureTags::HurtReaction;
	UPROPERTY()
	FName SlamAttack = SummitKnightFeatureTags::SlamAttack;
	UPROPERTY()
	FName CirclingIntro = SummitKnightFeatureTags::CirclingIntro;
	UPROPERTY()
	FName SingleSlash = SummitKnightFeatureTags::SingleSlash;
	UPROPERTY()
	FName DualSlash = SummitKnightFeatureTags::DualSlash;
	UPROPERTY()
	FName SpinningShockwave = SummitKnightFeatureTags::SpinningShockwave;
	UPROPERTY()
	FName HomingFireballs = SummitKnightFeatureTags::HomingFireballs;
	UPROPERTY()
	FName MetalWall = SummitKnightFeatureTags::MetalWall;
	UPROPERTY()
	FName SpikeTrail = SummitKnightFeatureTags::SpikeTrail;
	UPROPERTY()
	FName SummonCritters = SummitKnightFeatureTags::SummonCritters;
	UPROPERTY()
	FName SummonObstacles = SummitKnightFeatureTags::SummonObstacles;
	UPROPERTY()
	FName LargeAreaStrike = SummitKnightFeatureTags::LargeAreaStrike;
	UPROPERTY()
	FName SmashGround = SummitKnightFeatureTags::SmashGround;
	UPROPERTY()
	FName AlmostDeadRecoil = SummitKnightFeatureTags::AlmostDeadRecoil;
	UPROPERTY()
	FName Death = SummitKnightFeatureTags::Death;
}

namespace SummitKnightSubTagsSlamAttack
{
	const FName Enter = n"Enter";
	const FName Mh = n"Mh";
	const FName Exit = n"Exit";
	const FName Stun = n"Stun";
}

struct FSummitRubyKnightSlamAttackSubTags
{
	UPROPERTY()
	FName Enter = SummitKnightSubTagsSlamAttack::Enter;
	UPROPERTY()
	FName Mh = SummitKnightSubTagsSlamAttack::Mh;
	UPROPERTY()
	FName Exit = SummitKnightSubTagsSlamAttack::Exit;
	UPROPERTY()
	FName Stun = SummitKnightSubTagsSlamAttack::Stun;
}

namespace SummitKnightSubTagsSwoop
{
	const FName Enter = n"Enter";
	const FName Mh = n"Mh";
	const FName Exit = n"Exit";
}

struct FSummitRubyKnightSwoopSubTags
{
	UPROPERTY()
	FName Enter = SummitKnightSubTagsSlamAttack::Enter;
	UPROPERTY()
	FName Mh = SummitKnightSubTagsSlamAttack::Mh;
	UPROPERTY()
	FName Exit = SummitKnightSubTagsSlamAttack::Exit;
	UPROPERTY()
	FName Stun = SummitKnightSubTagsSlamAttack::Stun;
}

namespace SummitKnightSubTagsSpinningShockwave
{
	const FName Enter = n"Enter";
	const FName Mh = n"Mh";
	const FName Exit = n"Exit";
}

struct FSummitKnightSpinningShockwaveSubTags
{
	UPROPERTY()
	FName Enter = SummitKnightSubTagsSpinningShockwave::Enter;
	UPROPERTY()
	FName Mh = SummitKnightSubTagsSpinningShockwave::Mh;
	UPROPERTY()
	FName Exit = SummitKnightSubTagsSpinningShockwave::Exit;
}

namespace SummitKnightSubTagsAlmostDead
{
	const FName Start = n"Start";
	const FName End = n"End";
}

class UAnimInstanceRubyKnight : UAnimInstanceAIBase
{
	// Animations
    UPROPERTY(BlueprintReadOnly, Category = "Animations|Locomotion")
    FHazePlaySequenceData Mh;

    UPROPERTY(BlueprintReadOnly, Category = "Animations|Locomotion")
    FHazePlaySequenceData Swoop_Enter;

    UPROPERTY(BlueprintReadOnly, Category = "Animations|Locomotion")
    FHazePlaySequenceData Swoop_Mh;

    UPROPERTY(BlueprintReadOnly, Category = "Animations|Locomotion")
    FHazePlaySequenceData Swoop_Exit;

	UPROPERTY(BlueprintReadOnly, Category = "Animations|Locomotion")
    FHazePlaySequenceData CirclingIntro;


	UPROPERTY(BlueprintReadOnly, Category = "Animations|TakeDamage")
    FHazePlaySequenceData SmashCrystal;

	UPROPERTY(BlueprintReadOnly, Category = "Animations|TakeDamage")
    FHazePlaySequenceData HurtReaction;

	UPROPERTY(BlueprintReadOnly, Category = "Animations|TakeDamage")
	FHazePlaySequenceData AlmostDeadStart;

	UPROPERTY(BlueprintReadOnly, Category = "Animations|TakeDamage")
	FHazePlaySequenceData AlmostDeadEnd;

	UPROPERTY(BlueprintReadOnly, Category = "Animations|TakeDamage")
	FHazePlaySequenceData Death;

	UPROPERTY(BlueprintReadOnly, Category = "Animations|Attacks")
    FHazePlaySequenceData SlamAttack_Enter;

	UPROPERTY(BlueprintReadOnly, Category = "Animations|Attacks")
    FHazePlaySequenceData SlamAttack_Mh;

	UPROPERTY(BlueprintReadOnly, Category = "Animations|Attacks")
    FHazePlaySequenceData SlamAttack_Exit;

	UPROPERTY(BlueprintReadOnly, Category = "Animations|Attacks")
    FHazePlaySequenceData SlamAttack_Stun;

	UPROPERTY(BlueprintReadOnly, Category = "Animations|Attacks")
	FHazePlaySequenceData OneSlash;

	UPROPERTY(BlueprintReadOnly, Category = "Animations|Attacks")
	FHazePlaySequenceData TwoSlashes;

	UPROPERTY(BlueprintReadOnly, Category = "Animations|Attacks")
	FHazePlaySequenceData SpinningShockwaveEnter;

	UPROPERTY(BlueprintReadOnly, Category = "Animations|Attacks")
	FHazePlaySequenceData SpinningShockwaveMh;

	UPROPERTY(BlueprintReadOnly, Category = "Animations|Attacks")
	FHazePlaySequenceData SpinningShockwaveExit;

	UPROPERTY(BlueprintReadOnly, Category = "Animations|Attacks")
	FHazePlaySequenceData HomingFireballs;

	
UPROPERTY(BlueprintReadOnly, Category = "Animations|Attacks")
	FHazePlaySequenceData SpikeTrail;

	UPROPERTY(BlueprintReadOnly, Category = "Animations|Attacks")
	FHazePlaySequenceData SummonCritters;

	UPROPERTY(BlueprintReadOnly, Category = "Animations|Attacks")
	FHazePlaySequenceData SummonObstacles;

	UPROPERTY(BlueprintReadOnly, Category = "Animations|Attacks")
	FHazePlaySequenceData LargeAreaStrike;

	UPROPERTY(BlueprintReadOnly, Category = "Animations|Attacks")
	FHazePlaySequenceData SmashGround;


    UPROPERTY(BlueprintReadOnly, Category = "Tags")
	FSummitRubyKnightFeatureTags Tags;

    UPROPERTY(BlueprintReadOnly, Category = "Tags")
	FSummitRubyKnightSlamAttackSubTags SlamAttackSubTags;

    UPROPERTY(BlueprintReadOnly, Category = "Tags")
	FSummitRubyKnightSwoopSubTags SwoopSubTags;

    UPROPERTY(BlueprintReadOnly, Category = "Tags")
	FSummitKnightSpinningShockwaveSubTags SpinningShockwaveSubTags;


	UPROPERTY(BlueprintReadOnly, Category = "AnimData")
	float SpinningShockwavePlayRate = 1.0;

	UBasicAIKnockdownComponent KnockdownComp;
	USummitKnightAnimationComponent KnightAnimComp;
	
	// On Initialize
	UFUNCTION(BlueprintOverride)
	void BlueprintInitializeAnimation()
	{
        Super::BlueprintInitializeAnimation();

		if (HazeOwningActor == nullptr)
			return;
		
		KnockdownComp = UBasicAIKnockdownComponent::GetOrCreate(HazeOwningActor);
		KnightAnimComp = USummitKnightAnimationComponent::GetOrCreate(HazeOwningActor);
    }

    // On Tick Update
	UFUNCTION(BlueprintOverride)
	void BlueprintUpdateAnimation(float DeltaTime)
	{
        Super::BlueprintUpdateAnimation(DeltaTime);

		if (HazeOwningActor == nullptr)
			return;

		// TODO: Investigate why this becomes trash if only set in BlueprintInitializeAnimation!
		KnightAnimComp = USummitKnightAnimationComponent::GetOrCreate(HazeOwningActor);
		if ((KnightAnimComp != nullptr) && (KnightAnimComp.SpinningSlashLoopDuration > 0.0))
			SpinningShockwavePlayRate = SpinningShockwaveMh.Sequence.SequenceLength / KnightAnimComp.SpinningSlashLoopDuration;
    }

	UFUNCTION(BlueprintPure, Meta = (BlueprintThreadSafe))
	bool IsRequestingSubTag()
	{
		return CurrentSubTag != NAME_None;
	}
}

