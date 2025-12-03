
UCLASS(Abstract)
class ASummitSlingshot : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent LeftRoot;
	
	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent RightRoot;

	UPROPERTY(DefaultComponent, Attach = BasketRoot)
	UHazeTEMPCableComponent LeftCable;
	
	UPROPERTY(DefaultComponent, Attach = BasketRoot)
	UHazeTEMPCableComponent RightCable;

	UPROPERTY(DefaultComponent, Attach = BasketRoot)
	UHazeTEMPCableComponent PullCable;

	UPROPERTY(DefaultComponent, Attach = Root)
	UFauxPhysicsTranslateComponent BasketRoot;

	UPROPERTY(DefaultComponent, Attach = Root)
	UFauxPhysicsTranslateComponent PullRoot;

	UPROPERTY(DefaultComponent, Attach = BasketRoot)
	UBoxComponent BasketLaunchCollision;

	UPROPERTY(DefaultComponent, Attach = PullRoot)
	UInteractionComponent PullInteraction;
	default PullInteraction.UsableByPlayers = EHazeSelectPlayer::Zoe;
	default PullInteraction.InteractionCapability = n"SummitSlingshotPullCapability";

	// Camera to use while pulling the slingshot
	UPROPERTY(EditAnywhere, Category = "Slingshot")
	AHazeCameraActor Camera;
	
	// Maximum angle we can rotate the slingshot basket in
	UPROPERTY(EditAnywhere, Category = "Slingshot")
	float PullMaxAngle = 45.0;

	// Maximum distance to pull
	UPROPERTY(EditAnywhere, Category = "Slingshot")
	float PullMaxDistance = 3000.0;

	// Height of the basket at the top of the slingshot
	UPROPERTY(EditAnywhere, Category = "Slingshot")
	float BasketBaseHeight = 800.0;

	// How fast does the basket move?
	UPROPERTY(EditAnywhere, Category = "Slingshot")
	float BasketMovementSpeed = 500.0;

	// Acceleration used when pulling the basket
	UPROPERTY(EditAnywhere, Category = "Slingshot")
	float BasketAcceleration = 600.0;

	// Strength of the basket spring
	UPROPERTY(EditAnywhere, Category = "Slingshot")
	float BasketSpringStrength = 50.0;

	// How much we launch the acid dragon
	UPROPERTY(EditAnywhere, Category = "Slingshot")
	FVector LaunchImpulse(6000.0, 0.0, 4000.0);

	private bool bIsPulling = false;
	private bool bIsLaunching = false;
	private bool bPerformedImpulse = false;
	private float LaunchGameTime = 0.0;
	private FVector LaunchDirection;
	private float LaunchPct;
	private float PullMinDistance;

	private float PullTetherAngle = 0.0;
	private float PullTetherLength = 0.0;
	FVector OriginalSpringOffset;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		LeftCable.SetAttachEndTo(this, n"LeftRoot");
		RightCable.SetAttachEndTo(this, n"RightRoot");
		PullCable.SetAttachEndTo(this, n"PullRoot");

		PullMinDistance = -PullRoot.RelativeLocation.X;
		PullTetherLength = PullMinDistance;
		MovePullDelta(FVector::ZeroVector);

		BasketRoot.SpringStrength = BasketSpringStrength;
		BasketRoot.SpringParentOffset = BasketRoot.RelativeLocation;
		OriginalSpringOffset = BasketRoot.RelativeLocation;
	}

	void MovePullDelta(FVector Delta)
	{
		FVector DeltaRelative = PullRoot.WorldTransform.InverseTransformVector(Delta);

		float WantedBackMovement = -DeltaRelative.X;
		if (WantedBackMovement != 0.0)
			PullTetherLength = Math::Clamp(PullTetherLength + WantedBackMovement, PullMinDistance, PullMaxDistance);

		float WantedSideMovement = -DeltaRelative.Y / (PullTetherLength * TWO_PI / 360.0);
		if (WantedSideMovement != 0.0)
			PullTetherAngle = Math::Clamp(PullTetherAngle + WantedSideMovement, -PullMaxAngle, PullMaxAngle);

		FQuat TetherRotation = FQuat(FVector::UpVector, Math::DegreesToRadians(PullTetherAngle));
		FVector PullWanted = TetherRotation.RotateVector(-FVector::ForwardVector * PullTetherLength);

		PullRoot.RelativeLocation = PullWanted;
		PullRoot.RelativeRotation = FRotator::MakeFromX(-PullWanted);

		FVector BasketRelative = PullWanted + (FVector(0.0, 0.0, BasketBaseHeight) - PullWanted).GetSafeNormal() * 600.0;
		BasketRoot.RelativeLocation = BasketRelative;
		BasketRoot.RelativeRotation = FRotator::MakeFromX(FVector(0.0, 0.0, BasketBaseHeight) - BasketRelative);
	}

	void StartPulling()
	{
		bIsPulling = true;
		BasketRoot.AddDisabler(this);
	}

	void StopPulling()
	{
		bIsPulling = false;
		BasketRoot.RemoveDisabler(this);

		FVector BasketRelative = BasketRoot.RelativeLocation;
		if (BasketRelative.X < BasketRoot.SpringParentOffset.X - 50.0)
		{
			bIsLaunching = true;
			bPerformedImpulse = false;
			LaunchGameTime = Time::GameTimeSeconds;
			LaunchDirection = (ActorTransform.TransformPosition(BasketRoot.SpringParentOffset) - PullRoot.WorldLocation).GetSafeNormal();
			LaunchPct = -PullRoot.RelativeLocation.X / PullMaxDistance;
			PullInteraction.Disable(this);

			BasketRoot.SpringParentOffset = FVector(0.0, 0.0, BasketBaseHeight);
		}
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		if (bIsLaunching)
		{
			if (!bPerformedImpulse)
			{
				if (Time::GetGameTimeSince(LaunchGameTime) > 0.2)
				{
					FVector Impulse = FRotator::MakeFromX(LaunchDirection.GetSafeNormal2D()).RotateVector(LaunchImpulse * LaunchPct);

					TArray<AActor> Overlaps;
					BasketLaunchCollision.GetOverlappingActors(Overlaps);

					//auto MioDragonComp = UPlayerTeenDragonComponent::Get(Game::Mio);
					if (Overlaps.Contains(Game::Mio))
						Game::Mio.AddMovementImpulse(Impulse);

					bPerformedImpulse = true;
					BasketRoot.SpringParentOffset = OriginalSpringOffset;
				}
			}

			bool bFinishedLaunching = BasketRoot.GetVelocity().Size() < 30.0
				&& BasketRoot.RelativeLocation.Equals(BasketRoot.SpringParentOffset, 20.0)
				&& bPerformedImpulse;

			if (bFinishedLaunching)
			{
				bIsLaunching = false;
				PullInteraction.Enable(this);
			}
		}

		if (!bIsPulling)
		{
			PullTetherLength = Math::FInterpTo(PullTetherLength, PullMinDistance, DeltaSeconds, 3.0);
			PullTetherAngle = Math::FInterpTo(PullTetherAngle, 0.0, DeltaSeconds, 3.0);

			FQuat TetherRotation = FQuat(FVector::UpVector, Math::DegreesToRadians(PullTetherAngle));
			FVector PullWanted = TetherRotation.RotateVector(-FVector::ForwardVector * PullTetherLength);

			PullRoot.RelativeLocation = PullWanted;
			PullRoot.RelativeRotation = FRotator::MakeFromX(-PullWanted);

			FVector BasketRelative = BasketRoot.RelativeLocation;
			if (BasketRelative.X < -50.0 && (!bIsLaunching || Time::GetGameTimeSince(LaunchGameTime) > 0.5))
			{
				FRotator Rotation = FRotator::MakeFromX(FVector(0.0, 0.0, BasketBaseHeight) - BasketRelative);
				BasketRoot.RelativeRotation = Math::RInterpConstantTo(BasketRoot.RelativeRotation, Rotation, DeltaSeconds, 180.0);
			}
		}
	}
};