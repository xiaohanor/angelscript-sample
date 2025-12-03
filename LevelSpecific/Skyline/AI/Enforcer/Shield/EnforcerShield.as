UCLASS(Abstract)
class AEnforcerShield : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent)
	USphereComponent Collision;
	default Collision.SetCollisionProfileName(n"NoCollision");

	UPROPERTY(DefaultComponent)
	UGravityWhipTargetComponent GravityWhipTargetComponent;

	UPROPERTY(DefaultComponent, Attach = GravityWhipTargetComponent)
	UTargetableOutlineComponent TargetableOutlineComp;

	UPROPERTY(DefaultComponent)
	UGravityWhipResponseComponent GravityWhipResponseComponent;
	default GravityWhipResponseComponent.GrabMode = EGravityWhipGrabMode::Sling;

	UPROPERTY(EditAnywhere)
	UNiagaraSystem DestroyEffect;

	UPROPERTY(DefaultComponent)
	UHazeMovementComponent MovementComponent;

	USweepingMovementData Movement;

	UPROPERTY(EditAnywhere)
	float GrabForceMultiplier = 1.0;
		
	private float GrabbedTime = 0;
	private FVector AngularVelocity;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		GravityWhipResponseComponent.OnGrabbed.AddUFunction(this, n"OnGrabbed");
		Movement = MovementComponent.SetupSweepingMovementData();
	}

	UFUNCTION()
	void OnGrabbed(UGravityWhipUserComponent UserComponent,
		UGravityWhipTargetComponent TargetComponent,
		TArray<UGravityWhipTargetComponent> OtherComponents)
	{
		GrabbedTime = Time::GameTimeSeconds;	
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		if(GrabbedTime == 0)
			return;

		if (!GravityWhipResponseComponent.IsGrabbed())
		{
			if (MovementComponent.PrepareMove(Movement))
			{
				FVector Velocity = MovementComponent.Velocity;
				FVector Force;
				FVector Acceleration = Force * GrabForceMultiplier;

				AngularVelocity -= AngularVelocity * 1.0 * DeltaSeconds;

				Movement.AddVelocity(Velocity);
				Movement.AddAcceleration(Acceleration);
				Movement.BlockGroundTracingForThisFrame();
				Movement.SetRotation(GetMovementRotation(DeltaSeconds));
				MovementComponent.ApplyMove(Movement);
			}
		}

		if(Time::GetGameTimeSince(GrabbedTime) > 0.35)
		{
			for (int i = GravityWhipResponseComponent.Grabs.Num() - 1; i >= 0; --i)
				GravityWhipResponseComponent.Grabs[i].UserComponent.Release(this);
			Niagara::SpawnOneShotNiagaraSystemAtLocation(DestroyEffect, ActorLocation);
			DestroyActor();
		}
	}

	FQuat GetMovementRotation(float DeltaTime)
	{
		return ActorQuat * FQuat(AngularVelocity.GetSafeNormal(), AngularVelocity.Size() * DeltaTime);
	}
}