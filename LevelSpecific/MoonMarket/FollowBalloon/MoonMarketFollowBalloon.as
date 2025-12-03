event void FMoonMarketOnBalloonPoppedEvent(AHazePlayerCharacter InstigatingPlayer);

class AMoonMarketFollowBalloon : AMoonMarketInteractableActor
{
	default InteractComp.bUseLazyTriggerShapes = true;
	default InteractableTag = EMoonMarketInteractableTag::Balloon;
	default CompatibleInteractions.Add(EMoonMarketInteractableTag::Balloon);
	//default CompatibleInteractions.Add(EMoonMarketInteractableTag::Lantern);
	//default CompatibleInteractions.Add(EMoonMarketInteractableTag::FlowerHat);
	//default CompatibleInteractions.Add(EMoonMarketInteractableTag::Wand);

	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	UStaticMeshComponent MeshComp;

	UPROPERTY(DefaultComponent)
	USceneComponent AutoGroundAttach;
	bool bGroundAttachLocationFound = false;

	UPROPERTY(DefaultComponent, Attach = MeshComp)
	USphereComponent Collider;

	UPROPERTY(DefaultComponent)
	UHazeListedActorComponent ListComp;

	UPROPERTY(DefaultComponent)
	UTemporalLogTransformLoggerComponent TransformLoggerComp;

	UPROPERTY(DefaultComponent)
	UMoonMarketBouncyBallResponseComponent BallResponseComp;

	UPROPERTY(DefaultComponent)
	UFireworksResponseComponent FireworkResponseComp;

	UPROPERTY(DefaultComponent)
	UMoonMarketThunderStruckComponent ThunderResponseComp;

	UPROPERTY(DefaultComponent)
	UCableComponent String;
	default String.bAttachEnd = true;
	default String.CableLength = 150;
	default String.CableWidth = 2;
	default String.NumSegments = 10;

	UPROPERTY(EditDefaultsOnly)
	UNiagaraSystem PopBalloonEffect;

	UPROPERTY(EditInstanceOnly)
	bool bActivateAfterTownComplete = false;
	
	UPROPERTY(EditDefaultsOnly)
	const float LiftStrength = 400;

	UPROPERTY(EditDefaultsOnly)
	const float PopBalloonHeight = 20000;

	UPROPERTY(EditDefaultsOnly)
	const float SwaySpeed = 2;

	UPROPERTY(EditDefaultsOnly)
	const float SwayStrength = 20;

	FHazeAcceleratedFloat RespawnSize;
	float RespawnTime;
	bool bFinishedRespawn = true;
	bool bIsPopped = false;
	bool bCanRespawn = true;

	float RandomSwayOffset;

	FHazeAcceleratedVector CurrentWindStrength;


	const float MaxVerticalAcceleration = 250;
	const float TimeToReachMaxVerticalAcceleration = 2;

	//How long you have to run for the string attach to use the hand socket location instead of player center location
	const float MaxGroundedRunTime = 2;

	//How quickly should the string start using the player center location instead of hand socket location when you stop running?
	const float StopRunLerpInterpSpeed = 3;

	//How long has the player been running without dashing, stopping or turning?
	float PlayerRunTime = 0;

	//Prevent snapping when switching string origin location
	const float StringLocationLerpDuration = 0.1;

	//How big must the balloon's horizontal velocity be for an impulse to be applied?
	const float HorizontalImpulseMinVelocity = 2;

	UHazeMovementComponent PlayerMoveComp;
	UPlayerStepDashComponent PlayerDashComp;
	FVector PlayerHorizontalVelocityLastFrame;

	FVector OriginalLocation;
	FHazeAcceleratedVector CurrentStringAttachLocation;
	FHazeAcceleratedVector HorizontalVelocity;
	FHazeAcceleratedVector VerticalAcceleration;
	FHazeAcceleratedRotator AccRot;

	bool bCollected = false;
	bool bIsColliding = false;

	FMoonMarketOnBalloonPoppedEvent OnPoppedEvent;

	const FVector GetStringAttachLocation() const
	{
		if(InteractingPlayer != nullptr)
		{
			float LerpAlpha = PlayerRunTime  / MaxGroundedRunTime;
			return Math::Lerp(InteractingPlayer.ActorCenterLocation, InteractingPlayer.Mesh.GetSocketLocation(n"LeftHand"), LerpAlpha);
		}
		else if(String.AttachedComponent != nullptr)
		{
			if(String.AttachEndToSocketName != "None")
				return String.AttachedComponent.GetSocketLocation(String.AttachEndToSocketName);
			return String.AttachedComponent.WorldLocation;
		}
		
		return AutoGroundAttach.WorldLocation;
	}

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Super::BeginPlay();
		RandomSwayOffset = Math::RandRange(0, 200);
		AccRot.SnapTo(ActorRotation);
		InteractComp.OnInteractionStarted.AddUFunction(this, n"OnInteractionStarted");
		BallResponseComp.OnHitByBallEvent.AddUFunction(this, n"OnHitByBall");
		FireworkResponseComp.OnFireWorksImpact.AddUFunction(this, n"OnHitByFirework");
		ThunderResponseComp.OnStruckByThunder.AddUFunction(this, n"OnStruckByThunder");
		OriginalLocation = ActorLocation;
		
		FVector GroundAttachLocation = AutoGroundAttach.WorldLocation;
		AutoGroundAttach.SetAbsolute(true);
		AutoGroundAttach.SetWorldLocation(GroundAttachLocation);

		Attach();
		RespawnSize.SnapTo(1);
	}

	UFUNCTION()
	private void OnHitByFirework(FMoonMarketFireworkImpactData Data)
	{
		Pop(Data.InstigatingPlayer);
	}

	UFUNCTION()
	private void OnStruckByThunder(FMoonMarketThunderStruckData Data)
	{
		Pop(Data.InstigatingPlayer);
	}

	UFUNCTION()
	private void OnHitByBall(FMoonMarketBouncyBallHitData Data)
	{
		Pop(Data.InstigatingPlayer);
	}

	void Attach()
	{
		String.SetRelativeLocation(FVector(0, 0, 0));
		String.SetAttachEndToComponent(AutoGroundAttach, NAME_None);

		String.EndLocation = FVector::ZeroVector;
		String.bAttachEnd = true;
		CurrentStringAttachLocation.SnapTo(GetStringAttachLocation());
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		if(bIsPopped)
			return;

		if(!bFinishedRespawn)
		{
			RespawnSize.SpringTo(1, 20, 0.6, DeltaTime);
			
			if(Time::GetGameTimeSince(RespawnTime) > 2)
			{
				bFinishedRespawn = true;
				RespawnSize.SnapTo(1);
			}
			
			SetActorScale3D(FVector::OneVector * RespawnSize.Value);

		}

		float DistanceToPlayers = Game::GetDistanceFromLocationToClosestPlayer(ActorLocation);
		if (!String.bAttachEnd || DistanceToPlayers < 7000)
		{
			HandleMovement(DeltaTime);
			HandleRotation(DeltaTime);

			if(ActorLocation.Z > OriginalLocation.Z + PopBalloonHeight)
				Pop(nullptr);
		}
	}

	void AddImpulse(FVector Impulse)
	{
		VerticalAcceleration.Value += FVector::UpVector * Impulse.Z;
		HorizontalVelocity.Value += Impulse.VectorPlaneProject(FVector::UpVector);
	}

	void HandleMovement(float DeltaTime)
	{
		if(!String.bAttachEnd && bIsColliding)
			return;

		VerticalAcceleration.AccelerateTo(FVector::UpVector * MaxVerticalAcceleration, TimeToReachMaxVerticalAcceleration, DeltaTime);

		if(InteractingPlayer == nullptr)
		{
			float Noise1 = Math::PerlinNoise1D(Time::GetGameTimeSeconds() + RandomSwayOffset) * SwayStrength;
			float Noise2 = Math::PerlinNoise1D(Time::GetGameTimeSeconds() + RandomSwayOffset + 20) * SwayStrength;

			CurrentWindStrength.AccelerateTo(FVector(Noise1, Noise2, 0), 1 / SwaySpeed, DeltaTime);
		}

		const FVector Velocity = HorizontalVelocity.Value + VerticalAcceleration.Value + CurrentWindStrength.Value;
		FVector NewDesiredLocation = MeshComp.WorldLocation + Velocity * DeltaTime;
		FVector DeltaToNewLocation = NewDesiredLocation - ActorLocation;

		
		// If we are attached to anything
		if(String.bAttachEnd)
		{
			if(PlayerMoveComp != nullptr)
			{
				//If player is airborne, dashes, stops or turns abruptly, stop using hand socket for the string location as it will cause hacking movement.
				if(!PlayerMoveComp.HasGroundContact() || PlayerDashComp.IsDashing() || PlayerHorizontalVelocityLastFrame.DotProduct(PlayerMoveComp.HorizontalVelocity) < 0.5)
					PlayerRunTime = Math::FInterpConstantTo(PlayerRunTime, 0, DeltaTime, StopRunLerpInterpSpeed);
				else
					PlayerRunTime = Math::Clamp(PlayerRunTime + DeltaTime, 0, MaxGroundedRunTime);

				PlayerHorizontalVelocityLastFrame = PlayerMoveComp.HorizontalVelocity;
			}

			CurrentStringAttachLocation.AccelerateTo(GetStringAttachLocation(), StringLocationLerpDuration, DeltaTime);
			FVector StringAttachLocation = CurrentStringAttachLocation.Value;

			// If the ball is further away than the string allows
			if((NewDesiredLocation - StringAttachLocation).Size() > String.CableLength * 2)
			{
				const FVector DirToDesiredLocation = (NewDesiredLocation - StringAttachLocation).GetSafeNormal();
				DeltaToNewLocation = (StringAttachLocation + DirToDesiredLocation * String.CableLength * 2) - ActorLocation;

				if(DeltaToNewLocation.Size() > 0.1)
				{
					CurrentWindStrength.AccelerateTo(FVector::ZeroVector, 1, DeltaTime);

					NewDesiredLocation = ActorLocation + DeltaToNewLocation;

					// Apply an impulse towards the new location
					const FVector Impulse = -DirToDesiredLocation * DeltaToNewLocation.Size();
					const FVector HorizontalImpulse = Impulse.VectorPlaneProject(FVector::UpVector);
	
					VerticalAcceleration.AccelerateTo(FVector::UpVector * Impulse.Z * 5, 1, DeltaTime);

					//Only apply yanking if the delta is large enough
					if(HorizontalImpulse.Size() >= HorizontalImpulseMinVelocity)
					{
						HorizontalVelocity.AccelerateTo(HorizontalImpulse, 2, DeltaTime);
						UMoonMarketFollowBalloonEventHandler::Trigger_OnBalloonYanked(this);
					}
					else //If delta was not large enough, gradually move the balloon toward the center
					{
						FVector HorizontalDeltaToCenter = (StringAttachLocation - ActorLocation).VectorPlaneProject(FVector::UpVector);
						HorizontalVelocity.AccelerateTo(HorizontalDeltaToCenter, 1, DeltaTime);
					}
				}
				else //If the balloon is already at its target location, reset the velocity to 0
				{
					HorizontalVelocity.AccelerateTo(FVector::ZeroVector, 0.5, DeltaTime);
					VerticalAcceleration.AccelerateTo(FVector::ZeroVector, 0.5, DeltaTime);

					float Noise1 = Math::PerlinNoise1D(Time::GetGameTimeSeconds() + RandomSwayOffset) * SwayStrength;
					float Noise2 = Math::PerlinNoise1D(Time::GetGameTimeSeconds() + RandomSwayOffset + 20) * SwayStrength;

					CurrentWindStrength.AccelerateTo(FVector(Noise1, Noise2, 0), 1 / SwaySpeed, DeltaTime);
				}

			}
			else //If the balloon string is not tightened, dampen the balloon's horizontal velocity
			{
				HorizontalVelocity.AccelerateTo(FVector::ZeroVector, 3, DeltaTime);
			}

			//TEMPORAL_LOG(this).DirectionalArrow("Horizontal Velocity", ActorLocation, HorizontalVelocity.Value, Color = FLinearColor::Red);
			//TEMPORAL_LOG(this).DirectionalArrow("Vertical Velocity", ActorLocation, VerticalAcceleration.Value, Color = FLinearColor::Blue);
		}
		else //If the balloon string is not attached to anything, dampen the balloon's horizontal velocity
		{
			HorizontalVelocity.AccelerateTo(FVector::ZeroVector, 3, DeltaTime);
		}

		//TEMPORAL_LOG(this).Sphere("Target Location", NewDesiredLocation, 10);
		
		if (!DeltaToNewLocation.IsNearlyZero())
		{
			//Trace for roof
			if (DeltaToNewLocation.Size() > 0.001)
				CollisionTrace(NewDesiredLocation, DeltaToNewLocation, DeltaTime);

			if(DeltaToNewLocation.Size() > 10 && Time::GetGameTimeSince(StartInteractionTime) < 0.5)
			{
				DeltaToNewLocation = DeltaToNewLocation.GetSafeNormal() * 10;
			}

			AddActorWorldOffset(DeltaToNewLocation);
		}
	}


	void CollisionTrace(FVector DesiredLocation, FVector& DeltaToNewLocation, float DeltaTime)
	{
		FHazeTraceSettings SphereTrace = Trace::InitObjectType(EObjectTypeQuery::WorldStatic);
		SphereTrace.UseSphereShape(Collider.ScaledSphereRadius);

		FVector TraceOrigin = DesiredLocation + FVector::UpVector * Collider.ScaledSphereRadius * 0.5;
		FVector TraceEnd = DesiredLocation + FVector::UpVector * Collider.ScaledSphereRadius;

		// FHazeTraceDebugSettings DebugSettings;
		// DebugSettings.Thickness = 2;
		// DebugSettings.TraceColor = FLinearColor::Purple;
		// SphereTrace.DebugDraw(DebugSettings);

		FHitResult Hit = SphereTrace.QueryTraceSingle(TraceOrigin, TraceEnd);
		if(Hit.bBlockingHit)
		{
			if(Cast<AIndoorSkyLightingVolume>(Hit.Actor) != nullptr)
				return;
			
			//Debug::DrawDebugArrow(TraceEnd, Hit.ImpactPoint);
			FVector DeltaToHit = Hit.ImpactPoint - TraceOrigin;
			FVector TargetDelta = DeltaToNewLocation - DeltaToHit.GetSafeNormal() * DeltaToNewLocation.Size();
			DeltaToNewLocation = TargetDelta;
			bIsColliding = true;
			UMoonMarketFollowBalloonEventHandler::Trigger_OnBalloonCollide(this);

			//if(!String.bAttachEnd)
			{
				HorizontalVelocity.SnapTo(FVector::ZeroVector);
				VerticalAcceleration.SnapTo(FVector::ZeroVector);
			}
		}
		else
			bIsColliding = false;
	}

	void HandleRotation(float DeltaTime)
	{
		FVector DirToStringAttach = (GetStringAttachLocation() - MeshComp.WorldLocation).GetSafeNormal();

		FVector ModifiedVector = DirToStringAttach * -1.0;

		if(!String.bAttachEnd)
			ModifiedVector = FVector::UpVector;

		FRotator TargetRotation = FRotator::MakeFromZ(ModifiedVector);

		if(DirToStringAttach.DotProduct(FVector::DownVector) >= 0.95)
			TargetRotation.Yaw = MeshComp.WorldRotation.Yaw;

		if(InteractingPlayer == nullptr)
			TargetRotation.Yaw = AccRot.Value.Yaw;

		AccRot.AccelerateTo(TargetRotation, 2, DeltaTime);
		//Debug::DrawDebugArrow(MeshComp.WorldLocation, MeshComp.WorldLocation + ModifiedVector * 200);
		MeshComp.SetWorldRotation(AccRot.Value);
	}

	void OnInteractionStarted(UInteractionComponent InteractionComponent, AHazePlayerCharacter Player) override
	{
		Super::OnInteractionStarted(InteractionComponent, Player);
		
		FMoonMarketFollowBalloonPlayerParams Params;
		Params.Player = Player;

		UMoonMarketFollowBalloonEventHandler::Trigger_OnBalloonTaken(this, Params);
		String.bAttachEnd = true;
		String.SetAttachEndToComponent(Player.Mesh, n"LeftHand");
		String.EndLocation = FVector::ZeroVector;
		UMoonMarketHoldBalloonComp::Get(InteractingPlayer).AddBalloon(this);
		PlayerMoveComp = UHazeMovementComponent::Get(InteractingPlayer);
		PlayerDashComp = UPlayerStepDashComponent::Get(InteractingPlayer);
		PlayerHorizontalVelocityLastFrame = PlayerMoveComp.HorizontalVelocity;
		// Maybe smooth this out with a lerp
		SetActorControlSide(InteractingPlayer);
	}

	void OnInteractionStopped(AHazePlayerCharacter Player) override
	{
		PlayerMoveComp = nullptr;
		PlayerDashComp = nullptr;

		if(InteractingPlayer != nullptr)
		{
			auto HoldBalloonComp = UMoonMarketHoldBalloonComp::Get(InteractingPlayer);
			HoldBalloonComp.ReleaseBalloon(this);
		}
		
		Super::OnInteractionStopped(Player);
	}

	void OnInteractionCanceled() override
	{
		Super::OnInteractionCanceled();
		if(InteractingPlayer != nullptr)
		{
			auto HoldBalloonComp = UMoonMarketHoldBalloonComp::Get(InteractingPlayer);
			HoldBalloonComp.ReleaseBalloon(this);
			HoldBalloonComp.ReleaseAllBalloons();
		}
	}

	void Release()
	{
		UMoonMarketFollowBalloonEventHandler::Trigger_OnBalloonReleased(this);
		InteractingPlayer = nullptr;
		String.bAttachEnd = false;
		InteractComp.Enable(this);
	}

	void Pop(AHazePlayerCharacter InstigatingPlayer)
	{
		if(InteractingPlayer != nullptr)
			StopInteraction(InteractingPlayer);

		UMoonMarketFollowBalloonEventHandler::Trigger_OnBalloonPopped(this);
		Niagara::SpawnOneShotNiagaraSystemAtLocation(PopBalloonEffect, MeshComp.WorldLocation);
		bIsPopped = true;
		OnPoppedEvent.Broadcast(InstigatingPlayer);

		if(bCanRespawn)
		{
			Attach();
			SetActorScale3D(FVector::ZeroVector);
			Timer::SetTimer(this, n"Respawn", 2);
		}
		else
		{
			DestroyActor();
		}
	}

	UFUNCTION()
	void Respawn()
	{
		SetActorLocation(OriginalLocation);
		RespawnSize.SnapTo(0);
		RespawnTime = Time::GetGameTimeSeconds();
		bFinishedRespawn = false;
		bIsPopped = false;
	}


#if EDITOR
	UFUNCTION(BlueprintOverride)
	void OnVisualizeInEditor() const
	{
		if(bGroundAttachLocationFound)
		{
			Debug::DrawDebugLine(ActorLocation, ActorLocation + FVector::DownVector * (String.CableLength * 2));
			Debug::DrawDebugSphere(AutoGroundAttach.WorldLocation, 10, 12, FLinearColor::Green);
		}
		else
		{
			Debug::DrawDebugLine(ActorLocation, ActorLocation + FVector::DownVector * (String.CableLength * 2), FLinearColor::Red);
		}
	}
#endif

	#if EDITOR
	UFUNCTION(BlueprintOverride)
	void OnActorModifiedInEditor()
	{
		FHazeTraceSettings TraceSettings = Trace::InitChannel(ECollisionChannel::ECC_Pawn);
		TraceSettings.UseLine();
		TraceSettings.IgnoreActor(this);

		const FVector Start = ActorLocation;
		const FVector End = Start + FVector::DownVector * (String.CableLength * 2);
		FHitResult GroundHit = TraceSettings.QueryTraceSingle(Start, End);
		
		bGroundAttachLocationFound = GroundHit.IsValidBlockingHit();
		if(bGroundAttachLocationFound)
			AutoGroundAttach.SetWorldLocation(GroundHit.ImpactPoint);
		
	}
	#endif
};