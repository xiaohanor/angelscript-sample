class UKineticCameraShakeForceFeedbackComponent : UCameraShakeForceFeedbackComponent
{
	AKineticMovingActor MovingActorRef;
	AKineticRotatingActor RotatingActorRef;

	UPROPERTY(EditInstanceOnly, Category = "Reactions")
	bool bOnStartForward = false;

	UPROPERTY(EditInstanceOnly, Category = "Reactions")
	bool bOnStartBackward = false;

	UPROPERTY(EditInstanceOnly, Category = "Reactions")
	bool bOnStopForward = false;

	UPROPERTY(EditInstanceOnly, Category = "Reactions")
	bool bOnStopBackward = false;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		SetActorRef();

		if(MovingActorRef != nullptr)
		{
			if(bOnStartForward)
				MovingActorRef.OnStartForward.AddUFunction(this, n"KineticActorReaction");
			if(bOnStartBackward)
				MovingActorRef.OnStartBackward.AddUFunction(this, n"KineticActorReaction");
			if(bOnStopForward)
				MovingActorRef.OnReachedForward.AddUFunction(this, n"KineticActorReaction");
			if(bOnStopBackward)
				MovingActorRef.OnReachedBackward.AddUFunction(this, n"KineticActorReaction");
		}

		if(RotatingActorRef != nullptr)
		{
			if(bOnStartForward)
				RotatingActorRef.OnStartForward.AddUFunction(this, n"KineticActorReaction");
			if(bOnStartBackward)
				RotatingActorRef.OnStartBackward.AddUFunction(this, n"KineticActorReaction");
			if(bOnStopForward)
				RotatingActorRef.OnFinishedForward.AddUFunction(this, n"KineticActorReaction");
			if(bOnStopBackward)
				RotatingActorRef.OnFinishedBackward.AddUFunction(this, n"KineticActorReaction");
		}
	}

	UFUNCTION()
	void KineticActorReaction()
	{
		ActivateCameraShakeAndForceFeedback();
	}

	void SetActorRef()
	{
		AActor ParentActor = GetOwner();
		if(Cast<AKineticMovingActor>(ParentActor) != nullptr)
		{
			MovingActorRef = Cast<AKineticMovingActor>(ParentActor);
		}
		else if(Cast<AKineticRotatingActor>(ParentActor) != nullptr)
		{
			RotatingActorRef = Cast<AKineticRotatingActor>(ParentActor);
		}
	}
};