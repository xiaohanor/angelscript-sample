
class UWingsuitBossStationKeepingMovementCapability : UHazeCapability
{
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;
	default TickGroup = EHazeTickGroup::BeforeMovement;
	default CapabilityTags.Add(CapabilityTags::Movement);	

	UWingsuitBossSettings Settings;
	AWingsuitBoss Boss;
	float WobbleTimer = 0.0;
	bool bKeepStationWithCart = false;

	ACoastTrainCart FollowCart;
	FVector TargetOffset;
	FHazeAcceleratedVector AccOffset;

	FHazeAcceleratedRotator AccRotation;

	UHazeCrumbSyncedVectorComponent CrumbSyncedLocation;
	UHazeCrumbSyncedRotatorComponent CrumbSyncedRotation;

	TPerPlayer<UCoastTrainRiderComponent> RiderComps;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Boss = Cast<AWingsuitBoss>(Owner);
		Settings = UWingsuitBossSettings::GetSettings(Owner);
		CrumbSyncedLocation = UHazeCrumbSyncedVectorComponent::Get(Owner);
		CrumbSyncedRotation = UHazeCrumbSyncedRotatorComponent::Get(Owner);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (Boss.TargetCart == nullptr)
			return false;
		if (Boss.bHasMovedThisFrame)
			return false;		
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (Boss.TargetCart == nullptr)
			return true;
		if (Boss.bHasMovedThisFrame)
			return true;		
		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		for (AHazePlayerCharacter Player : Game::Players)
		{
			RiderComps[Player] = UCoastTrainRiderComponent::Get(Player);
		}

		FollowCart = Boss.TargetCart;
		AccOffset.SnapTo(GetFollowTransform(FollowCart).InverseTransformPosition(Owner.ActorLocation));
		AccRotation.SnapTo(Owner.ActorRotation);
		Reposition();
		Boss.RepositionTimer = Settings.InitialRepositionDelay;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if (Boss.TargetCart == nullptr)
			return;

		if (HasControl())
		{
			FVector WantedOffset = TargetOffset;
			if (!bKeepStationWithCart)
			{
				FVector PlayerOffset = GetPlayerOffset();
				WantedOffset += PlayerOffset;
			}

			UpdateCartToFollow();

			// Reposition a while after being near wanted offset from cart
			if (AccOffset.Value.IsWithinDist(WantedOffset, Settings.StationKeepingRange))
				Boss.RepositionTimer -= DeltaTime;
			if ((Boss.RepositionTimer < SMALL_NUMBER) || (bKeepStationWithCart != Settings.bKeepStationWithCart))
				Reposition();

			// Slower acc when players are high up
			float PlayerHeight = Math::Min(Game::Mio.ActorLocation.Z, Game::Zoe.ActorLocation.Z) - FollowCart.ActorLocation.Z;
			float FlyingFactor = Math::GetMappedRangeValueClamped(FVector2D(1000.0, 3000.0), FVector2D(1.0, 0.1), PlayerHeight);

			// Position us relative to the players position along the target train cart
			FTransform CartPosition = GetFollowTransform(FollowCart);
			AccOffset.SpringTo(WantedOffset, Settings.StationKeepingMoveSpringStiffness * FlyingFactor, Settings.StationKeepingMoveSpringDamping, DeltaTime);
			FVector TargetLocation = CartPosition.TransformPosition(AccOffset.Value);

			// How do we want to rotate?
			FRotator TargetRotation = GetTargetRotation();

			// Wobble
			WobbleTimer += 2.0 * DeltaTime;
			TargetLocation.Z += 200.0 * Math::Sin(WobbleTimer);
			TargetLocation.Y += 200.0 * Math::Sin(WobbleTimer * 0.79);
			TargetRotation.Yaw += 10.0 * Math::Sin(WobbleTimer * 0.81);
			TargetRotation.Pitch += 10.0 * Math::Sin(WobbleTimer * 0.43 + 1.0);

			float Stiffness = Settings.StationKeepingRotationSpringStiffness;
			if(!Boss.OverrideRotationSpringStiffness.IsDefaultValue())
				Stiffness = Boss.OverrideRotationSpringStiffness.Get();

			AccRotation.SpringTo(TargetRotation, Stiffness, Settings.StationKeepingRotationSpringDamping, DeltaTime);

			CrumbSyncedLocation.Value = TargetLocation;
			CrumbSyncedRotation.Value = AccRotation.Value;
		}
		
		// Set position (this will be replicated values on remote)
		Owner.SetActorLocationAndRotation(CrumbSyncedLocation.Value, CrumbSyncedRotation.Value);
		Boss.bHasMovedThisFrame = true;
	}

	void Reposition()
	{
		if (!HasControl())
			return;

		// When flying over train with wingsuit we want to stay farther ahead
		float PlayerHeight = Math::Min(Game::Mio.ActorLocation.Z, Game::Zoe.ActorLocation.Z) - FollowCart.ActorLocation.Z;
		float FlyingFactor = Math::GetMappedRangeValueClamped(FVector2D(1000.0, 3000.0), FVector2D(1.0, 2.0), PlayerHeight);

		// Target offset is synced, but it's fine to have a desynced value for a little while at start
		FVector Offset;
		Offset.X = Math::RandRange(Settings.StationKeepingOffsetMin.X, Settings.StationKeepingOffsetMax.X) * FlyingFactor;
		Offset.Y = Math::RandRange(Settings.StationKeepingOffsetMin.Y, Settings.StationKeepingOffsetMax.Y);
		Offset.Z = Math::RandRange(Settings.StationKeepingOffsetMin.Z, Settings.StationKeepingOffsetMax.Z);
		CrumbSetTargetOffset(Offset, Settings.bKeepStationWithCart);
	}

	UFUNCTION(CrumbFunction)
	void CrumbSetTargetOffset(FVector Offset, bool _bKeepStationWithCart)
	{
		Boss.RepositionTimer = Settings.RepositionInterval;
		bKeepStationWithCart = _bKeepStationWithCart;
		TargetOffset = Offset;
	}

	FTransform GetFollowTransform(ACoastTrainCart Cart)
	{
		return Cart.MeshRootAbsoluteComp.WorldTransform;
	}

	void UpdateCartToFollow()
	{
		// Always follow a cart at or in front of foremost player (never move back)
		ACoastTrainCart ForemostCart = Boss.TargetCart;
		float ForemostDistance = Boss.TargetCart.SplineDistanceFromDriver;		
		for (AHazePlayerCharacter Player : Game::Players)
		{
			if (Player.IsPlayerDead())
				continue;
			if (!IsValid(RiderComps[Player].CurrentTrainCart))
				continue;
			float Distance = RiderComps[Player].DistanceToDriver;
			if (Distance > ForemostDistance)
				continue;
			ForemostDistance = Distance;
			ForemostCart = RiderComps[Player].CurrentTrainCart;
		}	

		if (HasControl() && (ForemostCart != Boss.TargetCart))
			CrumbSwitchFollowCart(ForemostCart); 

		if (Boss.TargetCart == FollowCart)
			return;

		// Rebase offset along new cart
		FTransform OldPosition = GetFollowTransform(FollowCart);
		FTransform NewPosition = GetFollowTransform(Boss.TargetCart);

		FVector WorldLoc = OldPosition.TransformPosition(AccOffset.Value);
		FVector NewOffset = NewPosition.InverseTransformPosition(WorldLoc);
		
		FVector WorldVelocity = OldPosition.TransformVector(AccOffset.Velocity);
		FVector NewVelocity = NewPosition.InverseTransformVector(WorldVelocity);

		AccOffset.SnapTo(NewOffset, NewVelocity);
		FollowCart = Boss.TargetCart;
	}

	FRotator GetTargetRotation()
	{
		if(!Boss.OverrideTargetRotation.IsDefaultValue())
			return Boss.OverrideTargetRotation.Get();

		FVector FocusOffset = FVector::ZeroVector;
		int NumValidTargets = 0;
		for (AHazePlayerCharacter Player : Game::Players)
		{
			if (Player.IsPlayerDead())
				continue;
			NumValidTargets++;
			FocusOffset += Player.ActorCenterLocation - Owner.ActorLocation;
		}
		if (NumValidTargets == 0)
			return Owner.ActorRotation;
		FocusOffset /= float(NumValidTargets);
		return FocusOffset.Rotation();
	}

	FVector GetPlayerOffset()
	{
		// Get forward offset of foremost player along the cart
		FTransform FollowTransform = GetFollowTransform(FollowCart);
		float Foremost = -BIG_NUMBER; 
		if (IsAnyPlayerOnTrain()) 
			Foremost = FollowCart.TrainInheritMovement.RelativeLocation.X - FollowCart.TrainInheritMovement.Shape.BoxExtents.X * 0.75; // Never move back more than end of cart
		int NumValidPlayers = 0;
		for (AHazePlayerCharacter Player : Game::Players)
		{
			if (Player.IsPlayerDead())
				continue;

			NumValidPlayers++;
			float Ahead = FollowTransform.InverseTransformPosition(Player.ActorLocation).X;
			if (Ahead > Foremost)
				Foremost = Ahead;
		}
		if (NumValidPlayers == 0)
			return FVector::ZeroVector;
		return FVector(Foremost, 0.0, 0.0);
	}

	bool IsAnyPlayerOnTrain()
	{
		for (AHazePlayerCharacter Player : Game::Players)
		{
			if (RiderComps[Player] == nullptr)
				continue;
			if (RiderComps[Player].CurrentTrainCart != nullptr)
				return true;
		}
		return false;
	}

	UFUNCTION(CrumbFunction)
	void CrumbSwitchFollowCart(ACoastTrainCart Cart)
	{
		Boss.TargetCart = Cart;
	}
};