event void FOnWhipSlingableObjectImpact(TArray<FHitResult> HitResults, FVector Velocity);
event void FOnWhipSlingableGrabbed();

class AWhipSlingableObject : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USphereComponent Collision;
	default Collision.SphereRadius = 50.0;
	default Collision.SetCollisionProfileName(n"BlockOnlyPlayerCharacter");
	default Collision.SetCollisionResponseToChannel(ECollisionChannel::EnemyCharacter, ECollisionResponse::ECR_Block);
	default Collision.bDisableUpdateOverlapsOnComponentMove = true;

	UPROPERTY(DefaultComponent, Attach = Collision)
	UGravityWhipTargetComponent GravityWhipTargetComponent;

	UPROPERTY(DefaultComponent, Attach = GravityWhipTargetComponent)
	UTargetableOutlineComponent TargetableOutlineComp;

	UPROPERTY(DefaultComponent)
	UGravityWhipResponseComponent GravityWhipResponseComponent;
	default GravityWhipResponseComponent.GrabMode = EGravityWhipGrabMode::Sling;

	UPROPERTY(DefaultComponent)
	UHazeCrumbSyncedActorPositionComponent SyncedPosition;
	default SyncedPosition.SyncDetailLevel = EHazeActorPositionSyncDetailLevel::TransformOnly;
	default SyncedPosition.SyncRate = EHazeCrumbSyncRate::High;

	UPROPERTY(DefaultComponent)
	UGravityBladeCombatResponseComponent GravityBladeResponseComponent;

	UPROPERTY(DefaultComponent)
	UHazeMovementComponent MovementComponent;

	UPROPERTY(DefaultComponent)
	UBasicAIHomingProjectileComponent HomingProjectileComp;

	UPROPERTY(DefaultComponent)
	UDisableComponent DisableComp;
	default DisableComp.bAutoDisable = true;
	default DisableComp.AutoDisableRange = 10000.0;

	UPROPERTY()
	FOnWhipSlingableObjectImpact OnWhipSlingableObjectImpact;
	UPROPERTY()
	FOnWhipSlingableGrabbed OnWhipSlingableGrabbed;

	UGravityBladeCombatTargetComponent BladeTargetComp;
	USimpleMovementData Movement;
	UHazeActorNetworkedSpawnPoolComponent SpawnPool;

	// Set the life time of the object after being thrown, 0.0 = infinite
	UPROPERTY(EditAnywhere)
	float LifeTimeAfterThrown = 0.0;

	UPROPERTY(EditAnywhere)
	bool bSpawnHitEffectAfterLifetimeExpired = false;

	UPROPERTY(EditAnywhere)
	float GrabbedDrag = 1.0;

	UPROPERTY(EditAnywhere)
	float ThrownDrag = 1.0;

	// Set to 0 for no gravity
	UPROPERTY(EditAnywhere)
	float Gravity = -980.0;

	UPROPERTY(EditAnywhere)
	float Bounce = 0.5;

	UPROPERTY(EditAnywhere)
	float SlingSpeed = 1000.0;

	UPROPERTY(EditAnywhere)
	float GrabForceMultiplier = 1.0;

	UPROPERTY(EditAnywhere)
	bool bDestroyOnImpact = true;

	UPROPERTY(EditAnywhere, Category = "Damage")
	bool bCanDamagePlayer;

	bool bGrabbed;
	bool bThrown;
	bool bImpactDamage;
	float ThrowTime;

	float PlayerCollisionRadius;
	FVector PlayerCollisionPreviousLocation;
	float RemainingLifeTime;

	UPROPERTY(EditAnywhere, Category = "Damage")
	float Damage = 1.0;

	UPROPERTY(EditAnywhere, Category = "Damage")
	EDamageType DamageType = EDamageType::Default;

	UPROPERTY(EditAnywhere)
	float ImpactEffectThreshold = 100.0;

	UPROPERTY(EditAnywhere)
	float MaxGrabSpeed = 500.0;

	UPROPERTY(EditAnywhere)
	bool bSpinRandomlyWhileGrabbed = true;

	UPROPERTY(EditAnywhere)
	UNiagaraSystem HitEffect;

	UPROPERTY(EditAnywhere, Category = "Damage")
	bool bUseRadialDamage;

	UPROPERTY(EditAnywhere, Meta = (EditCondition = "bUseRadialDamage", EditConditionHides), Category = "Damage")
	float RadialDamage = 0.5;

	UPROPERTY(EditAnywhere, Meta = (EditCondition = "bUseRadialDamage", EditConditionHides), Category = "Damage")
	float RadialDamageRadius = 500.0;

	UPROPERTY(EditAnywhere, Category = "DebugLine")
	bool bDrawDebugLine;

	FVector AngularVelocity;

	bool bUseFocusLocation = true;

	UPROPERTY(EditAnywhere)
	TSubclassOf<UDamageEffect> DamageEffect;

	UPROPERTY(EditAnywhere)
	bool bUseStackHierarchy = false;

	TArray<FInstigator> DisableInstigators;

	FVector GrabbedRotationAxis;

	// TArray<AActor> InitialMovementIgnoreActors;

	UPROPERTY(EditAnywhere)
	bool bGravityBladeBreakable = false;

	UPROPERTY(EditAnywhere)
	float HomingStrength = 300.0;

	UPROPERTY(EditDefaultsOnly)
	TSubclassOf<UCameraShakeBase> ImpactCameraShake;

	protected float TimeLastImpact = 0;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		SetActorControlSide(Game::Zoe);
		RemainingLifeTime = LifeTimeAfterThrown;

		Movement = MovementComponent.SetupSimpleMovementData();

		GravityWhipResponseComponent.OnGrabbed.AddUFunction(this, n"OnGrabbed");
		GravityWhipResponseComponent.OnThrown.AddUFunction(this, n"OnThrown");

		BladeTargetComp = UGravityBladeCombatTargetComponent::Get(this);
		if (BladeTargetComp != nullptr && !bGravityBladeBreakable)
			BladeTargetComp.Disable(this);

		if (bGravityBladeBreakable)
		{
			GravityBladeResponseComponent.OnHit.AddUFunction(this, n"OnBladeHit");
		}


		if (bUseStackHierarchy && AttachParentActor != nullptr)
		{
			auto SlingableParent = Cast<AWhipSlingableObject>(AttachParentActor);
			if (SlingableParent != nullptr)
				SlingableParent.AddDisabler(this);
		}
	
		GrabbedRotationAxis = Math::GetRandomRotation().ForwardVector;
		if (bSpinRandomlyWhileGrabbed)
			GravityWhipResponseComponent.SpinSpeedWhileSlinging = FQuat(GrabbedRotationAxis, PI).Rotator();

		// for (auto InitialMovementIgnoreActor : InitialMovementIgnoreActors)
		// 	MovementComponent.AddMovementIgnoresActor(this, InitialMovementIgnoreActor);

		FVector Extents = GetActorBoxExtents(false);
		float Radius = Extents.GetMax();
		PlayerCollisionRadius = Radius;
	}

	UFUNCTION()
	private void OnBladeHit(UGravityBladeCombatUserComponent CombatComp, FGravityBladeHitData HitData)
	{
		if(!bGravityBladeBreakable)
			return;
		// Niagara::SpawnOneShotNiagaraSystemAtLocation(HitEffect, ActorLocation, ActorRotation);
		UWhipSlingableObjectEventHandler::Trigger_OnBladeHitImpact(this);
		SpawnHitEffect(HitData.ImpactNormal*-1.0);
		DestroyOrUnSpawn();
	}

	// TODO: Should be handled by response component
	UFUNCTION()
	void OnBreak()
	{
		// Niagara::SpawnOneShotNiagaraSystemAtLocation(HitEffect, ActorLocation, ActorRotation);
		SpawnHitEffect(FVector::ZeroVector);
		DestroyOrUnSpawn();
	}

	void SpawnHitEffect(FVector Vel)
	{
		Niagara::SpawnOneShotNiagaraSystemAtLocation(HitEffect, ActorLocation, ActorRotation);
		OnSpawnHitEffect(Vel);
	}

	UFUNCTION(BlueprintEvent)
	void OnSpawnHitEffect(FVector Vel) { }

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		if (HasControl())
		{
			if (!bThrown)
				return;

			if (MovementComponent.PrepareMove(Movement))
			{
				FVector Velocity = MovementComponent.Velocity;
				FVector Force;

				for (auto& Grab : GravityWhipResponseComponent.Grabs)
					Force += Grab.TargetComponent.ConsumeForce();

				FVector Acceleration = Force * GrabForceMultiplier
									- MovementComponent.Velocity * (bThrown ? ThrownDrag : GrabbedDrag)
									+ FVector::UpVector * Gravity * (bThrown && HomingProjectileComp.Target == nullptr ? 1.0 : 0.0);

				AngularVelocity -= AngularVelocity * 1.0 * DeltaSeconds;

				if(HomingProjectileComp.Target != nullptr)
				{
					FVector TargetLocation = HomingProjectileComp.Target.ActorCenterLocation;
					if(Velocity.DotProduct(TargetLocation - ActorLocation) > 0)
					{
						float LaunchDuration = Time::GetGameTimeSince(ThrowTime);
						Velocity += HomingProjectileComp.GetPlanarHomingAcceleration(TargetLocation, Velocity.GetSafeNormal(), HomingStrength * LaunchDuration) * DeltaSeconds;
					}
				}

				Movement.AddVelocity(Velocity);
				Movement.AddAcceleration(Acceleration);
				Movement.BlockGroundTracingForThisFrame();
				Movement.SetRotation(GetMovementRotation(DeltaSeconds));
				MovementComponent.ApplyMove(Movement);
			}

			if (bThrown)
			{
				// Process movement component impacts
				if (bDestroyOnImpact || MovementComponent.PreviousVelocity.Size() > 1.0)
				{
					if (MovementComponent.HasAnyValidBlockingContacts())
					{
						auto MovementImpacts = GetImpacts();
						auto ImpactMembers = GetImpactTeamMembers();

						// Filter out any hits on local-only objects so we don't get issues in network
						for (int i = MovementImpacts.Num() - 1; i >= 0; --i)
						{
							if (MovementImpacts[i].Component == nullptr || !MovementImpacts[i].Component.IsObjectNetworked())
								MovementImpacts.RemoveAt(i);
						}

						// Reflect velocity off the impact
						for (auto HitResult : MovementImpacts)
						{
							if (HitResult.Actor == nullptr)
								continue;

							FVector Velocity = MovementComponent.PreviousVelocity;

							auto ImpactResponseComponent = UGravityWhipImpactResponseComponent::Get(HitResult.Actor);
							if (ImpactResponseComponent != nullptr && bImpactDamage)
							{
								if (ImpactResponseComponent.bIsNonStopping)
								{
									ActorVelocity = Velocity * ImpactResponseComponent.VelocityScaleAfterImpact;
								}
								else
								{
									ActorVelocity = Math::GetReflectionVector(Velocity, MovementImpacts[0].Normal) * ImpactResponseComponent.VelocityScaleAfterImpact * Bounce;
									AngularVelocity = ActorTransform.InverseTransformVectorNoScale(MovementImpacts[0].ImpactNormal.CrossProduct(Velocity) * ImpactResponseComponent.VelocityScaleAfterImpact * 0.01);
								}
							}
							else
							{
								ActorVelocity = Math::GetReflectionVector(Velocity, MovementImpacts[0].Normal) * Bounce;
								AngularVelocity = ActorTransform.InverseTransformVectorNoScale(MovementImpacts[0].ImpactNormal.CrossProduct(Velocity) * 0.01);
							}
						}

						if (bDestroyOnImpact || Time::GetGameTimeSince(TimeLastImpact) > 0.1)
						{
							CrumbProcessImpacts(MovementImpacts, ImpactMembers, MovementComponent.PreviousVelocity);
						}
					}
					else if(TryToHitMio() && Time::GetGameTimeSince(TimeLastImpact) > 0.1)
					{
						// Make it easier to hit Mio with stuff
						if(PlayerCollisionPreviousLocation.IsNearlyZero())
							PlayerCollisionPreviousLocation = ActorLocation;
						FVector Delta = ActorLocation - PlayerCollisionPreviousLocation;
						PlayerCollisionPreviousLocation = ActorLocation;

						if(!Delta.IsNearlyZero())
						{
							FHazeTraceSettings Trace = Trace::InitAgainstComponent(Game::Mio.CapsuleComponent);
							Trace.UseSphereShape(PlayerCollisionRadius);
							FHitResult Hit = Trace.QueryTraceComponent(ActorCenterLocation, ActorCenterLocation - Delta);
							if(Hit.bBlockingHit)
							{
								TArray<FHitResult> MovementImpacts;
								MovementImpacts.Add(Hit);
								CrumbProcessImpacts(MovementImpacts, TArray<AActor>(), MovementComponent.PreviousVelocity);
							}
						}					
					}
				}

				if (RemainingLifeTime > 0.0 && !IsActorBeingDestroyed() && HomingProjectileComp.Target == nullptr)
				{
					RemainingLifeTime -= DeltaSeconds;
					if (RemainingLifeTime <= 0.0)
						CrumbLifeTimeExpired();
				}
			}
			else
			{
				// Some temp added rotation
				AngularVelocity = GrabbedRotationAxis * 5.0;
				// AngularVelocity = FVector(10.0, 20.0, 10.0) * 0.1;
				// AddActorLocalRotation(FRotator(10.0, 20.0, 10.0) * 6.0 * DeltaSeconds);	
			}
		}
		else
		{
			if (bThrown)
			{
				auto& Position = SyncedPosition.Position;
				SetActorLocationAndRotation(
					Position.WorldLocation,
					Position.WorldRotation
				);
			}
		}
	}

	protected bool TryToHitMio()
	{
		if(!bCanDamagePlayer)
			return false;
		if(MovementComponent.Velocity.IsNearlyZero())
			return false;
		if(Game::Mio.IsPlayerDead())
			return false;
		return true;
	}

	UFUNCTION(CrumbFunction)
	void CrumbApplyPVPDamage(AHazePlayerCharacter Player)
	{
		if (Player.IsMio())
		{
			auto HealthComp = UPlayerHealthComponent::Get(Player);
			if (HealthComp.WouldDieFromDamage(0.5, true) && HealthComp.CanTakeDamage(false))
			{
				USkylinePVPEffectHandler::Trigger_KilledByOtherPlayer(Player);

				auto GravityBladeComp = UGravityBladeCombatUserComponent::Get(Player);
				auto RespawnComp = UPlayerRespawnComponent::Get(Player);
				RespawnComp.OnPlayerRespawned.AddUFunction(GravityBladeComp, n"OnRespawnAfterKilledByOtherPlayer");
			}
			else
			{
				USkylinePVPEffectHandler::Trigger_HitByOtherPlayer(Player);
			}
		}

		Player.DamagePlayerHealth(0.5, DamageEffect = DamageEffect);
	}

	UFUNCTION(CrumbFunction)
	protected void CrumbProcessImpacts(TArray<FHitResult> HitResults, 
		TArray<AActor> ImpactMembers,
		FVector Velocity)
	{
		TArray<AActor> HitActors;
		TArray<FVector> HitLocations;

		for (auto HitResult : HitResults)
		{
			HitLocations.Add(HitResult.ImpactPoint);

			if (HitResult.Actor == nullptr)
				continue;

			auto ImpactResponseComponent = UGravityWhipImpactResponseComponent::Get(HitResult.Actor);
			if (ImpactResponseComponent != nullptr && bImpactDamage)
			{
				HitActors.Add(HitResult.Actor);

				FGravityWhipImpactData ImpactData;
				ImpactData.ImpactVelocity = Velocity;
				ImpactData.HitResult = HitResult;
				ImpactData.Damage = Damage;
				ImpactData.ThrownActor = this;
				ImpactResponseComponent.Impact(ImpactData);				
			}

			if (bCanDamagePlayer)
			{
				auto Player = Cast<AHazePlayerCharacter>(HitResult.Actor);
				if (Player != nullptr && Player.HasControl() && !Player.IsZoe() && !Player.IsPlayerInvulnerable())
				{
					FVector KnockDirection = (Player.ActorCenterLocation - ActorLocation).GetSafeNormal2D(Player.MovementWorldUp);
					CrumbApplyPVPDamage(Player);
					Player.ApplyKnockdown(KnockDirection * 300, 1.0);
				}
			}
		}

		if (bUseRadialDamage)
		{
			if (bCanDamagePlayer)
			{
				for (auto Player : Game::Players)
				{
					if (Player.IsZoe())
						continue;
					if (!Player.HasControl())
						continue;

					if (!Overlap::QueryShapeOverlap(
						Player.CapsuleComponent.GetCollisionShape(),
						Player.CapsuleComponent.WorldTransform,
						FCollisionShape::MakeSphere(RadialDamageRadius),
						FTransform(ActorLocation),
					))
					{
						continue;
					}

					FVector KnockDirection = (Player.ActorCenterLocation - ActorLocation).GetSafeNormal2D(Player.MovementWorldUp);
					CrumbApplyPVPDamage(Player);
					Player.ApplyKnockdown(KnockDirection * 300, 1.0);
				}
			}

			for (auto Member : ImpactMembers)
			{
				if(HitActors.Contains(Member))
					continue;
				auto ImpactResponseComponent = UGravityWhipImpactResponseComponent::GetOrCreate(Member);
				FGravityWhipRadialImpactData Data;
				Data.Damage = RadialDamage;
				ImpactResponseComponent.RadialImpact(Data);
			}
		}

		if (Velocity.Size() >= ImpactEffectThreshold)
		{
			// Niagara::SpawnOneShotNiagaraSystemAtLocation(HitEffect, ActorLocation, ActorRotation);
			// Debug::DrawDebugArrow(ActorLocation, ActorLocation - Velocity.GetSafeNormal()*1000.0, 1000.0, FLinearColor::Yellow, 3.0, 5.0);
			SpawnHitEffect(Velocity);
			TriggerImpactAudio();
		}

		if (GravityWhipTargetComponent.IsDisabled() && Velocity.Size() <= MaxGrabSpeed)
			GravityWhipTargetComponent.Enable(this);

		OnWhipSlingableObjectImpact.Broadcast(HitResults, Velocity);
		TimeLastImpact = Time::GameTimeSeconds;
		
		FSkylineSlingableImpactEventData Data;
		Data.HitResults = HitResults;
		Data.Velocity = Velocity;
		UWhipSlingableObjectEventHandler::Trigger_OnImpact(this, Data);

		// FF and CS
		ForceFeedback::PlayWorldForceFeedback(ForceFeedback::Default_Medium, ActorLocation, false, this, 150, 400);
		if(ImpactCameraShake != nullptr)
		{
			for(AHazePlayerCharacter Player : Game::Players)
				Player.PlayWorldCameraShake(ImpactCameraShake, this, ActorLocation, 150, 400);
		}

		if (bDestroyOnImpact)
			DestroyOrUnSpawn();
	}

	void TriggerImpactAudio()
	{
		auto AudioData = GravityWhipTargetComponent.AudioData;
		if(AudioData.bAudioObject && AudioData.ImpactEvent != nullptr)
		{
			FHazeAudioFireForgetEventParams Params;
			Params.AttenuationScaling = AudioData.AttenuationScaling;
			Params.Transform = GetActorTransform();			

			Params.RTPCs.Reserve(3);
	
			auto MakeUpGainId = AudioData.GravityWhipTargetMakeUpGainRtpc;
			Params.RTPCs.Add(FHazeAudioRTPCParam(FHazeAudioID(MakeUpGainId), AudioData.MakeUpGain));	

			auto VoiceVolumeId = AudioData.GravityWhipTargetVoiceVolumeRtpc;
			Params.RTPCs.Add(FHazeAudioRTPCParam(FHazeAudioID(VoiceVolumeId), AudioData.VoiceVolume));
		
			auto PitchId = AudioData.GravityWhipTargetPitchRtpc;			
			Params.RTPCs.Add(FHazeAudioRTPCParam(FHazeAudioID(PitchId), AudioData.Pitch));	
		
			AudioComponent::PostFireForget(GravityWhipTargetComponent.AudioData.ImpactEvent, Params);
		}
	}

	UFUNCTION()
	void OnGrabbed(UGravityWhipUserComponent UserComponent,
		UGravityWhipTargetComponent TargetComponent,
		TArray<UGravityWhipTargetComponent> OtherComponents)
	{
		OnWhipSlingableGrabbed.Broadcast();
		bGrabbed = true;
		bThrown = false;

		// Clear 
		MovementComponent.RemoveMovementIgnoresActor(this);

		for (UGravityWhipTargetComponent Component : OtherComponents)
		{
			if (Component != TargetComponent)
			{
				MovementComponent.AddMovementIgnoresActor(this, Component.Owner);
			}
		}
	
		if (bUseStackHierarchy && AttachParentActor != nullptr)
		{
			auto SlingableParent = Cast<AWhipSlingableObject>(AttachParentActor);
			if (SlingableParent != nullptr)
				SlingableParent.RemoveDisabler(this);
		}

		// GravityWhipResponseComponent.SpinSpeedWhileSlinging = FQuat(AngularVelocity.GetSafeNormal(), AngularVelocity.Size()).Rotator();
		DetachFromActor();

		if (BladeTargetComp != nullptr)
			BladeTargetComp.Disable(this);
	
		UWhipSlingableObjectEventHandler::Trigger_OnGrabbed(this);

		UNavModifierComponent NavComp = Cast<UNavModifierComponent>(GetComponentByClass(UNavModifierComponent));
		if(NavComp != nullptr)
			NavComp.DestroyComponent(NavComp);
	}

	UFUNCTION()
	void OnThrown(UGravityWhipUserComponent UserComponent,
		UGravityWhipTargetComponent TargetComponent,
		FHitResult HitResult,
		FVector Impulse)
	{
		if(bDrawDebugLine)
			Debug::DrawDebugLine(ActorLocation, ActorLocation + (Impulse.GetSafeNormal() * 2000.0), FLinearColor::Green, 10.0, 2.0);

		Collision.SetCollisionProfileName(n"BlockAllDynamic");

		bThrown = true;
		bImpactDamage = true;
		GravityWhipTargetComponent.Disable(this);
		ThrowTime = Time::GetGameTimeSeconds();
		DisableComp.SetEnableAutoDisable(false);

		FVector Dir = Impulse.SafeNormal;

		UTargetableComponent PrimaryTarget = UPlayerTargetablesComponent::GetOrCreate(UserComponent.Owner).GetPrimaryTargetForCategory(GravityWhip::Grab::SlingTargetableCategory);
		if(PrimaryTarget != nullptr && bUseFocusLocation)
		{
			HomingProjectileComp.Target = Cast<AHazeActor>(PrimaryTarget.Owner);
			Dir = (Cast<AHazeActor>(PrimaryTarget.Owner).FocusLocation - ActorLocation).GetSafeNormal();
		}
		
		SetActorVelocity(Dir * SlingSpeed);
		Collision.SetSphereRadius(10.0); // HAX to avoid unwanted collision in the path

		UWhipSlingableObjectEventHandler::Trigger_OnThrown(this);
	}

	TArray<FHitResult> GetImpacts()
	{
		TArray<FHitResult> HitResults;

		if (MovementComponent.HasGroundContact())
			HitResults.Add(MovementComponent.GroundContact.ConvertToHitResult());

		if (MovementComponent.HasWallContact())
			HitResults.Add(MovementComponent.WallContact.ConvertToHitResult());

		if (MovementComponent.HasCeilingContact())
			HitResults.Add(MovementComponent.CeilingContact.ConvertToHitResult());

		return HitResults;
	}

	TArray<AActor> GetImpactTeamMembers()
	{
		TArray<AActor> Members;

		auto Team = HazeTeam::GetTeam(n"GravityWhipImpactTeam");
		if (Team != nullptr)
		{
			auto TeamMembers = Team.GetMembers();
			for (int i = TeamMembers.Num() - 1; i >= 0; --i)
			{
				auto Member = TeamMembers[i];
				if (Member == nullptr)
					continue;
				if (!ActorLocation.IsWithinDist(Member.ActorLocation, RadialDamageRadius))
					continue;

				Members.Add(Member);
			}
		}

		return Members;
	}

	FQuat GetMovementRotation(float DeltaTime)
	{
		return ActorQuat * FQuat(AngularVelocity.GetSafeNormal(), AngularVelocity.Size() * DeltaTime);
	}

	UFUNCTION()
	void AddDisabler(FInstigator DisableInstigator)
	{
		if (!HasControl())
			return;

		CrumbAddDisabler(DisableInstigator);
	}
		
	UFUNCTION(CrumbFunction)
	void CrumbAddDisabler(FInstigator Instigator)
	{
		if (DisableInstigators.Num() == 0)
			GravityWhipTargetComponent.Disable(this);

		DisableInstigators.AddUnique(Instigator);
	}

	UFUNCTION()
	void RemoveDisabler(FInstigator DisableInstigator)
	{
		if (!HasControl())
			return;

		CrumbRemoveDisabler(DisableInstigator);
	}

	UFUNCTION(CrumbFunction)
	void CrumbRemoveDisabler(FInstigator Instigator)
	{
		DisableInstigators.Remove(Instigator);

		if (DisableInstigators.Num() == 0)
			GravityWhipTargetComponent.Enable(this);
	}

	UFUNCTION(CrumbFunction)
	void CrumbLifeTimeExpired()
	{
		if (bSpawnHitEffectAfterLifetimeExpired)
			SpawnHitEffect(FVector::ZeroVector);
		DestroyOrUnSpawn();
	}

	void DestroyOrUnSpawn()
	{
		if (SpawnPool != nullptr)
		{
			SpawnPool.UnSpawn(this);
			bThrown = false;

			DisableComp.SetEnableAutoDisable(true);
			GravityWhipTargetComponent.Enable(this);
			MovementComponent.RemoveMovementIgnoresActor(this);
			RemainingLifeTime = LifeTimeAfterThrown;
			HomingProjectileComp.Target = nullptr;

			AddActorDisable(n"UnSpawned");
		}
		else
		{
			DestroyActor();
		}
	}
}