class UAnimInstanceTundraMonkeyCrowd : UHazeAnimInstanceBase
{
	UPROPERTY(BlueprintReadOnly)
	FLocomotionFeatureMonkeyCrowdAnimData AnimData;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	bool bSuccess;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	bool bFail;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	bool bIdling;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	bool bIsDJ;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	bool bDJDanceShowdownFail = false;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	float PlayRate;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	EMonkeyCongaStage Stage;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	int DanceShowdownStage;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	ECrowdMonkeyState CrowdState;

	ADanceShowdownCrowdMonkey MonkeyCrowd;

	UFUNCTION(BlueprintOverride)
	void BlueprintInitializeAnimation()
	{
		if (HazeOwningActor != nullptr)
		{
			MonkeyCrowd = Cast < ADanceShowdownCrowdMonkey>(HazeOwningActor);
			if (MonkeyCrowd != nullptr)
			{
				AnimData = MonkeyCrowd.AnimationFeature.AnimData;
			}
		}
	}


	UFUNCTION(BlueprintOverride)
	void BlueprintUpdateAnimation(float DeltaTime)
	{
		if(HazeOwningActor == nullptr)
		if (MonkeyCrowd == nullptr)
			return;
		
		if (!HazeOwningActor.HasActorBegunPlay())
			return;

		if(DanceShowdown::GetManager() != nullptr)
		{
			DanceShowdownStage = DanceShowdown::GetManager().RhythmManager.GetCurrentStage();
			CrowdState = DanceShowdown::GetManager().CrowdMonkeyManager.CurrentCrowdState;
			// Print("CrowdState: " + CrowdState, 0.f);
		}

		bSuccess = MonkeyCrowd.AnimData.bSuccess;
		bFail = MonkeyCrowd.AnimData.bFail;
		Stage = MonkeyCrowd.AnimData.Stage;
		bIdling = !bFail && !bSuccess;
		bIsDJ = MonkeyCrowd.bIsDJ;

		if ((Stage == EMonkeyCongaStage::SimonSays || Stage == EMonkeyCongaStage::CongaLine) && !bIsDJ)
			PlayRate = 1.6;
		
		else
			PlayRate = 1.0;

		if (Stage == EMonkeyCongaStage::DanceShowdown && bIsDJ && bFail)
			bDJDanceShowdownFail = true;
		else
			bDJDanceShowdownFail = false;

	}
}