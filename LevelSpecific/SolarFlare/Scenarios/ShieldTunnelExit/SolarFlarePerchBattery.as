class ASolarFlarePerchBattery : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent MeshRoot;

	UPROPERTY(EditAnywhere)
	APerchPointActor ActivePerchPoint;

	UPROPERTY(EditAnywhere)
	FVector TargetOffset = FVector(0.0, 0.0, -300.0);

	private FVector StartLoc;
	private float InterpSpeedDown = 350.0;
	private float InterpSpeedUp = 650.0;
	private bool bPlayerOnPerch;

	AHazePlayerCharacter ActivePlayer;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		StartLoc = ActorLocation;
		ActivePerchPoint.OnPlayerStartedPerchingEvent.AddUFunction(this, n"OnPlayerStartedPerchingEvent");
		ActivePerchPoint.OnPlayerStoppedPerchingEvent.AddUFunction(this, n"OnPlayerStoppedPerchingEvent");
		ActivePerchPoint.AttachToComponent(MeshRoot, NAME_None, EAttachmentRule::KeepWorld);
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		if (bPlayerOnPerch)
		{
			ActorLocation = Math::VInterpConstantTo(ActorLocation, StartLoc + TargetOffset, DeltaSeconds, InterpSpeedDown);
		}
		else
		{
			ActorLocation = Math::VInterpConstantTo(ActorLocation, StartLoc, DeltaSeconds, InterpSpeedUp);
		}
	}

	UFUNCTION()
	private void OnPlayerStartedPerchingEvent(AHazePlayerCharacter Player,
	                                          UPerchPointComponent PerchPoint)
	{
		ActivePlayer = Player;
		bPlayerOnPerch = true;
		PerchPoint.DisableForPlayer(Player.OtherPlayer, this);
	}

	UFUNCTION()
	private void OnPlayerStoppedPerchingEvent(AHazePlayerCharacter Player,
	                                          UPerchPointComponent PerchPoint)
	{
		bPlayerOnPerch = false;
		PerchPoint.EnableForPlayer(Player.OtherPlayer, this);
	}

	bool BatteryActivated()
	{
		return bPlayerOnPerch;
	}
}