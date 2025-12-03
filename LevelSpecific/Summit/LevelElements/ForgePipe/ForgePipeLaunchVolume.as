class AForgePipeLaunchVolume : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	UBoxComponent BoxComp;
	default BoxComp.SetCollisionResponseToAllChannels(ECollisionResponse::ECR_Ignore);
	default BoxComp.SetCollisionResponseToChannel(ECollisionChannel::PlayerCharacter, ECollisionResponse::ECR_Overlap);


	UPROPERTY(DefaultComponent, Attach = BoxComp)
	UArrowComponent ArrowComp;

	UPROPERTY(EditAnywhere)
	float LaunchForce = 5000.0;
	UPROPERTY(EditAnywhere)
	bool bAtStart = false;


	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		BoxComp.OnComponentBeginOverlap.AddUFunction(this, n"OnComponentBeginOverlap");

	}

	UFUNCTION()
	private void OnComponentBeginOverlap(UPrimitiveComponent OverlappedComponent, AActor OtherActor,
	                                     UPrimitiveComponent OtherComp, int OtherBodyIndex,
	                                     bool bFromSweep, const FHitResult&in SweepResult)
	{
		
		UForgePipePlayerLaunchComponent PlayerPipeComp = UForgePipePlayerLaunchComponent::Get(OtherActor);

		if(PlayerPipeComp != nullptr)
		{
			FVector Velocity;
			Velocity += ActorForwardVector * LaunchForce;

			PlayerPipeComp.SetLaunch(Velocity, bAtStart);
		}
	}
}