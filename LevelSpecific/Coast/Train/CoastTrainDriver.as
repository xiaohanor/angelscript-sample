delegate void FOnTrainFinishedParkingDelegate();
event void FOnPlayerLandedOnTrain(AHazePlayerCharacter Player);

struct FCoastTrainCartInfo
{
	UPROPERTY(Category = Train, EditInstanceOnly)
	float DistanceFromCartInFront = 1000.0;

	UPROPERTY(Category = Train, EditInstanceOnly)
	ACoastTrainCart Cart;
};

struct FCoastTrainParkRequest
{
	FSplinePosition ParkPosition;
	bool bReached = false;
	bool bResumed = false;
	FInstigator Instigator;
	FOnTrainFinishedParkingDelegate Delegate;
};

struct FCoastTrainRubberBanding
{
	FInstigator Instigator;
	float TargetSplineDistanceBehindDriver;
	float TargetTolerance;
	float DistanceForMinimumSpeed;
	float DistanceForMaximumSpeed;
	float MinimumSlowdownMultiplier;
	float MaximumSpeedupMultiplier;
};

struct FCoastTrainSpinRegion
{
	bool bHasEnded = false;
	bool bSpinToTarget = false;
	FSplinePosition StartPosition;
	FSplinePosition EndPosition;
	float SpinSpeed = 0.0;
	float SpinTarget = 0.0;
}

namespace CoastTrain
{
	ACoastTrainDriver GetMainTrainDriver()
	{
		TListedActors<ACoastTrainDriver> ListedDrivers;
		for(ACoastTrainDriver Driver : ListedDrivers.Array)
		{
			if(Driver.bIsMainDriver)
				return Driver;
		}
	
		return nullptr;
	}
}


UCLASS(Meta = (HideCategories = "LOD Physics AssetUserData Collision Tags Cooking Activation Rendering"))
class ACoastTrainDriver : ACoastTrainCart
{
	UPROPERTY(DefaultComponent)
	UCoastTrainDriverDummyComponent Dummy;

	UPROPERTY(DefaultComponent)
	UHazeCrumbSyncedActorPositionComponent CrumbPosition;
	default CrumbPosition.SyncRate = EHazeCrumbSyncRate::PlayerSynced;
	default CrumbPosition.SyncDetailLevel = EHazeActorPositionSyncDetailLevel::Player;

	UPROPERTY(DefaultComponent)
	UHazeCapabilityComponent CapabilityComp;
	default CapabilityComp.DefaultCapabilities.Add(n"CoastTrainDriverMovementCapability");

	UPROPERTY(DefaultComponent)
	UHazeRequestCapabilityOnPlayerComponent RequestComp;
	default RequestComp.PlayerCapabilities.Add(n"TrainPlayerLaunchOffCapability");
	default RequestComp.PlayerCapabilities.Add(n"TrainPlayerLaunchOffMarkerCapability");
	default RequestComp.PlayerCapabilities.Add(n"TrainPlayerRespawnPointCapability");

	UPROPERTY(DefaultComponent)
	UDisableComponent DisableComp;
	default DisableComp.bStartDisabled = true;

	UPROPERTY(DefaultComponent)
	UHazeListedActorComponent ListedComponent;

	UPROPERTY(Category = Driver, EditInstanceOnly, BlueprintReadOnly)
	TArray<FCoastTrainCartInfo> Carts;

	UPROPERTY(Category = Driver, EditInstanceOnly, BlueprintReadOnly)
	bool bIsMainDriver = false;

	access CoastTrainInternal = private, UCoastTrainDriverMovementCapability;

	UPROPERTY(Category = Driver, EditAnywhere, BlueprintReadOnly)
	access:CoastTrainInternal
	float Speed = 1500.0;

	// Acceleration the train uses when it changes speed (rubberbanding, parking, etc)
	UPROPERTY(Category = Driver, EditAnywhere, BlueprintReadOnly)
	access:CoastTrainInternal
	float Acceleration = 5000.0;

	// If set, the train will sway back and forth going slower and faster with this distance
	UPROPERTY(Category = Driver, EditAnywhere, BlueprintReadOnly)
	float ForwardMovementCurveMagnitude = 0.0;

	// The period of the forward movement curve, how many seconds it takes to sway back and forth
	UPROPERTY(Category = Driver, EditAnywhere, BlueprintReadOnly)
	float ForwardMovementCurvePeriod = 1.0;

	UPROPERTY()
	FOnPlayerLandedOnTrain OnPlayerLandedOnTrain;

	access:CoastTrainInternal
	TInstigated<float> TrainMovementSpeed;

	private TArray<FCoastTrainParkRequest> ParkRequests;
	private TArray<FCoastTrainRubberBanding> RubberBanding;
	private TInstigated<float> InstigatedKillPlayersBelowTrain;
	private TArray<FInstigator> RespawnDisableInstigators;
	private TPerPlayer<bool> HasPlayerLandedOnTrain;
	
	TArray<FCoastTrainSpinRegion> ActiveSpins;

	access:CoastTrainInternal
	float ForwardCurveTimer = 0.0;

	access:CoastTrainInternal
	float ForwardCurveCurrent = 0.0;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Super::BeginPlay();

		CurrentPosition = FindClosestSplinePosition();
		TrainMovementSpeed.SetDefaultValue(Speed);

		Driver = this;
		SplineDistanceFromDriver = 0.0;

		FSplinePosition ChildPosition = CurrentPosition;
		float Distance = 0.0;

		ACoastTrainCart CurCart = this;

		for (auto CartInfo : Carts)
		{
			Distance += CartInfo.DistanceFromCartInFront;
			if (CartInfo.Cart != nullptr)
			{
				CartInfo.Cart.Driver = this;
				CartInfo.Cart.SplineDistanceFromDriver = Distance;

				ChildPosition.Move(-CartInfo.DistanceFromCartInFront);
				CartInfo.Cart.CurrentPosition = ChildPosition;

				if (CurCart != nullptr)
				{
					CurCart.NextCart = CartInfo.Cart;
					CurCart = CartInfo.Cart;
				}
			}
		}

		for (AHazePlayerCharacter Player : Game::Players)
		{
			UCoastTrainRiderComponent TrainRiderComp = UCoastTrainRiderComponent::GetOrCreate(Player);
			TrainRiderComp.Register(this);
		}
	}

	UFUNCTION(BlueprintOverride)
	void EndPlay(EEndPlayReason EndPlayReason)
	{
		for (AHazePlayerCharacter Player : Game::Players)
		{
			UCoastTrainRiderComponent TrainRiderComp = UCoastTrainRiderComponent::GetOrCreate(Player);
			TrainRiderComp.Unregister(this);
		}
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		Super::Tick(DeltaSeconds);
		
		for(AHazePlayerCharacter Player : Game::Players)
		{
			if(HasPlayerLandedOnTrain[Player])
				continue;

			if(IsPlayerOnTrain(Player))
			{
				OnPlayerLandedOnTrain.Broadcast(Player);
				HasPlayerLandedOnTrain[Player] = true;
			}
		}
	}

	UFUNCTION(BlueprintCallable)
	UCoastTrainInheritMovementComponent GetClosestInheritMovementComponentToPoint(FVector Point) const
	{
		float ClosestSqrDistance = MAX_flt;
		FCoastTrainCartInfo ClosestCart;
		for(auto Cart : Carts)
		{
			float SqrDist = Cart.Cart.ActorLocation.DistSquared(Point);
			if(SqrDist < ClosestSqrDistance)
			{
				ClosestSqrDistance = SqrDist;
				ClosestCart = Cart;
			}
		}

		devCheck(ClosestCart.Cart != nullptr, "Tried to get closest cart");
		return ClosestCart.Cart.TrainInheritMovement;
	}

	/**
	 * Enable automatically killing players that are this far below the train.
	 */
	UFUNCTION(Category = "Coast Train")
	void EnableKillPlayersBelowTrain(FInstigator Instigator, float HeightBelowTrain = 500.0)
	{
		InstigatedKillPlayersBelowTrain.Apply(HeightBelowTrain, Instigator);
	}

	/**
	 * Disable a previous automatic player kill height.
	 */
	UFUNCTION(Category = "Coast Train")
	void DisableKillPlayersBelowTrain(FInstigator Instigator)
	{
		InstigatedKillPlayersBelowTrain.Clear(Instigator);
	}

	bool ShouldKillPlayerFallingOffTrain() const
	{
		return !InstigatedKillPlayersBelowTrain.IsDefaultValue();
	}

	float GetKillPlayerBelowTrainHeight() const property
	{
		return InstigatedKillPlayersBelowTrain.Get();
	}

	UFUNCTION()
	float GetTrainSpeed() const
	{
		return TrainMovementSpeed.Get();
	}

	UFUNCTION(Category = "Coast Train")
	void DisableRespawnOnTrain(FInstigator Instigator)
	{
		RespawnDisableInstigators.Add(Instigator);
	}

	UFUNCTION(Category = "Coast Train")
	void EnableRespawnOnTrain(FInstigator Instigator)
	{
		RespawnDisableInstigators.Remove(Instigator);
	}

	UFUNCTION(Category = "Coast Train")
	void SetPlayerToRespawnOnTrain(AHazePlayerCharacter Player)
	{
		auto RiderComp = UCoastTrainRiderComponent::GetOrCreate(Player);

		auto ClosestCart = GetCartClosestToPlayer(Player);
		FVector PositionOnCart = ClosestCart.ActorTransform.InverseTransformPosition(Player.ActorLocation);

		RiderComp.CurrentTrainCart = ClosestCart;
		RiderComp.CurrentTrainCartPosition = PositionOnCart.X;
		RiderComp.ReachedTrainCart = ClosestCart;
		RiderComp.ReachedTrainCartPosition = PositionOnCart.X;
	}

	bool CanRespawnOnTrain() const
	{
		return RespawnDisableInstigators.Num() == 0 && !IsActorDisabled();
	}

	/**
	 * Teleport the train to a checkpoint location.
	 */
	UFUNCTION(Category = "Coast Train")
	void TeleportTrainToCheckpoint(ACoastTrainCheckpoint Checkpoint)
	{
		FSplinePosition NewPosition = Checkpoint.CheckpointSplinePosition;
		if (!NewPosition.IsValid())
		{
			devError("Tried to TeleportTrainToCheckpoint to a checkpoint without a valid spline position set.");
			return;
		}

		CurrentPosition = NewPosition;

		// Immediately teleport the train actor itself
		SnapTo(CurrentPosition);

		// Update all child carts' positions as well
		FSplinePosition ChildPosition = CurrentPosition;
		for(auto Cart : Carts)
		{
			if (Cart.Cart.bCartDisconnected)
				continue;

			ChildPosition.Move(-Cart.DistanceFromCartInFront);
			Cart.Cart.SnapTo(ChildPosition);
		}

		if (HasControl())
			CrumbPosition.SnapRemote();
	}

	/**
	 * Park the train at an upcoming checkpoint location.
	 * 
	 * The train will continue driving normally until it reaches the checkpoint location, then
	 * it will stop until ResumeParkedTrain is called with all instigators.
	 */
	UFUNCTION(Category = "Coast Train", Meta = (UseExecPins))
	void ParkTrainAtCheckpoint(ACoastTrainCheckpoint Checkpoint, FInstigator Instigator, FOnTrainFinishedParkingDelegate FinishedParking)
	{
		if (!HasControl())
			return;

		FCoastTrainParkRequest Request;
		Request.ParkPosition = Checkpoint.CheckpointSplinePosition;
		Request.Instigator = Instigator;
		Request.Delegate = FinishedParking;
		Request.bReached = false;
		Request.bResumed = false;

		if (!Request.ParkPosition.IsValid())
		{
			devError("Tried to ParkTrainAtCheckpoint to a checkpoint without a valid spline position set.");
			return;
		}

		ParkRequests.Add(Request);
	}

	/**
	 * Enable the train for the first time after starting disabled.
	 */
	UFUNCTION(Category = "Coast Train")
	void EnableTrainFromStartDisabled()
	{
		RemoveActorDisable(DisableComp.StartDisabledInstigator);
	}

	/**
	 * Resume a previously parked train and start driving again.
	 */
	UFUNCTION(Category = "Coast Train")
	void ResumeParkedTrain(FInstigator Instigator)
	{
		if (!HasControl())
			return;

		for (int i = ParkRequests.Num() - 1; i >= 0; --i)
		{
			auto& Request = ParkRequests[i];
			if (Request.Instigator == Instigator)
			{
				Request.bResumed = true;

				// Don't remove it yet if it hasn't been reached yet
				if (Request.bReached)
					ParkRequests.RemoveAt(i);
			}
		}
	}

	/**
	 * Disable all grapple points on the train carts
	 */
	UFUNCTION(Category = "Coast Train")
	void DisableAllGrapplePointsOnTrain(FInstigator Instigator)
	{
		TArray<UCoastTrainCartGrapplePointLine> Lines;
		TArray<UGrapplePointBaseComponent> Points;
		TArray<AActor> AttachedActors;

		for (auto CartInfo : Carts)
		{
			if (CartInfo.Cart != nullptr)
			{
				CartInfo.Cart.GetComponentsByClass(Lines);
				for (auto Line : Lines)
					Line.DisableGrapplePointLine(Instigator);
				Lines.Reset();

				CartInfo.Cart.GetComponentsByClass(Points);
				for (auto Point : Points)
					Point.Disable(Instigator);
				Points.Reset();

				CartInfo.Cart.GetAttachedActors(AttachedActors, true, true);
				for (AActor Attach : AttachedActors)
				{
					auto TwistingSpline = Cast<ACoastTrainTwistingGrappleSpline>(Attach);
					if (TwistingSpline != nullptr)
						TwistingSpline.AddActorDisable(this);
				}
				AttachedActors.Reset();
			}
		}
	}

	/**
	 * Enable all grapple points on the train carts
	 */
	UFUNCTION(Category = "Coast Train")
	void EnableAllGrapplePointsOnTrain(FInstigator Instigator)
	{
		TArray<UCoastTrainCartGrapplePointLine> Lines;
		TArray<UGrapplePointBaseComponent> Points;
		TArray<AActor> AttachedActors;

		for (auto CartInfo : Carts)
		{
			if (CartInfo.Cart != nullptr)
			{
				CartInfo.Cart.GetComponentsByClass(Lines);
				for (auto Line : Lines)
					Line.EnableGrapplePointLine(Instigator);
				Lines.Reset();

				CartInfo.Cart.GetComponentsByClass(Points);
				for (auto Point : Points)
					Point.Enable(Instigator);
				Points.Reset();

				CartInfo.Cart.GetAttachedActors(AttachedActors, true, true);
				for (AActor Attach : AttachedActors)
				{
					auto TwistingSpline = Cast<ACoastTrainTwistingGrappleSpline>(Attach);
					if (TwistingSpline != nullptr)
						TwistingSpline.RemoveActorDisable(this);
				}
				AttachedActors.Reset();
			}
		}
	}

	/**
	 * Disable all movement inherit volumes on the train.
	 */
	UFUNCTION(Category = "Coast Train")
	void DisableAllInheritMovementVolumesOnTrain(AHazePlayerCharacter Player, FInstigator Instigator)
	{
		TArray<UCoastTrainInheritMovementComponent> InheritComponents;

		for (auto CartInfo : Carts)
		{
			if (CartInfo.Cart != nullptr)
			{
				CartInfo.Cart.GetComponentsByClass(InheritComponents);
				for (auto InheritComp : InheritComponents)
					InheritComp.DisableTriggerForPlayer(Player, Instigator);
				InheritComponents.Reset();
			}
		}
	}

	/**
	 * Whether the train is currently parked and standing still.
	 */
	private bool IsTrainParked() const
	{
		for (auto& Request : ParkRequests)
		{
			if (Request.bReached)
				return true;
		}
		return false;
	}

	/**
	 * Start rubberbanding the train so the players' position is always either
	 * behind or at the specified position.
	 * 
	 * Players that are currently _on_ the train are ignored for rubberbanding purposes.
	 */
	UFUNCTION(Category = "Coast Train")
	void StartRubberBandingPlayers(FInstigator Instigator, AHazeActor RubberBandTargetCart,
		float RubberBandTargetOffset, float RubberBandTargetTolerance = 1000.0,
		float MinimumSlowdownMultiplier = 0.0, float MaximumSpeedupMultiplier = 2.0,
		float DistanceForMinimumSpeed = 5000.0, float DistanceForMaximumSpeed = 5000.0)
	{
		if (!HasControl())
			return;

		float TargetDistance = RubberBandTargetOffset;
		if (RubberBandTargetCart != nullptr && CurrentPosition.IsValid())
		{
			FVector CartLocation = RubberBandTargetCart.ActorLocation;

			FSplinePosition CartSplinePos = CurrentPosition.CurrentSpline.GetClosestSplinePositionToWorldLocation(CartLocation);
			float DistanceToCart = CartSplinePos.Distance(CurrentPosition, ESplineMovementPolarity::Positive);
			if (DistanceToCart != MAX_flt)
				TargetDistance += DistanceToCart;
		}

		FCoastTrainRubberBanding RubberBandSettings;
		RubberBandSettings.Instigator = Instigator;
		RubberBandSettings.TargetSplineDistanceBehindDriver = TargetDistance;
		RubberBandSettings.TargetTolerance = RubberBandTargetTolerance;
		RubberBandSettings.MinimumSlowdownMultiplier = MinimumSlowdownMultiplier;
		RubberBandSettings.MaximumSpeedupMultiplier = MaximumSpeedupMultiplier;
		RubberBandSettings.DistanceForMaximumSpeed = DistanceForMaximumSpeed;
		RubberBandSettings.DistanceForMinimumSpeed = DistanceForMinimumSpeed;

		RubberBanding.Add(RubberBandSettings);
	}

	/**
	 * Stop previously started rubberbanding.
	 */
	UFUNCTION(Category = "Coast Train")
	void StopRubberBandingPlayers(FInstigator Instigator)
	{
		if (!HasControl())
			return;

		for (int i = RubberBanding.Num() - 1; i >= 0; --i)
		{
			FCoastTrainRubberBanding& RubberBandSettings = RubberBanding[i];
			if (RubberBandSettings.Instigator == Instigator)
				RubberBanding.RemoveAt(i);
		}
	}

	/**
	 * Override the train's overall movement speed with an instigator.
	 */
	UFUNCTION(Category = "Coast Train")
	void ApplyTrainMovementSpeedOverride(float NewSpeed, FInstigator Instigator, EInstigatePriority Priority = EInstigatePriority::Normal)
	{
		if (!HasControl())
			return;

		TrainMovementSpeed.Apply(NewSpeed, Instigator, Priority);
	}

	/**
	 * Clear a previous override for the train's movement speed.
	 */
	UFUNCTION(Category = "Coast Train")
	void ClearTrainMovementSpeedOverride(FInstigator Instigator)
	{
		if (!HasControl())
			return;

		TrainMovementSpeed.Clear(Instigator);
	}

	/**
	 * Start spinning the train starting with the driver
	 */
	UFUNCTION(Category = "Coast Train")
	void SpinTrain(float SpinSpeedDegreesPerSecond)
	{
		for (auto& Spin : ActiveSpins)
		{
			if (!Spin.bHasEnded)
			{
				Spin.EndPosition = CurrentPosition;
				Spin.bHasEnded = true;
			}
		}

		FCoastTrainSpinRegion NewSpin;
		NewSpin.StartPosition = CurrentPosition;
		NewSpin.SpinSpeed = SpinSpeedDegreesPerSecond;
		ActiveSpins.Add(NewSpin);
	}

	/**
	 * Reset the train's spin back to neutral on the spline with the given speed.
	 */
	UFUNCTION(Category = "Coast Train")
	void ResetTrainSpinToNeutral(float SpinSpeedDegreesPerSecond)
	{
		for (auto& Spin : ActiveSpins)
		{
			if (!Spin.bHasEnded)
			{
				Spin.EndPosition = CurrentPosition;
				Spin.bHasEnded = true;
			}
		}

		FCoastTrainSpinRegion NewSpin;
		NewSpin.bSpinToTarget = true;
		NewSpin.SpinTarget = 0.0;
		NewSpin.StartPosition = CurrentPosition;
		NewSpin.SpinSpeed = Math::Abs(SpinSpeedDegreesPerSecond);
		ActiveSpins.Add(NewSpin);
	}

	/**
	 * Spin the train and then stop spinning at a specific target rotation relative to neutral.
	 */
	UFUNCTION(Category = "Coast Train")
	void SpinTrainToTargetRotation(float SpinSpeedDegreesPerSecond, float TargetRotationDegrees)
	{
		for (auto& Spin : ActiveSpins)
		{
			if (!Spin.bHasEnded)
			{
				Spin.EndPosition = CurrentPosition;
				Spin.bHasEnded = true;
			}
		}

		FCoastTrainSpinRegion NewSpin;
		NewSpin.bSpinToTarget = true;
		NewSpin.SpinTarget = TargetRotationDegrees;
		NewSpin.StartPosition = CurrentPosition;
		NewSpin.SpinSpeed = Math::Abs(SpinSpeedDegreesPerSecond);
		ActiveSpins.Add(NewSpin);
	}

	UFUNCTION(NotBlueprintCallable, DevFunction)
	void DevSpinCounterClockwise()
	{
		SpinTrain(5.0);
	}

	UFUNCTION(NotBlueprintCallable, DevFunction)
	void DevSpinClockwise()
	{
		SpinTrain(-5.0);
	}

	UFUNCTION(NotBlueprintCallable, DevFunction)
	void DevResetSpin()
	{
		ResetTrainSpinToNeutral(5.0);
	}

	UFUNCTION(CallInEditor, NotBlueprintCallable)
	private void SnapChildren()
	{
		Modify();

		FSplinePosition ChildPosition = FindClosestSplinePosition();

		// Move all children to follow!
		for(auto CartInfo : Carts)
		{
			if (CartInfo.Cart != nullptr)
			{
				ChildPosition.Move(-CartInfo.DistanceFromCartInFront);

				CartInfo.Cart.Modify();
				CartInfo.Cart.bReverseOnRail = bReverseOnRail;
				CartInfo.Cart.SnapTo(ChildPosition);
			}
		}
	}

	UFUNCTION(CallInEditor, NotBlueprintCallable)
	private void UpdateCartDistances()
	{
		if (Carts.Num() == 0)
			return;

		Modify();

		// Then update between each subsequent child
		ACoastTrainCart LastParent = this;
		for(int Index = 0; Index < Carts.Num(); ++Index)
		{
			auto& Child = Carts[Index];
			if (Child.Cart == nullptr)
				continue;

			Child.Cart.Modify();

			float Distance = CalculateDistanceBetweenCarts(LastParent, Child.Cart);
			Child.DistanceFromCartInFront = Distance;

			LastParent = Child.Cart;
		}
	}

	access:CoastTrainInternal
	float CalculateTrainMovementSpeed()
	{
		// If the train is parked we should not move
		if (IsTrainParked())
			return 0.0;

		float MoveSpeed = TrainMovementSpeed.Get();
		float RubberBandMultiplier = 0.0;

		FTemporalLog TemporalLog = TEMPORAL_LOG(this).Section("Rubberbanding");

		// If we are rubberbanding, adapt the train's speed so players are
		// guaranteed to land in roughly the correct spot.
		if (RubberBanding.Num() != 0)
		{
			const FCoastTrainRubberBanding& RubberBandSettings = RubberBanding[0];
			TemporalLog.Value("Instigator", RubberBandSettings.Instigator);
			TemporalLog.Value("TargetSplineDistanceBehindDriver", RubberBandSettings.TargetSplineDistanceBehindDriver);
			TemporalLog.Value("TargetTolerance", RubberBandSettings.TargetTolerance);
			TemporalLog.Value("DistanceForMinimumSpeed", RubberBandSettings.DistanceForMinimumSpeed);
			TemporalLog.Value("DistanceForMaximumSpeed", RubberBandSettings.DistanceForMaximumSpeed);
			TemporalLog.Value("MinimumSlowdownMultiplier", RubberBandSettings.MinimumSlowdownMultiplier);
			TemporalLog.Value("MaximumSpeedupMultiplier", RubberBandSettings.MaximumSpeedupMultiplier);

			FSplinePosition RubberBandSplinePos = CurrentPosition;
			RubberBandSplinePos.Move(-RubberBandSettings.TargetSplineDistanceBehindDriver);

			TemporalLog.Point(f"RubberBandSplinePos", RubberBandSplinePos.WorldLocation);

			bool bAnyRubberbandingPlayers = false;
			bool bAnyPlayersAffectingRubberband = false;
			for (AHazePlayerCharacter Player : Game::Players)
			{
				// If the player is already on the train ignore them for rubberbanding
				if (IsPlayerOnTrain(Player))
					continue;
				if (Player.IsAnyCapabilityActive(n"Waterski"))
					continue;

				bAnyRubberbandingPlayers = true;

				// Dead players don't contribute to rubberbanding
				if (Player.IsPlayerDead())
					continue;

				bAnyPlayersAffectingRubberband = true;

				// Calculate how far ahead or behind our target region the player is
				FSplinePosition PlayerSplinePosition = CurrentPosition.CurrentSpline.GetClosestSplinePositionToWorldLocation(Player.ActorLocation);
				float RubberBandDistance = PlayerSplinePosition.DeltaToReachClosest(RubberBandSplinePos);

				TemporalLog.Value(f"{Player.Player :n} Distance", RubberBandDistance);
				TemporalLog.Point(f"{Player.Player :n} SplinePosition", PlayerSplinePosition.WorldLocation);

				// If the player is ahead, speed up the train
				if (RubberBandDistance < -RubberBandSettings.TargetTolerance)
				{
					float WantedMultiplier = Math::GetMappedRangeValueClamped(
						InputRange = FVector2D(-RubberBandSettings.DistanceForMaximumSpeed - RubberBandSettings.TargetTolerance, -RubberBandSettings.TargetTolerance),
						OutputRange = FVector2D(RubberBandSettings.MaximumSpeedupMultiplier, 1.0),
						Value = RubberBandDistance,
					);

					if (WantedMultiplier > RubberBandMultiplier)
						RubberBandMultiplier = WantedMultiplier;
					continue;
				}

				// If the player is behind, slow down the train so the player can catch up
				if (RubberBandDistance > RubberBandSettings.TargetTolerance)
				{
					float WantedMultiplier = Math::GetMappedRangeValueClamped(
						InputRange = FVector2D(RubberBandSettings.TargetTolerance, RubberBandSettings.DistanceForMinimumSpeed + RubberBandSettings.TargetTolerance),
						OutputRange = FVector2D(1.0, RubberBandSettings.MinimumSlowdownMultiplier),
						Value = RubberBandDistance,
					);

					if (WantedMultiplier > RubberBandMultiplier)
						RubberBandMultiplier = WantedMultiplier;
					continue;
				}

				// We are in the margin, so we should speed up to normal speed
				if (RubberBandMultiplier < 1.0)
					RubberBandMultiplier = 1.0;
			}

			if (!bAnyRubberbandingPlayers)
			{
				RubberBandMultiplier = 1.0;
				RubberBanding.Reset();
			}
			else if (!bAnyPlayersAffectingRubberband)
			{
				RubberBandMultiplier = 1.0;
			}

			TemporalLog.Value("bAnyRubberBandingPlayers", bAnyRubberbandingPlayers);
		}
		else
		{
			RubberBandMultiplier = 1.0;
		}

		TemporalLog.Value("RubberBandMultiplier", RubberBandMultiplier);
		return MoveSpeed * RubberBandMultiplier;
	}

	/**
	 * Check whether the specified player is currently on the train.
	 */
	bool IsPlayerOnTrain(AHazePlayerCharacter Player)
	{
		auto PlayerMoveComp = UHazeMovementComponent::Get(Player);
		USceneComponent CheckComp = PlayerMoveComp.GetCurrentMovementReferenceFrameComponent();
		while (CheckComp != nullptr)
		{
			auto Cart = Cast<ACoastTrainCart>(CheckComp.Owner);
			if (Cart != nullptr && Cart.Driver == this)
				return true;
			CheckComp = CheckComp.AttachParent;
		}

		return false;
	}

	private float CalculateDistanceBetweenCarts(ACoastTrainCart Parent, ACoastTrainCart Child)
	{
		if (Parent == nullptr || Child == nullptr)
			return 0.0;

		auto ParentPosition = Parent.FindClosestSplinePosition();
		auto ChildPosition = Child.FindClosestSplinePosition();

		return ChildPosition.Distance(ParentPosition, ESplineMovementPolarity::Positive);
	}

	access:CoastTrainInternal
	void UpdateTrainParking(FSplinePosition PreviousPosition, FSplinePosition NewPosition)
	{
		for (int i = ParkRequests.Num() - 1; i >= 0; --i)
		{
			auto& Request = ParkRequests[i];
			if (Request.bReached)
				continue;

			if (Request.ParkPosition.IsBetweenPositions(PreviousPosition, NewPosition))
			{
				Request.bReached = true;
				CurrentPosition = Request.ParkPosition;
				CrumbParkingSpotReached(Request.Delegate);

				// Remove the request if it was already resumed earlier
				if (Request.bResumed)
					ParkRequests.RemoveAt(i);
			}
		}
	}

	UFUNCTION(CrumbFunction)
	private void CrumbParkingSpotReached(FOnTrainFinishedParkingDelegate Delegate)
	{
		Delegate.ExecuteIfBound();
	}

	ACoastTrainCart GetCartClosestToPlayer(AHazePlayerCharacter Player) 
	{
		ACoastTrainCart ClosestCart = this;
		float ClosestDistance = GetCartDistanceToPlayer(Player);
		for (auto CartInfo : Carts)
		{
			if (CartInfo.Cart != nullptr)
			{
				float Dist = CartInfo.Cart.GetCartDistanceToPlayer(Player);
				if (Dist < ClosestDistance)
				{
					ClosestCart = CartInfo.Cart;
					ClosestDistance = Dist;
				}
			}
		}

		return ClosestCart;
	}

	ACoastTrainCart GetCartClosestToLocation(FVector WorldLocation) 
	{
		ACoastTrainCart ClosestCart = this;
		float ClosestDistance = GetCartDistanceToLocation(WorldLocation);
		for (auto CartInfo : Carts)
		{
			if (CartInfo.Cart != nullptr)
			{
				float Dist = CartInfo.Cart.GetCartDistanceToLocation(WorldLocation);
				if (Dist < ClosestDistance)
				{
					ClosestCart = CartInfo.Cart;
					ClosestDistance = Dist;
				}
			}
		}

		return ClosestCart;
	}

	// Get all carts, including the driver cart
	TArray<ACoastTrainCart> GetAllTrainCarts()
	{
		TArray<ACoastTrainCart> AllCarts;
		AllCarts.Add(this);

		for (auto& CartInfo : Carts)
		{
			if (CartInfo.Cart != nullptr)
				AllCarts.Add(CartInfo.Cart);
		}

		return AllCarts;
	}
}