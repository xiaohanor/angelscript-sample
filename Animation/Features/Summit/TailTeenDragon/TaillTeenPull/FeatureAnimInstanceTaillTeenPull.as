UCLASS(Abstract)
class UFeatureAnimInstanceTaillTeenPull : UHazeFeatureSubAnimInstance
{
	// The Feature associated with this Feature Sub Anim Instance
	UPROPERTY(Transient, BlueprintHidden, NotEditable)
	ULocomotionFeatureTaillTeenPull Feature;

	// Read all Feature Anim Data from this struct in the Anim Graph
	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	FLocomotionFeatureTaillTeenPullAnimData AnimData;

	// Add Custom Variables Here

	UHazeAnimSlopeAlignComponent AnimSlopeAlignComponent;
	UHazeMovementComponent MoveComp;

	AHazePlayerCharacter DragonRider;


	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	bool bWantsToMove;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	FVector2D BlendspaceValues;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	bool bPlayExit;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	bool bPlayLongExit;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	FRotator SlopeRotation;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	FVector SlopeOffset;

	
	UFUNCTION(BlueprintOverride)
	void BlueprintBeginPlay()
	{
		auto Dragon = Cast<ATeenDragon>(HazeOwningActor);
		bool bIsPlayer = Dragon == nullptr;
		if (bIsPlayer)
		{
			DragonRider = Cast<AHazePlayerCharacter>(HazeOwningActor);
			MoveComp = UHazeMovementComponent::Get(HazeOwningActor);
		}
		else
		{
			DragonRider = Cast<AHazePlayerCharacter>(Dragon.DragonComponent.Owner);
			MoveComp = UHazeMovementComponent::Get(Dragon.DragonComponent.Owner);
		}

		AnimSlopeAlignComponent = UHazeAnimSlopeAlignComponent::GetOrCreate(MoveComp.Owner);
		AnimSlopeAlignComponent.InitializeSlopeTransformData(SlopeOffset, SlopeRotation);
	}


	UFUNCTION(BlueprintOverride)
	void BlueprintInitializeAnimation()
	{
		ULocomotionFeatureTaillTeenPull NewFeature = GetFeatureAsClass(ULocomotionFeatureTaillTeenPull);
		if (Feature != NewFeature)
		{
			Feature = NewFeature;
			AnimData = NewFeature.AnimData;
		}

		if (Feature == nullptr)
			return;

	}


	/*UFUNCTION(BlueprintOverride)
	float GetBlendTime() const
	{
		return 0.2f;
	}
	*/


	UFUNCTION(BlueprintOverride)
	void BlueprintUpdateAnimation(float DeltaTime)
	{
		if (DragonRider == nullptr)
			return;

		// Because we don't get a floor movement hit when doing this pullback, calculate the slope normal etc. manually.
		CalculateCustomFloorData();	

		bWantsToMove = !MoveComp.SyncedMovementInputForAnimationOnly.IsNearlyZero();

		const FVector LocalVelocity = HazeOwningActor.GetActorLocalVelocity();
		
		const float Speed = LocalVelocity.Size();

		// Store blendspace values when stopping by only updating them while user has input
		if (bWantsToMove)
		{
			// Set blendspace values
			if (LocalVelocity.X > 0)
				BlendspaceValues.Y =  Speed / 400;
			else
				BlendspaceValues.Y = -Speed / 170;
		}
		
		bPlayExit = LocomotionAnimationTag != Feature.Tag;

		
	}


	/**
	 * Copied from AnimSlopeAlignComponent
	 */
	void CalculateCustomFloorData()
	{
		FVector CustomFloorNormal = GetAnimVectorParam(n"GroundUp", true);
		FVector CustomImpactPoint = DragonRider.ActorLocation + (DragonRider.ActorUpVector * DragonRider.ScaledCapsuleHalfHeight) - (CustomFloorNormal * DragonRider.ScaledCapsuleRadius); 

		// Make sure lines intersect before using `LinePlaneIntersection`
		const float NormalDotProduct = CustomFloorNormal.DotProduct(HazeOwningActor.ActorUpVector);
		FVector DeltaLocation = FVector::ZeroVector;
		if (!Math::IsNearlyZero(NormalDotProduct) && !Math::IsNearlyEqual(Math::Abs(NormalDotProduct), 1))
		{
			const FVector TargetLocation = Math::LinePlaneIntersection(
				HazeOwningActor.ActorLocation,
				HazeOwningActor.ActorLocation + HazeOwningActor.ActorUpVector,
				CustomImpactPoint,
				CustomFloorNormal
			);
			DeltaLocation = TargetLocation - HazeOwningActor.ActorLocation;
		}

		SlopeOffset = DeltaLocation;
		SlopeRotation = FRotator::MakeFromZX(
								HazeOwningActor.ActorTransform.InverseTransformVectorNoScale(CustomFloorNormal), 
								FVector::ForwardVector
							);
	}


	UFUNCTION(BlueprintOverride)
	bool CanTransitionFrom() const
	{
		
		if (LocomotionAnimationTag != n"Movement")
			return true;

		// Finish playing the Exit animation before leaving
		return IsTopLevelGraphRelevantAnimFinished() && TopLevelGraphRelevantStateName == n"Exit";
	}


	UFUNCTION(BlueprintOverride)
	void OnTransitionFrom(UHazeFeatureSubAnimInstance NewSubAnimInstance)
	{
	}
}
