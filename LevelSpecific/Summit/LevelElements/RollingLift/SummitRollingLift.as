asset SummitRollingLiftGravitySettings of UMovementGravitySettings
{
	GravityAmount = 10000.0;

	TerminalVelocity = 10000.0;
}

class ASummitRollingLift : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent)
	USceneComponent RollingRoot;
	default RollingRoot.bAbsoluteRotation = true;

	UPROPERTY(DefaultComponent)
	USummitObjectBobbingComponent Bob;

	UPROPERTY(DefaultComponent, Attach = Bob)
	USceneComponent PlatformRoot;
	default PlatformRoot.bAbsoluteRotation = true;

	UPROPERTY(DefaultComponent, Attach = PlatformRoot)
	USceneComponent PlatformPasengerRoot;

	UPROPERTY(DefaultComponent, Attach = RollingRoot)
	USphereComponent CollisionSphere;
	default CollisionSphere.SphereRadius = 375.0;

	UPROPERTY(DefaultComponent)
	UHazeRequestCapabilityOnPlayerComponent RequestComp;

	UPROPERTY(DefaultComponent)
	USceneComponent DriverExitLocation;
	default DriverExitLocation.RelativeLocation = FVector(0, 0, 840);

	UPROPERTY(DefaultComponent)
	UHazeMovementComponent LiftMoveComp;

	UPROPERTY(DefaultComponent)
	UHazeCapabilityComponent CapabilityComp;
	//default CapabilityComp.DefaultCapabilities.Add(n"SummitRollingLiftMovementCapability");

	UPROPERTY(DefaultComponent)
	UDisableComponent DisableComp;
	default DisableComp.bAutoDisable = true;
	default DisableComp.AutoDisableRange = 50000.0;


	/** Camera which is active when you are interacting with the lift */
	UPROPERTY(EditAnywhere, Category = "Camera")
	AHazeCameraActor Camera;

	/** Camera settings which gets enabled when interacting with the lift */
	UPROPERTY(EditAnywhere, Category = "Camera")
	UHazeCameraSettingsDataAsset CameraSettings;

	UPROPERTY(EditAnywhere, Category = "Settings")
	TArray<ASplineActor> MovementGuideSplines;

	/** How fast the lift can go in any direction */
	UPROPERTY(EditAnywhere, Category = "Settings")
	float MaxSpeed = 8000.0;

	UPROPERTY(EditAnywhere, Category = "Settings")
	float Acceleration = 2000.0;

	UPROPERTY(EditAnywhere, Category = "Settings")
	float AccelerationInAir = 1000.0;

	UPROPERTY(EditAnywhere, Category = "Settings")
	float Friction = 1.0;

	UPROPERTY(EditAnywhere, Category = "Settings")
	float AirFriction = 0.3;

	UPROPERTY(EditAnywhere, Category = "Settings")
	float JumpImpulse = 2500.0;

	UPROPERTY(EditAnywhere, Category = "Settings")
	float UpSlopeSpeedMultiplier = 0.15;

	UPROPERTY(EditAnywhere, Category = "Settings")
	float DownSlopeSpeedMultiplier = 0.75;

	UHazeMovementComponent CurrentMoveComp;	

	FVector LastSplineForward;

	bool bIsControlled = false;
	private FVector LastGroundNormal = FVector::UpVector;
	private FVector CurrentGravity;

	TInstigated<float> AccelerationFactor;
	default AccelerationFactor.DefaultValue = 1.0;
	private TArray<UHazeSplineComponent> GuideSplines;
	UHazeSplineComponent CurrentSpline;

	private FVector LastLocation; 

	private ASummitRollingLiftSeeSaw SeeSawCurrentlyOn;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		ApplyDefaultSettings(SummitRollingLiftGravitySettings);

		SetActorControlSide(Game::Zoe);
		CurrentMoveComp = LiftMoveComp;

		for(auto It : MovementGuideSplines)
			GuideSplines.Add(It.Spline);
		
		if(GuideSplines.Num() > 0)
		{
			CurrentSpline = GuideSplines[0];
			auto SplinePos = CurrentSpline.GetClosestSplinePositionToWorldLocation(ActorLocation);
			LastSplineForward = SplinePos.WorldForwardVector;
		}
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		RotateBasedOnVelocity();
		CheckIfOnSeeSawAndNotify();
		LastLocation = ActorLocation;
	}

	FVector GetAccelerationFromInput(FVector MovementInput, float DeltaTime) const 
	{
		float AccelerationToUse = CurrentMoveComp.IsInAir() ? AccelerationInAir : Acceleration;
		AccelerationToUse *= AccelerationFactor.Get();
		FVector FrameAcceleration = MovementInput * AccelerationToUse * DeltaTime;
		TEMPORAL_LOG(this)
			.DirectionalArrow("Frame Acceleration", ActorLocation, FrameAcceleration, 20, 40, FLinearColor::White)
		;
		return FrameAcceleration;
	}

	FVector GetDeceleration(FVector CurrentVelocity, float DeltaTime) const 
	{
		float FrictionToUse = CurrentMoveComp.IsInAir() ? AirFriction : Friction;
		FVector FrameDeceleration = (CurrentVelocity * FrictionToUse) * DeltaTime;
		TEMPORAL_LOG(this)
			.DirectionalArrow("Frame Deceleration", ActorLocation, FrameDeceleration, 20, 40, FLinearColor::Black)
		;
		return FrameDeceleration;
	}

	FVector GetSlopeAcceleration(float DeltaTime) const 
	{
		FVector SlopeAcceleration;

		if(CurrentMoveComp.HorizontalVelocity.IsNearlyZero(100))
			return FVector::ZeroVector;
		FVector HorizontalDir = CurrentMoveComp.HorizontalVelocity.GetSafeNormal();

		float VelocityGravityAlignment = FVector::DownVector.DotProduct(HorizontalDir);
		if(Math::IsNearlyZero(VelocityGravityAlignment, 0.1))
			return FVector::ZeroVector;

		bool bIsGoingUpHill = VelocityGravityAlignment > 0.0;

		float SlopeAccelerationMultiplier = bIsGoingUpHill ? DownSlopeSpeedMultiplier : UpSlopeSpeedMultiplier;
		float SlopeSpeedChange = ((VelocityGravityAlignment * SlopeAccelerationMultiplier) * CurrentMoveComp.GetGravityForce()) * DeltaTime;

		SlopeAcceleration = HorizontalDir * SlopeSpeedChange;

		TEMPORAL_LOG(this)
			.DirectionalArrow("Slope Acceleration", ActorLocation, SlopeAcceleration, 20, 40, FLinearColor::Gray)
		;
		return SlopeAcceleration;
	}

	FVector ClampVelocityToMaxSpeed(FVector CurrentVelocity) const 
	{
		return CurrentVelocity.GetClampedToMaxSize(MaxSpeed);
	}

	private void RotateBasedOnVelocity()
	{	
		FVector RotationAxis;
		FVector GroundNormal;
		
		if(CurrentMoveComp.IsOnAnyGround())
		{
			GroundNormal = CurrentMoveComp.CurrentGroundNormal;
			LastGroundNormal = GroundNormal;
		}
		else
		{
			GroundNormal = LastGroundNormal;
		}
		RotationAxis = GroundNormal.CrossProduct(CurrentMoveComp.HorizontalVelocity).GetSafeNormal();

		FVector CurrentVelocity = (ActorLocation - LastLocation) / Time::GlobalWorldDeltaSeconds;
		FVector CurrentHorizontalVelocity = CurrentVelocity.ConstrainToPlane(LastGroundNormal);

		float Speed = CurrentHorizontalVelocity.Size();

		float Angle = -Speed / CollisionSphere.SphereRadius;
		
		FRotator AdditionalRotation = FRotator::MakeFromEuler(RotationAxis * Angle);
		RollingRoot.AddWorldRotation(AdditionalRotation);
	}


	FSplinePosition UpdateBestGuideSpline(AHazePlayerCharacter Driver)
	{
		FVector MovementDir = Driver.ActorVelocity.GetSafeNormal();
		if(MovementDir.IsNearlyZero())
			MovementDir = LastSplineForward;
		if(MovementDir.IsNearlyZero())
			MovementDir = Driver.ActorForwardVector;

		const FVector CurrentLocation = Driver.ActorLocation;

		if(HasControl())
		{
			FSplinePosition BestFoundSplinePosition;
			bool bFoundIsAtEnd = false;

			// If we don't have a spline, we need to find the closest one
			if(CurrentSpline == nullptr)
			{
				float ClosestDistanceSq = BIG_NUMBER;
				for(auto It : GuideSplines)
				{
					FSplinePosition SplinePosition = It.GetClosestSplinePositionToWorldLocation(CurrentLocation);
					float DistSq = SplinePosition.WorldLocation.DistSquared(CurrentLocation);
					if(DistSq > ClosestDistanceSq)
						continue;
					ClosestDistanceSq = DistSq;
					BestFoundSplinePosition = SplinePosition;
				}
				
				CurrentSpline = BestFoundSplinePosition.CurrentSpline;
			}

			if(CurrentSpline != nullptr)
			{
				BestFoundSplinePosition = CurrentSpline.GetClosestSplinePositionToWorldLocation(CurrentLocation);
				float ForwardDot = MovementDir.DotProduct(BestFoundSplinePosition.WorldForwardVector);
		
				// Moving backwards
				if(ForwardDot < 0 && BestFoundSplinePosition.CurrentSplineDistance < 10 && CurrentSpline != GuideSplines[0])
					bFoundIsAtEnd = true;
				// Moving forward
				else if(ForwardDot > 0 && BestFoundSplinePosition.CurrentSplineDistance > BestFoundSplinePosition.CurrentSpline.SplineLength - 10)
					bFoundIsAtEnd = true;
			}

			// If we reach the end of the current spline
			// we try to find the next spline in line depending if we are moving backwards or forward
			if(bFoundIsAtEnd)
			{
				for(auto It : GuideSplines)
				{
					if(It == CurrentSpline)
						continue;

					FSplinePosition SplinePosition = It.GetClosestSplinePositionToWorldLocation(CurrentLocation);
					float ForwardDot = MovementDir.DotProduct(BestFoundSplinePosition.WorldForwardVector);
						
					// Moving forward
					if(ForwardDot > 0)
					{
						if(SplinePosition.CurrentSplineDistance > BestFoundSplinePosition.CurrentSplineDistance)
							continue;

						BestFoundSplinePosition = SplinePosition;
					}
					// Moving backward
					else if(ForwardDot < 0)
					{
						if(SplinePosition.CurrentSplineDistance < BestFoundSplinePosition.CurrentSplineDistance)
							continue;

						BestFoundSplinePosition = SplinePosition;
					}
				}
			}

			if(BestFoundSplinePosition.CurrentSpline != CurrentSpline)
			{
				CrumbFollowSpline(BestFoundSplinePosition.CurrentSpline);
			}
			
			LastSplineForward = BestFoundSplinePosition.WorldForwardVector * Math::Sign(BestFoundSplinePosition.WorldForwardVector.DotProduct(MovementDir));
			//Debug::DrawDebugString(BestFoundSplinePosition.WorldLocation, f"{CurrentSpline.Owner.GetActorLabel()}");
			return BestFoundSplinePosition;
		}
		else if(CurrentSpline != nullptr)
		{
			FSplinePosition Out = CurrentSpline.GetClosestSplinePositionToWorldLocation(CurrentLocation);
			LastSplineForward = Out.WorldForwardVector * Math::Sign(Out.WorldForwardVector.DotProduct(MovementDir));
			return Out;
		}

		return FSplinePosition();
		
	}

	UFUNCTION(CrumbFunction)
	private void CrumbFollowSpline(UHazeSplineComponent NewSpline)
	{
		CurrentSpline = NewSpline;
	}

	UFUNCTION(NotBlueprintCallable)
	void OnDoubleInteractionCompleted()
	{
		bIsControlled = true;

		// Attach the driver
		{
			auto Player = Game::GetZoe();
			{
				RequestComp.StartInitialSheetsAndCapabilities(Player, this);
				auto LiftComp = USummitTeenDragonRollingLiftComponent::Get(Player);
				LiftComp.CurrentRollingLift = this;
				LiftComp.bIsDriver = true;
			}
		}

		// Attach the passenger
		{
			auto Player = Game::GetMio();
			{
				RequestComp.StartInitialSheetsAndCapabilities(Player, this);
				auto LiftComp = USummitTeenDragonRollingLiftComponent::Get(Player);
				LiftComp.CurrentRollingLift = this;
				LiftComp.bIsDriver = false;
			}
		}

		OnDrivingStarted();
	}

	void ExitRollingLift()
	{
		for(auto Player : Game::Players)
		{
			RequestComp.StopInitialSheetsAndCapabilities(Player, this);
		}
		OnDrivingStopped();
	}

	UFUNCTION(BlueprintEvent)
	protected void OnDrivingStarted()
	{

	}

	UFUNCTION(BlueprintEvent)
	protected void OnDrivingStopped()
	{

	}

	void CheckIfOnSeeSawAndNotify()
	{
		if(SeeSawCurrentlyOn != nullptr)
			SeeSawCurrentlyOn.CurrentImpactingData.Reset();
		
		auto GroundImpact = CurrentMoveComp.GetGroundContact();
		auto SeeSaw = Cast<ASummitRollingLiftSeeSaw>(GroundImpact.Actor);
		if(SeeSaw != nullptr)
		{
			FSummitRollingLiftSeeSawData SeeSawData;
			SeeSawData.ImpactLocation = GroundImpact.ImpactPoint;
			SeeSawData.RollingLift = this;
			SeeSawCurrentlyOn = SeeSaw;
			SeeSawCurrentlyOn.CurrentImpactingData.Set(SeeSawData);
		} 
	}
};