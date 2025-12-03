UCLASS(Abstract)
class UFeatureAnimInstanceSnowMonkeyConga : UHazeFeatureSubAnimInstance
{
	// The Feature associated with this Feature Sub Anim Instance
	UPROPERTY(Transient, BlueprintHidden, NotEditable)
	ULocomotionFeatureSnowMonkeyConga Feature;

	// Read all Feature Anim Data from this struct in the Anim Graph
	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	FLocomotionFeatureSnowMonkeyCongaAnimData AnimData; 

	UPROPERTY()
	bool bIsDancing;

	UPROPERTY()
	bool bIsPausing;

	UPROPERTY()
	bool bStunned;

	UPROPERTY()
	bool bMyLineCutoff;

	UPROPERTY()
	bool bOtherLineCutoff;

	UPROPERTY()
	bool bIsOnDanceFloor;

	UPROPERTY()
	bool bShouldStrikePose;

	UPROPERTY()
	ECongaLineStrikePose PoseToStrike;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	float PosePlayRate = 1.0;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	int PoseRandIndex;

	bool PrevPose = false;

	AHazePlayerCharacter PlayerRef;
	ACongaLineManager Manager;
	UCongaLinePlayerComponent CongaLineComp;
	UCongaLineStrikePoseComponent StrikePoseComp;

	UFUNCTION(BlueprintOverride)
	void BlueprintBeginPlay()
	{
		if (HazeOwningActor == nullptr)
			return;

		PlayerRef = Cast<AHazePlayerCharacter>(HazeOwningActor.AttachParentActor);
	}

	UFUNCTION(BlueprintOverride)
	void BlueprintInitializeAnimation()
	{
		ULocomotionFeatureSnowMonkeyConga NewFeature = GetFeatureAsClass(ULocomotionFeatureSnowMonkeyConga);
		if (Feature != NewFeature)
		{
			Feature = NewFeature;
			AnimData = NewFeature.AnimData;
		}

		if (Feature == nullptr)
			return;

		CongaLineComp = UCongaLinePlayerComponent::Get(PlayerRef);
		StrikePoseComp = UCongaLineStrikePoseComponent::Get(PlayerRef);

		PrevPose = false;

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

		if(Manager == nullptr)
		{
			Manager = CongaLine::GetManager();
			if(Manager == nullptr)
				return;
		}

		bIsPausing = /*StrikePoseComp.IsInStrikePoseWindow() ||*/ StrikePoseComp.IsStrikingPose();
		bIsDancing = CongaLineComp.IsLeadingCongaLine() && !bIsPausing;
		
		bStunned = CongaLineComp.bStunned;
		bMyLineCutoff = CongaLineComp.bMyLineCutoff;
		bOtherLineCutoff = CongaLineComp.bOtherLineCutoff;
		CongaLineComp.bMyLineCutoff = false;
		CongaLineComp.bOtherLineCutoff = false;
		CongaLineComp.bStunned = false;
		
		
		bIsOnDanceFloor = CongaLineComp.bIsOnDanceFLoor;

		if (bIsOnDanceFloor)
			PosePlayRate = 0.8;
		else
			PosePlayRate = 1.0;
		// if (PrevPose != Manager.IsStrikingPose())
		// {
		// }
		PoseRandIndex = StrikePoseComp.RandomPoseAnimVariation;
		//Print("PoseRandIndex: " + PoseRandIndex, 0.f);


		if(StrikePoseComp.IsStrikingPose())
		{
			bShouldStrikePose = true;
			PoseToStrike = StrikePoseComp.CurrentPose;
		}
		else
		{
			bShouldStrikePose = false;
			PoseToStrike = ECongaLineStrikePose::None;
		}
		
		Print("bShouldStrikePose: " + bShouldStrikePose, 0.f);

		//PrevPose = Manager.IsStrikingPose();
	}

	UFUNCTION(BlueprintOverride)
	bool CanTransitionFrom() const
	{
		return true;
	}

	UFUNCTION(BlueprintOverride)
	void OnTransitionFrom(UHazeFeatureSubAnimInstance NewSubAnimInstance)
	{
	}

	UFUNCTION(BlueprintPure)
	float GetExplicitTime(float Multiplier)
	{
		return CongaLine::GetExplicitTime(Multiplier);
	}
}
