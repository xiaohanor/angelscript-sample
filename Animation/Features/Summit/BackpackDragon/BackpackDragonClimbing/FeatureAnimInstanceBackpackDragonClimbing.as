UCLASS(Abstract)
class UFeatureAnimInstanceBackpackDragonClimbing : UHazeFeatureSubAnimInstance
{
	// The Feature associated with this Feature Sub Anim Instance
	UPROPERTY(Transient, BlueprintHidden, NotEditable)
	ULocomotionFeatureBackpackDragonClimbing Feature;

	// Read all Feature Anim Data from this struct in the Anim Graph
	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	FLocomotionFeatureBackpackDragonClimbingAnimData AnimData;

	// Add Custom Variables Here

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	bool bIsPlayer;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	bool bPlayExit;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	FVector2D LaunchForce = FVector2D::ZeroVector;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	FVector2D BlendspaceValues;

	UPlayerMovementComponent MoveComponent;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	FVector2D CachedLaunchForce = FVector2D::ZeroVector;

	private UPlayerTailBabyDragonComponent TailDragonComp;

	UHazePhysicalAnimationComponent PhysAnimComp;

	AHazePlayerCharacter PlayerOwner;

	UFUNCTION(BlueprintOverride)
	void BlueprintBeginPlay()
	{
		PlayerOwner = Cast<AHazePlayerCharacter>(HazeOwningActor);
		if (PlayerOwner != nullptr)
		{
			bIsPlayer = true;
			TailDragonComp = UPlayerTailBabyDragonComponent::Get(PlayerOwner);
			MoveComponent = UPlayerMovementComponent::Get(PlayerOwner);
		}
		else
		{
			bIsPlayer = false;
			auto DragonOwner = Cast<ABabyDragon>(HazeOwningActor);
			PlayerOwner = DragonOwner.Player;
			TailDragonComp = UPlayerTailBabyDragonComponent::Get(DragonOwner.Player);
			MoveComponent = UPlayerMovementComponent::Get(DragonOwner.Player);
		}
	}

	UFUNCTION(BlueprintOverride)
	void BlueprintInitializeAnimation()
	{
		ULocomotionFeatureBackpackDragonClimbing NewFeature = GetFeatureAsClass(ULocomotionFeatureBackpackDragonClimbing);
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
		return 0.0;
	}

	UFUNCTION(BlueprintOverride)
	void BlueprintUpdateAnimation(float DeltaTime)
	{
		if (Feature == nullptr)
			return;

		if (TailDragonComp == nullptr)
			return;

		bPlayExit = LocomotionAnimationTag != Feature.Tag;

		FRotator OwnerRotation = TailDragonComp.Owner.ActorRotation;

		FVector LocalForce = OwnerRotation.UnrotateVector(TailDragonComp.ClimbLaunchForce);

		if (!bPlayExit)
			CachedLaunchForce = BlendspaceValues;

		LaunchForce = FVector2D(LocalForce.Y, LocalForce.Z) / BabyDragonTailClimbSettings::LaunchForce.Max;

		BlendspaceValues.X = PlayerOwner.ViewRotation.UnrotateVector(MoveComponent.SyncedMovementInputForAnimationOnly).Y;
	}

	UFUNCTION(BlueprintOverride)
	bool CanTransitionFrom() const
	{
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
