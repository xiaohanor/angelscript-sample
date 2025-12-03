class UFeatureAnimInstanceMoonGuardian : UHazeAnimInstanceBase
{
	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
    FLocomotionFeatureMoonGuardianAnimData AnimData;

	UPROPERTY(Transient, BlueprintHidden, NotEditable)
    ULocomotionFeatureMoonGuardian Feature;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	bool bHarpFail;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	bool bFootstepFail;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	bool bRoaring;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	EMoonGuardianSleepState SleepState;

	AMoonGuardianCat Cat;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	FName CachedTopLevelGraphRelevantStateName;

    // On Initialize
	UFUNCTION(BlueprintOverride)
	void BlueprintInitializeAnimation()
	{
        if(Feature == nullptr)
            return;

		AnimData = Feature.AnimData;
		Cat = Cast<AMoonGuardianCat>(HazeOwningActor);
		CachedTopLevelGraphRelevantStateName = n"Sleep";
    }

    // On Tick Update
	UFUNCTION(BlueprintOverride)
	void BlueprintUpdateAnimation(float DeltaTime)
	{
        if(Feature == nullptr)
            return;

		if(Cat == nullptr)
			return;

		bHarpFail = Cat.AnimData.bHarpFail;
		bFootstepFail = Cat.AnimData.bFootstepFail;
		bRoaring = Cat.AnimData.bRoaring;
		SleepState = Cat.SleepState;

		CachedTopLevelGraphRelevantStateName = TopLevelGraphRelevantStateName == NAME_None ? n"Sleep" : TopLevelGraphRelevantStateName;
    }
    
}