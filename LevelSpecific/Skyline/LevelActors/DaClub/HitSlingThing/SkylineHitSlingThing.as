event void FSkylineHitSlingThingSignature(ASkylineHitSlingThing HitSlingThing);

class ASkylineHitSlingThing : AHazeActor
{
	ASkylineHitSlingThingSpawner Spawner;

	UPROPERTY(DefaultComponent, RootComponent)
	USphereComponent Collision;
	default Collision.SphereRadius = 40.0;
	default Collision.bGenerateOverlapEvents = false;
	default Collision.SetCollisionResponseToAllChannels(ECollisionResponse::ECR_Ignore);
	default Collision.SetCollisionResponseToChannel(ECollisionChannel::ECC_WorldStatic, ECollisionResponse::ECR_Block);
	default Collision.SetCollisionResponseToChannel(ECollisionChannel::ECC_WorldDynamic, ECollisionResponse::ECR_Block);
	default Collision.SetCollisionResponseToChannel(ECollisionChannel::WorldGeometry, ECollisionResponse::ECR_Block);
	default Collision.SetCollisionResponseToChannel(ECollisionChannel::WeaponTraceMio, ECollisionResponse::ECR_Block);
	default Collision.SetCollisionResponseToChannel(ECollisionChannel::PlayerCharacter, ECollisionResponse::ECR_Block);

	UPROPERTY(DefaultComponent)
	UGravityBladeCombatTargetComponent BladeCombatTargetComp;
	default BladeCombatTargetComp.bCanRushTowards = false;
	default BladeCombatTargetComp.bOverrideTargetRange = true;
	default BladeCombatTargetComp.TargetRange = 400.0;

	UPROPERTY(DefaultComponent, Attach = BladeCombatTargetComp)
	UTargetableOutlineComponent BladeOutlineComp;

	UPROPERTY(DefaultComponent)
	UGravityWhipTargetComponent WhipTargetComp;
	default WhipTargetComp.MaximumAngle = 45.0;
	default WhipTargetComp.MaximumDistance = 1600.0;

	UPROPERTY(DefaultComponent, Attach = WhipTargetComp)
	UTargetableOutlineComponent WhipOutlineComp;

	UPROPERTY(DefaultComponent)
	UHazeCrumbSyncedActorPositionComponent SyncedPosition;
	default SyncedPosition.SyncRate = EHazeCrumbSyncRate::PlayerSynced;

	UPROPERTY(DefaultComponent)
	UHazeMovementComponent MoveComp;
	default MoveComp.bResolveMovementLocally.DefaultValue = true;

	USweepingMovementData Movement;

	UPROPERTY(DefaultComponent)
	UGravityBladeCombatResponseComponent BladeCombatResponseComp;

	UPROPERTY(DefaultComponent)
	UGravityWhipResponseComponent WhipResponseComp;
	default WhipResponseComp.GrabMode = EGravityWhipGrabMode::Sling;
	default WhipResponseComp.bAllowMultiGrab = false;

	UPROPERTY(DefaultComponent)
	UHazeListedActorComponent ListedActorComp;

	UPROPERTY(DefaultComponent)
	UCameraShakeForceFeedbackComponent CameraShakeForceFeedbackComponent;

	UPROPERTY()
	FSkylineHitSlingThingSignature OnStuck;

	UPROPERTY()
	FSkylineHitSlingThingSignature OnExpire;

	float Drag = 0.0;
	float GroundDrag = 1.0;
	float Restitution = 0.5;
	float Gravity = -3038.0;
	float HitSpeed = 3600.0; //3400
	float SlingSpeed = 3600.0; //3400

	float AfterImpactExpireTime = 0.0;
	float ExpireTime = 0.0;
	float BeforeImpactLifeTime = 3.0;
	float LastImpactTime = 0.0;
	bool bIsTriggered = false;
	bool bIsLaunched = false;
	bool bStuck = false;

	float NetworkSlowdownTimer = 0.0;
	float NetworkSlowdownDuration = 0.0;
	float AchievedSlowdown = 0.0;

	FVector PendingImpulse;
	bool bDisabledInteraction = false;

	AHazePlayerCharacter LastInteractingPlayer;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		DisableInteraction();
		Timer::SetTimer(this, n"EnableInteraction", 0.5);

//		MoveComp.AddMovementIgnoresActor(this, Game::Mio);
//		MoveComp.AddMovementIgnoresActor(this, Game::Zoe);

		SetActorControlSide(Game::Mio);

		Movement = MoveComp.SetupSweepingMovementData();

		BladeCombatResponseComp.OnHit.AddUFunction(this, n"HandleHit");
		WhipResponseComp.OnGrabbed.AddUFunction(this, n"HandleGrabbed");
		WhipResponseComp.OnReleased.AddUFunction(this, n"HandleReleased");
		WhipResponseComp.OnThrown.AddUFunction(this, n"HandleThrown");

/*	
		TListedActors<ASkylineRoboDog> RoboDog;
		RoboDog.Single.Target = this;
		OnStuck.AddUFunction(RoboDog.Single, n"HandleBallStuck");
*/
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		if (bIsLaunched)
		{
			PrintToScreen("Expire in: " + (ExpireTime - Time::GameTimeSeconds), 0.0, FLinearColor::Green);

			// Only Zoe can expire the ball, so we don't accidentally expire it at the same time as grabbing it with the whip
			if (Game::Zoe.HasControl())
			{
				if (bIsTriggered && Time::GameTimeSeconds > ExpireTime)
					CrumbExpire();
				else if (!WhipResponseComp.IsGrabbed() && Time::GameTimeSeconds > ExpireTime)
					CrumbExpire();
			}
		}
		else
		{
			return;
		}

		if (WhipResponseComp.IsGrabbed())
			return;

		if (bStuck)
			return;

		if (MoveComp.PrepareMove(Movement))
		{
			float MoveDeltaTime = DeltaSeconds;
			if (HasControl() && NetworkSlowdownDuration > 0)
			{
				float SlowdownDeltaTime = Acceleration::GetFrameMovementWithDestination(
					NetworkSlowdownTimer, DeltaSeconds,
					NetworkSlowdownDuration, 2.0, 1.0, 1.0
				);

				SlowdownDeltaTime = Math::Min(SlowdownDeltaTime, MoveDeltaTime);
				MoveDeltaTime -= SlowdownDeltaTime;
				AchievedSlowdown += SlowdownDeltaTime;
				NetworkSlowdownTimer += DeltaSeconds;
			}

			FVector Velocity = MoveComp.Velocity;
			Velocity += ConsumeImpulse();
			Velocity -= MoveComp.Velocity * (MoveComp.HasGroundContact() ? GroundDrag : Drag) * MoveDeltaTime;

			FVector Acceleration = (FVector::UpVector * Gravity);

			FVector DeltaMove = Velocity * MoveDeltaTime;
			Velocity += Acceleration * MoveDeltaTime;
			DeltaMove += Acceleration * (0.5 * Math::Square(MoveDeltaTime));

			Movement.SetRotation(DeltaMove.ToOrientationQuat());
			Movement.AddDeltaWithCustomVelocity(DeltaMove, Velocity);
			MoveComp.ApplyMove(Movement);

			FHitResult HitResult;
			if (MoveComp.GetFirstValidImpact(HitResult))
			{
				AHazePlayerCharacter HitPlayer = Cast<AHazePlayerCharacter>(HitResult.Actor);
				if (HitPlayer != nullptr)
				{
					if (HitPlayer.HasControl())
					{
						HitPlayer.DamagePlayerHealth(1.0);

						FSkylineHitSlingThingEventImpactData EventData;
						EventData.ImpactActor = HitResult.Actor;
						EventData.ImpactLocation = HitResult.ImpactPoint;
						EventData.BallActor = this;
//						USkylineHitSlingThingEventHandler::Trigger_OnImpacted(Spawner, EventData);

						CrumbImpacted(HitResult, MoveComp.PreviousVelocity.Size());
					}
				}
				else 
				{
					auto HitSlingThingResponseComp = USkylineHitSlingThingResponseComponent::Get(HitResult.Actor);

					if (HitSlingThingResponseComp != nullptr)
					{
						ActorLocation = HitResult.Location;
						ActorVelocity = FVector::ZeroVector;
						LastImpactTime = Time::GameTimeSeconds;
						bIsTriggered = false;

						FVector Direction = GetLaunchDirection(ActorLocation, HitSlingThingResponseComp.Target.ActorLocation, 300.0);
						Launch(Direction, 300.0, false);

						if (HasControl())
							CrumbHitResponseComponent(HitResult, HitSlingThingResponseComp, LastInteractingPlayer);
					}

					// Send an impact, but don't do this too often so we don't spam impacts when stuck between two things
					if (Time::GetGameTimeSince(LastImpactTime) > 0.5
						&& HitSlingThingResponseComp == nullptr)
					{
						LastImpactTime = Time::GameTimeSeconds;

						float Speed = MoveComp.PreviousVelocity.Size();
						if (Speed > 100.0 && !WhipResponseComp.IsGrabbed() && !bIsTriggered)
						{
							CameraShakeForceFeedbackComponent.ActivateCameraShakeAndForceFeedback();
							BP_Impact(HitResult, Speed);
							AddActorVisualsBlock(n"LocalImpact");
						}

						if (Game::Zoe.HasControl())
							CrumbImpacted(HitResult, Speed);
					}

					// Reflect the velocity of the ball
					if (HasControl())
					{
						auto ImpactResponseComponent = UGravityWhipImpactResponseComponent::Get(HitResult.Actor);
						if (ImpactResponseComponent != nullptr)
						{
							if (ImpactResponseComponent.bIsNonStopping)
								ActorVelocity = MoveComp.PreviousVelocity * ImpactResponseComponent.VelocityScaleAfterImpact;
							else
								ActorVelocity = Math::GetReflectionVector(MoveComp.PreviousVelocity, HitResult.Normal) * Restitution;
						}
						else
						{
							ActorVelocity = Math::GetReflectionVector(MoveComp.PreviousVelocity, HitResult.Normal) * Restitution;
						}
					}
				}
			}
/*
			auto HitResult = GetImpact();
			if (HitResult.bBlockingHit)
			{
				if (HasControl())
					CrumbImpacted(HitResult);
			}
*/

		}
	}

	UFUNCTION(CrumbFunction)
	private void CrumbHitResponseComponent(FHitResult HitResult, USkylineHitSlingThingResponseComponent ResponseCompenent, AHazePlayerCharacter PlayerInstigator)
	{
		DisableInteraction();

		FSkylineHitSlingThingEventHitResponseComponentData EventData;
		EventData.ImpactActor = HitResult.Actor;
		EventData.ImpactLocation = HitResult.ImpactPoint;
		EventData.BallActor = this;
		EventData.PlayerInstigator = PlayerInstigator;
		EventData.ResponseCompenent = ResponseCompenent;
		USkylineHitSlingThingEventHandler::Trigger_OnResponseComponentHit(Spawner, EventData);
	}

	UFUNCTION(CrumbFunction)
	private void CrumbImpacted(FHitResult HitResult, float Speed)
	{
		if (Time::GetGameTimeSince(LastImpactTime) > 0.5)
		{
			LastImpactTime = Time::GameTimeSeconds;
			if (Speed > 100.0 && !WhipResponseComp.IsGrabbed() && !bIsTriggered)
			{
				CameraShakeForceFeedbackComponent.ActivateCameraShakeAndForceFeedback();
				BP_Impact(HitResult, Speed);
			}
				
		}

		if (bIsLaunched && !bIsTriggered)
			Trigger();

		{
			FSkylineHitSlingThingEventImpactData EventData;
			EventData.ImpactActor = HitResult.Actor;
			EventData.ImpactLocation = HitResult.ImpactPoint;
			EventData.BallActor = this;
			USkylineHitSlingThingEventHandler::Trigger_OnImpacted(Spawner, EventData);
		}

		auto ResponsComp = USkylineHitSlingThingResponseComponent::Get(HitResult.Actor);
		if (ResponsComp != nullptr)
		{
		}

		auto ImpactResponseComponent = UGravityWhipImpactResponseComponent::Get(HitResult.Actor);
		if (ImpactResponseComponent != nullptr)
		{
			if (HasControl())
			{
				// Send this as a secondary crumb on the response component, because
				// the sling thing might already be destroyed on the other side and this crumb
				// won't arrive there to trigger the impact.
				FGravityWhipImpactData ImpactData;
				ImpactData.ImpactVelocity = MoveComp.PreviousVelocity;
				ImpactData.HitResult = HitResult;
				ImpactResponseComponent.CrumbImpact(ImpactData);
			}
		}

		if (bDisabledInteraction)
			EnableInteraction();

	//			ActorVelocity = Math::GetReflectionVector(MoveComp.PreviousVelocity, HitResult.Normal) * Restitution;
	}

	UFUNCTION()
	private void HandleGrabbed(UGravityWhipUserComponent UserComponent, UGravityWhipTargetComponent TargetComponent, TArray<UGravityWhipTargetComponent> OtherComponents)
	{
		DetachFromActor();

		MoveComp.RemoveMovementIgnoresActor(this);
		RemoveActorVisualsBlock(n"LocalImpact");
		ActorVelocity = FVector::ZeroVector;
		bIsTriggered = false;
		
		LastInteractingPlayer = Game::Zoe;

		// Once grabbed, zoe takes control of the actor
		SetActorControlSide(Game::Zoe);
		USkylineHitSlingThingEventHandler::Trigger_OnWhipGrab(Spawner, CreateEventData());
	}

	UFUNCTION()
	private void HandleReleased(UGravityWhipUserComponent UserComponent, UGravityWhipTargetComponent TargetComponent, FVector Impulse)
	{
		RemoveActorVisualsBlock(n"LocalImpact");
		LastInteractingPlayer = Game::Zoe;
		USkylineHitSlingThingEventHandler::Trigger_OnWhipReleased(Spawner, CreateEventData());
	}

	UFUNCTION()
	private void HandleThrown(UGravityWhipUserComponent UserComponent, UGravityWhipTargetComponent TargetComponent, FHitResult HitResult, FVector Impulse)
	{
		RemoveActorVisualsBlock(n"LocalImpact");
		WhipTargetComp.Disable(this);
		LastInteractingPlayer = Game::Zoe;

		auto Player = Cast<AHazePlayerCharacter>(UserComponent.Owner);
		MoveComp.AddMovementIgnoresActor(this, Player);
		USkylineHitSlingThingEventHandler::Trigger_OnWhipThrown(Spawner, CreateEventData());

		auto Trace = Trace::InitChannel(ECollisionChannel::PlayerAiming);
//		Trace.IgnoreActor(Player);
		FVector Start = Player.ViewLocation;
		FVector End = Player.ViewLocation + Player.ViewRotation.ForwardVector * 30000.0;

		auto AimHitResult = Trace.QueryTraceSingle(Start, End);
		if (AimHitResult.bBlockingHit)
			End = AimHitResult.ImpactPoint;

		// Check for AutoAimTargets
		auto AimComp = UPlayerAimingComponent::Get(Player);
		if (AimComp != nullptr)
		{
			FAimingSettings AimingSettings;
			AimingSettings.bUseAutoAim = true; 
//			AimingSettings.OverrideAutoAimTarget = USkylineAxisAutoAimTargetComponent;
			AimComp.StartAiming(this, AimingSettings);
			auto AimingResult = AimComp.GetAimingTarget(this);
			if (AimingResult.AutoAimTarget != nullptr)
				End = AimingResult.AutoAimTargetPoint;

			AimComp.StopAiming(this);
		}

		// Custom AutoAim to OtherPlayer
		float ViewDotToOtherPlayer = (Player.OtherPlayer.ActorCenterLocation - Player.ViewLocation).SafeNormal.DotProduct(Player.ViewRotation.ForwardVector);
		if (Math::DotToDegrees(ViewDotToOtherPlayer) < 4.0) // 7.0
			End = Player.OtherPlayer.FocusLocation;

//		Debug::DrawDebugPoint(End, 20.0, FLinearColor::Red, 1.0);

		FVector Direction = GetLaunchDirection(ActorLocation, End, SlingSpeed);
		Launch(Direction, SlingSpeed, false);

		if (!bIsTriggered)
			ExpireTime = Time::GameTimeSeconds + BeforeImpactLifeTime;
	}

	UFUNCTION()
	private void HandleHit(UGravityBladeCombatUserComponent CombatComp, FGravityBladeHitData HitData)
	{
		RemoveActorVisualsBlock(n"LocalImpact");
		BladeCombatResponseComp.AddResponseComponentDisable(this);
		LastInteractingPlayer = Game::Mio;

		DetachFromActor();

		WhipResponseComp.bGrabAttachImmediately = true;
		USkylineHitSlingThingEventHandler::Trigger_OnBladeHit(Spawner, CreateEventData());

		auto Player = Cast<AHazePlayerCharacter>(CombatComp.Owner);
		MoveComp.AddMovementIgnoresActor(this, Player);
		MoveComp.AddMovementIgnoresActor(this, Spawner);

		FVector ToPlayer = ActorLocation - Player.ActorLocation;

		auto Trace = Trace::InitChannel(ECollisionChannel::PlayerAiming);
		Trace.IgnoreActor(Player);
		FVector Start = Player.ViewLocation;
		FVector End = Player.ViewLocation + Player.ViewRotation.ForwardVector * 30000.0;

/*
		auto HitResult = Trace.QueryTraceSingle(Start, End);
		if (HitResult.bBlockingHit)
			End = HitResult.ImpactPoint;
*/


		FVector BallToTarget = End - ActorLocation;
//		Debug::DrawDebugLine(ActorLocation, ActorLocation + BallToTarget, FLinearColor::Yellow, 10.0, 1.0);

//		Debug::DrawDebugPoint(End, 20.0, FLinearColor::Green, 1.0);

/*
		FVector ConstrainedDirection = BallToTarget.ConstrainToCone(Player.ViewRotation.ForwardVector.VectorPlaneProject(FVector::UpVector), Math::DegreesToRadians(10.0));
		ConstrainedDirection.Z = BallToTarget.Z;
		ConstrainedDirection = ConstrainedDirection.ConstrainToCone(FVector::UpVector, Math::DegreesToRadians(90.0));
		End = ActorLocation + ConstrainedDirection;
*/

		FVector ConstrainedDirection = BallToTarget.VectorPlaneProject(FVector::UpVector).SafeNormal;
		End = ActorLocation + ConstrainedDirection * 4000.0;

		// Check for AutoAimTargets
		auto AimComp = UPlayerAimingComponent::Get(Player);
		if (AimComp != nullptr)
		{
			FAimingSettings AimingSettings;
			AimingSettings.bUseAutoAim = true;
			AimingSettings.OverrideAutoAimTarget = USkylineAxisAutoAimTargetComponent;
			AimComp.StartAiming(this, AimingSettings);
			auto AimingResult = AimComp.GetAimingTarget(this);
			if (AimingResult.AutoAimTarget != nullptr)
				End = AimingResult.AutoAimTargetPoint;

			AimComp.StopAiming(this);
		}

		// Custom AutoAim to OtherPlayer
		float ViewDotToOtherPlayer = (Player.OtherPlayer.ActorCenterLocation - Player.ViewLocation).VectorPlaneProject(FVector::UpVector).SafeNormal.DotProduct(Player.ViewRotation.ForwardVector.VectorPlaneProject(FVector::UpVector).SafeNormal);
		if (Math::DotToDegrees(ViewDotToOtherPlayer) < 4.0) // 7.0
			End = Player.OtherPlayer.FocusLocation;

//		Debug::DrawDebugPoint(End, 20.0, FLinearColor::Red, 1.0);

		FVector Direction = GetLaunchDirection(ActorLocation, End, HitSpeed);

		Launch(Direction, HitSpeed, true);
	
//		Trigger();
	}

	void Launch(FVector Direction, float LaunchSpeed, bool bNetworkSlowdown)
	{
		if (HasControl())
		{
			if (bNetworkSlowdown)
			{
				NetworkSlowdownTimer = 0.0;
				NetworkSlowdownDuration = Time::GetEstimatedCrumbRoundtripDelay();
			}
			else
			{
				NetworkSlowdownDuration = 0.0;
			}

			CrumbLaunch(ActorLocation, Direction, LaunchSpeed);
		}
	}

	UFUNCTION(CrumbFunction)
	void CrumbLaunch(FVector Location, FVector Direction, float LaunchSpeed)
	{
		bIsLaunched = true;

		if (!bIsTriggered)
			ExpireTime = Time::GameTimeSeconds + BeforeImpactLifeTime;

		WhipTargetComp.MaximumDistance = 2000.0;
		ActorLocation = Location;
		ActorVelocity = FVector::ZeroVector;
		PendingImpulse = FVector::ZeroVector;
		AddImpulse(Direction * LaunchSpeed);
	}

	void AddImpulse(FVector Impulse)
	{
		PendingImpulse += Impulse;
	}

	FVector ConsumeImpulse()
	{
		FVector Impulse = PendingImpulse;
		PendingImpulse = FVector::ZeroVector;
		return Impulse;
	}

	UFUNCTION()
	void DisableInteraction()
	{
		bDisabledInteraction = true;
		BladeCombatResponseComp.AddResponseComponentDisable(this);
//		BladeCombatTargetComp.Disable(this);
		WhipTargetComp.Disable(this);
	}

	UFUNCTION()
	void EnableInteraction()
	{
		bDisabledInteraction = false;
//		BladeCombatTargetComp.Enable(this);
		BladeCombatResponseComp.RemoveResponseComponentDisable(this);
		WhipTargetComp.Enable(this);
		RemoveActorVisualsBlock(n"LocalImpact");
	}

	void Trigger()
	{
		if (WhipResponseComp.IsGrabbed())
			return;
		WhipTargetComp.Disable(this);
		bIsTriggered = true;
		ExpireTime = Time::GameTimeSeconds + AfterImpactExpireTime;
		BP_Trigger();
	}

	UFUNCTION(CrumbFunction)
	void CrumbExpire()
	{
		OnExpire.Broadcast(this);
		BP_Expire();
		DestroyActor();
	}

	void Stick()
	{
		bStuck = true;
		DisableInteraction();
		OnStuck.Broadcast(this);
	}

	FHitResult GetImpact()
	{
		FHitResult HitResult;

		if (MoveComp.HasGroundContact())
			HitResult = MoveComp.GroundContact.ConvertToHitResult();

		if (MoveComp.HasWallContact())
			HitResult = MoveComp.WallContact.ConvertToHitResult();

		if (MoveComp.HasCeilingContact())
			HitResult = MoveComp.CeilingContact.ConvertToHitResult();

		return HitResult;
	}

	FVector GetLaunchDirection(FVector LaunchLocation, FVector TargetLocation, float LaunchSpeed)
	{
		FVector Direction;

		FVector ToTarget = TargetLocation - LaunchLocation;
		float LaunchSpeedSquared = LaunchSpeed * LaunchSpeed;
		float DistanceSquared = ToTarget.SizeSquared();

		float Root = LaunchSpeedSquared * LaunchSpeedSquared - Gravity * (Gravity * DistanceSquared + (2.0 * ToTarget.Z * LaunchSpeedSquared));

		float Angle = 30.0; // 45.0

		if (Root >= 0.0)
			Angle = Math::RadiansToDegrees(-Math::Atan2(Gravity * Math::Sqrt(DistanceSquared), LaunchSpeedSquared + Math::Sqrt(Root)));

		FVector PitchAxis = ToTarget.CrossProduct(FVector::UpVector).SafeNormal;

		Direction = ToTarget.RotateAngleAxis(Angle, PitchAxis).SafeNormal;

		return Direction;
	}

	UFUNCTION(BlueprintEvent)
	void BP_Trigger() { }

	UFUNCTION(BlueprintEvent)
	void BP_Impact(FHitResult HitResult, float Speed) { }

	UFUNCTION(BlueprintEvent)
	void BP_Expire() { }

	FSkylineHitSlingThingEventData CreateEventData()
	{
		FSkylineHitSlingThingEventData Data;
		Data.BallActor = this;
		return Data;
	}
};