namespace FeatureTagSummitDecimator
{
	const FName Locomotion = n"Locomotion";

	const FName Turn = n"Turn";

	const FName TurnJump = n"TurnJump";

	const FName TakeDamage = n"TakeDamage";
	
	const FName Spin = n"Spin";

	const FName Magic = n"Magic";
	
}

struct FSummitDecimatorFeatureTags
{
	UPROPERTY()
	FName Locomotion = FeatureTagSummitDecimator::Locomotion;

	UPROPERTY()
	FName Turn = FeatureTagSummitDecimator::Turn;

	UPROPERTY()
	FName TurnJump = FeatureTagSummitDecimator::TurnJump;

	UPROPERTY()
	FName TakeDamage = FeatureTagSummitDecimator::TakeDamage;
	
	UPROPERTY()
	FName Spin = FeatureTagSummitDecimator::Spin;

	UPROPERTY()
	FName Magic = FeatureTagSummitDecimator::Magic;
		
}

namespace SubTagSummitDecimatorAttack
{
	const FName SpinStart = n"SpinStart";
	
	const FName SpinStop= n"SpinStop";

	const FName SpinTakeDamage= n"SpinTakeDamage";

	const FName SpinStopTakeDamage= n"SpinStopTakeDamage";

	const FName SpinJump= n"SpinJump";

	const FName Push= n"Push";
	
	const FName PushPanic= n"PushPanic";
	
}

struct FSummitDecimatorAttackSubTags
{
	UPROPERTY()
	FName SpinStart= SubTagSummitDecimatorAttack::SpinStart;
	
	UPROPERTY()
	FName SpinStop = SubTagSummitDecimatorAttack::SpinStop;

	UPROPERTY()
	FName SpinTakeDamage = SubTagSummitDecimatorAttack::SpinTakeDamage;

	UPROPERTY()
	FName SpinStopTakeDamage = SubTagSummitDecimatorAttack::SpinStopTakeDamage;

	UPROPERTY()
	FName SpinJump = SubTagSummitDecimatorAttack::SpinJump;

	UPROPERTY()
	FName Push = SubTagSummitDecimatorAttack::Push;

	UPROPERTY()
	FName PushPanic = SubTagSummitDecimatorAttack::PushPanic;
	
}

namespace SubTagSummitDecimatorMagic
{
	const FName Magic1 = n"Magic1";
	
	const FName Magic2= n"Magic2";

	const FName Magic3= n"Magic3";
	
}

struct FSummitDecimatorMagicSubTags
{
	UPROPERTY()
	FName Magic1= SubTagSummitDecimatorMagic::Magic1;
	
	UPROPERTY()
	FName Magic2 = SubTagSummitDecimatorMagic::Magic2;

	UPROPERTY()
	FName Magic3 = SubTagSummitDecimatorMagic::Magic3;
	
}



class UAnimInstanceDecimator : UAnimInstanceAIBase
{
	// Animations

    UPROPERTY(BlueprintReadOnly, Category = "Animations|Locomotion")
    FHazePlaySequenceData Mh;

	 UPROPERTY(BlueprintReadOnly, Category = "Animations|Locomotion")
    FHazePlaySequenceData MhTakeDamage;

	UPROPERTY(BlueprintReadOnly, Category = "Animations|Locomotion")
    FHazePlaySequenceData RunStart;
	
	UPROPERTY(BlueprintReadOnly, Category = "Animations|Locomotion")
    FHazePlayBlendSpaceData Run;

	UPROPERTY(BlueprintReadOnly, Category = "Animations|Locomotion")
    FHazePlaySequenceData RunTakeDamage;

	UPROPERTY(BlueprintReadOnly, Category = "Animations|Locomotion")
    FHazePlayBlendSpaceData Turn;

	UPROPERTY(BlueprintReadOnly, Category = "Animations|Locomotion")
    FHazePlayBlendSpaceData TurnWalk;
	
	UPROPERTY(BlueprintReadOnly, Category = "Animations|Locomotion")
    FHazePlayBlendSpaceData TurnJump;

	UPROPERTY(BlueprintReadOnly, Category = "Animations|Spin")
    FHazePlaySequenceData SpinEnter;

	UPROPERTY(BlueprintReadOnly, Category = "Animations|Spin")
    FHazePlaySequenceData SpinEnterFromKnockDown;

	UPROPERTY(BlueprintReadOnly, Category = "Animations|Spin")
    FHazePlaySequenceData SpinEnterFromTakeDamage;
	
	UPROPERTY(BlueprintReadOnly, Category = "Animations|Spin")
    FHazePlaySequenceData Spin;

	UPROPERTY(BlueprintReadOnly, Category = "Animations|Spin")
    FHazePlaySequenceData SpinJump;

	UPROPERTY(BlueprintReadOnly, Category = "Animations|Spin")
    FHazePlaySequenceData SpinStop;

	UPROPERTY(BlueprintReadOnly, Category = "Animations|Spin")
    FHazePlaySequenceData SpinStopMh;
	
	UPROPERTY(BlueprintReadOnly, Category = "Animations|Spin")
    FHazePlaySequenceData SpinTakeDamage;

	UPROPERTY(BlueprintReadOnly, Category = "Animations|Spin")
    FHazePlaySequenceData SpinStopTakeDamage;

	UPROPERTY(BlueprintReadOnly, Category = "Animations|Spin")
    FHazePlaySequenceData BellyFlop;

	UPROPERTY(BlueprintReadOnly, Category = "Animations|Spin")
    FHazePlaySequenceData PushEnter;

	UPROPERTY(BlueprintReadOnly, Category = "Animations|Spin")
    FHazePlaySequenceData PushMh;

	UPROPERTY(BlueprintReadOnly, Category = "Animations|Spin")
    FHazePlaySequenceData PushPanic;

	UPROPERTY(BlueprintReadOnly, Category = "Animations|Magic")
    FHazePlaySequenceData Magic1;

	UPROPERTY(BlueprintReadOnly, Category = "Animations|Magic")
    FHazePlaySequenceData Magic2;

	UPROPERTY(BlueprintReadOnly, Category = "Animations|Magic")
    FHazePlaySequenceData Magic3;

	

	UPROPERTY(BlueprintReadOnly, NotEditable)
	FSummitDecimatorFeatureTags FeatureTags;

	UPROPERTY(BlueprintReadOnly, NotEditable)
	FSummitDecimatorAttackSubTags AttackSubTags;

	UPROPERTY(BlueprintReadOnly, NotEditable)
	FSummitDecimatorMagicSubTags MagicSubTags;

	

	

	UBasicAIKnockdownComponent KnockdownComp;

	UHazeMovementComponent MoveComp;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	bool bSkipStart;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	bool bPlayingHitReaction;
	
	

	UFUNCTION(BlueprintOverride)
	void BlueprintBeginPlay()
	{
		MoveComp = UHazeMovementComponent::Get(HazeOwningActor);
	}


	// On Initialize
	UFUNCTION(BlueprintOverride)
	void BlueprintInitializeAnimation()
	{
        Super::BlueprintInitializeAnimation();

		bSkipStart = GetAnimBoolParam(n"SkipMovementStart", true); 
		
		
		
    }

    // On Tick Update
	UFUNCTION(BlueprintOverride)
	void BlueprintUpdateAnimation(float DeltaTime)
	{
        Super::BlueprintUpdateAnimation(DeltaTime);
		if (CurrentSubTag == AttackSubTags.SpinTakeDamage)
			bPlayingHitReaction = true;

		
    }

	UFUNCTION()
	void AnimNotify_StopPlaying()
	{
		bPlayingHitReaction = false;
	}

	

}