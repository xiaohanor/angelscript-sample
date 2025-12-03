class ASummitCloud : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	UStaticMeshComponent Cloud;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent EndLoc;

	UPROPERTY(DefaultComponent)
	UHazeListedActorComponent ListedComponent;

	float StartSpeed = 5000.0;
	float Speed;
	bool bSendUp;

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		if (bSendUp)
		{
			Speed = Math::FInterpConstantTo(Speed, 0.0, DeltaSeconds, StartSpeed / 1.5);
			ActorLocation += FVector::UpVector * Speed * DeltaSeconds;
		}
	}

	void SendCloudUp()
	{
		if (bSendUp)
			return;

		Speed = StartSpeed;
		bSendUp = true;
	}
}