
class UTrainFlyingEnemyCrashCapability : UHazeCapability
{
	default TickGroup = EHazeTickGroup::BeforeMovement;
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	UTrainFlyingEnemySettings Settings;
	ATrainFlyingEnemy Enemy;
	FVector CrashOffset;
	ACoastTrainCart RelativeToCart;
	FRotator CrashRotation;
	FHazeAcceleratedRotator AccAlignRot;
	float SpinDir = -1.0;

	TArray<AHazePlayerCharacter> PlayersOnEnemy;

	UHazeCrumbSyncedVectorComponent CrumbSyncedLocation;
	UHazeCrumbSyncedRotatorComponent CrumbSyncedRotation;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Enemy = Cast<ATrainFlyingEnemy>(Owner);
		Settings = UTrainFlyingEnemySettings::GetSettings(Owner);
		CrumbSyncedLocation = UHazeCrumbSyncedVectorComponent::Get(Owner);
		CrumbSyncedRotation = UHazeCrumbSyncedRotatorComponent::Get(Owner);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (!Enemy.bDestroyedByPlayer)
			return false;
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		UTrainFlyingEnemyEffectEventHandler::Trigger_StartCrash(Enemy);
		CrashRotation = Enemy.ActorRotation;
		AccAlignRot.SnapTo(CrashRotation);
		RelativeToCart = Enemy.TrainCart;
		if (Enemy.Target.TargetPlayer != nullptr)
			RelativeToCart = Enemy.TrainCart.Driver.GetCartClosestToPlayer(Enemy.Target.TargetPlayer);
		CrashOffset = RelativeToCart.MeshRoot.WorldTransform.InverseTransformPosition(Enemy.ActorLocation);	
		SpinDir = (CrashOffset.Y < 0) ? 1.0 : -1.0;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		for (auto Player : PlayersOnEnemy)
			PlayerLeftEnemy(Player);
		PlayersOnEnemy.Empty();
	}

	void PlayerIsOnEnemy(AHazePlayerCharacter Player)
	{
		Player.PlayCameraShake(Enemy.CrashingCameraShake, this, 1);
		Player.ApplyCameraSettings(Enemy.CrashingCameraSettings, 2.0, this, EHazeCameraPriority::Medium, 140);
	}

	void PlayerLeftEnemy(AHazePlayerCharacter Player)
	{
		Player.StopCameraShakeByInstigator(this);
		Player.ClearCameraSettingsByInstigator(this, 3.0);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if (RelativeToCart == nullptr)
			return;

		// Update which players are on top of the enemy at the moment
		for (auto Player : Game::Players)
		{
			if (Enemy.IsPlayerOnTopOfCar(Player))
			{
				if (!PlayersOnEnemy.Contains(Player))
				{
					PlayersOnEnemy.Add(Player);
					PlayerIsOnEnemy(Player);
				}
			}
			else
			{
				if (PlayersOnEnemy.Contains(Player))
				{
					PlayersOnEnemy.Remove(Player);
					PlayerLeftEnemy(Player);
				}
			}
		}

		FTransform CartPosition = RelativeToCart.MeshRoot.WorldTransform;

		if (HasControl())
		{
			FVector CrashVelocity = Settings.EnemyDestroyedFallVelocity * Math::Min(1.0, ActiveDuration);
			CrashOffset += CrashVelocity * DeltaTime;

			// Initially shake the position of the enemy so we know something is wrong
			FVector OffsetShake;
			float ShakeAmplitude = Settings.CrashShakeAmplitude * Math::Max( 0.0, 1.0 - ActiveDuration);
			OffsetShake.Z = Math::Sin(ActiveDuration * 15.1) * ShakeAmplitude;
			OffsetShake.X = Math::Sin(ActiveDuration * 13.0) * ShakeAmplitude;
			OffsetShake.Y = Math::Sin(ActiveDuration * 17.0) * ShakeAmplitude;

			// Position of the enemy relative to the target train cart
			FVector TargetLocation = CartPosition.TransformPosition(CrashOffset + OffsetShake);

			// Align with train 
			AccAlignRot.SpringTo(RelativeToCart.ActorRotation, Settings.CrashAlignWithTrainForce, 0.2, DeltaTime);
			CrashRotation.Yaw = AccAlignRot.Value.Yaw;

			// Go into a wild spin gradually
			CrashRotation.Roll += SpinDir * Settings.CrashRollSpeed * Math::Square(Math::Min(ActiveDuration * 0.3, 1.0)) * DeltaTime;

			// Oscillate the rotation of the enemy as well, but only slightly
			FRotator TargetRotation = CrashRotation;
			TargetRotation.Yaw += Math::Sin(ActiveDuration * 11.15) * 5.0;
			TargetRotation.Pitch += Math::Sin(ActiveDuration * 9.7) * 3.0;

			CrumbSyncedLocation.Value = TargetLocation;
			CrumbSyncedRotation.Value = TargetRotation;
		}

		// Set position (synced on remote side)
		Enemy.SetActorLocationAndRotation(CrumbSyncedLocation.Value, CrumbSyncedRotation.Value);

		if (Math::Abs(FRotator::NormalizeAxis(CrumbSyncedRotation.Value.Roll)) > 45.0)
		{
			// Throw off any players when roll becomes too much
			// No need to network, launch is crumbed
			FVector LaunchForce = GetLaunchForce(CartPosition);
			for (AHazePlayerCharacter Player : PlayersOnEnemy)
			{
				LaunchPlayer(Player, LaunchForce, RelativeToCart);
				PlayerLeftEnemy(Player);
			}
			PlayersOnEnemy.Empty();
		}

		// Explode when low enough 
		if (HasControl())
		{
			if (CrumbSyncedLocation.Value.Z < CartPosition.Location.Z - Settings.CrashExplosionBelowTrainHeight)
			{
				CrumbExplode(GetLaunchForce(CartPosition), RelativeToCart);
			}
		}
	}

	FVector GetLaunchForce(FTransform CartPosition) const
	{
		FVector LocalForce = Settings.EnemyExplodeLaunchForce;

		// Additional sideways force when far away
		LocalForce.Y -= 0.5 * Math::Max(0.0, Math::Abs(CrashOffset.Y) - 3000.0);

		// Launch rightwards back to train when to the left of train
		if (CrashOffset.Y < 0.0)
			LocalForce.Y *= -1.0;

		return CartPosition.TransformVectorNoScale(LocalForce);	
	}

	UFUNCTION(CrumbFunction)
	void CrumbExplode(FVector LaunchForce, ACoastTrainCart Cart)
	{
		// Launch players that are nearby (not just on cart, since we might have panicked and tried to jump off before crash)
		for (auto Player : Game::Players)
		{
			if (!Player.ActorLocation.IsWithinDist(Enemy.ActorCenterLocation, Settings.EnemyExplodeLaunchRadius))
				continue;
			LaunchPlayer(Player, LaunchForce, Cart);
		}

		UTrainFlyingEnemyEffectEventHandler::Trigger_CrashExplode(Enemy);
		Enemy.AddActorDisable(n"EnemyExploded");

		for (auto Player : Game::Players)
		{
			Player.PlayWorldCameraShake(
				Enemy.ExplodesCameraShake,
				this,
				Enemy.ActorLocation,
				1000.0,
				10000.0,
			);
		}

		for (auto Player : PlayersOnEnemy)
			PlayerLeftEnemy(Player);
		PlayersOnEnemy.Empty();
	}

	void LaunchPlayer(AHazePlayerCharacter Player, FVector LaunchForce, ACoastTrainCart Cart)
	{
		auto LaunchComp = UTrainPlayerLaunchOffComponent::GetOrCreate(Player);
		FTrainPlayerLaunchParams Launch;
		Launch.LaunchFromCart = Cart;
		Launch.ForceDuration = Settings.EnemyExplodeLaunchForceDuration;
		Launch.FloatDuration = Settings.EnemyExplodeLaunchFloatDuration;
		Launch.PointOfInterestDuration = Settings.EnemyExplodeLaunchPointOfInterestDuration;
		Launch.Force = LaunchForce;
		LaunchComp.TryLaunch(Launch);
	}
}