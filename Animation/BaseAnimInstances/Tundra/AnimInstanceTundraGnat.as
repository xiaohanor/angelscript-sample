namespace TundraGnatTags
{
	const FName GrabAttack = n"GrabAttack";
	const FName Attack = n"Attack";
	const FName Stunned = n"Stunned";
	const FName StartingTaunt = n"StartingTaunt";
	const FName LatchOn = n"LatchOn";
	const FName GnatapultReload = n"GnatapultReload";
	const FName GnatapultLaunch = n"GnatapultLaunch";
	const FName GrabbedByMonkey = n"GrabbedByMonkey";
	const FName ThrownByMonkey = n"ThrownByMonkey";
	const FName TargetedByMonkeyThrow = n"TargetedByMonkeyThrow";
	const FName HitByThrownMonkey = n"HitByThrownMonkey";
	const FName Leaping = n"Leaping";
}

class UAnimInstanceTundraGnat : UAnimInstanceAIBase
{
	UPROPERTY(BlueprintReadOnly, Category = "Animations")
	FHazePlayBlendSpaceData Locomotion;

	UPROPERTY(BlueprintReadOnly, Category = "Animations")
	FHazePlayRndSequenceData Annoy;

	UPROPERTY(BlueprintReadOnly, Category = "Animations")
	FHazePlayRndSequenceData StartingTaunt;

	UPROPERTY(BlueprintReadOnly, Category = "Animations")
	FHazePlaySequenceData GrabbedByMonkey;

	UPROPERTY(BlueprintReadOnly, Category = "Animations")
	FHazePlaySequenceData GrabbedByMonkeyMH;

	UPROPERTY(BlueprintReadOnly, Category = "Animations")
	FHazePlaySequenceData ThrownByMonkey;

	UPROPERTY(BlueprintReadOnly, Category = "Animations")
	FHazePlaySequenceData ThrownMh;

	UPROPERTY(BlueprintReadOnly, Category = "Animations")
	FHazePlayBlendSpaceData BackAway;

	// Leaping onto walking stick e.g. from monkey tower
	UPROPERTY(BlueprintReadOnly, Category = "Animations")
	FHazePlaySequenceData Leap;

	UPROPERTY(Transient)
	bool bIsGrabbing;

	UPROPERTY(Transient)
	bool bIsPerformingStartingTaunt;

	UPROPERTY(Transient)
	bool bIsGrabbedByMonkey;

	UPROPERTY(Transient)
	bool bIsThrownByMonkey;

	UPROPERTY(Transient)
	bool bIsTargetedByMonkeyThrow;

	UPROPERTY(Transient)
	bool bIsLeaping;

	UFUNCTION(BlueprintOverride)
	void BlueprintBeginPlay()
	{
		DevTogglesGnape::ShowAnimTag.MakeVisible();
	}

	UFUNCTION(BlueprintOverride)
	void BlueprintInitializeAnimation()
	{
		Super::BlueprintInitializeAnimation();
	}

	UFUNCTION(BlueprintOverride)
	void BlueprintUpdateAnimation(float DeltaTime)
	{
		Super::BlueprintUpdateAnimation(DeltaTime);

		bIsLeaping = IsCurrentFeatureTag(TundraGnatTags::Leaping);
		bIsPerformingStartingTaunt = IsCurrentFeatureTag(TundraGnatTags::StartingTaunt);

		bIsGrabbing = IsCurrentFeatureTag(TundraGnatTags::GrabAttack);

		bIsTargetedByMonkeyThrow = IsCurrentFeatureTag(TundraGnatTags::TargetedByMonkeyThrow);
		bIsGrabbedByMonkey = IsCurrentFeatureTag(TundraGnatTags::GrabbedByMonkey);
		bIsThrownByMonkey = IsCurrentFeatureTag(TundraGnatTags::ThrownByMonkey) || IsCurrentFeatureTag(TundraGnatTags::HitByThrownMonkey);

		if (DevTogglesGnape::ShowAnimTag.IsEnabled())
			Debug::DrawDebugString(HazeOwningActor.ActorLocation + FVector(0,0,50), "" + CurrentFeatureTag, Scale = 2);		
	}

	float GetStartingTauntMaxDuration() const
	{
		float MaxDuration = 0.0;
		for (FHazeAnimSeqAndProbability Anim : StartingTaunt.Sequences)
		{
			if (Anim.Probability == 0.0)
				continue;
			if (Anim.Sequence.ScaledPlayLength > MaxDuration)
				MaxDuration = Anim.Sequence.ScaledPlayLength;
		}
		return MaxDuration;
	}
}