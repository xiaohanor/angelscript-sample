struct FSkylineAttackShipProjectilePhaseData
{
	UPROPERTY(EditDefaultsOnly)
	FVector Force = FVector::ZeroVector;

	UPROPERTY(EditDefaultsOnly)
	FVector Impulse = FVector::ZeroVector;

	UPROPERTY(EditDefaultsOnly)
	float Drag = 0.0;

	UPROPERTY(EditDefaultsOnly)
	bool bLocalSpace = true;

	UPROPERTY(EditDefaultsOnly)
	bool bHomingActive = false;

	UPROPERTY(EditDefaultsOnly)
	float Duration = 0.0;
}

enum ESkylineAttackShipProjectileState
{
	Free,
	Grabbed,
	Thrown
}

event void FSkylineAttackShipProjectileSignature(ASkylineAttackShipProjectileBase Projectile);
class ASkylineAttackShipProjectileBase : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent)
	USceneComponent MissileRoot;

	UPROPERTY(DefaultComponent)
	UGravityWhipTargetComponent GravityWhipTargetComponent;

	UPROPERTY(DefaultComponent, Attach = GravityWhipTargetComponent)
	UTargetableOutlineComponent TargetableOutlineComponent;

	UPROPERTY(DefaultComponent)
	UGravityWhipResponseComponent GravityWhipResponseComponent;
	default GravityWhipResponseComponent.GrabMode = EGravityWhipGrabMode::Sling;
	default GravityWhipResponseComponent.MinSpreadRadius = 0.0;
	default GravityWhipResponseComponent.MaxSpreadRadius = 0.0;

	ESkylineAttackShipProjectileState State = ESkylineAttackShipProjectileState::Free;

	FVector Velocity;

	AActor Target;
	FVector TargetRelativeLocation;

	TArray<AActor> ActorsToIgnore;

	UPROPERTY(EditDefaultsOnly)
	TArray<FSkylineAttackShipProjectilePhaseData> ProjectilePhases;

	FSkylineAttackShipProjectilePhaseData ProjectilePhase;

	UPROPERTY(EditAnywhere)
	float LifeTimeUngrabbed = 10.0;

	UPROPERTY(EditAnywhere)
	float EffectPower = 1.0;

	UPROPERTY(EditAnywhere)
	float Damage = 0.5;

	float TimeStamp;
	int PhaseIndex = 0;

	bool bIsGrabbed = false;
	bool bThrown = false;

	bool bCanDamagePlayer = true;

	UPlayerAimingComponent PlayerAimingComponent;

	FSkylineAttackShipProjectileSignature OnExpired;

	UPROPERTY(DefaultComponent)
	UHazeCrumbSyncedActorPositionComponent SyncedPositionComp;
	default SyncedPositionComp.SyncDetailLevel = EHazeActorPositionSyncDetailLevel::TransformOnly;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		SetActorControlSide(Game::Zoe);

		GravityWhipResponseComponent.OnGrabbed.AddUFunction(this, n"HandleGrabbed");
		GravityWhipResponseComponent.OnThrown.AddUFunction(this, n"HandleThrown");

	//	GravityWhipTargetComponent.Disable(this);
		AddActorDisable(this);
	}

	void Launch(FTransform LaunchTransform)
	{
		ActorTransform = LaunchTransform;
		Velocity = FVector::ZeroVector;
		PhaseIndex = 0;
		bIsGrabbed = false;
		bThrown = false;
		PlayerAimingComponent = nullptr;
		LifeTimeUngrabbed = 10.0;
		State = ESkylineAttackShipProjectileState::Free;
		GravityWhipTargetComponent.Enable(this);

		RemoveActorDisable(this);
		SetActorEnableCollision(false); // TODO stuff
		TimeStamp = Time::GameTimeSeconds;

		ProjectilePhase = ProjectilePhases[PhaseIndex];

		ActivatePhase(PhaseIndex);

		BP_OnLaunch();
	}

	UFUNCTION()
	private void HandleGrabbed(UGravityWhipUserComponent UserComponent, UGravityWhipTargetComponent TargetComponent, TArray<UGravityWhipTargetComponent> OtherComponents)
	{
		State = ESkylineAttackShipProjectileState::Grabbed;
		PlayerAimingComponent = UPlayerAimingComponent::Get(UserComponent.Owner);
		LifeTimeUngrabbed = 5.0;
		ActorsToIgnore.Empty();
	}

	UFUNCTION()
	private void HandleThrown(UGravityWhipUserComponent UserComponent, UGravityWhipTargetComponent TargetComponent, FHitResult HitResult, FVector Impulse)
	{
		State = ESkylineAttackShipProjectileState::Thrown;
		GravityWhipTargetComponent.Disable(this);
		Velocity = Impulse.SafeNormal * 5000.0;

		Target = nullptr;
		if (HitResult.bBlockingHit)
		{
			Target = HitResult.Actor;
			TargetRelativeLocation = Target.ActorTransform.InverseTransformPositionNoScale(HitResult.ImpactPoint);
		}
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		MissileRoot.AddRelativeRotation(FRotator(0.0, 0.0, 360.0 * DeltaSeconds));

		if (HasControl())
		{
			FVector Force;
			FVector Acceleration;

			switch (State)
			{
				case ESkylineAttackShipProjectileState::Free:
				{
					LifeTimeUngrabbed -= DeltaSeconds;
					if (LifeTimeUngrabbed <= 0.0)
					{
						Expire();
						return;
					}

					while (ProjectilePhase.Duration > 0.0 && Time::GameTimeSeconds >= TimeStamp + ProjectilePhase.Duration)
					{
						PhaseIndex++;

						if (PhaseIndex < ProjectilePhases.Num())
						{
							// Set new Phase
							ProjectilePhase = ProjectilePhases[PhaseIndex];
							ActivatePhase(PhaseIndex);
						}
						else
							break; 
					}

					Force = ProjectilePhase.Force;

					if (ProjectilePhase.bLocalSpace)
						Force = ActorTransform.TransformVectorNoScale(Force);

					if (ProjectilePhase.bHomingActive)
					{
						if (Target != nullptr)
						{
							FVector ToTarget = Target.ActorLocation - ActorLocation;
							Force = ToTarget.SafeNormal * ProjectilePhase.Force.Size();

							float ProximityPrecision = 1.0 - Math::GetPercentageBetweenClamped(0.0, 50000.0, ToTarget.Size());

							Velocity = Velocity.SlerpTowards(ToTarget.SafeNormal, ProximityPrecision * 2.0 * DeltaSeconds);			

							if (ToTarget.Size() < 1000.0)
								ProjectilePhase.bHomingActive = false;					
						}
					}

					Acceleration = Force
								- Velocity * ProjectilePhase.Drag;

					Velocity += Acceleration * DeltaSeconds;	
				
					FQuat TargetRotation = ActorQuat;

					if (!Force.IsNearlyZero())
						TargetRotation = Force.ToOrientationQuat();

					FQuat Rotation = FQuat::Slerp(ActorQuat, TargetRotation, 5.0 * DeltaSeconds);
					SetActorRotation(Rotation);
				}
					break;

				case ESkylineAttackShipProjectileState::Grabbed:
				{
				}
					break;

				case ESkylineAttackShipProjectileState::Thrown:
				{
					LifeTimeUngrabbed -= DeltaSeconds;
					if (LifeTimeUngrabbed <= 0.0)
					{
						Expire();
						return;
					}
	/*
					if (Target != nullptr)
					{
						FVector ToTarget = Target.ActorTransform.TransformPositionNoScale(TargetRelativeLocation) - ActorLocation;
						Force = ToTarget.SafeNormal * 2000.0;

						float ProximityPrecision = 1.0 - Math::GetPercentageBetweenClamped(0.0, 50000.0, ToTarget.Size());

						Velocity = Velocity.SlerpTowards(ToTarget.SafeNormal, ProximityPrecision * 2.0 * DeltaSeconds);			
					}

					Acceleration = Force
								- Velocity * ProjectilePhase.Drag;

					Velocity += Acceleration * DeltaSeconds;	
	*/
					FQuat TargetRotation = Velocity.ToOrientationQuat();

					FQuat Rotation = FQuat::Slerp(ActorQuat, TargetRotation, 10.0 * DeltaSeconds);
					SetActorRotation(Rotation);
				}
					break;
			}

			FVector DeltaMove = Velocity * DeltaSeconds;

			Move(DeltaMove);
		}
		else
		{
			auto Position = SyncedPositionComp.Position;
			SetActorLocationAndRotation(Position.WorldLocation, Position.WorldRotation);
		}
	}

	void ActivatePhase(int Index)
	{
		if (!HasControl())
			return;

		CrumbActivatePhase(Index);
	}

	UFUNCTION(CrumbFunction)
	void CrumbActivatePhase(int Index)
	{
		auto PhaseData = ProjectilePhases[Index];

		// Apply Impulse
		FVector Impulse = PhaseData.Impulse;

		if (PhaseData.bLocalSpace)
			Impulse = ActorTransform.TransformVectorNoScale(Impulse);

		if (PhaseData.bHomingActive)
		{
			if (Target != nullptr)
			{
				FVector ToTarget = Target.ActorLocation - ActorLocation;
				Impulse = ToTarget.SafeNormal * PhaseData.Impulse.Size();
			}
		}

		Velocity += Impulse;

		BP_OnPhaseActivate(Index);
	}

	void Move(FVector DeltaMove)
	{
		auto Trace = Trace::InitChannel(ECollisionChannel::ECC_Visibility);
		Trace.IgnoreActors(ActorsToIgnore);
		auto HitResult = Trace.QueryTraceSingle(ActorLocation, ActorLocation + DeltaMove);

		if (State != ESkylineAttackShipProjectileState::Grabbed && HitResult.bBlockingHit)
			HandleImpact(HitResult);
		else
			ActorLocation += DeltaMove;
	}

	void HandleImpact(FHitResult HitResult)
	{
		if (!HasControl())
			return;

		CrumbHandleImpact(HitResult);
	}

	UFUNCTION(CrumbFunction)
	void CrumbHandleImpact(FHitResult HitResult)
	{
		if (HitResult.Actor != nullptr)
		{
			
			auto GravityWhipImpactResponseComponent = UGravityWhipImpactResponseComponent::Get(HitResult.Actor);
			if (GravityWhipImpactResponseComponent != nullptr)
			{
				FGravityWhipImpactData ImpactData;
				ImpactData.HitResult = HitResult;
				ImpactData.ImpactVelocity = Velocity;
				ImpactData.Damage = Damage;
				GravityWhipImpactResponseComponent.Impact(ImpactData);
			}
		
		
			else
				Damage::AIRadialDamageToTeam(HitResult.ImpactPoint, 500.0, 0.5, this, n"BasicAITeam");
				Damage::PlayerRadialDamage(HitResult.ImpactPoint, 500.0, 0.5);
				//auto Player = Cast<AHazePlayerCharacter>(HitResult.Actor);
			
		}
	

		BP_OnImpact(HitResult);
		Expire();
	}

	void Expire()
	{
		if (!HasControl())
			return;

		CrumbExpire();
	}

	UFUNCTION(CrumbFunction)
	void CrumbExpire()
	{
		AddActorDisable(this);
		OnExpired.Broadcast(this);
		BP_OnExpire();
	}

	UFUNCTION(BlueprintEvent)
	void BP_OnImpact(FHitResult HitResult) { }

	UFUNCTION(BlueprintEvent)
	void BP_OnLaunch() { }

	UFUNCTION(BlueprintEvent)
	void BP_OnExpire() { }

	UFUNCTION(BlueprintEvent)
	void BP_OnPhaseActivate(int Phase) { }
}