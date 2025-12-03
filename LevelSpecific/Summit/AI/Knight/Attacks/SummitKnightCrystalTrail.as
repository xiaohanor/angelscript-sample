class USummitKnightCrystalTrailLauncher : UBasicAINetworkedProjectileLauncherComponent
{
}

struct FSummitKnightCrystalTrailSegment
{
	FName Name;
	UStaticMeshComponent Mesh;
	USummitKnightCrystalTrailCollisionComponent Collision;
	FHazeAcceleratedFloat AccScale;
	float StartGrowTime;
	bool bHidden = false;
	bool bDisabled = false;

	void Smash(AHazeActor Owner)
	{
		if (!bHidden)
		{
			Hide();
			USummitKnightCrystalTrailEventHandler::Trigger_OnSmashSegment(Owner, FSummitKnightCrystalTrailSmashSegmentParams(Collision.WorldLocation));
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

	void CopyCollision(USummitKnightCrystalTrailCollisionComponent TemplateCollision)
	{
		Collision = USummitKnightCrystalTrailCollisionComponent::Create(TemplateCollision.Owner, FName(Name + "_Collision"));
		Collision.DetachFromParent(true);
		
		// Workaround for component creation default collision profile bug
		Collision.CollisionProfileName = n"BlockOnlyPlayerCharacter";
		Collision.SetCollisionResponseToChannel(ECollisionChannel::WeaponTraceZoe, ECollisionResponse::ECR_Block);
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
	}

	void StartGrowing(FVector Location, AHazeActor Owner)
	{
		Collision.WorldLocation = Location;
		AccScale.SnapTo(0.0);
		Mesh.WorldScale3D = FVector(AccScale.Value);
		StartGrowTime = Time::GameTimeSeconds;
		USummitKnightCrystalTrailEventHandler::Trigger_OnSpawnSegment(Owner, FSummitKnightCrystalTrailSmashSegmentParams(Location));
	}
}

class USummitKnightCrystalTrailCollisionComponent : UHazeCapsuleCollisionComponent
{
	default bGenerateOverlapEvents = false;
	default CapsuleHalfHeight = 600.0;
	default CapsuleRadius = 200.0;
	default CollisionProfileName = n"BlockOnlyPlayerCharacter";
	default CollisionObjectType = ECollisionChannel::ECC_WorldDynamic;
	default CollisionEnabled = ECollisionEnabled::QueryAndPhysics;
	default SetCollisionResponseToChannel(ECollisionChannel::WeaponTraceZoe, ECollisionResponse::ECR_Block);
}

class ASummitKnightCrystalTrail : AHazeActor
{
	default PrimaryActorTick.bStartWithTickEnabled = false;

	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent)
	USummitKnightCrystalTrailCollisionComponent SmashCollision;

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
	default TailAttackResponseComp.bShouldStopPlayer = true;

	TArray<FSummitKnightCrystalTrailSegment> Segments;
	int iTrailHead;
	float TrailHeadDistance;

	AHazePlayerCharacter Target;
	USummitKnightSettings Settings;
	USummitKnightComponent KnightComp;
	FVector DefaultMeshScale;
	FVector DefaultCollisionRelativeLocation;
	FTransform DefaultMeshRelativeTransform;
	FHazeAcceleratedFloat AccSpeed;
	FHazeAcceleratedFloat AccHomingAlpha;
	FHazeAcceleratedRotator AccRot;

	UTeenDragonRollComponent RollComp;
	ASummitKnightMobileArena Arena;

	UHazeCharacterSkeletalMeshComponent PrepareMesh;
	FName PrepareSocket;
	FVector PreparedLocation;
	bool bIsPrepared = false;

	float ReleaseTime;
	FVector ReleaseLocation;
	FVector ReleaseTangent;
	FVector LandTangent;
	FVector LandLocation;
	FVector StartHomingLocation;
	bool bHasLanded;
	bool bStartedTrail;
	bool bStartedHoming = false;
	bool bStopHoming = false;
	float StartExpireTime;
	bool bIsExpiring;
	float SpeedScale = 1.0;
	float GroundStartTime;
	int NumSegments = 1;
	bool bCollision = true;
	int TrailIndex;
	float LandPause;
	float InViewDuration;
	float ObscuringViewDuration;
	float HomingNearDuration;

	TArray<AHazePlayerCharacter> AvailableTargets;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		SetActorControlSide(Game::Mio);

		TailAttackResponseComp.OnHitByRoll.AddUFunction(this, n"OnHitByRoll");

		DefaultMeshScale = Mesh.WorldScale;
		DefaultMeshRelativeTransform = Mesh.RelativeTransform;
		DefaultCollisionRelativeLocation = SmashCollision.RelativeLocation;

		FSummitKnightCrystalTrailSegment Segment;
		Segment.Name = n"Segment0";
		Segment.Mesh = Mesh;
		Segment.Collision = SmashCollision;
		Segment.AccScale.SnapTo(0.0);
		Segment.StartGrowTime = 0.0;
		Segments.Add(Segment);

		RollComp = UTeenDragonRollComponent::Get(Game::Zoe);
	}

	UFUNCTION()
	private void OnHitByRoll(FRollParams Params)
	{
		if (!Settings.bCrystalTrailCanSmash)
			return;
		if (!ProjectileComp.bIsLaunched)	
			return;
		for (int iSegment = 0; iSegment < Segments.Num(); iSegment++)
		{
			if (Params.HitComponent == Segments[iSegment].Collision)
			{
				// Smash surrounding segments
				for (int iSmash = -Settings.CrystalTrailSmashSegmentWidth; iSmash <= Settings.CrystalTrailSmashSegmentWidth; iSmash++)
				{
					if (Segments.IsValidIndex(iSegment + 2 * iSmash))
						Segments[iSegment + 2 * iSmash].Smash(this);
				}
				break;
			}
		}
		StartExpiring();
	}

	void StartExpiring()
	{
		if (bIsExpiring)
			return;
		bIsExpiring = true;
		if (StartExpireTime > Time::GameTimeSeconds)
			StartExpireTime = Time::GameTimeSeconds;
		USummitKnightCrystalTrailEventHandler::Trigger_OnExpired(this);	
	}

	void Prepare(UHazeCharacterSkeletalMeshComponent LauncherMesh, FName Socket, AHazePlayerCharacter TargetPlayer, float TrailSpeedScale, int Index)
	{
		if (HasControl())
			CrumbPrepare(ProjectileComp.Launcher, LauncherMesh, Socket, TargetPlayer, TrailSpeedScale, Index);
	}

	UFUNCTION(CrumbFunction)
	void CrumbPrepare(AHazeActor Launcher, UHazeCharacterSkeletalMeshComponent LauncherMesh, FName Socket, AHazePlayerCharacter TargetPlayer, float TrailSpeedScale, int Index)
	{
		bIsPrepared = true;
		ProjectileComp.Launcher = Launcher;
		Target = TargetPlayer;
		TrailIndex = Index;
		ReleaseTime = BIG_NUMBER;
		bHasLanded = false;
		bStartedTrail = false;
		bStartedHoming = false;
		bStopHoming = false;
		StartExpireTime = BIG_NUMBER; 
		bIsExpiring = false;
		SpeedScale = TrailSpeedScale;
		GroundStartTime = BIG_NUMBER;
		AccHomingAlpha.SnapTo(0.0);	
		AvailableTargets = Game::Players;
		InViewDuration = 0.0;
		ObscuringViewDuration = 0.0;
		HomingNearDuration = 0.0;
	
		PrepareMesh = LauncherMesh;
		PrepareSocket = Socket;
		PreparedLocation = ActorLocation;
		Settings = USummitKnightSettings::GetSettings(ProjectileComp.Launcher);
		KnightComp = USummitKnightComponent::Get(ProjectileComp.Launcher);

		// Set up segments
		iTrailHead = 0;
		TrailHeadDistance = 0.0;
		NumSegments = Settings.CrystalTrailSegmentsNumber;
		for (int i = Segments.Num(); i < NumSegments; i++)
		{
			// Create new segments as needed
			FSummitKnightCrystalTrailSegment Segment;
			Segment.Name = FName("Segment" + Segments.Num());
			Segment.CopyCollision(SmashCollision);
			Segment.CopyMesh(Mesh);
			Segment.Mesh.AttachToComponent(Segment.Collision, NAME_None, EAttachmentRule::KeepRelative);
			Segment.Mesh.RelativeTransform = DefaultMeshRelativeTransform;
			Segments.Add(Segment);
		}
		for (int i = Math::Max(0, NumSegments - 1); i < Segments.Num(); i++)
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
		for (FSummitKnightCrystalTrailSegment& Segment : Segments)
		{
			Segment.AccScale.SnapTo(0.0);
			Segment.StartGrowTime = BIG_NUMBER;
			Segment.Mesh.WorldScale3D = FVector::ZeroVector;
			Segment.Hide();

			if (bCollision && !Settings.bCrystalTrailCanSmash)
				Segment.Collision.AddComponentCollisionBlocker(this);
			else if (!bCollision && Settings.bCrystalTrailCanSmash)
				Segment.Collision.RemoveComponentCollisionBlocker(this);
		}
		bCollision = Settings.bCrystalTrailCanSmash;

		// Prepare main segment to be shown before landing
		if (NumSegments > 0)
			Segments[0].Show();
		Segments[0].Collision.AttachTo(Root, NAME_None);
		Segments[0].Collision.RelativeLocation = DefaultCollisionRelativeLocation;

		USummitKnightCrystalTrailEventHandler::Trigger_OnSpawned(this);		
	}

	void Release(ASummitKnightMobileArena TargetArena, FVector StartLocation, float PauseDuration)
	{
		ReleaseTime = Time::GameTimeSeconds;
		ReleaseLocation = ActorLocation;
		ReleaseTangent = (ActorLocation - ProjectileComp.Launcher.ActorLocation).GetSafeNormal2D() * Settings.CrystalTrailReleaseSpeed;
		ReleaseTangent.Z += Settings.CrystalTrailReleaseSteepness;
		LandTangent = KnightComp.CenterDir * Settings.CrystalTrailReleaseSpeed;
		LandTangent.Z -= Settings.CrystalTrailLandSteepness;
		Arena = TargetArena;
		LandLocation = Arena.GetClampedToArena(StartLocation, 400.0);
		StartHomingLocation = LandLocation;
		LandPause = PauseDuration;

		USummitKnightCrystalTrailEventHandler::Trigger_OnLaunch(this);		
	}

	void Land(float DeltaTime)
	{
		float Scale = Segments[0].AccScale.AccelerateTo(0.0, Settings.CrystalTrailLandPause, DeltaTime);
		Segments[0].Mesh.WorldScale3D = DefaultMeshScale * Scale;
		if (!bHasLanded)
		{
			bHasLanded = true;
			ProjectileComp.Velocity = FVector::ZeroVector;
			AccRot.SnapTo(ActorRotation);
			ActorLocation = LandLocation;
			StartExpireTime = Time::GameTimeSeconds + Settings.CrystalTrailMaxGroundDuration;
			USummitKnightCrystalTrailEventHandler::Trigger_OnLand(this);		
		}
		FVector ToTarget = (Target.ActorLocation - ActorLocation);
		ToTarget.Z = 0.0;
		ActorRotation = AccRot.AccelerateTo(ToTarget.Rotation(), Settings.CrystalTrailLandPause * 4.0, DeltaTime);
	}

	void StartTrail()
	{
		ProjectileComp.Velocity = KnightComp.CenterDir * 1.0;
		AccSpeed.SnapTo(ProjectileComp.Velocity.Size());
		Segments[0].Collision.DetachFromParent(true);
		Segments[0].StartGrowing(ActorLocation + DefaultCollisionRelativeLocation, this);
		bStartedTrail = true;
		GroundStartTime = Time::GetGameTimeSince(ProjectileComp.LaunchTime);
	}

	// Projectile will start ticking when launched and will be disabled when it expires
	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		if (!bIsPrepared)
			return; // Not yet spawned

		if (DeltaTime < SMALL_NUMBER)
			return;

		if (bHasLanded && SceneView::IsInView(Target, ActorLocation))
			InViewDuration += DeltaTime;

		float CurTime = Time::GameTimeSeconds;		
		if (CurTime > StartExpireTime)
			Expiring(DeltaTime);
		else if (CurTime < ReleaseTime)
			PreparingMove(DeltaTime);
		else if (CurTime < ReleaseTime + Settings.CrystalTrailFlightDuration)	
			FlightMove(DeltaTime);
		else if (CurTime < ReleaseTime + Settings.CrystalTrailFlightDuration + LandPause)
			Land(DeltaTime);
		else 
			GroundTrailMove(DeltaTime);

		if (bHasLanded && !bIsExpiring) 
		{
			for (int i = AvailableTargets.Num() - 1; i >= 0; i--)
			{
				if (!AvailableTargets[i].HasControl())
					continue;
				if (AvailableTargets[i].IsPlayerDead())
					continue;
				if (!ActorLocation.IsWithinDist2D(AvailableTargets[i].ActorLocation, Settings.CrystalTrailHitRadius))
					continue;
				if (Math::Abs(ActorLocation.Z + 200.0 - AvailableTargets[i].ActorLocation.Z) > Settings.CrystalTrailHitRadius)
					continue;
				CrumbHitTarget(AvailableTargets[i]);
			}
		}

		for(AHazePlayerCharacter Player : Game::Players)
		{
			const float EffectDistance = 1000;
			float Distance = ActorLocation.Distance(Player.ActorLocation);
			if(Distance < EffectDistance)
			{
				float FFFrequency = 200.0;
				float FFIntensity = 1;
				FHazeFrameForceFeedback FF;
				FF.LeftMotor = Math::Sin(Time::GameTimeSeconds * FFFrequency) * FFIntensity;
				FF.RightMotor = Math::Sin(-Time::GameTimeSeconds * FFFrequency) * FFIntensity;
				Player.SetFrameForceFeedback(FF, 1 - Distance / EffectDistance);
			}
		}
	}

	void PreparingMove(float DeltaTime)
	{
		// Move with animation
		FTransform LocalTransform = PrepareMesh.GetSocketTransform(PrepareSocket, ERelativeTransformSpace::RTS_Component);
		FVector Location = LocalTransform.Location;
		Location.X = Math::Min(Location.X, 300.0); 
		Location.Y = Math::Min(Location.Y, 300.0);
		LocalTransform.Location = Location; // Hack restrain anim
		ActorLocation = PrepareMesh.WorldTransform.TransformPosition(LocalTransform.Location);
		ActorRotation = PrepareMesh.WorldTransform.TransformRotation(LocalTransform.Rotator());

		// Keep track of velocity while preparing to properly launch
		if (DeltaTime > SMALL_NUMBER)
			ProjectileComp.Velocity = (ActorLocation - PreparedLocation) / DeltaTime;
		PreparedLocation = ActorLocation;

		// Scale up main segment quickly
		Segments[0].AccScale.AccelerateTo(1.0, 5.0, DeltaTime);
		Segments[0].Mesh.WorldScale3D = DefaultMeshScale * Segments[0].AccScale.Value;
	}

	void FlightMove(float DeltaTime)
	{
		float Alpha = Time::GetGameTimeSince(ReleaseTime) / Settings.CrystalTrailFlightDuration;
		FVector ReleaseControl = ReleaseLocation + ReleaseTangent;
		FVector LandControl = LandLocation - LandTangent; 
		FVector NewLoc = BezierCurve::GetLocation_2CP_ConstantSpeed(ReleaseLocation, ReleaseControl, LandControl, LandLocation,	Alpha);
		ProjectileComp.Velocity = (NewLoc - ActorLocation) / DeltaTime;
		ActorLocation = NewLoc;

		// Spin in flight
		FRotator Rot = ActorRotation;
		Rot.Yaw += 1.0 * 360.0 * DeltaTime;
		Rot.Pitch = 0.0;
		ActorRotation = Rot;
	}

	const float TrailOscillationAmplitude = 2000.0;
	const float TrailOscillationFrequency = 1.2;

	void GroundTrailMove(float DeltaTime)
	{
		float CurTime = Time::GameTimeSeconds;

		if (!bStartedTrail)
			StartTrail();

		if (!bStartedHoming && Target.HasControl() && ShouldHomeInOn(Target, Settings.CrystalTrailHomingRange))
			CrumbStartHoming();	

		if (!bStopHoming)
		{
			if (Target.HasControl() && ShouldStopHoming())
				CrumbStopHoming();	

			FVector ToTarget = (Target.ActorLocation - ActorLocation);
			ToTarget.Z = 0.0;
			if (!bStartedHoming && (InViewDuration < SMALL_NUMBER))
			{
				// When outside of view, rotate towards view periphery so we won't hit player from behind
				FRotator ViewRot = FRotator(0.0, Target.ViewRotation.Yaw, 0.0);
				FVector ViewFwd = ViewRot.ForwardVector;
				FVector ViewSide = ViewRot.RightVector;
				if (ViewSide.DotProduct(ToTarget) > 0.0)
					ViewSide *= -1.0;
				FVector ToViewPeriphery = Target.ActorLocation	+ (ViewFwd * 0.6 + ViewSide) * 0.8 * Settings.CrystalTrailMoveSpeedMax - ActorLocation;
				ToViewPeriphery.Z = 0.0;
				ActorRotation = AccRot.AccelerateTo(ToViewPeriphery.Rotation(), 1.0, DeltaTime);
			}
			else
			{
				// Rotate towards target
				ActorRotation = AccRot.AccelerateTo(ToTarget.Rotation(), 1.0, DeltaTime);
			}
		}

		// Move forward, dealing damage when reached
		float AccDuration = Settings.CrystalTrailAccelerationDuration / Math::Max(1.0, SpeedScale);
		float TargetSpeed = Settings.CrystalTrailMoveSpeedMax * SpeedScale;
		if (!bStartedHoming)
			TargetSpeed *= 0.5;
		AccSpeed.AccelerateTo(TargetSpeed, AccDuration, DeltaTime);
		FVector NewLoc = ActorLocation + ActorForwardVector * AccSpeed.Value * DeltaTime;

		if (bStartedHoming)
			AccHomingAlpha.AccelerateTo(1.0, 0.5, DeltaTime);
		else 
			AccHomingAlpha.AccelerateTo(0.0, 1.0, DeltaTime);
		if (AccHomingAlpha.Value > KINDA_SMALL_NUMBER)
		{
			float HomingOffset = ActorRightVector.DotProduct(Target.ActorLocation - ActorLocation);
			NewLoc += ActorRightVector * HomingOffset * AccHomingAlpha.Value * DeltaTime;
		}

		if (!Target.ActorLocation.IsWithinDist2D(ActorLocation, Settings.CrystalTrailHomingEndRange + 1000.0))
		{
			// Oscillate 
			float GroundDuration = Time::GetGameTimeSince(ProjectileComp.LaunchTime) - GroundStartTime;
			float CurveOffset = Math::Sin(GroundDuration * TrailOscillationFrequency * 2.0 * PI * (1.0 - TrailIndex * 0.6 / float(Settings.CrystalTrailNumber)));
			CurveOffset *= TrailOscillationAmplitude * (3.0 - Math::Sin(CurTime * 1.7371)) * 0.25; // [0.5..1] * Amplitude
			if (Settings.CrystalTrailNumber > 1)
				CurveOffset += (TrailIndex / float(Settings.CrystalTrailNumber - 1)) * 400.0 - 200.0;
			NewLoc += ActorRightVector * CurveOffset * DeltaTime;
		}

		ProjectileComp.Velocity = (NewLoc - ActorLocation) / DeltaTime;
		NewLoc = Arena.GetAtArenaHeight(NewLoc);
		ActorLocation = NewLoc;

		// Update segments
		if (NumSegments > 0)
		{
			float Interval = SmashCollision.CapsuleRadius * 1.5;
			TrailHeadDistance += AccSpeed.Value * DeltaTime;
			if (TrailHeadDistance > Interval)
			{
				// Move a new crystal to trail head
				iTrailHead++;
				Segments[iTrailHead % NumSegments].StartGrowing(ActorLocation + DefaultCollisionRelativeLocation, this);
				TrailHeadDistance -= Interval;
				if (iTrailHead < NumSegments)
					Segments[iTrailHead].Show();	// First time segment is used this round	
			}

			float StartRetractingTime = Settings.CrystalTrailSegmentGrowTime + 0.1;
			float RetractDuration = Settings.CrystalTrailSegmentShrinkTime;
			int NumToUpdate = Math::Min(iTrailHead + 1, Segments.Num());
			for (int i = 0; i < NumToUpdate; i++)
			{
				float Scale = 0.0;
				float LifeTime = Time::GetGameTimeSince(Segments[i].StartGrowTime);
				if (LifeTime < 0.0)
					continue;
				if (LifeTime < Settings.CrystalTrailSegmentGrowTime)
					Scale = Math::EaseOut(0.0, 1.0, LifeTime / Settings.CrystalTrailSegmentGrowTime, 2.0); 					
				else if (LifeTime < StartRetractingTime)
					Scale = 1.0;
				else
					Scale = Math::EaseIn(1.0, 0.0, Math::Clamp((LifeTime - StartRetractingTime) / RetractDuration, 0.0, 1.0), 2.0); 

				// Scale mesh, move collision (which mesh is attached to)
				Segments[i].AccScale.SnapTo(Scale);
				Segments[i].Mesh.WorldScale3D = DefaultMeshScale * Scale;
				FVector Loc = Segments[i].Collision.WorldLocation;
				Loc.Z = ActorLocation.Z + Scale * DefaultCollisionRelativeLocation.Z;
				Segments[i].Collision.WorldLocation = Loc;
			}
		}

		if (IsObscuringView())
			ObscuringViewDuration += DeltaTime;
		else
			ObscuringViewDuration = 0.0;

		if (bStartedHoming && ActorLocation.IsWithinDist2D(Target.ActorLocation, Settings.CrystalTrailHomingNearRange))
			HomingNearDuration += DeltaTime;

		if (ShouldExpire())
			StartExpiring();

#if EDITOR
		//ProjectileComp.Launcher.bHazeEditorOnlyDebugBool = true;
		if (ProjectileComp.Launcher.bHazeEditorOnlyDebugBool)
		{
		}
#endif		
	}

	bool IsObscuringView()
	{
		FVector ViewLoc = Target.ViewLocation;
		ViewLoc.Z = ActorLocation.Z;
		FVector TargetLoc = Target.ActorLocation;
		TargetLoc.Z = ActorLocation.Z;
		FVector Dir = (TargetLoc - ViewLoc).GetSafeNormal2D();
		if (ActorLocation.IsInsideTeardrop(ViewLoc + Dir * 100.0, TargetLoc - Dir * 200.0, 100.0, 200.0))
			return true;
		return false; 
	}

	bool ShouldExpire()
	{
		if (bIsExpiring)
			return false;

		// Always live for a while
		if (Time::GameTimeSeconds < ReleaseTime + Settings.CrystalTrailFlightDuration + Settings.CrystalTrailLandPause + 2.0)
			return false;

		// Exoire if we end up outside of arena
		if (!Arena.IsInsideArena(ActorLocation, 100.0))
			return true;
			
		// Expire if in between target camera and target for a short while
	 	if (ObscuringViewDuration > 0.7)
			return true;

		return false;
	}

	bool ShouldStopHoming()
	{
		if (!bStartedHoming)
			return false;

		// Stop homing when we've passed behind target from where we started homing
		if ((Target.ActorLocation - StartHomingLocation).DotProduct(Target.ActorLocation - ActorLocation) < 0.0)
			return true;

		// Stop homing when chasing player for long enough
		if (HomingNearDuration > Settings.CrystalTrailHomingMaxNearDuration)
			return true;

		return false;	
	}

	UFUNCTION(CrumbFunction)
	void CrumbStartHoming()
	{
		bStartedHoming = true;
		StartHomingLocation = ActorLocation;
	}

	UFUNCTION(CrumbFunction)
	void CrumbStopHoming()
	{
		bStopHoming = true;
	}

	void Expiring(float DeltaTime)
	{
		if (!bIsExpiring)
			StartExpiring();

		for (FSummitKnightCrystalTrailSegment& Segment : Segments)
		{
			float Scale = Segment.AccScale.AccelerateTo(0.0, 2.0, DeltaTime);
			Segment.Mesh.WorldScale3D = DefaultMeshScale * Scale;
			FVector Loc = Segment.Collision.WorldLocation;
			Loc.Z = ActorLocation.Z + Scale * DefaultCollisionRelativeLocation.Z;
			Segment.Collision.WorldLocation = Loc;
		}
		if (Time::GetGameTimeSince(StartExpireTime) > 2.0)
		{
			// Expire a short while later to allow effects to play out
			Arena = nullptr;
			bIsPrepared = false;
			ProjectileComp.Expire();
		}
	}

	UFUNCTION(CrumbFunction)
	void CrumbHitTarget(AHazePlayerCharacter PlayerTarget)
	{
		AvailableTargets.RemoveSingle(PlayerTarget);
		Target = PlayerTarget;
		PlayerTarget.DealTypedDamage(KnightComp.Owner, Settings.CrystalTrailHitDamage, EDamageEffectType::FireImpact, EDeathEffectType::FireImpact, false);
		if (PlayerTarget.HasControl() && PlayerTarget.IsPlayerDead())
			CrumbDeathFromTrail(PlayerTarget);

		FVector StumbleMove = (PlayerTarget.ActorLocation - ActorLocation).GetNormalized2DWithFallback(-PlayerTarget.ActorForwardVector) * Settings.CrystalTrailStumbleDistance;
		KnightComp.StumbleDragon(PlayerTarget, StumbleMove, HeightFactor = 0.8, ClampWithinArenaThreshold = 200.0);

		USummitKnightCrystalTrailEventHandler::Trigger_OnHitPlayer(this);		
		USummitKnightEventHandler::Trigger_OnTrackingFlameImpact(Cast<AHazeActor>(KnightComp.Owner), FSummitKnightTrackingFlameImpactParams(PlayerTarget, this));
		StartExpiring();

		FSummitKnightProjectileDamageParams DamageEventParams;
		DamageEventParams.Player = PlayerTarget; 
		DamageEventParams.Damage = Settings.CrystalTrailHitDamage; 
		DamageEventParams.Direction = (PlayerTarget.ActorLocation - ActorLocation).GetSafeNormal2D();
		USummitKnightProjectileDamageEventHandler::Trigger_OnPlayerDamage(this, DamageEventParams);
	}

	UFUNCTION(CrumbFunction)
	void CrumbDeathFromTrail(AHazePlayerCharacter Player)
	{
		KnightComp.bDeathCouldHaveBeenDashAvoided[Player] = true; 
	}

	bool ShouldHomeInOn(AHazePlayerCharacter HomingTarget, float HomingRange)
	{
		if (bStopHoming)
			return false;
		if (InViewDuration < 1.0)
			return false;
		if (!ActorLocation.IsWithinDist2D(HomingTarget.ActorLocation, HomingRange))
			return false;
		return true;
	}
}

UCLASS(Abstract)
class USummitKnightCrystalTrailEventHandler : UHazeEffectEventHandler
{
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnSpawned() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnLaunch() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnLand() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnSpawnSegment(FSummitKnightCrystalTrailSmashSegmentParams Params) {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnSmashSegment(FSummitKnightCrystalTrailSmashSegmentParams Params) {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnHitPlayer() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnExpired() {}
}


struct FSummitKnightCrystalTrailSmashSegmentParams 
{
	UPROPERTY()
	FVector Location;

	FSummitKnightCrystalTrailSmashSegmentParams(FVector Loc)
	{
		Location = Loc;
	}
}
