class USummitKnightCrystalCageLauncher : UBasicAINetworkedProjectileLauncherComponent
{
}

struct FSummitKnightCrystalCageSegment
{
	FName Name;
	UStaticMeshComponent Mesh;
	USummitKnightCrystalCageCollisionComponent Collision;
	FHazeAcceleratedFloat AccScale;
	float StartGrowTime;
	float FullScale;
	bool bSpawned = false;
	bool bSmashed = false;
	bool bIsDisabled = false;

	void Smash(AHazeActor Owner, ASummitKnightMobileArena Arena)
	{
		if (bIsDisabled)
			return;

		if (!bSmashed)
		{
			bSmashed = true;
			Mesh.AddComponentVisualsBlocker(Owner);
			Collision.AddComponentCollisionBlocker(Owner);
			USummitKnightCrystalCageEventHandler::Trigger_OnSmashSegment(Owner, FSummitKnightCrystalCageSegmentParams(Mesh, Arena));
		}
	}

	void Restore(AHazeActor Owner)
	{
		if (bSmashed)
		{
			bSmashed = false;
			Mesh.RemoveComponentVisualsBlocker(Owner);
			Collision.RemoveComponentCollisionBlocker(Owner);
		}
		bSpawned = false;
	}

	void Disable()
	{
		if (bIsDisabled)
			return;

		bIsDisabled = true;
		Mesh.AddComponentVisualsAndCollisionAndTickBlockers(n"SegmentDisabler");		
		Collision.AddComponentVisualsAndCollisionAndTickBlockers(n"SegmentDisabler");
		bSpawned = false;
	}

	void Enable()
	{
		if (!bIsDisabled)
			return;

		bIsDisabled = false;
		Mesh.RemoveComponentVisualsAndCollisionAndTickBlockers(n"SegmentDisabler");		
		Collision.RemoveComponentVisualsAndCollisionAndTickBlockers(n"SegmentDisabler");
	}

	void Copy(UStaticMeshComponent TemplateMesh, USummitKnightCrystalCageCollisionComponent TemplateCollision)
	{
		Mesh = UStaticMeshComponent::Create(TemplateMesh.Owner, FName(Name + "_Mesh"));
		Mesh.StaticMesh = TemplateMesh.StaticMesh;
		for (int iMat = 0; iMat < TemplateMesh.GetNumMaterials(); iMat++)
		{
			Mesh.SetMaterial(iMat, TemplateMesh.Materials[iMat]);
		}			
		Mesh.CollisionProfileName = n"NoCollision";	

		Collision = USummitKnightCrystalCageCollisionComponent::Create(TemplateCollision.Owner, FName(Name + "_Collision"));
		Collision.CapsuleHalfHeight = TemplateCollision.CapsuleHalfHeight;
		Collision.CapsuleRadius = TemplateCollision.CapsuleRadius;
		Collision.RelativeTransform = TemplateCollision.RelativeTransform;

		// For some reason, these do not get set by constructor
		Collision.CollisionProfileName = n"BlockOnlyPlayerCharacter";
		Collision.CollisionObjectType = ECollisionChannel::ECC_WorldDynamic;
		Collision.CollisionEnabled = ECollisionEnabled::QueryAndPhysics;
		Collision.SetCollisionResponseToChannel(ECollisionChannel::WeaponTraceZoe, ECollisionResponse::ECR_Block);
		Collision.SetCollisionResponseToChannel(ECollisionChannel::ECC_Camera, ECollisionResponse::ECR_Ignore);

		Mesh.AttachToComponent(Collision);
	}
}

class USummitKnightCrystalCageCollisionComponent : UHazeCapsuleCollisionComponent
{
	default bGenerateOverlapEvents = false;
	default CapsuleHalfHeight = 600.0;
	default CapsuleRadius = 200.0;
	default CollisionProfileName = n"BlockOnlyPlayerCharacter";
	default CollisionObjectType = ECollisionChannel::ECC_WorldDynamic;
	default CollisionEnabled = ECollisionEnabled::QueryAndPhysics;
	default SetCollisionResponseToChannel(ECollisionChannel::WeaponTraceZoe, ECollisionResponse::ECR_Block);
	default SetCollisionResponseToChannel(ECollisionChannel::ECC_Camera, ECollisionResponse::ECR_Ignore);
}

class ASummitKnightCrystalCage : AHazeActor
{
	default PrimaryActorTick.bStartWithTickEnabled = false;

	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent)
	USummitKnightCrystalCageCollisionComponent SmashCollision;

	UPROPERTY(DefaultComponent, Attach = "SmashCollision")
	UStaticMeshComponent Mesh;
	default Mesh.CollisionProfileName = n"NoCollision";

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

	UPROPERTY(DefaultComponent)
	UTeenDragonRollAutoAimComponent RollAutoAimComp;

	TArray<FSummitKnightCrystalCageSegment> Segments;

	USummitKnightSettings Settings;
	USummitKnightComponent KnightComp;
	UTeenDragonRollComponent RollComp;
	ASummitKnightMobileArena Arena;
	AHazePlayerCharacter Target;
	float ExpirationTime;
	FVector DefaultScale;
	FVector ArcStart;
	FVector ArcStartControl;
	FVector ArcEnd;
	FVector ArcEndControl;
		
	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		SetActorControlSide(Game::Zoe);

		TailAttackResponseComp.OnHitByRoll.AddUFunction(this, n"OnHitByRoll");

		DefaultScale = Mesh.WorldScale;

		FSummitKnightCrystalCageSegment Segment;
		Segment.Name = n"Segment0";
		Segment.Mesh = Mesh;
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
	}

	UFUNCTION()
	private void OnHitByRoll(FRollParams Params)
	{
		if (!ProjectileComp.bIsLaunched)	
			return;

		int SmashWidth = Settings.CrystalCageSmashSegmentsHalfWidth;
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
						Segments[iSmash].Smash(this, Arena);
				}
				break;
			}
		} 

		// The rest of the cage retract after one segment was hit
		ExpirationTime = Time::GetGameTimeSince(ProjectileComp.LaunchTime) + Settings.CrystalCageSmashedExpirationDuration;
	}

	void Spawn(AHazePlayerCharacter PlayerTarget, ASummitKnightMobileArena KnightArena, FVector ArcStartLoc, FVector ArcStartTangent, FVector ArcEndLoc, FVector ArcEndTangent, FVector FrontPoint)
	{
		Target = PlayerTarget;
		Arena = KnightArena;
		Settings = USummitKnightSettings::GetSettings(ProjectileComp.Launcher);
		KnightComp = USummitKnightComponent::Get(ProjectileComp.Launcher);
		ExpirationTime = Settings.CrystalCageExpirationDuration;

		SetActorLocation(Arena.GetClampedToArena(PlayerTarget.ActorLocation));
		SetActorRotation(FRotator::MakeFromZX(FVector::UpVector, PlayerTarget.ViewRotation.ForwardVector));

		ArcStart = ArcStartLoc;
		ArcStartControl = ArcStartLoc + ArcStartTangent;
		ArcEndControl = ArcEndLoc - ArcEndTangent;
		ArcEnd = ArcEndLoc;

		// Set up segments
		float SegmentWidth = SmashCollision.CapsuleRadius * 2.0;
		float ArcLength = BezierCurve::GetLength_3CP(ArcStart, ArcStartControl, FrontPoint, ArcEndControl, ArcEnd);
		int NumSegments = Math::TruncToInt(ArcLength / SegmentWidth);
		for (int i = Segments.Num(); i < NumSegments; i++)
		{
			// Create new segments as needed
			FSummitKnightCrystalCageSegment Segment;
			Segment.Name = FName("Segment" + Segments.Num());
			Segment.Copy(Mesh, SmashCollision);
			Segments.Add(Segment);
		}
		for (int i = NumSegments - 1; i < Segments.Num(); i++)
		{
			// Disable extraneous segments
			Segments[i].Disable();
		}
		
		// Prepare all segments for spawn with current settings
		for (int i = 0; i < NumSegments; i++)
		{
			Segments[i].Enable();
			float Alpha = float(i) / float(NumSegments);
			Segments[i].AccScale.SnapTo(0.0001);
			Segments[i].StartGrowTime = Alpha * Settings.CrystalCageSpreadDuration;
			Segments[i].FullScale = Math::RandRange(0.9, 1.2);
			Segments[i].Collision.WorldLocation = BezierCurve::GetLocation_3CP_ConstantSpeed(ArcStart, ArcStartControl, FrontPoint, ArcEndControl, ArcEnd, Alpha) + 
												  FVector::UpVector * Segments[i].Collision.CapsuleHalfHeight * Segments[i].FullScale;
			Segments[i].Restore(this);
		}

//		MovableCameraShakeComp.ActivateMovableCameraShake();
		ForceFeedbackComp.Play();
		USummitKnightCrystalCageEventHandler::Trigger_OnSpawned(this);	
	}

	// Projectile will start ticking when launched and will be disabled when it expires
	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		if (!ProjectileComp.bIsLaunched)
			return;

		float ActiveDuration = Time::GetGameTimeSince(ProjectileComp.LaunchTime);
		if (HasControl() && (ActiveDuration > ExpirationTime))
			CrumbExpire();

		// Update segments
		float ExpirationScale = Math::GetMappedRangeValueClamped(
			FVector2D(Settings.CrystalCageSmashedExpirationDuration, 0.0), 
			FVector2D(1.0, 0.001), 
			ExpirationTime - ActiveDuration);
		for (FSummitKnightCrystalCageSegment& Segment : Segments)
		{
			if (Segment.bIsDisabled)
				continue;

			if (ActiveDuration < Segment.StartGrowTime)
			{
				Segment.Mesh.WorldScale3D = DefaultScale * 0.001;
				continue;
			}

			if (!Segment.bSpawned)
				USummitKnightCrystalCageEventHandler::Trigger_OnSpawnSegment(this, FSummitKnightCrystalCageSegmentParams(Segment.Mesh, Arena));
			Segment.bSpawned = true;

			Segment.AccScale.AccelerateTo(Segment.FullScale * ExpirationScale, Settings.CrystalCageSegmentGrowthDuration, DeltaTime);
			Segment.Mesh.WorldScale3D = DefaultScale * Segment.AccScale.Value;
			FVector Loc = Segment.Mesh.RelativeLocation;
			Loc.Z = -40.0 - SmashCollision.CapsuleHalfHeight * 2.0 * (1.0 - Segment.AccScale.Value);
			Segment.Mesh.RelativeLocation = Loc;
		}

		// TODO: Push from growing segments
	}

	UFUNCTION(CrumbFunction)
	void CrumbExpire()
	{
		if(ProjectileComp.bIsExpired)
			return;
		USummitKnightCrystalCageEventHandler::Trigger_OnExpired(this);
		ProjectileComp.Expire();
		MovableCameraShakeComp.DeactivateMovableCameraShake();
		ForceFeedbackComp.Stop();
	}	
}

UCLASS(Abstract)
class USummitKnightCrystalCageEventHandler : UHazeEffectEventHandler
{
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnSpawnSegment(FSummitKnightCrystalCageSegmentParams Params) {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnSmashSegment(FSummitKnightCrystalCageSegmentParams Params) {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnExpired() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnSpawned() {}
}


struct FSummitKnightCrystalCageSegmentParams 
{
	UPROPERTY()
	FVector GroundLocation;

	UPROPERTY()
	UStaticMeshComponent Mesh;

	FSummitKnightCrystalCageSegmentParams(UStaticMeshComponent CrystalMesh, ASummitKnightMobileArena Arena)
	{
		GroundLocation = Arena.GetAtArenaHeight(CrystalMesh.WorldLocation);
		Mesh = CrystalMesh;
	}
}
