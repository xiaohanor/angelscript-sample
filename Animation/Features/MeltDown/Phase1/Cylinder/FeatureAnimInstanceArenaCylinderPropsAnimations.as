struct FArenaCylinderPropsAnimations
{
	UPROPERTY(Category = "Cylinder")
	FHazePlaySequenceData StartPhase;

	UPROPERTY(Category = "Cylinder")
	FHazePlaySequenceData BendArena;

	UPROPERTY(Category = "Cylinder")
	FHazePlaySequenceData FirstRotationLeft90;

	UPROPERTY(Category = "Cylinder")
	FHazePlaySequenceData RotationRight180;

	UPROPERTY(Category = "Cylinder")
	FHazePlaySequenceData SecondRotationLeft90;

	UPROPERTY(Category = "Cylinder")
	FHazePlaySequenceData Reset;

	UPROPERTY(Category = "Cylinder")
	FHazePlaySequenceData FinishPhase;
}

UCLASS()
class ULocomotionFeatureArenaCylinderProps : UDataAsset
{
	UPROPERTY(Meta = ShowOnlyInnerProperties)
	FArenaCylinderPropsAnimations AnimData;
}

UCLASS(Abstract)
class UFeatureAnimInstanceArenaCylinderProps : UHazeAnimInstanceBase
{
	UPROPERTY()
	ULocomotionFeatureArenaCylinderProps FrontRow1Feature;
	UPROPERTY()
	ULocomotionFeatureArenaCylinderProps FrontRow2Feature;
	UPROPERTY()
	ULocomotionFeatureArenaCylinderProps FrontRow3Feature;
	UPROPERTY()
	ULocomotionFeatureArenaCylinderProps FrontRow4Feature;
	UPROPERTY()
	ULocomotionFeatureArenaCylinderProps FrontRow5Feature;
	UPROPERTY()
	ULocomotionFeatureArenaCylinderProps FrontRow6Feature;
	UPROPERTY()
	ULocomotionFeatureArenaCylinderProps FrontRow7Feature;
	UPROPERTY()
	ULocomotionFeatureArenaCylinderProps FrontRow8Feature;
	UPROPERTY()
	ULocomotionFeatureArenaCylinderProps FrontRow9Feature;
	UPROPERTY()
	ULocomotionFeatureArenaCylinderProps FrontRow10Feature;

	UPROPERTY()
	FArenaCylinderPropsAnimations AnimData;

	// The fraction of the time of each move the arena makes. Using this 0-1 float in the ABP to then multiply by the sequence length of each corresponding animation, the animation only progresses from start (0) to completed (1) with this value
	UPROPERTY()
	float PlatformMoveTimer;

	UFUNCTION(BlueprintOverride)
	void BlueprintBeginPlay()
	{
		if (HazeOwningActor == nullptr)
			return;

		// This is a hack, because the skeletal meshes are on the same actor
		// if (OwningComponent.Name == n"LeftGauntletMesh")
		// 	AnimData = LeftGauntletFeature.AnimData;
		// else if (OwningComponent.Name == n"RightGauntletMesh")
		// 	AnimData = RightGauntletFeature.AnimData;
		//  else
		//  	AnimData = HydraFeature.AnimData;
	}

	UFUNCTION(BlueprintOverride)
	void BlueprintInitializeAnimation()
	{
	}

	UFUNCTION(BlueprintOverride)
	void BlueprintUpdateAnimation(float DeltaTime)
	{
		
	}
}
