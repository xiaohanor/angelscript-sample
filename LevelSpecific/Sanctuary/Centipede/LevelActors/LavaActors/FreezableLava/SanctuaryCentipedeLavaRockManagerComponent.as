namespace SanctuaryCentipedeLavaRock
{
	USanctuaryCentipedeLavaRockManagerComponent GetManager()
	{
		USanctuaryCentipedeLavaRockManagerComponent Manager = USanctuaryCentipedeLavaRockManagerComponent::Get(Game::Mio);
		return Manager;
	}
}

class USanctuaryCentipedeLavaRockManagerComponent : UActorComponent
{
	private TArray<ASanctuaryCentipedeFrozenLavaRock> InactiveRocks;
	private TArray<ASanctuaryCentipedeFrozenLavaRock> ActiveRocks;

	const TArray<ASanctuaryCentipedeFrozenLavaRock>& GetFrozenRocks() const
	{
		return ActiveRocks;
	}

	UPROPERTY(EditDefaultsOnly)
	float MinSpawnCooldown = 0.1;
	UPROPERTY(EditDefaultsOnly)
	float MaxSpawnCooldown = 0.2;

	private float SpawnCooldownTimestamp = 0.0;
	private int NetworkUniqueRockIdentifier = 0;

	private int TotalSpawnedRocks = 0;
	private int MaxSpawnedRocks = 100;
	private TArray<EObjectTypeQuery> TracingObjectTypes;

	UPROPERTY(EditDefaultsOnly)
	FSoundDefReference LavaRockManagerSoundDef;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		TracingObjectTypes.Add(EObjectTypeQuery::WorldDynamic);
		TracingObjectTypes.Add(EObjectTypeQuery::WorldStatic);

		LavaRockManagerSoundDef.SpawnSoundDefAttached(Game::GetMio());
	}

	void RequestSpawnRock(USanctuaryCentipedeLavaSplineSegmentComponent OptionalLavaSpline, TSubclassOf<ASanctuaryCentipedeFrozenLavaRock> LavaRockClass, FVector Location, FVector RandomLocationOffset, bool bRandomRotateAroundZ, float RockLifetime)
	{
		if (!HasControl())
			return;

		if (LavaRockClass == nullptr)
			return;

		if (SpawnCooldownTimestamp > Time::GameTimeSeconds)
			return;

		SpawnCooldownTimestamp = Time::GameTimeSeconds + Math::RandRange(MinSpawnCooldown, MaxSpawnCooldown);
		FVector FinalLocation = FindIshFreeSpot(Location);
		FinalLocation.X += Math::RandRange(-RandomLocationOffset.X, RandomLocationOffset.X);
		FinalLocation.Y += Math::RandRange(-RandomLocationOffset.Y, RandomLocationOffset.Y);
		FinalLocation.Z += Math::RandRange(-RandomLocationOffset.Z, RandomLocationOffset.Z);
		FRotator FinalRotation;
		if (bRandomRotateAroundZ)
			FinalRotation = FRotator::MakeFromEuler(FVector(0,0, Math::RandRange(-180, 180)));

		float RockStartScale = Math::RandRange(0.7, 0.8);
		float RockEndScale = Math::RandRange(0.9, 1.0);

		if (InactiveRocks.Num() > 0)
			CrumbActivateRock(OptionalLavaSpline, FinalLocation, FinalRotation, RockStartScale, RockEndScale, RockLifetime);
		else if (TotalSpawnedRocks < MaxSpawnedRocks)
			CrumbSpawnRock(OptionalLavaSpline, LavaRockClass, FinalLocation, FinalRotation, RockStartScale, RockEndScale, RockLifetime);
		
		// Start force recycle the ones which has lived longest, We're probably at river and not seeing it anyways
		if (ActiveRocks.Num() > MaxSpawnedRocks - 15)
		{
			float LongestLife = 0;
			ASanctuaryCentipedeFrozenLavaRock LongestLivedRock = nullptr;
			for (int i = 0; i < ActiveRocks.Num(); ++i)
			{
				if (!ActiveRocks[i].IsMelting() && ActiveRocks[i].ReturnToLavaTimer > LongestLife)
				{
					LongestLife = ActiveRocks[i].ReturnToLavaTimer;
					LongestLivedRock = ActiveRocks[i];
				}
			}
			if (LongestLivedRock != nullptr)
				LongestLivedRock.MeltNowPlz();
		}
	}

	UFUNCTION(CrumbFunction)
	private void CrumbSpawnRock(USanctuaryCentipedeLavaSplineSegmentComponent OptionalLavaSpline, TSubclassOf<ASanctuaryCentipedeFrozenLavaRock> LavaRockClass, FVector FinalLocation, FRotator FinalRotation, float RockStartScale, float RockEndScale, float RockLifetime)
	{
		ASanctuaryCentipedeFrozenLavaRock Rock = SpawnActor(LavaRockClass, FinalLocation, FinalRotation, FName(GetName() + "_LavaRock"), true);
		Rock.AddActorDisable(this);
		Rock.MakeNetworked(this, TotalSpawnedRocks);
		TotalSpawnedRocks++;
		FinishSpawningActor(Rock);
		InactiveRocks.Add(Rock);
		Rock.OnDestroyed.AddUFunction(this, n"HandleDestroyed");
		Rock.OnMeltedEvent.AddUFunction(this, n"HandleMelted");
		Rock.LavaRockComp.SetVisibility(false);
		ActivateRock(OptionalLavaSpline, FinalLocation, FinalRotation, RockStartScale, RockEndScale, RockLifetime);
	}

	UFUNCTION(CrumbFunction)
	private void CrumbActivateRock(USanctuaryCentipedeLavaSplineSegmentComponent OptionalLavaSpline, FVector FinalLocation, FRotator FinalRotation, float RockStartScale, float RockEndScale, float RockLifetime)
	{
		ActivateRock(OptionalLavaSpline, FinalLocation, FinalRotation, RockStartScale, RockEndScale, RockLifetime);
	}

	private void ActivateRock(USanctuaryCentipedeLavaSplineSegmentComponent OptionalLavaSpline, FVector FinalLocation, FRotator FinalRotation, float RockStartScale, float RockEndScale, float RockLifetime)
	{
		if (InactiveRocks.Num() > 0)
		{
			auto SpawnedRock = InactiveRocks[0];
			InactiveRocks.RemoveAt(0);
			ActiveRocks.Add(SpawnedRock);
			SpawnedRock.RemoveActorDisable(this);
			SpawnedRock.DetachRootComponentFromParent();
			SpawnedRock.SetActorLocation(FinalLocation);
			SpawnedRock.SetActorRotation(FinalRotation);
			SpawnedRock.Freeze(RockStartScale, RockEndScale, RockLifetime);
			if (OptionalLavaSpline != nullptr)
				OptionalLavaSpline.RegisterRock(SpawnedRock);
		}
	}

	private FVector FindIshFreeSpot(FVector DesiredLocation)
	{
		float NumDirections = 5;
		float Divisions = 360.0 / NumDirections;
		FVector NewLocation = DesiredLocation;
		int NumBlocks = 0;
		for (int i = 0; i < NumDirections; ++i)
		{
			FRotator AddedRot = FRotator::MakeFromEuler(FVector(0,0, Divisions * i));
			FHazeTraceSettings Tracey = Trace::InitObjectTypes(TracingObjectTypes);
			// Tracey.DebugDraw(3.0);
			FVector Offset = AddedRot.ForwardVector * 300.0;
			FHitResult Result = Tracey.QueryTraceSingle(DesiredLocation, DesiredLocation + Offset);
			if (Result.bBlockingHit)
			{
				ASanctuaryCentipedeFrozenLavaRock NearbyRock = Cast<ASanctuaryCentipedeFrozenLavaRock>(Result.Actor);
				if (NearbyRock != nullptr)
				{
					++NumBlocks;
					NewLocation -= Offset;
				}
			}
		}
		return NumBlocks == NumDirections ? DesiredLocation : NewLocation;
	}

	UFUNCTION()
	private void HandleDestroyed(AActor DestroyedActor)
	{
		if (!IsValid(this))
			return;
		ASanctuaryCentipedeFrozenLavaRock Rock = Cast<ASanctuaryCentipedeFrozenLavaRock>(DestroyedActor);
		if (Rock != nullptr && ActiveRocks.Contains(Rock))
			ActiveRocks.Remove(Rock);
		if (Rock != nullptr && InactiveRocks.Contains(Rock))
			InactiveRocks.Remove(Rock);
	}

	UFUNCTION()
	private void HandleMelted(ASanctuaryCentipedeFrozenLavaRock MoltenRock)
	{
		if (HasControl())
			CrumbInactivateRock(MoltenRock);
	}

	UFUNCTION(CrumbFunction)
	void CrumbInactivateRock(ASanctuaryCentipedeFrozenLavaRock MoltenRock)
	{
		if (ActiveRocks.Contains(MoltenRock))
			ActiveRocks.Remove(MoltenRock);
		if (!InactiveRocks.Contains(MoltenRock))
			InactiveRocks.Add(MoltenRock);
	}
}