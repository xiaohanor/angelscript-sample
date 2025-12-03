
enum EMovementResponseBallPhysicsType
{
	RelativeToSelf,
	RelativeToActor
}

/**
 * A component that will respond to any delta translation and rotate anything attached to the component after that delta translation.
 */
class UMovementResponseBallPhysicsComponent : USceneComponent
{
	/** What should the rotation be relative to */
	UPROPERTY(EditAnywhere, Category ="Settings")
	EMovementResponseBallPhysicsType Type = EMovementResponseBallPhysicsType::RelativeToSelf;

	/** Define the radius of the object so we can rotate correctly */
	UPROPERTY(EditAnywhere, Category ="Settings")
	float BallRadius = 50;

	private uint64 OnMovedDelegateHandle = 0;
	private FVector PreviousPosition = FVector::ZeroVector;
	private FQuat InternalWorldRotation = FQuat::Identity;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		OnMovedDelegateHandle = SceneComponent::BindOnSceneComponentMoved(Owner.RootComponent, FOnSceneComponentMoved(this, n"OnMoved"));
		PreviousPosition = WorldLocation;
		InternalWorldRotation = GetWorldRotation().Quaternion();
	}

	UFUNCTION(BlueprintOverride)
	void EndPlay(EEndPlayReason EndPlayReason)
	{
		SceneComponent::UnbindOnSceneComponentMoved(Owner.RootComponent, OnMovedDelegateHandle);
	}

	UFUNCTION(NotBlueprintCallable)
	protected void OnMoved(USceneComponent MovedComponent, bool bIsTeleport)
	{
		if(bIsTeleport)
		{
			InternalWorldRotation = GetWorldRotation().Quaternion();
			return;
		}
		
		FVector Delta = WorldLocation - PreviousPosition;
		PreviousPosition = WorldLocation;
		if(Delta.IsNearlyZero())
			return;

		float RotationAngle = Math::RadiansToDegrees(Delta.Size() / BallRadius);// * Time::UndilatedWorldDeltaSeconds;
		FRotator DeltaRotation = Math::RotatorFromAxisAndAngle(FRotator::MakeFromZX(FVector::UpVector, Delta).RightVector, RotationAngle);
		
		if(Type == EMovementResponseBallPhysicsType::RelativeToActor)
		{
			AddWorldRotation(DeltaRotation);
		}
		else if(Type == EMovementResponseBallPhysicsType::RelativeToSelf)
		{
			InternalWorldRotation = DeltaRotation.Quaternion() * InternalWorldRotation;
			SetWorldRotation(InternalWorldRotation);
		}
		else
		{
			// Not implemented
			devCheck(false);
		}
	}
}


#if EDITOR
class UMovementResponseBallPhysicsComponentVisualizer : UHazeScriptComponentVisualizer
{
    default VisualizedClass = UMovementResponseBallPhysicsComponent;

    UFUNCTION(BlueprintOverride)
    void VisualizeComponent(const UActorComponent Component)
    {
		auto RotatingComp = Cast<UMovementResponseBallPhysicsComponent>(Component);
		if(RotatingComp == nullptr)
			return;

		DrawWireSphere(RotatingComp.WorldLocation, RotatingComp.BallRadius);
	}
}
#endif