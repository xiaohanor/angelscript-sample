// This is the double overload platform just before the elevator in stormdrain, after the spinning hallway
UCLASS(Abstract)
class AIslandDoubleOverloadPlatform : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(EditInstanceOnly)
	AIslandOverloadPlatform OuterOverloadPlatform;

	UPROPERTY(EditInstanceOnly)
	AIslandOverloadPlatform InnerOverloadPlatform;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		InnerOverloadPlatform.OnActivated.AddUFunction(this, n"OnInnerPlatformStateChanged");
		OuterOverloadPlatform.OnActivated.AddUFunction(this, n"OnOuterPlatformStateChanged");

		InnerOverloadPlatform.OnReset.AddUFunction(this, n"OnInnerPlatformStateChanged");
		OuterOverloadPlatform.OnReset.AddUFunction(this, n"OnOuterPlatformStateChanged");

		InnerOverloadPlatform.OnReachedDestination.AddUFunction(this, n"OnInnerPlatformStateChanged");
		OuterOverloadPlatform.OnReachedDestination.AddUFunction(this, n"OnOuterPlatformStateChanged");

		InnerOverloadPlatform.OnReachedOrigin.AddUFunction(this, n"OnInnerPlatformStateChanged");
		OuterOverloadPlatform.OnReachedOrigin.AddUFunction(this, n"OnOuterPlatformStateChanged");
	}

	UFUNCTION()
	private void OnInnerPlatformStateChanged()
	{
		OnPlatformStateChanged(InnerOverloadPlatform, OuterOverloadPlatform);
	}

	UFUNCTION()
	private void OnOuterPlatformStateChanged()
	{
		OnPlatformStateChanged(OuterOverloadPlatform, InnerOverloadPlatform);
	}

	private void OnPlatformStateChanged(AIslandOverloadPlatform Current, AIslandOverloadPlatform Other)
	{
		switch(Current.CurrentPlatformMoveState)
		{
			case EIslandOverloadPlatformMoveState::Origin:
			{
				UIslandDoubleOverloadPlatformEffectHandler::Trigger_OnStopMoving(this);

				if(Other.CurrentPlatformMoveState == EIslandOverloadPlatformMoveState::Origin)
					UIslandDoubleOverloadPlatformEffectHandler::Trigger_OnFullyRetracted(this);

				if(Other.CurrentPlatformMoveState == EIslandOverloadPlatformMoveState::Destination)
					UIslandDoubleOverloadPlatformEffectHandler::Trigger_OnHitConstraintOne(this);
				break;
			}
			case EIslandOverloadPlatformMoveState::MovingToDestination:
			{
				UIslandDoubleOverloadPlatformEffectHandler::Trigger_OnStartExtending(this);
				break;
			}
			case EIslandOverloadPlatformMoveState::MovingToOrigin:
			{
				UIslandDoubleOverloadPlatformEffectHandler::Trigger_OnStartRetracting(this);
				break;
			}
			case EIslandOverloadPlatformMoveState::Destination:
			{
				UIslandDoubleOverloadPlatformEffectHandler::Trigger_OnStopMoving(this);

				if(Other.CurrentPlatformMoveState == EIslandOverloadPlatformMoveState::Destination)
					UIslandDoubleOverloadPlatformEffectHandler::Trigger_OnFullyExtended(this);

				if(Other.CurrentPlatformMoveState == EIslandOverloadPlatformMoveState::Origin)
					UIslandDoubleOverloadPlatformEffectHandler::Trigger_OnHitConstraintOne(this);
				break;
			}
			default:
			devError("Forgot to add case!");
		}
	}
}

UCLASS(Abstract)
class UIslandDoubleOverloadPlatformEffectHandler : UHazeEffectEventHandler
{
	// Triggers every time a part starts extending outwards.
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnStartExtending() {}

	// Triggers every time a part starts retracting inwards
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnStartRetracting() {}

	// Triggers every time a part stops moving
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnStopMoving() {}

	// When a part hits the midway point (so if one platform is at origin and other is at destination or vice versa), will not trigger if the other platform is moving when the constraint is hit.
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnHitConstraintOne() {}

	// Triggers when both platforms are fully extended
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnFullyExtended() {}

	// Triggers when both platforms are fully retracted
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnFullyRetracted() {}
}