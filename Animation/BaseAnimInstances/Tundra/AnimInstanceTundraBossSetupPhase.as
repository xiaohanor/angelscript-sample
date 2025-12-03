enum ETundraBossSetupAttackAnim
{
	None,
	Appear,
	Smash,
	Claw01,
	Claw02,
	BreakIce,
	Pounce,
	BreakFromUnderIce,
	BreakFromUnderIceMirrored
}
class UAnimInstanceTundraBossSetupPhase : UHazeAnimInstanceBase 
{
	UPROPERTY(Category = "Sequences")
	FHazePlaySequenceData SneakUp;
	
	UPROPERTY(Category = "Sequences")
	FHazePlaySequenceData SlamIce;

	UPROPERTY(Category = "Sequences")
	FHazePlaySequenceData ClawStrike01;

	UPROPERTY(Category = "Sequences")
	FHazePlaySequenceData ClawStrike02;

	UPROPERTY(Category = "Sequences")
	FHazePlaySequenceData BreakIce;

	UPROPERTY(Category = "Sequences")
	FHazePlaySequenceData BreakFromUnderIce;

	UPROPERTY(Category = "Sequences")
	FHazePlaySequenceData BreakFromUnderIceMirrored;

	UPROPERTY(Category = "Sequences")
	FHazePlaySequenceData Breach;

	UPROPERTY()
	bool bSmashReset = false;
	UPROPERTY()
	bool bBreakFromUnderIceReset = false;

	UPROPERTY(EditAnywhere)
	ETundraBossSetupAttackAnim TundraBossSetupAttackAnim;

	ATundraBossSetup Boss;

	UFUNCTION(BlueprintOverride)
	void BlueprintInitializeAnimation()
	{
		if(HazeOwningActor == nullptr)	
			return;

		Boss = Cast<ATundraBossSetup>(HazeOwningActor);
	}

	UFUNCTION(BlueprintOverride)
	void BlueprintUpdateAnimation(float DeltaTimeX)
	{
		if(Boss == nullptr)
			return;
		
		TundraBossSetupAttackAnim = Boss.CurrentAnimationState;
		bSmashReset = GetAnimBoolParam(n"SmashReset", true);
		bBreakFromUnderIceReset = GetAnimBoolParam(n"BreakFromUnderIceReset", true);
	}

	UFUNCTION()
	float GetTundraBossSetupAnimationDuration(ETundraBossSetupAttackAnim AnimationState)
	{
		switch(AnimationState)
		{
			case ETundraBossSetupAttackAnim::Appear:
				return SneakUp.Sequence.GetPlayLength();
			case ETundraBossSetupAttackAnim::Smash:
				return SlamIce.Sequence.GetPlayLength() / SlamIce.Sequence.GetRateScale();
			case ETundraBossSetupAttackAnim::Claw01:
				return ClawStrike01.Sequence.GetPlayLength() / ClawStrike01.Sequence.GetRateScale();
			case ETundraBossSetupAttackAnim::Claw02:
				return ClawStrike02.Sequence.GetPlayLength() / ClawStrike02.Sequence.GetRateScale();
			case ETundraBossSetupAttackAnim::BreakIce:
				return BreakIce.Sequence.GetPlayLength();
			case ETundraBossSetupAttackAnim::Pounce:
				return Breach.Sequence.GetPlayLength();
			case ETundraBossSetupAttackAnim::BreakFromUnderIce:
				return BreakFromUnderIce.Sequence.GetPlayLength();
			case ETundraBossSetupAttackAnim::BreakFromUnderIceMirrored:
				return BreakFromUnderIceMirrored.Sequence.GetPlayLength();
			case ETundraBossSetupAttackAnim::None:
				return 0;
		}
	}
}