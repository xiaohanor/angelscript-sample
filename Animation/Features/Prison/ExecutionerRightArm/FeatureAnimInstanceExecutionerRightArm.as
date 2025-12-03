UCLASS(Abstract)
class UFeatureAnimInstanceExecutionerRightArm : UHazeAnimInstanceBase
{

	UPROPERTY(Category = "ExecutionerRightArm")
	FHazePlaySequenceData ArmDefaultMH;

	UPROPERTY(Category = "ExecutionerRightArm")
	FHazePlaySequenceData ArmRip;
	
	UPROPERTY(Category = "ExecutionerRightArm")
	FHazePlaySequenceData ArmMH;

	UPROPERTY(Category = "ExecutionerRightArm")
	FHazePlaySequenceData ArmSmashEnter;

	UPROPERTY(Category = "ExecutionerRightArm")
	FHazePlaySequenceData ArmSmashMH;

	UPROPERTY(Category = "ExecutionerRightArm")
	FHazePlaySequenceData ArmSmashAttack;

	UPROPERTY(Category = "ExecutionerRightArm")
	FHazePlaySequenceData ArmSmashExit;

	UPROPERTY(Category = "ExecutionerRightArm")
	FHazePlaySequenceData ArmBatEnter;

	UPROPERTY(Category = "ExecutionerRightArm")
	FHazePlaySequenceData ArmBatMH;

	UPROPERTY(Category = "ExecutionerRightArm")
	FHazePlaySequenceData ArmBatAttack;

	UPROPERTY(Category = "ExecutionerRightArm")
	FHazePlaySequenceData ArmBatExit;

	UPROPERTY(Category = "ExecutionerRightArm")
	FHazePlaySequenceData ArmLoseArm;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	AArenaBossArm ArmActor;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	AArenaBoss ExecutionerActor;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	EArenaBossState CurrentState;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	bool bExitingState = false;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	bool bArmRaising = false;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	bool bArmSmashing = false;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	bool bBatting = false;

	UFUNCTION(BlueprintOverride)
	void BlueprintBeginPlay()
	{
		if (HazeOwningActor == nullptr)
			return;

		ArmActor = Cast<AArenaBossArm>(HazeOwningActor);
		ExecutionerActor = Cast<AArenaBoss>(ArmActor.AttachParentActor);
	}

	UFUNCTION(BlueprintOverride)
	void BlueprintInitializeAnimation()
	{

	}

	UFUNCTION(BlueprintOverride)
	void BlueprintUpdateAnimation(float DeltaTime)
	{
		if (ArmActor == nullptr)
			return;

		if (ExecutionerActor == nullptr)
			return;

		CurrentState = ExecutionerActor.CurrentState;

		bExitingState = ExecutionerActor.AnimationData.bExitingState;

		bArmRaising = ExecutionerActor.AnimationData.ArmSmashState == EArenaBossArmSmashState::RaisingArm;
		bArmSmashing = ExecutionerActor.AnimationData.ArmSmashState == EArenaBossArmSmashState::Smashing;

		bBatting = ExecutionerActor.AnimationData.bBatting;
	}
}
