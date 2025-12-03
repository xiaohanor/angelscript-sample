UCLASS(Abstract)
class ASummitCrossbow : AHazeActor
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

	UPROPERTY(DefaultComponent, Attach = Root)
	UFauxPhysicsTranslateComponent BasketRoot;

	UPROPERTY(DefaultComponent, Attach = BasketRoot)
	UBoxComponent BasketLaunchCollision;

	UPROPERTY(DefaultComponent, Attach = BasketRoot)
	UInteractionComponent PullInteraction;
	default PullInteraction.UsableByPlayers = EHazeSelectPlayer::Zoe;
	default PullInteraction.InteractionCapability = n"SummitCrossbowPullCapability";

	// Camera to use while pulling the slingshot
	UPROPERTY(EditAnywhere, Category = "Slingshot")
	AHazeCameraActor Camera;
	
	private bool bIsPulling = false;
	private bool bIsLaunching = false;
	private bool bPerformedImpulse = false;
	private float LaunchGameTime = 0.0;
	private FVector LaunchDirection;
	private float LaunchPct;
	private FVector OriginalSpringOffset;

	UPROPERTY(EditAnywhere, Category = "Slingshot")
	USummitCrossbowSettings CrossbowSettings;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		if(CrossbowSettings != nullptr)
			ApplyDefaultSettings(CrossbowSettings);
		else
			CrossbowSettings = USummitCrossbowSettings::GetSettings(this);

		LeftCable.SetAttachEndTo(this, n"LeftRoot");
		RightCable.SetAttachEndTo(this, n"RightRoot");

		MovePullDelta(0.0);

		BasketRoot.SpringStrength = CrossbowSettings.BasketSpringStrength;
		BasketRoot.SpringParentOffset = BasketRoot.RelativeLocation;
		OriginalSpringOffset = BasketRoot.RelativeLocation;
	}

	void MovePullDelta(float PullDelta)
	{
		float PullResistance = 1 - CrossbowSettings.PullResistance.GetFloatValue(GetPullAlpha());
		float ResistedPullDelta = PullDelta * PullResistance; 
		FVector Pos = BasketRoot.RelativeLocation;
		Pos.X = Math::Clamp(Pos.X - ResistedPullDelta, OriginalSpringOffset.X - CrossbowSettings.PullMaxDistance, OriginalSpringOffset.X);
		BasketRoot.SetRelativeLocation(Pos);
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
			LaunchDirection = BasketRoot.ForwardVector;
			LaunchPct = (OriginalSpringOffset.X - BasketRoot.RelativeLocation.X) / CrossbowSettings.PullMaxDistance;
			PullInteraction.Disable(this);
		}
	}

	float GetPullAlpha() const
	{
		return BasketRoot.RelativeLocation.X / (OriginalSpringOffset.X - CrossbowSettings.PullMaxDistance);
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
					FVector Impulse = FRotator::MakeFromX(LaunchDirection.GetSafeNormal2D()).RotateVector(CrossbowSettings.LaunchImpulse * LaunchPct);

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
	}
};