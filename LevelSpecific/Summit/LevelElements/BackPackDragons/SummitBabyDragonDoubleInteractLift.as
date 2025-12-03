event void FOnBackpackActivated();event void FOnBackpackDectivated();event void FOnBackpackReady();
class ASummitBabyDragonDoubleInteractLift : AHazeActor
{
	UPROPERTY()
	FOnBackpackActivated OnActivated;

	UPROPERTY()
	FOnBackpackActivated OnDeactivated;

	UPROPERTY()
	FOnBackpackReady OnReady;

	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent ClimbRoot;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent InteractRoot;

	UPROPERTY(DefaultComponent)
	UHazeCapabilityComponent CapabilityComp;
	default CapabilityComp.DefaultCapabilities.Add(n"SummitBabyDragonDoubleInteractLiftCapability");

	UPROPERTY()
	bool bIsActive;

	UPROPERTY(EditAnywhere, Category = "Settings")
	bool bPlayAnimationOnMioDragon = true;

	UPROPERTY(EditAnywhere, Category = "Settings", Meta = (EditCondition = bPlayAnimationOnMioDragon, EditConditionHides))
	FHazePlaySlotAnimationParams MioDragonInteractAnimation;

	UPROPERTY(EditAnywhere, Category = "Settings", Meta = (EditCondition = bPlayAnimationOnMioDragon, EditConditionHides))
	float TimeUntilFruitGetsEatenFromStartOfAnimation = 2.60;

	UPROPERTY(EditAnywhere, Category = "Settings", Meta = (EditCondition = bPlayAnimationOnMioDragon, EditConditionHides))
	UNiagaraSystem EffectWhenFruitGetsEaten;

	UOneShotInteractionComponent OneShotInteractComp;
	UStaticMeshComponent FruitSphereMesh;	

	bool bFruitAnimationIsPlaying = false;
	float TimeFruitAnimationStartedPlaying;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		if(bPlayAnimationOnMioDragon)
		{
			OneShotInteractComp = UOneShotInteractionComponent::Get(this);
			if(OneShotInteractComp != nullptr)
			{
				OneShotInteractComp.OnInteractionStarted.AddUFunction(this, n"OneShotInteractStarted");
				OneShotInteractComp.OnInteractionStopped.AddUFunction(this, n"OneShotInteractStopped");
			}

			FruitSphereMesh = UStaticMeshComponent::Get(this, n"Sphere");
		}
	}

	

	UFUNCTION()
	private void OneShotInteractStarted(UInteractionComponent InteractionComponent, AHazePlayerCharacter Player)
	{
		auto DragonComp = UPlayerBabyDragonComponent::Get(Player);
		if(DragonComp == nullptr)
			return;

		DragonComp.BabyDragon.PlaySlotAnimation(MioDragonInteractAnimation);
		FruitSphereMesh.AttachTo(Player.Mesh, n"LeftAttach", EAttachLocation::SnapToTarget);

		bFruitAnimationIsPlaying = true;
		TimeFruitAnimationStartedPlaying = Time::GameTimeSeconds;
	}

	UFUNCTION()
	private void OneShotInteractStopped(UInteractionComponent InteractionComponent,
	                                    AHazePlayerCharacter Player)
	{
		
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		if(bFruitAnimationIsPlaying
		&& Time::GetGameTimeSince(TimeFruitAnimationStartedPlaying) > TimeUntilFruitGetsEatenFromStartOfAnimation)		
		{
			EatFruit();
		}
	}

	private void EatFruit()
	{
		if(FruitSphereMesh == nullptr)
			return;

		if(EffectWhenFruitGetsEaten != nullptr)
			Niagara::SpawnOneShotNiagaraSystemAtLocation(EffectWhenFruitGetsEaten, FruitSphereMesh.WorldLocation);

		FruitSphereMesh.DetachFromParent();
		FruitSphereMesh.AddComponentCollisionBlocker(this);
		FruitSphereMesh.AddComponentTickBlocker(this);
		FruitSphereMesh.AddComponentVisualsBlocker(this);

		bFruitAnimationIsPlaying = false;
	}

	UFUNCTION()
	void Activate()
	{
		if (bIsActive)
			return;
		bIsActive = true;
		OnActivated.Broadcast();
		BP_Activate();
	}

	UFUNCTION()
	void Reverse()
	{
		bIsActive = false;
		OnDeactivated.Broadcast();
		BP_Reverse();
	}
	
	UFUNCTION(BlueprintEvent)
	void BP_Activate() 
    {
		
	}

	UFUNCTION(BlueprintEvent)
	void BP_Reverse() 
    {
		
	}

}

class USummitBabyDragonDoubleInteractLiftCapability : UHazeCapability
{
	default TickGroup = EHazeTickGroup::BeforeMovement;

	UPlayerTailBabyDragonComponent DragonComp;
	UPlayerMovementComponent MioMovementComp;

	ASummitBabyDragonDoubleInteractLift BackpackInteractActor;

	bool bIsHanging;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		BackpackInteractActor = Cast<ASummitBabyDragonDoubleInteractLift>(Owner);
	}

	UFUNCTION(BlueprintOverride)
	void PreTick(float DeltaTime)
	{
		if (DragonComp == nullptr)
			DragonComp = UPlayerTailBabyDragonComponent::Get(Game::Zoe);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (DragonComp == nullptr)
			return false;
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (DragonComp == nullptr)
			return true;
		return false;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{

		if (DragonComp.ClimbState == ETailBabyDragonClimbState::Hang
			&& DragonComp.AttachmentComponent != nullptr
			&& DragonComp.AttachmentComponent.Owner == Owner)
		{
			// PrintToScreen("hejsan", 1);
			bIsHanging = true;
			BackpackInteractActor.Activate();
		} else {
			bIsHanging = false;
		}

		if (BackpackInteractActor.bIsActive && !bIsHanging)
		{
			BackpackInteractActor.Reverse();
		}
	}
};