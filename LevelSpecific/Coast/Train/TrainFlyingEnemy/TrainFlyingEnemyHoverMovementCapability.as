
class UTrainFlyingEnemyHoverMovementCapability : UHazeCapability
{
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;
	default TickGroup = EHazeTickGroup::BeforeMovement;

	UTrainFlyingEnemySettings Settings;
	ATrainFlyingEnemy Enemy;
	float WobbleTimer = 0.0;

	bool bTargetReached = false;
	FVector ReachedTargetOffset;

	ACoastTrainCart RelativeToCart;
	FVector HoverOffset;
	FHazeAcceleratedVector AccelOffset;

	UHazeCrumbSyncedVectorComponent CrumbSyncedLocation;
	UHazeCrumbSyncedRotatorComponent CrumbSyncedRotation;

	bool bShown = false;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Enemy = Cast<ATrainFlyingEnemy>(Owner);
		Enemy.AddActorVisualsBlock(this); // Don't show until movement starts, or we will get a one frame pops
		Settings = UTrainFlyingEnemySettings::GetSettings(Owner);
		CrumbSyncedLocation = UHazeCrumbSyncedVectorComponent::Get(Owner);
		CrumbSyncedRotation = UHazeCrumbSyncedRotatorComponent::Get(Owner);
		Reposition();
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (Enemy.bDestroyedByPlayer)
			return false;
		if (Enemy.Target.TargetCart == nullptr)
			return false;
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (Enemy.bDestroyedByPlayer)
			return true;
		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		if (!bShown)
			Enemy.RemoveActorVisualsBlock(this);
		bShown = true;

		// Remove the offset from the mesh so we can move the actor properly
		Enemy.SetActorLocationAndRotation(Enemy.Mesh.WorldLocation, Enemy.Mesh.WorldRotation);
		Enemy.Mesh.SetRelativeLocation(FVector::ZeroVector);

		Enemy.bIsFlyingIn = true;
		AccelOffset.SnapTo(Enemy.SplineOffset + Settings.StartingOffset);
		RelativeToCart = Enemy.Target.TargetCart;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if (Enemy.bReposition)
			Reposition();

		if (Enemy.TrainCart == nullptr)
			return;
		if (Enemy.Target.TargetPlayer == nullptr)
			return;

		if (HasControl())
		{
			// Rebase our relative offset if the cart changes
			if (RelativeToCart != Enemy.Target.TargetCart)
			{
				FTransform OldPosition = RelativeToCart.MeshRoot.WorldTransform;
				FTransform NewPosition = Enemy.Target.TargetCart.MeshRoot.WorldTransform;

				FVector NewOffset = OldPosition.TransformPosition(AccelOffset.Value);
				NewOffset = NewPosition.InverseTransformPosition(NewOffset);
				
				FVector NewVelocity = OldPosition.TransformVector(AccelOffset.Velocity);
				NewVelocity = NewPosition.InverseTransformVector(NewVelocity);

				AccelOffset.SnapTo(NewOffset, NewVelocity);
				RelativeToCart = Enemy.Target.TargetCart;
			}

			// Position the enemy relative to the target train cart
			FTransform CartPosition = RelativeToCart.MeshRoot.WorldTransform;
			FVector TargetOffset = Enemy.SplineOffset; 
			TargetOffset.X += Enemy.Target.TargetOffset.X + HoverOffset.X;
			TargetOffset.Y += Math::Sign(Enemy.SplineOffset.Y) * HoverOffset.Y;
			TargetOffset.Z += HoverOffset.Z;

			float MoveDuration = Settings.MovementLocationChangeDuration;
			if (Enemy.bIsFlyingIn)
				MoveDuration = Settings.MovementFlyingInDuration;
			AccelOffset.AccelerateTo(TargetOffset, MoveDuration, DeltaTime);
			FVector TargetLocation = CartPosition.TransformPosition(AccelOffset.Value);

			if (Enemy.bIsFlyingIn && AccelOffset.Value.IsWithinDist(TargetOffset, Settings.StartAttackingRange))
				Enemy.bIsFlyingIn = false;

			// Calculate the rotation we want
			FRotator TargetRotation = FRotator::MakeFromX(-Enemy.SplineOffset);
			FVector ToTarget = CartPosition.TransformPosition(FVector(Enemy.Target.TargetOffset.X + Settings.HoverRotateTowardsDistanceInFrontOfTarget, 0.0, 0.0)) - TargetLocation;
			FRotator ToTargetRotation = FRotator::MakeFromX(ToTarget);

			TargetRotation.Yaw = ToTargetRotation.Yaw;

			// Wobble the car
			WobbleTimer += 2.0 * DeltaTime;
			TargetLocation.Z += 100.0 * Math::Sin(WobbleTimer);
			TargetRotation.Yaw += 10.0 * Math::Sin(WobbleTimer * 0.81);
			TargetRotation.Pitch += 10.0 * Math::Sin(WobbleTimer * 0.43 + 1.0);

			TargetRotation = Math::RInterpTo(Enemy.ActorRotation, TargetRotation, DeltaTime, 1.0);

			CrumbSyncedLocation.Value = TargetLocation;
			CrumbSyncedRotation.Value = TargetRotation;
		}		
		
		// Set position (this will be replicated values on remote)
		Enemy.SetActorLocationAndRotation(CrumbSyncedLocation.Value, CrumbSyncedRotation.Value);
	}

	void Reposition()
	{
		Enemy.bReposition = false;
		if (!HasControl())
			return;

		// Hover offset is synced, but it's fine to have a desynced value for a little while at start
		FVector Offset;
		Offset.X = Math::RandRange(Settings.HoverDistanceOffsetMin.X, Settings.HoverDistanceOffsetMax.X);
		Offset.Y = Math::RandRange(Settings.HoverDistanceOffsetMin.Y, Settings.HoverDistanceOffsetMax.Y);
		Offset.Z = Math::RandRange(Settings.HoverDistanceOffsetMin.Z, Settings.HoverDistanceOffsetMax.Z);
		CrumbSetHoverOffset(Offset);
	}

	UFUNCTION(CrumbFunction)
	void CrumbSetHoverOffset(FVector Offset)
	{
		HoverOffset = Offset;
	}
};