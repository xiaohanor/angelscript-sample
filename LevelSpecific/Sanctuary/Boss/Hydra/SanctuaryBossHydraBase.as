struct FSanctuaryBossHydraPlayerData
{
	FVector Location = FVector::ZeroVector;
	FVector HorizontalDirection = FVector::ForwardVector;
	USceneComponent PlatformComponent = nullptr;
	float PlatformEnterTime = -1.0;
	float PlatformLeaveTime = -1.0;
}

class ASanctuaryBossHydraBase : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(NotVisible, BlueprintReadOnly, Category = "Hydra")
	TArray<ASanctuaryBossHydraHead> Heads;
	default Heads.SetNumZeroed(5);

	UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = "Hydra")
	bool bDisableRotation = false;

	UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = "Hydra")
	float SeperationDistance = 2500.0;

	FHazeAcceleratedQuat AcceleratedQuat;
	
	TArray<USanctuaryBossHydraAttackData> PendingAttacks;
	TPerPlayer<FSanctuaryBossHydraPlayerData> PlayerData;

	private const FName BaseDisableName = n"BaseDisabled";
	private int NetworkAttackIndex = 0; 

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		TArray<AActor> AttachedActors;
		GetAttachedActors(AttachedActors);

		for (auto Actor : AttachedActors)
		{
			auto Head = Cast<ASanctuaryBossHydraHead>(Actor);
			if (Head == nullptr)
				continue;

			int Index = int(Head.Identifier);
			if (!devEnsure(Heads[Index] == nullptr, f"Identifier \"{Head.Identifier}\" has already been assigned."))
				continue;

			Heads[Index] = Head;
		}

		// Deactivate by default, progress points sets the active base and activates
		Deactivate();
	}

	UFUNCTION(BlueprintCallable)
	void Activate()
	{
		if (!bDisableRotation)
		{
			FVector CenterLocation = (Game::Mio.ActorCenterLocation + Game::Zoe.ActorCenterLocation) / 2.0;
			FVector FacingDirection = (CenterLocation - ActorLocation).ConstrainToPlane(ActorUpVector).GetSafeNormal();
			AcceleratedQuat.SnapTo(FacingDirection.ToOrientationQuat());
			SetActorRotation(AcceleratedQuat.Value);
		}

		for (auto Head : Heads)
		{
			if (Head != nullptr && Head.IsActorDisabledBy(BaseDisableName))
				Head.RemoveActorDisable(BaseDisableName);
		}

		if (IsActorDisabledBy(BaseDisableName))
			RemoveActorDisable(BaseDisableName);
	}

	UFUNCTION(BlueprintCallable)
	void Deactivate()
	{
		for (auto Head : Heads)
		{
			if (Head != nullptr && !Head.IsActorDisabledBy(BaseDisableName))
				Head.AddActorDisable(BaseDisableName);
		}

		if (!IsActorDisabledBy(BaseDisableName))
			AddActorDisable(BaseDisableName);
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		UpdatePlayerData();
		UpdateHeadData();
		ProcessPendingAttacks();

		if (!bDisableRotation)
		{
			FVector CenterLocation = GetPlayersCenterLocation();
			FVector FacingDirection = (CenterLocation - ActorLocation).ConstrainToPlane(ActorUpVector).GetSafeNormal();
			AcceleratedQuat.AccelerateTo(FacingDirection.ToOrientationQuat(), 2.0, DeltaTime);
			SetActorRotation(AcceleratedQuat.Value);
		}
	}

	private void UpdatePlayerData()
	{
		for (auto Player : Game::Players)
		{
			auto& Data = PlayerData[Player];

			// Reset player platform data on death
			//  location is kept but isn't updated
			if (Player.IsPlayerDead())
			{
				Data.PlatformComponent = nullptr;
				Data.PlatformEnterTime = -1.0;
				Data.PlatformLeaveTime = -1.0;
				continue;
			}

			// Update platform movement is based on
			auto MoveComp = UPlayerMovementComponent::Get(Player);
			
			if (MoveComp.HasGroundContact())
			{
				auto PlatformActor = MoveComp.GroundContact.Actor;
				USceneComponent PlatformComponent = MoveComp.GroundContact.Component;

				if (PlatformActor != nullptr)
				{
					auto HydraPlatformComponent = USanctuaryBossHydraPlatformComponent::Get(PlatformActor);
					if (HydraPlatformComponent != nullptr)
						PlatformComponent = HydraPlatformComponent;
				}

				if (Data.PlatformComponent != PlatformComponent)
				{
					Data.PlatformComponent = PlatformComponent;
					Data.PlatformEnterTime = Time::GameTimeSeconds;
					Data.PlatformLeaveTime = -1.0;
				}
			}
			else
			{
				if (Data.PlatformComponent != nullptr && Data.PlatformLeaveTime < 0.0)
					Data.PlatformLeaveTime = Time::GameTimeSeconds;
			}

			// Update location and direction for both players
			Data.Location = Player.ActorCenterLocation;
			Data.HorizontalDirection = (Data.Location - ActorLocation).ConstrainToPlane(ActorUpVector).GetSafeNormal();
		}
	}

	private void UpdateHeadData()
	{
		FVector CenterLocation = GetPlayersCenterLocation();
		FVector FacingDirection = GetFacingDirection();

		// NOTE: Left and right may be the same, if either player is dead
		//  can also be null if both are dead
		AHazePlayerCharacter LeftPlayer = nullptr;
		AHazePlayerCharacter RightPlayer = nullptr;

		if (ArePlayersSeperated())
		{
			LeftPlayer = GetLeftPlayer(FacingDirection);
			RightPlayer = GetRightPlayer(FacingDirection);
		}

		for (int i = 0; i < Heads.Num(); ++i)
		{
			auto Head = Heads[i];
			if (Head == nullptr)
				continue;

			// Update location where the heads are looking depending on their
			//  identifiers and which player is left/right of base forward
			FVector TargetLocation = CenterLocation;

			if (Head.IsHeadLeft())
			{
				if (LeftPlayer != nullptr)
					TargetLocation = PlayerData[LeftPlayer].Location;
			}
			else if (Head.IsHeadRight())
			{
				if (RightPlayer != nullptr)
					TargetLocation = PlayerData[RightPlayer].Location;
			}

			Head.TargetLocation = TargetLocation;

			// Debug::DrawDebugLine(Head.HeadPivot.WorldLocation, Head.TargetLocation, Thickness = 5.0);
		}
	}

	private void ProcessPendingAttacks()
	{
		if (!HasControl())
			return;

		for (int i = PendingAttacks.Num() - 1; i >= 0; --i)
		{
			auto& PendingAttack = PendingAttacks[i];

			if (!PendingAttack.IsValid())
			{
				PendingAttacks.RemoveAt(i);
				continue;
			}

			ASanctuaryBossHydraHead AttackingHead = nullptr;

			// Identifier has been set; we want a specific head to perform this attack
			if (PendingAttack.Identifier != ESanctuaryBossHydraIdentifier::MAX)
			{
				AttackingHead = Heads[int(PendingAttack.Identifier)];

				if (AttackingHead == nullptr)
				{
					devError(f"Head with identifier \"{PendingAttack.Identifier}\" is not valid, has it been destroyed?");
				}
			}

			// If we failed to find by identifier, get closest head
			if (AttackingHead == nullptr)
			{
				float ClosestDistanceSqr = MAX_flt;
				ASanctuaryBossHydraHead ClosestHead = nullptr;
				for (auto Head : Heads)
				{
					if (Head == nullptr)
						continue;
					
					FVector ToPlatform = (Head.HeadPivot.WorldLocation - PendingAttack.WorldLocation);
					float DistanceSqr = ToPlatform.ConstrainToPlane(FVector::UpVector).SizeSquared();
					if (ClosestHead != nullptr && DistanceSqr >= ClosestDistanceSqr)
						continue;

					ClosestDistanceSqr = DistanceSqr;
					ClosestHead = Head;
				}

				AttackingHead = ClosestHead;
			}

			// Perform the attack if the selected head isn't busy
			if (AttackingHead != nullptr && !AttackingHead.HasAttackData())
			{
				CrumbAssignPendingAttack(AttackingHead, PendingAttacks[i]);
			}
		}
	}

	UFUNCTION(CrumbFunction)
	void CrumbAssignPendingAttack(ASanctuaryBossHydraHead Head, USanctuaryBossHydraAttackData AttackData)
	{
		if (Head == nullptr)
		{
			devError(f"Attempting to assign attack to an invalid hydra head.");
			return;
		}

		if (AttackData == nullptr)
		{
			devError(f"Attempting to assign an invalid attack to hydra head {Head.Identifier}.");
			return;
		}

		Head.AttackData = AttackData;
		PendingAttacks.Remove(AttackData);
	}

	/**
	 * Triggers a smash attack at the world location by hydra identifier.
	 * Setting target component will enable tracking, input location must remain world-space but will be made relative.
	 */
	UFUNCTION(BlueprintCallable)
	void TriggerSmash(FVector WorldLocation,
		USceneComponent TargetComponent = nullptr,
		USceneComponent TelegraphComponent = nullptr,
		float TelegraphDuration = -1.0,
		float RecoverDuration = -1.0,
		ESanctuaryBossHydraIdentifier Identifier = ESanctuaryBossHydraIdentifier::MAX)
	{
		if (!HasControl())
			return;

		CrumbTriggerSmash(
			WorldLocation,
			TargetComponent,
			TelegraphComponent,
			TelegraphDuration,
			RecoverDuration,
			Identifier
		);
	}
	
	UFUNCTION(CrumbFunction)
	void CrumbTriggerSmash(FVector WorldLocation,
		USceneComponent TargetComponent = nullptr,
		USceneComponent TelegraphComponent = nullptr,
		float TelegraphDuration = -1.0,
		float RecoverDuration = -1.0,
		ESanctuaryBossHydraIdentifier Identifier = ESanctuaryBossHydraIdentifier::MAX)
	{
		FVector Location = WorldLocation;
		if (TargetComponent != nullptr)
		{
			Location = TargetComponent	
				.WorldTransform
				.InverseTransformPosition(WorldLocation);
		}

		auto PointAttack = Cast<USanctuaryBossHydraPointAttackData>(
			NewObject(this, USanctuaryBossHydraPointAttackData, bTransient = true)
		);
		PointAttack.MakeNetworked(this, NetworkAttackIndex);
		NetworkAttackIndex++;
		PointAttack.AttackType = ESanctuaryBossHydraAttackType::Smash;
		PointAttack.Identifier = Identifier;
		PointAttack.TargetComponent = TargetComponent;
		PointAttack.Location = Location;
		PointAttack.TelegraphComponent = TelegraphComponent;
		PointAttack.TelegraphDuration = TelegraphDuration;
		PointAttack.RecoverDuration = RecoverDuration;
		PendingAttacks.Insert(PointAttack);
	}

	/**
	 * Triggers a sweeping fire breath attack by hydra identifier.
	 * Head moves along the first spline and directs the attack towards the target spline.
	 * If any duration is below zero, default settings are used.
	 */
	UFUNCTION(BlueprintCallable)
	void TriggerFireBreath(FHazeRuntimeSpline HeadSpline,
		FHazeRuntimeSpline TargetSpline,
		USceneComponent TargetComponent = nullptr,
		float SweepDuration = -1.0,
		float TelegraphDuration = -1.0,
		float RecoverDuration = -1.0,
		bool bInfiniteHeight = false,
		ESanctuaryBossHydraIdentifier Identifier = ESanctuaryBossHydraIdentifier::MAX)
	{
		if (!HasControl())
			return;

		CrumbTriggerFireBreath(
			HeadSpline,
			TargetSpline,
			TargetComponent,
			SweepDuration,
			TelegraphDuration,
			RecoverDuration,
			bInfiniteHeight,
			Identifier
		);
	}

	UFUNCTION(CrumbFunction)
	void CrumbTriggerFireBreath(FHazeRuntimeSpline HeadSpline,
		FHazeRuntimeSpline TargetSpline,
		USceneComponent TargetComponent = nullptr,
		float SweepDuration = -1.0,
		float TelegraphDuration = -1.0,
		float RecoverDuration = -1.0,
		bool bInfiniteHeight = false,
		ESanctuaryBossHydraIdentifier Identifier = ESanctuaryBossHydraIdentifier::MAX)
	{
		FHazeRuntimeSpline RelativeHeadSpline = HeadSpline;
		FHazeRuntimeSpline RelativeTargetSpline = TargetSpline;

		if (TargetComponent != nullptr)
		{
			MakeRuntimeSplineRelativeToComponent(RelativeHeadSpline, TargetComponent);
			MakeRuntimeSplineRelativeToComponent(RelativeTargetSpline, TargetComponent);
		}

		auto SweepAttack = Cast<USanctuaryBossHydraSweepAttackData>(
			NewObject(this, USanctuaryBossHydraSweepAttackData, bTransient = true)
		);
		SweepAttack.MakeNetworked(this, NetworkAttackIndex);
		NetworkAttackIndex++;
		SweepAttack.AttackType = ESanctuaryBossHydraAttackType::FireBreath;
		SweepAttack.Identifier = Identifier;
		SweepAttack.HeadSpline = RelativeHeadSpline;
		SweepAttack.TargetSpline = RelativeTargetSpline;
		SweepAttack.TargetComponent = TargetComponent;
		SweepAttack.SweepDuration = SweepDuration;
		SweepAttack.TelegraphDuration = TelegraphDuration;
		SweepAttack.RecoverDuration = RecoverDuration;
		SweepAttack.bInfiniteHeight = bInfiniteHeight;
		PendingAttacks.Insert(SweepAttack);
	}

	private void MakeRuntimeSplineRelativeToComponent(FHazeRuntimeSpline& Spline, USceneComponent Component)
	{
		TArray<FVector> Points = Spline.Points;
		for (int i = 0; i < Points.Num(); ++i)
			Points[i] = Component.WorldTransform.InverseTransformPosition(Points[i]);
		Spline.Points = Points;

		TArray<FVector> UpDirections = Spline.UpDirections;
		for (int i = 0; i < UpDirections.Num(); ++i)
			UpDirections[i] = Component.WorldTransform.InverseTransformVector(UpDirections[i]);
		Spline.UpDirections = UpDirections;
	}

	UFUNCTION(DevFunction, NotBlueprintCallable)
	void EnqueueSmash()
	{
		if (!HasControl())
			return;

		for (auto Player : Game::Players)
		{
			auto& Data = PlayerData[Player];
			if (Data.PlatformComponent == nullptr)
				continue;
			if (Player.IsPlayerDead())
				continue;

			auto TargetComponent = Data.PlatformComponent;
			CrumbTriggerSmash(TargetComponent.WorldLocation, TargetComponent);

			// Only perform attack from one head if the players are sharing platform
			if (ArePlayersSharingPlatform())
				break;
		}
	}

	UFUNCTION(DevFunction, NotBlueprintCallable)
	void EnqueueFireBreath()
	{
		if (!HasControl())
			return;

		for (auto Player : Game::Players)
		{
			auto& Data = PlayerData[Player];
			if (Data.PlatformComponent == nullptr)
				continue;
			if (Player.IsPlayerDead())
				continue;

			// This all just simulates what we did before using splines, since we don't have any splines
			//  available to us when using the dev function, testing use so don't matter how ugly it is :^)
			auto Head = Heads[0];

			auto TargetComponent = Data.PlatformComponent;
			FVector ToBase = (TargetComponent.WorldLocation - Head.BaseTransform.Location);
			FVector ToBaseConstrained = ToBase.ConstrainToPlane(FVector::UpVector).GetSafeNormal();

			float OffsetDistance = Head.HeadLength + 500.0;
			FVector HeadLocation = TargetComponent.WorldLocation - (ToBaseConstrained * OffsetDistance);

			float SweepAngle = 60.0;
			FVector LeftForward = ToBaseConstrained.RotateAngleAxis(-SweepAngle * 0.5, FVector::UpVector);
			FVector RightForward = ToBaseConstrained.RotateAngleAxis(SweepAngle * 0.5, FVector::UpVector);

			FHazeRuntimeSpline HeadSpline;
			HeadSpline.AddPoint(HeadLocation);

			FHazeRuntimeSpline TargetSpline;
			TargetSpline.AddPoint(HeadLocation + LeftForward * OffsetDistance);
			TargetSpline.AddPoint(HeadLocation + RightForward * OffsetDistance);

			CrumbTriggerFireBreath(HeadSpline, TargetSpline, TargetComponent, bInfiniteHeight = true);

			// Only perform attack from one head if the players are sharing platform
			if (ArePlayersSharingPlatform())
				break;
		}
	}

	UFUNCTION(BlueprintPure)
	FVector GetPlayersCenterLocation() const
	{
		const auto& MioData = PlayerData[Game::Mio];
		const auto& ZoeData = PlayerData[Game::Zoe];

		if (!Game::Mio.IsPlayerDead())
		{
			if (Game::Zoe.IsPlayerDead())
				return MioData.Location;
		}
		else
		{
			if (!Game::Zoe.IsPlayerDead())
				return ZoeData.Location;
		}

		return (MioData.Location + ZoeData.Location) / 2.0;
	}

	UFUNCTION(BlueprintPure)
	AHazePlayerCharacter GetLeftPlayer(FVector FacingDirection) const
	{
		if (!Game::Mio.IsPlayerDead())
		{
			if (Game::Zoe.IsPlayerDead())
				return Game::Mio;
		}
		else
		{
			if (!Game::Zoe.IsPlayerDead())
				return Game::Zoe;

			return nullptr;
		}

		const auto& MioData = PlayerData[Game::Mio];
		const auto& ZoeData = PlayerData[Game::Zoe];
		FVector ToMio = MioData.HorizontalDirection;
		FVector ToZoe = ZoeData.HorizontalDirection;

		if (ToMio.DotProduct(FacingDirection) < ToZoe.DotProduct(FacingDirection))
			return Game::Zoe;

		return Game::Mio;
	}

	UFUNCTION(BlueprintPure)
	AHazePlayerCharacter GetRightPlayer(FVector FacingDirection) const
	{
		if (!Game::Mio.IsPlayerDead())
		{
			if (Game::Zoe.IsPlayerDead())
				return Game::Mio;
		}
		else
		{
			if (!Game::Zoe.IsPlayerDead())
				return Game::Zoe;

			return nullptr;
		}

		const auto& MioData = PlayerData[Game::Mio];
		const auto& ZoeData = PlayerData[Game::Zoe];
		FVector ToMio = MioData.HorizontalDirection;
		FVector ToZoe = ZoeData.HorizontalDirection;

		if (ToMio.DotProduct(FacingDirection) < ToZoe.DotProduct(FacingDirection))
			return Game::Mio;

		return Game::Zoe;
	}

	UFUNCTION(BlueprintPure)
	USceneComponent GetPlayerPlatformComponent(AHazePlayerCharacter Player) const
	{
		auto& Data = PlayerData[Player];
		return Data.PlatformComponent;
	}

	UFUNCTION(BlueprintPure)
	AActor GetPlayerPlatformActor(AHazePlayerCharacter Player) const
	{
		auto& Data = PlayerData[Player];
		if (Data.PlatformComponent == nullptr)
			return nullptr;

		return Data.PlatformComponent.Owner;
	}

	FVector GetFacingDirection() const
	{
		FVector CenterLocation = GetPlayersCenterLocation();
		FVector FacingDirection = (CenterLocation - ActorLocation).ConstrainToPlane(ActorUpVector).GetSafeNormal();
		return FacingDirection;
	}

	UFUNCTION(BlueprintPure)
	bool ArePlayersSeperated()
	{
		const auto& MioData = PlayerData[Game::Mio];
		const auto& ZoeData = PlayerData[Game::Zoe];
		
		if (Game::Mio.IsPlayerDead())
			return true;
		if (Game::Zoe.IsPlayerDead())
			return true;
		if (MioData.Location.DistSquared(ZoeData.Location) > Math::Square(SeperationDistance))
			return true;

		return false;
	}

	UFUNCTION(BlueprintPure)
	bool ArePlayersSharingPlatform() const
	{
		const auto& MioData = PlayerData[Game::Mio];
		const auto& ZoeData = PlayerData[Game::Zoe];

		if (MioData.PlatformComponent == nullptr)
			return false;
		if (ZoeData.PlatformComponent == nullptr)
			return false;
		if (MioData.PlatformComponent.Owner != ZoeData.PlatformComponent.Owner)
			return false;

		return true;
	}

	UFUNCTION(BlueprintPure)
	bool HasPendingAttack() const
	{
		return PendingAttacks.Num() != 0;
	}
}