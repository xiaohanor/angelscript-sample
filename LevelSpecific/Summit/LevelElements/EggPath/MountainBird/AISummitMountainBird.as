class AAISummitMountainBird : ABasicAIFlyingCharacter
{
	access ReadOnlyAccess = private, * (readonly);

	//default CapabilityComp.DefaultCapabilities.Add(n"SummitMountainBirdTakeFlightCapability");
	//default CapabilityComp.DefaultCapabilities.Add(n"SummitMountainBirdHoverCapability");
	//default CapabilityComp.DefaultCapabilities.Add(n"SummitMountainBirdFreeFlyHoverCapability");
	//default CapabilityComp.DefaultCapabilities.Add(n"SummitMountainBirdLandCapability");
	default CapabilityComp.DefaultCapabilities.Add(n"SummitMountainFlyAwayCapability");

	UPROPERTY(EditAnywhere)
	ASummitMountainBirdFlightSpotScenepointActor EscapeLocation;

	//
	// Animations
	//

	UPROPERTY(EditDefaultsOnly, Category = "Animations")
	UAnimSequence IdleAnimation;

	UPROPERTY(EditDefaultsOnly, Category = "Animations")
	UAnimSequence TakeOffAnimation;

	UPROPERTY(EditDefaultsOnly, Category = "Animations")
	UAnimSequence LandAnimation;
	
	UPROPERTY(EditDefaultsOnly, Category = "Animations")
	UAnimSequence GlideAnimation;

	UPROPERTY(EditDefaultsOnly, Category = "Animations")
	UAnimSequence FlapAnimation;
	
	UPROPERTY(EditDefaultsOnly, Category = "Animations")
	UAnimSequence FlyAwayAnimation;

	// Nest location
	FVector NestLocation;
	FRotator InitialRotation;

	// Optional home landing spot. Could take off from another landing spot to return to 
	UPROPERTY(EditInstanceOnly)
	ASummitMountainBirdLandingSpot NestLandingSpot;

	// When any player is within this range, bird takes off.
	UPROPERTY(EditInstanceOnly)
	float PlayerClosebyRange = 1600;

	ASummitMountainBirdLandingSpot CurrentLandingSpot;

	access:ReadOnlyAccess
	ESummitMountainBirdFlightState CurrentState = ESummitMountainBirdFlightState::Idle;

	access:ReadOnlyAccess
	ESummitMountainBirdFlightState PrevState = ESummitMountainBirdFlightState::Idle;
	bool bIsReturningToNest = false;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Super::BeginPlay();

		SummitMountainBird::Animations::PlayIdleAnimation(this);
		NestLocation = ActorLocation;
		InitialRotation = ActorRotation;

		// Claim forever.
		if (NestLandingSpot != nullptr)
		{
			NestLandingSpot.Claim(this);
			NestLandingSpot.bIsNest = true;
		}
	}

	// Idle capability
	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		if (CurrentState == ESummitMountainBirdFlightState::Idle)
		{
			float PlayerCloseRangeSqr = PlayerClosebyRange * PlayerClosebyRange;
			AHazePlayerCharacter Player = Game::GetClosestPlayer(ActorLocation);
			if (Player.ActorLocation.DistSquared(NestLocation) < PlayerCloseRangeSqr && ActorLocation.DistSquared(NestLocation) < 100)
			{
				if (CurrentState != ESummitMountainBirdFlightState::TakeFlight)
					USummitMountainBirdEventHandler::Trigger_OnPlayerTooClose(this);
				SetCurrentState(ESummitMountainBirdFlightState::TakeFlight);				
			}			
		}

	}

	void SetCurrentState(ESummitMountainBirdFlightState NewState)
	{
		if (CurrentState == NewState)
			return;

		// Can happen when using the DevReset function
		if (CurrentState == ESummitMountainBirdFlightState::Idle && NewState != ESummitMountainBirdFlightState::TakeFlight)
			return;

		PrevState = CurrentState;
		CurrentState = NewState;
	}

	UFUNCTION(DevFunction)
	void DevReset()
	{
		PrevState = ESummitMountainBirdFlightState::Idle;
		CurrentState = ESummitMountainBirdFlightState::Idle;
		ActorLocation = NestLocation;
		ActorRotation = InitialRotation;
		SummitMountainBird::Animations::PlayIdleAnimation(this);
	}
}

enum ESummitMountainBirdFlightState
{
	Idle,
	TakeFlight,
	Hover,
	Land
}

class ASummitMountainBirdFlightSpotScenepointActor : AScenepointActor
{
	UPROPERTY(DefaultComponent)
	UHazeListedActorComponent ListedActorComp;
}