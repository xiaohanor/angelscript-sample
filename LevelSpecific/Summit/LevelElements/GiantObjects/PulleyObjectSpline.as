class APulleyObjectSpline : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent MeshRoot;

	UPROPERTY(DefaultComponent, Attach = MeshRoot)
	UBoxComponent HitBox;

	UPROPERTY(EditAnywhere, Category = "Setup")
	ASplineActor Spline;

	UPROPERTY(EditAnywhere, Category = "Setup")
	APulleyInteraction PulleyInteraction;

	UPROPERTY(EditAnywhere, Category = "Setup")
	ANightQueenMetal QueenMetal;

	UPROPERTY(EditAnywhere, Category = "Settings")
	float ImpulseAmount = 15585000.0;

	UPROPERTY(EditAnywhere, Category = "Settings")
	float FallRotationAmount = 90.0;

	//How much it should go down by % wise every second
	UPROPERTY(EditAnywhere, Category = "Settings")
	float Friction = 0.4;

	UPROPERTY(EditAnywhere, Category = "Settings")
	float Threshold = 20.0;

	UPROPERTY(EditAnywhere, Category = "Settings")
	float ObjectGravity = 15000.0;

	UPROPERTY()
	FRotator StartingRot;
	FVector StartLocation;

	float MaxVelocity = 2500.0;

	UHazeSplineComponent SplineComp;

	FVector MoveDirection;

	float CurrentDistance;
	float MoveSpeed;
	float StartingDistance;

	bool bPulling;

	bool bIsChained;

	float TargetPullLoc;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		HitBox.OnComponentBeginOverlap.AddUFunction(this, n"OnComponentBeginOverlap");
		StartingRot = MeshRoot.RelativeRotation;

		SplineComp = Spline.Spline;
		CurrentDistance = SplineComp.GetClosestSplineDistanceToWorldLocation(ActorLocation);
		StartingDistance = CurrentDistance;
		ActorLocation = SplineComp.GetWorldLocationAtSplineDistance(CurrentDistance);
		StartLocation = ActorLocation;


		if(QueenMetal != nullptr)
		{
			QueenMetal.OnNightQueenMetalMelted.AddUFunction(this, n"OnMetalMelted");
			bIsChained = true;
		}

		PulleyInteraction.OnSummitPulleyPulling.AddUFunction(this, n"OnSummitPulleyPulling");
		PulleyInteraction.OnSummitPulleyReleased.AddUFunction(this, n"OnSummitPulleyReleased");
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		// PulleyInteraction.SetObjectDistanceFromCenter(GetDistanceFromCenter());
		
		FVector Tangent = SplineComp.GetWorldTangentAtSplineDistance(CurrentDistance);
		Tangent.Normalize();

		float Dot = -FVector::UpVector.DotProduct(Tangent);


		if(bIsChained)
		{
			return;
		}
		//Ensures that it loses 0.5 per second
		else if (!bPulling)
		{
			MoveSpeed *= Math::Pow(1 - Friction, DeltaTime);
			float GravityForce = Dot * ObjectGravity;
			MoveSpeed += GravityForce * DeltaTime;
			CurrentDistance += MoveSpeed * DeltaTime;
			CurrentDistance = Math::Clamp(CurrentDistance, 0.0, SplineComp.SplineLength);
		}
		else
		{
			float TargetAlpha = 0.5 - (PulleyInteraction.PullAlpha / 2);
			TargetPullLoc = SplineComp.GetSplineLength() * TargetAlpha;
			CurrentDistance = Math::FInterpTo(CurrentDistance, TargetPullLoc, DeltaTime, 0.95);
		}

		ActorLocation = SplineComp.GetWorldLocationAtSplineDistance(CurrentDistance);
	}

	UFUNCTION()
	private void OnMetalMelted()
	{
		bIsChained = false;
	}

	UFUNCTION()
	private void OnSummitPulleyPulling()
	{
		// if (!bPulling)
		// 	TargetPullLoc = CurrentDistance;
		if(bIsChained == false)
			bPulling = true;
		else
			return;
		
		// float HalfwayPoint = SplineComp.GetSplineLength() / 2;

		// TargetPullLoc = HalfwayPoint + Force;

	}

	UFUNCTION()
	private void OnSummitPulleyReleased()
	{
		bPulling = false;
		MoveSpeed += 1000.0;
	}

	float GetDistanceFromCenter()
	{
		float HalfwayPoint = SplineComp.GetSplineLength() / 2;
		return CurrentDistance - HalfwayPoint;
	}

	UFUNCTION()
	private void OnComponentBeginOverlap(UPrimitiveComponent OverlappedComponent, AActor OtherActor,
	                                     UPrimitiveComponent OtherComp, int OtherBodyIndex,
	                                     bool bFromSweep, const FHitResult&in SweepResult)
	{
		UGoldGiantBreakResponseComponent BreakComp = UGoldGiantBreakResponseComponent::Get(OtherActor);

		if (BreakComp == nullptr)
			return;

		FVector Dir = -OtherActor.ActorForwardVector;
		BreakComp.BreakGiant(Dir, ImpulseAmount);

		if (BreakComp.IsBreakDisabled())
		{
			if (MoveSpeed > 0.0)
				MoveSpeed = -MoveSpeed;
			
			Print("METAL IN THE WAY");
		}
		else
		{
			// if (!BreakComp.bIsBroken)
			// {
			// 	Game::Mio.PlayCameraShake(CameraShake, this, 0.8);
			// 	Game::Zoe.PlayCameraShake(CameraShake, this, 0.8);
			// }
		}
	}
}