
asset LightSeekerSheet of UHazeCapabilitySheet
{
	Capabilities.Add(ULightSeekerSleepCapability);
	Capabilities.Add(ULightSeekerChaseCapability);
	Capabilities.Add(ULightSeekerTranceCapability);
	Capabilities.Add(ULightSeekerReturnCapability);
	Capabilities.Add(ULightSeekerMovementCapability);
	Capabilities.Add(ULightSeekerFacingCapability);
	Capabilities.Add(ULightSeekerSwingyHeadAnimationCapability);
	Capabilities.Add(ULightSeekerEmissiveEscaCapability);
};

class ALightSeeker : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent)
	USceneComponent Origin;

	UPROPERTY(DefaultComponent)
	USceneComponent Head;

	UPROPERTY(DefaultComponent)
	UHazeSkeletalMeshComponentBase SkeletalMesh;
	default SkeletalMesh.SetCollisionEnabled(ECollisionEnabled::QueryAndPhysics);
	default SkeletalMesh.SetCollisionObjectType(ECollisionChannel::ECC_WorldDynamic);
	default SkeletalMesh.SetCollisionResponseToAllChannels(ECollisionResponse::ECR_Ignore);
	default SkeletalMesh.SetCollisionResponseToChannel(ECollisionChannel::PlayerCharacter, ECollisionResponse::ECR_Block);

	UPROPERTY(DefaultComponent)
	UHazeCapabilityComponent CapabilityComponent;
	default CapabilityComponent.DefaultSheets.Add(LightSeekerSheet);

	UPROPERTY(DefaultComponent)
	UHazeRequestCapabilityOnPlayerComponent RequestComp;
	default RequestComp.PlayerCapabilities.AddUnique(n"LightSeekerPlayerWalkingOnSeekerCapability");
	// default RequestComp.PlayerCapabilities.AddUnique(n"LightSeekerPlayerAssistedAirMoveCapability");

	UPROPERTY(DefaultComponent)
	UDisableComponent DisableComp;
	default DisableComp.bAutoDisable = true;
	default DisableComp.AutoDisableRange = 8000.0;

	bool bDebugging = false;

	bool bHasSwinging = false;

	// animation variables
	UPROPERTY(EditAnywhere)
	float PrepareAttackRange = 700.0;

	float AttackAlpha = 0.0;

	UPROPERTY(EditAnywhere)
	float AttackTime = 0.2;
	bool bIsSleeping = true;
	bool bIsChasing = false;
	bool bIsInTrance = false;
	bool bIsConstrained = false;
	bool bIsAttacking = false;
	bool bIsReturning = false;
	bool bIsSwinging = false;
	FVector SwingingDirection = FVector::ZeroVector;
	bool bIsGrappling = false;
	FVector GrapplingDirection = FVector::ZeroVector;
	FHazeAcceleratedFloat AnimationDownUpGradient;
	FHazeAcceleratedFloat AnimationLeftRightGradient;

	UPROPERTY(Category = "Settings")
	float DistanceToBeStraightToBurrow = 300.0;
	UPROPERTY(Category = "Settings")
	float DistanceToOriginCountAsSleepingWithSwingingPlayer = 550.0;
	UPROPERTY(Category = "Settings")
	float DistanceToOriginCountAsSleeping = 10.0;
	UPROPERTY(Category = "Settings")
	float AngleToOriginCountAsSleeping = 5.0;
	UPROPERTY(Category = "Settings")
	float TranceSpeed = 100.0;
	UPROPERTY(Category = "Settings")
	float TranceAngularInterpolationDuration = 1.0;
	UPROPERTY(Category = "Settings")
	float TranceRollWiggleAngle = 10.0;
	UPROPERTY(Category = "Settings")
	float TranceWigglingPerSecond = 0.3;
	UPROPERTY(Category = "Settings")
	float PlayerWalkableAngleOverride = 60.0;
	UPROPERTY(Category = "Settings", EditAnywhere)
	float DetectionRange = 3500.0;
	UPROPERTY(Category = "Settings", EditAnywhere)
	float DetectionAngle = 90.0;
	UPROPERTY(Category = "Settings", EditAnywhere)
	float MaximumReach = 2000.0;
	UPROPERTY(Category = "Settings", EditAnywhere)
	float SlowDownRange = 100.0;
	UPROPERTY(Category = "Settings", EditAnywhere)
	float ChaseDelay = 0.7;
	UPROPERTY(Category = "Settings", EditAnywhere)
	float ChaseSpeed = 800.0;
	UPROPERTY(Category = "Settings", EditAnywhere)
	float ChaseAngularInterpolationDuration = 2.0;
	UPROPERTY(Category = "Settings", EditAnywhere)
	float DesiredOffset = 350.0;
	UPROPERTY(Category = "Settings", EditAnywhere)
	float DesiredOffsetAcceptedRadius = 10.0;
	UPROPERTY(Category = "Settings", EditAnywhere)
	float ReturnSpeed = 200.0;
	UPROPERTY(Category = "Settings", EditAnywhere)
	float ReturnAngularInterpolationDuration = 3.0;
	UPROPERTY(Category = "Settings")
	FHazeTimeLike ChaseSpeedTimeLike;
	default ChaseSpeedTimeLike.UseSmoothCurveZeroToOne();

	float SwingUpDownAffectAnimationMultiplier = 0.5;
	float SwingLeftRightAffectAnimationMultiplier = 0.3;

	FHazeRuntimeSpline RuntimeSpline;
	
	ULightSeekerTargetingComponent TargetingComp;
	FVector StartHeadWorldLocation;

	UFUNCTION(BlueprintOverride)
	void ConstructionScript()
	{
		TargetingComp = ULightSeekerTargetingComponent::GetOrCreate(this, n"LightSeekerTargetingComp");
	}

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		SetActorControlSide(Game::Mio);
		StartHeadWorldLocation = Head.WorldLocation;
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		UpdateSpline();
		if (bDebugging)
		{
			FVector LocationAboveSeeker = Head.WorldLocation + Head.GetWorldRotation().UpVector * 300.0;
			Debug::DrawDebugLine(Head.WorldLocation, LocationAboveSeeker, FLinearColor::Blue, 10.0, 0.0);
			Debug::DrawDebugLine(LocationAboveSeeker, LocationAboveSeeker + Head.GetWorldRotation().ForwardVector * 300.0, FLinearColor::Red, 10.0, 0.0);
			Debug::DrawDebugLine(LocationAboveSeeker, LocationAboveSeeker + Head.GetWorldRotation().RightVector * 300.0, FLinearColor::Green, 10.0, 0.0);
		}
	}

	void UpdateSpline()
	{
		float RootToHeadDistance = (Root.WorldLocation - Head.WorldLocation).Size();
		Origin.RelativeLocation = FVector(Math::Clamp(RootToHeadDistance - 50.0, 0.0, 400.0), 0.0, 0.0);
		
		const float SplineMargin = 10.0;
		TArray<FVector> Points;
		FVector AlmostRoot = Root.WorldLocation - ActorForwardVector * SplineMargin;
		float OutwardsDistance = Math::Clamp(Head.RelativeLocation.Size(), 0, DistanceToBeStraightToBurrow) / DistanceToBeStraightToBurrow;
		FVector FirstPoint = Origin.WorldLocation - ActorForwardVector * OutwardsDistance;
		FVector LastPoint = Head.WorldLocation;

		Points.Add(AlmostRoot);
		Points.Add(FirstPoint);
		
		// note(ylva) Spline beziering for smoothness, but doesn't work well atm. 
		// We get jaggedness when seeker enter/exit the burrow.
		/*
		if (!bIsSleeping)
		{
			float ControlPointFactor = Head.RelativeLocation.Size() * 0.4;
			FVector ToOrigin = (Origin.WorldLocation - Head.WorldLocation).GetSafeNormal();
			FVector SecondControlPoint = Head.WorldLocation + ToOrigin * ControlPointFactor;
			FVector FirstControlPoint = FirstPoint + (SecondControlPoint - FirstPoint) * 0.5;

			const float NumExtraPoints = 2;
			const float Margin = 0.15;
			const float Whole = 1.0 - Margin * 2;
			const float FractionStep = Whole / (NumExtraPoints +1);
			for (int i = 1; i <= NumExtraPoints; ++i)
			{
				float Distance = Margin + FractionStep * i;
				PrintToScreen("Delta step: " + Distance);
				Points.Add(BezierCurve::GetLocation_2CP(FirstPoint, FirstControlPoint, SecondControlPoint, LastPoint, Distance));
				Debug::DrawDebugPoint(Points.Last(), 10, FLinearColor::Red, 0.0, true);
			}
			if (bDebugging)
			{
				Debug::DrawDebugSphere(FirstControlPoint, 100, 12, FLinearColor::Blue);
				Debug::DrawDebugSphere(SecondControlPoint, 100, 12, FLinearColor::Green);
				for (int i = 0; i < Points.Num() -1; ++i)
					Debug::DrawDebugSphere(Points[i], 175);
			}
		}
		*/

		Points.Add(LastPoint);

		TArray<FVector> UpDirections;
		for (int i = 0; i < Points.Num() -1; ++i)
			UpDirections.Add(Origin.UpVector);
		UpDirections.Add(Head.UpVector);

		RuntimeSpline.Points = Points;
		RuntimeSpline.UpDirections = UpDirections;
		RuntimeSpline.SetCustomEnterTangentPoint(Points[0] - Origin.ForwardVector);
		RuntimeSpline.SetCustomExitTangentPoint(Head.WorldLocation + Head.ForwardVector);
		if (bDebugging)
			RuntimeSpline.DrawDebugSpline();
	}

	bool HasReturned()
	{
		if (bIsSwinging && Head.RelativeLocation.Size() < DistanceToOriginCountAsSleepingWithSwingingPlayer)
		{
			DevPrintString("Lightworms", "dist " + Head.RelativeLocation.Size(), 0.0);
			return true;
		}
		else if (Head.RelativeLocation.Size() > DistanceToOriginCountAsSleeping)
			return false;

		float Angle = Math::DotToDegrees(Head.RelativeRotation.ForwardVector.DotProduct(FVector::ForwardVector));
		if (Angle > AngleToOriginCountAsSleeping)
		{
			DevPrintString("Lightworms", "angle " + Angle, 0.0);
			return false;
		}

		return true;
	}
}