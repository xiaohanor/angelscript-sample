class AMoonMarketBalloonCluster : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent)
	UBillboardComponent Billboard;

	UPROPERTY(EditInstanceOnly)
	TArray<AMoonMarketFollowBalloon> Balloons;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		for(auto Balloon : Balloons)
		{
			Balloon.String.SetAttachEndToComponent(Root, NAME_None);
			Balloon.String.EndLocation = FVector::ZeroVector;
			Balloon.String.bAttachEnd = true;
			Balloon.AutoGroundAttach = Root;
			Balloon.InteractComp.Disable(this);
		}
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		TArray<FPendingBalloonImpulse> PendingImpulses;

		for(int i = 0; i < Balloons.Num(); i++)
		{
			if(Balloons[i].bIsPopped)
				continue;

			const float RepulsionStrength = 250;
			const float Radius = Balloons[i].Collider.ScaledSphereRadius;
			
			const FVector Balloon1Center = Balloons[i].MeshComp.WorldLocation + Balloons[i].MeshComp.UpVector * Radius;

			FVector Impulse = FVector::ZeroVector;

			for(int j = 0; j < Balloons.Num(); j++)
			{
				if(i == j)
					continue;

				const FVector Balloon2Center = Balloons[j].MeshComp.WorldLocation + Balloons[j].MeshComp.UpVector * Radius;
				const float Dist = Balloon1Center.Distance(Balloon2Center);
				if(Dist > Radius * 2)
					continue;

				Impulse += (Balloons[i].MeshComp.WorldLocation - Balloons[j].MeshComp.WorldLocation).GetSafeNormal() * RepulsionStrength * DeltaSeconds;
			}

			PendingImpulses.Add(FPendingBalloonImpulse(i, Impulse));
		}

		for(int i = 0; i < PendingImpulses.Num(); i++)
		{
			Balloons[PendingImpulses[i].BalloonIndex].AddImpulse(PendingImpulses[i].Impulse);
		}
	}
};