
class UTrainPlayerRespawnPointCapability : UHazePlayerCapability
{
	UCoastTrainRiderComponent RiderComp;
	UCoastTrainRiderComponent OtherPlayerRiderComp;
	UPlayerMovementComponent MoveComp;
	UPlayerHealthComponent HealthComp;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Player.ApplyRespawnPointOverrideDelegate(this, FOnRespawnOverride(this, n"OnPlayerPrepareRespawn"));
		RiderComp = UCoastTrainRiderComponent::GetOrCreate(Player);
		OtherPlayerRiderComp = UCoastTrainRiderComponent::GetOrCreate(Player.OtherPlayer);
		MoveComp = UPlayerMovementComponent::Get(Player);
	}

	UFUNCTION()
	private bool OnPlayerPrepareRespawn(AHazePlayerCharacter RespawnPlayer, FRespawnLocation& OutLocation)
	{
		if (!IsValid(RiderComp.ReachedTrainCart) || !IsValid(RiderComp.CurrentTrainCart))
			return false;
		if (!RiderComp.ReachedTrainCart.Driver.CanRespawnOnTrain())
			return false;

		FVector PlayerLastPosition = RiderComp.CurrentTrainCart.ActorTransform.TransformPosition(
			FVector(RiderComp.CurrentTrainCartPosition, 0.0, 0.0)
		);

		ARespawnPoint BestRespawn = nullptr;
		float FurthestRespawnDistance = MAX_flt;

		// Spawn at the respawn point that is the furthest that either play has reached
		for (ACoastTrainCart Cart : RiderComp.ReachedTrainCart.Driver.GetAllTrainCarts())
		{
			if (!IsValid(Cart))
				continue;
			if (Cart.SplineDistanceFromDriver < RiderComp.ReachedTrainCart.SplineDistanceFromDriver
				&& Cart.SplineDistanceFromDriver < OtherPlayerRiderComp.ReachedTrainCart.SplineDistanceFromDriver)
				continue;
			if (Cart.RespawnPoints.Num() == 0)
				continue;
			if (Cart.bCartDisconnected)
				continue;
			if (Cart.bCartDisabled)
				continue;

			FTransform CartTransform = Cart.ActorTransform;
			for (ACoastTrainRespawnPoint RespawnPoint : Cart.RespawnPoints)
			{
				if (!RespawnPoint.IsValidToRespawn(Player))
					continue;

				bool bReachedByMe = true;
				bool bReachedByOtherPlayer = true;

				FVector PositionOnCart = CartTransform.InverseTransformPosition(
					RespawnPoint.ActorLocation
				);
				if (Cart == RiderComp.ReachedTrainCart)
				{
					// Don't allow using respawn points we haven't actually reached yet
					if (PositionOnCart.X - RespawnPoint.ReachPointThreshold > RiderComp.ReachedTrainCartPosition)
						bReachedByMe = false;
				}

				if (Cart == OtherPlayerRiderComp.ReachedTrainCart)
				{
					// Don't allow using respawn points we haven't actually reached yet
					if (PositionOnCart.X - RespawnPoint.ReachPointThreshold > OtherPlayerRiderComp.ReachedTrainCartPosition)
						bReachedByOtherPlayer = false;
				}

				if (!bReachedByMe && !bReachedByOtherPlayer)
					continue;

				float DistanceFromFront = Cart.SplineDistanceFromDriver - PositionOnCart.X;
				if (BestRespawn == nullptr || DistanceFromFront < FurthestRespawnDistance)
				{
					FurthestRespawnDistance = DistanceFromFront;
					BestRespawn = RespawnPoint;
				}
			}
		}

		if (BestRespawn == nullptr)
		{
			// No respawn point is valid, spawn at the one furthest back
			FurthestRespawnDistance = 0.0;

			for (ACoastTrainCart Cart : RiderComp.ReachedTrainCart.Driver.GetAllTrainCarts())
			{
				if (Cart.RespawnPoints.Num() == 0)
					continue;
				if (Cart.bCartDisconnected)
					continue;
				if (Cart.bCartDisabled)
					continue;

				FTransform CartTransform = Cart.ActorTransform;
				for (ACoastTrainRespawnPoint RespawnPoint : Cart.RespawnPoints)
				{
					if (!RespawnPoint.IsValidToRespawn(Player))
						continue;

					float Distance = RespawnPoint.ActorLocation.Distance(RiderComp.ReachedTrainCart.Driver.ActorLocation);
					if (BestRespawn == nullptr || Distance > FurthestRespawnDistance)
					{
						FurthestRespawnDistance = Distance;
						BestRespawn = RespawnPoint;
					}
				}
			}
		}

		if (BestRespawn != nullptr)
		{
			OutLocation.RespawnPoint = BestRespawn;
			OutLocation.RespawnRelativeTo = BestRespawn.RootComponent;
			OutLocation.RespawnTransform = BestRespawn.GetRelativePositionForPlayer(Player);
			return true;
		}

		return false;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		return true;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		// Find the train cart we are currently on
		ACoastTrainCart FollowCart = nullptr;
		USceneComponent FollowComp = MoveComp.GetCurrentMovementReferenceFrameComponent();

		if (FollowComp != nullptr)
		{
			AActor AttachActor = FollowComp.Owner;
			while (AttachActor != nullptr)
			{
				auto Cart = Cast<ACoastTrainCart>(AttachActor);
				if (Cart != nullptr)
				{
					FollowCart = Cart;
					break;
				}
				AttachActor = AttachActor.GetAttachParentActor();
			}
		}

		// Did our train get disabled or streamed out?
		if (!IsValid(FollowCart) || !IsValid(FollowCart.Driver) || !FollowCart.Driver.CanRespawnOnTrain())
			FollowCart = nullptr;
		if (!IsValid(RiderComp.CurrentTrainCart) || !IsValid(RiderComp.CurrentTrainCart.Driver) || !RiderComp.CurrentTrainCart.Driver.CanRespawnOnTrain())
			RiderComp.CurrentTrainCart = nullptr;
		if (!IsValid(RiderComp.ReachedTrainCart) || !IsValid(RiderComp.ReachedTrainCart.Driver) || !RiderComp.ReachedTrainCart.Driver.CanRespawnOnTrain())
			RiderComp.ReachedTrainCart = nullptr;

		if (FollowCart != nullptr)
		{
			// Find the position on the cart the player is currently
			FVector PositionOnCart = FollowCart.ActorTransform.InverseTransformPosition(Player.ActorLocation);

			// We don't update checkpoints if we've fallen below the train
			if (PositionOnCart.Z >= -10.0)
			{
				RiderComp.CurrentTrainCart = FollowCart;
				RiderComp.CurrentTrainCartPosition = PositionOnCart.X;
				
				// Did we switch to a different train?
				if (RiderComp.ReachedTrainCart != nullptr)
				{
					if (RiderComp.ReachedTrainCart == RiderComp.CurrentTrainCart)
					{
						RiderComp.ReachedTrainCartPosition = Math::Max(PositionOnCart.X, RiderComp.ReachedTrainCartPosition);
					}
					else if (RiderComp.ReachedTrainCart.Driver != RiderComp.CurrentTrainCart.Driver
						|| RiderComp.ReachedTrainCart.SplineDistanceFromDriver > RiderComp.CurrentTrainCart.SplineDistanceFromDriver)
					{
						RiderComp.ReachedTrainCart = RiderComp.CurrentTrainCart;
						RiderComp.ReachedTrainCartPosition = PositionOnCart.X;
					}
				}
				else
				{
					RiderComp.ReachedTrainCart = RiderComp.CurrentTrainCart;
					RiderComp.ReachedTrainCartPosition = PositionOnCart.X;
				}
			}
		}
	}
};