UCLASS(Abstract)
class APigWorldGrill : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	UFauxPhysicsConeRotateComponent RotateComp;

	UPROPERTY(DefaultComponent, Attach = RotateComp)
	UCapsuleComponent OverlapComp;

	UPROPERTY(DefaultComponent, Attach = RotateComp)
	UBoxComponent FlameOverlapComp;

	UPROPERTY(DefaultComponent, Attach = RotateComp)
	UBoxComponent GrillOverlapComp;

	UPROPERTY(DefaultComponent, Attach = RotateComp)
	UArrowComponent LaunchDirectionComp;

	UPROPERTY(DefaultComponent)
	UMovementImpactCallbackComponent ImpactComp;

	UPROPERTY(DefaultComponent, Attach = Root)
	UOneShotInteractionComponent InteractComp;

	UPROPERTY()
	bool bCanImpact = true;

	UPROPERTY()
	bool bFlameOn = false;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		//ImpactComp.OnAnyImpactByPlayer.AddUFunction(this, n"WallImpact");
		GrillOverlapComp.OnComponentBeginOverlap.AddUFunction(this, n"OverlapGrill");
		OverlapComp.OnComponentBeginOverlap.AddUFunction(this,n"OverlapButton");
		InteractComp.OnInteractionStarted.AddUFunction(this,n"InteractStarted");
	}

	UFUNCTION()
	private void OverlapButton(UPrimitiveComponent OverlappedComponent, AActor OtherActor,
	                           UPrimitiveComponent OtherComp, int OtherBodyIndex, bool bFromSweep,
	                           const FHitResult&in SweepResult)
	{
		AHazePlayerCharacter Player = Cast<AHazePlayerCharacter>(OtherActor);

		// if(!bFlameOn)
		// {
		// 	OnWallImpact(Player);
		// 	Player.ResetMovement();
		// 	FVector LaunchImpulse = LaunchDirectionComp.GetForwardVector()*1200;
		// 	LaunchImpulse.Z = 800;
		// 	Player.AddMovementImpulse(LaunchImpulse);
		// }
		// if(bFlameOn)
		// {
		// 	OnWallImpact(Player);
		// 	Player.ResetMovement();
		// 	FVector LaunchImpulse = LaunchDirectionComp.GetForwardVector()*1200;
		// 	LaunchImpulse.Z = 800;
		// 	Player.AddMovementImpulse(LaunchImpulse);
		// }
	}

	UFUNCTION()
	private void InteractStarted(UInteractionComponent InteractionComponent, AHazePlayerCharacter Player)
	{
		FPigWorldGrillParams Params;
		Params.Player = Player;
		UPigWorldGrillEventHandler::Trigger_TurnOnGrill(this,Params);
		Print("Itneract!");
	}

	UFUNCTION()
	private void OverlapGrill(UPrimitiveComponent OverlappedComponent, AActor OtherActor,
	                     UPrimitiveComponent OtherComp, int OtherBodyIndex, bool bFromSweep,
	                     const FHitResult&in SweepResult)
	{

		AHazePlayerCharacter Player = Cast<AHazePlayerCharacter>(OtherActor);

		if(OtherActor == Player && OtherActor.HasControl())
		{
			UPlayerPigSausageComponent PigSausageComponent = UPlayerPigSausageComponent::Get(OtherActor);
			if (PigSausageComponent != nullptr)
				PigSausageComponent.Crumbed_RemoveCondiments();
		}
	}

	// UFUNCTION()
	// private void WallImpact(AHazePlayerCharacter Player)
	// {
	// 	if(OverlapComp.IsOverlappingActor(Player) && !bFlameOn)
	// 	{
	// 		OnWallImpact(Player);
	// 		Player.ResetMovement();
	// 		FVector LaunchImpulse = LaunchDirectionComp.GetForwardVector()*1200;
	// 		LaunchImpulse.Z = 800;
	// 		Player.AddMovementImpulse(LaunchImpulse);
	// 	}

	// 	if(FlameOverlapComp.IsOverlappingActor(Player) && bFlameOn)
	// 	{
	// 		OnWallImpact(Player);
	// 		Player.ResetMovement();
	// 		FVector LaunchImpulse = LaunchDirectionComp.GetForwardVector()*1200;
	// 		LaunchImpulse.Z = 800;
	// 		Player.AddMovementImpulse(LaunchImpulse);
	// 	}
	// }

	UFUNCTION(BlueprintEvent)
	void OnWallImpact(AHazePlayerCharacter Player){}

	UFUNCTION(BlueprintEvent)
	void OnFlameImpact(AHazePlayerCharacter Player){}

};
