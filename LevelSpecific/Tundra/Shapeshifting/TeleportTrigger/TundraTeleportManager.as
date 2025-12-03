class ATundraTeleportManager : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent)
	UBillboardComponent Billboard;

	UPROPERTY(EditAnywhere)
	TArray<ARespawnPoint> TeleportPoints;

	UPROPERTY()
	ARespawnPoint MostRelevantTeleportPoint;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		float ClosestDistance = BIG_NUMBER;

		FVector ZoeLookPoint = Game::GetZoe().ActorLocation + Game::GetZoe().GetControlRotation().ForwardVector * 2600;

		for (int i = TeleportPoints.Num() - 1; i >= 0; i--)
		{
			float RespawnPointDistanceToZoe = TeleportPoints[i].ActorLocation.Distance(ZoeLookPoint);

			if (RespawnPointDistanceToZoe < ClosestDistance)
			{
				ClosestDistance = RespawnPointDistanceToZoe;
				MostRelevantTeleportPoint = TeleportPoints[i];
			}
		}

		// Debug::DrawDebugSphere(MostRelevantTeleportPoint.ActorLocation, 1500);
	}




	UFUNCTION()
	void SetNewTeleportPoint(ARespawnPoint Respawn)
	{

	}



};