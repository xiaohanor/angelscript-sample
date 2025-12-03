struct FCrystalSpikeRuptureData
{
	ACrystalSpikeRupture Rupture;
	float DistanceAlongSpline;
}

class ACrystalSpikeRuptureManager : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

#if EDITOR
	UPROPERTY(DefaultComponent, Attach = Root)
	UBillboardComponent Visual;
	default Visual.SetWorldScale3D(FVector(4.0));
#endif

	UPROPERTY(EditAnywhere)
	ASplineActor PlayerFollowingSpline;

	UPROPERTY(EditAnywhere)
	float MaxRubberbandDistance = 1000.0;
	UPROPERTY(EditAnywhere)
	float MinRubberbandDistance = 200.0;
	UPROPERTY(EditAnywhere)
	float RuptureSplineTravelSpeed = 150.0;
	UPROPERTY(EditAnywhere)
	float StartingDistance = 0.0;
	float CurrentSplineDistance;

	TArray<ACrystalSpikeRupture> SpikeRuptures;
	TArray<FCrystalSpikeRuptureData> Ruptures;

	UPROPERTY(EditAnywhere)
	AStoneBeastPlayerSpline StoneBeastPlayerSpline;

	UPROPERTY(EditAnywhere)
	bool bCanKillPlayersBehindSpawnDistance = true;

	int Iteration = 0;

	float RuptureTime;

	float KillStuffTime = 0.0;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		SetActorTickEnabled(false);
	}

	UFUNCTION()
	void DisablePreviousRuptures()
	{
		for (ACrystalSpikeRupture Rupture : SpikeRuptures)
		{
			if (IsValid(Rupture) && !Rupture.bLeaveAfterManagerDisable)
				Rupture.AddActorDisable(this);
		}
	}

	void AddRuptureToDataSet(ACrystalSpikeRupture NewRupture)
	{
		if (PlayerFollowingSpline != nullptr)
		{
			FCrystalSpikeRuptureData NewData;
			NewData.Rupture = NewRupture;
			NewData.DistanceAlongSpline = PlayerFollowingSpline.Spline.GetClosestSplineDistanceToWorldLocation(NewRupture.ActorLocation);
			Ruptures.Add(NewData);
			SpikeRuptures.Add(NewRupture);
		}
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		if (Ruptures.Num() == 0)
			DeactivateRuptures();

		float Multiplier = 1.0;
		float MioSplineDistance = PlayerFollowingSpline.Spline.GetClosestSplineDistanceToWorldLocation(Game::Mio.ActorLocation);
		float ZoeSplineDistance = PlayerFollowingSpline.Spline.GetClosestSplineDistanceToWorldLocation(Game::Zoe.ActorLocation);

		if (PlayerFollowingSpline != nullptr && Ruptures.Num() > 0)
		{
			float SampleDistance;

			if (!Game::Mio.IsPlayerDead() && !Game::Zoe.IsPlayerDead())
				SampleDistance = (MioSplineDistance + ZoeSplineDistance) * 0.5;
			else if (!Game::Mio.IsPlayerDead())
				SampleDistance = MioSplineDistance;
			else if (!Game::Zoe.IsPlayerDead())
				SampleDistance = ZoeSplineDistance;
			else
				SampleDistance = PlayerFollowingSpline.Spline.GetClosestSplineDistanceToWorldLocation(Ruptures[Iteration].Rupture.ActorLocation);

			float DistanceDifference = SampleDistance - CurrentSplineDistance;
			DistanceDifference = Math::Clamp(DistanceDifference, MinRubberbandDistance, MaxRubberbandDistance);

			DistanceDifference -= MinRubberbandDistance;
			float Percent = DistanceDifference / (MaxRubberbandDistance - MinRubberbandDistance);
			PrintToScreen(f"{Percent=}");
			Multiplier = 0.2 + Math::Clamp(Percent, 0.0, 1.3);
			PrintToScreen(f"{Multiplier=}");
		}

		CurrentSplineDistance += RuptureSplineTravelSpeed * Multiplier * DeltaSeconds;
		if (StoneBeastPlayerSpline != nullptr)
			StoneBeastPlayerSpline.MinRespawnSplineDistance = StoneBeastPlayerSpline.Spline.GetClosestSplineDistanceToWorldLocation(PlayerFollowingSpline.Spline.GetWorldLocationAtSplineDistance(CurrentSplineDistance));

		TArray<FCrystalSpikeRuptureData> RupturesToRemove;

		for (FCrystalSpikeRuptureData& Data : Ruptures)
		{
			if (Data.DistanceAlongSpline < CurrentSplineDistance)
			{
				Data.Rupture.ActivateSpikeRupture();
				RupturesToRemove.Add(Data);
			}
		}

		for (FCrystalSpikeRuptureData Data : RupturesToRemove)
		{
			Ruptures.Remove(Data);
		}

		if (Time::GameTimeSeconds > KillStuffTime)
			KillStuffInSpikes(200.0, 2000.0, 3000.0);

		if (bCanKillPlayersBehindSpawnDistance)
		{
			if (MioSplineDistance < CurrentSplineDistance)
				Game::Mio.KillPlayer();

			if (ZoeSplineDistance < CurrentSplineDistance)
				Game::Zoe.KillPlayer();
		}
	}

	UFUNCTION()
	void ActivateRuptures()
	{
		SetActorTickEnabled(true);
		CurrentSplineDistance = StartingDistance;
	}

	UFUNCTION()
	void ActivateRupturesWithPlayerDistanceCheck(float OffsetBehind = 500.0)
	{
		FVector StartingPosition = Game::GetClosestPlayer(ActorLocation).ActorLocation;
		CurrentSplineDistance = PlayerFollowingSpline.Spline.GetClosestSplineDistanceToWorldLocation(StartingPosition);
		CurrentSplineDistance -= OffsetBehind;
		SetActorTickEnabled(true);
	}

	UFUNCTION()
	void SetRuptureEndStates()
	{
		for (FCrystalSpikeRuptureData& Data : Ruptures)
		{
			Data.Rupture.SetSpikeRuptureEndState();
		}
	}

	UFUNCTION()
	void SetNewSpeed(float NewSpeed)
	{
		RuptureSplineTravelSpeed = NewSpeed;
	}

	UFUNCTION()
	void DeactivateRuptures()
	{
		SetActorTickEnabled(false);
	}

	void KillStuffInSpikes(float KillEndDepth, float KillHeight, float KillWidth)
	{
		KillStuffTime = Time::GameTimeSeconds + 0.5;
		if (CurrentSplineDistance < KillEndDepth)
			return;
		TArray<AHazeActor> Victims;
		// Victims.Add(Game::Mio);
		// Victims.Add(Game::Zoe);
		UHazeTeam AITeam = HazeTeam::GetTeam(AITeams::Default);
		if (IsValid(AITeam))
			Victims.Append(AITeam.GetMembers());
		if (Victims.Num() == 0)
			return;
		FTransform KillzoneEndTransform = PlayerFollowingSpline.Spline.GetWorldTransformAtSplineDistance(CurrentSplineDistance - KillEndDepth);
		FTransform KillzoneStartTransform = PlayerFollowingSpline.Spline.GetWorldTransformAtSplineDistance(0.0);
		FVector KillzoneEndLoc = KillzoneEndTransform.Location;
		FVector KillzoneEndDir = KillzoneEndTransform.Rotation.ForwardVector;
		FVector KillzoneStartLoc = KillzoneStartTransform.Location;
		FVector KillzoneStartDir = KillzoneStartTransform.Rotation.ForwardVector;
		FVector KillzoneSide = KillzoneEndTransform.Rotation.RightVector;
		for (AHazeActor Victim : Victims)
		{
			if (Victim == nullptr)
				continue;
			FVector VictimLoc = Victim.ActorLocation;
			if (Math::Abs(KillzoneEndLoc.Z - VictimLoc.Z) > KillHeight)
				continue; // Too high or low
			if (KillzoneEndDir.DotProduct(VictimLoc - KillzoneEndLoc) > 0.0)
				continue; // After end
			if (KillzoneStartDir.DotProduct(VictimLoc - KillzoneStartLoc) < 0.0)
				continue; // Before start
			if (Math::Abs(KillzoneSide.DotProduct(VictimLoc - KillzoneEndLoc)) > KillWidth)
				continue; // Too far to the side
			USummitStoneBeastCritterCrystalSpikeResponseComponent CritterResponseComp = USummitStoneBeastCritterCrystalSpikeResponseComponent::Get(Victim);
			if (CritterResponseComp != nullptr)
			{
				// Critters die instantly.
				CritterResponseComp.OnHit.Broadcast(this);
			}
			else
			{
				// Handle other AIs
				UBasicAIHealthComponent HealthComp = UBasicAIHealthComponent::Get(Victim);
				if (HealthComp != nullptr)
				{
					HealthComp.TakeDamage(100.0, EDamageType::MeleeSharp, this);
				}
			}
			// else
			// {
			// 	AHazePlayerCharacter Player = Cast<AHazePlayerCharacter>(Victim);
			// 	if (Player != nullptr)
			// 		Player.DamagePlayerHealth(1.0);
			// }
		}
	}
};