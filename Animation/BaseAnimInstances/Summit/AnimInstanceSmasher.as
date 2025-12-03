namespace SummitSmasherFeatureTag
{
	const FName Locomotion = n"Locomotion";
	const FName Attack = n"Attack";
	const FName JumpAttack = n"JumpAttack";
	const FName Teleport = n"Teleport";
	const FName Melted = n"Melted";
	const FName Enter = n"Enter";
	const FName Exit = n"Exit";

}

struct FSummitSmasherFeatureTags
{
	UPROPERTY()
	FName Locomotion = SummitSmasherFeatureTag::Locomotion;
	UPROPERTY()
	FName Attack = SummitSmasherFeatureTag::Attack;
	UPROPERTY()
	FName JumpAttack = SummitSmasherFeatureTag::JumpAttack;
	UPROPERTY()
	FName Teleport = SummitSmasherFeatureTag::Teleport;
	UPROPERTY()
	FName Melted = SummitSmasherFeatureTag::Melted;
}

namespace SubTagSmasherMelted
{
	const FName Enter = n"Enter";
	const FName Mh = n"Mh";
	const FName Exit = n"Exit";
}

struct FSmasherMeltedSubTags
{
	UPROPERTY()
	FName Enter = SubTagSmasherMelted::Enter;

	UPROPERTY()
	FName Mh = SubTagSmasherMelted::Mh;

	UPROPERTY()
	FName Exit = SubTagSmasherMelted::Exit;
}


class UAnimInstanceSmasher : UAnimInstanceAIBase
{
	// Animations 

	UPROPERTY(BlueprintReadOnly, Category = "Animations|Locomotion")
    FHazePlayBlendSpaceData Movement;

	UPROPERTY(BlueprintReadOnly, Category = "Animations|Locomotion")
    FHazePlayBlendSpaceData Mh;

	UPROPERTY(BlueprintReadOnly, Category = "Animations|Teleport")
    FHazePlaySequenceData Teleport;

	UPROPERTY(BlueprintReadOnly, Category = "Animations|Attack")
    FHazePlaySequenceData Attack;

	UPROPERTY(BlueprintReadOnly, Category = "Animations|Attack")
    FHazePlaySequenceData JumpAttack;

	UPROPERTY(BlueprintReadOnly, Category = "Animations|Melted")
    FHazePlaySequenceData Melted;

	UPROPERTY(BlueprintReadOnly, Category = "Animations|Melted")
    FHazePlaySequenceData Enter;

	UPROPERTY(BlueprintReadOnly, Category = "Animations|Melted")
    FHazePlaySequenceData Exit;


	// FeatureTags and SubTags
	UPROPERTY(BlueprintReadOnly, NotEditable)
	FSummitSmasherFeatureTags FeatureTags;

	UPROPERTY(BlueprintReadOnly, NotEditable)
	FSmasherMeltedSubTags MeltedSubTags;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	bool bWantsToMove = false;

	USummitSmasherPauseMovementComponent PauseMoveComp;

	UFUNCTION(BlueprintOverride)
	void BlueprintInitializeAnimation()
	{
		Super::BlueprintInitializeAnimation();
		if (HazeOwningActor != nullptr)
			PauseMoveComp = USummitSmasherPauseMovementComponent::Get(HazeOwningActor);
	}

	UFUNCTION(BlueprintOverride)
	void BlueprintUpdateAnimation(float DeltaTime)
	{
		Super::BlueprintUpdateAnimation(DeltaTime);
		if (PauseMoveComp != nullptr)
			bWantsToMove = PauseMoveComp.bWantsToMove;
	}

	UAnimSequence GetRequestedAnimation(FName Tag, FName SubTag) override
	{
		if (Tag == SummitSmasherFeatureTag::Attack)
			return Attack.Sequence;
		if (Tag == SummitSmasherFeatureTag::JumpAttack)
			return JumpAttack.Sequence;
		if (Tag == SummitSmasherFeatureTag::Melted)
		{
			if (SubTag == SubTagSmasherMelted::Enter)
				return Enter.Sequence;
			if (SubTag == SubTagSmasherMelted::Exit)
				return Exit.Sequence;
			return Melted.Sequence;
		}
		return nullptr;
	}
}