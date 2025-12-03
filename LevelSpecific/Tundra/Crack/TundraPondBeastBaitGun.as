class UTundraPondBeastBaitGunVisualizationComponent : USceneComponent
{
	// Uncheck this bool to reset the shoot origin and target location to the default values
	UPROPERTY(EditAnywhere, BlueprintHidden)
	bool bIsInitialized = false;

	UFUNCTION(CallInEditor)
	void ResetArcPosition()
	{
		bIsInitialized = false;
	}

	UPROPERTY(EditAnywhere)
	FVector ShootOrigin;

	UPROPERTY(EditAnywhere)
	FVector TargetLocation;
}

class UTundraPondBeastBaitGunVisualizer : UHazeScriptComponentVisualizer
{
	default VisualizedClass = UTundraPondBeastBaitGunVisualizationComponent;

	bool bIsTargetSelected = false;
	bool bIsOriginSelected = false;

	UFUNCTION(BlueprintOverride)
	void VisualizeComponent(const UActorComponent Component)
	{
		auto Current = Cast<UTundraPondBeastBaitGunVisualizationComponent>(Component);
		auto Gun = Cast<ATundraPondBeastBaitGun>(Current.Owner);
		if(!Current.bIsInitialized)
			Initialize(Current, Gun);

		SetHitProxy(n"ShootOrigin", EVisualizerCursor::GrabHand);
		DrawPoint(Current.ShootOrigin, FLinearColor::Green, 40);

		SetHitProxy(n"ShootTarget", EVisualizerCursor::GrabHand);
		DrawPoint(Current.TargetLocation, FLinearColor::Red, 40);
		ClearHitProxy();

		FVector Velocity = Trajectory::CalculateVelocityForPathWithHorizontalSpeed(Current.ShootOrigin, Current.TargetLocation, Gun.ProjectileGravity, Gun.ProjectileHorizontalSpeed);
		DrawTrajectory(Current.ShootOrigin, Current.TargetLocation, Velocity, -FVector::UpVector * Gun.ProjectileGravity);

		FVector ShootingAreaPoint1 = Current.TargetLocation + Gun.ShootingAreaRotation.ForwardVector * Gun.ShootingAreaExtents.X - Gun.ShootingAreaRotation.RightVector * Gun.ShootingAreaExtents.Y;
		FVector ShootingAreaPoint2 = Current.TargetLocation + Gun.ShootingAreaRotation.ForwardVector * Gun.ShootingAreaExtents.X + Gun.ShootingAreaRotation.RightVector * Gun.ShootingAreaExtents.Y;
		FVector ShootingAreaPoint3 = Current.TargetLocation - Gun.ShootingAreaRotation.ForwardVector * Gun.ShootingAreaExtents.X + Gun.ShootingAreaRotation.RightVector * Gun.ShootingAreaExtents.Y;
		FVector ShootingAreaPoint4 = Current.TargetLocation - Gun.ShootingAreaRotation.ForwardVector * Gun.ShootingAreaExtents.X - Gun.ShootingAreaRotation.RightVector * Gun.ShootingAreaExtents.Y;
		
		DrawLine(ShootingAreaPoint1, ShootingAreaPoint2, FLinearColor::Red, 5.0);
		DrawLine(ShootingAreaPoint2, ShootingAreaPoint3, FLinearColor::Red, 5.0);
		DrawLine(ShootingAreaPoint3, ShootingAreaPoint4, FLinearColor::Red, 5.0);
		DrawLine(ShootingAreaPoint4, ShootingAreaPoint1, FLinearColor::Red, 5.0);
	}

	UFUNCTION(BlueprintOverride)
	void EndEditing()
	{
		bIsTargetSelected = false;
		bIsOriginSelected = false;
	}

	// Handle when the point with the hitproxy is clicked 
	UFUNCTION(BlueprintOverride)
	bool VisProxyHandleClick(FName HitProxy, FVector ClickOrigin, FVector ClickDirection, FKey Key,
							 EInputEvent Event)
	{
		if(HitProxy == n"ShootOrigin")
		{
			bIsOriginSelected = true;
			bIsTargetSelected = false;
			return true;
		}
		if(HitProxy == n"ShootTarget")
		{
			bIsTargetSelected = true;
			bIsOriginSelected = false;
			return true;
		}

		return false;
	}

	// Used by the editor to determine where the transform gizmo ends up
	UFUNCTION(BlueprintOverride)
	bool GetWidgetLocation(FVector& OutLocation) const
	{
		auto Current = Cast<UTundraPondBeastBaitGunVisualizationComponent>(EditingComponent);

		if(bIsTargetSelected)
		{
			OutLocation = Current.TargetLocation;
			return true;
		}

		if(bIsOriginSelected)
		{
			OutLocation = Current.ShootOrigin;
			return true;
		}

		return false;
	}

	UFUNCTION(BlueprintOverride)
	bool GetCustomInputCoordinateSystem(EVisualizerCoordinateSystem CoordSystem,
										EVisualizerWidgetMode WidgetMode, FTransform& OutTransform) const
	{
		if (!bIsTargetSelected && !bIsOriginSelected)
			return false;

		OutTransform = FTransform::MakeFromXZ(FVector::ForwardVector, FVector::UpVector);

		return true;
	}

	// Used by the editor when the transform gizmo is moved while we are overriding it
	UFUNCTION(BlueprintOverride)
	bool HandleInputDelta(FVector& DeltaTranslate, FRotator& DeltaRotate, FVector& DeltaScale)
	{
		if(bIsOriginSelected)
		{
			auto Current = Cast<UTundraPondBeastBaitGunVisualizationComponent>(EditingComponent);
			if (!DeltaTranslate.IsNearlyZero())
			{
				Current.ShootOrigin += DeltaTranslate;
			}
			return true;
		}

		if(bIsTargetSelected)
		{
			auto Current = Cast<UTundraPondBeastBaitGunVisualizationComponent>(EditingComponent);
			if (!DeltaTranslate.IsNearlyZero())
			{
				Current.TargetLocation += DeltaTranslate;
			}
			return true;
		}

		return false;
	}

	void Initialize(UTundraPondBeastBaitGunVisualizationComponent Current, ATundraPondBeastBaitGun Gun)
	{
		TListedActors<ATundraPondBeastBaitTrigger> Triggers;

			float ClosestDistance = BIG_NUMBER;
			int CurrentIndex = -1;
			for(int i = 0; i < Triggers.Num(); i++)
			{
				float Dist = Triggers[i].ActorLocation.Distance(Gun.ActorLocation);
				if(Dist < ClosestDistance)
				{
					ClosestDistance = Dist;
					CurrentIndex = i;
				}
			}

			if(CurrentIndex < 0)
				return;

			auto Trigger = Triggers[CurrentIndex];

			Current.TargetLocation = Trigger.ActorLocation + FVector::UpVector * (Trigger.ActorScale3D.Z * 100);
			Current.ShootOrigin = Gun.ActorLocation + FVector::UpVector * 200.0;

			Current.bIsInitialized = true;
	}

	void DrawTrajectory(FVector Origin, FVector Destination, FVector Velocity, FVector Gravity)
	{
		Trajectory::FTrajectoryPoints Points = Trajectory::CalculateTrajectory(Origin, 5000.0, Velocity, Gravity.Size(), 1.5, -1.0, -Gravity.GetSafeNormal());

		for(int i=0; i<Points.Positions.Num() - 1; ++i)
		{
			FVector Start = Points.Positions[i];
			FVector End = Points.Positions[i + 1];
			bool bDone = false;

			if((Start - Destination).GetSafeNormal().DotProduct((End - Destination).GetSafeNormal()) < 0.0)
			{
				End = Destination;
				bDone = true;
			}

			DrawLine(Start, End, FLinearColor::Red, 5);
			if(bDone)
				break;
		}
	}
}

UCLASS(Abstract)
class ATundraPondBeastBaitGun : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent)
	UTundraLifeReceivingComponent LifeReceivingComponent;

	UPROPERTY(DefaultComponent, Attach=Root)
	UTundraGroundedLifeReceivingTargetableComponent LifeReceivingTargetableComponent;

	UPROPERTY(DefaultComponent, Attach=Root)
	UTundraPondBeastBaitGunVisualizationComponent GunVisualizer;

	UPROPERTY(DefaultComponent)
	UHazeCrumbSyncedVectorComponent SyncedShootLocation;

	UPROPERTY(EditAnywhere)
	TSubclassOf<ATundraPondBeastBait> BeastBaitProjectileClass;

	UPROPERTY(EditAnywhere)
	float AimingSpeed = 2000.0;

	UPROPERTY(EditAnywhere)
	float ProjectileHorizontalSpeed = 4000.0;

	UPROPERTY(EditAnywhere)
	float ProjectileGravity = 1600.0;

	UPROPERTY(EditAnywhere)
	FVector2D ShootingAreaExtents = FVector2D(2400.0, 2200.0);

	UPROPERTY(EditAnywhere)
	FRotator ShootingAreaRotation = FRotator(0.0, 13.0, 0.0);

	FVector CurrentWorldTarget;
	FTransform ShootAreaTransform;
	AHazePlayerCharacter Player;
	FVector CurrentProjectileTargetVelocity;
	UHazeActorNetworkedSpawnPoolComponent SpawnPoolComponent;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Player = Game::Zoe;
		SetActorControlSide(Player);

		CurrentWorldTarget = GunVisualizer.TargetLocation;
		ShootAreaTransform = FTransform(ShootingAreaRotation, GunVisualizer.TargetLocation);

		if(HasControl())
			SubscribeToEvents();

		SpawnPoolComponent = HazeActorNetworkedSpawnPoolStatics::GetOrCreateSpawnPool(BeastBaitProjectileClass, this);
		SpawnPoolComponent.OnSpawnedBySpawner.FindOrAdd(this).AddUFunction(this, n"OnBaitProjectileSpawned");
	}

	UFUNCTION(BlueprintOverride)
	void OnActorEnabled()
	{
		if(HasControl())
			SubscribeToEvents();
	}

	UFUNCTION(BlueprintOverride)
	void OnActorDisabled()
	{
		if(HasControl())
			UnsubscribeToEvents();
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		if(LifeReceivingComponent.IsCurrentlyLifeGiving())
		{
			if(HasControl())
			{
				CurrentWorldTarget += GetInputInWorldSpace() * (AimingSpeed * DeltaTime);
				FVector LocalTarget = ShootAreaTransform.InverseTransformPosition(CurrentWorldTarget);

				LocalTarget.X = Math::Clamp(LocalTarget.X, -ShootingAreaExtents.X, ShootingAreaExtents.X);
				LocalTarget.Y = Math::Clamp(LocalTarget.Y, -ShootingAreaExtents.Y, ShootingAreaExtents.Y);

				CurrentWorldTarget = ShootAreaTransform.TransformPosition(LocalTarget);

				SyncedShootLocation.Value = CurrentWorldTarget;
			}
			else
			{
				CurrentWorldTarget = SyncedShootLocation.Value;
			}

			CurrentProjectileTargetVelocity = Trajectory::CalculateVelocityForPathWithHorizontalSpeed(GunVisualizer.ShootOrigin, CurrentWorldTarget, ProjectileGravity, ProjectileHorizontalSpeed);

			FVector Normal = FVector::UpVector;
			FRotator TempRot;
			TempRot.Roll = 90;
			FVector Perpendicular1 = TempRot.RotateVector(Normal);
			FVector Perpendicular2 = Normal.CrossProduct(Perpendicular1);

			Debug::DrawDebugCircle(CurrentWorldTarget, 75, 5, FLinearColor::Red, 20, Perpendicular1, Perpendicular2);
			Trajectory::DebugDrawTrajectoryWithDestination(GunVisualizer.ShootOrigin, CurrentWorldTarget, CurrentProjectileTargetVelocity, -FVector::UpVector, ProjectileGravity);
		}
	}

	UFUNCTION(NotBlueprintCallable)
	private void OnShoot()
	{
		FHazeActorSpawnParameters Params(this);
		Params.Location = GunVisualizer.ShootOrigin;
		SpawnPoolComponent.SpawnControl(Params);
	}

	UFUNCTION()
	private void OnBaitProjectileSpawned(AHazeActor SpawnedActor, FHazeActorSpawnParameters Params)
	{
		auto BeastBait = Cast<ATundraPondBeastBait>(SpawnedActor);
		BeastBait.Initialize(CurrentProjectileTargetVelocity, ProjectileGravity, SpawnPoolComponent, this);
	}

	FVector GetInputInWorldSpace()
	{
		const FVector Up = FVector::UpVector;
		const FRotator PlayerControlRotation = Player.GetControlRotation();
		const FVector Forward = MovementInput::FixupMovementForwardVector(PlayerControlRotation, Up);	
		const FVector Right = MovementInput::FixupMovementRightVector(PlayerControlRotation, Up, Forward);

		return Forward * LifeReceivingComponent.RawVerticalInput + Right * LifeReceivingComponent.RawHorizontalInput;
	}

	void SubscribeToEvents()
	{
		LifeReceivingComponent.OnInteractStartDuringLifeGive.AddUFunction(this, n"OnShoot");
	}

	void UnsubscribeToEvents()
	{
		LifeReceivingComponent.OnInteractStartDuringLifeGive.Unbind(this, n"OnShoot");
	}
}