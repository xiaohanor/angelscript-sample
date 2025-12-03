class USummitKnightMetalWallLauncher : UBasicAINetworkedProjectileLauncherComponent
{
}

struct FSummitKnightMetalWallSegment
{
	FName Name;
	UStaticMeshComponent Mesh;
	USummitKnightMetalWallCollisionComponent Collision;
	USummitMeltComponent MeltComp;
	UTeenDragonAcidAutoAimComponent AutoAimComp;
	UAcidResponseComponent AcidResponseComp;

	FHazeAcceleratedFloat AccAlpha;
	float StartTime;
	float FullScale;
	float TargetOffset;
	bool bMelted = false;
	bool bShattered = false;
	bool bIsDisabled = false;
	FVector Velocity = FVector::ZeroVector;

	UMaterialInstanceDynamic MeltingMaterial = nullptr;
	float MeltIntactAlpha = 1.0;
	float MeltDissolveAlpha = 0.0;	

	void Melt(AHazeActor Owner)
	{
		if (bIsDisabled)
			return;

		if (!bMelted)
		{
			bMelted = true;
			Collision.AddComponentCollisionBlocker(n"Melt");
			USummitKnightMetalWallEventHandler::Trigger_OnStartMeltingSegment(Owner, FSummitKnightMetalWallSegmentParams(this));
		}
	}

	void UpdateMelting(float MeltSpeed, float DissolveSpeed, float DeltaTime)
	{
		if (!bMelted)
			return;

		// When detached we slide to a stop
		Velocity *= Math::Pow(0.37, DeltaTime);
		Collision.WorldLocation += Velocity * DeltaTime;
		
		MeltIntactAlpha = Math::FInterpConstantTo(MeltIntactAlpha, 0.0, DeltaTime, MeltSpeed);

		if (MeltIntactAlpha < SMALL_NUMBER)
			MeltDissolveAlpha = Math::FInterpConstantTo(MeltDissolveAlpha, 1.0, DeltaTime, DissolveSpeed);		

		if (MeltingMaterial != nullptr)
		{
			// Having a dynamic material for each segment makes them green and unresponsive to params, so do this for
			// the template only. This will be replaced by the new stuff soon anyway.
			MeltingMaterial.SetScalarParameterValue(n"BlendMelt", 1.0 - MeltIntactAlpha);
			MeltingMaterial.SetScalarParameterValue(n"BlendDissolve", MeltDissolveAlpha);
		}
	}

	void Shatter(AHazeActor Owner)
	{
		bShattered = true;
		Mesh.AddComponentVisualsBlocker(n"Shatter");
		AutoAimComp.Disable(n"Shatter");
		Collision.AddComponentCollisionBlocker(n"Shatter");
		USummitKnightMetalWallEventHandler::Trigger_OnShatterSegment(Owner, FSummitKnightMetalWallSegmentParams(this));
	}

	void Restore(AHazeActor Owner)
	{
		if (bMelted)
			Collision.RemoveComponentCollisionBlocker(n"Melt");
		if (bShattered)
		{
			Mesh.RemoveComponentVisualsBlocker(n"Shatter");
			Collision.RemoveComponentCollisionBlocker(n"Shatter");
			AutoAimComp.Enable(n"Shatter");
		}
		bMelted = false;
		bShattered = false;
		AccAlpha.PrecisionLambertNominator = 5.0;			
		AccAlpha.SnapTo(0.0);
		Mesh.WorldScale3D = FVector::ZeroVector;
		MeltIntactAlpha = 1.0;
		MeltDissolveAlpha = 0.0;
		if (MeltingMaterial != nullptr)
		{
			MeltingMaterial.SetScalarParameterValue(n"BlendMelt", 0.0);
			MeltingMaterial.SetScalarParameterValue(n"BlendDissolve", 0.0);
		}
		Velocity = FVector::ZeroVector;
	}

	void Disable()
	{
		if (bIsDisabled)
			return;

		bIsDisabled = true;
		Mesh.AddComponentVisualsAndCollisionAndTickBlockers(n"SegmentDisabler");		
		Collision.AddComponentVisualsAndCollisionAndTickBlockers(n"SegmentDisabler");
		AutoAimComp.Disable(n"SegmentDisabler");
	}

	void Enable()
	{
		if (!bIsDisabled)
			return;

		bIsDisabled = false;
		Mesh.RemoveComponentVisualsAndCollisionAndTickBlockers(n"SegmentDisabler");		
		Collision.RemoveComponentVisualsAndCollisionAndTickBlockers(n"SegmentDisabler");
		AutoAimComp.Enable(n"SegmentDisabler");
	}

	void CopyCollision(USummitKnightMetalWallCollisionComponent TemplateComp)
	{
		Collision = USummitKnightMetalWallCollisionComponent::Create(TemplateComp.Owner, FName(Name + "_Collision"));
		Collision.CapsuleHalfHeight = TemplateComp.CapsuleHalfHeight;
		Collision.CapsuleRadius = TemplateComp.CapsuleRadius;
		Collision.RelativeTransform = TemplateComp.RelativeTransform;

		// For some reason, these do not get set by constructor
		Collision.CollisionProfileName = n"BlockOnlyPlayerCharacter";
		Collision.CollisionObjectType = ECollisionChannel::ECC_WorldDynamic;
		Collision.CollisionEnabled = ECollisionEnabled::QueryAndPhysics;
		Collision.SetCollisionResponseToChannel(ECollisionChannel::WeaponTraceMio, ECollisionResponse::ECR_Block);
		Collision.SetCollisionResponseToChannel(ECollisionChannel::WeaponTracePlayer, ECollisionResponse::ECR_Block);
		Collision.SetCollisionResponseToChannel(ECollisionChannel::ECC_Camera, ECollisionResponse::ECR_Ignore);
	}

	void CopyMesh(UStaticMeshComponent TemplateComp)
	{
		Mesh = UStaticMeshComponent::Create(TemplateComp.Owner, FName(Name + "_Mesh"));
		Mesh.StaticMesh = TemplateComp.StaticMesh;
		
		// TODO: fix proper melting material etc post UXR
		for (int iMat = 0; iMat < TemplateComp.GetNumMaterials(); iMat++)
		{
			Mesh.SetMaterial(iMat, TemplateComp.GetMaterial(iMat));
		}			
		Mesh.CollisionProfileName = n"NoCollision";	
		Mesh.AttachToComponent(Collision);
		Mesh.RelativeRotation = TemplateComp.RelativeRotation;
	}

	void CopyMeltComponent(USummitMeltComponent TemplateComp)
	{
		MeltComp = USummitMeltComponent::Create(TemplateComp.Owner, FName(Name + "_Melt"));
	}

	void CopyAutoAimComponent(UTeenDragonAcidAutoAimComponent TemplateComp)
	{
		AutoAimComp = UTeenDragonAcidAutoAimComponent::Create(TemplateComp.Owner, FName(Name + "_AutoAim"));
		AutoAimComp.AttachToComponent(Collision);
		AutoAimComp.RelativeLocation = TemplateComp.RelativeLocation;
		AutoAimComp.AutoAimMaxAngle = TemplateComp.AutoAimMaxAngle;
		AutoAimComp.TargetShape = TemplateComp.TargetShape;	
	}

	void CopyAcidResponseComponent(UAcidResponseComponent TemplateComp)
	{
		AcidResponseComp = UAcidResponseComponent::Create(TemplateComp.Owner, FName(Name + "_AcidResponse"));
		AcidResponseComp.AttachToComponent(Collision);
		AcidResponseComp.RelativeLocation = TemplateComp.RelativeLocation;
		AcidResponseComp.Shape = TemplateComp.Shape;
	}
}

class USummitKnightMetalWallCollisionComponent : UHazeCapsuleCollisionComponent
{
	default bGenerateOverlapEvents = false;
	default CapsuleHalfHeight = 800.0;
	default CapsuleRadius = 200.0;
	default CollisionProfileName = n"BlockOnlyPlayerCharacter";
	default CollisionObjectType = ECollisionChannel::ECC_WorldDynamic;
	default CollisionEnabled = ECollisionEnabled::QueryAndPhysics;
	default SetCollisionResponseToChannel(ECollisionChannel::WeaponTraceMio, ECollisionResponse::ECR_Block);
	default SetCollisionResponseToChannel(ECollisionChannel::WeaponTraceZoe, ECollisionResponse::ECR_Block);
	default SetCollisionResponseToChannel(ECollisionChannel::WeaponTracePlayer, ECollisionResponse::ECR_Block);
	default SetCollisionResponseToChannel(ECollisionChannel::ECC_Camera, ECollisionResponse::ECR_Ignore);
	default RemoveTag(ComponentTags::Walkable);
	default RemoveTag(ComponentTags::LedgeClimbable);
	default RemoveTag(ComponentTags::LedgeRunnable);
	default RemoveTag(ComponentTags::InheritHorizontalMovementIfGround);
	default RemoveTag(ComponentTags::InheritVerticalDownMovementIfGround);
	default RemoveTag(ComponentTags::InheritVerticalUpMovementIfGround);
	default RemoveTag(ComponentTags::AllowRelativePositionSyncing);
}

asset SummitKnightMetalWallMeltSettings of USummitMeltSettings
{
	MaxHealth = 0.01;
}

class ASummitKnightMetalWall : AHazeActor
{
	default PrimaryActorTick.bStartWithTickEnabled = false;

	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent)
	USummitKnightMetalWallCollisionComponent Collision;

	UPROPERTY(DefaultComponent, Attach = "Collision")
	UStaticMeshComponent Mesh;
	default Mesh.CollisionProfileName = n"NoCollision";

	UPROPERTY(DefaultComponent, Attach = Collision)
	UAcidResponseComponent AcidResponseComp;
	default AcidResponseComp.Shape = FHazeShapeSettings::MakeCapsule(Collision.CapsuleRadius, Collision.CapsuleHalfHeight);

	UPROPERTY(DefaultComponent, Attach = Collision)
	UTeenDragonAcidAutoAimComponent AutoAimComp;
	default AutoAimComp.RelativeLocation = FVector(0.0, 0.0, 0.0);
	default AutoAimComp.AutoAimMaxAngle = 5.0;
	default AutoAimComp.TargetShape.SphereRadius = 150.0;

	// DEPRECATED, remove after UXR
	UPROPERTY(DefaultComponent)
	USummitMeltComponent MeltComp;
	default MeltComp.DefaultMeltSettings = SummitKnightMetalWallMeltSettings;

	UPROPERTY(DefaultComponent)
	UBasicAIProjectileComponent ProjectileComp;

	UPROPERTY(DefaultComponent)
	UHazeActorRespawnableComponent RespawnComp;

	UPROPERTY(DefaultComponent)
	UMovableCameraShakeComponent MovableCameraShakeComp;

	UPROPERTY(DefaultComponent)
	UForceFeedbackComponent ForceFeedbackComp;

	TArray<FSummitKnightMetalWallSegment> Segments;

	USummitKnightSettings Settings;
	USummitKnightComponent KnightComp;
	ASummitKnightMobileArena Arena;
	FVector DefaultScale;
	TPerPlayer<float> CheckDragonPushTime;
	FHazeAcceleratedFloat AccelWallSpeed;
	TPerPlayer<UHazeMovementComponent> MoveComps;
	TPerPlayer<AHazeActor> IgnoredDivider;
	float DeployTime;
	FVector StartLocation;
	const float InsideOffset;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		SetActorControlSide(Game::Mio);

		DefaultScale = Mesh.WorldScale;

		FSummitKnightMetalWallSegment Segment;
		Segment.Name = n"Segment0";
		Segment.Mesh = Mesh;
		Segment.Collision = Collision;
		Segment.AutoAimComp = AutoAimComp;
		Segment.MeltComp = MeltComp;
		Segment.AcidResponseComp = AcidResponseComp;
		Segment.AccAlpha.SnapTo(0.0);
		Segment.StartTime = 0.0;
		Segment.FullScale = 1.0;
		Segment.TargetOffset = 0.0;
		Segment.AcidResponseComp.OnAcidHit.AddUFunction(this, n"OnAcidHit");
		Segment.MeltingMaterial = Mesh.CreateDynamicMaterialInstance(0);
		for (int iMat = 0; iMat < Mesh.GetNumMaterials(); iMat++)
		{
			Mesh.SetMaterial(iMat, Segment.MeltingMaterial);
		}			
		Segments.Add(Segment);

		for (AHazePlayerCharacter Player : Game::Players)
		{
			MoveComps[Player] = UHazeMovementComponent::Get(Player);
		}

		ProjectileComp.OnLaunch.AddUFunction(this, n"Launched");
	}

	UFUNCTION()
	private void Launched(UBasicAIProjectileComponent Projectile)
	{
		MovableCameraShakeComp.ActivateMovableCameraShake();
		ForceFeedbackComp.Play();
	}

	void Launch(ASummitKnightMobileArena KnightArena)
	{
		Settings = USummitKnightSettings::GetSettings(ProjectileComp.Launcher);
		KnightComp = USummitKnightComponent::Get(ProjectileComp.Launcher);
		Arena = KnightArena;
		StartLocation = Arena.GetClampedToArena(ActorLocation, InsideOffset);
		SetActorLocation(StartLocation);
		SetActorRotation(FRotator::MakeFromZX(FVector::UpVector, (Arena.Center - StartLocation)));

		// Set up segments
		int NumSegments = Settings.MetalWallSegmentWidthNumber * 2 + 1;
		for (int i = Segments.Num(); i < NumSegments; i++)
		{
			// Create new segments as needed
			FSummitKnightMetalWallSegment Segment;
			Segment.Name = FName("Segment" + Segments.Num());
			Segment.CopyCollision(Collision);
			Segment.CopyMesh(Mesh);
			Segment.CopyAutoAimComponent(AutoAimComp);
			Segment.CopyMeltComponent(MeltComp);
			Segment.CopyAcidResponseComponent(AcidResponseComp);
			Segment.TargetOffset = Collision.CapsuleRadius * 2.0 * (((i % 2) * 2) - 1) * Math::IntegerDivisionTrunc(i + 1, 2);
			Segment.AcidResponseComp.OnAcidHit.AddUFunction(this, n"OnAcidHit");
			Segments.Add(Segment);
		}
		for (int i = NumSegments; i < Segments.Num(); i++)
		{
			// Disable extraneous segments
			Segments[i].Disable();
			Segments[i].AcidResponseComp.OnAcidHit.Unbind(this, n"OnAcidHit");
		}
		
		// Prepare all segments for launch with current settings
		float Width = Math::Max(1.0, float(Settings.MetalWallSegmentWidthNumber));
		for (int i = 0; i < NumSegments; i++)
		{
			if (Segments[i].bIsDisabled)
				Segments[i].AcidResponseComp.OnAcidHit.AddUFunction(this, n"OnAcidHit");
			Segments[i].Enable();
			float Order = Math::IntegerDivisionTrunc(i + 1, 2) / Width;
			Segments[i].Collision.AttachToComponent(RootComponent);
			Segments[i].Collision.RelativeLocation = FVector(Order * Settings.MetalWallDepthAtEdges, 0.0, Collision.ScaledCapsuleHalfHeight);
			Segments[i].StartTime = Order * Settings.MetalWallSegmentSpreadDuration;
			Segments[i].FullScale = 1.0 - (Order * 0.3);
			Segments[i].Restore(this);
		}
		DeployTime = BIG_NUMBER;

		AccelWallSpeed.SnapTo(Settings.MetalWallMoveSpeedStart);
		for (AHazePlayerCharacter Player : Game::Players)
		{
			CheckDragonPushTime[Player] = 0.0;
		}
	}

	UFUNCTION()
	private void OnAcidHit(FAcidHit Hit)
	{
		// Note that acid hits are replicated
		for (int i = 0; i < Segments.Num(); i++)
		{
			if (Segments[i].bMelted)
				continue;
			if (Segments[i].bIsDisabled)
				continue;
			if (Segments[i].Collision != Hit.HitComponent)
				continue;
			if (Segments[i].AccAlpha.Value < 0.5)	
				continue;

			// Melt all segments when one is hit
			for (FSummitKnightMetalWallSegment& Segment : Segments)
			{
				if (Segment.bMelted)
					continue;
				if (Segment.bIsDisabled)
					continue;

				// Detach from us so that segment can come to a separate stop, then start melting
				Segment.Collision.DetachFromParent(true);
				Segment.Melt(this);
			}
			return;	
		}
	}

	// Projectile will start ticking when launched and will be disabled when it expires
	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		if (!ProjectileComp.bIsLaunched)
			return;

		FTransform PrevTransform = ActorTransform;

		// Move inexorably towards destination, hopefully sweeping target down off arena
		float TargetSpeed = Settings.MetalWallMoveSpeedTarget;
		AccelWallSpeed.AccelerateTo(TargetSpeed, Settings.MetalWallSpeedUpDuration, DeltaTime);
			
		// Move along arena
		ActorLocation += ActorForwardVector * AccelWallSpeed.Value * DeltaTime;

		float RemainingDistance = (Arena.Radius * 2.0) - InsideOffset - StartLocation.Dist2D(ActorLocation);
		if (HasControl() && (RemainingDistance < InsideOffset))
			CrumbExpire();
		float ExpirationScale = Math::GetMappedRangeValueClamped(FVector2D(500.0, 0.0), FVector2D(1.0, 0.0001), RemainingDistance);

		float ActiveDuration = Time::GetGameTimeSince(ProjectileComp.LaunchTime);
		if (DeployTime > ActiveDuration + 1.0)
			DeployTime = ActiveDuration;

		// Update segments
		for (int i = 0; i < Segments.Num(); i++)
		{
			if (Segments[i].bIsDisabled)
				continue;

			// Deploy first segment on launch, the rest later
			if ((i > 0) && (ActiveDuration < DeployTime + Segments[i].StartTime))
			{
				Segments[i].Mesh.WorldScale3D = FVector::ZeroVector;
				continue;
			}

			float Alpha = Segments[i].AccAlpha.AccelerateTo(1.0, Settings.MetalWallSegmentSpreadDuration, DeltaTime);
			float Order = Math::IntegerDivisionTrunc(i + 1, 2) / Math::Max(1.0, float(Settings.MetalWallSegmentWidthNumber));
			float HalfHeight = Segments[i].Collision.ScaledCapsuleHalfHeight;
			Segments[i].Mesh.RelativeScale3D = DefaultScale * Math::Min(1.0, Alpha * 1.0) * Segments[i].FullScale * ExpirationScale; 
			Segments[i].Mesh.RelativeLocation = FVector(0.0, 0.0, -(HalfHeight * (1.0 - Alpha)) - (HalfHeight * (1.0 - Segments[i].FullScale))); 
			if (i > 0)
				Segments[i].Mesh.RelativeRotation = FRotator(0.0, -90.0, 0.0).Compose(FRotator(0.0, 0.0, (1.0 - Alpha) * 60.0 * (((i % 2) * 2.0) - 1.0))); 

			if (!Segments[i].bMelted)
			{
				// Move segment relative to us
				Segments[i].Collision.RelativeLocation = FVector(Order * Settings.MetalWallDepthAtEdges, Segments[i].TargetOffset * Alpha, HalfHeight);
				Segments[i].Velocity = ProjectileComp.Velocity;	
			}
			else
			{
				// Segment is melting and moves independently
				Segments[i].UpdateMelting(1.5, 1.0, DeltaTime);	
			}
		}

		if (ExpirationScale > 0.5)
		{
			for (AHazePlayerCharacter Player : Game::Players)
			{
				if (ActiveDuration < CheckDragonPushTime[Player])
					continue;
				if (!Player.HasControl())
					continue;
				for (FSummitKnightMetalWallSegment& Segment : Segments)
				{
					if (Segment.bMelted || Segment.bShattered)
						continue;
					FVector SegmentProbeLoc = Segment.Collision.WorldLocation + ActorForwardVector * 140.0;
					if (!SegmentProbeLoc.IsWithinDist2D(Player.ActorLocation, Segment.Collision.ScaledCapsuleRadius))
						continue;
					if (Player.ActorLocation.Z > Segment.Collision.WorldLocation.Z + Segment.Collision.ScaledCapsuleHalfHeight)
						continue;	
					if (Player.ActorLocation.Z < Segment.Collision.WorldLocation.Z - Segment.Collision.ScaledCapsuleHalfHeight - Segment.Collision.ScaledCapsuleRadius)
						continue;	
					// Dragon was hit. Stumble is internally networked
					float HeightFraction = 0.6;
					FVector Move = (ActorForwardVector * (1.0 - HeightFraction) + FVector::UpVector * HeightFraction) * Settings.MetalWallDragonStumbleDistance;
					if (KnightComp.StumbleDragon(Player, Move, 0.0))
					{
						CheckDragonPushTime[Player]	= ActiveDuration + 1.0;

						// Player stumble should not be impeded by dividers
						if ((IgnoredDivider[Player] == nullptr) && (KnightComp.ActiveDivider != nullptr))
						{
							IgnoredDivider[Player] = KnightComp.ActiveDivider;
							MoveComps[Player].AddMovementIgnoresActor(this, KnightComp.ActiveDivider);
						}
					}				
					Player.DamagePlayerHealth(Settings.MetalWallPlayerDamage);
					Segment.Shatter(this);
					break;					
				}
			}
		}
	}

	UFUNCTION(CrumbFunction)
	void CrumbExpire()
	{
		if(ProjectileComp.bIsExpired)
			return;

		USummitKnightMetalWallEventHandler::Trigger_OnExpired(this);
		ProjectileComp.Expire();
		ProjectileComp.bIsLaunched = false;
		MovableCameraShakeComp.DeactivateMovableCameraShake();
		ForceFeedbackComp.Stop();
	}	
}

UCLASS(Abstract)
class USummitKnightMetalWallEventHandler : UHazeEffectEventHandler
{
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnStartMeltingSegment(FSummitKnightMetalWallSegmentParams Params) {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnShatterSegment(FSummitKnightMetalWallSegmentParams Params) {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnExpired() {}
}


struct FSummitKnightMetalWallSegmentParams 
{
	UPROPERTY()
	FVector Location;

	UPROPERTY()
	UStaticMeshComponent Mesh;

	UPROPERTY()
	USummitKnightMetalWallCollisionComponent Collision;

	FSummitKnightMetalWallSegmentParams(FSummitKnightMetalWallSegment Segment)
	{
		Location = Segment.Collision.WorldLocation;
		Mesh = Segment.Mesh;
		Collision = Segment.Collision;
	}
}

