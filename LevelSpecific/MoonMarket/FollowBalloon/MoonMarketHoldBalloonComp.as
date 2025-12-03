struct FPendingBalloonImpulse
{
	int BalloonIndex;
	FVector Impulse;

	FPendingBalloonImpulse(int Index, FVector AnImpulse)
	{
		BalloonIndex = Index;
		Impulse = AnImpulse;
	}
}

class UMoonMarketHoldBalloonComp : UActorComponent
{
	UPROPERTY()
	FRuntimeFloatCurve BalloonLiftStrengthCurve;

	const int BalloonsRequiredToStartLifting = 6;

	TArray<AMoonMarketFollowBalloon> CurrentlyHeldBalloons;
	AHazePlayerCharacter Player;


	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Player = Cast<AHazePlayerCharacter>(Owner);
	}

	void AddBalloon(AMoonMarketFollowBalloon Balloon)
	{
		CurrentlyHeldBalloons.Add(Balloon);
	}

	void ReleaseBalloon(AMoonMarketFollowBalloon Balloon)
	{
		Balloon.Release();
		CurrentlyHeldBalloons.Remove(Balloon);
	}

	void ReleaseBalloon()
	{
		CurrentlyHeldBalloons.Last().Release();
		CurrentlyHeldBalloons.RemoveAt(CurrentlyHeldBalloons.Num() - 1);
	}

	void ReleaseAllBalloons()
	{
		for(int i = CurrentlyHeldBalloons.Num() -1; i >= 0; i--)
		{
			CurrentlyHeldBalloons[i].Release();
			CurrentlyHeldBalloons[i].StopInteraction(Player);
		}

		CurrentlyHeldBalloons.Empty();
	}

	void StealOtherPlayerBalloons(UMoonMarketHoldBalloonComp OtherPlayerBalloonComp)
	{
		TArray<AMoonMarketFollowBalloon> Balloons = OtherPlayerBalloonComp.CurrentlyHeldBalloons;
		OtherPlayerBalloonComp.ReleaseAllBalloons();

		for(auto Balloon : Balloons)
		{
			Balloon.OnInteractionStarted(UInteractionComponent::Get(Player), Player);
		}
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		if(CurrentlyHeldBalloons.Num() > 1)
			ApplyForcesToBalloons(DeltaSeconds);
	}

	void PopAllBalloons()
	{
		for(int i = 0; i < CurrentlyHeldBalloons.Num(); i++)
		{
			CurrentlyHeldBalloons[i].Pop(Player);
		}

		CurrentlyHeldBalloons.Empty();
	}

	void ApplyForcesToBalloons(float DeltaTime)
	{
		TArray<FPendingBalloonImpulse> PendingImpulses;

		for(int i = 0; i < CurrentlyHeldBalloons.Num(); i++)
		{
			const float RepulsionStrength = 250;
			const float Radius = CurrentlyHeldBalloons[i].Collider.ScaledSphereRadius;
			
			const FVector Balloon1Center = CurrentlyHeldBalloons[i].MeshComp.WorldLocation + CurrentlyHeldBalloons[i].MeshComp.UpVector * Radius;

			FVector Impulse = FVector::ZeroVector;

			for(int j = 0; j < CurrentlyHeldBalloons.Num(); j++)
			{
				if(i == j)
					continue;

				const FVector Balloon2Center = CurrentlyHeldBalloons[j].MeshComp.WorldLocation + CurrentlyHeldBalloons[j].MeshComp.UpVector * Radius;
				const float Dist = Balloon1Center.Distance(Balloon2Center);
				if(Dist > Radius * 2)
					continue;

				Impulse += (CurrentlyHeldBalloons[i].MeshComp.WorldLocation - CurrentlyHeldBalloons[j].MeshComp.WorldLocation).GetSafeNormal() * RepulsionStrength * DeltaTime;
			}

			PendingImpulses.Add(FPendingBalloonImpulse(i, Impulse));
		}

		for(int i = 0; i < PendingImpulses.Num(); i++)
		{
			CurrentlyHeldBalloons[PendingImpulses[i].BalloonIndex].AddImpulse(PendingImpulses[i].Impulse);
		}
	}
};