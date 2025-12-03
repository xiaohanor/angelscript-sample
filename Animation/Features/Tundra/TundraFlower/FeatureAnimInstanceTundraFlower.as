UCLASS(Abstract)
class UFeatureAnimInstanceTundraFlower : UHazeAnimInstanceBase
{
	// Animations
	UPROPERTY(Category = "Animation")
	FHazePlaySequenceData BudMH;

	UPROPERTY(Category = "Animation")
	FHazePlaySequenceData BudToOpen;

	UPROPERTY(Category = "Animation")
	FHazePlaySequenceData OpenMH;

	UPROPERTY(Category = "Animation")
	FHazePlaySequenceData OpenToBud;

	UPROPERTY(Category = "Animation")
	FHazePlaySequenceData ShotReaction;

	UPROPERTY(Category = "Animation")
	FHazePlaySequenceData ShotMH;

	UPROPERTY(Category = "Animation")
	FHazePlaySequenceData ShotMHToOpenMH;


	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	bool bOpen;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	bool bClose;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	bool bShot;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	bool bExit;

	ATundraRangedLifeGivingActor RangedLifeActor;
	ATundraGroundedLifeGivingActor GroundedLifeActor;

	UFUNCTION(BlueprintOverride)
	void BlueprintBeginPlay()
	{
		if(HazeOwningActor == nullptr)
			return;

		RangedLifeActor = Cast<ATundraRangedLifeGivingActor>(HazeOwningActor);
		GroundedLifeActor = Cast<ATundraGroundedLifeGivingActor>(HazeOwningActor);
	}

	UFUNCTION(BlueprintOverride)
	void BlueprintInitializeAnimation()
	{
		if(HazeOwningActor == nullptr)
			return;

	}

	UFUNCTION(BlueprintOverride)
	void BlueprintUpdateAnimation(float DeltaTime)
	{
		if(HazeOwningActor == nullptr)
			return;

		if(RangedLifeActor != nullptr)
		{
			bShot = RangedLifeActor.AnimData.bShot;
			bExit = !RangedLifeActor.AnimData.bInteractingWith;
			bOpen = RangedLifeActor.AnimData.IsLookingAt();
			bClose = !RangedLifeActor.AnimData.IsLookingAt();
		}

		if(GroundedLifeActor != nullptr)
		{
			bShot = GroundedLifeActor.AnimData.bInteracting;
			bExit = !GroundedLifeActor.AnimData.bInteracting;
			bOpen = GroundedLifeActor.AnimData.bWithinRange;
			bClose = !GroundedLifeActor.AnimData.bWithinRange;
		}
	}
}
