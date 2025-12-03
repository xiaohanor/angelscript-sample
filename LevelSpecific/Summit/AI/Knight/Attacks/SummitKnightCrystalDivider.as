class USummitKnightCrystalDividerLauncher : UBasicAINetworkedProjectileLauncherComponent
{
}

struct FSummitKnightCrystalDividerSegment
{
	FName Name;
	UStaticMeshComponent Mesh;
	USummitKnightCrystalDividerCollisionComponent Collision;
	FHazeAcceleratedFloat AccScale;
	float StartGrowTime;
	bool bHidden = false;
	bool bDisabled = false;

	void Smash(AHazeActor Owner)
	{
		if (!bHidden)
		{
			Hide();
			USummitKnightCrystalDividerEventHandler::Trigger_OnSmashSegment(Owner, FSummitKnightCrystalDividerSmashSegmentParams(Collision.WorldLocation));
		}
	}

	void Hide()
	{
		if (bHidden)
			return;
		bHidden = true;
		Mesh.AddComponentVisualsBlocker(n"Hidden");
		Collision.AddComponentCollisionBlocker(n"Hidden");
	}

	void Show()
	{
		if (!bHidden)
			return;
		bHidden = false;
		Mesh.RemoveComponentVisualsBlocker(n"Hidden");
		Collision.RemoveComponentCollisionBlocker(n"Hidden");
	}

	void Disable()
	{
		if (bDisabled)
			return;
		bDisabled = true;
		Mesh.AddComponentVisualsAndCollisionAndTickBlockers(n"Disabled");
		Collision.AddComponentVisualsAndCollisionAndTickBlockers(n"Disabled");
	}

	void Enable()
	{
		if (!bDisabled)
			return;
		bDisabled = false;
		Mesh.RemoveComponentVisualsAndCollisionAndTickBlockers(n"Disabled");
		Collision.RemoveComponentVisualsAndCollisionAndTickBlockers(n"Disabled");
	}

	void CopyCollision(USummitKnightCrystalDividerCollisionComponent TemplateCollision)
	{
		Collision = USummitKnightCrystalDividerCollisionComponent::Create(TemplateCollision.Owner, FName(Name + "_Collision"));
		Collision.DetachFromParent(true);
		
		// Workaround for component creation default collision profile bug
		Collision.CollisionProfileName = n"BlockOnlyPlayerCharacter";
		Collision.SetCollisionResponseToChannel(ECollisionChannel::WeaponTraceZoe, ECollisionResponse::ECR_Block);
		Collision.SetCollisionResponseToChannel(ECollisionChannel::WeaponTraceMio, ECollisionResponse::ECR_Block);
		Collision.SetCollisionResponseToChannel(ECollisionChannel::WeaponTracePlayer, ECollisionResponse::ECR_Block);
	}

	void CopyMesh(UStaticMeshComponent TemplateMesh)
	{
		Mesh = UStaticMeshComponent::Create(TemplateMesh.Owner, FName(Name + "_Mesh"));
		Mesh.StaticMesh = TemplateMesh.StaticMesh;
		for (int iMat = 0; iMat < TemplateMesh.GetNumMaterials(); iMat++)
		{
			Mesh.SetMaterial(iMat, TemplateMesh.Materials[iMat]);
		}			
		Mesh.CollisionProfileName = n"NoCollision";
		Mesh.AttachToComponent(Collision);	
		Mesh.RelativeTransform = TemplateMesh.RelativeTransform;
	}

	void StartGrowing(FVector Location, AHazeActor Owner)
	{
		Collision.WorldLocation = Location + FVector::UpVector * Collision.ScaledCapsuleHalfHeight;
		AccScale.SnapTo(0.0);
		Mesh.WorldScale3D = FVector(AccScale.Value);
		StartGrowTime = Time::GameTimeSeconds;
		USummitKnightCrystalDividerEventHandler::Trigger_OnSpawnSegment(Owner, FSummitKnightCrystalDividerSmashSegmentParams(Location));
	}
}

class USummitKnightCrystalDividerCollisionComponent : UHazeCapsuleCollisionComponent
{
	default bGenerateOverlapEvents = false;
	default CapsuleHalfHeight = 300.0;
	default CapsuleRadius = 200.0;
	default CollisionProfileName = n"BlockOnlyPlayerCharacter";
	default CollisionObjectType = ECollisionChannel::ECC_WorldDynamic;
	default CollisionEnabled = ECollisionEnabled::QueryAndPhysics;
	default SetCollisionResponseToChannel(ECollisionChannel::WeaponTraceZoe, ECollisionResponse::ECR_Block);
	default SetCollisionResponseToChannel(ECollisionChannel::WeaponTraceMio, ECollisionResponse::ECR_Block);
	default SetCollisionResponseToChannel(ECollisionChannel::WeaponTracePlayer, ECollisionResponse::ECR_Block);
	default RemoveTag(ComponentTags::Walkable);
	default RemoveTag(ComponentTags::LedgeClimbable);
	default RemoveTag(ComponentTags::LedgeRunnable);
	default RemoveTag(ComponentTags::InheritHorizontalMovementIfGround);
	default RemoveTag(ComponentTags::InheritVerticalDownMovementIfGround);
	default RemoveTag(ComponentTags::InheritVerticalUpMovementIfGround);
	default RemoveTag(ComponentTags::AllowRelativePositionSyncing);
}

UCLASS(Abstract)
class ASummitKnightCrystalDivider : AHazeActor
{
	default PrimaryActorTick.bStartWithTickEnabled = false;

	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent)
	USummitKnightCrystalDividerCollisionComponent SmashCollision;

	UPROPERTY(DefaultComponent, Attach = "SmashCollision")
	UStaticMeshComponent Mesh;
	default Mesh.CollisionProfileName = n"NoCollision";

	UPROPERTY(DefaultComponent)
	UBasicAIProjectileComponent ProjectileComp;

	UPROPERTY(DefaultComponent)
	UHazeActorRespawnableComponent RespawnComp;

	UPROPERTY(DefaultComponent)
	UTeenDragonTailAttackResponseComponent TailAttackResponseComp;
	default TailAttackResponseComp.ImpactType = ETailAttackImpactType::Enemy;
	default TailAttackResponseComp.bIsPrimitiveParentExclusive = false;
	default TailAttackResponseComp.bShouldStopPlayer = false;

	TArray<FSummitKnightCrystalDividerSegment> Segments;

	USummitKnightSettings Settings;
	USummitKnightComponent KnightComp;
	FVector DefaultMeshScale;

	FVector StartLocation;
	FVector StartControl;
	FVector DivideTangent;
	FVector DivideLocation;
	FVector EndLocation;
	bool bPreDivision;
	float PreDivideAlpha;
	float PostDivideAlpha;	
	float StartExpireTime;
	int NumSegments;
	float AlphaPerSecond;
	float SegmentInterval;
	int iSegmentHead;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		SetActorControlSide(Game::Mio);

		TailAttackResponseComp.OnHitByRoll.AddUFunction(this, n"OnHitByRoll");

		DefaultMeshScale = Mesh.WorldScale;

		FSummitKnightCrystalDividerSegment Segment;
		Segment.Name = n"Segment0";
		Segment.Mesh = Mesh;
		Segment.Collision = SmashCollision;
		Segment.AccScale.SnapTo(0.0);
		Segment.StartGrowTime = 0.0;
		Segments.Add(Segment);
		Segment.Collision.DetachFromParent(true);

		SegmentInterval = SmashCollision.ScaledCapsuleRadius * 1.5;
	}

	UFUNCTION()
	private void OnHitByRoll(FRollParams Params)
	{
		if (!ProjectileComp.bIsLaunched)	
			return;
		for (int iSegment = 0; iSegment < Segments.Num(); iSegment++)
		{
			if (Params.HitComponent == Segments[iSegment].Collision)
			{
				// Smash surrounding segments
				for (int iSmash = -Settings.CrystalDividerSmashSegmentWidth; iSmash <= Settings.CrystalDividerSmashSegmentWidth; iSmash++)
				{
					if (Segments.IsValidIndex(iSegment + 2 * iSmash))
						Segments[iSegment + 2 * iSmash].Smash(this);
				}
				break;
			}
		}
		if (StartExpireTime > Time::GameTimeSeconds)
			StartExpireTime = Time::GameTimeSeconds;
	}

	void Divide(FVector Origin, FVector Destination, float LifeTime)
	{
		Settings = USummitKnightSettings::GetSettings(ProjectileComp.Launcher);
		KnightComp = USummitKnightComponent::Get(ProjectileComp.Launcher);
		KnightComp.ActiveDivider = this;
		ActorRotation = FRotator::MakeFromZX(FVector::UpVector, Destination - Origin);

		StartExpireTime = Time::GameTimeSeconds + LifeTime - Settings.CrystalDividerExpirationDuration; 

		bPreDivision = true;
		PreDivideAlpha = 0.0;
		PostDivideAlpha = 0.0;

		StartLocation = Origin;
		EndLocation = Destination;

		DivideLocation = (Game::Mio.ActorLocation + Game::Zoe.ActorLocation) * 0.5;
		float DivideDist = StartLocation.Dist2D(DivideLocation);
		FVector StartToDivide = DivideLocation - StartLocation;

		// Tangent from divide point back towards start that defines from which direction divider pass between players
		DivideTangent = FVector::UpVector.CrossProduct(DivideLocation - Game::Mio.ActorLocation).GetSafeNormal2D();
		if (DivideTangent.DotProduct(StartToDivide) > 0.0)
			DivideTangent = -DivideTangent; 
		DivideTangent *= DivideDist * 0.5;	

		// Start out towards divide but tending away from divide tangent so we'll get a nice curve
		FVector SideStart = StartToDivide.CrossProduct(FVector::UpVector);
		if (SideStart.DotProduct(DivideTangent) > 0.0)
			SideStart = -SideStart;
		StartControl = StartLocation + StartToDivide * 0.25 + SideStart * 0.25;

		float StartLength = BezierCurve::GetLength_2CP(StartLocation, StartControl, DivideLocation + DivideTangent, DivideLocation); 
		float EndLength = BezierCurve::GetLength_1CP(DivideLocation, DivideLocation - DivideTangent, EndLocation);
		AlphaPerSecond = Settings.CrystalDividerMoveSpeed / Math::Max(1.0, StartLength);

		// Set up segments
		NumSegments = Math::Min(Settings.CrystalDividerMaxSegments, Math::TruncToInt((StartLength + EndLength) / SegmentInterval));
		for (int i = Segments.Num(); i < NumSegments; i++)
		{
			// Create new segments as needed
			FSummitKnightCrystalDividerSegment Segment;
			Segment.Name = FName("Segment" + Segments.Num());
			Segment.CopyCollision(SmashCollision);
			Segment.CopyMesh(Mesh);
			Segments.Add(Segment);
		}
		for (int i = NumSegments - 1; i < Segments.Num(); i++)
		{
			// Disable extraneous segments
			Segments[i].Disable();
		}
		for (int i = 0; i < NumSegments; i++)
		{
			// Enable the ones we'll use
			Segments[i].Enable();
		}
		// Prepare all segments for launch with current settings
		for (FSummitKnightCrystalDividerSegment& Segment : Segments)
		{
			Segment.AccScale.SnapTo(0.0);
			Segment.StartGrowTime = BIG_NUMBER;
			Segment.Mesh.WorldScale3D = FVector::ZeroVector;
			Segment.Hide();
		}

		// Start growing first segment
		iSegmentHead = 0;
		Segments[0].Show();
		Segments[0].StartGrowing(StartLocation, this);
		Segments[0].Mesh.WorldRotation = FRotator::MakeFromZX(FVector::UpVector, StartControl - StartLocation);
	}

	// Projectile will start ticking when launched and will be disabled when it expires
	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		if (!ProjectileComp.bIsLaunched)
			return; // Not yet spawned

		if (DeltaTime < SMALL_NUMBER)
			return;

		float CurTime = Time::GameTimeSeconds;		
		if (CurTime > StartExpireTime)
			Expiring(DeltaTime);
		else if (bPreDivision)
			MoveToDivision(DeltaTime);
		else
			MoveAfterDivision(DeltaTime);

#if EDITOR
		if (ProjectileComp.Launcher.bHazeEditorOnlyDebugBool)
		{
			Debug::DrawDebugLine(ActorLocation, ActorLocation + FVector(0.0, 0.0, 200.0), FLinearColor::DPink, 5.0);
			BezierCurve::DebugDraw_2CP(StartLocation, StartControl, DivideLocation + DivideTangent, DivideLocation, FLinearColor::Yellow, 5.0);
			BezierCurve::DebugDraw_1CP(DivideLocation, DivideLocation - DivideTangent, EndLocation, FLinearColor::Purple, 5.0);
		}
#endif		
	}

	void MoveToDivision(float DeltaTime)
	{
		DivideLocation = (Game::Mio.ActorLocation + Game::Zoe.ActorLocation) * 0.5;

		PreDivideAlpha += AlphaPerSecond * DeltaTime;
		if (PreDivideAlpha > 1.0)
		{
			// We've reached division, set up curve for remaining part and move there instead
			bPreDivision = false;
			float PreDivideLength = BezierCurve::GetLength_2CP(StartLocation, StartControl, DivideLocation + DivideTangent, DivideLocation);
			float RemainingDist = (PreDivideAlpha - 1.0) * PreDivideLength;
			float PostDivideLength = BezierCurve::GetLength_1CP(DivideLocation, DivideLocation - DivideTangent, EndLocation);
			AlphaPerSecond = Settings.CrystalDividerMoveSpeed / Math::Max(1.0, PostDivideLength);
			MoveAfterDivision(RemainingDist / Settings.CrystalDividerMoveSpeed);
			PreDivideAlpha = 1.0;
			return;
		}

		// Move along bezier curve towards point in between players
		FVector CurveLoc = BezierCurve::GetLocation_2CP(StartLocation, StartControl, DivideLocation + DivideTangent, DivideLocation, PreDivideAlpha);
		FVector ArenaLoc = KnightComp.GetArenaLocation(CurveLoc, Game::Zoe);
		ProjectileComp.Velocity = (ArenaLoc - ActorLocation) / DeltaTime;
		ActorLocation = ArenaLoc;

		UpdateSegments(DeltaTime);
	}

	void MoveAfterDivision(float DeltaTime)
	{
		// Note that we no longer need to update division location
		// Move along bezier curve towards destination
		PostDivideAlpha += AlphaPerSecond * DeltaTime;
		if (PostDivideAlpha > 1.0)
		{
			// We're done
			PostDivideAlpha = 1.0;
		}
		else
		{
			FVector CurveLoc = BezierCurve::GetLocation_1CP(DivideLocation, DivideLocation - DivideTangent, EndLocation, PostDivideAlpha);
			FVector ArenaLoc = KnightComp.GetArenaLocation(CurveLoc, Game::Zoe);
			ProjectileComp.Velocity = (ArenaLoc - ActorLocation) / DeltaTime;
			ActorLocation = ArenaLoc;
		}

		UpdateSegments(DeltaTime);
	}

	void UpdateSegments(float DeltaTime)
	{
		// Update segments
		if (!ActorLocation.IsWithinDist2D(Segments[iSegmentHead].Collision.WorldLocation, SegmentInterval) && 
			(Segments.IsValidIndex(iSegmentHead + 1)))	
		{
			// Start growing a new crystal
			iSegmentHead++;
			Segments[iSegmentHead].StartGrowing(ActorLocation, this);
			Segments[iSegmentHead].Mesh.WorldRotation = FRotator::MakeFromZX(FVector::UpVector, ActorLocation - Segments[iSegmentHead - 1].Mesh.WorldLocation);
		 	Segments[iSegmentHead].Show();
		}

		float CurTime = Time::GameTimeSeconds;
		for (int i = 0; i <= iSegmentHead; i++)
		{
			float Scale = 0.0;
			float LifeTime = CurTime - Segments[i].StartGrowTime;
			if (LifeTime < 0.0)
				continue;
			if (LifeTime < Settings.CrystalDividerSegmentGrowTime)
				Scale = Math::EaseOut(0.0, 1.0, LifeTime / Settings.CrystalDividerSegmentGrowTime, 2.0); 					
			else 
				Scale = 1.0;

			// Scale mesh, move collision (which mesh is attached to)
			Segments[i].AccScale.SnapTo(Scale);
			Segments[i].Mesh.WorldScale3D = DefaultMeshScale * Scale;
			FVector Loc = Segments[i].Collision.WorldLocation;
			Loc.Z = ActorLocation.Z + Scale * Segments[i].Collision.ScaledCapsuleHalfHeight;
			Segments[i].Collision.WorldLocation = Loc;
		}
	}

	void Expiring(float DeltaTime)
	{
		bool bExpired = true;
		for (FSummitKnightCrystalDividerSegment& Segment : Segments)
		{
			float Scale = Segment.AccScale.AccelerateTo(0.0, Settings.CrystalDividerExpirationDuration, DeltaTime);
			Segment.Mesh.WorldScale3D = DefaultMeshScale * Scale;
			FVector Loc = Segment.Collision.WorldLocation;
			Loc.Z = ActorLocation.Z + Scale * Segment.Collision.ScaledCapsuleHalfHeight;
			Segment.Collision.WorldLocation = Loc;
			if (Scale > 0.05)
				bExpired = false;
		}
		if (bExpired)
		{
			USummitKnightCrystalDividerEventHandler::Trigger_OnExpired(this);

			ProjectileComp.Expire();
			ProjectileComp.bIsLaunched = false;
			if (KnightComp.ActiveDivider == this)
				KnightComp.ActiveDivider = nullptr;
		}
	}

	// UFUNCTION(CrumbFunction)
	// void CrumbHitTarget(AHazePlayerCharacter PlayerTarget)
	// {
	// 	Target = PlayerTarget;
	// 	Target.DamagePlayerHealth(Settings.CrystalDividerHitDamage);	
	// 	KnightComp.ApplyDashTutorialIfPlayerDead(Target);

	// 	FVector StumbleMove = (PlayerTarget.ActorLocation - ActorLocation).GetNormalized2DWithFallback(-PlayerTarget.ActorForwardVector) * Settings.CrystalDividerStumbleDistance;
	// 	KnightComp.StumbleDragon(PlayerTarget, StumbleMove);

	// 	USummitKnightCrystalDividerEventHandler::Trigger_OnHitPlayer(this);		
	// 	if (StartExpireTime > Time::GameTimeSeconds)
	// 		StartExpireTime = Time::GameTimeSeconds;
	// }
}

UCLASS(Abstract)
class USummitKnightCrystalDividerEventHandler : UHazeEffectEventHandler
{
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnSpawnSegment(FSummitKnightCrystalDividerSmashSegmentParams Params) {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnSmashSegment(FSummitKnightCrystalDividerSmashSegmentParams Params) {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnHitPlayer(FSummitKnightCrystalDividerHitPlayerParams Params) {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnExpired() {}
}


struct FSummitKnightCrystalDividerSmashSegmentParams 
{
	UPROPERTY()
	FVector Location;

	FSummitKnightCrystalDividerSmashSegmentParams(FVector Loc)
	{
		Location = Loc;
	}
}

struct FSummitKnightCrystalDividerHitPlayerParams 
{
	UPROPERTY()
	AHazePlayerCharacter Player;

	UPROPERTY()
	FVector Location;

	FSummitKnightCrystalDividerHitPlayerParams(FVector Loc, AHazePlayerCharacter _Player)
	{
		Location = Loc;
		Player = _Player;
	}
}
