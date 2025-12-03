UCLASS(Abstract)
class UFeatureAnimInstanceBackpackDragonZipline : UHazeFeatureSubAnimInstance
{
	// The Feature associated with this Feature Sub Anim Instance
	UPROPERTY(Transient, BlueprintHidden, NotEditable)
	ULocomotionFeatureBackpackDragonZipline Feature;

	// Read all Feature Anim Data from this struct in the Anim Graph
	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	FLocomotionFeatureBackpackDragonZiplineAnimData AnimData;

	// Add Custom Variables Here

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	bool bPlayExit;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	bool bIsPlayer;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	bool bInAir;

	private UPlayerTailBabyDragonComponent TailDragonComp;

	UPlayerMovementComponent PlayerMoveComp;
	UHazePhysicalAnimationComponent PhysAnimComp;


	UFUNCTION(BlueprintOverride)
	void BlueprintBeginPlay()
	{
		auto PlayerOwner = Cast<AHazePlayerCharacter>(HazeOwningActor);

		if(PlayerOwner != nullptr)
		{
			bIsPlayer = true;
			TailDragonComp = UPlayerTailBabyDragonComponent::Get(PlayerOwner);
			PlayerMoveComp = UPlayerMovementComponent::Get(PlayerOwner);
		}
		else
		{
			bIsPlayer = false;
			auto DragonOwner = Cast<ABabyDragon>(HazeOwningActor);
			TailDragonComp = UPlayerTailBabyDragonComponent::Get(DragonOwner.Player);
			PlayerMoveComp = UPlayerMovementComponent::Get(DragonOwner.Player);
		}
	}

	UFUNCTION(BlueprintOverride)
	void BlueprintInitializeAnimation()
	{
		ULocomotionFeatureBackpackDragonZipline NewFeature = GetFeatureAsClass(ULocomotionFeatureBackpackDragonZipline);
		if (Feature != NewFeature)
		{
			Feature = NewFeature;
			AnimData = NewFeature.AnimData;
		}

		if (Feature == nullptr)
			return;

		if (!bIsPlayer)
		{
			PhysAnimComp = UHazePhysicalAnimationComponent::Get(HazeOwningActor);
			if (PhysAnimComp != nullptr)
				PhysAnimComp.Disable(this);
		}
	}

	UFUNCTION(BlueprintOverride)
	float GetBlendTime() const
	{
		return 0.1;
	}
	

	UFUNCTION(BlueprintOverride)
	void BlueprintUpdateAnimation(float DeltaTime)
	{
		if (Feature == nullptr)
			return;

		// Implement Custom Stuff Here

		bPlayExit = LocomotionAnimationTag != Feature.Tag;

		bInAir = PlayerMoveComp.IsInAir();
	}

	UFUNCTION(BlueprintOverride)
	bool CanTransitionFrom() const
	{
		// Implement Custom Stuff Here

		if (bIsPlayer && LocomotionAnimationTag != n"AirMovement")
			return true;

		if (!bIsPlayer && LocomotionAnimationTag != n"Movement")
			return true;

		return TopLevelGraphRelevantStateName == n"Exit" && IsLowestLevelGraphRelevantAnimFinished();

		
	}

	UFUNCTION(BlueprintOverride)
	void OnTransitionFrom(UHazeFeatureSubAnimInstance NewSubAnimInstance)
	{
		if (PhysAnimComp != nullptr)
			PhysAnimComp.ClearDisable(this);
	}
}
