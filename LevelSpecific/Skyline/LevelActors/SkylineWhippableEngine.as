event void FSkylineWhippableEngineGrabbedSignature();

UCLASS(Abstract)
class ASkylineWhippableEngine : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent)
	UStaticMeshComponent Mesh;

	UPROPERTY(DefaultComponent, Attach = Mesh)
	UGravityWhipTargetComponent GravityWhipTargetComponent;

	UPROPERTY(DefaultComponent, Attach = GravityWhipTargetComponent)
	UTargetableOutlineComponent TargetableOutlineComp;

	UPROPERTY(DefaultComponent)
	UGravityWhipResponseComponent WhipResponse;

	UPROPERTY(DefaultComponent)
	UHazeMovementComponent MovementComponent;

	USweepingMovementData Movement;

	UPROPERTY(EditAnywhere)
	UNiagaraSystem RemoveFx;

	UPROPERTY(EditAnywhere)
	ASkylineWhippableEngineWeakpoint Weakpoint;

	UPROPERTY()
	FSkylineWhippableEngineGrabbedSignature OnGrabbed;

	UPROPERTY(EditAnywhere)
	float GrabForceMultiplier = 2.0;
		
	private bool bGrabbed;
	private FVector AngularVelocity;

	private FVector RelativeLocation;
	private FHazeAcceleratedVector AccReturnLocation;

	USceneComponent FollowedComp;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		WhipResponse.OnGrabbed.AddUFunction(this, n"OnWhipGrabbed");
		WhipResponse.OnReleased.AddUFunction(this, n"OnWhipReleased");

		Movement = MovementComponent.SetupSweepingMovementData();
		FollowedComp = AttachParentActor.RootComponent;
		MovementComponent.FollowComponentMovement(FollowedComp, this);
		MovementComponent.ApplyFollowEnabledOverride(this, EMovementFollowEnabledStatus::FollowEnabled);

		RelativeLocation = ActorRelativeLocation;
		DetachFromActor(EDetachmentRule::KeepWorld);

		Weakpoint.Unexpose();
		Weakpoint.OnExploded.AddUFunction(this, n"OnExploded");
	}

	UFUNCTION()
	private void OnExploded()
	{
		for (int i = WhipResponse.Grabs.Num() - 1; i >= 0; --i)
				WhipResponse.Grabs[i].UserComponent.Release(this);
		Niagara::SpawnOneShotNiagaraSystemAtLocation(RemoveFx, ActorLocation);
		AddActorDisable(this);
	}

	UFUNCTION()
	private void OnWhipReleased(UGravityWhipUserComponent UserComponent,
	                            UGravityWhipTargetComponent TargetComponent, FVector Impulse)
	{
		bGrabbed = false;
		Weakpoint.Unexpose();
	}

	UFUNCTION()
	private void OnWhipGrabbed(UGravityWhipUserComponent UserComponent,
	                       UGravityWhipTargetComponent TargetComponent,
	                       TArray<UGravityWhipTargetComponent> OtherComponents)
	{
		bGrabbed = true;
		Weakpoint.Expose();
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		FVector OriginalLocation = FollowedComp.WorldTransform.TransformPosition(RelativeLocation);

		if (MovementComponent.PrepareMove(Movement))
		{
			FVector Velocity = MovementComponent.Velocity;
			FVector Force;

			if(!bGrabbed)
			{
				float Speed = 2500 * Math::Clamp(ActorLocation.Distance(OriginalLocation) / 1500, 0, 1);
				Force = (OriginalLocation - ActorLocation).GetSafeNormal() * Speed;
			}
			else
			{
				for (auto& Grab : WhipResponse.Grabs)
					Force += Grab.TargetComponent.ConsumeForce();
			}

			FVector Acceleration = Force * GrabForceMultiplier
				- MovementComponent.Velocity * 2;

			Movement.AddVelocity(Velocity);
			Movement.AddAcceleration(Acceleration);
			Movement.BlockGroundTracingForThisFrame();
			MovementComponent.ApplyMove(Movement);
		}

		Debug::DrawDebugLine(ActorLocation, OriginalLocation, Thickness = 20, LineColor = FLinearColor::Blue);
	}
}