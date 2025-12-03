event void FSkylineBasketballSignature(ASkylineBasketball Basketball);

struct FSkylineBasketballEventData
{
	UPROPERTY()
	ASkylineBasketball Basketball;
}

struct FSkylineBasketballImpactData
{
	UPROPERTY()
	ASkylineBasketball Basketball;

	UPROPERTY()
	AActor ImpactActor;

	UPROPERTY()
	FVector ImpactLocation;
};

UCLASS(Abstract)
class USkylineBasketballEventHandler : UHazeEffectEventHandler
{
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnBladeHit(FSkylineBasketballEventData EventData)
	{
	}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnWhipGrab(FSkylineBasketballEventData EventData)
	{
	}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnWhipReleased(FSkylineBasketballEventData EventData)
	{
	}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnWhipThrown(FSkylineBasketballEventData EventData)
	{
	}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnImpacted(FSkylineBasketballImpactData EventData)
	{
	}
};

class ASkylineBasketball : AHazeActor
{
	ASkylineBasketballSpawner Spawner;

	UPROPERTY(DefaultComponent, RootComponent)
	USphereComponent Collision;
	default Collision.SphereRadius = 20.0;
	default Collision.bGenerateOverlapEvents = false;
	default Collision.SetCollisionResponseToAllChannels(ECollisionResponse::ECR_Ignore);
	default Collision.SetCollisionResponseToChannel(ECollisionChannel::ECC_WorldStatic, ECollisionResponse::ECR_Block);
	default Collision.SetCollisionResponseToChannel(ECollisionChannel::ECC_WorldDynamic, ECollisionResponse::ECR_Block);
	default Collision.SetCollisionResponseToChannel(ECollisionChannel::WorldGeometry, ECollisionResponse::ECR_Block);
	default Collision.SetCollisionResponseToChannel(ECollisionChannel::WeaponTraceMio, ECollisionResponse::ECR_Block);
	default Collision.SetCollisionResponseToChannel(ECollisionChannel::PlayerCharacter, ECollisionResponse::ECR_Block);

	UPROPERTY(DefaultComponent)
	USceneComponent Pivot;

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
	USweepingMovementData Movement;

	UPROPERTY(DefaultComponent)
	UGravityBladeCombatResponseComponent BladeCombatResponseComp;

	UPROPERTY(DefaultComponent)
	UGravityWhipResponseComponent WhipResponseComp;
	default WhipResponseComp.GrabMode = EGravityWhipGrabMode::Sling;
	default WhipResponseComp.bAllowMultiGrab = false;

	UPROPERTY(DefaultComponent)
	UHazeListedActorComponent ListedActorComp;

	UPROPERTY()
	FSkylineBasketballSignature OnStuck;

	UPROPERTY()
	FSkylineBasketballSignature OnExpire;

	float Drag = 0.0;
	float GroundDrag = 1.0;
	float Restitution = 0.76;
	float Gravity = -980.0 * 2.0;
	float HitSpeed = 2600.0;
	float SlingSpeed = 2600.0;

	float AfterImpactExpireTime = 5.0;
	float ExpireTime = 5.0;
	float BeforeImpactLifeTime = 3.0;
	bool bIsTriggered = false;
	bool bIsLaunched = false;
	bool bStuck = false;

	FVector PendingImpulse;
	bool bDisabledInteraction = false;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		SetActorControlSide(Game::Zoe);

		Movement = MoveComp.SetupSweepingMovementData();

		BladeCombatResponseComp.OnHit.AddUFunction(this, n"HandleHit");
		WhipResponseComp.OnGrabbed.AddUFunction(this, n"HandleGrabbed");
		WhipResponseComp.OnReleased.AddUFunction(this, n"HandleReleased");
		WhipResponseComp.OnThrown.AddUFunction(this, n"HandleThrown");
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
			if (HasControl())
			{
				FVector Velocity = MoveComp.Velocity;

				FVector Acceleration = (FVector::UpVector * Gravity)
									 - MoveComp.Velocity * (MoveComp.HasGroundContact() ? GroundDrag : Drag);

				Velocity += Acceleration * DeltaSeconds
						 + ConsumeImpulse();

				FVector DeltaMove = Velocity * DeltaSeconds;

				Movement.SetRotation(DeltaMove.ToOrientationQuat());
				Movement.AddDelta(DeltaMove);
			}
			// Remote update
			else
			{
				Movement.ApplyCrumbSyncedAirMovement();
			}

			MoveComp.ApplyMove(Movement);

			auto HitResult = GetImpact();
			if (HitResult.bBlockingHit)
			{
				if (HasControl())
					CrumbImpacted(HitResult);
			}

		}
	}

	UFUNCTION(CrumbFunction)
	private void CrumbImpacted(FHitResult HitResult)
	{
		float Speed = MoveComp.PreviousVelocity.Size();
		if (Speed > 100.0)
			BP_Impact(HitResult, Speed);

		if (bIsLaunched && !bIsTriggered)
			Trigger();

		{
			FSkylineBasketballImpactData EventData;
			EventData.ImpactActor = HitResult.Actor;
			EventData.ImpactLocation = HitResult.ImpactPoint;
			EventData.Basketball = this;
			USkylineBasketballEventHandler::Trigger_OnImpacted(this, EventData);
		}

		auto ImpactedPlayer = Cast<AHazePlayerCharacter>(HitResult.Actor);
		if (ImpactedPlayer != nullptr)
		{
			ImpactedPlayer.DamagePlayerHealth(1.0);
		}

		FVector Velocity = MoveComp.PreviousVelocity;

		auto BasketballResponsComp = USkylineBasketballResponseComponent::Get(HitResult.Actor);
		if (BasketballResponsComp != nullptr)
		{
			Velocity = BasketballResponsComp.GetDampedVelocity(Velocity);
		}

		auto WhipImpactResponseComp = UGravityWhipImpactResponseComponent::Get(HitResult.Actor);
		if (WhipImpactResponseComp != nullptr)
		{
			if (HasControl())
			{
				// Send this as a secondary crumb on the response component, because
				// the sling thing might already be destroyed on the other side and this crumb
				// won't arrive there to trigger the impact.
				FGravityWhipImpactData ImpactData;
				ImpactData.ImpactVelocity = Velocity;
				ImpactData.HitResult = HitResult;
				WhipImpactResponseComp.CrumbImpact(ImpactData);
			}

			if (WhipImpactResponseComp.bIsNonStopping)
			{
				if (HasControl())
					Velocity = Velocity * WhipImpactResponseComp.VelocityScaleAfterImpact;
			}
			else
			{
				if (HasControl())
					Velocity = Math::GetReflectionVector(Velocity, HitResult.Normal) * Restitution;
			}
		}
		else
		{
			if (HasControl())
				Velocity = Math::GetReflectionVector(Velocity, HitResult.Normal) * Restitution;
		}

		if (bDisabledInteraction)
			EnableInteraction();


		ActorVelocity = Velocity;
	//			ActorVelocity = Math::GetReflectionVector(MoveComp.PreviousVelocity, HitResult.Normal) * Restitution;
	}

	UFUNCTION()
	private void HandleGrabbed(UGravityWhipUserComponent UserComponent, UGravityWhipTargetComponent TargetComponent, TArray<UGravityWhipTargetComponent> OtherComponents)
	{
		MoveComp.RemoveMovementIgnoresActor(this);
		ActorVelocity = FVector::ZeroVector;
		bIsTriggered = false;

		// Once grabbed, zoe takes control of the actor
		SetActorControlSide(Game::Zoe);
		USkylineBasketballEventHandler::Trigger_OnWhipGrab(this, CreateEventData());
	}

	UFUNCTION()
	private void HandleReleased(UGravityWhipUserComponent UserComponent, UGravityWhipTargetComponent TargetComponent, FVector Impulse)
	{
		USkylineBasketballEventHandler::Trigger_OnWhipReleased(this, CreateEventData());
	}

	UFUNCTION()
	private void HandleThrown(UGravityWhipUserComponent UserComponent, UGravityWhipTargetComponent TargetComponent, FHitResult HitResult, FVector Impulse)
	{
		auto Player = Cast<AHazePlayerCharacter>(UserComponent.Owner);
		MoveComp.AddMovementIgnoresActor(this, Player);
		USkylineBasketballEventHandler::Trigger_OnWhipThrown(this, CreateEventData());

		auto Trace = Trace::InitChannel(ECollisionChannel::PlayerAiming);
//		Trace.IgnoreActor(Player);
		FVector Start = Player.ViewLocation;
		FVector End = Player.ViewLocation + Player.ViewRotation.ForwardVector * 20000.0;

		auto AimHitResult = Trace.QueryTraceSingle(Start, End);
		if (AimHitResult.bBlockingHit)
			End = AimHitResult.ImpactPoint;

		FVector Direction = GetLaunchDirection(ActorLocation, End, SlingSpeed);
		Launch(Direction, SlingSpeed);

		if (!bIsTriggered)
			ExpireTime = Time::GameTimeSeconds + BeforeImpactLifeTime;
	}

	UFUNCTION()
	private void HandleHit(UGravityBladeCombatUserComponent CombatComp, FGravityBladeHitData HitData)
	{
		WhipResponseComp.bGrabAttachImmediately = true;
		USkylineBasketballEventHandler::Trigger_OnBladeHit(this, CreateEventData());

		auto Player = Cast<AHazePlayerCharacter>(CombatComp.Owner);
		MoveComp.AddMovementIgnoresActor(this, Player);

		auto Trace = Trace::InitChannel(ECollisionChannel::PlayerAiming);
//		Trace.IgnoreActor(Player);
		FVector Start = Player.ViewLocation;
		FVector End = Player.ViewLocation + Player.ViewRotation.ForwardVector * 20000.0;

		auto HitResult = Trace.QueryTraceSingle(Start, End);
		if (HitResult.bBlockingHit)
			End = HitResult.ImpactPoint;

		// Prevent direction into ground
		End = FVector(End.X, End.Y, Math::Max(ActorLocation.Z + Collision.SphereRadius + 10.0, End.Z));

//		Debug::DrawDebugPoint(End, 20.0, FLinearColor::Green, 1.0);

		FVector Direction = GetLaunchDirection(ActorLocation, End, HitSpeed);

		Launch(Direction, HitSpeed);
	
//		Trigger();
	}

	void Launch(FVector Direction, float LaunchSpeed)
	{
		bIsLaunched = true;

		if (!bIsTriggered)
			ExpireTime = Time::GameTimeSeconds + BeforeImpactLifeTime;

		WhipTargetComp.MaximumDistance = 2000.0;
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

	void DisableInteraction()
	{
		bDisabledInteraction = true;
		BladeCombatTargetComp.Disable(this);
		WhipTargetComp.Disable(this);
	}

	void EnableInteraction()
	{
		bDisabledInteraction = false;
		BladeCombatTargetComp.Enable(this);
		WhipTargetComp.Enable(this);
	}

	void Trigger()
	{
		if (WhipResponseComp.IsGrabbed())
			return;
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

		float Angle = 30.0;

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

	FSkylineBasketballEventData CreateEventData()
	{
		FSkylineBasketballEventData Data;
		Data.Basketball = this;
		return Data;
	}
};