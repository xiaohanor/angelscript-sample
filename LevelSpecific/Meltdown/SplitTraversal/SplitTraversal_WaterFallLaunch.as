UCLASS(Abstract)
class ASplitTraversal_WaterFallLaunch : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root, ShowOnActor, Category = "LaunchSettings")
	UBoxComponent LaunchVolume;

	UPROPERTY(DefaultComponent, Attach = Root)
	UArrowComponent LaunchDirection;

	UPROPERTY(EditAnywhere, Category = "LaunchSettings")
	float ImpulseStrength = 1000;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		LaunchVolume.OnComponentBeginOverlap.AddUFunction(this, n"Launch");
		LaunchVolume.OnComponentEndOverlap.AddUFunction(this, n"ExitLaunch");
	}

	UFUNCTION()
	private void Launch(UPrimitiveComponent OverlappedComponent, AActor OtherActor,
	                    UPrimitiveComponent OtherComp, int OtherBodyIndex, bool bFromSweep,
	                    const FHitResult&in SweepResult)
	{
		AHazePlayerCharacter Player = Cast<AHazePlayerCharacter>(OtherActor);
		if(Player != nullptr)
		{
			Player.ConsumeAirDashUsage();
			Player.ConsumeAirJumpUsage();
			Player.AddPlayerLaunchMovementImpulse(LaunchDirection.ForwardVector * ImpulseStrength);
			Player.BlockCapabilities(n"Dash",this);
			Player.BlockCapabilities(n"Jump",this);
		}
	}

	UFUNCTION()
	private void ExitLaunch(UPrimitiveComponent OverlappedComponent, AActor OtherActor,
	                        UPrimitiveComponent OtherComp, int OtherBodyIndex)
	{
			AHazePlayerCharacter Player = Cast<AHazePlayerCharacter>(OtherActor);
			if(Player != nullptr)
			{
				Player.UnblockCapabilities(n"Dash",this);
				Player.UnblockCapabilities(n"Jump",this);
			}
	}


};