UCLASS(Abstract)
class ASplitTraversal_GrappleDrone : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent DroneRoot;

	UPROPERTY(DefaultComponent, Attach = DroneRoot)
	UFauxPhysicsConeRotateComponent ConeRotateComp;

	UPROPERTY(DefaultComponent, Attach = ConeRotateComp)
	USceneComponent RSpinRoot;

	UPROPERTY(DefaultComponent, Attach = ConeRotateComp)
	USceneComponent LSpinRoot;

	UPROPERTY(DefaultComponent)
	UHazeActionQueueComponent QueueComp;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		TArray<AActor> AttachedActors;
		GetAttachedActors(AttachedActors);

		for (auto AttachedActor : AttachedActors)
		{
			auto LaunchPoint = Cast<AGrappleLaunchPoint>(AttachedActor);
			if (LaunchPoint != nullptr)
				LaunchPoint.OnPlayerInitiatedGrappleToPointEvent.AddUFunction(this, n"HandleGrappleInitiated");
		}
	}

	UFUNCTION()
	private void HandleGrappleInitiated(AHazePlayerCharacter Player,
	                                    UGrapplePointBaseComponent TargetedGrapplePoint)
	{
		QueueComp.Idle(0.35);
		QueueComp.Event(this, n"DelayedImpulse");
	}

	UFUNCTION()
	private void DelayedImpulse()
	{
		AHazePlayerCharacter Player = Game::Mio;
		FVector ImpulseLocation = ConeRotateComp.WorldLocation + FVector::UpVector * 200.0;
		FVector Impulse = (Player.ActorLocation - ImpulseLocation).GetSafeNormal() * 600.0;
		ConeRotateComp.ApplyImpulse(ImpulseLocation, Impulse);
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		RSpinRoot.AddLocalRotation(FRotator(0,500*DeltaSeconds,0));
		if(RSpinRoot.RelativeRotation.Yaw > 360)
			RSpinRoot.AddLocalRotation(FRotator(0,-360,0));

		LSpinRoot.AddLocalRotation(FRotator(0,-500*DeltaSeconds,0));
		if(LSpinRoot.RelativeRotation.Yaw < -360)
			LSpinRoot.AddLocalRotation(FRotator(0,360,0));
		
		FVector DroneRelativeLocation = FVector::UpVector * Math::Sin(Time::GameTimeSeconds * 0.75 + ActorLocation.Y) * 30.0;
		FRotator DroneRelativeRotation = FRotator(0.0, Math::Sin(Time::GameTimeSeconds * 0.5 + ActorLocation.X) * 20.0, 0.0);
		DroneRoot.SetRelativeLocationAndRotation(DroneRelativeLocation, DroneRelativeRotation);
	}
};
