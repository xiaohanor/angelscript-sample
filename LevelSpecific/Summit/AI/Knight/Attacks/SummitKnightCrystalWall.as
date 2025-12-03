class USummitKnightCrystalWallLauncher : UBasicAINetworkedProjectileLauncherComponent
{
}

struct FSummitKnightCrystalWallSegment
{
	FName Name;
	TArray<UStaticMeshComponent> Meshes;
	USummitKnightCrystalWallCollisionComponent Collision;
	int GrowthIndex;
	FHazeAcceleratedFloat AccScale;
	float StartGrowTime;
	float FullScale;
	bool bSmashed = false;
	bool bIsDisabled = false;

	void Smash(AHazeActor Owner)
	{
		if (bIsDisabled)
			return;

		if (!bSmashed)
		{
			bSmashed = true;
			for (UStaticMeshComponent Mesh : Meshes)
			{
				Mesh.AddComponentVisualsBlocker(Owner);
			}
			Collision.AddComponentCollisionBlocker(Owner);
			USummitKnightCrystalWallEventHandler::Trigger_OnSmashSegment(Owner, FSummitKnightCrystalWallSmashSegmentParams(Collision.WorldLocation));
		}
	}

	void Restore(AHazeActor Owner)
	{
		if (bSmashed)
		{
			bSmashed = false;
			for (UStaticMeshComponent Mesh : Meshes)
			{
				Mesh.RemoveComponentVisualsBlocker(Owner);
			}
			Collision.RemoveComponentCollisionBlocker(Owner);
		}
	}

	void Disable()
	{
		if (bIsDisabled)
			return;

		bIsDisabled = true;
		for (UStaticMeshComponent Mesh : Meshes)
		{
			Mesh.AddComponentVisualsAndCollisionAndTickBlockers(n"SegmentDisabler");		
		}
		Collision.AddComponentVisualsAndCollisionAndTickBlockers(n"SegmentDisabler");
	}

	void Enable()
	{
		if (!bIsDisabled)
			return;

		bIsDisabled = false;
		for (UStaticMeshComponent Mesh : Meshes)
		{
			Mesh.RemoveComponentVisualsAndCollisionAndTickBlockers(n"SegmentDisabler");		
		}
		Collision.RemoveComponentVisualsAndCollisionAndTickBlockers(n"SegmentDisabler");
	}

	void CopyMesh(UStaticMeshComponent TemplateMesh)
	{
		for (int i = 0; i < 5; i++)
		{
			UStaticMeshComponent Mesh = UStaticMeshComponent::Create(TemplateMesh.Owner, FName(Name + "_Mesh" + i));
			Mesh.StaticMesh = TemplateMesh.StaticMesh;
			for (int iMat = 0; iMat < TemplateMesh.GetNumMaterials(); iMat++)
			{
				Mesh.SetMaterial(iMat, TemplateMesh.Materials[iMat]);
			}			
			Mesh.CollisionProfileName = n"NoCollision";	
			Mesh.DetachFromParent();
			Meshes.Add(Mesh);
		}
	}

	void CopyCollision(USummitKnightCrystalWallCollisionComponent TemplateCollision)
	{
		Collision = USummitKnightCrystalWallCollisionComponent::Create(TemplateCollision.Owner, FName(Name + "_Collision"));
		Collision.CapsuleHalfHeight = TemplateCollision.CapsuleHalfHeight;
		Collision.CapsuleRadius = TemplateCollision.CapsuleRadius;
		Collision.RelativeTransform = TemplateCollision.RelativeTransform;

		// For some reason, these do not get set by constructor
		Collision.CollisionProfileName = n"BlockOnlyPlayerCharacter";
		Collision.CollisionObjectType = ECollisionChannel::ECC_WorldDynamic;
		Collision.CollisionEnabled = ECollisionEnabled::QueryAndPhysics;
		Collision.SetCollisionResponseToChannel(ECollisionChannel::WeaponTraceZoe, ECollisionResponse::ECR_Block);
		Collision.SetCollisionResponseToChannel(ECollisionChannel::ECC_Camera, ECollisionResponse::ECR_Ignore);
	}
}

class USummitKnightCrystalWallCollisionComponent : UHazeCapsuleCollisionComponent
{
	default bGenerateOverlapEvents = false;
	default CapsuleHalfHeight = 800.0;
	default CapsuleRadius = 200.0;
	default CollisionProfileName = n"BlockOnlyPlayerCharacter";
	default CollisionObjectType = ECollisionChannel::ECC_WorldDynamic;
	default CollisionEnabled = ECollisionEnabled::QueryAndPhysics;
	default SetCollisionResponseToChannel(ECollisionChannel::WeaponTraceZoe, ECollisionResponse::ECR_Block);
	default SetCollisionResponseToChannel(ECollisionChannel::ECC_Camera, ECollisionResponse::ECR_Ignore);
}

class ASummitKnightCrystalWall : AHazeActor
{
	default PrimaryActorTick.bStartWithTickEnabled = false;

	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent)
	UStaticMeshComponent Mesh;
	default Mesh.CollisionProfileName = n"NoCollision";

	UPROPERTY(DefaultComponent)
	USummitKnightCrystalWallCollisionComponent SmashCollision;

	UPROPERTY(DefaultComponent)
	UBasicAIProjectileComponent ProjectileComp;

	UPROPERTY(DefaultComponent)
	UHazeActorRespawnableComponent RespawnComp;

	UPROPERTY(DefaultComponent)
	UMovableCameraShakeComponent MovableCameraShakeComp;

	UPROPERTY(DefaultComponent)
	UForceFeedbackComponent ForceFeedbackComp;

	UPROPERTY(DefaultComponent)
	UTeenDragonTailAttackResponseComponent TailAttackResponseComp;
	default TailAttackResponseComp.ImpactType = ETailAttackImpactType::Enemy;
	default TailAttackResponseComp.bIsPrimitiveParentExclusive = false;
	default TailAttackResponseComp.bShouldStopPlayer = true;

	// TODO: Move this to remaining segments to make it easy to hit small segments (large ones should not be hard to hit)
	UPROPERTY(DefaultComponent)
	UTeenDragonRollAutoAimComponent RollAutoAimComp;

	TArray<FSummitKnightCrystalWallSegment> Segments;

	USummitKnightSettings Settings;
	USummitKnightComponent KnightComp;
	UTeenDragonRollComponent RollComp;
	ASummitKnightMobileArena Arena;
	FVector DefaultScale;
	float SpeedFactor = 1.0;
	FHazeAcceleratedFloat AccelWallSpeed;
	FVector StartLocation;
	const float InsideOffset = 100.0;
	TPerPlayer<float> CheckDragonPushTime;
	
	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		SetActorControlSide(Game::Mio);

		TailAttackResponseComp.OnHitByRoll.AddUFunction(this, n"OnHitByRoll");

		DefaultScale = Mesh.WorldScale;

		FSummitKnightCrystalWallSegment Segment;
		Segment.Name = n"Segment0";
		Segment.CopyMesh(Mesh);
		Segment.Collision = SmashCollision;
		Segment.AccScale.SnapTo(0.0);
		Segment.StartGrowTime = 0.0;
		Segment.FullScale = 1.0;
		Segments.Add(Segment);

		// Original mesh is not used
		Mesh.AddComponentVisualsBlocker(this);
		Mesh.AddComponentTickBlocker(this);
		Mesh.AddComponentCollisionBlocker(this);

		RollComp = UTeenDragonRollComponent::Get(Game::Zoe);

		ProjectileComp.OnLaunch.AddUFunction(this, n"Launched");
	}

	UFUNCTION()
	private void Launched(UBasicAIProjectileComponent Projectile)
	{
		MovableCameraShakeComp.ActivateMovableCameraShake();
		USummitKnightCrystalWallEventHandler::Trigger_OnLaunched(this);	
		ForceFeedbackComp.Play();
	}

	UFUNCTION()
	private void OnHitByRoll(FRollParams Params)
	{
		if (!ProjectileComp.bIsLaunched)	
			return;

		int SmashWidth = Settings.CrystalWallSmashSegmentWidth;
		for (int iSegment = 0; iSegment < Segments.Num(); iSegment++)
		{
			if (Params.HitComponent == Segments[iSegment].Collision)
			{
				// Smash surrounding segments
				for (int iOffset = -SmashWidth; iOffset <= SmashWidth; iOffset++)
				{
					int iSmash = iSegment + (iOffset * 2);
					if (iSmash < 0)
						iSmash = -iSmash - 1;
					if (Segments.IsValidIndex(iSmash))
						Segments[iSmash].Smash(this);
				}
				break;
			}
		} 
	}

	void Launch(ASummitKnightMobileArena KnightArena, float WallSpeedFactor)
	{
		Arena = KnightArena;
		Settings = USummitKnightSettings::GetSettings(ProjectileComp.Launcher);
		KnightComp = USummitKnightComponent::Get(ProjectileComp.Launcher);
		SpeedFactor = WallSpeedFactor;

		StartLocation = Arena.GetClampedToArena(ActorLocation, InsideOffset);
		SetActorLocation(StartLocation);
		SetActorRotation(FRotator::MakeFromZX(FVector::UpVector, Arena.Center - StartLocation));

		// Set up segments
		int NumSegments = Settings.CrystalWallSegmentsHalfWidth * 2 + 1;
		for (int i = Segments.Num(); i < NumSegments; i++)
		{
			// Create new segments as needed
			FSummitKnightCrystalWallSegment Segment;
			Segment.Name = FName("Segment" + Segments.Num());
			Segment.CopyMesh(Mesh);
			Segment.CopyCollision(SmashCollision);
			Segments.Add(Segment);
		}
		for (int i = NumSegments - 1; i < Segments.Num(); i++)
		{
			// Disable extraneous segments
			Segments[i].Disable();
		}
		
		// Prepare all segments for launch with current settings
		float Width = Math::Max(1.0, float(Settings.CrystalWallSegmentsHalfWidth));
		for (int i = 0; i < NumSegments; i++)
		{
			Segments[i].Enable();
			float Alpha = Math::FloorToFloat((i + 1.001) / 2.0) / Width;
			FVector Offset = SmashCollision.RelativeLocation;
			Offset.X += Math::EaseIn(0.0, 1.0, Alpha, 3.0) * Settings.CrystalWallCurvature; // Sweep forward at edges
			Offset.Y += ((i % 2) * 2.0 - 1.0) * Alpha * SmashCollision.CapsuleRadius * Width * 1.0; // Move outwards at regular intervals
			Segments[i].Collision.RelativeLocation = Offset;
			Segments[i].AccScale.SnapTo(0.0);
			Segments[i].StartGrowTime = Alpha * Settings.CrystalWallSegmentSpreadDuration;
			Segments[i].FullScale = 1.0 - (Alpha * 0.3);
			Segments[i].GrowthIndex = -1;
			for (UStaticMeshComponent& SegMesh : Segments[0].Meshes)
			{
				SegMesh.WorldScale3D = FVector::OneVector * 0.001;
				SegMesh.WorldLocation = Segments[i].Collision.WorldLocation;
			}
			Segments[i].Restore(this);
		}

		AccelWallSpeed.SnapTo(Settings.CrystalWallMoveSpeedStart);
		for(AHazePlayerCharacter Player : Game::Players)
			CheckDragonPushTime[Player] = 0.0;
	}

	// Projectile will start ticking when launched and will be disabled when it expires
	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		if (!ProjectileComp.bIsLaunched)
			return;

		FTransform PrevTransform = ActorTransform;	

		// Move along arena
		float TargetSpeed = Settings.CrystalWallMoveSpeedTarget;
		TargetSpeed *= SpeedFactor;
		AccelWallSpeed.AccelerateTo(TargetSpeed, Settings.CrystalWallSpeedUpDuration, DeltaTime);
		ActorLocation += ActorForwardVector * AccelWallSpeed.Value * DeltaTime;
			
		float RemainingDistance = (Arena.Radius * 2.0) - InsideOffset - StartLocation.Dist2D(ActorLocation);
		if (HasControl() && (RemainingDistance < InsideOffset))
			CrumbExpire();

		// Update segments
		float ActiveDuration = Time::GetGameTimeSince(ProjectileComp.LaunchTime);
		FVector Dir = ActorForwardVector;
		float ExpirationScale = Math::GetMappedRangeValueClamped(FVector2D(500.0, 0.0), FVector2D(1.0, 0.001), RemainingDistance);
		for (FSummitKnightCrystalWallSegment& Segment : Segments)
		{
			if (Segment.bIsDisabled)
				continue;

			if (ActiveDuration < Segment.StartGrowTime)
			{
				for (int i = 0; i < Segment.Meshes.Num(); i++)
				{
					Segment.Meshes[i].WorldScale3D = DefaultScale * 0.001;
				}
				continue;
			}

			float Interval = Segment.Collision.CapsuleRadius;
			float GrowDistance = Interval * 2.0;
			if ((Segment.GrowthIndex < 0) || 
				(Dir.DotProduct(Segment.Meshes[Segment.GrowthIndex % Segment.Meshes.Num()].WorldLocation - Segment.Collision.WorldLocation - Dir * Interval) < 0.0))
			{
				// Start growing a new crystal since current one is close enough to collision along growth direction
				Segment.GrowthIndex++;
				int iNew = Segment.GrowthIndex % Segment.Meshes.Num();
				Segment.Meshes[iNew].WorldLocation = Segment.Collision.WorldLocation + Dir * GrowDistance;
				Segment.Meshes[iNew].WorldScale3D = FVector::OneVector * 0.001;
			}	

			float PauseInterval = Interval * 0.5;
			float RetractDistance = (Interval * Segment.Meshes.Num()) - PauseInterval - GrowDistance;
			for (int i = 0; i < Segment.Meshes.Num(); i++)
			{
				float Scale = 0.0;
				if (Segment.GrowthIndex >= i)
				{
					float Dist = Dir.DotProduct(Segment.Meshes[i].WorldLocation - Segment.Collision.WorldLocation);
					if (Dist > 0.0)
						Scale = Math::Clamp(Math::EaseIn(1.0, 0.001, Dist / (2.0 * Interval), 2.0), 0.001, 1.0); 					
					else if (Dist > -PauseInterval)
						Scale = 1.0;
					else
						Scale = Math::Clamp(Math::EaseInOut(1.0, 0.001, (Math::Abs(Dist) - PauseInterval) / RetractDistance, 2.0), 0.001, 1.0); 
				}
				Segment.Meshes[i].WorldScale3D = DefaultScale * Scale * Segment.FullScale * ExpirationScale;
				FVector Loc = Segment.Meshes[i].WorldLocation;
				Loc.Z = Segment.Collision.WorldLocation.Z - ((1.0 - Scale) * Mesh.RelativeLocation.Z);
				Segment.Meshes[i].WorldLocation = Loc;
			}
		}

		if (ExpirationScale > 0.99)
		{
			for(AHazePlayerCharacter Player : Game::Players)
			{
				if(!Player.HasControl())
					continue;
				if(ActiveDuration < CheckDragonPushTime[Player])
					continue;

				for (int iSegment = 0; iSegment < Segments.Num(); iSegment++)
				{
					FSummitKnightCrystalWallSegment& Segment = Segments[iSegment];
					if (Segment.bSmashed)
						continue;
					if (RollComp.Player == Player && RollComp.IsRolling())
						continue;
					FVector SegmentProbeLoc = Segment.Collision.WorldLocation + Dir * 150.0;
					if (SegmentProbeLoc.IsWithinDist2D(Player.ActorLocation, Segment.Collision.ScaledCapsuleRadius))	
					{
						// Stumble is internally networked
						UTeenDragonStumbleComponent StumbleComp = UTeenDragonStumbleComponent::GetOrCreate(Player);		
						if (Time::GetGameTimeSince(StumbleComp.LastStumbleTime) > 0.0)
						{
							FTeenDragonStumble Stumble;
							Stumble.Duration = 0.6;
							float Distance = Settings.CrystalWallDragonStumbleDistance;
							float HeightFraction = 0.4;
							Stumble.Move = (Dir * (1.0 - HeightFraction) + FVector::UpVector * HeightFraction) * Distance;
							Stumble.ArcHeight = Distance * 0.2;
							Stumble.Apply(Player);
							CheckDragonPushTime[Player]	= ActiveDuration + Stumble.Duration + 0.1;
						}			
						Player.DamagePlayerHealth(Settings.CrystalWallPlayerDamage);

						// Smash surrounding segments
						for (int iOffset = -1; iOffset <= 1; iOffset++)
						{
							int iSmash = iSegment + (iOffset * 2);
							if (iSmash < 0)
								iSmash = -iSmash - 1;
							if (Segments.IsValidIndex(iSmash))
								Segments[iSmash].Smash(this);
						}
						break;
					}
				}
			}
		}
	}

	UFUNCTION(CrumbFunction)
	void CrumbExpire()
	{
		if(ProjectileComp.bIsExpired)
			return;
		USummitKnightCrystalWallEventHandler::Trigger_OnExpired(this);
		ProjectileComp.Expire();
		MovableCameraShakeComp.DeactivateMovableCameraShake();
		ForceFeedbackComp.Stop();
	}	
}

UCLASS(Abstract)
class USummitKnightCrystalWallEventHandler : UHazeEffectEventHandler
{
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnSmashSegment(FSummitKnightCrystalWallSmashSegmentParams Params) {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnExpired() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnLaunched() {}
}


struct FSummitKnightCrystalWallSmashSegmentParams 
{
	UPROPERTY()
	FVector Location;

	FSummitKnightCrystalWallSmashSegmentParams(FVector Loc)
	{
		Location = Loc;
	}
}
