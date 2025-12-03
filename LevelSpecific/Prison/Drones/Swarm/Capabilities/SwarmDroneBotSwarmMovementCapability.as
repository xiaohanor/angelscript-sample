class USwarmMovementBotInstance : UObject
{
	UPROPERTY()
	ASwarmBot Bot = nullptr;

	UPROPERTY()
	TArray<USwarmMovementBotInstance> Constraints;

	FVector PreviousLocation = FVector::ZeroVector;

	USwarmMovementBotInstance(ASwarmBot SwarmBot)
	{
		Bot = SwarmBot;
	}
}

class USwarmDroneBotSwarmMovementCapability : UHazePlayerCapability
{
	default TickGroup = EHazeTickGroup::LastMovement;

	UPlayerSwarmDroneComponent SwarmDroneComponent;

	UPROPERTY(Transient)
	TArray<USwarmMovementBotInstance> Bots;

	const int Rings = 3;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		SwarmDroneComponent = UPlayerSwarmDroneComponent::Get(Owner);
		SwarmDroneComponent.OnSwarmDronePossessed.AddUFunction(this, n"OnSwarmDronePossessed");
	}

	void Initialize()
	{
		Bots.Add(USwarmMovementBotInstance(SwarmDroneComponent.SwarmBots[0]));

		// Create bots
		{
			int CurrentRingSize = 3;
			int Offset = 1;

			for (int Ring = 1; Ring <= Rings; Ring++)
			{
				for (int i = 0; i < CurrentRingSize; i++)
				{
					int BotIndex = i + Offset;
					USwarmMovementBotInstance Bot = USwarmMovementBotInstance(SwarmDroneComponent.SwarmBots[BotIndex]);

					// Add to array
					Bots.Add(Bot);
				}

				Offset += CurrentRingSize;
				CurrentRingSize *= 2;
			}
		}

		// Create constraints
		{
			int CurrentRingSize = 3;
			int Offset = 1;

			for (int Ring = 1; Ring <= Rings; Ring++)
			{
				for (int i = 0; i < CurrentRingSize; i++)
				{
					int BotIndex = i + Offset;
					USwarmMovementBotInstance Bot = Bots[BotIndex];

					// Immediate neighbors
					{
						int PreviousNeighborIndex = Math::WrapIndex(i - 1, 0, CurrentRingSize) + Offset;
						int NextNeighborIndex = Math::WrapIndex(i + 1, 0, CurrentRingSize) + Offset;

						auto PreviousBot = Bots[PreviousNeighborIndex];
						// if (!PreviousBot.Constraints.Contains(Bot))
							Bot.Constraints.AddUnique(PreviousBot);

						auto NextBot = Bots[NextNeighborIndex];
						// if (!NextBot.Constraints.Contains(Bot))
							Bot.Constraints.AddUnique(NextBot);

						// Add special constraint with player
						if (Ring == 1)
						{
							// Bots[0].Constraints.AddUnique(Bot);
							Bot.Constraints.AddUnique(Bots[0]);
						}
					}

					// Ring neighbors
					{
						if (Ring == Rings)
							continue;

						int SuperOffset = Offset + CurrentRingSize;
						int SuperRingSize = CurrentRingSize * 2;

						// int Min = CurrentRingSize + 1;
						int Min = SuperRingSize - 2;
						int Max = SuperRingSize + CurrentRingSize + Offset;

						int SuperNeighborIndex = BotIndex + Rings * Ring + i;
						int PreviousSuperNeighborIndex = Math::WrapIndex(SuperNeighborIndex - 1, Min, Max);
						int NextSuperNeighborIndex = Math::WrapIndex(SuperNeighborIndex + 1, Min, Max);

						auto SuperBot = Bots[SuperNeighborIndex];
						// if (!SuperBot.Constraints.Contains(Bot))
							Bot.Constraints.AddUnique(SuperBot);

						auto PreviousBot = Bots[PreviousSuperNeighborIndex];
						// if (!PreviousBot.Constraints.Contains(Bot))
							Bot.Constraints.AddUnique(PreviousBot);

						auto NextBot = Bots[NextSuperNeighborIndex];
						// if (!NextBot.Constraints.Contains(Bot))
							Bot.Constraints.AddUnique(NextBot);
					}
				}

				Offset += CurrentRingSize;
				CurrentRingSize *= 2;
			}
		}
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (!SwarmDroneComponent.bSwarmModeActive)
			return false;

		if (!IsInitialized())
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (!SwarmDroneComponent.bSwarmModeActive)
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		auto MasterBot = Bots[0];
		MasterBot.Bot.SetActorLocation(Player.ActorLocation - FVector::UpVector * Bots[0].Bot.Collider.BoundsRadius * 1.5);
		MasterBot.Bot.SetActorRotation(Player.ActorRotation);

		for (int i = 0; i < 5; i++)
		{
			TickMovement(DeltaTime);

			TickConstraints();

			TickCollisions();
		}
	}

	void TickMovement(float DeltaTime)
	{
		FVector Gravity = -FVector::UpVector * Drone::Gravity;

		for (auto Bot : Bots)
		{
			if (Bot.Bot.Id == 0)
				continue;

			FVector MoveDelta = (Bot.Bot.ActorLocation - Bot.PreviousLocation);
			MoveDelta += Gravity * DeltaTime;
			Bot.PreviousLocation = Bot.Bot.ActorLocation;

			// Add friction
			MoveDelta -= MoveDelta * 0.98;

			FVector NextLocation = Bot.Bot.ActorLocation + MoveDelta;
			Bot.Bot.SetActorLocation(NextLocation);
		}
	}

	void TickConstraints()
	{
		for (auto Bot : Bots)
		{
			if (Bot.Bot.Id == 0)
				continue;

			for (auto Constraint : Bot.Constraints)
			{
				float Length = Bot.Bot.Collider.SphereRadius * 3;
				float Distance = Math::Max(Bot.Bot.ActorLocation.Distance(Constraint.Bot.ActorLocation), 0.016);
				float Delta = Length - Distance;
				float Multiplier = (Delta / Distance) * 0.5;

				FVector BotToOtherBot = Constraint.Bot.ActorLocation - Bot.Bot.ActorLocation;
				BotToOtherBot = BotToOtherBot.ConstrainToPlane(FVector::UpVector);

				if (Constraint.Bot.Id == 0)
				{
					Bot.Bot.AddActorWorldOffset(-BotToOtherBot * Multiplier * 3);
					Bot.Bot.SetActorRotation(BotToOtherBot.ToOrientationQuat());
				}
				else
				{
					Bot.Bot.AddActorWorldOffset(-BotToOtherBot * Multiplier);
					Constraint.Bot.AddActorWorldOffset(BotToOtherBot * Multiplier);

					Bot.Bot.SetActorRotation(BotToOtherBot.ToOrientationQuat());
				}
			}
		}
	}

	void TickCollisions()
	{
		for (auto Bot : Bots)
		{
			if (Bot.Bot.Id == 0)
				continue;

			FHazeTraceSettings Trace = Trace::InitFromPrimitiveComponent(Bot.Bot.Collider);

			FVector Offset;

			FOverlapResultArray Overlaps = Trace.QueryOverlaps(Bot.Bot.ActorLocation);
			for (auto Overlap : Overlaps)
			{
				// if (!Overlap.Actor.IsA(ASwarmBot))
					Offset += Overlap.GetDepenetrationDelta(Trace.Shape, Bot.Bot.ActorLocation) * 0.3;
			}

			Bot.Bot.AddActorWorldOffset(Offset);
		}
	}

	UFUNCTION(NotBlueprintCallable)
	void OnSwarmDronePossessed()
	{
		if (!IsInitialized())
			Initialize();
	}

	bool IsInitialized() const
	{
		return !Bots.IsEmpty();
	}
}