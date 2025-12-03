UCLASS(NotBlueprintable, HideCategories = "ComponentTick Disable Activation Cooking ArrowComponent Collision Physics Lighting Navigation VirtualTexture Tags LOD HLOD TextureStreaming RayTracing")
class UMaxSecurityLaserComponent : USceneComponent
{
	access Internal = protected, AMaxSecurityLaserInvisible, UMaxSecurityLaserVisualizer;
	access Audio = private, UWorld_Prison_MaxSecurity_Spot_MaxSecurityLaser_SoundDef;

	UPROPERTY(EditAnywhere, Category = "Laser Component")
	bool bShowEmitter = true;

	UPROPERTY(EditAnywhere, Category = "Laser Component")
	float BeamLength = 1000.0;

	UPROPERTY(EditAnywhere, Category = "Laser Component")
	float BeamWidth = 3.0;

	UPROPERTY(EditAnywhere, Category = "Laser Component")
	private FVector BeamStartOffset = FVector(10.0, 0.0, 0.0);

	UPROPERTY(EditAnywhere, Category = "Laser Component")
	access:Internal
	bool bDamagePlayers = true;

	UPROPERTY(EditAnywhere, Category = "Laser Component")
	TSubclassOf<UDeathEffect> DeathEffect;

	UPROPERTY(EditDefaultsOnly, Category = "Laser Component")
	access:Internal
	bool bHideLaserOnStart = false;

	UPROPERTY(EditAnywhere, Category = "Laser Component", Meta = (EditCondition = "bDamagePlayers", ClampMin = "0.0", ClampMax = "1.0", UIMin = "0.0", UIMax = "1.0", EditConditionHides))
	float Damage = 1.0;

	UPROPERTY(EditAnywhere, Category = "Laser Component|Laser Effect")
	access:Internal
	bool bAutoSetBeamStartAndEnd = true;

	UPROPERTY(EditAnywhere, Category = "Laser Component|Impact Effect")
	access:Internal
	bool bShowImpactEffect = true;

	UPROPERTY(EditAnywhere, Category = "Laser Component|Impact Effect", Meta = (EditCondition = "bShowImpactEffect"))
	access:Internal
	bool bTraceForImpact = true;

	UPROPERTY(EditAnywhere, Category = "Laser Component|Impact Effect", Meta = (EditCondition = "bShowImpactEffect"))
	private UNiagaraSystem ImpactEffectSystem;

	UPROPERTY(EditAnywhere, Category = "Laser Component|Impact Effect", Meta = (EditCondition = "bShowImpactEffect"))
	private float SpawnImpactEffectDistance = 3000;

	UPROPERTY(EditAnywhere, Category = "Laser Component|Impact Effect", Meta = (EditCondition = "bShowImpactEffect"))
	private TArray<AActor> TraceIgnoreActors;

	access:Audio
	FVector CurrentBeamStartLoc;
	access:Audio
	FVector CurrentBeamEndLoc;

	UStaticMeshComponent LaserMeshComp;
	private UNiagaraComponent ImpactEffectComp;

	UFUNCTION(BlueprintOverride)
	void OnComponentModifiedInEditor()
	{
		LaserMeshComp = UStaticMeshComponent::Get(Owner, n"LaserMeshComp");
		if(LaserMeshComp == nullptr)
			return;

		SetBeamLength(BeamLength);
	}

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		LaserMeshComp = UStaticMeshComponent::Get(Owner, n"LaserMeshComp");
		devCheck(LaserMeshComp != nullptr, f"Laser Component {this} expects to find a static mesh component called LaserMeshComp on the same actor.");
		SetBeamLength(BeamLength);

		if(bHideLaserOnStart)
			LaserMeshComp.SetHiddenInGame(true);
	}

	void ExternalTick(float DeltaSeconds)
	{
		if (bTraceForImpact)
		{
			// Trace against the world to place impact VFX, also used to kill the player on hit

			FHazeTraceSettings Trace = Trace::InitChannel(ECollisionChannel::ECC_Visibility);
			Trace.IgnoreActor(Owner);
			for (AActor Actor : TraceIgnoreActors)
				Trace.IgnoreActor(Actor);
			Trace.UseLine();

			FHitResult Hit = Trace.QueryTraceSingle(GetBeamStart(), GetUnobstructedBeamEnd());

			// Check if we hit a player first, so we can ignore the players and trace again
			if(Hit.bBlockingHit && bDamagePlayers)
			{
				// Allow 2 retries (one for each player)
				for(int i = 0; i < 2; i++)
				{
					AHazePlayerCharacter Player = Cast<AHazePlayerCharacter>(Hit.Actor);
					if(Player != nullptr)
					{
						// We hit a player, kill, then ignore and trace again to not stop at the player capsule
						if(Player.HasControl())
						{
							if (Math::IsNearlyEqual(Damage, 1.0))
								Player.KillPlayer();
							else
								Player.DamagePlayerHealth(Damage);
						}

						Trace.IgnoreActor(Player);
						Hit = Trace.QueryTraceSingle(GetBeamStart(), GetUnobstructedBeamEnd());
					}
				}
			}

			FVector BeamEndLoc = Hit.TraceEnd;
			if (Hit.bBlockingHit)
			{
				BeamEndLoc = Hit.ImpactPoint;
				if (bShowImpactEffect)
				{
					const float DistanceToClosestPlayer = Game::GetDistanceFromLocationToClosestPlayer(Hit.ImpactPoint);
					if(DistanceToClosestPlayer < SpawnImpactEffectDistance)
					{
						TrySpawnImpactEffect();

						if(ImpactEffectComp != nullptr)
						{
							ImpactEffectComp.SetWorldLocation(BeamEndLoc);
							FVector ImpactDir = -ForwardVector;
							ImpactEffectComp.SetWorldRotation(ImpactDir.Rotation());
							ActivateImpactEffect();
						}
					}
					else
					{
						DeactivateImpactEffect();
					}
				}
			}
			else
			{
				if (bShowImpactEffect)
					DeactivateImpactEffect();
			}

			if(bAutoSetBeamStartAndEnd)
			{
				if (bTraceForImpact && Hit.bBlockingHit)
					SetBeamLength(Hit.Distance);
				else
					SetBeamLength(BeamLength);
			}
		}
		else if(bDamagePlayers)
		{
			// If we only want to hit the players, make a much cheaper LineTraceComponent instead.

			for(auto Player : Game::Players)
			{
				if(!Player.HasControl())
					continue;
				
				FVector HitLocation;
				FVector HitNormal;
				FName HitBone;
				FHitResult HitResult;
				if(Player.CapsuleComponent.LineTraceComponent(GetBeamStart(), GetUnobstructedBeamEnd(), false, false, false, HitLocation, HitNormal, HitBone, HitResult))
				{
					if (Math::IsNearlyEqual(Damage, 1.0))
						Player.KillPlayer();
					else
						Player.DamagePlayerHealth(Damage);
				}
			}

			if(bAutoSetBeamStartAndEnd)
				SetBeamLength(BeamLength);
		}
		else
		{
			if(bAutoSetBeamStartAndEnd)
				SetBeamLength(BeamLength);
		}
	}

	UFUNCTION(BlueprintOverride)
	void OnActorDisabled()
	{
		DeactivateImpactEffect();
	}

	UFUNCTION(CallInEditor, Category = "Laser Component")
	void InitLaserVariables()
	{
		FHazeTraceSettings Trace = Trace::InitChannel(ECollisionChannel::ECC_Visibility);
		Trace.IgnoreActor(Owner);
		Trace.UseLine();

		FHitResult Hit = Trace.QueryTraceSingle(GetBeamStart(), GetUnobstructedBeamEnd());
		if (Hit.bBlockingHit && bTraceForImpact)
		{
			BeamLength = Hit.Distance;
		}
	}

	private bool TrySpawnImpactEffect()
	{
		devCheck(bShowImpactEffect);
		devCheck(ImpactEffectSystem != nullptr, "No ImpactEffectSystem assigned!");
		if(ImpactEffectComp != nullptr)
			return true;

		ImpactEffectComp = Niagara::SpawnLoopingNiagaraSystemAttached(ImpactEffectSystem, this);
		ImpactEffectComp.SetRelativeLocationAndRotation(FVector::ZeroVector, FRotator::ZeroRotator);
		ImpactEffectComp.SetAutoDestroy(true);

		return ImpactEffectComp != nullptr;
	}

	void ShowLaser()
	{
		devCheck(LaserMeshComp != nullptr);

		if(LaserMeshComp.IsHiddenInGame())
			LaserMeshComp.SetHiddenInGame(false);
	}

	void HideLaser()
	{
		devCheck(LaserMeshComp != nullptr);

		if(!LaserMeshComp.IsHiddenInGame())
			LaserMeshComp.SetHiddenInGame(true);
	}

	void ActivateImpactEffect()
	{
		TrySpawnImpactEffect();

		if(ImpactEffectComp == nullptr)
			return;

		if(ImpactEffectComp.IsActive())
			return;

		ImpactEffectComp.Activate(true);
	}

	void DeactivateImpactEffect()
	{
		if(ImpactEffectComp == nullptr)
			return;

		ImpactEffectComp.DestroyComponent(this);
		ImpactEffectComp = nullptr;
	}

	void SetBeamLength(float Length)
	{
		devCheck(LaserMeshComp != nullptr);

		FTransform Transform = LaserMeshComp.RelativeTransform;
		Transform.Location = BeamStartOffset;
		Transform.Scale3D = FVector(Length, BeamWidth, BeamWidth);
		LaserMeshComp.SetRelativeTransform(Transform);

		CurrentBeamStartLoc = GetBeamStart();
		CurrentBeamEndLoc = GetVisualBeamEnd();
	}

	void SetBeamStartAndEnd(FVector Start, FVector End)
	{
		devCheck(LaserMeshComp != nullptr);

		FVector RelativeStart = WorldTransform.InverseTransformPosition(Start);
		FVector RelativeEnd = WorldTransform.InverseTransformPosition(End);

		float Length = RelativeStart.Distance(RelativeEnd);
		FVector Scale = FVector(Length, BeamWidth, BeamWidth);

		LaserMeshComp.SetRelativeTransform(FTransform(FQuat::Identity, RelativeStart, Scale));

		CurrentBeamStartLoc = Start;
        CurrentBeamEndLoc = End;
	}

	FVector GetBeamStart() const
	{
		return WorldLocation;
		// return WorldTransform.TransformPosition(BeamStartOffset);
	}

	FVector GetUnobstructedBeamEnd() const
	{
		return GetBeamStart() + WorldTransform.Rotation.ForwardVector * BeamLength;
	}

	FVector GetVisualBeamStart() const
	{
		if(LaserMeshComp == nullptr)
			return FVector::ZeroVector;

		return LaserMeshComp.WorldLocation;
	}

	FVector GetVisualBeamEnd() const
	{
		if(LaserMeshComp == nullptr)
			return FVector::ZeroVector;

		return LaserMeshComp.WorldTransform.TransformPosition(FVector(1, 0, 0));
	}

#if EDITOR
	void CopyFrom(UMaxSecurityLaserComponent Other)
	{
		SetRelativeTransform(Other.RelativeTransform);

		BeamLength = Other.BeamLength;
		BeamWidth = Other.BeamWidth;
		BeamStartOffset = Other.BeamStartOffset;
		bDamagePlayers = Other.bDamagePlayers;
		bHideLaserOnStart = Other.bHideLaserOnStart;
		bAutoSetBeamStartAndEnd = Other.bAutoSetBeamStartAndEnd;
		bShowImpactEffect = Other.bShowImpactEffect;
		bTraceForImpact = Other.bTraceForImpact;
		ImpactEffectSystem = Other.ImpactEffectSystem;
		SpawnImpactEffectDistance = Other.SpawnImpactEffectDistance;
	}
#endif
};