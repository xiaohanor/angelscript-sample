UCLASS(Abstract)
class UFeatureAnimInstanceDanceShowdown : UHazeFeatureSubAnimInstance
{
	// The Feature associated with this Feature Sub Anim Instance
	UPROPERTY(Transient, BlueprintHidden, NotEditable)
	ULocomotionFeatureDanceShowdown Feature;

	// Read all Feature Anim Data from this struct in the Anim Graph
	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	FLocomotionFeatureDanceShowdownAnimData AnimData;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	UDanceShowdownPlayerComponent DanceComp;

	// Add Custom Variables Here

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	FVector2D DanceInput;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	EDanceShowdownPose PoseToStrike;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	bool bChangedPose;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	bool bHasInput;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	bool bHasMonkeyOnFace;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	int StageNumber;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	float TempoMultiplier;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	float ExplicitTime;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	int RandomMhInt = 0;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	float DiscoPlayRate = 1.25;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	float BellyPlayRate = 1.5;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	float BreakdancePlayRate = 1.5;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	bool bTutorialActive = false;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	bool bDancePaused = false;
	
	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	bool bSuccess;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	bool bFail;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	float StickInputX = 0;

	ADanceShowdownManager Manager;

	UFUNCTION(BlueprintOverride)
	void BlueprintBeginPlay()
	{
		if (HazeOwningActor == nullptr)
			return;

	}

	UFUNCTION(BlueprintOverride)
	void BlueprintInitializeAnimation()
	{
		ULocomotionFeatureDanceShowdown NewFeature = GetFeatureAsClass(ULocomotionFeatureDanceShowdown);
		if (Feature != NewFeature)
		{
			Feature = NewFeature;
			AnimData = NewFeature.AnimData;
		}

		if (Feature == nullptr)
			return;

		DanceComp = UDanceShowdownPlayerComponent::Get(HazeOwningActor.AttachParentActor);
		Manager = DanceShowdown::GetManager();

		auto PhysComp = UHazePhysicalAnimationComponent::Get(HazeOwningActor);
		if (PhysComp != nullptr)
			PhysComp.bAllowInSequence = true;
	}

	UFUNCTION(BlueprintOverride)
	void BlueprintUpdateAnimation(float DeltaTime)
	{
		if (Feature == nullptr)
			return;

		if(HazeOwningActor == nullptr)
			return;

		StageNumber = Manager.RhythmManager.GetCurrentStage();

		auto PlayerAnimData = UDanceShowdownPlayerComponent::Get(HazeOwningActor.AttachParentActor).AnimData;
		//FVector2D NewDanceInput = PlayerAnimData.Input;
		StickInputX = PlayerAnimData.StickInput.X;
		PoseToStrike = PlayerAnimData.Pose;
		bSuccess = PlayerAnimData.bSuccess;
		bFail = PlayerAnimData.bFail;
		bHasMonkeyOnFace = PlayerAnimData.bHasMonkeyOnFace;
		ExplicitTime = Manager.RhythmManager.GetExplicitTime();
		bTutorialActive = Manager.TutorialManager.bTutorialActive;
		RandomMhInt = Manager.RhythmManager.IdleAnimationIndex;
		if (bFail)
			bDancePaused = false;
		else 
			bDancePaused = Manager.RhythmManager.IsPaused();
		// if (!bDancePaused)
		// 	bSuccess = false;
		// else 
		// 	bSuccess = PlayerAnimData.bSuccess;


		//NewDanceInput.X = Math::RoundToInt(NewDanceInput.X);
		//NewDanceInput.Y = Math::RoundToInt(NewDanceInput.Y);

		// bHasInput = NewDanceInput != FVector2D::ZeroVector;

		// bChangedPose = NewDanceInput != DanceInput;
		// if (bChangedPose)
		// {
		// 	DanceInput = NewDanceInput;
		// }
		//Print("StageNumber: " + StageNumber, 0.f);
		/*
		Print("bChangedPose: " + bChangedPose, 0.f); // Emils Print
		Print("DanceInput: " + DanceInput, 0.f); // Emils Print
		Print("bHasInput: " + bHasInput, 0.f); // Emils Print
		*/
		// Implement Custom Stuff Here
	}

	UFUNCTION(BlueprintOverride)
	bool CanTransitionFrom() const
	{
		// Implement Custom Stuff Here

		return true;
	}

	UFUNCTION(BlueprintOverride)
	void OnTransitionFrom(UHazeFeatureSubAnimInstance NewSubAnimInstance)
	{
		// Implement Custom Stuff Here
	}
}
