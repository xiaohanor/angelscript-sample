class USummitKnightRotatingCrystalLauncher : UBasicAINetworkedProjectileLauncherComponent
{
}

class ASummitKnightRotatingCrystal : AHazeActor
{
	default PrimaryActorTick.bStartWithTickEnabled = false;

	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent)
	UStaticMeshComponent Mesh;
	default Mesh.CollisionProfileName = n"NoCollision";
	default Mesh.bCanEverAffectNavigation = false;

	UPROPERTY(DefaultComponent)
	UBasicAIProjectileComponent ProjectileComp;

	UPROPERTY(DefaultComponent)
	UHazeActorRespawnableComponent RespawnComp;

	UPROPERTY(DefaultComponent)
	UTeenDragonTailAttackResponseComponent TailAttackResponseComp;
	default TailAttackResponseComp.ImpactType = ETailAttackImpactType::Enemy;

	UPROPERTY(DefaultComponent)
	UTeenDragonRollAutoAimComponent RollAutoAimComp;

	UPROPERTY(DefaultComponent)
	UHazeSphereCollisionComponent SmashCollision;
	default SmashCollision.SphereRadius = 400.0;
	default SmashCollision.CollisionProfileName = n"BlockOnlyPlayerCharacter";
	default SmashCollision.CollisionEnabled = ECollisionEnabled::QueryOnly;
	default SmashCollision.SetCollisionResponseToChannel(ECollisionChannel::WeaponTraceZoe, ECollisionResponse::ECR_Block);

	USummitKnightSettings Settings;
	AHazePlayerCharacter Target;
	FHazeAcceleratedFloat AccScale;
	FHazeAcceleratedFloat AccSpikesScale;

	USummitKnightComponent KnightComp;
	FVector LaunchLoc;
	FVector LaunchTangent;
	FVector DeployTangent;

	float LaunchTime;

	UHazeCharacterSkeletalMeshComponent PrepareMesh;
	FName PrepareSocket;
	FVector PreparedLocation;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		SetActorControlSide(Game::Mio);
		ResetScale();

		TailAttackResponseComp.OnHitByRoll.AddUFunction(this, n"OnHitByRoll");
	}

	UFUNCTION()
	private void OnHitByRoll(FRollParams Params)
	{
		if (!ProjectileComp.bIsLaunched)	
			return;
		USummitKnightRotatingCrystalEventHandler::Trigger_OnSmashed(this);
		ProjectileComp.Expire();
	}

	void Prepare(UHazeCharacterSkeletalMeshComponent LauncherMesh, FName Socket)
	{
		// AttachRootComponentTo(LauncherMesh, Socket, EAttachLocation::SnapToTarget);
		PrepareMesh = LauncherMesh;
		PrepareSocket = Socket;
		LaunchTime = BIG_NUMBER;
		PreparedLocation = ActorLocation;
		Settings = USummitKnightSettings::GetSettings(ProjectileComp.Launcher);
		KnightComp = USummitKnightComponent::Get(ProjectileComp.Launcher);
		ResetScale();

		USummitKnightRotatingCrystalEventHandler::Trigger_OnLaunch(this);
	}

	void LaunchAt(AHazePlayerCharacter _Target, FVector LaunchDir)
	{
		RootComponent.DetachFromParent(true);
		Target = _Target; 

		LaunchLoc = ActorLocation;
		LaunchTangent = ProjectileComp.Velocity.GetSafeNormal() * 1000.0;
		DeployTangent = LaunchDir * 2000.0 + FVector(0.0, 0.0, Settings.RotatingLaunchSteepness);

		LaunchTime = Time::GameTimeSeconds;
	}

	void ResetScale()
	{
		AccScale.SnapTo(0.1);
		ActorScale3D = FVector(AccScale.Value);
		AccSpikesScale.SnapTo(0.1);
	}

	// Projectile will start ticking when launched and will be disabled when it expires
	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		if (!ProjectileComp.bIsLaunched)
			return;

		AccScale.AccelerateTo(1.0, Settings.RotatingCrystalStrikeDuration * 0.25, DeltaTime);
		ActorScale3D = FVector(AccScale.Value);

		if (Time::GameTimeSeconds < LaunchTime)
		{
			FTransform LocalTransform = PrepareMesh.GetSocketTransform(PrepareSocket, ERelativeTransformSpace::RTS_Component);
			ActorLocation = PrepareMesh.WorldTransform.TransformPosition(LocalTransform.Location);
			ActorRotation = PrepareMesh.WorldTransform.TransformRotation(LocalTransform.Rotator());

			// Keep track of velocity while preparing to properly launch
			if (DeltaTime > SMALL_NUMBER)
				ProjectileComp.Velocity = (ActorLocation - PreparedLocation) / DeltaTime;
			PreparedLocation = ActorLocation;
			return;
		}	

		float ActiveDuration = Time::GetGameTimeSince(LaunchTime);

		// Movement is deterministic, simulate locally
		FVector StartLoc = LaunchLoc;
		FVector StrikeLoc = Target.ActorLocation;
		FVector StrikeTangent = (Target.ActorLocation - ActorLocation).GetSafeNormal2D() * Settings.RotatingStrikeLength + FVector(0.0, 0.0, -Settings.RotatingStrikeSteepness);
		float TimeFraction = ActiveDuration / Settings.RotatingCrystalStrikeDuration;
		float Alpha = Math::EaseOut(0.0, 0.3, Math::Min(TimeFraction * 3.33, 1.0), 2.0) + TimeFraction * 0.7;
		FVector NewLoc = BezierCurve::GetLocation_3CP_ConstantSpeed(
							StartLoc, 
							StartLoc + LaunchTangent, 
							StartLoc + LaunchTangent + DeployTangent, 
							StrikeLoc - StrikeTangent, 
							StrikeLoc, 
							Alpha);
		ActorLocation = NewLoc;	

		// Spin, visuals only
		FRotator Rot = ActorRotation;
		Rot.Yaw += 1.0 * 360.0 * DeltaTime;
		Rot.Pitch = 0.0;
		ActorRotation = Rot;
		//UpdateSpikes(DeltaTime);		

		// Automatic hit at end of spline (so must be smashed by tail player)
		if ((Alpha > 0.99) || (ActorLocation.IsWithinDist(Target.ActorLocation, 400.0)))
		{
			Target.DamagePlayerHealth(Settings.RotatingCrystalPlayerDamage);
			USummitKnightRotatingCrystalEventHandler::Trigger_OnStrikePlayer(this);
			ProjectileComp.Expire();		
		}

#if EDITOR
		// ProjectileComp.Launcher.bHazeEditorOnlyDebugBool = true;
		if (ProjectileComp.Launcher.bHazeEditorOnlyDebugBool)
		{
		}
#endif		
	}
}

UCLASS(Abstract)
class USummitKnightRotatingCrystalEventHandler : UHazeEffectEventHandler
{
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnLaunch(){}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnSmashed() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnStrikePlayer() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnExpired() {}
}



