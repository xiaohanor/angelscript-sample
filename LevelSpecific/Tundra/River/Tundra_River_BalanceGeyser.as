struct FTundra_River_BalanceGeyserPlayerShapeData
{
	UPROPERTY()
	AHazePlayerCharacter Player;

	UPROPERTY()
	ETundraShapeshiftShape Shape = ETundraShapeshiftShape::None;
}

class UTundra_River_BalanceGeyserEffectEventHandler : UHazeEffectEventHandler
{
	UFUNCTION(BlueprintEvent)
	void OnGroundSlammed () {}

	UFUNCTION(BlueprintEvent)
	void OnReturnAfterGroundSlam () {}

	UFUNCTION(BlueprintEvent)
	void OnPlayerLand (FTundra_River_BalanceGeyserPlayerShapeData Data) {}

	UFUNCTION(BlueprintEvent)
	void OnRiseAfterOtherPlatformGroundSlammed () {}

	UFUNCTION(BlueprintEvent)
	void OnReturnAfterOtherPlatformGroundSlammed () {}
}

class ATundra_River_BalanceGeyser : AHazeActor
{
	// This has a different tick group because UAnimFootTraceComponent uses the impact point of the ground contact to determine where the feet should be placed so the faux physics has to run before player movement to not make snow monkey/otter (that uses the foot trace) lag behind the platform.
	default PrimaryActorTick.TickGroup = ETickingGroup::TG_HazeInput;

	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	UFauxPhysicsTranslateComponent MoveRoot;
	default MoveRoot.bConstrainX = true;
	default MoveRoot.bConstrainY = true;
	default MoveRoot.bConstrainZ = true;
	default MoveRoot.MinZ = -50.0;
	default MoveRoot.MaxZ = 100000.0;
	default MoveRoot.ConstrainBounce = 0.0;
	default MoveRoot.PrimaryComponentTick.TickGroup = ETickingGroup::TG_HazeInput;

	UPROPERTY(DefaultComponent, Attach = MoveRoot)
	USceneComponent PlatformRoot;

	UPROPERTY(DefaultComponent, Attach = PlatformRoot)
	UStaticMeshComponent PlatformVisualComp;
	default PlatformVisualComp.CollisionEnabled = ECollisionEnabled::NoCollision;

	UPROPERTY(DefaultComponent, Attach = PlatformRoot)
	UStaticMeshComponent PlatformColliderComp;
	default PlatformColliderComp.bHiddenInGame = true;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent GeyserRoot;

	UPROPERTY(DefaultComponent, Attach = GeyserRoot)
	UStaticMeshComponent GeyserMeshComp;

	UPROPERTY(DefaultComponent, Attach = Root)
	UBillboardComponent WaterSurface;
	default WaterSurface.RelativeLocation = FVector(0,0,400);

	UPROPERTY(DefaultComponent, Attach = Root)
	UBillboardComponent HighPoint;
	default HighPoint.RelativeLocation = FVector(0,0,2000);

	UPROPERTY(DefaultComponent, Attach = Root)
	UBillboardComponent LowPoint;
	default LowPoint.RelativeLocation = FVector(0,0,0);

	UPROPERTY(DefaultComponent)
	UMovementImpactCallbackComponent ImpactCallbackComp;

	UPROPERTY(DefaultComponent)
	UTundraPlayerSnowMonkeyGroundSlamResponseComponent GroundSlamResponse;

	UPROPERTY(DefaultComponent, Attach=PlatformRoot)
	USquishTriggerBoxComponent PlatformSquishBox;
	default PlatformSquishBox.Polarity = ESquishTriggerBoxPolarity::Down;
	default PlatformSquishBox.BoxExtent = FVector(300.0, 300.0, 70.0);

	UPROPERTY(DefaultComponent, Attach=GeyserRoot)
	USquishTriggerBoxComponent GeyserSquishBox;
	default GeyserSquishBox.Polarity = ESquishTriggerBoxPolarity::Up;
	default GeyserSquishBox.BoxExtent = FVector(300.0, 300.0, 70.0);

	UPROPERTY(EditInstanceOnly, Category = "Tree Interaction Settings")
	bool bRaisedAtStart = true;

	UPROPERTY(EditAnywhere, Category = "Tree Interaction Settings")
	float PlatformMoveSpeed = 2000;

	UPROPERTY(EditAnywhere, Category = "Forces")
	float GravityForce = 50000.0;

	UPROPERTY(EditAnywhere, Category = "Forces")
	float MaxGeyserForce = GravityForce * 1.2;

	UPROPERTY(EditAnywhere, Category = "Forces")
	float SmallShapeImpulse = 400.0;

	UPROPERTY(EditAnywhere, Category = "Forces")
	float PlayerShapeImpulse = 1000.0;

	UPROPERTY(EditAnywhere, Category = "Forces")
	float BigShapeImpulse = 2000.0;

	const float MonkeyGroundSlamImpulse = 10000.0;

	UPROPERTY(EditAnywhere, Category = "Forces")
	float SmallShapeWeight = 25.0;

	UPROPERTY(EditAnywhere, Category = "Forces")
	float PlayerShapeWeight = 50.0;

	UPROPERTY(EditAnywhere, Category = "Forces")
	float BigShapeWeight = 100.0;

	UPROPERTY(EditAnywhere, Category = "Forces")
	float SmallShapeLaunchForce = 500.0;

	UPROPERTY(EditAnywhere, Category = "Forces")
	float PlayerShapeLaunchForce = 800.0;

	UPROPERTY(EditAnywhere, Category = "Forces")
	float BigShapeLaunchForce = 0.0;

	UPROPERTY(EditAnywhere, Category = "Forces")
	float DefaultPlatformLaunchForce = 2000.0;

	UPROPERTY(EditAnywhere, Category = "Forces")
	float SmallShapePlatformLaunchForce = 2000.0;

	UPROPERTY(EditAnywhere, Category = "Forces")
	float PlayerShapePlatformLaunchForce = 1200.0;

	UPROPERTY(EditAnywhere, Category = "Forces")
	float BigShapePlatformLaunchForce = 500.0;

	UPROPERTY(EditAnywhere, Category = "Forces")
	float SmallShapeLaunchSpeedThreshold = 500;

	UPROPERTY(EditAnywhere, Category = "Forces")
	float PlayerShapeLaunchSpeedThreshold = 500;

	UPROPERTY(EditAnywhere, Category = "Forces")
	float BigShapeLaunchSpeedThreshold = 500;

	UPROPERTY(EditAnywhere, Category = "Forces")
	float SmallShapeGeyserLiftSpeed = 10000;

	UPROPERTY(EditAnywhere, Category = "Forces")
	float PlayerShapeGeyserLiftSpeed = 7500;

	UPROPERTY(EditAnywhere, Category = "Forces")
	float BigShapeGeyserLiftSpeed = 5000;

	UPROPERTY(EditAnywhere)
	float GeyserLiftRadius = 100;

	/* If a player impacts the bottom of the platform, was just within the geyser radius and their vertical speed is greater or equal to this value. */
	UPROPERTY(EditAnywhere)
	float KillPlayerVelocityThreshold = 300.0;

	UPROPERTY(EditAnywhere)
	float PlatformStuckTime = 2;

	float LaunchSpeedThreshold = 500;

	
	

	UPROPERTY(EditDefaultsOnly)
	FHazeTimeLike MoveUpDownAnimation;
	default MoveUpDownAnimation.Duration = 6;
	default MoveUpDownAnimation.Curve.AddDefaultKey(0,0);
	default MoveUpDownAnimation.Curve.AddDefaultKey(3, 1);
	default MoveUpDownAnimation.Curve.AddDefaultKey(6,0);

	UPROPERTY(EditDefaultsOnly)
	TArray<UNiagaraComponent> GeyserParticles;

	UTundraLifeReceivingComponent LifeReceivingComp;
	TPerPlayer<bool> bPlayerImpact;
	TPerPlayer<bool> bPlayerInGeyser;
	TPerPlayer<bool> bPlayerWasInGeyser;
	TPerPlayer<UTundraPlayerShapeshiftingComponent> ShapeshiftComps;
	TPerPlayer<UPlayerMovementComponent> MovementComps;

	bool bTriggered = false;
	float Depth;
	float CurrentWeight = 0;
	float MoveAlpha;
	float StuckTime = 0;
	float MonkeySlamTime;
	bool bIsTravelingUp = false;
	bool bApplyUpwardsImpulse = false;
	float MoveRootLastFrame;

	UPROPERTY(EditInstanceOnly)
	ATundra_River_BalanceGeyser OtherGeyser;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		PlatformRoot.GetChildrenComponentsByClass(UNiagaraComponent, false, GeyserParticles);

		GeyserParticles[0].Activate();

		Depth = WaterSurface.RelativeLocation.Z;
		
		ImpactCallbackComp.AddComponentUsedForImpacts(PlatformColliderComp);
		ImpactCallbackComp.OnGroundImpactedByPlayer.AddUFunction(this, n"OnPlayerGroundImpact");
		ImpactCallbackComp.OnGroundImpactedByPlayerEnded.AddUFunction(this, n"OnPlayerGroundImpactEnd");
		ImpactCallbackComp.OnCeilingImpactedByPlayer.AddUFunction(this, n"OnPlayerCeilingImpact");
		
		GroundSlamResponse.OnGroundSlam.AddUFunction(this, n"OnGroundSlam");
		
		for(AHazePlayerCharacter Player : Game::Players)
			ShapeshiftComps[Player] = UTundraPlayerShapeshiftingComponent::Get(Player);
	}

	ETundraShapeshiftShape GetShape(AHazePlayerCharacter Player)
	{
		if(ShapeshiftComps[Player] == nullptr)
			ShapeshiftComps[Player] = UTundraPlayerShapeshiftingComponent::Get(Player);

		return ShapeshiftComps[Player].CurrentShapeType;
	}

	UPlayerMovementComponent GetMovementComponent(AHazePlayerCharacter Player)
	{
		if(MovementComps[Player] == nullptr)
			MovementComps[Player] = UPlayerMovementComponent::Get(Player);

		return MovementComps[Player];
	}

	UFUNCTION()
	private void OnPlayerCeilingImpact(AHazePlayerCharacter Player)
	{
		if(bPlayerWasInGeyser[Player])
			Player.KillPlayer();
	}

	UFUNCTION()
	private void OnGroundSlam(ETundraPlayerSnowMonkeyGroundSlamType GroundSlamType, FVector PlayerLocation)
	{
		if(PlayerLocation.Z < MoveRoot.WorldLocation.Z)
			return;
		
		if(StuckTime > 0)
		{
			StuckTime = PlatformStuckTime;
			return;
		}

		MoveRoot.ApplyImpulse(MoveRoot.WorldLocation, FVector::DownVector * MonkeyGroundSlamImpulse);
		if(MoveRoot.RelativeLocation.Z > 0)
		{
			MonkeySlamTime = Time::GameTimeSeconds;
			OtherGeyser.OnOtherGeyserGroundSlammed();
		}

		UTundra_River_BalanceGeyserEffectEventHandler::Trigger_OnGroundSlammed(this);
	}

	UFUNCTION()
	private void OnPlayerGroundImpact(AHazePlayerCharacter Player)
	{
		bPlayerImpact[Player] = true;
		float Impulse = 0;
		ETundraShapeshiftShape Shape = GetShape(Player);

		if(Shape == ETundraShapeshiftShape::Small)
		{
			Impulse = SmallShapeImpulse;
		}
		else if(Shape == ETundraShapeshiftShape::Player)
		{
			Impulse = PlayerShapeImpulse;
		}
		else if(Shape == ETundraShapeshiftShape::Big)
		{
			Impulse = BigShapeImpulse;
		}
		else
			devError("Forgot to add case");

		MoveRoot.ApplyImpulse(MoveRoot.WorldLocation, FVector::DownVector * Impulse);
		OtherGeyser.MoveRoot.ApplyImpulse(OtherGeyser.MoveRoot.WorldLocation, FVector::UpVector * Impulse);

		FTundra_River_BalanceGeyserPlayerShapeData Data;
		Data.Player = Player;
		Data.Shape = Shape;

		UTundra_River_BalanceGeyserEffectEventHandler::Trigger_OnPlayerLand(this, Data);
	}

	UFUNCTION()
	private void OnPlayerGroundImpactEnd(AHazePlayerCharacter Player)
	{
		bPlayerImpact[Player] = false;
	}

	float GetMiddlePoint()
	{
		return (LowPoint.RelativeLocation.Z + HighPoint.RelativeLocation.Z) / 2.0;
	}

	float GetDesiredHeight()
	{
		return GetMiddlePoint() - CurrentWeight + OtherGeyser.CurrentWeight;
	}

	void OnOtherGeyserGroundSlammed()
	{
		float ImpulseStrength = DefaultPlatformLaunchForce;
		for(AHazePlayerCharacter Player : Game::Players)
		{
			if(!bPlayerImpact[Player])
				continue;

			float Force;
			ETundraShapeshiftShape Shape = GetShape(Player);
			if(Shape== ETundraShapeshiftShape::Small)
			{
				ImpulseStrength = SmallShapePlatformLaunchForce;
				LaunchSpeedThreshold = SmallShapeLaunchSpeedThreshold;
			}
			else if(Shape== ETundraShapeshiftShape::Player)
			{
				ImpulseStrength = PlayerShapePlatformLaunchForce;
				LaunchSpeedThreshold = PlayerShapeLaunchSpeedThreshold;
			}
			else if(Shape== ETundraShapeshiftShape::Big)
			{
				ImpulseStrength = BigShapePlatformLaunchForce;
				LaunchSpeedThreshold = BigShapeLaunchSpeedThreshold;
			}
		}

		MoveRoot.ApplyImpulse(OtherGeyser.MoveRoot.WorldLocation, FVector::UpVector * ImpulseStrength);
		bIsTravelingUp = false;
		bApplyUpwardsImpulse = true;
		MoveRootLastFrame = MoveRoot.RelativeLocation.Z;

		UTundra_River_BalanceGeyserEffectEventHandler::Trigger_OnRiseAfterOtherPlatformGroundSlammed(this);
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		if(StuckTime > 0)
		{
			StuckTime -= DeltaTime;

			// Trigger the return just a little bit early
			if(StuckTime <= 0.2)
				UTundra_River_BalanceGeyserEffectEventHandler::Trigger_OnReturnAfterGroundSlam(this);

			return;
		}

		CheckPlayersInGeyser(DeltaTime);

		// Apply gravity
		MoveRoot.ApplyForce(MoveRoot.WorldLocation, FVector::DownVector * GravityForce);
		
		ApplyPlayerWeight();
		
		if(MoveRoot.RelativeLocation.Z < LowPoint.RelativeLocation.Z && Time::GameTimeSeconds - MonkeySlamTime < 2)
		{
			MoveRoot.SetRelativeLocation(FVector(0, 0, LowPoint.RelativeLocation.Z));
			StuckTime = PlatformStuckTime;
		}

		if(bTriggered)
		{
			float SineRotate = Math::Sin(Time::GetGameTimeSeconds() * 30) * 1.25;
			PlatformVisualComp.RelativeRotation = FRotator(Math::Sin(Time::GetGameTimeSeconds() * 10), 0, Math::Sin(Time::GetGameTimeSeconds() * 5)) * SineRotate;
		}
		else
		{
			float SineRotate = Math::Sin(Time::GetGameTimeSeconds() * 50) * 0.75;
			PlatformVisualComp.RelativeRotation = FRotator(1, 0, 1) * SineRotate;
		}


		FVector LocalOffset = GeyserParticles[0].GetWorldTransform().InverseTransformPosition(GeyserRoot.WorldLocation);
		GeyserParticles[0].SetVectorParameter(n"BeamEnd", LocalOffset);

		ApplyGeyserForce(DeltaTime, GetDesiredHeight());

		if(MoveRoot.GetVelocity().Z < LaunchSpeedThreshold)
		{
			if(bIsTravelingUp && bApplyUpwardsImpulse)
			{
				bApplyUpwardsImpulse = false;
				bIsTravelingUp = false;
				ApplyGroundSlamImpulse();
			}
		}
		else
			bIsTravelingUp = true;

		MoveRootLastFrame = MoveRoot.RelativeLocation.Z;
	}

	void ApplyGroundSlamImpulse()
	{
		for(AHazePlayerCharacter Player : Game::Players)
		{
			if(!bPlayerImpact[Player])
				continue;

			float Force = 0;
			ETundraShapeshiftShape Shape = GetShape(Player);

			if(Shape == ETundraShapeshiftShape::Small)
			{
				Force = SmallShapeLaunchForce;
			}
			else if(Shape == ETundraShapeshiftShape::Player)
			{
				Force = PlayerShapeLaunchForce;
			}
			else if(Shape == ETundraShapeshiftShape::Big)
			{
				Force = BigShapeLaunchForce;
			}

			Player.AddMovementImpulse(FVector::UpVector * Force);
		}
	}

	void ApplyPlayerWeight()
	{
		CurrentWeight = 0;

		for(AHazePlayerCharacter Player : Game::Players)
		{
			if(!bPlayerImpact[Player])
				continue;

			ETundraShapeshiftShape Shape = GetShape(Player);
			float Force;
			if(Shape == ETundraShapeshiftShape::Small)
			{
				CurrentWeight += SmallShapeWeight;
			}
			else if(Shape == ETundraShapeshiftShape::Player)
			{
				CurrentWeight += PlayerShapeWeight;
			}
			else if(Shape == ETundraShapeshiftShape::Big)
			{
				CurrentWeight += BigShapeWeight;
			}
		}
	}

	void ApplyGeyserForce(float DeltaTime, float Height)
	{
		float Distance = Height - MoveRoot.RelativeLocation.Z;
		float MaxDistance = HighPoint.RelativeLocation.Z - LowPoint.RelativeLocation.Z;
		float Force = Math::Lerp(GravityForce, MaxGeyserForce, Distance / MaxDistance);
		MoveRoot.ApplyForce(MoveRoot.WorldLocation, FVector::UpVector * Force);
	}

	void CheckPlayersInGeyser(float DeltaTime)
	{
		for(auto Player : Game::Players)
		{
			float Dist = Player.ActorLocation.Dist2D(GeyserRoot.WorldLocation, FVector::UpVector);
			if(Dist < GeyserLiftRadius && Player.ActorLocation.Z < PlatformRoot.WorldLocation.Z)
			{
				bPlayerInGeyser[Player] = true;
				bPlayerWasInGeyser[Player] = true;

				float Impulse = 0;
				ETundraShapeshiftShape Shape = GetShape(Player);
				if(Shape == ETundraShapeshiftShape::Small)
				{
					Impulse = SmallShapeGeyserLiftSpeed;
				}
				else if(Shape == ETundraShapeshiftShape::Player)
				{
					Impulse = PlayerShapeGeyserLiftSpeed;
				}
				else if(Shape == ETundraShapeshiftShape::Big)
				{
					Impulse = BigShapeGeyserLiftSpeed;
				}
				
				Player.AddMovementImpulse(FVector::UpVector * (Impulse * DeltaTime));
			}
			else
			{
				bPlayerInGeyser[Player] = false;

				UPlayerMovementComponent MoveComp = GetMovementComponent(Player);
				if(bPlayerWasInGeyser[Player] && MoveComp.VerticalSpeed < KillPlayerVelocityThreshold)
				{
					bPlayerWasInGeyser[Player] = false;
				}
			}
		}
	}
};