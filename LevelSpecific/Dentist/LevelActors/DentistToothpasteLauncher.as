UCLASS(Abstract)
class ADentistToothpasteLauncher : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent PanPivot;

	UPROPERTY(DefaultComponent, Attach = PanPivot)
	USceneComponent ToothpasteLauncherRoot;

	UPROPERTY(DefaultComponent, Attach = ToothpasteLauncherRoot)
	USceneComponent TiltPivot;

	UPROPERTY(DefaultComponent, Attach = TiltPivot)
	UHazeSplineComponent SplineComp;

	UPROPERTY()
	float LaunchImpulse = 1500.0;

	UPROPERTY()
	FDentistToothApplyRagdollSettings RagdollSettings;

	UPROPERTY(EditAnywhere)
	float TiltMin = -30.0;

	UPROPERTY(EditAnywhere)
	float TiltMax = 0.0;

	UPROPERTY(EditAnywhere)
	float PanDegrees = 30.0;

	UPROPERTY(EditAnywhere)
	float TiltStartingAlpha = 0.0;
	float TiltOffset;

	UPROPERTY(EditAnywhere)
	float PanStartingAlpha = 0.0;
	float PanOffset;

	bool bMioOverlapping = false;
	bool bZoeOverlapping = false;


	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		TiltOffset = TiltStartingAlpha * PI;
		PanOffset = PanStartingAlpha * PI;
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		//Tilting
		float TiltAlpha = (Math::Sin(Time::GameTimeSeconds + TiltOffset) * 0.5) + 0.5; 

		TiltPivot.SetRelativeRotation(FRotator(Math::Lerp(TiltMin, TiltMax, TiltAlpha), 0.0, 0.0));

		//Paning
		float PanAlpha = (Math::Sin(Time::GameTimeSeconds * 0.5 + PanOffset) * 0.5) + 0.5; 

		PanPivot.SetRelativeRotation(FRotator(0.0, Math::Lerp(0.0, PanDegrees, PanAlpha), 0.0));


		//Shoot Toothpaste
		FHazeTraceSettings Trace = Trace::InitChannel(ECollisionChannel::ECC_Visibility);
		Trace.IgnorePlayers();
		Trace.IgnoreActor(this);
		FVector TraceEnd = TiltPivot.WorldLocation + TiltPivot.ForwardVector * 10000.0;
		FHitResult HitResult = Trace.QueryTraceSingle(TiltPivot.WorldLocation, TraceEnd);
		FVector HitLocation = HitResult.ImpactPoint;

		if (!HitResult.bBlockingHit)
			HitLocation = TraceEnd;

		SetToothPasteParameters(TiltPivot.WorldLocation, HitLocation);


		//Player Impact
		for(auto Player : Game::Players)
		{
			FVector ClosestSplineLocation = SplineComp.GetClosestSplineWorldLocationToWorldLocation(Player.ActorCenterLocation);
			float DistanceToSpline = (ClosestSplineLocation - Player.ActorCenterLocation).Size();
			
			if (DistanceToSpline < 150.0)
			{
				FVector Impulse = (ClosestSplineLocation - Player.ActorLocation).GetSafeNormal() * LaunchImpulse;
				Impulse = TiltPivot.ForwardVector * LaunchImpulse;

				auto ResponseComp = UDentistToothImpulseResponseComponent::Get(Player);
				if(ResponseComp != nullptr)
				{
					ResponseComp.OnImpulseFromObstacle.Broadcast(this, Impulse, RagdollSettings);
				}
			}
		}
	}

	UFUNCTION(BlueprintEvent)
	void SetToothPasteParameters(FVector BeamStart, FVector BeamEnd)
	{

	}
};