UCLASS(Abstract)
class ASummitKnightShieldwallBase : AHazeActor
{
	default PrimaryActorTick.bStartWithTickEnabled = false;

	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent)
	USummitObjectBobbingComponent BobbingComponent;

	UPROPERTY(DefaultComponent, Attach = BobbingComponent)
	USceneComponent MeshRoot;

	UPROPERTY(DefaultComponent, Attach = MeshRoot)
	USceneComponent Shields;

	UPROPERTY(DefaultComponent, Attach = MeshRoot)
	USceneComponent ShieldTarget;

	UPROPERTY(DefaultComponent)
	URotatingMovementComponent RotatingMovement;

	USummitKnightSettings Settings;

	FVector StartLocation = FVector(BIG_NUMBER);
	FVector TargetLocation = FVector(BIG_NUMBER);
	FHazeAcceleratedFloat DeployedOffset;
	bool bDeployed = false;
	float Radius = 0.0;
	float PlayerDetectionRadius = 0.0;
	bool bStartedRaising = false;

	UPROPERTY(EditAnywhere)
	FHazeTimeLike MoveAnim;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		float RadiusSum = 0.0;
		TArray<USceneComponent> AttachedComps;
		Root.GetChildrenComponents(true, AttachedComps);
		TArray<ANightQueenShield> AttachedShields;
		for (USceneComponent AttachComp : AttachedComps)
		{
			ANightQueenShield Shield = Cast<ANightQueenShield>(AttachComp.Owner);
			if (Shield != nullptr)
				AttachedShields.Add(Shield);
		}

		// Attach shields to mesh root component
		for (ANightQueenShield Shield : AttachedShields)
		{
			Shield.RootComponent.AttachToComponent(MeshRoot, NAME_None, EAttachmentRule::KeepWorld);
		}	

		// Find average radius of shields
		for (ANightQueenShield Shield : AttachedShields)
		{
			RadiusSum += Shield.ActorLocation.Dist2D(ActorLocation);		
		}
		if (AttachedShields.Num() > 0)
			Radius = RadiusSum / float(AttachedShields.Num());
		if (Radius < 1000.0)
			Radius = 1000.0;

		Settings = USummitKnightSettings::GetSettings(this);
		PlayerDetectionRadius = Radius + 1000.0;
		StartLocation = ActorLocation;
		TargetLocation = StartLocation + ShieldTarget.RelativeLocation;
	}

	void Deploy()
	{
		bDeployed = true;
	}

	void Remove()
	{
		bDeployed = false;
		bStartedRaising = false;
	}

	bool IsRemoved()
	{
		if (bDeployed)
			return false;
		if (MoveAnim.Value > 0.01)
			return false;  
		if (DeployedOffset.Value > -9900)
			return false;
		return true;	
	}

	// Called from knight shieldwall capability
	void Update(float DeltaTime)
	{
		if (bDeployed)
		{
			// Slow down when nearing deployment height
			float DeployDuration = 5000.0 / (Math::Abs(DeployedOffset.Value) + 2000.0);
			DeployedOffset.AccelerateTo(0.0, DeployDuration, DeltaTime);		

			float PlayerDistSqr = Game::Zoe.ActorLocation.DistSquared2D(ActorLocation);	
			if (PlayerDistSqr < Math::Square(Math::Max(Radius - Settings.ShieldwallLowerWhenInsideBuffer, 0.0)))
			{
				// Lower shields when we're far enough inside them
				if ((MoveAnim.Value > 0.99) && !MoveAnim.IsReversed())
					MoveAnim.Reverse();
			}
			else if (Settings.ShieldWallOnlyRaiseNearTailDragon)
			{
				if ((MoveAnim.Value < 0.01) && (PlayerDistSqr < Math::Square(PlayerDetectionRadius)))
					MoveAnim.Play();
				else if ((MoveAnim.Value > 0.99) && (PlayerDistSqr > Math::Square(PlayerDetectionRadius * 1.2)))
					MoveAnim.Reverse();
			}
			else if ((MoveAnim.Value < 0.01) && (PlayerDistSqr > Math::Square(Radius)))
			{
				MoveAnim.Play();	
			}

			if (!bStartedRaising && MoveAnim.IsPlaying())
			{
				bStartedRaising = true;
				USummitKnightShieldwallEventHandler::Trigger_OnRaiseWall(this);
			}	
		}
		else
		{
			// Slowly at first when retracting
			float DeployDuration = 2000.0 / (Math::Abs(DeployedOffset.Value) + 500.0);
			DeployedOffset.AccelerateTo(-10000.0, DeployDuration, DeltaTime);		
			MoveAnim.Reverse();
		}

		// Move
		ActorLocation = Math::Lerp(StartLocation, TargetLocation, MoveAnim.Value) + FVector(0.0, 0.0, DeployedOffset.Value);

		if (MoveAnim.IsReversed())
			bStartedRaising = false;
	}
};