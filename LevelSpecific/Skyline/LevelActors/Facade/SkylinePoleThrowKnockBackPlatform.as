class ASkylinePoleThrowKnockBackPlatform : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent)
	UAttachOwnerToParentComponent AttachComp;

	UPROPERTY(EditAnywhere)
	AKineticMovingActor MovingActor;

	UPROPERTY(DefaultComponent)
	UBoxComponent BoxComp;

	UPROPERTY(DefaultComponent)
	UArrowComponent KnockdownDirection;

	UPROPERTY(DefaultComponent)
	UCameraShakeForceFeedbackComponent CameraShakeForceFeedbackComponent;

	float CollisionReEnableTimer = 0.0;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		MovingActor.OnReachedForward.AddUFunction(this, n"HandleReachedForward");
		MovingActor.OnReachedBackward.AddUFunction(this, n"HandleReachedBackwards");
	}

	UFUNCTION()
	private void HandleReachedForward()
	{
		CameraShakeForceFeedbackComponent.CameraShakeScale = 0.5;
		CameraShakeForceFeedbackComponent.ForceFeedbackScale = 0.5;
		CameraShakeForceFeedbackComponent.ActivateCameraShakeAndForceFeedback();
	}

	UFUNCTION()
	private void HandleReachedBackwards()
	{
		CameraShakeForceFeedbackComponent.CameraShakeScale = 1.0;
		CameraShakeForceFeedbackComponent.ForceFeedbackScale = 1.0;
		CameraShakeForceFeedbackComponent.ActivateCameraShakeAndForceFeedback();
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		if (BoxComp.IsOverlappingActor(Game::Mio) && MovingActor.IsMovingBackward())
		{
			TArray<AActor> Actors;
			MovingActor.GetAttachedActors(Actors);

			for (auto Actor : Actors)
			{
				if (Actor.RootComponent.AttachParent == MovingActor.RootComp)
					Actor.AddActorCollisionBlock(this);
			}
			
			CollisionReEnableTimer = 0.5;
			Game::Mio.ApplyKnockdown(KnockdownDirection.ForwardVector * 500 + ActorRightVector * 1400, 1.5);
		}

		if (CollisionReEnableTimer > 0.0)
		{
			CollisionReEnableTimer -= DeltaSeconds;
			if (CollisionReEnableTimer <= 0.0)
			{
				TArray<AActor> Actors;
				MovingActor.GetAttachedActors(Actors);

				for (auto Actor : Actors)
				{
					if (Actor.RootComponent.AttachParent == MovingActor.RootComp)
						Actor.RemoveActorCollisionBlock(this);
				}
			}
		}
	}
};