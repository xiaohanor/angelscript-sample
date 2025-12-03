namespace FeatureTagClimbingCritter
{
	const FName Locomotion = n"Locomotion";
	const FName Grab = n"Grab";
}

struct FSummitClimbingCritterFeatureTags
{
	UPROPERTY()
	FName Locomotion = FeatureTagClimbingCritter::Locomotion;
	
	UPROPERTY()
	FName Grab = FeatureTagClimbingCritter::Grab;
}

namespace SummitClimbingCritterSubTags
{
	const FName GrabEnter = n"GrabEnter";
	const FName GrabEnterVar1 = n"GrabEnterVar1";
	const FName GrabEnterVar2 = n"GrabEnterVar2";
	const FName GrabEnterVar3 = n"GrabEnterVar3";
	
}

struct FSummitClimbingCritterSubTags
{
	UPROPERTY()
	FName GrabEnter = SummitClimbingCritterSubTags::GrabEnter;

	UPROPERTY()
	FName GrabEnterVar1 = SummitClimbingCritterSubTags::GrabEnterVar1;

	UPROPERTY()
	FName GrabEnterVar2 = SummitClimbingCritterSubTags::GrabEnterVar2;

	UPROPERTY()
	FName GrabEnterVar3 = SummitClimbingCritterSubTags::GrabEnterVar3;
	
}

class UAnimInstanceSummitClimbingCritter : UAnimInstanceAIBase
{
	// Animations

	UPROPERTY(BlueprintReadOnly, Category = "Animations|Locomotion")
    FHazePlaySequenceData MoveFwd;

	UPROPERTY(BlueprintReadOnly, Category = "Animations|Grab")
    FHazePlaySequenceData GrabStart;

	UPROPERTY(BlueprintReadOnly, Category = "Animations|Grab")
    FHazePlaySequenceData GrabStartMh;

	UPROPERTY(BlueprintReadOnly, Category = "Animations|Grab")
    FHazePlaySequenceData GrabEnter;

	UPROPERTY(BlueprintReadOnly, Category = "Animations|Grab")
    FHazePlaySequenceData GrabMh;

	UPROPERTY(BlueprintReadOnly, Category = "Animations|Grab")
    FHazePlaySequenceData GrabStartVar1;

	UPROPERTY(BlueprintReadOnly, Category = "Animations|Grab")
    FHazePlaySequenceData GrabMhVar1;

	UPROPERTY(BlueprintReadOnly, Category = "Animations|Grab")
    FHazePlaySequenceData GrabStartVar2;

	UPROPERTY(BlueprintReadOnly, Category = "Animations|Grab")
    FHazePlaySequenceData GrabMhVar2;

	UPROPERTY(BlueprintReadOnly, Category = "Animations|Grab")
    FHazePlaySequenceData GrabStartVar3;

	UPROPERTY(BlueprintReadOnly, Category = "Animations|Grab")
    FHazePlaySequenceData GrabMhVar3;

	// FeatureTags and SubTags

	UPROPERTY(BlueprintReadOnly, NotEditable)
	FSummitClimbingCritterFeatureTags FeatureTags;

	UPROPERTY(BlueprintReadOnly, NotEditable)
	FSummitClimbingCritterSubTags SubTags;

    // On Initialize
	UFUNCTION(BlueprintOverride)
	void BlueprintInitializeAnimation()
	{
        Super::BlueprintInitializeAnimation();
    }

    // On Tick Update
	UFUNCTION(BlueprintOverride)
	void BlueprintUpdateAnimation(float DeltaTime)
	{
        Super::BlueprintUpdateAnimation(DeltaTime);
    }
}