class ADeathStaticCamera : AStaticCameraActor
{
	FVector CameraStartingVelocity;
	AHazePlayerCharacter Player;
	float StopDuration = 0.5;
	float BlendOutDuration = 0.0;
	float TimePassed;
	float ForceOutwards = 0.0;

	FHazeAcceleratedVector AccelVelocity;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		FVector OutForce = ActorForwardVector * ForceOutwards;
		AccelVelocity.SnapTo(CameraStartingVelocity);
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		if (StopDuration <= SMALL_NUMBER)
			return;
		
		AccelVelocity.AccelerateTo(FVector(0.0), StopDuration, DeltaSeconds);

		FHazeTraceSettings TraceSettings = Trace::InitChannel(ECollisionChannel::ECC_Camera);
		TraceSettings.UseSphereShape(30.0);
		TraceSettings.IgnoreActor(this);
		
		FVector DeltaOffset = AccelVelocity.Value * DeltaSeconds;

		if(!DeltaOffset.IsNearlyZero())
		{
			FHitResultArray HitArray = TraceSettings.QueryTraceMulti(ActorLocation, ActorLocation + DeltaOffset);

			for (FHitResult Hit : HitArray)
			{
				if (!Hit.bBlockingHit)
					continue;

				DeltaOffset = DeltaOffset.ConstrainToPlane(Hit.ImpactNormal);
			}
			
			ActorLocation += DeltaOffset;
		}
	}
};